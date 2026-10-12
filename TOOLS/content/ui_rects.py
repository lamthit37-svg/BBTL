# Bản tính vị trí cửa sổ thứ hai, ĐỘC LẬP với module gui C++ của THIENLONG, để đối chiếu N-phiên
# bản. Viết riêng từ mã gốc TLBB (G:\TLBB\_ref\client\Game\Client: CEGUI, CEGUIFalagardEx,
# CEGUISystem) và layout gốc _raw/Interface/**/*.layout.xml; không đọc SRC/gui, SRC/ui, tests/gui_*,
# G:\TLBB\Dev (các bản port).
# Ghi tests/golden/ui_rects.tsv: ô chữ nhật điểm ảnh (x, y, rộng, cao; gốc trái trên) của MỌI
# <Window> khai trong các layout đã gom ở CLIENT/data/Interface, ở bốn cỡ màn hình. Cách dùng xem
# USAGE; --all-raw chỉ thống kê mọi layout gốc ở 1024x768; --self-test chạy ca tính tay.
# Quyết định đã chốt:
# - Mô phỏng đúng luồng nạp (tạo cửa sổ, gắn cha, áp từng Property theo thứ tự tệp, onParentSized
#   lan xuống con), không dùng công thức đóng: cỡ điểm ảnh được lưu đệm và làm tròn ở nhiều chỗ.
# - Mọi phép tính số thực làm tròn về float32 sau TỪNG phép, như bản gốc 32 bit.
# - Rect báo cáo là getUnclippedPixelRect: không cắt theo cha, không theo vùng client.
# - Bảng mã layout tự dò: BOM, rồi UTF-8, rồi encoding khai báo, rồi GBK; tên cửa sổ nguyên văn.
# Nguồn thuật toán: CEGUI 0.4.1 cộng phần TLBB thêm (ZoomMode, HookMode); số dòng ở khối dưới.
#
# ĐỐI CHIẾU BẢN 2026 (mã máy Bin64/CEGUIBase.dll của client 2026, RVA; chuẩn của dự án là bản này)
# Khớp mã 2008 ở các mục 1, 2, 4-12: PixelAligned cắt về 0 (asAbsolute 0x1c1d0),
# getAbsoluteXPosition 0x24bf0, getUnclippedPixelRect 0xa2000, windowToScreen 0xa9090,
# relativeToAbsolute_impl 0xa4c50, onParentSized 0xa44f0, setPosition 0xa6ec0, GUISheet::initialise
# 0x8a840, ZoomMode mặc định 2 (constructor 0x99b39), bảng HookMode, mẫu sscanf của PropertyHelper,
# trình nạp layout áp Property theo thứ tự tệp. Ba chỗ bản 2026 KHÁC và tệp này theo bản 2026:
# a. setWindowArea_impl (0xa7e10) không kẹp cỡ vào [min, max]; Min/MaxSize chỉ còn được lưu.
# b. Size, AbsoluteSize, Width, Height, AbsoluteWidth, AbsoluteHeight bỏ qua giá trị âm (0xb4c90,
#    0xb4270, 0xb42b0); bản Relative* không chặn.
# c. setSize(mode, Size) (0xa76d0) bỏ qua lời gọi cùng giá trị với lời gọi trước (ô nhớ 0x2e0,
#    khởi tạo -1); onSized (0xa46c0) xoá ô nhớ.
# Golden của 21 layout HUD giống từng byte dưới cả hai ngữ nghĩa. Chưa đối chiếu: Rect (bản 2026 gọi
# setAreaRect), ZoomMode 3 và 4 mới của bản 2026, các lớp tự đổi cỡ.
#
# NGỮ NGHĨA ĐÃ CHỐT (số dòng của bản đã đọc; .cpp ở CEGUI/CEGUI/src, .h ở CEGUI/CEGUI/include, trừ
# khi ghi thư mục khác)
# 1. Làm tròn: PixelAligned(x) = (float)(int)(x + 0.5f) (CEGUIBase.h:159; bật bởi CEGUIConfig.h:63
#    qua CEGUIBase.h:35). Cắt về 0 SAU khi cộng 0.5 nên số âm KHÔNG làm tròn như thường: -4 thành
#    -3, -1 thành 0.
# 2. UDim: asAbsolute(base) = PixelAligned(base * scale) + offset (CEGUIUDim.h:50): chỉ phần scale
#    bị làm tròn, offset giữ nguyên, nên cộng trừ sau làm tròn khác trước làm tròn. asRelative :51.
#    URect lưu (min, max); getSize = max - min (:142); setSize :153-156 và setPosition :146-151 đi
#    qua cộng/trừ float nên d_area có nhiễu 1 ulp; giữ nguyên để cùng kết quả ở ca đúng .5.
# 3. Cỡ: setWindowArea_impl (CEGUIWindow.cpp:3282-3454) tính d_pixelSize = size.asAbsolute(cỡ cha)
#    (:3301). Mã 2008 còn kẹp vào [min, max] theo cỡ MÀN HÌNH (:3291-3292, :3308-3315; mặc định
#    min = 0, max = 1 x màn hình, :227-228); bản 2026 KHÔNG kẹp (mục a ở trên) nên tệp này không
#    kẹp, chỉ đếm cửa sổ vượt giới hạn. d_pixelSize được lưu đệm; getAbsoluteWidth chỉ trả nó
#    (CEGUIWindow.h:934).
# 4. Vị trí KHÔNG lưu đệm: getAbsoluteXPosition = d_min.x.asAbsolute(getParentWidth())
#    (CEGUIWindow.h:904), tính lúc cần theo d_pixelSize hiện tại của cha
#    (CEGUIWindow.cpp:2065-2098).
# 5. Toạ độ màn hình: getUnclippedPixelRect (CEGUIWindow.cpp:587-597) =
#    windowToScreen(Rect(0,0,1,1)) ở chế độ Relative, Rect(0,0,w,h) ở Absolute. windowToScreen(Rect)
#    (:1595-1640) = gốc của cha (đệ quy windowToScreen(Point) :1526-1570) + vị trí tuyệt đối của
#    chính nó; căn Centre cộng thêm (cỡ cha - cỡ mình) x 0.5, căn Right/Bottom cộng (cỡ cha - cỡ
#    mình), đều KHÔNG làm tròn. Cạnh phải/dưới = PixelAligned(1 x d_pixelSize)
#    (relativeToAbsolute_impl :2336-2347): cỡ hiển thị được làm tròn lần hai ở Relative, giữ nguyên
#    ở Absolute.
# 6. Gốc cha: layout chưa có cha lúc nạp nên cỡ cha = cỡ màn hình (getWindowSize_impl :2407-2418;
#    CEGUIRenderer/include/OgreCEGUIRenderer.h:242). Client gắn cửa sổ gốc vào tấm nền
#    DefaultGUISheet phủ kín màn hình (CEGUISystem/UIWindowMng.cpp:124-129, :448;
#    GUISheet::initialise đặt cỡ {1,1}, elements/CEGUIGUISheet.h:92-98; tên lớp
#    elements/CEGUIGUISheet.cpp:34, bí danh CEGUISystem.cpp:346) bằng addChild_impl
#    (CEGUIWindow.cpp:2126-2143) nên onParentSized chạy lại. Mô phỏng cả bước đó.
# 7. Thứ tự áp: CEGUIGUILayout_xmlHandler.cpp:75-118 — mở <Window> là tạo cửa sổ và
#    addChildWindow(cha) NGAY, cha còn đang xây dở. :120-150 — mỗi <Property> gọi setProperty theo
#    thứ tự tệp, mọi ngoại lệ bị nuốt (:145-148); tên lạ ném UnknownObjectException
#    (CEGUIWindow.cpp:3752-3762) nên thành không làm gì. Thuộc tính sau đè thuộc tính trước; thuộc
#    tính đọc cỡ/vị trí hiện tại (XPosition, Width...) thấy trạng thái tại thời điểm đó. Bộ phân
#    tích XML là Expat (CEGUISystem.cpp:67-68; client không truyền bộ khác:
#    CEGUISystem/UISystem.cpp:361), không kiểm lược đồ.
# 8. Lan truyền: setWindowArea_impl phát onSized khi d_pixelSize đổi (:3438-3453); onSized gọi
#    onParentSized từng con (:3944-3952); onParentSized tính lại từ d_area.getPosition()/getSize()
#    (:4202) và chỉ lan xuống tiếp khi d_area.d_max có scale khác 0 (:4211-4215), nên cỡ của cháu có
#    thể cũ khi scale vị trí cộng scale cỡ bằng 0. Cha đổi cỡ SAU khi con tạo vẫn cập nhật con.
# 9. Thuộc tính hình học là tập đăng ký ở Window::addStandardProperties (CEGUIWindow.cpp:2852-2925),
#    xử lý ở CEGUIWindowProperties.cpp: Unified* :893-989 đặt thẳng UDim; Position, Size, XPosition,
#    Width, Rect và bản Relative*/Absolute* của chúng :437-686 đi qua
#    setPosition/setSize/setRect(mode) (CEGUIWindow.cpp:2719-2804): Relative -> UDim(giá trị, 0),
#    Absolute -> UDim(0, PixelAligned(giá trị)). Relative/AbsoluteMin/MaxSize :41-166
#    (CEGUIWindow.cpp:2458-2496). Chuỗi đọc bằng sscanf (CEGUIPropertyHelper.cpp:36-196): mẫu dừng ở
#    chỗ lệch đầu tiên, phần chưa đọc giữ giá trị khởi tạo. MinWidth, MaxWidth, MinHeight... không
#    thuộc Window cốt lõi (không đăng ký ở lớp nào có mặt trong 21 layout, kiểm bằng grep
#    CEGUIFalagardEx) nên không đổi vùng: bỏ qua và đếm.
# 10. MetricsMode (CEGUIWindow.cpp:705-713, :2546-2562; CEGUIWindowProperties.cpp:178-187): mặc định
#    Relative, Inherited lấy của cha (:2586-2589). Chỉ đổi cách đọc Position/Size... đặt SAU đó và
#    nhánh Relative/Absolute của getUnclippedPixelRect (mục 5); KHÔNG tính lại vùng đã đặt. Chuỗi lạ
#    thành Inherited (CEGUIPropertyHelper.cpp:116-131).
# 11. ZoomMode/HookMode/HookPosition (TLBB thêm; CEGUIWindow.cpp:3293-3303, :3327-3433,
#    CEGUIWindowProperties.cpp:992-1024, CEGUIWindow.h:4177-4191): Absolute/Relative tính cỡ theo
#    nền cố định 1024x768 thay cho cỡ cha và đặt vị trí từ HookPosition (Relative nhân cỡ cha), trừ
#    phần cỡ cửa sổ theo HookMode; HookMode None thì KHÔNG đặt vị trí. Các thuộc tính này chỉ ghi
#    giá trị, có tác dụng từ lần setWindowArea_impl SAU. Không layout nào trong 2.034 layout gốc
#    dùng chúng (mã gốc chỉ đặt bằng code, vd CEGUIFalagardEx/FalagardWorldMap.cpp:96-145): cài theo
#    mã, kiểm bằng ca tính tay.
# 12. Vùng client: con khai trong layout tính theo ô cha ĐẦY ĐỦ, không theo vùng client. Gốc của con
#    là windowToScreen của cha (mục 5) và cỡ con theo d_pixelSize đầy đủ của cha (mục 3-4);
#    getUnclippedInnerRect (CEGUIWindow.cpp:606-609, ghi đè ở elements/CEGUIStatic.cpp:85-103) chỉ
#    dùng để cắt (CEGUIWindow.cpp:553, :572). Mã này không có getParentPixelRect; look Falagard chỉ
#    bố trí widget do chính look dựng (falagard/CEGUIFalWidgetComponent.cpp:144), không đụng con
#    khai trong layout.
#
# KHÔNG CHẮC: độ chính xác số thực — float32 từng phép (SSE, hoặc x87 đặt 24 bit như D3D9 mặc định)
#   hay x87 53 bit. Mặc định float32. Hai khả năng chỉ khác nhau ở ca scale x cỡ cha sát .5 (báo cáo
#   đếm số lần gọi PixelAligned sát .5). Đã đo: thay bằng float64 cho 0 dòng khác trên 21 layout x 4
#   cỡ; trên 2.034 layout gốc ở 1024x768 khác 52 trong 94.540 cửa sổ (từ 0.5 px trở lên).
# KHÔNG CHẮC: bước gắn cửa sổ gốc vào tấm nền toàn màn hình (mục 6) — tính lại như client thật
#   (CEGUISystem/UIWindowMng.cpp:129) hay chỉ tính lúc nạp. Mặc định tính lại. Lượt tính lại thêm
#   nhiễu float ở d_area (mục 2). Đã đo: bỏ bước này cho 0 dòng khác trên 21 layout x 4 cỡ; trên
#   2.034 layout gốc khác 25 cửa sổ (từ 0.5 px trở lên), đều ở ca sát .5.
# KHÔNG CHẮC: chuỗi thiếu số — UDim() không khởi tạo (CEGUIUDim.h:46) nên bản gốc để RÁC; Size,
#   Point, Rect thì khởi tạo 0. Mặc định 0 cho cả hai và đếm lại. Không layout nào trong 2.034
#   layout gốc có chuỗi Unified* thiếu số (báo cáo --all-raw).
# KHÔNG CHẮC: cửa sổ không Name — tên rỗng hay __cewin_uid_N do CEGUI tự sinh
#   (CEGUIWindowManager.cpp:81), số này phụ thuộc thứ tự nạp toàn cục nên không tái tạo được. Mặc
#   định tên rỗng, không tính là trùng. 21 layout không có ca nào; toàn bộ raw có 13.
# KHÔNG CHẮC: lớp tự đổi cỡ — mô phỏng hay bỏ qua. Mặc định bỏ qua: SelfFitWindow tự đổi cỡ lúc nạp
#   (CEGUIFalagardEx/FalagardSelfFitWindow.cpp:63-83, :128-132), Falagard/ResizeText bỏ luôn onSized
#   (FalagardResizeText.cpp:218-222), resizeSelf của SuperTooltip và ChatChannel do logic game gọi
#   lúc chạy (FalSuperTooltip.cpp:194-198). Chỉ đếm ở --all-raw. Mọi hook
#   onSized/onParentSized/initialise của lớp có mặt trong 21 layout đã đọc: không cái nào đổi vùng
#   của cửa sổ khai trong layout.
# KHÔNG CHẮC: cỡ hiển thị — PixelAligned(d_pixelSize) (getUnclippedPixelRect) hay d_pixelSize
#   nguyên. Mặc định theo getUnclippedPixelRect vì drawSelf vẽ theo ô đó (CEGUIWindow.cpp:2039);
#   bản C++ lấy thẳng d_pixelSize sẽ lệch tới 0.5 px ở cỡ lẻ.
# KHÔNG CHẮC: ZoomMode, HookMode, HookPosition — cài theo mã nhưng không dữ liệu thật nào dùng (mục
#   11), chỉ kiểm bằng ca tính tay. Mặc định theo mã.

