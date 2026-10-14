"""Ngữ nghĩa các hàm API của engine máy chủ gốc (LuaFnTbl_*.h) khi bộ đánh giá từng phần gặp chúng.

Mỗi hàm API nhận (bộ đánh giá, môi trường, đối số đã tính, danh sách bước đầu ra) và trả giá trị.
Hàm đọc trạng thái người chơi trả giá trị tượng trưng (NumSym, Dom01); hàm ghi phát bước Effect với op
đóng của module `ops`; hàm dựng hộp thoại phát bước Begin/Text/Option/Dispatch. Hàm thuần hiển thị
(âm thanh, hình ảnh, nhật ký) bị bỏ có đếm. Hàm chưa có ở đây làm script thành "cần handler" với lý do
`API <tên>`; không có lối tắt nào âm thầm bỏ hiệu ứng thật.
"""
from __future__ import annotations

import math
from collections.abc import Callable

import lua_bool as B
import lua_values as V
from lua_flow import Step
from lua_values import Unsupported

LEVEL_CAP = 150  # PlayerExpLevel.txt của client 2026 có 150 cấp

SCENE_SCRIPT_ID = 888888
EX_BASE = 1_000_000  # bộ đếm mở rộng (GetMissionDataEx) nằm ở dải riêng của bộ đếm


def _int(value: object, what: str) -> int:
    if isinstance(value, V.Marker) and value.kind == "scene":
        return -1  # cảnh hiện tại của người chơi
    number = V._num(value)
    if number is None or not float(number).is_integer():
        raise Unsupported(f"{what} không phải số nguyên hằng")
    return int(number)


def _text_of(value: object) -> object:
    if isinstance(value, (str, V.Tpl, V.Choice, V.Pick)):
        return value
    number = V._num(value)
    if number is not None:
        return V.number_text(number)
    if isinstance(value, V.NameSym):
        return V.Tpl((V.Param("npc"),))
    raise Unsupported(f"văn bản kiểu {type(value).__name__}")


# --- hộp thoại ---
def begin_event(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("begin"))


def end_event(low: object, env: object, args: list, out: list) -> None:
    return None


def add_text(low: object, env: object, args: list, out: list) -> None:
    if len(args) < 2:
        raise Unsupported("AddText thiếu đối số")
    _emit_text(out, _text_of(args[1]))


def _emit_text(out: list, text: object) -> None:
    if isinstance(text, V.Pick):
        # n chữ liền sau dấu pick: lúc chạy chọn đều một trong n chữ, bỏ n - 1 chữ còn lại.
        out.append(Step("pick", (len(text.options),)))
        for option in text.options:
            out.append(Step("text", (), option))
        return
    if isinstance(text, V.Choice):
        then_out: list = []
        other_out: list = []
        _emit_text(then_out, _text_of(text.then))
        _emit_text(other_out, _text_of(text.other))
        out.append(Step("branch", (), None, text.cond, then_out, other_out))
        return
    out.append(Step("text", (), text))


def add_num_text(low: object, env: object, args: list, out: list) -> None:
    # LuaFnAddNumText của máy chủ gốc: (sceneId, id, msg, [state], [index]); state và index vắng là -1.
    if len(args) < 3:
        raise Unsupported("AddNumText thiếu đối số")
    script = _int(args[1], "script của lựa chọn")
    icon = _int(args[3], "biểu tượng lựa chọn") if len(args) > 3 else -1
    value = _int(args[4], "giá trị lựa chọn") if len(args) > 4 else -1
    out.append(Step("option", (script, icon, value), _text_of(args[2])))


def dispatch_event_list(low: object, env: object, args: list, out: list) -> None:
    box = len(args) >= 3 and args[2] == -1
    out.append(Step("dispatch", ("box" if box else "list",)))


def dispatch_kind(kind: str) -> Callable:
    def handler(low: object, env: object, args: list, out: list) -> None:
        out.append(Step("dispatch", (kind,)))

    return handler


def bonus(kind: str) -> Callable:
    def handler(low: object, env: object, args: list, out: list) -> None:
        numbers = tuple(_int(item, "thưởng") for item in args[1:])
        out.append(Step("bonus", (kind, *numbers)))

    return handler


