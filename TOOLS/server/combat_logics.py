"""Bảng logic kỹ năng và logic hiệu ứng của lõi chiến đấu (src/server/combat), dạng dữ liệu thuần.

Mỗi dòng: số logic -> (tên mã xử lý, cột roles, độ trung thực, ghi chú). Tên mã xử lý phải có trong
src/server/combat/detail/skills.cpp (logic kỹ năng) hoặc effects*.cpp (logic hiệu ứng); bộ nạp C++ từ chối tên lạ.

Cột roles ("chỉ số tham số:vai[@xác suất][*lặp][+phụ]") nói tham số nào của dòng dữ liệu là id hiệu ứng, gửi tới ai:
  target, self, target_tick, self_tick, friend, enemy, rank<N>, rest, friend<N>, enemy<N>, friend_rest, enemy_rest,
  self_male, self_female, combo<N>, trap, trap_tick, summon, totem, dispel_self, cut_cooldown+<ô>, sub.
Nghĩa từng vai ở src/server/combat/catalog.hpp (RoleKind). Chỉ số tham số của logic kỹ năng là ô 0..14 của
skill_levels.tsv; của logic hiệu ứng là ô 0..15 của effects.tsv.

Độ trung thực: full (hành vi có từ mã nguồn 2008 hoặc nghĩa tham số không mơ hồ), core (phần chính làm đủ, cơ chế phụ
nêu trong ghi chú chưa làm), event (lõi chỉ phát sự kiện cho module ngoài). Logic không có dòng ở đây (hoặc có handler
unsupported) không tính vào độ phủ; logic unsupported vẫn khai roles để skill_coverage.py theo được id hiệu ứng trong
dữ liệu.
Hiệu ứng đánh dấu (handler none) là full: phần của lõi chỉ là cho tập id hỏi được buff đang có.

Nghĩa tham số của logic 0..57 theo mã 2008 (GameServer/Skills/*.cpp); logic lớn hơn chỉ có ở dữ liệu client 2026,
nghĩa lấy từ cột mô tả của dữ liệu.
"""
from __future__ import annotations

from typing import NamedTuple


class Logic(NamedTuple):
    handler: str
    roles: str
    fidelity: str
    note: str


FULL = "full"
CORE = "core"
EVENT = "event"