import argparse
import codecs
import math
import os
import re
import struct
import sys
import time
import xml.etree.ElementTree as ElementTree
from collections import Counter, defaultdict
from collections.abc import Callable
from dataclasses import dataclass, field
from enum import Enum

Element = ElementTree.Element
Point = tuple[float, float]

INTERFACE = "Interface"
SCHEMA = "Schema"
LAYOUT_SUFFIX = ".layout.xml"
SCHEME_SUFFIX = ".scheme.xml"
SCREENS = ((1024, 768), (1280, 720), (1920, 1080), (2560, 1600))
STATISTICS_SCREEN = (1024, 768)
ZOOM_WIDTH = 1024.0
ZOOM_HEIGHT = 768.0
SHEET_NAME = "__BACKGOUNDSHEET__"
DEFAULT_TYPES = ("DefaultWindow", "DefaultGUISheet")
FALAGARD_PREFIX = "Falagard/"
SELF_SIZING_TARGETS = ("Falagard/SelfFitWindow", "Falagard/ResizeText")
COLUMNS = ("screen_w", "screen_h", "layout", "window", "x", "y", "w", "h", "is_duplicate")
USAGE = (
    'python ui_rects.py --raw "<_raw>" --collected "<CLIENT/data>" --out "<tsv>" [--all-raw]'
    ' | python ui_rects.py --raw "<_raw>" --all-raw | python ui_rects.py --self-test'
)
DESCRIPTION = (
    "Tính ô chữ nhật điểm ảnh của mọi cửa sổ trong layout CEGUI, độc lập với module gui C++."
)
LIST_LIMIT = 20
NAME_LIST_LIMIT = 200
GEOMETRY_HINT = re.compile(
    r"Size|Position|Rect|Width|Height|Metrics|Zoom|Hook|Align|Anchor|Offset|Padding"
)
CELL_BREAKS = re.compile(r"[\t\r\n]+")
DECLARATION = re.compile(r"\A<\?xml[^?]*\?>")
ENCODING_ATTRIBUTE = re.compile(r"""(encoding\s*=\s*)(["'])([^"']*)\2""", re.IGNORECASE)
DECLARED_ENCODING = re.compile(
    rb"""\A\s*<\?xml[^?]*?encoding\s*=\s*["']([^"']+)["']""", re.IGNORECASE
)
FLOAT_TOKEN = re.compile(r"[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?")
SPACES = " \t\n\v\f\r"
FLOAT32_FORMAT = struct.Struct("<f")
INT_INDEFINITE = -2147483648
NO_SET_SIZE = (-1.0, -1.0)
TOLERANCE = 1e-4
NEAR_HALF = 1e-4
ANOMALY_NAMES = (
    "không hữu hạn", "rộng hoặc cao âm", "rộng hoặc cao bằng 0", "nằm hẳn ngoài màn hình",
    "lấn ra ngoài màn hình", "vượt min/max (2026 không kẹp)",
)


class UiError(Exception):
    pass


# Mốc: số thực float32 và làm tròn điểm ảnh


# Số lần gọi PixelAligned đáng chú ý, đặt lại đầu mỗi lượt tính: "negative" là kết quả khác làm tròn
# thường (chỉ với số âm); "near_half" là đầu vào sát .5 nhưng không đúng .5, nơi nhiễu float quyết
# định làm tròn lên hay xuống.
ALIGN_QUIRKS: Counter = Counter()


def float32(value: float) -> float:
    try:
        return FLOAT32_FORMAT.unpack(FLOAT32_FORMAT.pack(value))[0]
    except OverflowError:
        return math.copysign(math.inf, value)


# (float)(int)(value + 0.5f): int() cắt về 0 như ép kiểu của C++; ngoài tầm int32, x86 cho INT_MIN.
def pixel_align(value: float) -> float:
    shifted = float32(value + 0.5)
    if not math.isfinite(shifted) or abs(shifted) >= 2147483648.0:
        return float32(float(INT_INDEFINITE))
    truncated = int(shifted)
    if truncated != math.floor(shifted):
        ALIGN_QUIRKS["negative"] += 1
    if 0.0 < abs(value - (math.floor(value) + 0.5)) <= NEAR_HALF:
        ALIGN_QUIRKS["near_half"] += 1
    return float32(float(truncated))


# Mốc: UDim, UVector2, URect


@dataclass(frozen=True, slots=True)
class UDim:
    scale: float = 0.0
    offset: float = 0.0

    def as_absolute(self, base: float) -> float:
        product = float32(base * self.scale)
        return float32(pixel_align(product) + self.offset)

    def as_relative(self, base: float) -> float:
        if base == 0.0:
            return 0.0
        quotient = float32(self.offset / base)
        return float32(quotient + self.scale)

    def plus(self, other: "UDim") -> "UDim":
        return UDim(float32(self.scale + other.scale), float32(self.offset + other.offset))

    def minus(self, other: "UDim") -> "UDim":
        return UDim(float32(self.scale - other.scale), float32(self.offset - other.offset))


@dataclass(frozen=True, slots=True)
class UVector2:
    x: UDim = UDim()
    y: UDim = UDim()

    def as_absolute(self, width: float, height: float) -> Point:
        return self.x.as_absolute(width), self.y.as_absolute(height)

    def plus(self, other: "UVector2") -> "UVector2":
        return UVector2(self.x.plus(other.x), self.y.plus(other.y))

    def minus(self, other: "UVector2") -> "UVector2":
        return UVector2(self.x.minus(other.x), self.y.minus(other.y))


@dataclass(frozen=True, slots=True)
class URect:
    low: UVector2 = UVector2()
    high: UVector2 = UVector2()

    def size(self) -> UVector2:
        return self.high.minus(self.low)

    def with_size(self, size: UVector2) -> "URect":
        return URect(self.low, self.low.plus(size))

    # Qua phép trừ rồi cộng lại như URect::setPosition nên cạnh dưới phải có thể lệch 1 ulp.
    def with_position(self, position: UVector2) -> "URect":
        extent = self.high.minus(self.low)
        return URect(position, position.plus(extent))