# --- trạng thái nhiệm vụ ---
def is_have_mission(low: object, env: object, args: list, out: list) -> object:
    return V.Dom01(B.atom("quest_active", _int(args[2], "id nhiệm vụ")))


def is_mission_done(low: object, env: object, args: list, out: list) -> object:
    return V.Dom01(B.atom("quest_done", _int(args[2], "id nhiệm vụ")))


def get_script_id_by_mission_id(low: object, env: object, args: list, out: list) -> object:
    return V.HeldScript(_int(args[2], "id nhiệm vụ"))


def get_mission_name(low: object, env: object, args: list, out: list) -> object:
    held = args[0]
    if not isinstance(held, V.HeldScript):
        raise Unsupported("tên nhiệm vụ của script không lấy từ GetScriptIDByMissionID")
    return V.NameSym(f"quest:{held.quest}")


def have_impact(low: object, env: object, args: list, out: list) -> object:
    who = args[1]
    if not (isinstance(who, V.Marker) and who.kind == "self"):
        raise Unsupported("hiệu ứng của người khác")
    return V.Dom01(B.atom("impact_active", _int(args[2], "mã hiệu ứng")))


def get_mission_index(low: object, env: object, args: list, out: list) -> object:
    return V.Marker("slot", _int(args[2], "id nhiệm vụ"))


def _slot(value: object) -> int:
    if not isinstance(value, V.Marker) or value.kind != "slot":
        raise Unsupported("chỉ số ô nhiệm vụ không xác định")
    return int(value.arg)