SKILL_LOGICS: dict[int, Logic] = {
    0: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", FULL,
        "đòn thường và kỹ năng chuẩn: hiệu ứng một lần và theo nhịp dẫn lên mục tiêu"),
    1: Logic(
        "standard", "0:self;1:target;2:self_tick;3:target_tick", FULL,
        "hiệu ứng một lần và theo nhịp dẫn, mỗi loại cho bản thân và cho mục tiêu"),
    2: Logic(
        "dash", "0:self;1:self;2:self", CORE,
        "lướt tới điểm chọn; ô 3 là hiệu ứng hình ảnh dịch chuyển, bỏ"),
    3: Logic(
        "standard", "0:target;1:self@2;3:target@4", CORE,
        "hiệu ứng đánh, rồi hiệu ứng thêm cho bản thân và mục tiêu theo xác suất"),
    4: Logic(
        "standard", "0:target;2:target@3*1", CORE,
        "hiệu ứng đánh, rồi hiệu ứng thêm cho mục tiêu theo xác suất và số lần"),
    5: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", FULL,
        "như logic 0; ô 4 là mã script, lõi không chạy Lua"),
    6: Logic(
        "standard", "0:target;1:target;2:target;3:target;4:target", CORE,
        "năm hiệu ứng một lần lên mục tiêu"),
    7: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0"),
    8: Logic(
        "passive_armor", "", FULL,
        "bị động: cộng phần trăm điểm phòng thủ gốc của giáp"),
    9: Logic(
        "passive_weapon", "", FULL,
        "bị động: cộng phần trăm điểm công gốc của vũ khí theo loại vũ khí"),
    10: Logic(
        "unsupported", "", EVENT,
        "bắt thú: cần module thú cưng"),
    11: Logic(
        "unsupported", "", EVENT,
        "triệu hồi thú / võ hồn: cần module thú cưng"),
    12: Logic(
        "standard", "0:trap", CORE,
        "đặt bẫy"),
    14: Logic(
        "standard", "0:dispel_self", FULL,
        "gỡ buff biến thân và cưỡi"),
    15: Logic(
        "standard", "", EVENT,
        "khinh công: di chuyển do zone xử lý, kỹ năng không gửi hiệu ứng"),
    16: Logic(
        "standard", "0:self", CORE,
        "hiệu ứng về thành; ô 1..8 (vật phẩm xung đột) thuộc module vật phẩm"),
    17: Logic(
        "unsupported", "", EVENT,
        "kỹ năng thú: cần module thú cưng"),
    18: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0"),
    19: Logic(
        "unsupported", "", EVENT,
        "triệu gọi con cái: cần module xã hội"),
    52: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", FULL,
        "như logic 0"),
    77: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0"),
    80: Logic(
        "standard", "0:combo0;1:combo1;2:combo2", FULL,
        "hiệu ứng theo số đoạn liên kích đã tiêu (1, 2, 3 đoạn)"),
    81: Logic(
        "standard", "0:combo0;1:combo1;2:combo2;3:combo3;4:target;5:target", FULL,
        "như logic 80, thêm hiệu ứng cho lần không tiêu liên kích và hai hiệu ứng luôn có"),
    82: Logic(
        "standard", ("0:self;1:self_tick;2:target;3:target_tick;4:self;5:self_tick;"
            "6:target;7:target_tick;8:self;9:self_tick;10:target;"
            "11:target_tick"), FULL,
        "ba bộ bốn ô: bản thân và mục tiêu, một lần và theo nhịp dẫn"),
    111: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0; ô 4 là tập buff khống chế được miễn, chưa dùng"),
    141: Logic(
        "standard", "0:friend;1:friend;2:enemy;3:enemy", FULL,
        "hiệu ứng riêng cho bạn và cho địch trong vùng"),
    142: Logic(
        "standard", "0:friend0;1:friend_rest;3:enemy0;4:enemy_rest", CORE,
        "chữa mục tiêu chính và phụ, đánh địch chính và phụ; ô 2, 5 (dây nối), 6, 7 (hệ số chữa thêm) chưa dùng"),
    143: Logic(
        "standard", "0:target;1:target", CORE,
        "khiên hấp thụ và buff mệt mỏi cho mục tiêu"),
    144: Logic(
        "standard", "0:target;1:target;2:target;7:self;8:self", CORE,
        "hiệu ứng lên mục tiêu, buff biến thân cho bản thân; ô 3..6 (thay kỹ năng) là việc của client"),
    145: Logic(
        "standard", "0:target;2:target", CORE,
        "buff chữa và buff mệt mỏi; ô 1 (hệ số chữa thêm) chưa dùng"),
    146: Logic(
        "standard", "0:rank0;1:rank1;2:rank2", CORE,
        "chữa ba mục tiêu theo thứ tự; ô 3..5 (hệ số, suy giảm), 6 (dây nối) chưa dùng"),
    147: Logic(
        "standard", "0:target;3:self", CORE,
        "buff chữa cho mục tiêu, buff chữa cho bản thân; ô 1, 2 (hệ số chữa thêm theo nghìn) chưa dùng"),
    148: Logic(
        "standard", "0:target;1:target@2", FULL,
        "hiệu ứng 1, rồi hiệu ứng 2 theo xác suất"),
    149: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0; ô 4 (phần trăm hồi máu) chưa dùng"),
    170: Logic(
        "standard", "0:self_male;1:self_female;2:self", FULL,
        "biến thân theo giới tính và buff miễn khống chế"),
    171: Logic(
        "standard", "2:target@1", CORE,
        "gây độc theo xác suất; ô 0 (cộng công độc) chưa dùng"),
    172: Logic(
        "standard", "0:target;2:target@1", FULL,
        "buff sát thương và buff phong huyệt theo xác suất"),
    173: Logic(
        "standard", "0:trap;1:self_male;2:self_female;3:self", FULL,
        "đặt bẫy, biến thân theo giới tính, buff miễn khống chế"),
    174: Logic(
        "standard", "0:target;1:summon", FULL,
        "buff mù và triệu hồi vật"),
    175: Logic(
        "standard", "0:target;1:target", FULL,
        "hiệu ứng và buff mệt mỏi"),
    176: Logic(
        "unsupported", ("0:self;1:self;2:self;3:self;4:self;5:self;6:self;7:self;8:self;"
            "9:self;10:self;11:self;13:self;14:self"), EVENT,
        "ngũ độc tụ đỉnh: chọn hiệu ứng theo loại và số độc trùng đã thả, lõi chưa theo dõi độc trùng"),
    177: Logic(
        "standard", "0:target;2:self@1", FULL,
        "hiệu ứng đánh, rồi buff triệu hồi trăn theo xác suất"),
    178: Logic(
        "standard", "0:target", FULL,
        "buff hộ thân"),
    179: Logic(
        "standard", "0:target", CORE,
        "hiệu ứng đánh; ô 1..5 (khoá mục tiêu, hồi chiêu theo nộ khí) chưa dùng"),
    201: Logic(
        "unsupported", "", EVENT,
        "chọn ngẫu nhiên một trong bốn hiệu ứng theo trọng số cho người/thú và quái"),
    202: Logic(
        "standard", "0:trap_tick", FULL,
        "thả bẫy theo nhịp dẫn"),
    204: Logic(
        "standard", "0:target;2:dispel_self", CORE,
        "sát thương thêm của nhị thức, rồi gỡ buff nhị thức; ô 1 (hệ số suy giảm) chưa dùng"),
    205: Logic(
        "standard", "0:target;2:target@1;5:self@3", CORE,
        "hiệu ứng 1, hiệu ứng 2 theo xác suất, buff nhị thức theo xác suất; ô 4, 6 chưa dùng"),
    206: Logic(
        "standard", "0:target;2:target@1;3:self;4:dispel_self", FULL,
        "hiệu ứng 1, hiệu ứng 2 theo xác suất, buff cho bản thân, gỡ buff nhị thức"),
    207: Logic(
        "unsupported", "", EVENT,
        "trận pháp: cần cơ chế đội hình, bảng không có tham số hiệu ứng"),
    208: Logic(
        "standard", "0:dispel_self", FULL,
        "gỡ buff nhị thức"),
    231: Logic(
        "standard", "0:target", CORE,
        "hiệu ứng đóng băng; ô 1 (hiệu ứng hình ảnh dịch chuyển) bỏ"),
    260: Logic(
        "standard", "1:trap", CORE,
        "đặt bẫy; ô 0 (buff ghi bẫy), 2 (trần số bẫy cùng loại) do zone xử lý"),
    261: Logic(
        "standard", "0:self", CORE,
        "hiệu ứng tức thì; ô 1 (loại bẫy cần kích nổ) cần quản lý bẫy của zone"),
    262: Logic(
        "standard", "1:target", CORE,
        "sát thương kích nổ; ô 0 (tập hiệu ứng kích nổ) cần quản lý bẫy của zone"),
    290: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0"),
    291: Logic(
        "standard", "1:target;2:target_tick;3:target;4:target_tick", CORE,
        "như logic 0 sau ô buff mệt mỏi"),
    292: Logic(
        "standard", "1:self;2:target;3:self_tick;4:target_tick", CORE,
        "như logic 1 sau ô buff mệt mỏi"),
    400: Logic(
        "standard", "0:self;1:target;2:target", CORE,
        "buff cho bản thân và hai hiệu ứng lên mục tiêu"),
    641: Logic(
        "standard", "0:self;1:target", CORE,
        "hiệu ứng cho bản thân và mục tiêu"),
    642: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0"),
    643: Logic(
        "standard", "0:target;3:target", CORE,
        (
        "tâm pháp thứ tám Thiếu Lâm: hai hiệu ứng lên mục tiêu; ô 1, 2, 4, 5 (cận dưới và cận trên phần trăm "
        "hiệu ứng) chưa dùng")),
    644: Logic(
        "standard", "0:target;3:target", CORE,
        "tâm pháp thứ tám Thiếu Lâm, nhánh khống chế: như logic 643"),
    645: Logic(
        "unsupported", "", EVENT,
        "kỹ năng thú theo tư chất: cần module thú cưng"),
    646: Logic(
        "standard", "0:trap_tick", CORE,
        "thả bẫy theo nhịp dẫn"),
    647: Logic(
        "standard", "0:trap_tick;3:trap_tick", CORE,
        "thả bẫy theo nhịp dẫn, kể cả bẫy tăng cường"),
    648: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0"),
    649: Logic(
        "standard", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "như logic 0; ô 4 là mã script, lõi không chạy Lua"),
    670: Logic(
        "unsupported", "1:target;3:target;5:target;7:target;9:target;11:target;13:target", EVENT,
        (
        "hiệu ứng theo tập khống chế mục tiêu đang mang: cần so tập buff của mục tiêu với từng cặp (tập, hiệu "
        "ứng)")),
    671: Logic(
        "sect_mimic", "", CORE,
        (
        "hoá khí thức: phát kỹ năng cùng chiêu của môn phái mục tiêu (ô 0..14 là id kỹ năng theo phái), không có "
        "phái hợp lệ thì rút ngẫu nhiên; phát ở cấp cao nhất có dữ liệu")),
    672: Logic(
        "standard", "0:target;2:totem", CORE,
        "hiệu ứng đánh và tượng; ô 1 (tầm dịch chuyển tới mục tiêu) chưa dùng"),
    700: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    701: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    702: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    703: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    704: Logic(
        "unsupported", "0:target@1", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên) (bản này đã bỏ)")),
    705: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    706: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    707: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    730: Logic(
        "standard", "0:totem;2:self", CORE,
        "dựng tượng và hiệu ứng bất tử; ô 1 (máu tượng) do zone đọc từ tham số kỹ năng"),
    731: Logic(
        "standard", "0:self;1:self;2:totem;3:totem;4:totem", CORE,
        "buff trễ, buff miễn khống chế, ba tượng; ô 5..7 (máu tượng) do zone đọc"),
    732: Logic(
        "standard", "0:target", CORE,
        "hiệu ứng đánh; ô 1, 2 (giảm hồi chiêu khi hội tâm) chưa dùng"),
    734: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    735: Logic(
        "unsupported", "", EVENT,
        (
        "bí pháp tiến giai: tác dụng lên kỹ năng gốc qua điểm tiến giai, bảng không nối bí pháp với kỹ năng gốc "
        "(chỉ có tên; đo 59 trên 138 bí pháp trùng tên nhiều mẫu hoặc không có mẫu cùng tên)")),
    736: Logic(
        "standard", "0:target", CORE,
        "sát thương chính; ô 1..4 (nổ lan theo xác suất) chưa dùng"),
    760: Logic(
        "dash", "0:target;1:target_tick;2:target;3:target_tick", CORE,
        "lướt tới điểm chọn, hiệu ứng như logic 0"),
    761: Logic(
        "unsupported", "", EVENT,
        "trận pháp: cần cơ chế đội hình, bảng không có tham số hiệu ứng"),
    762: Logic(
        "unsupported", "", EVENT,
        "trận pháp: cần cơ chế đội hình, bảng không có tham số hiệu ứng"),
    763: Logic(
        "unsupported", "", EVENT,
        "trận pháp: cần cơ chế đội hình, bảng không có tham số hiệu ứng"),
    764: Logic(
        "unsupported", "", EVENT,
        "trận pháp: cần cơ chế đội hình, bảng không có tham số hiệu ứng"),
    765: Logic(
        "unsupported", "", EVENT,
        "trận pháp: cần cơ chế đội hình, bảng không có tham số hiệu ứng"),
    766: Logic(
        "standard", "0:totem", CORE,
        "dựng tượng trận"),
    767: Logic(
        "standard", "1:self", CORE,
        "buff bá thể; ô 0 (dây nối), 2..6 (bẫy gây sát thương cho đồng đội) chưa dùng"),
    768: Logic(
        "unsupported", ("0:target;1:target;2:target;3:target;4:target;5:target;6:target;"
            "7:target;8:trap"), EVENT,
        "sát thương và choáng chọn theo số mục tiêu bị trúng, cần chọn ô theo số lượng và bẫy cảnh báo"),
    769: Logic(
        "standard", "4:rank0;5:rank1;6:rank2;7:rank3;8:rank4;9:rank5;10:rank6", CORE,
        "sát thương theo thứ tự mục tiêu; ô 0..3 (dây nối, cự ly đứt dây) chưa dùng"),
    770: Logic(
        "standard", "0:target;2:self", CORE,
        "khiên trường sinh cho mục tiêu, buff hội tâm cho bản thân; ô 1 (phần trăm máu khiên) chưa dùng"),
    791: Logic(
        "standard", "0:self", CORE,
        "hiệu ứng cho bản thân; ô 1 (tầm di chuyển tối đa của khôi lỗi) chưa dùng"),
    792: Logic(
        "standard", "0:target;1:target", CORE,
        "hai hiệu ứng một lần"),
    793: Logic(
        "dash", "1:self;4:enemy;5:enemy", CORE,
        "lướt, buff cho bản thân, hiệu ứng lên địch trên đường; ô 0, 2, 3 chưa dùng"),
    794: Logic(
        "standard", "0:self;1:self;2:self", CORE,
        "ba buff cho bản thân"),
    795: Logic(
        "standard", "0:trap;2:self;3:self", CORE,
        "đặt bẫy tại chỗ khôi lỗi thu về; ô 1, 4 chưa dùng"),
    797: Logic(
        "standard", "0:target", CORE,
        "hiệu ứng một lần; ô 1 (buff bị động tầng 0) chưa dùng"),
    799: Logic(
        "standard", "0:target;1:target;2:self;5:self", CORE,
        "hiệu ứng lên địch quanh khôi lỗi và buff cho khôi lỗi (coi là bản thân); ô 3, 4 chưa dùng"),
    800: Logic(
        "standard", "1:target;3:target;4:self;5:self", CORE,
        "hiệu ứng theo nhánh quảng quân tửu; ô 0, 2 chưa dùng"),
    801: Logic(
        "standard", "0:self;1:target;2:self_tick;3:target_tick;4:self;5:trap", FULL,
        "như logic 1, thêm hiệu ứng thứ hai cho bản thân và bẫy dưới chân"),
    802: Logic(
        "standard", "0:target", CORE,
        "hiệu ứng một lần"),
    803: Logic(
        "standard", "0:target", CORE,
        "hiệu ứng lên mục tiêu; ô 1 (số mục tiêu quanh) chưa dùng"),
    833: Logic(
        "unsupported", "", EVENT,
        "sát thương thật theo tỉ lệ máu: ô không có id hiệu ứng, công thức chưa có nguồn"),
    835: Logic(
        "standard", "0:target", CORE,
        "buff lên mục tiêu"),
    836: Logic(
        "standard", "0:target", CORE,
        "hiệu ứng một lần"),
    837: Logic(
        "standard", "0:target", CORE,
        "buff khống chế"),
    838: Logic(
        "standard", "0:target;1:target", CORE,
        "buff khống chế và sát thương trực tiếp"),
    840: Logic(
        "standard", "4:self", CORE,
        "buff dịch chuyển; ô 1 (bán kính bẫy), 3 (xác suất đao vực) chưa dùng"),
    841: Logic(
        "standard", "0:self;1:self;2:target", FULL,
        "buff đao ý, buff dịch chuyển, hiệu ứng lên mục tiêu"),
    842: Logic(
        "standard", "0:target", CORE,
        "hiệu ứng một lần"),
    862: Logic(
        "standard", "0:trap;1:self;2:self", CORE,
        "đặt bẫy, buff dịch chuyển, hiệu ứng cho bản thân"),
    864: Logic(
        "standard", "0:self;1:target;2:target;3:cut_cooldown+4", CORE,
        "hiệu ứng cho bản thân, mục tiêu, sát thương, rồi giảm hồi chiêu một nhóm"),
    865: Logic(
        "standard", "0:target", CORE,
        (
        "sát thương cơ bản; ô 1..9 (hệ số theo số hồn mất) chưa dùng. hệ ba hồn: cần trạng thái hồn của mục tiêu "
        "để chọn hiệu ứng, lõi chưa theo dõi")),
    866: Logic(
        "standard", "0:target;1:target;2:target", CORE,
        "hiệu ứng một lần lên mục tiêu"),
    867: Logic(
        "standard", "0:target", CORE,
        (
        "sát thương cơ bản; ô 1..5 (hệ số theo số hồn mất, chém giết) chưa dùng. hệ ba hồn: cần trạng thái hồn "
        "của mục tiêu để chọn hiệu ứng, lõi chưa theo dõi")),
    868: Logic(
        "standard", "0:target", CORE,
        (
        "sát thương cơ bản; ô 1..11 (đốt hồn, tê liệt, xoá hồi chiêu) chưa dùng. hệ ba hồn: cần trạng thái hồn "
        "của mục tiêu để chọn hiệu ứng, lõi chưa theo dõi")),
    869: Logic(
        "unsupported", "0:self;1:self;2:self", EVENT,
        "hệ ba hồn: cần trạng thái hồn của mục tiêu để chọn hiệu ứng, lõi chưa theo dõi"),
    870: Logic(
        "unsupported", "1:self@0;2:self@0;3:self@0;4:self;5:self;6:self", EVENT,
        "hệ ba hồn: cần trạng thái hồn của mục tiêu để chọn hiệu ứng, lõi chưa theo dõi"),
    882: Logic(
        "standard", "0:self;1:target;2:self_tick;3:target_tick", FULL,
        "như logic 1; ô 4 (xác suất hội tâm) chưa dùng"),
    883: Logic(
        "unsupported", "", EVENT,
        "hiệu ứng theo mức máu mục tiêu (trên/dưới 40%): chưa có vai điều kiện máu"),
    884: Logic(
        "standard", "0:target", FULL,
        "hiệu ứng một lần"),
    885: Logic(
        "standard", "1:target", CORE,
        "hiệu ứng lên mục tiêu; ô 4..7 (hội tâm gây nổ lan) chưa dùng"),
    886: Logic(
        "unsupported", "", EVENT,
        "không có tham số hiệu ứng trong bảng"),
    887: Logic(
        "standard", "0:target", CORE,
        "sát thương; ô 1..6 (buff hội tâm chồng tầng) chưa dùng"),
    901: Logic(
        "standard", "0:target;1:target", CORE,
        "sát thương và choáng lên mục tiêu"),
}

