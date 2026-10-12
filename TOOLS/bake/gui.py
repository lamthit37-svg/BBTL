# Cửa sổ Tkinter của công cụ niêm và cook. Việc nặng chạy ở luồng khác, hàng đợi
# đưa kết quả về luồng giao diện. Đóng cửa sổ thì dừng giữa các tệp và xoá bản dở.

from __future__ import annotations

import ctypes
import queue
import sys
import threading
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, scrolledtext, ttk

from audio_cook import CookRefusal, cook_tree
from errors import MISMATCH_TEXT, BakeError, Cancelled
from keyfile import MEM_MODERATE, MEM_SENSITIVE, OPS_MODERATE, OPS_SENSITIVE
from map_cook import MapCookRefusal, cook_map
from tlpak import random_key
from tree import load_key, open_folder, seal_folder, store_key, verify_folder, wipe_key

_WARNING = (
    "Khoá không nằm trong client. Game không đọc gói này nên tốc độ nạp và khung hình không đổi. "
    "Ảnh chụp GPU lúc game đang chạy vẫn thấy asset đã đưa lên bộ nhớ hình."
)
_COOK_NOTE = (
    "Wav và mp3 thành .tla: dưới 0,4 giây giữ PCM, dài hơn thì Opus. Tệp khác chép nguyên. "
    "Thư mục ra phải khác cây sound. Game chỉ dùng .tla khi tệp đó nằm cạnh bản gốc — tool không đặt vào đó."
)
_MAP_NOTE = (
    "Tệp .glb thành .vnmap bằng map_cook của VnNet: chia mảnh, ba mức chi tiết, nén, nướng độ che khuất. "
    "Đặt biến BAKE_MAP_COOK hoặc đưa map_cook vào PATH. Cook hỏng thì tệp .vnmap cũ còn nguyên."
)
_KEY_NOTE = (
    "Cụm mật khẩu bọc file khoá bằng Argon2id. Mức cao là 1 GiB, mức vừa là 256 MiB. "
    "Thiếu bộ nhớ thì dừng, không hạ mức. Để trống thì chính file khoá là bí mật."
)
_LEVEL_HIGH = "cao (1 GiB)"
_LEVEL_MID = "vừa (256 MiB)"


def _enable_dpi() -> None:
    if sys.platform != "win32":
        return
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        return None