def get_mission_param(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("objective", (_slot(args[2]), _int(args[3], "chỉ số tham số")))


def set_mission_by_index(low: object, env: object, args: list, out: list) -> None:
    quest, index, value = _slot(args[2]), _int(args[3], "chỉ số"), args[4]
    if isinstance(value, V.Inc):
        same = value.sym.kind == "objective" and value.sym.args == (quest, index)
        if not same:
            raise Unsupported("tăng tham số bằng đại lượng khác")
        out.append(Step("effect", ("objective_add", quest, index, value.delta)))
        return
    out.append(Step("effect", ("objective_set", quest, index, _int(value, "giá trị"))))


def add_mission(low: object, env: object, args: list, out: list) -> object:
    out.append(Step("effect", ("quest_accept", _int(args[2], "id nhiệm vụ"), _int(args[3], "script"))))
    return 1


def del_mission(low: object, env: object, args: list, out: list) -> object:
    out.append(Step("effect", ("quest_remove", _int(args[2], "id nhiệm vụ"))))
    return 1


def mission_com(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("effect", ("quest_mark_done", _int(args[2], "id nhiệm vụ"))))


def is_mission_full(low: object, env: object, args: list, out: list) -> object:
    return V.Dom01(B.atom("quest_slots_free_at_least", 1, neg=True))


def get_mission_count(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("quest_count")


def counter_of(low: object, name_or_index: object) -> int:
    return _int(name_or_index, "chỉ số dữ liệu nhiệm vụ")


def get_mission_data(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("counter", (counter_of(low, args[2]),))


def set_mission_data(low: object, env: object, args: list, out: list) -> None:
    index, value = counter_of(low, args[2]), args[3]
    if isinstance(value, V.NumSym) and value.kind == "clock":
        out.append(Step("effect", ("set_counter_clock", index, value.args[0])))
        return
    if isinstance(value, V.Inc):
        if value.sym.kind != "counter" or value.sym.args != (index,):
            raise Unsupported("tăng bộ đếm bằng đại lượng khác")
        out.append(Step("effect", ("counter_add", index, value.delta)))
        return
    out.append(Step("effect", ("set_counter", index, _int(value, "giá trị đếm"))))


def get_mission_data_ex(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("counter", (EX_BASE + counter_of(low, args[2]),))


def set_mission_data_ex(low: object, env: object, args: list, out: list) -> None:
    shifted = [args[0], args[1], EX_BASE + counter_of(low, args[2]), *args[3:]]
    set_mission_data(low, env, shifted, out)


def get_mission_flag(low: object, env: object, args: list, out: list) -> object:
    return V.Dom01(B.atom("flag_set", _int(args[2], "cờ nhiệm vụ")))


def set_mission_flag(low: object, env: object, args: list, out: list) -> None:
    flag = _int(args[2], "cờ nhiệm vụ")
    op = "set_flag" if _int(args[3], "giá trị cờ") != 0 else "clear_flag"
    out.append(Step("effect", (op, flag)))


# --- đọc nhân vật ---
def get_level(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("level")


def get_name(low: object, env: object, args: list, out: list) -> object:
    who = args[1] if len(args) > 1 else None
    if isinstance(who, V.Marker) and who.kind == "target":
        return V.NameSym("target")
    if isinstance(who, V.Marker) and who.kind == "monster":
        return V.NameSym("monster")
    if isinstance(who, V.Marker) and who.kind == "self":
        return V.Tpl((V.Param("player"),))
    raise Unsupported("GetName của đối tượng không xác định")


def get_sex(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("gender")


def get_menpai(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("sect")


def get_item_count(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("item_count", (_int(args[2], "id vật phẩm"),))


def have_item(low: object, env: object, args: list, out: list) -> object:
    return V.Dom01(B.atom("item_count_at_least", _int(args[2], "id vật phẩm"), 1))


def bag_space(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("bag_space")


def get_money(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("money", (0,))


def get_money_bound(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("money", (1,))


def team_size(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("team_size")


def has_team(low: object, env: object, args: list, out: list) -> object:
    return V.Dom01(B.atom("team_size_at_least", 2))


def team_leader(low: object, env: object, args: list, out: list) -> object:
    return V.Dom01(B.atom("team_leader"))


def have_skill(low: object, env: object, args: list, out: list) -> object:
    return V.Dom01(B.atom("skill_known", _int(args[2], "id kỹ năng")))


def ability_level(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("ability", (_int(args[2], "id kỹ năng sống"),))


def guild_id(low: object, env: object, args: list, out: list) -> object:
    return V.NumSym("guild")


CLOCKS = {"GetDayTime": 1, "GetHourTime": 2, "GetQuarterTime": 3, "GetWeekTime": 4, "LuaFnGetCurrentTime": 5}


def clock_reader(which: int) -> Callable:
    def handler(low: object, env: object, args: list, out: list) -> object:
        return V.NumSym("clock", (which,))

    return handler


def monster_name_by_data(low: object, env: object, args: list, out: list) -> object:
    if not (isinstance(args[0], V.NumSym) and args[0].kind == "monster"):
        raise Unsupported("tên quái của mã không phải sự kiện")
    return V.NameSym("monster")


def monster_owner_count(low: object, env: object, args: list, out: list) -> object:
    return 1


def monster_owner_id(low: object, env: object, args: list, out: list) -> object:
    return V.Marker("self")


def get_num_text(low: object, env: object, args: list, out: list) -> object:
    if low.num is None:
        raise Unsupported("GetNumText chưa biết giá trị")
    return low.num


def level_cap(low: object, env: object, args: list, out: list) -> object:
    return LEVEL_CAP


# --- hiệu ứng ---
def add_money(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("effect", ("give_money", _int(args[2], "số tiền"), 0)))


def add_money_bound(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("effect", ("give_money", _int(args[2], "số tiền"), 1)))


def cost_money(low: object, env: object, args: list, out: list) -> object:
    out.append(Step("effect", ("take_money", _int(args[2], "số tiền"), 0)))
    return 1


def add_exp(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("effect", ("give_exp", _int(args[2], "kinh nghiệm"))))


ADD_ITEM_KEY = "\x00add_item"  # số vật phẩm đã AddItem trên ĐƯỜNG ĐANG CHẠY từ BeginAddItem (trong env, nên theo nhánh)


def begin_add_item(low: object, env: object, args: list, out: list) -> None:
    env.local[ADD_ITEM_KEY] = 0


def add_item(low: object, env: object, args: list, out: list) -> None:
    """AddItem phát luôn bước give_item tại chỗ gọi: nhánh `if item.id == selectRadioId` nhờ vậy mang đúng điều
    kiện của nó.
    (Hiệu ứng vẫn chỉ áp một lần, nguyên tử, qua bộ hiệu ứng; AddItemListToHuman gốc không còn việc gì để làm.)"""
    count = env.local.get(ADD_ITEM_KEY)
    _largest(count)
    out.append(Step("effect", ("give_item", _int(args[1], "id vật phẩm"), _int(args[2], "số lượng"), 0)))
    env.local[ADD_ITEM_KEY] = _bump(count)


def _bump(value: object) -> object:
    """Cộng một vào bộ đếm vật phẩm; sau chỗ hợp nhất nhánh bộ đếm là Choice của các số."""
    if isinstance(value, V.Choice):
        return V.Choice(value.cond, _bump(value.then), _bump(value.other))
    return value + 1


def _largest(value: object) -> int:
    if isinstance(value, V.Choice):
        return max(_largest(value.then), _largest(value.other))
    if not isinstance(value, int) or isinstance(value, bool):
        raise Unsupported("AddItem ngoài BeginAddItem")
    return value


def end_add_item(low: object, env: object, args: list, out: list) -> object:
    """Số ô trống cần là số AddItem lớn nhất trên một đường chạy (mỗi nhánh chỉ thêm phần của nó)."""
    count = _largest(env.local.get(ADD_ITEM_KEY))
    return V.Dom01(B.atom("bag_space_at_least", max(1, count)))


def add_item_list(low: object, env: object, args: list, out: list) -> None:
    if ADD_ITEM_KEY not in env.local:
        raise Unsupported("AddItemListToHuman ngoài EndAddItem")


def try_receive_item(low: object, env: object, args: list, out: list) -> object:
    out.append(Step("effect", ("give_item", _int(args[2], "id vật phẩm"), _int(args[3], "số lượng"), 0)))
    return 1


def del_item(low: object, env: object, args: list, out: list) -> object:
    out.append(Step("effect", ("take_item", _int(args[2], "id vật phẩm"), _int(args[3], "số lượng"))))
    return 1


def msg_to_player(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("effect", ("notify", 0), _text_of(args[2])))


def broadcast(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("effect", ("announce",), _text_of(args[2])))


def new_world(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("effect", ("teleport", _int(args[2], "cảnh"), _int(args[3], "x"), _int(args[4], "z"))))


def set_pos(low: object, env: object, args: list, out: list) -> None:
    """SetPos(sceneId, selfId, x, z): dời vị trí trong cảnh hiện tại (cảnh -1 của chỉ thị dịch chuyển)."""
    out.append(Step("effect", ("teleport", -1, _int(args[2], "x"), _int(args[3], "z"))))


def begin_ui_command(low: object, env: object, args: list, out: list) -> None:
    low.ui_ints = []
    low.ui_strings = 0


def ui_add_int(low: object, env: object, args: list, out: list) -> None:
    if getattr(low, "ui_ints", None) is None:
        raise Unsupported("UICommand_AddInt ngoài BeginUICommand")
    value = args[1]
    if isinstance(value, V.Marker) and value.kind in ("target", "self"):
        # id đối tượng chỉ có lúc chạy: -1 là NPC đang đối thoại, -2 là chính nhân vật (id thật luôn không âm).
        low.ui_ints.append(-1 if value.kind == "target" else -2)
        return
    low.ui_ints.append(_int(value, "số của lệnh giao diện"))


def ui_add_string(low: object, env: object, args: list, out: list) -> None:
    if getattr(low, "ui_ints", None) is None:
        raise Unsupported("UICommand_AddString ngoài BeginUICommand")
    low.ui_strings += 1


def dispatch_ui_command(low: object, env: object, args: list, out: list) -> None:
    """Lệnh giao diện cho client: id + tối đa hai số. Chuỗi hay nhiều số hơn chưa có chỗ trong chỉ thị đóng."""
    ints = getattr(low, "ui_ints", None)
    if ints is None:
        raise Unsupported("DispatchUICommand không có BeginUICommand")
    strings = low.ui_strings
    low.ui_ints = None
    if strings or len(ints) > 2:
        raise Unsupported("lệnh giao diện có chuỗi hoặc hơn hai số")
    first, second = (*ints, 0, 0)[:2]
    out.append(Step("effect", ("ui_command", _int(args[2], "id lệnh giao diện"), first, second)))


def lua_random(low: object, env: object, args: list, out: list) -> object:
    if len(args) != 1:
        raise Unsupported("random nhiều đối số")
    count = _int(args[0], "cận của random")
    if count < 1 or count > 64:
        raise Unsupported("random ngoài 1..64")
    return V.RandIdx(count)


def open_shop(low: object, env: object, args: list, out: list) -> None:
    out.append(Step("effect", ("open_shop", _int(args[3], "id cửa hàng") if len(args) > 3 else 0)))


def ignored(reason: str) -> Callable:
    def handler(low: object, env: object, args: list, out: list) -> None:
        low.drop(reason)

    return handler


def note(reason: str) -> Callable:
    """Bỏ hiệu ứng thuần hiển thị nhưng để lại dấu 'note' (cho phép trong hàm giá trị)."""

    def handler(low: object, env: object, args: list, out: list) -> None:
        low.drop(reason)
        out.append(Step("note", (reason,)))

    return handler


# --- thư viện chuẩn Lua ---
def lua_floor(low: object, env: object, args: list, out: list) -> object:
    return int(math.floor(_float(args[0])))


def lua_mod(low: object, env: object, args: list, out: list) -> object:
    divisor = _float(args[1])
    if divisor == 0:
        raise Unsupported("mod cho 0")
    return _norm(math.fmod(_float(args[0]), divisor))


def lua_getn(low: object, env: object, args: list, out: list) -> object:
    if not isinstance(args[0], V.LTable):
        raise Unsupported("getn của giá trị không phải bảng")
    return args[0].length()


def lua_tostring(low: object, env: object, args: list, out: list) -> object:
    return _text_of(args[0]) if args[0] is not None else "nil"


def lua_tonumber(low: object, env: object, args: list, out: list) -> object:
    number = V._num(args[0])
    if number is not None:
        return _norm(number)
    raise Unsupported("tonumber không phải hằng")


def lua_type(low: object, env: object, args: list, out: list) -> object:
    value = args[0]
    if value is None:
        return "nil"
    if isinstance(value, str):
        return "string"
    if isinstance(value, V.LTable):
        return "table"
    return "number"


def lua_format(low: object, env: object, args: list, out: list) -> object:
    template = args[0]
    if not isinstance(template, str):
        raise Unsupported("format với mẫu không phải chuỗi hằng")
    values = list(args[1:])
    pieces: list = []
    rest = template
    while rest:
        at = rest.find("%")
        if at < 0:
            pieces.append(rest)
            break
        pieces.append(rest[:at])
        spec = rest[at + 1 : at + 2]
        rest = rest[at + 2 :]
        pieces.append(_format_one(spec, values))
    merged: object = ""
    for piece in pieces:
        merged = V.concat(merged, piece)
    return merged


def _format_one(spec: str, values: list) -> object:
    if spec == "%":
        return "%"
    if spec not in ("d", "s") or not values:
        raise Unsupported(f"format %{spec}")
    value = values.pop(0)
    if spec == "d":
        number = V._num(value)
        if number is None:
            return _number_param(value)
        return str(int(number))
    return _text_of(value)


def _number_param(value: object) -> object:
    """Số tượng trưng trong chuỗi định dạng thành tham số có kiểu: "kind:đối số..." do máy chủ điền lúc gửi."""
    if isinstance(value, V.Inc) and value.delta == 0:
        value = value.sym
    if not isinstance(value, V.NumSym):
        raise Unsupported("format %d với giá trị không hằng")
    label = ":".join([value.kind, *[str(item) for item in value.args]])
    return V.Tpl((V.Param(label),))


def _float(value: object) -> float:
    number = V._num(value)
    if number is None:
        raise Unsupported("tham số số không phải hằng")
    return number


def _norm(value: float) -> object:
    return int(value) if float(value).is_integer() else value


# --- CallScriptFunction ---
def call_script_function(low: object, env: object, args: list, out: list) -> object:
    target = _int(args[0], "id script")
    name = args[1]
    if not isinstance(name, str):
        raise Unsupported("CallScriptFunction với tên hàm không hằng")
    rest = list(args[2:])
    if target == SCENE_SCRIPT_ID:
        return scene_call(low, name, rest, out)
    unit = low.units.get(target)
    if unit is None:
        # Máy chủ gốc gọi tới script không nạp thì chỉ ghi nhật ký lỗi và bỏ qua (ExeScript_*):
        # không hiệu ứng, không giá trị.
        low.drop("CallScriptFunction tới script không có trong dữ liệu máy chủ (bản gốc bỏ qua)")
        out.append(Step("note", (f"script {target} không có",)))
        return None
    quest = quest_of_unit(unit)
    if name == "OnDefaultEvent" and quest is not None:
        out.append(Step("effect", ("offer_next", quest)))
        return None
    func = unit.funcs.get(f"x{target:06d}_{name}") or _by_suffix(unit, name)
    if func is None:
        raise Unsupported(f"script {target} không có hàm {name}")
    return low.call_user(unit, func, rest, out)


def quest_of_unit(unit: object) -> int | None:
    """Id nhiệm vụ nếu script là script nhiệm vụ (có g_MissionId số)."""
    for key, value in unit.globals.items():
        if key.endswith("_g_MissionId") and isinstance(value, int):
            return value
    return None


def _by_suffix(unit: object, name: str) -> object:
    for key, func in unit.funcs.items():
        if key.split("_", 1)[-1] == name:
            return func
    return None


def scene_call(low: object, name: str, args: list, out: list) -> object:
    """Hàm của scene.lua mà script nhiệm vụ gọi; ngữ nghĩa chép từ scene.lua, không inline cả tệp."""
    if name == "AskTheWay":
        out.append(Step("effect", ("signpost", _int(args[2], "cảnh"), _int(args[3], "x"), _int(args[4], "z")),
                        _text_of(args[5])))
        return None
    if name == "AskThePos":
        out.append(Step("effect", ("signpost_pos", _int(args[2], "cảnh"), _int(args[3], "x"), _int(args[4], "z")),
                        _text_of(args[5])))
        return None
    if name in ("DelSignpost", "PlaySoundEffect", "PlayBackSound", "StopBackSound"):
        low.drop(f"scene.{name}")
        out.append(Step("note", (name,)))
        return None
    if name == "CheckSubmit":
        quest = _int(args[2], "id nhiệm vụ")
        return V.Dom01(B.b_and(B.atom("quest_active", quest), B.atom("quest_done", quest, neg=True)))
    if name == "OnAcceptMissionCheck":
        return V.Dom01(B.atom("quest_slots_free_at_least", 1))
    raise Unsupported(f"scene.lua:{name}")


API: dict = {
    "BeginEvent": begin_event,
    "EndEvent": end_event,
    "AddText": add_text,
    "AddNumText": add_num_text,
    "DispatchEventList": dispatch_event_list,
    "DispatchMissionInfo": dispatch_kind("mission_info"),
    "DispatchMissionContinueInfo": dispatch_kind("continue"),
    "DispatchMissionDemandInfo": dispatch_kind("demand"),
    "DispatchMissionTips": dispatch_kind("tips"),
    "AddMoneyBonus": bonus("money"),
    "AddItemBonus": bonus("item"),
    "AddRadioItemBonus": bonus("radio"),
    "AddRandItemBonus": bonus("random"),
    "AddItemDemand": bonus("demand"),
    "IsHaveMission": is_have_mission,
    "IsMissionHaveDone": is_mission_done,
    "LuaFnHaveImpactOfSpecificDataIndex": have_impact,
    "GetMissionIndexByID": get_mission_index,
    "GetScriptIDByMissionID": get_script_id_by_mission_id,
    "TGetMissionName": get_mission_name,
    "GetMissionParam": get_mission_param,
    "SetMissionByIndex": set_mission_by_index,
    "AddMission": add_mission,
    "AddMissionEx": add_mission,
    "DelMission": del_mission,
    "MissionCom": mission_com,
    "IsMissionFull": is_mission_full,
    "GetMissionCount": get_mission_count,
    "GetMissionData": get_mission_data,
    "GetMissionDataEx": get_mission_data_ex,
    "SetMissionDataEx": set_mission_data_ex,
    **{name: clock_reader(which) for name, which in CLOCKS.items()},
    "SetMissionData": set_mission_data,
    "GetMissionFlag": get_mission_flag,
    "SetMissionFlag": set_mission_flag,
    "GetLevel": get_level,
    "LuaFnGetLevel": get_level,
    "GetName": get_name,
    "LuaFnGetName": get_name,
    "GetSex": get_sex,
    "LuaFnGetSex": get_sex,
    "GetMenPai": get_menpai,
    "LuaFnGetMenPai": get_menpai,
    "GetItemCount": get_item_count,
    "LuaFnGetAvailableItemCount": get_item_count,
    "HaveItemInBag": have_item,
    "HaveItem": have_item,
    "LuaFnGetPropertyBagSpace": bag_space,
    "LuaFnGetMaterialBagSpace": bag_space,
    "GetMoney": get_money,
    "LuaFnGetMoney": get_money,
    "GetMoneyJZ": get_money_bound,
    "GetTeamSize": team_size,
    "LuaFnGetTeamSize": team_size,
    "GetNearTeamCount": team_size,
    "LuaFnHasTeam": has_team,
    "LuaFnIsTeamLeader": team_leader,
    "HaveSkill": have_skill,
    "GetMonsterNamebyDataId": monster_name_by_data,
    "GetMonsterOwnerCount": monster_owner_count,
    "GetMonsterOwnerID": monster_owner_id,
    "QueryHumanAbilityLevel": ability_level,
    "GetHumanGuildID": guild_id,
    "GetHumanMaxLevelLimit": level_cap,
    "GetNumText": get_num_text,
    "AddMoney": add_money,
    "LuaFnAddMoney": add_money,
    "AddMoneyJZ": add_money_bound,
    "LuaFnCostMoney": cost_money,
    "LuaFnCostMoneyWithPriority": cost_money,
    "CostMoney": cost_money,
    "LuaFnAddExp": add_exp,
    "AddExp": add_exp,
    "BeginAddItem": begin_add_item,
    "AddItem": add_item,
    "EndAddItem": end_add_item,
    "AddItemListToHuman": add_item_list,
    "TryRecieveItem": try_receive_item,
    "LuaFnTryRecieveItem": try_receive_item,
    "DelItem": del_item,
    "LuaFnDelAvailableItem": del_item,
    "Msg2Player": msg_to_player,
    "LuaFnMsg2Player": msg_to_player,
    "BroadMsgByChatPipe": broadcast,
    "NewWorld": new_world,
    "DispatchShopItem": open_shop,
    "SetPos": set_pos,
    "BeginUICommand": begin_ui_command,
    "UICommand_AddInt": ui_add_int,
    "UICommand_AddString": ui_add_string,
    "EndUICommand": ignored("kết thúc lệnh giao diện"),
    "DispatchUICommand": dispatch_ui_command,
    "random": lua_random,
    "SetMissionEvent": ignored("đăng ký sự kiện nhiệm vụ"),
    "ResetMissionEvent": ignored("đăng ký sự kiện nhiệm vụ"),
    "LuaFnSendSpecificImpactToUnit": note("hiệu ứng hình ảnh"),
    "LuaFnCancelSpecificImpact": note("hiệu ứng hình ảnh"),
    "LuaFnAuditQuest": note("sổ kiểm"),
    "ScriptGlobal_AuditGeneralLog": note("sổ kiểm"),
    "MissionLog": note("nhật ký"),
    "print": note("in nhật ký"),
    "PrintStr": note("in nhật ký"),
    "CallScriptFunction": call_script_function,
    "floor": lua_floor,
    "mod": lua_mod,
    "getn": lua_getn,
    "tostring": lua_tostring,
    "tonumber": lua_tonumber,
    "type": lua_type,
    "format": lua_format,
}