# Mốc: chuỗi thuộc tính đọc như sscanf


@dataclass(slots=True)
class Scanned:
    values: list[float]
    is_complete: bool


def skip_spaces(text: str, position: int) -> int:
    while position < len(text) and text[position] in SPACES:
        position += 1
    return position


# Mẫu chỉ gồm ký tự thường, khoảng trắng (khớp 0 hay nhiều) và %f; dừng ở chỗ lệch đầu tiên.
# Khác gốc: giá trị chưa đọc được để 0, bản gốc để rác ở UDim (xem KHÔNG CHẮC ở đầu tệp).
def scan_floats(text: str, template: str, count: int) -> Scanned:
    values: list[float] = []
    position = 0
    index = 0
    while index < len(template):
        symbol = template[index]
        if symbol in SPACES:
            position = skip_spaces(text, position)
            index += 1
        elif symbol != "%":
            if text[position:position + 1] != symbol:
                break
            position += 1
            index += 1
        else:
            match = FLOAT_TOKEN.match(text, skip_spaces(text, position))
            if match is None:
                break
            values.append(float32(float(match.group())))
            position = match.end()
            index += 2
    is_complete = len(values) == count
    values.extend([0.0] * (count - len(values)))
    return Scanned(values, is_complete)


def parse_float(text: str) -> tuple[float, bool]:
    scanned = scan_floats(text, " %f", 1)
    return scanned.values[0], scanned.is_complete


def parse_size(text: str) -> tuple[Point, bool]:
    scanned = scan_floats(text, " w:%f h:%f", 2)
    return (scanned.values[0], scanned.values[1]), scanned.is_complete


def parse_point(text: str) -> tuple[Point, bool]:
    scanned = scan_floats(text, " x:%f y:%f", 2)
    return (scanned.values[0], scanned.values[1]), scanned.is_complete


def parse_rect(text: str) -> tuple[tuple[float, float, float, float], bool]:
    scanned = scan_floats(text, " l:%f t:%f r:%f b:%f", 4)
    left, top, right, bottom = scanned.values
    return (left, top, right, bottom), scanned.is_complete


def parse_udim(text: str) -> tuple[UDim, bool]:
    scanned = scan_floats(text, " {%f,%f}", 2)
    return UDim(scanned.values[0], scanned.values[1]), scanned.is_complete


def parse_uvector2(text: str) -> tuple[UVector2, bool]:
    scanned = scan_floats(text, " {{%f,%f},{%f,%f}}", 4)
    x_scale, x_offset, y_scale, y_offset = scanned.values
    vector = UVector2(UDim(x_scale, x_offset), UDim(y_scale, y_offset))
    return vector, scanned.is_complete


def parse_urect(text: str) -> tuple[URect, bool]:
    scanned = scan_floats(text, " {{%f,%f},{%f,%f},{%f,%f},{%f,%f}}", 8)
    values = scanned.values
    low = UVector2(UDim(values[0], values[1]), UDim(values[2], values[3]))
    high = UVector2(UDim(values[4], values[5]), UDim(values[6], values[7]))
    return URect(low, high), scanned.is_complete


# Mốc: cửa sổ


class Mode(Enum):
    RELATIVE = 0
    ABSOLUTE = 1
    INHERITED = 2


class Hook(Enum):
    NONE = 0
    LEFT = 1
    RIGHT = 2
    TOP = 3
    BOTTOM = 4
    LEFT_TOP = 5
    LEFT_BOTTOM = 6
    RIGHT_TOP = 7
    RIGHT_BOTTOM = 8
    CENTER = 9


class Align(Enum):
    START = 0
    CENTRE = 1
    END = 2


HOOK_NAMES = {
    "Left": Hook.LEFT, "Right": Hook.RIGHT, "Top": Hook.TOP, "Bottom": Hook.BOTTOM,
    "LeftTop": Hook.LEFT_TOP, "LeftBottom": Hook.LEFT_BOTTOM, "RightTop": Hook.RIGHT_TOP,
    "RightBottom": Hook.RIGHT_BOTTOM, "Center": Hook.CENTER,
}
# Phần cỡ cửa sổ bị trừ khỏi điểm móc theo trục x và trục y.
HOOK_SHIFT = {
    Hook.LEFT: (0.0, 0.5), Hook.RIGHT: (1.0, 0.5), Hook.TOP: (0.5, 0.0), Hook.BOTTOM: (0.5, 1.0),
    Hook.LEFT_TOP: (0.0, 0.0), Hook.LEFT_BOTTOM: (0.0, 1.0), Hook.RIGHT_TOP: (1.0, 0.0),
    Hook.RIGHT_BOTTOM: (1.0, 1.0), Hook.CENTER: (0.5, 0.5),
}


@dataclass(slots=True)
class Tally:
    windows: int = 0
    properties: int = 0
    nameless: int = 0
    self_sizing: int = 0
    align_negative: int = 0
    align_near_half: int = 0
    handled: Counter = field(default_factory=Counter)
    other: Counter = field(default_factory=Counter)
    partial: Counter = field(default_factory=Counter)
    partial_examples: list[str] = field(default_factory=list)
    unknown_types: Counter = field(default_factory=Counter)


@dataclass(slots=True)
class Environment:
    width: float
    height: float
    type_targets: dict[str, str]
    tally: Tally
    layout_label: str = ""

    # Khác gốc: không dựng widget con của look và không chạy initialise của lớp con; chỉ
    # DefaultWindow (GUISheet::initialise) đổi cỡ mặc định, vì các lớp khác đã đọc không đổi vùng.
    def create_window(self, type_name: str, name: str) -> "Window":
        window = Window(name, self)
        target = self.type_targets.get(type_name, type_name)
        is_known = type_name in self.type_targets or type_name.startswith(FALAGARD_PREFIX)
        self.tally.windows += 1
        if not name:
            self.tally.nameless += 1
        if target in SELF_SIZING_TARGETS:
            self.tally.self_sizing += 1
        if target in DEFAULT_TYPES:
            window.initialise_sheet()
        elif not is_known:
            self.tally.unknown_types[type_name] += 1
        return window

    def create_sheet(self) -> "Window":
        sheet = Window(SHEET_NAME, self)
        sheet.initialise_sheet()
        return sheet