class App:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.queue: queue.Queue = queue.Queue()
        self.stop = threading.Event()
        self.worker: threading.Thread | None = None
        self.key = tk.StringVar()
        self.passphrase = tk.StringVar()
        self.passphrase_again = tk.StringVar()
        self.kdf_level = tk.StringVar(value=_LEVEL_HIGH)
        self.create_button: ttk.Button | None = None
        self.seal_from = tk.StringVar()
        self.seal_out = tk.StringVar()
        self.cook_from = tk.StringVar()
        self.cook_out = tk.StringVar()
        self.map_from = tk.StringVar()
        self.map_out = tk.StringVar()
        self.status = tk.StringVar(value="Sẵn sàng")
        self._build()
        self.root.after(50, self._poll)

    def _build(self) -> None:
        style = ttk.Style(self.root)
        style.configure("TLabel", font=("Segoe UI", 10))
        style.configure("TButton", font=("Segoe UI", 10))
        style.configure("TEntry", font=("Segoe UI", 10))
        style.configure("Note.TLabel", font=("Segoe UI", 10), wraplength=700)
        notebook = ttk.Notebook(self.root)
        notebook.pack(fill="both", expand=True, padx=10, pady=10)
        seal_tab = ttk.Frame(notebook, padding=12)
        cook_tab = ttk.Frame(notebook, padding=12)
        notebook.add(seal_tab, text="Niêm asset")
        notebook.add(cook_tab, text="Cook âm thanh")
        map_tab = ttk.Frame(notebook, padding=12)
        notebook.add(map_tab, text="Cook bản đồ")
        self.seal_log, self.seal_bar = self._seal_tab(seal_tab)
        self.cook_log, self.cook_bar = self._cook_tab(cook_tab)
        self.map_log = self._map_tab(map_tab)
        ttk.Label(self.root, textvariable=self.status).pack(fill="x", padx=12, pady=(0, 10))
        self.root.protocol("WM_DELETE_WINDOW", self._close)

    def _path_row(self, parent: ttk.Frame, row: int, label: str, variable: tk.StringVar, browse) -> None:
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", pady=4)
        ttk.Entry(parent, textvariable=variable).grid(row=row, column=1, sticky="ew", padx=8)
        if browse is not None:
            ttk.Button(parent, text="Chọn", command=browse).grid(row=row, column=2, sticky="e")

    def _extra_buttons(self, parent: ttk.Frame, row: int, left_text: str, left, right_text: str, right) -> None:
        box = ttk.Frame(parent)
        box.grid(row=row, column=2, sticky="e")
        ttk.Button(box, text=left_text, command=left).pack(side="left", padx=(0, 4))
        ttk.Button(box, text=right_text, command=right).pack(side="left")

    def _seal_tab(self, parent: ttk.Frame) -> tuple[scrolledtext.ScrolledText, ttk.Progressbar]:
        parent.columnconfigure(1, weight=1)
        ttk.Label(parent, text=_WARNING, style="Note.TLabel").grid(row=0, column=0, columnspan=3, sticky="ew")
        self._path_row(parent, 1, "Khoá", self.key, self._browse_key)
        ttk.Label(parent, text="Cụm mật khẩu").grid(row=2, column=0, sticky="w", pady=4)
        self.passphrase_entry = ttk.Entry(parent, textvariable=self.passphrase, show="*")
        self.passphrase_entry.grid(row=2, column=1, sticky="ew", padx=8)
        self.create_button = ttk.Button(parent, text="Tạo khoá", command=self._create_key)
        self.create_button.grid(row=2, column=2, sticky="e")
        ttk.Label(parent, text="Nhập lại").grid(row=3, column=0, sticky="w", pady=4)
        ttk.Entry(parent, textvariable=self.passphrase_again, show="*").grid(row=3, column=1, sticky="ew", padx=8)
        self.kdf_level_box = ttk.Combobox(
            parent,
            textvariable=self.kdf_level,
            values=(_LEVEL_HIGH, _LEVEL_MID),
            state="readonly",
            width=16,
        )
        self.kdf_level_box.grid(row=3, column=2, sticky="e")
        ttk.Label(parent, text=_KEY_NOTE, style="Note.TLabel").grid(row=4, column=0, columnspan=3, sticky="ew")
        self._path_row(parent, 5, "Nguồn", self.seal_from, None)
        self._extra_buttons(parent, 5, "Thư mục", self._browse_seal_from, "Gói", self._browse_seal_package)
        self._path_row(parent, 6, "Đích", self.seal_out, None)
        self._extra_buttons(parent, 6, "Thư mục", self._browse_open_dir, "Gói", self._browse_seal_out)
        buttons = ttk.Frame(parent)
        buttons.grid(row=7, column=0, columnspan=3, sticky="w", pady=8)
        self.seal_buttons = []
        for label, command in (("Niêm", self._seal), ("Mở", self._open), ("Kiểm", self._verify)):
            button = ttk.Button(buttons, text=label, command=command)
            button.pack(side="left", padx=(0, 6))
            self.seal_buttons.append(button)
        self.cancel_seal = ttk.Button(buttons, text="Huỷ", command=self._cancel, state="disabled")
        self.cancel_seal.pack(side="left")
        bar = ttk.Progressbar(parent, mode="determinate", maximum=100)
        bar.grid(row=8, column=0, columnspan=3, sticky="ew", pady=4)
        log = scrolledtext.ScrolledText(parent, height=12, font=("Consolas", 10), state="disabled")
        log.grid(row=9, column=0, columnspan=3, sticky="nsew", pady=4)
        parent.rowconfigure(9, weight=1)
        return log, bar

    def _cook_tab(self, parent: ttk.Frame) -> tuple[scrolledtext.ScrolledText, ttk.Progressbar]:
        parent.columnconfigure(1, weight=1)
        ttk.Label(parent, text=_COOK_NOTE, style="Note.TLabel").grid(row=0, column=0, columnspan=3, sticky="ew")
        self._path_row(parent, 1, "Sound gốc", self.cook_from, self._browse_cook_from)
        self._path_row(parent, 2, "Thư mục ra", self.cook_out, self._browse_cook_out)
        buttons = ttk.Frame(parent)
        buttons.grid(row=3, column=0, columnspan=3, sticky="w", pady=8)
        self.cook_button = ttk.Button(buttons, text="Cook", command=self._cook)
        self.cook_button.pack(side="left", padx=(0, 6))
        self.cancel_cook = ttk.Button(buttons, text="Huỷ", command=self._cancel, state="disabled")
        self.cancel_cook.pack(side="left")
        bar = ttk.Progressbar(parent, mode="determinate", maximum=100)
        bar.grid(row=4, column=0, columnspan=3, sticky="ew", pady=4)
        log = scrolledtext.ScrolledText(parent, height=14, font=("Consolas", 10), state="disabled")
        log.grid(row=5, column=0, columnspan=3, sticky="nsew", pady=4)
        parent.rowconfigure(5, weight=1)
        return log, bar

    def _map_tab(self, parent: ttk.Frame) -> scrolledtext.ScrolledText:
        parent.columnconfigure(1, weight=1)
        ttk.Label(parent, text=_MAP_NOTE, style="Note.TLabel").grid(row=0, column=0, columnspan=3, sticky="ew")
        self._path_row(parent, 1, "Tệp .glb", self.map_from, self._browse_map_from)
        self._path_row(parent, 2, "Tệp .vnmap", self.map_out, self._browse_map_out)
        self.map_button = ttk.Button(parent, text="Cook", command=self._cook_map)
        self.map_button.grid(row=3, column=0, sticky="w", pady=8)
        log = scrolledtext.ScrolledText(parent, height=14, font=("Consolas", 10), state="disabled")
        log.grid(row=4, column=0, columnspan=3, sticky="nsew", pady=4)
        parent.rowconfigure(4, weight=1)
        return log

    def _browse_map_from(self) -> None:
        chosen = filedialog.askopenfilename(title="Bản đồ nguồn", filetypes=[("glTF nhị phân", "*.glb"), ("Mọi tệp", "*.*")])
        if chosen:
            self.map_from.set(chosen)

    def _browse_map_out(self) -> None:
        chosen = filedialog.asksaveasfilename(title="Tệp .vnmap", filetypes=[("Bản đồ VnNet", "*.vnmap"), ("Mọi tệp", "*.*")])
        if chosen:
            self.map_out.set(chosen)

    def _browse_key(self) -> None:
        chosen = filedialog.askopenfilename(title="Chọn khoá", filetypes=[("Khoá", "*.bin"), ("Mọi tệp", "*.*")])
        if chosen:
            self.key.set(chosen)

    def _browse_seal_from(self) -> None:
        chosen = filedialog.askdirectory(title="Thư mục nguồn")
        if chosen:
            self.seal_from.set(chosen)

    def _browse_seal_package(self) -> None:
        chosen = filedialog.askopenfilename(title="Tệp gói", filetypes=[("Gói TLBBPAK1", "*.tlpak"), ("Mọi tệp", "*.*")])
        if chosen:
            self.seal_from.set(chosen)

    def _browse_open_dir(self) -> None:
        chosen = filedialog.askdirectory(title="Thư mục đích")
        if chosen:
            self.seal_out.set(chosen)

    def _browse_seal_out(self) -> None:
        chosen = filedialog.asksaveasfilename(
            title="Tệp gói .tlpak",
            filetypes=[("Gói TLBBPAK1", "*.tlpak"), ("Mọi tệp", "*.*")],
        )
        if chosen:
            self.seal_out.set(chosen)

    def _browse_cook_from(self) -> None:
        chosen = filedialog.askdirectory(title="Thư mục sound gốc")
        if chosen:
            self.cook_from.set(chosen)

    def _browse_cook_out(self) -> None:
        chosen = filedialog.askdirectory(title="Thư mục .tla")
        if chosen:
            self.cook_out.set(chosen)

    def _append(self, log: scrolledtext.ScrolledText, line: str) -> None:
        log.configure(state="normal")
        log.insert("end", line + "\n")
        log.see("end")
        log.configure(state="disabled")

    def _need(self, *values: str) -> bool:
        if all(value.strip() for value in values):
            return True
        messagebox.showerror("Thiên Long", "Chưa chọn đủ đường dẫn.")
        return False

    def _set_busy(self, busy: bool) -> None:
        state = "disabled" if busy else "normal"
        cancel = "normal" if busy else "disabled"
        for button in self.seal_buttons:
            button.configure(state=state)
        if self.create_button is not None:
            self.create_button.configure(state=state)
        self.cook_button.configure(state=state)
        self.map_button.configure(state=state)
        self.cancel_seal.configure(state=cancel)
        self.cancel_cook.configure(state=cancel)

    def _start(self, work, log: scrolledtext.ScrolledText) -> None:
        if self.worker is not None and self.worker.is_alive():
            return
        self.stop.clear()
        self._set_busy(True)
        self.status.set("Đang chạy…")

        def runner() -> None:
            try:
                work()
            except Cancelled:
                self.queue.put(("status", "đã huỷ"))
            except (BakeError, CookRefusal, MapCookRefusal) as error:
                self.queue.put(("fail", str(error), log))
            except Exception as error:
                self.queue.put(("fail", str(error), log))
            finally:
                self.queue.put(("idle", ""))

        self.worker = threading.Thread(target=runner, name="bake-worker")
        self.worker.start()

    def _progress(self, bar: ttk.Progressbar, done: int, total: int) -> None:
        self.queue.put(("progress", bar, done, total))

    def _limits(self) -> tuple[int, int] | None:
        level = self.kdf_level.get()
        if level == _LEVEL_HIGH:
            return OPS_SENSITIVE, MEM_SENSITIVE
        if level == _LEVEL_MID:
            return OPS_MODERATE, MEM_MODERATE
        messagebox.showerror("Thiên Long", "Mức Argon2id không được hỗ trợ.")
        return None

    def _create_key(self) -> None:
        phrase = self.passphrase.get()
        if phrase != self.passphrase_again.get():
            messagebox.showerror("Thiên Long", MISMATCH_TEXT)
            return
        limits = self._limits()
        if limits is None:
            return
        chosen = filedialog.asksaveasfilename(title="Ghi khoá", filetypes=[("Khoá", "*.bin"), ("Mọi tệp", "*.*")])
        if not chosen:
            return
        destination = Path(chosen)

        def work() -> None:
            key = random_key()
            try:
                if phrase:
                    store_key(key, destination, phrase, limits[0], limits[1])
                    line = "đã ghi khoá. Chép file không đủ để mở."
                else:
                    store_key(key, destination)
                    line = "đã ghi khoá. Chính file khoá là bí mật."
            finally:
                wipe_key(key)
            self.queue.put(("status", line))
            self.queue.put(("log", self.seal_log, line))
            self.queue.put(("keyed", chosen))

        self._start(work, self.seal_log)

    def _seal(self) -> None:
        if not self._need(self.key.get(), self.seal_from.get(), self.seal_out.get()):
            return
        key_path = Path(self.key.get())
        phrase = self.passphrase.get()
        source = Path(self.seal_from.get())
        destination = Path(self.seal_out.get())
        bar = self.seal_bar

        def work() -> None:
            key = load_key(key_path, phrase)
            try:
                saved = seal_folder(
                    key,
                    source,
                    destination,
                    stop=self.stop.is_set,
                    on_progress=lambda done, total: self._progress(bar, done, total),
                )
            finally:
                wipe_key(key)
            line = f"đã niêm {saved.files} tệp, {saved.raw_bytes} byte"
            self.queue.put(("status", line))
            self.queue.put(("log", self.seal_log, line))

        self._start(work, self.seal_log)

    def _open(self) -> None:
        if not self._need(self.key.get(), self.seal_from.get(), self.seal_out.get()):
            return
        key_path = Path(self.key.get())
        phrase = self.passphrase.get()
        package = Path(self.seal_from.get())
        destination = Path(self.seal_out.get())

        def work() -> None:
            key = load_key(key_path, phrase)
            try:
                saved = open_folder(key, package, destination)
            finally:
                wipe_key(key)
            line = f"đã mở {saved.files} tệp, {saved.raw_bytes} byte"
            self.queue.put(("status", line))
            self.queue.put(("log", self.seal_log, line))

        self._start(work, self.seal_log)

    def _verify(self) -> None:
        if not self._need(self.key.get(), self.seal_from.get()):
            return
        key_path = Path(self.key.get())
        phrase = self.passphrase.get()
        package = Path(self.seal_from.get())

        def work() -> None:
            key = load_key(key_path, phrase)
            try:
                saved = verify_folder(key, package)
            finally:
                wipe_key(key)
            line = f"gói nguyên, {saved.files} tệp, {saved.raw_bytes} byte"
            self.queue.put(("status", line))
            self.queue.put(("log", self.seal_log, line))

        self._start(work, self.seal_log)

    def _cook(self) -> None:
        if not self._need(self.cook_from.get(), self.cook_out.get()):
            return
        source = Path(self.cook_from.get())
        destination = Path(self.cook_out.get())
        bar = self.cook_bar

        def work() -> None:
            def on_error(line: str) -> None:
                self.queue.put(("log", self.cook_log, line))

            report = cook_tree(
                source,
                destination,
                stop=self.stop.is_set,
                on_progress=lambda done, total: self._progress(bar, done, total),
                on_error=on_error,
            )
            for line in report.lines():
                self.queue.put(("log", self.cook_log, line))
            if report.failed:
                raise CookRefusal(report.lines()[0])
            self.queue.put(("status", report.lines()[0]))

        self._start(work, self.cook_log)

    def _cook_map(self) -> None:
        if not self._need(self.map_from.get(), self.map_out.get()):
            return
        source = Path(self.map_from.get())
        destination = Path(self.map_out.get())

        def work() -> None:
            lines: list[str] = []

            def on_line(line: str) -> None:
                lines.append(line)
                self.queue.put(("log", self.map_log, line))

            code = cook_map(source, destination, on_line)
            last = lines[-1] if lines else "map_cook không in gì"
            if code != 0:
                raise MapCookRefusal(last)
            self.queue.put(("status", last))

        self._start(work, self.map_log)

    def _cancel(self) -> None:
        self.stop.set()
        self.status.set("Sẽ dừng sau tệp này")

    def _poll(self) -> None:
        try:
            while True:
                item = self.queue.get_nowait()
                kind = item[0]
                if kind == "log":
                    self._append(item[1], item[2])
                elif kind == "status":
                    self.status.set(item[1])
                elif kind == "progress":
                    _bar, done, total = item[1], item[2], item[3]
                    value = 0 if total == 0 else (100 * done) / total
                    _bar.configure(value=value)
                elif kind == "fail":
                    self.status.set(item[1])
                    self._append(item[2], item[1])
                    messagebox.showerror("Thiên Long", item[1])
                elif kind == "keyed":
                    self.key.set(item[1])
                    self.passphrase.set("")
                    self.passphrase_again.set("")
                elif kind == "idle":
                    self._set_busy(False)
        except queue.Empty:
            pass
        if self.root.winfo_exists():
            self.root.after(50, self._poll)

    def _close(self) -> None:
        self.stop.set()
        if self.worker is not None and self.worker.is_alive():
            self.status.set("Đang dừng…")
            self.root.after(200, self._close)
            return
        self.root.destroy()


def build_app(visible: bool = True) -> App:
    _enable_dpi()
    root = tk.Tk()
    root.withdraw()
    root.title("Thiên Long — niêm asset")
    root.minsize(760, 640)
    root.geometry("840x720")
    app = App(root)
    if visible:
        root.deiconify()
    return app


def run_gui() -> int:
    app = build_app(True)
    app.root.mainloop()
    return 0