EFFECT_LOGICS: dict[int, Logic] = {
    0: Logic(
        "none", "", FULL,
        "hiệu ứng hình ảnh (nâng cấp): không đổi trạng thái"),
    1: Logic(
        "damage_flat", "", FULL,
        "sát thương thẳng một số"),
    2: Logic(
        "damage_percent", "", CORE,
        "sát thương theo phần trăm HP tối đa; lõi dùng HP tối đa hiện tại, bản 2008 dùng HP gốc"),
    3: Logic(
        "damage_attack", "", FULL,
        "sát thương sáu kênh theo công thức chiến đấu, cộng sát thương thẳng"),
    4: Logic(
        "restore_value", "", FULL,
        "đổi HP/MP/nộ khí/liên kích theo số"),
    5: Logic(
        "restore_rate", "", CORE,
        "đổi HP/MP/nộ khí/liên kích theo phần trăm mức tối đa; bỏ phép cộng 100 sai của bản 2008"),
    6: Logic(
        "pet_event", "", EVENT,
        "hồi phục cho thú cưng: module thú cưng làm"),
    8: Logic(
        "aggro_switch", "", EVENT,
        "khiêu khích/đổi mục tiêu của quái: AI quái làm theo sự kiện kAggro"),
    9: Logic(
        "teleport", "", CORE,
        "dịch chuyển; khác cảnh chỉ phát sự kiện cho zone"),
    10: Logic(
        "composite", ("0:sub;1:sub;2:sub;3:sub;4:sub;5:sub;6:sub;7:sub;8:sub;9:sub;"
            "10:sub;11:sub;12:sub;13:sub;14:sub;15:sub"), FULL,
        "gửi các hiệu ứng con lên người mang theo chu kỳ"),
    11: Logic(
        "stat_point", "", FULL,
        "cộng điểm vào 16 chỉ số công/thủ/kháng/tối đa"),
    12: Logic(
        "stat_rate", "", FULL,
        "cộng phần trăm vào 16 chỉ số công/thủ/kháng/tối đa"),
    13: Logic(
        "stat_hit", "", FULL,
        "cộng điểm trúng, né, hội tâm, hội tâm phòng"),
    14: Logic(
        "state_flags", "", FULL,
        "cờ trạng thái: hành động, di chuyển, bất tử, tốc chạy, ẩn thân, mô hình, bộ lọc kỹ năng/hiệu ứng"),
    15: Logic(
        "stat_primary", "", FULL,
        "cộng điểm thuộc tính cấp một"),
    16: Logic(
        "stat_primary_rate", "", FULL,
        "cộng phần trăm thuộc tính cấp một"),
    17: Logic(
        "immunity", "", FULL,
        "miễn nhiễm hiệu ứng thuộc các tập, theo cấp"),
    18: Logic(
        "dispel", "", FULL,
        "gỡ buff thuộc các tập"),
    19: Logic(
        "refix_impact", "", FULL,
        "chỉnh sức mạnh/thời gian hiệu ứng gửi đi"),
    20: Logic(
        "self_resurrect", "", CORE,
        "tự hồi sinh khi chết; lõi đặt đề nghị hồi sinh cho người chơi chấp nhận"),
    21: Logic(
        "skill_refix", "", FULL,
        "chỉnh kỹ năng trong tập: trúng, hội tâm, uy lực, tiêu hao, thời gian, hồi chiêu, gom, dẫn; có số lần"),
    22: Logic(
        "counter", "", CORE,
        "phản kích; sát thương phản trừ ngay thay vì trễ 500 ms"),
    23: Logic(
        "guard", "", FULL,
        "giảm sát thương nhận, hút nội lực và nộ khí đối phương"),
    24: Logic(
        "immune_odds", "", FULL,
        "xác suất hấp thụ hiệu ứng thuộc tập"),
    25: Logic(
        "crit_absorb", "", FULL,
        "xác suất hấp thụ hiệu ứng đến từ hội tâm"),
    26: Logic(
        "shield", "", FULL,
        "khiên sát thương: hút, miễn, phản"),
    27: Logic(
        "pet_event", "", EVENT,
        "chuyển sát thương của thú cưng: module thú cưng làm"),
    28: Logic(
        "pet_event", "", EVENT,
        "sát thương theo hệ của thú cưng: module thú cưng làm"),
    29: Logic(
        "absorb_shield", "", CORE,
        "khiên hút sát thương, giảm tiêu hao và thời gian gom; sửa RefixPowerByRate chia 1000 của bản 2008"),
    35: Logic(
        "terror", "", CORE,
        "choáng: không hành động được; AI hoảng sợ do zone làm theo cờ trạng thái"),
    36: Logic(
        "stat_detect", "", CORE,
        "cộng cấp dò ẩn thân"),
    38: Logic(
        "none", "", FULL,
        "buff đánh dấu (câu cá): không đổi trạng thái"),
    51: Logic(
        "none", "", FULL,
        "buff đánh dấu (phân thân): ảnh vệ do module ngoài lõi quản"),
    52: Logic(
        "none", "", FULL,
        "buff đánh dấu (ghi bẫy): quản bẫy do zone làm"),
    53: Logic(
        "cooldown_reset", "", FULL,
        "xoá hồi chiêu mọi kỹ năng đã học, trừ bốn nhóm"),
    54: Logic(
        "resurrect", "", CORE,
        "hồi sinh người đã chết; lõi đặt đề nghị hồi sinh cho người chơi chấp nhận"),
    56: Logic(
        "stat_mixed", "", CORE,
        "cộng trúng, né, hội tâm; phần trăm HP tối đa và công/thủ gốc"),
    57: Logic(
        "pet_event", "", EVENT,
        "thú cưng chia máu cho chủ: module thú cưng làm"),
    58: Logic(
        "friendliness", "", FULL,
        "tặng điểm thân thiện"),
    59: Logic(
        "stat_tough", "", CORE,
        "tăng nộ khí nhận, kháng bốn hệ, thủ, HP tối đa, né"),
    60: Logic(
        "rage_trigger", "2:target;3:self", CORE,
        "tăng nộ khí nhận; trúng địch có xác suất giáng hiệu ứng. Thời điểm kích hoạt suy từ dữ liệu"),
    61: Logic(
        "skill_refix_time", "", CORE,
        "bớt thời gian gom và hồi chiêu của kỹ năng trong tập, chỉnh trúng và hội tâm"),
    62: Logic(
        "ignore_disturb", "", FULL,
        "gom/dẫn khí không bị gián đoạn"),
    64: Logic(
        "ignore_defence", "", CORE,
        "đòn sát thương công thức kế tiếp bỏ qua phòng thủ ngoại và nội"),
    65: Logic(
        "combo_points", "", CORE,
        "nâng trần điểm liên kích, cộng điểm khi đánh trúng địch"),
    66: Logic(
        "absorb_percent", "", CORE,
        "hấp thụ một phần trăm sát thương nhận; nghĩa suy từ tên cột"),
    67: Logic(
        "hp_threshold", "", CORE,
        "một nhát theo phần trăm HP hiện tại, có sát thương tối thiểu"),
    68: Logic(
        "explosion", "2:sub", CORE,
        "nổ quanh người mang, gửi hiệu ứng con cho địch của người tạo"),
    69: Logic(
        "damage_amp", "", CORE,
        "người mang nhận thêm sát thương từ kỹ năng trong tập"),
    70: Logic(
        "steal", "", CORE,
        "sát thương kèm hút HP, MP, nộ khí về người tạo"),
    72: Logic(
        "none", "", FULL,
        "buff đánh dấu (đảo ngược càn khôn): kỹ năng khác hỏi qua tập buff"),
    74: Logic(
        "taunt", "", EVENT,
        "chế giễu: quái buộc đánh người tạo qua sự kiện kAggro, giảm phòng ngự nội"),
    76: Logic(
        "mark_damage", "", CORE,
        "sát thương từ kỹ năng trong tập kèm lượng cố định ở một kênh"),
    77: Logic(
        "mark_trigger", "1:sub", CORE,
        "trúng sát thương từ kỹ năng trong tập thì có xác suất nhận thêm hiệu ứng"),
    79: Logic(
        "stat_weaken", "", CORE,
        "không đi được và tăng công mọi hệ theo phần trăm"),
    81: Logic(
        "damage_boost", "", CORE,
        "khuếch đại sát thương gây ra; khác bản 2008 vì hook OnDamageTarget đổi được con số trừ máu"),
    83: Logic(
        "immunity_flags", "", CORE,
        "miễn hẳn sát thương ngoại và/hoặc nội công"),
    86: Logic(
        "interval_aoe", "6:sub;7:sub;8:sub", CORE,
        "vùng gây hiệu ứng theo chu kỳ quanh người mang; chọn đồng đội cần module tổ đội"),
    87: Logic(
        "none", "", FULL,
        "buff đánh dấu (cưỡi): trạng thái cưỡi do zone quản"),
    88: Logic(
        "trigger_on_hit", "5:self;6:self;7:target;8:target", CORE,
        "xác suất kích hoạt hiệu ứng khi gây/nhận sát thương hay hội tâm"),
    89: Logic(
        "reflect", "", CORE,
        "xác suất phản một phần sát thương về người đánh"),
    90: Logic(
        "script_event", "", EVENT,
        "gọi script: lõi chỉ báo mã script, không chạy Lua"),
    91: Logic(
        "stat_attack_rate", "", CORE,
        "cộng phần trăm công ngoại và nội"),
    92: Logic(
        "damage_amp_kind", "", CORE,
        "như logic 69, tỉ lệ khác cho quái và người"),
    93: Logic(
        "skill_refix_rage", "", CORE,
        "bớt thời gian gom và hồi chiêu của kỹ năng trong tập, tăng nộ khí nhận"),
    94: Logic(
        "stat_resist_reduce", "", CORE,
        "giảm kháng bốn hệ của đối phương khi mình gây sát thương"),
    95: Logic(
        "stat_chariot", "", CORE,
        "cộng thủ và kháng rất lớn (xe chiến); ô 6 là mã script, lõi chỉ báo"),
}