# Mỗi hàm dịch sát một hàm của CEGUI::Window (tên C++ ở comment đầu hàm); giữ toán tử và thứ tự.
# Khác gốc: không phát sự kiện Moved, không gọi performChildWindowLayout (chỉ bố trí widget do look
# dựng) và không có cửa sổ con do look dựng, vì các thứ đó không đổi vùng cửa sổ khai trong layout.
class Window:
    def __init__(self, name: str, environment: Environment):
        self.name = name
        self.environment = environment
        self.parent: Window | None = None
        self.children: list[Window] = []
        self.metrics_setting = Mode.RELATIVE
        self.zoom_mode = Mode.INHERITED
        self.hook_mode = Hook.NONE
        self.hook_x = 0.0
        self.hook_y = 0.0
        self.horizontal = Align.START
        self.vertical = Align.START
        self.area = URect()
        self.pixel_width = 0.0
        self.pixel_height = 0.0
        self.min_size = UVector2(UDim(0.0, 0.0), UDim(0.0, 0.0))
        self.max_size = UVector2(UDim(1.0, 0.0), UDim(1.0, 0.0))
        self.is_beyond_limits = False
        self.last_set_size = NO_SET_SIZE

    # GUISheet::initialise: DefaultWindow mặc định phủ kín cha.
    def initialise_sheet(self) -> None:
        self.set_maximum_size(1.0, 1.0)
        self.set_size(self.metrics_mode(), 1.0, 1.0)

    # getParentWidth, getParentHeight
    def parent_width(self) -> float:
        return self.environment.width if self.parent is None else self.parent.pixel_width

    def parent_height(self) -> float:
        return self.environment.height if self.parent is None else self.parent.pixel_height

    # getMetricsMode, getInheritedMetricsMode
    def metrics_mode(self) -> Mode:
        if self.metrics_setting is Mode.INHERITED:
            return self.inherited_metrics_mode()
        return self.metrics_setting

    def inherited_metrics_mode(self) -> Mode:
        return Mode.RELATIVE if self.parent is None else self.parent.metrics_mode()

    # getAbsoluteXPosition, getRelativeXPosition và các hàm cùng họ (CEGUIWindow.h:814-944).
    def absolute_x(self) -> float:
        return self.area.low.x.as_absolute(self.parent_width())

    def absolute_y(self) -> float:
        return self.area.low.y.as_absolute(self.parent_height())

    def relative_x(self) -> float:
        return self.area.low.x.as_relative(self.parent_width())

    def relative_y(self) -> float:
        return self.area.low.y.as_relative(self.parent_height())

    def relative_width(self) -> float:
        extent = self.area.high.x.minus(self.area.low.x)
        return extent.as_relative(self.parent_width())

    def relative_height(self) -> float:
        extent = self.area.high.y.minus(self.area.low.y)
        return extent.as_relative(self.parent_height())

    # getXPosition(mode), getYPosition(mode), getWidth(mode), getHeight(mode)
    def x_in_mode(self, mode: Mode) -> float:
        mode = self.inherited_metrics_mode() if mode is Mode.INHERITED else mode
        return self.relative_x() if mode is Mode.RELATIVE else self.absolute_x()

    def y_in_mode(self, mode: Mode) -> float:
        mode = self.inherited_metrics_mode() if mode is Mode.INHERITED else mode
        return self.relative_y() if mode is Mode.RELATIVE else self.absolute_y()

    def width_in_mode(self, mode: Mode) -> float:
        mode = self.inherited_metrics_mode() if mode is Mode.INHERITED else mode
        return self.relative_width() if mode is Mode.RELATIVE else self.pixel_width

    def height_in_mode(self, mode: Mode) -> float:
        mode = self.inherited_metrics_mode() if mode is Mode.INHERITED else mode
        return self.relative_height() if mode is Mode.RELATIVE else self.pixel_height

    # setPosition(mode, Point)
    def set_position(self, mode: Mode, x: float, y: float) -> None:
        mode = self.inherited_metrics_mode() if mode is Mode.INHERITED else mode
        if mode is Mode.RELATIVE:
            self.set_window_position(UVector2(UDim(x, 0.0), UDim(y, 0.0)))
            return
        aligned = UVector2(UDim(0.0, pixel_align(x)), UDim(0.0, pixel_align(y)))
        self.set_window_position(aligned)

    # setSize(mode, Size). Bản 2026 (RVA 0xa76d0) bỏ qua lời gọi có cùng giá trị với lời gọi trước,
    # bất kể mode; onSized xoá ô nhớ.
    def set_size(self, mode: Mode, width: float, height: float) -> None:
        if (width, height) == self.last_set_size:
            return
        self.last_set_size = (width, height)
        mode = self.inherited_metrics_mode() if mode is Mode.INHERITED else mode
        if mode is Mode.RELATIVE:
            self.set_window_size(UVector2(UDim(width, 0.0), UDim(height, 0.0)))
            return
        aligned = UVector2(UDim(0.0, pixel_align(width)), UDim(0.0, pixel_align(height)))
        self.set_window_size(aligned)

    # setRect(mode, Rect)
    def set_rect(self, mode: Mode, left: float, top: float, right: float, bottom: float) -> None:
        mode = self.inherited_metrics_mode() if mode is Mode.INHERITED else mode
        if mode is Mode.ABSOLUTE:
            left, top = pixel_align(left), pixel_align(top)
            right, bottom = pixel_align(right), pixel_align(bottom)
            low = UVector2(UDim(0.0, left), UDim(0.0, top))
            high = UVector2(UDim(0.0, right), UDim(0.0, bottom))
        else:
            low = UVector2(UDim(left, 0.0), UDim(top, 0.0))
            high = UVector2(UDim(right, 0.0), UDim(bottom, 0.0))
        area = URect(low, high)
        self.set_window_area(area.low, area.size())

    # setMinimumSize, setMaximumSize
    def set_minimum_size(self, width: float, height: float) -> None:
        self.set_window_min_size(self.limit_vector(width, height))

    def set_maximum_size(self, width: float, height: float) -> None:
        self.set_window_max_size(self.limit_vector(width, height))

    def limit_vector(self, width: float, height: float) -> UVector2:
        if self.metrics_mode() is Mode.ABSOLUTE:
            return UVector2(UDim(0.0, pixel_align(width)), UDim(0.0, pixel_align(height)))
        return UVector2(UDim(width, 0.0), UDim(height, 0.0))

    # setWindowArea, setWindowPosition, setWindowXPosition ... setWindowMaxSize, setWindowMinSize
    def set_window_area(self, position: UVector2, size: UVector2) -> None:
        self.set_window_area_impl(position, size, False, True)

    def set_window_position(self, position: UVector2) -> None:
        self.set_window_area_impl(position, self.area.size(), False, True)

    def set_window_x_position(self, x: UDim) -> None:
        position = UVector2(x, self.area.low.y)
        self.set_window_area_impl(position, self.area.size(), False, True)

    def set_window_y_position(self, y: UDim) -> None:
        position = UVector2(self.area.low.x, y)
        self.set_window_area_impl(position, self.area.size(), False, True)

    def set_window_size(self, size: UVector2) -> None:
        self.set_window_area_impl(self.area.low, size, False, True)

    def set_window_width(self, width: UDim) -> None:
        size = UVector2(width, self.area.size().y)
        self.set_window_area_impl(self.area.low, size, False, True)

    def set_window_height(self, height: UDim) -> None:
        size = UVector2(self.area.size().x, height)
        self.set_window_area_impl(self.area.low, size, False, True)

    def set_window_max_size(self, size: UVector2) -> None:
        self.max_size = size
        self.set_window_area(self.area.low, self.area.size())

    def set_window_min_size(self, size: UVector2) -> None:
        self.min_size = size
        self.set_window_area(self.area.low, self.area.size())

    # setWindowArea_impl: nơi duy nhất cỡ điểm ảnh được tính và lưu đệm.
    # Khác mã 2008: bản 2026 (RVA 0xa7e10) không kẹp cỡ vào [min, max]; min/max chỉ còn để thống kê.
    def set_window_area_impl(
        self, position: UVector2, size: UVector2, is_top_left_sizing: bool, is_firing_events: bool
    ) -> None:
        old_size = (self.pixel_width, self.pixel_height)
        display_width, display_height = self.environment.width, self.environment.height
        max_width, max_height = self.max_size.as_absolute(display_width, display_height)
        min_width, min_height = self.min_size.as_absolute(display_width, display_height)
        if self.zoom_mode is Mode.INHERITED:
            width, height = size.as_absolute(self.parent_width(), self.parent_height())
        else:
            width, height = size.as_absolute(ZOOM_WIDTH, ZOOM_HEIGHT)
        is_width_beyond = width < min_width or width > max_width
        is_height_beyond = height < min_height or height > max_height
        self.is_beyond_limits = is_width_beyond or is_height_beyond
        self.pixel_width, self.pixel_height = width, height
        self.area = self.area.with_size(size)
        is_sized = (width, height) != old_size
        if not is_top_left_sizing or is_sized:
            self.apply_position(position)
        if is_firing_events and is_sized:
            self.on_sized()

    # Phần chọn vị trí của setWindowArea_impl theo ZoomMode và HookMode.
    def apply_position(self, position: UVector2) -> None:
        if self.zoom_mode is Mode.INHERITED:
            self.area = self.area.with_position(position)
            return
        new_x, new_y = self.hook_x, self.hook_y
        if self.zoom_mode is Mode.RELATIVE:
            new_x = float32(self.hook_x * self.parent_width())
            new_y = float32(self.hook_y * self.parent_height())
        if self.hook_mode is Hook.NONE:
            return
        shift_x, shift_y = HOOK_SHIFT[self.hook_mode]
        new_x = float32(new_x - float32(self.pixel_width * shift_x))
        new_y = float32(new_y - float32(self.pixel_height * shift_y))
        hooked = UVector2(UDim(0.0, pixel_align(new_x)), UDim(0.0, pixel_align(new_y)))
        self.area = self.area.with_position(hooked)

    # onSized: báo mọi con rằng cha đổi cỡ.
    def on_sized(self) -> None:
        for child in tuple(self.children):
            child.on_parent_sized()
        self.last_set_size = NO_SET_SIZE

    # onParentSized: lan tiếp xuống con chỉ khi d_max có thành phần scale khác 0.
    def on_parent_sized(self) -> None:
        self.set_window_area_impl(self.area.low, self.area.size(), False, False)
        high = self.area.high
        if high.x.scale != 0.0 or high.y.scale != 0.0:
            self.on_sized()

    # addChild_impl
    def add_child(self, window: "Window") -> None:
        self.children.append(window)
        window.parent = self
        window.on_parent_sized()

    # Gốc trên màn hình: phần gốc của windowToScreen(Rect) chính là windowToScreen(Point(0, 0)).
    # Khác gốc: bỏ phép cộng cuối relativeToAbsolute(Point(0, 0)), vì PixelAligned(0 * cỡ) = 0.
    def screen_origin(self, parent_origin: Point) -> Point:
        base_x, base_y = parent_origin
        parent_width, parent_height = self.parent_width(), self.parent_height()
        x = origin_axis(base_x, self.absolute_x(), parent_width, self.pixel_width, self.horizontal)
        y = origin_axis(base_y, self.absolute_y(), parent_height, self.pixel_height, self.vertical)
        return x, y

    # getUnclippedPixelRect: (trái, trên, rộng, cao) sau khi cộng gốc.
    # Khác gốc: cạnh trái/trên bỏ PixelAligned(0 * cỡ) vì luôn bằng 0.
    def unclipped_pixel_rect(self, origin: Point) -> tuple[float, float, float, float]:
        origin_x, origin_y = origin
        right, bottom = self.pixel_width, self.pixel_height
        if self.metrics_mode() is Mode.RELATIVE:
            right, bottom = pixel_align(right), pixel_align(bottom)
        left = float32(0.0 + origin_x)
        top = float32(0.0 + origin_y)
        right = float32(right + origin_x)
        bottom = float32(bottom + origin_y)
        return left, top, float32(right - left), float32(bottom - top)


def origin_axis(
    base: float, absolute: float, parent_extent: float, own_extent: float, align: Align
) -> float:
    if align is Align.START:
        return float32(base + absolute)
    gap = float32(parent_extent - own_extent)
    shift = float32(gap * 0.5) if align is Align.CENTRE else gap
    return float32(base + float32(absolute + shift))


# Mốc: thuộc tính hình học


Handler = Callable[[Window, str], bool]


def udim_property(apply: Callable[[Window, UDim], None]) -> Handler:
    def handler(window: Window, text: str) -> bool:
        value, is_complete = parse_udim(text)
        apply(window, value)
        return is_complete
    return handler


def vector_property(apply: Callable[[Window, UVector2], None]) -> Handler:
    def handler(window: Window, text: str) -> bool:
        value, is_complete = parse_uvector2(text)
        apply(window, value)
        return is_complete
    return handler


def unified_area_rect(window: Window, text: str) -> bool:
    area, is_complete = parse_urect(text)
    window.set_window_area(area.low, area.size())
    return is_complete


# mode None: dùng chế độ đo của chính cửa sổ (Position, Size...); khác None: bản Relative/Absolute.
def point_property(mode: Mode | None) -> Handler:
    def handler(window: Window, text: str) -> bool:
        (x, y), is_complete = parse_point(text)
        window.set_position(window.metrics_mode() if mode is None else mode, x, y)
        return is_complete
    return handler


# Bản 2026 bỏ qua giá trị âm ở Size, AbsoluteSize, Width, Height, AbsoluteWidth, AbsoluteHeight
# (RVA 0xb4c90, 0xb4270, 0xb42b0); bản Relative* không chặn. Mã 2008 không chặn cái nào.
def is_rejected(mode: Mode | None, *values: float) -> bool:
    return mode is not Mode.RELATIVE and any(value < 0.0 for value in values)


def size_property(mode: Mode | None) -> Handler:
    def handler(window: Window, text: str) -> bool:
        (width, height), is_complete = parse_size(text)
        if is_rejected(mode, width, height):
            return is_complete
        window.set_size(window.metrics_mode() if mode is None else mode, width, height)
        return is_complete
    return handler


def rect_property(mode: Mode | None) -> Handler:
    def handler(window: Window, text: str) -> bool:
        (left, top, right, bottom), is_complete = parse_rect(text)
        effective = window.metrics_mode() if mode is None else mode
        window.set_rect(effective, left, top, right, bottom)
        return is_complete
    return handler


# Đặt một trục: trục còn lại đọc ngược từ UDim hiện có rồi ghi lại thành UDim thuần.
def x_position_property(mode: Mode | None) -> Handler:
    def handler(window: Window, text: str) -> bool:
        value, is_complete = parse_float(text)
        effective = window.metrics_mode() if mode is None else mode
        window.set_position(effective, value, window.y_in_mode(effective))
        return is_complete
    return handler


def y_position_property(mode: Mode | None) -> Handler:
    def handler(window: Window, text: str) -> bool:
        value, is_complete = parse_float(text)
        effective = window.metrics_mode() if mode is None else mode
        window.set_position(effective, window.x_in_mode(effective), value)
        return is_complete
    return handler


def width_property(mode: Mode | None) -> Handler:
    def handler(window: Window, text: str) -> bool:
        value, is_complete = parse_float(text)
        if is_rejected(mode, value):
            return is_complete
        effective = window.metrics_mode() if mode is None else mode
        window.set_size(effective, value, window.height_in_mode(effective))
        return is_complete
    return handler


def height_property(mode: Mode | None) -> Handler:
    def handler(window: Window, text: str) -> bool:
        value, is_complete = parse_float(text)
        if is_rejected(mode, value):
            return is_complete
        effective = window.metrics_mode() if mode is None else mode
        window.set_size(effective, window.width_in_mode(effective), value)
        return is_complete
    return handler


# Relative*Size nhận phân số của màn hình, Absolute*Size nhận điểm ảnh; đổi sang đơn vị của cửa sổ.
def size_limit_property(is_relative_value: bool, is_maximum: bool) -> Handler:
    def handler(window: Window, text: str) -> bool:
        (width, height), is_complete = parse_size(text)
        display_width, display_height = window.environment.width, window.environment.height
        mode = window.metrics_mode()
        if is_relative_value and mode is Mode.ABSOLUTE:
            width, height = float32(width * display_width), float32(height * display_height)
        if not is_relative_value and mode is Mode.RELATIVE:
            width, height = float32(width / display_width), float32(height / display_height)
        if is_maximum:
            window.set_maximum_size(width, height)
        else:
            window.set_minimum_size(width, height)
        return is_complete
    return handler


def parse_mode(text: str) -> Mode:
    if text == "Relative":
        return Mode.RELATIVE
    return Mode.ABSOLUTE if text == "Absolute" else Mode.INHERITED


def metrics_mode_property(window: Window, text: str) -> bool:
    window.metrics_setting = parse_mode(text)
    return True


def zoom_mode_property(window: Window, text: str) -> bool:
    window.zoom_mode = parse_mode(text)
    return True


def hook_mode_property(window: Window, text: str) -> bool:
    window.hook_mode = HOOK_NAMES.get(text, Hook.NONE)
    return True


def hook_position_property(window: Window, text: str) -> bool:
    (x, y), is_complete = parse_point(text)
    window.hook_x, window.hook_y = x, y
    return is_complete


def vertical_alignment_property(window: Window, text: str) -> bool:
    window.vertical = {"Centre": Align.CENTRE, "Bottom": Align.END}.get(text, Align.START)
    return True


def horizontal_alignment_property(window: Window, text: str) -> bool:
    window.horizontal = {"Centre": Align.CENTRE, "Right": Align.END}.get(text, Align.START)
    return True


HANDLERS: dict[str, Handler] = {
    "UnifiedAreaRect": unified_area_rect,
    "UnifiedPosition": vector_property(Window.set_window_position),
    "UnifiedXPosition": udim_property(Window.set_window_x_position),
    "UnifiedYPosition": udim_property(Window.set_window_y_position),
    "UnifiedSize": vector_property(Window.set_window_size),
    "UnifiedWidth": udim_property(Window.set_window_width),
    "UnifiedHeight": udim_property(Window.set_window_height),
    "UnifiedMinSize": vector_property(Window.set_window_min_size),
    "UnifiedMaxSize": vector_property(Window.set_window_max_size),
    "Position": point_property(None),
    "RelativePosition": point_property(Mode.RELATIVE),
    "AbsolutePosition": point_property(Mode.ABSOLUTE),
    "Size": size_property(None),
    "RelativeSize": size_property(Mode.RELATIVE),
    "AbsoluteSize": size_property(Mode.ABSOLUTE),
    "Rect": rect_property(None),
    "RelativeRect": rect_property(Mode.RELATIVE),
    "AbsoluteRect": rect_property(Mode.ABSOLUTE),
    "XPosition": x_position_property(None),
    "RelativeXPosition": x_position_property(Mode.RELATIVE),
    "AbsoluteXPosition": x_position_property(Mode.ABSOLUTE),
    "YPosition": y_position_property(None),
    "RelativeYPosition": y_position_property(Mode.RELATIVE),
    "AbsoluteYPosition": y_position_property(Mode.ABSOLUTE),
    "Width": width_property(None),
    "RelativeWidth": width_property(Mode.RELATIVE),
    "AbsoluteWidth": width_property(Mode.ABSOLUTE),
    "Height": height_property(None),
    "RelativeHeight": height_property(Mode.RELATIVE),
    "AbsoluteHeight": height_property(Mode.ABSOLUTE),
    "RelativeMinSize": size_limit_property(True, False),
    "RelativeMaxSize": size_limit_property(True, True),
    "AbsoluteMinSize": size_limit_property(False, False),
    "AbsoluteMaxSize": size_limit_property(False, True),
    "MetricsMode": metrics_mode_property,
    "ZoomMode": zoom_mode_property,
    "HookMode": hook_mode_property,
    "HookPosition": hook_position_property,
    "VerticalAlignment": vertical_alignment_property,
    "HorizontalAlignment": horizontal_alignment_property,
}


# Mốc: nạp layout như GUILayout_xmlHandler


def apply_property(window: Window, element: Element, tally: Tally) -> None:
    name = element.get("Name", "")
    value = element.get("Value", "")
    handler = HANDLERS.get(name)
    tally.properties += 1
    if handler is None:
        tally.other[name] += 1
        return
    tally.handled[name] += 1
    if handler(window, value):
        return
    tally.partial[name] += 1
    if len(tally.partial_examples) < LIST_LIMIT:
        label = window.environment.layout_label
        tally.partial_examples.append(f"{label}:{window.name}:{name}={value!r}")


def load_child(
    child: Element, window: Window, environment: Environment, windows: list[Window]
) -> None:
    if child.tag == "Property":
        apply_property(window, child, environment.tally)
    elif child.tag == "Window":
        load_window(child, window, environment, windows)


def load_window(
    element: Element, parent: Window | None, environment: Environment, windows: list[Window]
) -> Window:
    window = environment.create_window(element.get("Type", ""), element.get("Name", ""))
    windows.append(window)
    if parent is not None:
        parent.add_child(window)
    for child in element:
        load_child(child, window, environment, windows)
    return window


@dataclass(slots=True)
class WindowRect:
    name: str
    left: float
    top: float
    width: float
    height: float
    is_beyond_limits: bool


def origin_of(window: Window, cache: dict[Window, Point]) -> Point:
    cached = cache.get(window)
    if cached is not None:
        return cached
    parent_origin = (0.0, 0.0) if window.parent is None else origin_of(window.parent, cache)
    origin = window.screen_origin(parent_origin)
    cache[window] = origin
    return origin


# Layout có thể có nhiều cửa sổ gốc; client chỉ gắn d_root (cửa sổ gốc cuối) vào tấm nền.
def simulate_layout(layout_root: Element, environment: Environment) -> list[WindowRect]:
    sheet = environment.create_sheet()
    tops = [layout_root] if layout_root.tag == "Window" else list(layout_root.findall("Window"))
    windows: list[Window] = []
    attached: Window | None = None
    for element in tops:
        attached = load_window(element, None, environment, windows)
    if attached is not None:
        sheet.add_child(attached)
    cache: dict[Window, Point] = {}
    rects = []
    for window in windows:
        left, top, width, height = window.unclipped_pixel_rect(origin_of(window, cache))
        rects.append(WindowRect(window.name, left, top, width, height, window.is_beyond_limits))
    return rects


# Mốc: đọc XML gốc


@dataclass(slots=True)
class ParsedXml:
    root: Element
    codec: str


def declared_encoding(data: bytes) -> str | None:
    match = DECLARED_ENCODING.match(data[:256])
    return None if match is None else match.group(1).decode("ascii", "replace").lower()


# Theo BOM trước; không BOM thì UTF-8 chặt, rồi encoding khai báo, rồi GBK.
def decode_text(data: bytes, label: str) -> tuple[str, str]:
    if data.startswith((codecs.BOM_UTF16_LE, codecs.BOM_UTF16_BE)):
        choices: tuple[str, ...] = ("utf-16",)
    else:
        declared = declared_encoding(data)
        choices = ("utf-8-sig",) + ((declared,) if declared else ()) + ("gbk",)
    for codec in choices:
        try:
            return data.decode(codec), codec
        except (UnicodeDecodeError, LookupError):
            continue
    raise UiError(f"{label}: không giải mã được bằng {', '.join(choices)}")


def utf8_declaration(match: re.Match) -> str:
    quote = match.group(2)
    return f"{match.group(1)}{quote}utf-8{quote}"


def parse_xml_file(path: str, label: str) -> ParsedXml:
    with open(path, "rb") as stream:
        data = stream.read()
    text, codec = decode_text(data, label)
    head = DECLARATION.match(text)
    if head is not None:
        text = ENCODING_ATTRIBUTE.sub(utf8_declaration, head.group(0)) + text[head.end():]
    try:
        return ParsedXml(ElementTree.fromstring(text.encode("utf-8")), codec)
    except ElementTree.ParseError as error:
        raise UiError(f"{label}: XML hỏng: {error}") from error


class RawTree:
    # Chỉ lập chỉ mục layout và scheme dưới <raw>/Interface; tra không phân biệt hoa/thường.
    def __init__(self, raw_root: str):
        self.root = os.path.join(raw_root, INTERFACE)
        if not os.path.isdir(self.root):
            raise UiError(f"không có thư mục {self.root}")
        self.files: dict[str, str] = {}
        for base, folders, names in os.walk(self.root):
            folders.sort()
            for name in sorted(names):
                if name.lower().endswith((LAYOUT_SUFFIX, SCHEME_SUFFIX)):
                    relative = os.path.relpath(os.path.join(base, name), self.root)
                    relative = relative.replace(os.sep, "/")
                    self.files.setdefault(relative.lower(), relative)

    def find(self, relative: str) -> str | None:
        return self.files.get(relative.replace("\\", "/").lower())

    def path(self, relative: str) -> str:
        return os.path.join(self.root, *relative.split("/"))

    # Tệp theo đuôi; có folder thì chỉ lấy tệp nằm thẳng trong thư mục đó.
    def matching(self, suffix: str, folder: str | None = None) -> list[str]:
        found = [real for key, real in self.files.items() if key.endswith(suffix)]
        if folder is not None:
            prefix = folder.lower() + "/"
            found = [real for real in found if real.lower().startswith(prefix)]
            found = [real for real in found if real.count("/") == 1]
        return sorted(found)


# FalagardMapping: kiểu trong layout -> kiểu đích; cần để biết kiểu nào thực chất là DefaultWindow.
def read_type_targets(tree: RawTree) -> dict[str, str]:
    targets: dict[str, str] = {}
    for relative in tree.matching(SCHEME_SUFFIX, SCHEMA):
        parsed = parse_xml_file(tree.path(relative), relative)
        for element in parsed.root.iter("FalagardMapping"):
            targets[element.get("WindowType", "")] = element.get("TargetType", "")
    return targets


def collected_layouts(collected_root: str) -> list[str]:
    root = os.path.join(collected_root, INTERFACE)
    if not os.path.isdir(root):
        raise UiError(f"không có thư mục {root}")
    found = []
    for base, _folders, names in os.walk(root):
        for name in names:
            if name.lower().endswith(LAYOUT_SUFFIX):
                relative = os.path.relpath(os.path.join(base, name), root)
                found.append(relative.replace(os.sep, "/"))
    return sorted(found)


def new_environment(width: int, height: int, targets: dict[str, str]) -> Environment:
    return Environment(float(width), float(height), targets, Tally())


# Mốc: tính golden


@dataclass(slots=True)
class LayoutRun:
    layout: str
    raw_path: str
    root: Element
    rects: dict[tuple[int, int], list[WindowRect]] = field(default_factory=dict)


def load_runs(tree: RawTree, layouts: list[str]) -> list[LayoutRun]:
    runs = []
    for layout in layouts:
        real = tree.find(layout)
        if real is None:
            raise UiError(f"không thấy layout gốc cho {layout} trong {tree.root}")
        parsed = parse_xml_file(tree.path(real), real)
        runs.append(LayoutRun(layout, real, parsed.root))
    return runs


def compute_runs(runs: list[LayoutRun], targets: dict[str, str]) -> list[Tally]:
    tallies = []
    for width, height in SCREENS:
        environment = new_environment(width, height, targets)
        ALIGN_QUIRKS.clear()
        for run in runs:
            environment.layout_label = run.layout
            run.rects[(width, height)] = simulate_layout(run.root, environment)
        environment.tally.align_negative = ALIGN_QUIRKS["negative"]
        environment.tally.align_near_half = ALIGN_QUIRKS["near_half"]
        tallies.append(environment.tally)
    return tallies


@dataclass(slots=True)
class NameReport:
    duplicates: dict[str, list[str]]
    same_layout: int
    cross_layout: int


def analyse_names(per_layout: list[tuple[str, list[str]]]) -> NameReport:
    where: dict[str, list[str]] = defaultdict(list)
    for layout, names in per_layout:
        for name in names:
            where[name].append(layout)
    duplicates = {name: layouts for name, layouts in where.items() if name and len(layouts) > 1}
    same_layout = sum(1 for layouts in duplicates.values() if len(set(layouts)) < len(layouts))
    cross_layout = sum(1 for layouts in duplicates.values() if len(set(layouts)) > 1)
    return NameReport(duplicates, same_layout, cross_layout)


# Mốc: ghi bảng TSV


def format_number(value: float) -> str:
    text = f"{value:.4f}"
    return "0.0000" if text == "-0.0000" else text


def golden_comment(layout_count: int) -> str:
    return (
        "# ui_rects.tsv: ô chữ nhật điểm ảnh (gốc trái trên) của mọi <Window> khai trong layout; "
        "screen_w, screen_h = cỡ màn hình; layout = đường dẫn dưới Interface/; "
        "window = thuộc tính Name nguyên văn; x, y, w, h = getUnclippedPixelRect của CEGUI 0.4.1 "
        f"bản TLBB (%.4f); is_duplicate = 1 nếu tên xuất hiện nhiều lần trong {layout_count} "
        "layout này. Sinh bằng TOOLS/content/ui_rects.py từ _raw/Interface (layout gốc); sửa tay "
        "sẽ mất ở lượt sau"
    )


# Bảng theo tsv.hpp: dòng # là chú thích, dòng đầu còn lại là tên cột, ô không chứa tab/xuống dòng.
def golden_rows(
    run: LayoutRun, screen: tuple[int, int], duplicates: dict[str, list[str]]
) -> list[str]:
    width, height = screen
    layout = CELL_BREAKS.sub(" ", run.layout)
    rows = []
    for rect in run.rects[screen]:
        name = CELL_BREAKS.sub(" ", rect.name)
        numbers = [format_number(v) for v in (rect.left, rect.top, rect.width, rect.height)]
        flag = "1" if rect.name in duplicates else "0"
        rows.append("\t".join([str(width), str(height), layout, name, *numbers, flag]))
    return rows


def build_golden(runs: list[LayoutRun], duplicates: dict[str, list[str]]) -> bytes:
    lines = [golden_comment(len(runs)), "\t".join(COLUMNS)]
    for screen in SCREENS:
        for run in runs:
            lines += golden_rows(run, screen, duplicates)
    return ("\n".join(lines) + "\n").encode("utf-8")


def is_same(path: str, data: bytes) -> bool:
    if not os.path.isfile(path) or os.path.getsize(path) != len(data):
        return False
    with open(path, "rb") as stream:
        return stream.read() == data


def write_atomic(path: str, data: bytes) -> bool:
    if is_same(path, data):
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    temporary = path + ".tmp"
    try:
        with open(temporary, "wb") as stream:
            stream.write(data)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)
    return True


# Mốc: báo cáo


def limited(items: list[str], limit: int = LIST_LIMIT) -> str:
    shown = items[:limit]
    rest = len(items) - len(shown)
    return ", ".join(shown) + (f" ... còn {rest}" if rest else "")


def classify(rect: WindowRect, width: int, height: int) -> list[str]:
    values = (rect.left, rect.top, rect.width, rect.height)
    right, bottom = rect.left + rect.width, rect.top + rect.height
    flags = []
    if not all(math.isfinite(value) for value in values):
        flags.append(ANOMALY_NAMES[0])
    if rect.width < 0 or rect.height < 0:
        flags.append(ANOMALY_NAMES[1])
    if rect.width == 0 or rect.height == 0:
        flags.append(ANOMALY_NAMES[2])
    if right <= 0 or bottom <= 0 or rect.left >= width or rect.top >= height:
        flags.append(ANOMALY_NAMES[3])
    if rect.left < 0 or rect.top < 0 or right > width or bottom > height:
        flags.append(ANOMALY_NAMES[4])
    if rect.is_beyond_limits:
        flags.append(ANOMALY_NAMES[5])
    return flags


def anomaly_counts(rects: list[WindowRect], width: int, height: int) -> Counter:
    counts: Counter = Counter()
    for rect in rects:
        counts.update(classify(rect, width, height))
    return counts


def anomaly_text(counts: Counter, tally: Tally) -> str:
    parts = [f"{name} {counts[name]}" for name in ANOMALY_NAMES]
    near, negative = tally.align_near_half, tally.align_negative
    parts.append(f"lần PixelAligned nhận số âm, lệch làm tròn thường {negative}")
    parts.append(f"lần PixelAligned sát .5 không đúng .5, dễ lật theo nhiễu {near}")
    return ", ".join(parts)


def screen_lines(runs: list[LayoutRun], tallies: list[Tally]) -> list[str]:
    lines = []
    for screen, tally in zip(SCREENS, tallies):
        width, height = screen
        rects = [rect for run in runs for rect in run.rects[screen]]
        counts = anomaly_counts(rects, width, height)
        text = anomaly_text(counts, tally)
        lines.append(f"  {width}x{height}: {len(rects)} cửa sổ; {text}")
    return lines


def root_lines(runs: list[LayoutRun]) -> list[str]:
    lines = []
    for run in runs:
        rects = run.rects[SCREENS[0]]
        if not rects:
            continue
        first = rects[0]
        place = f"x={first.left:.2f} y={first.top:.2f} w={first.width:.2f} h={first.height:.2f}"
        lines.append(f"  {run.layout} [{first.name}]: {place}")
    return lines


def name_lines(report: NameReport) -> list[str]:
    total = sum(len(layouts) for layouts in report.duplicates.values())
    lines = [
        f"Tên trùng: {len(report.duplicates)} tên ({total} cửa sổ); trong cùng layout "
        f"{report.same_layout}, giữa các layout {report.cross_layout} "
        "(CEGUI thật ném AlreadyExistsException khi trùng tên và huỷ cả layout đang nạp)"
    ]
    for name, layouts in sorted(report.duplicates.items())[:NAME_LIST_LIMIT]:
        counted = sorted(Counter(layouts).items())
        where = ", ".join(f"{layout} x{count}" for layout, count in counted)
        lines.append(f"  {name}: {where}")
    return lines


def property_lines(tally: Tally) -> list[str]:
    handled = ", ".join(f"{name} {count}" for name, count in tally.handled.most_common())
    hinted = {name: count for name, count in tally.other.items() if GEOMETRY_HINT.search(name)}
    ranked = sorted(hinted.items(), key=lambda pair: -pair[1])
    unknown = ", ".join(f"{name} {count}" for name, count in ranked) or "không"
    partial = ", ".join(f"{name} {count}" for name, count in tally.partial.most_common()) or "không"
    lines = [
        f"Thuộc tính: {tally.properties} lần; hình học đã xử lý {sum(tally.handled.values())}: "
        f"{handled}",
        f"  tên giống hình học nhưng không thuộc Window cốt lõi, bỏ qua {sum(hinted.values())}: "
        f"{unknown}",
        f"  giá trị chỉ đọc được một phần (phần thiếu để 0): {partial}",
    ]
    if tally.partial_examples:
        lines.append(f"  ví dụ: {limited(tally.partial_examples)}")
    return lines


def golden_report(
    runs: list[LayoutRun], tallies: list[Tally], names: NameReport, outcome: str, elapsed: float
) -> None:
    first = tallies[0]
    case_fixed = sum(1 for run in runs if run.raw_path != run.layout)
    unknown = limited([f"{name} x{count}" for name, count in first.unknown_types.most_common()])
    lines = [
        f"Layout: {len(runs)} (đổi hoa/thường khi tra bản gốc {case_fixed}), "
        f"cửa sổ mỗi cỡ màn hình: {first.windows}, dòng golden: {first.windows * len(SCREENS)}"
    ]
    lines += name_lines(names) + property_lines(first)
    lines.append(
        f"Cửa sổ không tên: {first.nameless}; thuộc lớp tự đổi cỡ lúc chạy: {first.self_sizing}; "
        f"kiểu lạ: {unknown or 'không'}"
    )
    lines.append("Kiểm tính hợp lý theo cỡ màn hình:")
    lines += screen_lines(runs, tallies)
    lines.append(f"Cửa sổ gốc từng layout ở {SCREENS[0][0]}x{SCREENS[0][1]}:")
    lines += root_lines(runs)
    lines += [outcome, f"Thời gian: {elapsed:.1f} s"]
    print("\n".join(lines))


# Mốc: thống kê toàn bộ raw


@dataclass(slots=True)
class RawSurvey:
    layouts: int = 0
    failed: list[str] = field(default_factory=list)
    non_layout_root: list[str] = field(default_factory=list)
    codecs: Counter = field(default_factory=Counter)
    anomalies: Counter = field(default_factory=Counter)


def survey_layouts(
    tree: RawTree, targets: dict[str, str]
) -> tuple[RawSurvey, Tally, list[tuple[str, list[str]]]]:
    width, height = STATISTICS_SCREEN
    environment = new_environment(width, height, targets)
    survey = RawSurvey()
    names: list[tuple[str, list[str]]] = []
    ALIGN_QUIRKS.clear()
    for relative in tree.matching(LAYOUT_SUFFIX):
        survey.layouts += 1
        try:
            parsed = parse_xml_file(tree.path(relative), relative)
        except UiError as error:
            survey.failed.append(str(error))
            continue
        survey.codecs[parsed.codec] += 1
        if parsed.root.tag != "GUILayout":
            survey.non_layout_root.append(relative)
        environment.layout_label = relative
        rects = simulate_layout(parsed.root, environment)
        names.append((relative, [rect.name for rect in rects]))
        survey.anomalies.update(anomaly_counts(rects, width, height))
    environment.tally.align_negative = ALIGN_QUIRKS["negative"]
    environment.tally.align_near_half = ALIGN_QUIRKS["near_half"]
    return survey, environment.tally, names


def survey_report(survey: RawSurvey, tally: Tally, names: NameReport, elapsed: float) -> None:
    width, height = STATISTICS_SCREEN
    codecs_text = ", ".join(f"{codec} {count}" for codec, count in survey.codecs.most_common())
    unknown = limited([f"{name} x{count}" for name, count in tally.unknown_types.most_common()])
    non_layout = limited(survey.non_layout_root) or "không"
    lines = [
        f"Layout gốc: {survey.layouts}, lỗi parse {len(survey.failed)}, root không phải GUILayout "
        f"{len(survey.non_layout_root)}: {non_layout}; mã hoá: {codecs_text}",
        f"Cửa sổ: {tally.windows} (không tên {tally.nameless}, thuộc lớp tự đổi cỡ lúc chạy "
        f"{tally.self_sizing})",
        f"Kiểu không có trong FalagardMapping, DefaultWindow hay Falagard/*: "
        f"{len(tally.unknown_types)}: {unknown or 'không'}",
    ]
    lines += property_lines(tally) + name_lines(names)
    text = anomaly_text(survey.anomalies, tally)
    lines.append(f"Kiểm tính hợp lý ở {width}x{height}: {text}")
    if survey.failed:
        lines.append(f"Lỗi parse: {limited(survey.failed)}")
    lines += ["(--all-raw chỉ thống kê, không ghi golden)", f"Thời gian: {elapsed:.1f} s"]
    print("\n".join(lines))


# Mốc: tự kiểm bằng ca tính tay


@dataclass(slots=True)
class Case:
    title: str
    screen: tuple[int, int]
    xml: str
    expected: dict[str, tuple[float, float, float, float]]


POSITION = "UnifiedPosition"
SIZE = "UnifiedSize"


def window_xml(
    name: str, properties: list[tuple[str, str]], inner: str = "", type_name: str = "DefaultWindow"
) -> str:
    lines = "".join(f'<Property Name="{key}" Value="{value}"/>' for key, value in properties)
    return f'<Window Type="{type_name}" Name="{name}">{lines}{inner}</Window>'


def layout_xml(inner: str) -> str:
    return f"<GUILayout>{window_xml('Root', [], inner)}</GUILayout>"


def udim_case() -> str:
    properties = [(POSITION, "{{0.5,10},{0.25,-4}}"), (SIZE, "{{0.5,-20},{0.5,30}}")]
    return f"<GUILayout>{window_xml('A', properties)}</GUILayout>"


def half_pixel_case() -> str:
    first = window_xml("C1", [(POSITION, "{{0.5,0},{0.5,0}}"), (SIZE, "{{0.5,0},{0.5,0}}")])
    second = window_xml("C2", [(POSITION, "{{0,0.5},{0,0.4}}"), (SIZE, "{{0,10.25},{0,5.75}}")])
    return layout_xml(first + second)


def nested_case() -> str:
    grandchild = window_xml("G", [(POSITION, "{{0.5,0},{0.5,-3}}"), (SIZE, "{{1,-50},{0,40}}")])
    child_properties = [(POSITION, "{{0.1,5},{0.1,5}}"), (SIZE, "{{0.5,0},{0.5,0}}")]
    child = window_xml("C", child_properties, grandchild)
    root = window_xml("R", [(POSITION, "{{0,10},{0,20}}"), (SIZE, "{{0.5,0},{0.5,0}}")], child)
    return f"<GUILayout>{root}</GUILayout>"


def legacy_case() -> str:
    first_properties = [("AbsolutePosition", "x:10.5 y:20.4"), ("AbsoluteSize", "w:100.5 h:50.5")]
    first = window_xml("A1", first_properties)
    second = window_xml("A2", [(POSITION, "{{0,10.5},{0,20.4}}"), (SIZE, "{{0,100.5},{0,50.5}}")])
    third = window_xml("A3", [("Position", "x:0.5 y:0.25"), ("Size", "w:0.25 h:0.5")])
    return layout_xml(first + second + third)


def order_case() -> str:
    mode_first = [("MetricsMode", "Absolute"), ("Position", "x:10 y:20"), ("Size", "w:100 h:50")]
    mode_last = [("Position", "x:10 y:20"), ("Size", "w:0.1 h:0.1"), ("MetricsMode", "Absolute")]
    overridden = [
        (POSITION, "{{0,10},{0,20}}"), ("UnifiedXPosition", "{0,50}"),
        ("UnifiedYPosition", "{0,70}"), (SIZE, "{{0,5},{0,5}}"),
    ]
    inner = window_xml("E1", mode_first) + window_xml("E2", mode_last)
    return layout_xml(inner + window_xml("E3", overridden))


def alignment_case() -> str:
    centred = [(SIZE, "{{0,500},{0,100}}"), ("HorizontalAlignment", "Centre"),
               ("VerticalAlignment", "Bottom")]
    right = [(POSITION, "{{0,-10},{0,5}}"), (SIZE, "{{0,200},{0,50}}"),
             ("HorizontalAlignment", "Right")]
    return layout_xml(window_xml("A", centred) + window_xml("B", right))


def limits_case() -> str:
    windows = [
        window_xml("L1", [(SIZE, "{{2,0},{0,50}}")]),
        window_xml("L2", [(SIZE, "{{0,500},{0,100}}"), ("UnifiedMaxSize", "{{0,300},{1,0}}")]),
        window_xml("L3", [(SIZE, "{{0,-5},{0,10}}")]),
        window_xml("L4", [("RelativeMaxSize", "w:0.5 h:0.5"), (SIZE, "{{1,0},{1,0}}")]),
        window_xml("L5", [("AbsoluteMaxSize", "w:300 h:100"), (SIZE, "{{0,500},{0,500}}")]),
    ]
    return layout_xml("".join(windows))


# Bản 2026 bỏ qua Size, AbsoluteSize, Width, AbsoluteWidth... khi có thành phần âm; bản Relative*
# thì không chặn.
def negative_case() -> str:
    base = (SIZE, "{{0,100},{0,50}}")
    windows = [
        window_xml("N1", [base, ("AbsoluteSize", "w:-10 h:20")]),
        window_xml("N2", [base, ("Size", "w:0.5 h:-0.5")]),
        window_xml("N3", [base, ("AbsoluteWidth", "-3")]),
        window_xml("N4", [base, ("RelativeSize", "w:-0.5 h:0.5")]),
    ]
    return layout_xml("".join(windows))


# Ô nhớ setSize của bản 2026: lời gọi cùng giá trị với lời gọi trước bị bỏ qua, trừ khi onSized đã
# chạy ở giữa. R1 không đổi cỡ điểm ảnh ở AbsoluteSize nên Size sau đó bị bỏ; R2 thì có đổi.
def repeat_case() -> str:
    kept = [(SIZE, "{{0,100},{0,50}}"), ("AbsoluteSize", "w:100 h:50"), ("Size", "w:100 h:50")]
    applied = [("AbsoluteSize", "w:100 h:50"), ("Size", "w:100 h:50")]
    return layout_xml(window_xml("R1", kept) + window_xml("R2", applied))


def defaults_case() -> str:
    inner = window_xml("D", []) + window_xml("T", [], type_name="TLBB_Unknown")
    parent = window_xml("P", [(POSITION, "{{0,30},{0,40}}"), (SIZE, "{{0,400},{0,200}}")], inner)
    return f"<GUILayout>{parent}</GUILayout>"


def later_case() -> str:
    child = window_xml("B", [(SIZE, "{{0.5,0},{0.5,0}}")])
    late = f'<Property Name="{SIZE}" Value="{{{{0,400}},{{0,200}}}}"/>'
    return f"<GUILayout>{window_xml('P2', [], child + late)}</GUILayout>"


def messy_case() -> str:
    broken = [(POSITION, "{{0.5,10}"), (SIZE, "{{0,10},{0,10}}"), ("Foo", "bar")]
    negative = [(POSITION, "{{-0.5,0},{0,0}}"), (SIZE, "{{0,10},{0,10}}")]
    return layout_xml(window_xml("M1", broken) + window_xml("M2", negative))


def zoom_case() -> str:
    absolute = [("ZoomMode", "Absolute"), ("HookMode", "Center"), ("HookPosition", "x:500 y:300"),
                (SIZE, "{{0,100},{0,50}}")]
    relative = [("ZoomMode", "Relative"), ("HookMode", "LeftTop"), ("HookPosition", "x:0.5 y:0.5"),
                (SIZE, "{{0,100},{0,50}}")]
    return layout_xml(window_xml("Z1", absolute) + window_xml("Z2", relative))


def single_axis_case() -> str:
    width = [(POSITION, "{{0,10},{0,20}}"), (SIZE, "{{0,100},{0,50}}"), ("Width", "0.5")]
    absolute_x = [(POSITION, "{{0,10},{0,20}}"), (SIZE, "{{0,5},{0,5}}"),
                  ("AbsoluteXPosition", "33.4")]
    rect = [("Rect", "l:0.125 t:0.25 r:0.625 b:0.75")]
    area = [("UnifiedAreaRect", "{{0.25,10},{0,20},{0.75,10},{0,70}}")]
    inner = window_xml("W1", width) + window_xml("W2", absolute_x)
    return layout_xml(inner + window_xml("W3", rect) + window_xml("W4", area))


def self_test_cases() -> list[Case]:
    return [
        Case("udim_1024x768", (1024, 768), udim_case(), {"A": (522, 188, 492, 414)}),
        Case("udim_1280x720", (1280, 720), udim_case(), {"A": (650, 176, 620, 390)}),
        Case("half_pixel_and_fraction", (1001, 601), half_pixel_case(),
             {"C1": (501, 301, 501, 301), "C2": (0.5, 0.4, 10, 6)}),
        Case("nested_three_levels", (1000, 600), nested_case(),
             {"R": (10, 20, 500, 300), "C": (65, 55, 250, 150), "G": (190, 127, 200, 40)}),
        Case("absolute_vs_unified", (1000, 600), legacy_case(),
             {"A1": (11, 20, 101, 51), "A2": (10.5, 20.4, 101, 51), "A3": (500, 150, 250, 300)}),
        Case("property_order", (1000, 600), order_case(),
             {"E1": (10, 20, 100, 50), "E2": (10000, 12000, 100, 60), "E3": (50, 70, 5, 5)}),
        Case("alignment", (1001, 601), alignment_case(),
             {"A": (250.5, 501, 500, 100), "B": (791, 5, 200, 50)}),
        Case("min_max_not_clamped", (1000, 600), limits_case(),
             {"L1": (0, 0, 2000, 50), "L2": (0, 0, 500, 100), "L3": (0, 0, -4, 10),
              "L4": (0, 0, 1000, 600), "L5": (0, 0, 500, 500)}),
        Case("negative_size_ignored", (1000, 600), negative_case(),
             {"N1": (0, 0, 100, 50), "N2": (0, 0, 100, 50), "N3": (0, 0, 100, 50),
              "N4": (0, 0, -498, 300)}),
        Case("repeated_set_size", (1000, 600), repeat_case(),
             {"R1": (0, 0, 100, 50), "R2": (0, 0, 100000, 30000)}),
        Case("default_size_and_unknown_type", (1000, 600), defaults_case(),
             {"P": (30, 40, 400, 200), "D": (30, 40, 400, 200), "T": (30, 40, 0, 0)}),
        Case("parent_sized_after_child", (1000, 600), later_case(),
             {"P2": (0, 0, 400, 200), "B": (0, 0, 200, 100)}),
        Case("partial_value_and_negative_scale", (1000, 600), messy_case(),
             {"M1": (510, 0, 10, 10), "M2": (-499, 0, 10, 10)}),
        Case("zoom_and_hook", (1000, 600), zoom_case(),
             {"Z1": (450, 275, 100, 50), "Z2": (500, 300, 100, 50)}),
        Case("single_axis_and_rect_properties", (1000, 600), single_axis_case(),
             {"W1": (10, 20, 500, 50), "W2": (33, 20, 5, 5), "W3": (125, 150, 500, 300),
              "W4": (260, 20, 500, 50)}),
    ]


def run_case(case: Case) -> tuple[bool, str]:
    width, height = case.screen
    environment = new_environment(width, height, {})
    rects = simulate_layout(ElementTree.fromstring(case.xml), environment)
    actual = {rect.name: (rect.left, rect.top, rect.width, rect.height) for rect in rects}
    problems = []
    for name, expected in case.expected.items():
        got = actual.get(name)
        if got is None or any(abs(a - b) > TOLERANCE for a, b in zip(got, expected)):
            problems.append(f"{name}: mong đợi {expected}, thực tế {got}")
    return not problems, "; ".join(problems)


# PixelAligned theo (float)(int)(x + 0.5f); mong đợi viết cứng từ phép tính tay.
ALIGN_TABLE = (
    (2.5, 3.0), (2.4999, 2.0), (0.5, 1.0), (0.0, 0.0), (-0.5, 0.0), (-1.5, -1.0), (-2.0, -1.0),
    (-0.3, 0.0), (-511.9, -511.0), (1023.5, 1024.0),
)
SCAN_TABLE = (
    (" {{%f,%f},{%f,%f}}", "{{0.5,10},{0.25,-4}}", 4, True),
    (" {{%f,%f},{%f,%f}}", "{{0.5,10}", 4, False),
    (" {%f,%f}", "{1.0, -383}", 2, True),
    (" x:%f y:%f", "x:2  y:272", 2, True),
    (" w:%f h:%f", "", 2, False),
)


def run_helper_checks() -> list[tuple[str, bool, str]]:
    results = []
    for value, expected in ALIGN_TABLE:
        got = pixel_align(value)
        detail = f"mong đợi {expected}, thực tế {got}"
        results.append((f"pixel_align({value})", got == expected, detail))
    for template, text, count, is_complete in SCAN_TABLE:
        scanned = scan_floats(text, template, count)
        detail = f"giá trị {scanned.values}"
        results.append((f"scan {text!r}", scanned.is_complete == is_complete, detail))
    return results + run_text_checks()


# Tên trùng, dò bảng mã và định dạng số: không có ca nào trong dữ liệu thật của 21 layout.
def run_text_checks() -> list[tuple[str, bool, str]]:
    report = analyse_names([("a.xml", ["x", "y", "x", ""]), ("b.xml", ["y", "z", ""])])
    is_names_right = set(report.duplicates) == {"x", "y"}
    is_names_right = is_names_right and report.same_layout == 1 and report.cross_layout == 1
    chinese = '<a n="中文"/>'
    codec_cases = (
        ("utf-16", "<a/>".encode("utf-16")),
        ("utf-8-sig", codecs.BOM_UTF8 + "<a/>".encode("utf-8")),
        ("utf-8-sig", chinese.encode("utf-8")),
        ("gbk", chinese.encode("gbk")),
        ("gb2312", ('<?xml version="1.0" encoding="gb2312"?>' + chinese).encode("gb2312")),
    )
    results = [("analyse_names", is_names_right, f"{report}")]
    for expected, data in codec_cases:
        _text, codec = decode_text(data, "thử")
        results.append((f"decode_text {expected}", codec == expected, f"thực tế {codec}"))
    zero_text, half_text = format_number(-0.0), format_number(1.5)
    is_format_right = zero_text == "0.0000" and half_text == "1.5000"
    results.append(("format_number", is_format_right, f"{zero_text} {half_text}"))
    tenth, odd = float32(0.1), float32(16777217.0)
    is_single_right = tenth == 0.10000000149011612 and odd == 16777216.0
    results.append(("float32", is_single_right, f"{tenth!r} {odd!r}"))
    return results


def self_test() -> int:
    results = run_helper_checks()
    for case in self_test_cases():
        is_passed, detail = run_case(case)
        results.append((case.title, is_passed, detail))
    for title, is_passed, detail in results:
        suffix = "" if is_passed else f": {detail}"
        print(f"{'PASS' if is_passed else 'FAIL'} {title}{suffix}")
    passed = sum(1 for _title, is_passed, _detail in results if is_passed)
    print(f"Tự kiểm: {passed}/{len(results)} PASS")
    return 0 if passed == len(results) else 1


# Mốc: dòng lệnh


class VietnameseParser(argparse.ArgumentParser):
    def error(self, message: str):
        print(f"Cách dùng: {USAGE}", file=sys.stderr)
        self.exit(2, f"Lỗi tham số: {message}\n")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = VietnameseParser(prog="ui_rects.py", usage=USAGE, description=DESCRIPTION)
    parser.add_argument("--raw", help="kho gốc đã giải gói (_raw)")
    parser.add_argument("--collected", help="thư mục dữ liệu client đã gom (CLIENT/data)")
    parser.add_argument("--out", help="tệp TSV golden cần ghi")
    parser.add_argument("--all-raw", action="store_true",
                        help="thống kê mọi layout gốc ở 1024x768, không ghi golden")
    parser.add_argument("--self-test", action="store_true", help="chạy các ca tính tay rồi thoát")
    args = parser.parse_args(argv)
    if args.self_test:
        return args
    if not args.raw:
        parser.error("thiếu --raw")
    if not args.all_raw and not (args.collected and args.out):
        parser.error("thiếu --collected hoặc --out")
    args.raw = os.path.abspath(args.raw)
    args.collected = os.path.abspath(args.collected) if args.collected else None
    args.out = os.path.abspath(args.out) if args.out else None
    return args


def run_golden(args: argparse.Namespace) -> int:
    started = time.perf_counter()
    tree = RawTree(args.raw)
    targets = read_type_targets(tree)
    runs = load_runs(tree, collected_layouts(args.collected))
    tallies = compute_runs(runs, targets)
    per_layout = [(run.layout, [rect.name for rect in run.rects[SCREENS[0]]]) for run in runs]
    names = analyse_names(per_layout)
    data = build_golden(runs, names.duplicates)
    state = "ghi mới" if write_atomic(args.out, data) else "giữ nguyên"
    data_lines = data.count(b"\n") - 2
    outcome = f"{args.out}: {state}, {data_lines} dòng dữ liệu"
    golden_report(runs, tallies, names, outcome, time.perf_counter() - started)
    return 0


def run_survey(args: argparse.Namespace) -> int:
    started = time.perf_counter()
    tree = RawTree(args.raw)
    survey, tally, per_layout = survey_layouts(tree, read_type_targets(tree))
    names = analyse_names(per_layout)
    survey_report(survey, tally, names, time.perf_counter() - started)
    return 1 if survey.failed else 0


def main() -> int:
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    args = parse_args(sys.argv[1:])
    if args.self_test:
        return self_test()
    try:
        return run_survey(args) if args.all_raw else run_golden(args)
    except UiError as error:
        print(f"Lỗi dữ liệu: {error}", file=sys.stderr)
    except OSError as error:
        print(f"Lỗi tệp: {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
