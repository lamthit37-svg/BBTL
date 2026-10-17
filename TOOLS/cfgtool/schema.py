"""Lược đồ cấu hình máy chủ THIENLONG, chép từ bộ đọc C++ (src/server/config/*.cpp).

Mỗi khoá ghi đúng như bộ đọc: kiểu, miền, bắt buộc hay tuỳ chọn, mặc định (chỉ khoá tuỳ chọn mới có),
cùng mô tả tiếng Việt và hướng dẫn đặt giá trị cho máy chủ chạy thật. Khi bộ đọc C++ đổi, sửa tệp này
theo; test_cfgtool.py đối chiếu kết quả kiểm với chính thienlong_lint.exe để bắt chỗ lệch.
"""
from __future__ import annotations

from dataclasses import dataclass, field

INT_MOST = 2**31 - 1  # kIntMost: mọi số nguyên cấu hình nằm trong int32
NAME_MOST, PATH_MOST, IDENT_MOST, PASSWORD_MOST = 64, 512, 63, 256


@dataclass(frozen=True)
class Field:
    key: str                 # tên khoá trong nhóm
    kind: str                # xem KIND_TEXT
    desc: str                # chức năng
    guide: str = ""          # cách đặt cho production
    prod: str = ""           # giá trị gợi ý cho production (dạng TOML)
    lo: int | None = None
    hi: int | None = None
    most: int | None = None  # số phần tử tối đa của mảng
    choices: tuple[str, ...] = ()
    required: bool = True
    default: str = ""        # chỉ khoá tuỳ chọn: giá trị máy chủ dùng khi thiếu khoá
    unit: str = ""
    secret: bool = False


@dataclass(frozen=True)
class Group:
    path: str                # "" là gốc tệp; "database.postgres" là nhóm lồng
    title: str               # tên nhóm tiếng Việt (dùng cho khung tiêu đề khi dựng tệp chuẩn)
    fields: tuple[Field, ...] = ()
    rows: bool = False       # [[path]]
    required: bool = True
    most: int = 0            # trần số khối [[...]]
    about: str = ""


@dataclass(frozen=True)
class FileSpec:
    name: str
    title: str               # tiêu đề in hoa
    intro: tuple[str, ...]
    reader: str              # hàm C++ đọc tệp
    groups: tuple[Group, ...]
    note: str = ""


KIND_TEXT = {
    "schema": "số nguyên, đúng bằng 1",
    "int": "số nguyên",
    "flag": "true/false",
    "text": "chuỗi",
    "ident": "tên định danh (chữ cái đầu, rồi chữ, số, _ hoặc -; tối đa 63)",
    "port": "cổng 1–65535",
    "listen_port": "cổng 1–65535 (0 chỉ khi host là 127.0.0.1)",
    "ipv4": "địa chỉ IPv4 a.b.c.d",
    "endpoint": "\"a.b.c.d:cổng\" (cổng 0 chỉ với 127.0.0.1)",
    "ipv4_list": "mảng địa chỉ IPv4",
    "cidr_list": "mảng dải CIDR IPv4 \"a.b.c.d/n\"",
    "hours": "mảng giờ 0–23, không lặp, tối đa 24",
    "int_list": "mảng số nguyên, không lặp",
    "choice": "một trong tập giá trị",
}

SCHEMA = Field("schema", "schema", "Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu.",
               "Luôn để 1. Không sửa.", "1", lo=1, hi=1)


def count(key, desc, guide="", prod="", unit="", lo=1, hi=INT_MOST, **kw):
    return Field(key, "int", desc, guide, prod, lo=lo, hi=hi, unit=unit, **kw)


def amount(key, desc, guide="", prod="", unit="", **kw):
    return Field(key, "int", desc, guide, prod, lo=0, hi=INT_MOST, unit=unit, **kw)


def flag(key, desc, guide="", prod="", **kw):
    return Field(key, "flag", desc, guide, prod, **kw)


def path(key, desc, guide="", prod=""):
    return Field(key, "text", desc, guide, prod, lo=1, hi=PATH_MOST)


def db_group(name: str, user: str, pool: str) -> Group:
    return Group("database", "Database", (
        Field("name", "ident", "Tên database PostgreSQL mà tiến trình nối tới.",
              "Giữ đúng tên do setup_db.py tạo; đổi tên phải đổi cả database thật.", f'"{name}"'),
        Field("user", "ident", "Role PostgreSQL dùng để nối; chỉ có quyền trên database này.",
              "Mỗi dịch vụ một role riêng, không dùng role postgres. Mật khẩu nằm ở secrets.local.toml.",
              f'"{user}"'),
        count("pool", "Số kết nối giữ sẵn tới database.",
              "Bắt đầu 2–8; tăng khi đo thấy hàng chờ truy vấn. Tổng pool mọi tiến trình phải nhỏ hơn "
              "max_connections của PostgreSQL.", pool),
    ), about="Địa chỉ cụm PostgreSQL nằm ở cluster.toml, mật khẩu ở secrets.local.toml.")


FILES: dict[str, FileSpec] = {}


def add(spec: FileSpec) -> None:
    FILES[spec.name] = spec


add(FileSpec("admin.toml", "CẤU HÌNH CỔNG QUẢN TRỊ", ("Tệp: admin.toml. Trình giám sát và công cụ quản trị đọc tệp này.",),
    "config::read_admin (admin.cpp)", (
    Group("", "Chung", (
        SCHEMA,
        Field("listen", "endpoint", "Địa chỉ và cổng của cổng quản trị.",
              "Production: chỉ nghe 127.0.0.1 để phải ngồi ở máy chủ mới nối được. Không mở ra mạng.",
              '"127.0.0.1:7002"'),
        path("token_file", "Tệp mã bí mật mà công cụ quản trị phải trình khi nối (đường dẫn tương đối "
             "tính từ thư mục config).", "Đặt ngoài thư mục web, quyền đọc chỉ cho tài khoản chạy dịch vụ. "
             "Công cụ không bao giờ mở hay in tệp này.", '"../data/admin/token"'),
    )),
    Group("operator", "Người vận hành", (
        Field("name", "text", "Tên người vận hành.", "Tên ngắn, không dấu cách thừa.", '"admin"', lo=1, hi=NAME_MOST),
        amount("level", "Cấp quyền của người vận hành.", "Cấp thấp nhất đủ dùng.", "1"),
    ), rows=True, required=False, most=64, about="Khối tuỳ chọn, tối đa 64 khối."),
)))

add(FileSpec("auth.toml", "CẤU HÌNH DỊCH VỤ TÀI KHOẢN (AUTH)", ("Tệp: auth.toml. Chỉ tiến trình auth đọc tệp này.",),
    "config::read_auth (auth.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    db_group("thienlong_auth", "thienlong_auth", "4"),
    Group("register", "Đăng ký", (
        flag("auto_register", "true: đăng nhập bằng tên chưa có thì tạo luôn tài khoản.",
             "Production: false, để đăng ký đi qua trang đăng ký có kiểm soát; true chỉ cho máy thử.", "false"),
        amount("gift_points", "Số điểm nạp tặng cho tài khoản mới.", "0 trừ khi có chương trình khuyến mãi.", "0"),
    )),
    Group("password", "Băm mật khẩu", (
        count("ops_limit", "Số lượt tính của một lần băm Argon2id.",
              "Tối thiểu 2 (INTERACTIVE). Tăng lên 3 nếu máy dư CPU; đo thời gian đăng nhập < 0,5 giây.", "3"),
        count("mem_limit_kib", "Bộ nhớ của một lần băm Argon2id.",
              "Tối thiểu 65536 (64 MiB). Nhân với số đăng nhập đồng thời để chắc đủ RAM.", "65536", unit="KiB"),
    ), about="Tham số Argon2id của libsodium."),
    Group("ticket", "Vé đăng nhập", (
        amount("ttl_seconds", "Vé đăng nhập hết hạn sau bao nhiêu giây.",
               "60–300. Ngắn hơn thì vé lộ ít nguy hiểm hơn.", "120", unit="giây"),
    )),
    Group("login", "Luật đăng nhập", (
        flag("relogin_limit", "true: cùng một IP phải cách 20 giây mới được đăng nhập lại.",
             "Production: true để chặn dò mật khẩu nhanh.", "true"),
        flag("relogin_block", "true: đang online mà có đăng nhập từ IP khác thì đá phiên cũ và chặn.",
             "Bật nếu muốn chống chia sẻ tài khoản; cân nhắc người chơi đổi mạng 4G/Wi-Fi.", "false"),
        amount("relogin_block_ms", "Thời gian chặn của relogin_block.", "600000 (10 phút).", "600000", unit="mili giây"),
        count("queue_turn_size", "Số người trong hàng chờ được vào mỗi lượt khi máy chủ đầy.",
              "50–200 tuỳ sức zone.", "100"),
        count("max_sessions_per_device", "Số phiên cùng lúc cho một máy client.",
              "Production: 2–5 để hạn chế treo nhiều nick; bản thử để 30.", "3"),
    )),
    Group("captcha", "Mã xác minh", (
        flag("on_create", "true: hỏi mã xác minh khi tạo nhân vật.", "Bật khi bị tạo nick hàng loạt.", "false"),
        flag("on_enter", "true: hỏi mã xác minh khi vào game.", "Bật khi bị bot.", "false"),
    )),
    Group("security_card", "Thẻ bảo mật", (
        flag("enabled", "true: tài khoản có gắn thẻ phải trả lời ô thẻ khi đăng nhập.", "Tuỳ chính sách.", "false"),
    )),
)))

add(FileSpec("billing.toml", "CẤU HÌNH DỊCH VỤ NẠP TIỀN (BILLING)", ("Tệp: billing.toml. Chỉ tiến trình billing đọc tệp này.",),
    "config::read_billing (billing.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    db_group("thienlong_billing", "thienlong_billing", "2"),
    Group("access", "Quyền gọi", (
        Field("allow", "ipv4_list", "Địa chỉ được gọi billing; địa chỉ khác bị từ chối.",
              "Chỉ IP của máy chạy world. Một máy: [\"127.0.0.1\"].", '["127.0.0.1"]'),
    )),
    Group("limits", "Trần kết nối", (count("max_clients", "Số kết nối cùng lúc tới billing.", "Vài chục là đủ; chỉ world nối.", "64"),)),
    Group("points", "Điểm nạp", (
        count("ingot_per_point", "Một điểm nạp đổi được bao nhiêu ingot.", "Theo tỉ giá kinh doanh đã chốt.", "1"),
        amount("register_gift", "Số điểm nạp tặng khi tài khoản được tạo.", "0 trừ khi có khuyến mãi.", "0"),
    )),
    Group("spend", "Hạn mức tiêu", (amount("daily_ingot_cap", "Số ingot tối đa một nhân vật được tiêu mỗi ngày.",
                                         "Chặn thiệt hại khi tài khoản bị chiếm.", "120000"),)),
    Group("orders", "Đơn hàng", (
        amount("pending_timeout_seconds", "Đơn chờ game xác nhận quá số giây này thì sang đối soát.", "300–900.", "600", unit="giây"),
        amount("reconcile_interval_seconds", "Chu kỳ đối soát các đơn còn chờ.", "30–120.", "60", unit="giây"),
    )),
    Group("redeem", "Mã đổi", (amount("attempts_per_hour", "Số lần nhập mã tối đa mỗi giờ cho một tài khoản.",
                                     "5–10 để chống dò mã.", "5"),)),
    Group("webhook", "Webhook thanh toán", (
        Field("port", "int", "Cổng HTTP của webhook, chỉ nghe 127.0.0.1 sau reverse proxy có TLS.",
              "Cổng cố định 1024–65535; 0 (hệ điều hành chọn) chỉ dùng cho test. Chỉ nghe khi có [[provider]] bật.",
              "7014", lo=0, hi=65535),
    )),
    Group("provider", "Nhà cung cấp thanh toán", (
        Field("key", "text", "Mã nhà cung cấp.", "Tên ngắn, duy nhất.", '"momo"', lo=1, hi=NAME_MOST),
        path("webhook_path", "Đường dẫn HTTP nhà cung cấp gọi vào.", "Khó đoán, ví dụ có chuỗi ngẫu nhiên.", '"/pay/momo"'),
        path("secret_file", "Tệp chứa khoá ký của nhà cung cấp.", "Ngoài git, quyền đọc hạn chế. Công cụ không mở tệp này.",
             '"../data/billing/momo.key"'),
        flag("enabled", "Bật nhà cung cấp này.", "Chỉ bật khi đã thử webhook ở môi trường test.", "true"),
    ), rows=True, required=False, most=32, about="Khối tuỳ chọn; mỗi khối phải đủ 4 khoá. Tối đa 32 khối."),
)))

add(FileSpec("client.toml", "CẤU HÌNH GIAO DIỆN CLIENT", ("Tệp: client.toml. Chỉ tiến trình gate đọc tệp này.",),
    "config::read_client (client.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    Group("hud", "Giao diện", (
        Field("avatar_frame", "choice", "Dạng khung chân dung của HUD: square là classic (nền vuông, ảnh 2D), "
              "round là nền tròn đầu 3D.", "Chọn theo bản client phát hành.", '"square"', choices=("round", "square")),
    )),
)))

add(FileSpec("cluster.toml", "CẤU HÌNH CỤM MÁY CHỦ", ("Tệp: cluster.toml. Mọi tiến trình đều đọc tệp này.",
    "Đường dẫn tương đối tính từ thư mục của tệp này."), "config::read_cluster (cluster.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    Group("world", "Thế giới game", (
        count("id", "Số của thế giới, từ 1; database game mang tên thienlong_game_<id>.",
              "Mỗi máy chủ (server) một id riêng, không dùng lại. Phải khớp store.toml [database] name.", "1"),
        amount("zone_group", "Nhóm máy chủ; các thế giới cùng nhóm chung một danh sách chọn máy chủ.", "Theo quy hoạch cụm.", "0"),
        Field("name", "text", "Tên cụm trong log và công cụ quản trị; không gửi cho client.", "Tên dễ nhận ra, ví dụ \"tlbb-s1\".",
              '"tlbb-s1"', lo=1, hi=NAME_MOST),
        Field("table_variant", "text", "Bộ bảng thay thế theo loại máy chủ; rỗng là dùng bảng gốc.", "Thường để rỗng.",
              '""', lo=0, hi=NAME_MOST),
    )),
    Group("postgres", "Cụm PostgreSQL", (
        Field("host", "ipv4", "Địa chỉ cụm PostgreSQL nghe.", "Production: 127.0.0.1 hoặc IP mạng nội bộ; không mở ra Internet.", '"127.0.0.1"'),
        Field("port", "port", "Cổng TCP của cụm.", "5432 hoặc cổng nội bộ tuỳ chọn.", "5432", lo=1, hi=65535),
        path("bin_dir", "Thư mục chứa postgres.exe, pg_ctl.exe, psql.exe.", "Đường dẫn tới bản PostgreSQL đi kèm.", '"../pgsql/bin"'),
        path("data_dir", "Thư mục dữ liệu; xoá là mất mọi tài khoản và nhân vật.", "Ổ riêng, có sao lưu định kỳ.", '"../data/pg"'),
        path("log_file", "Tệp log của tiến trình postgres.", "Thư mục log có xoay vòng.", '"../log/postgres.log"'),
    )),
    Group("machine", "Máy vật lý", (
        amount("id", "Số của máy; khoá machine của [[process]] trỏ tới số này.", "0, 1, 2…; không lặp.", "0"),
    ), rows=True, required=True, most=256, about="Ít nhất một khối; tối đa 256; id không lặp."),
    Group("process", "Tiến trình", (
        Field("kind", "choice", "Loại tiến trình.", "Cần đủ store, auth, billing, world và ít nhất một zone.",
              '"zone"', choices=("store", "auth", "billing", "world", "zone")),
        amount("id", "Số thứ tự trong cùng loại, từ 0.", "Cặp (kind, id) không lặp.", "0"),
        amount("machine", "Máy chạy tiến trình, theo id của [[machine]].", "Phải có trong danh sách [[machine]].", "0"),
        Field("host", "ipv4", "Địa chỉ mà cổng ipc nghe.", "127.0.0.1 khi một máy; IP LAN nội bộ khi nhiều máy. Không IP công khai.",
              '"127.0.0.1"'),
        Field("port", "listen_port", "Cổng ipc nội bộ.", "Cổng cố định không trùng; 0 chỉ khi host là 127.0.0.1 (test).", "7020"),
    ), rows=True, required=True, most=256, about="Ít nhất một khối; tối đa 256."),
)))

add(FileSpec("gate.toml", "CẤU HÌNH CỔNG CÔNG KHAI (GATE)", ("Tệp: gate.toml. Chỉ tiến trình gate đọc tệp này.",),
    "config::read_gate (gate.cpp)", (
    Group("", "Chung", (
        SCHEMA,
        path("identity_key_file", "Khoá danh tính của máy chủ; mất là client phải cài lại.",
             "Sao lưu an toàn, không đưa vào git. Công cụ không mở tệp này.", '"../data/gate/identity.key"'),
        Field("trusted_proxies", "ipv4_list", "Proxy được tin để đọc IP thật của client; rỗng là không có.",
              "Chỉ điền IP proxy/LB của mình; điền sai là cho kẻ gian giả IP.", "[]"),
    )),
    Group("listen", "Cổng nghe", (
        Field("game", "endpoint", "Cổng chơi game: client đã có vé nối vào đây.", "\"0.0.0.0:7000\" hoặc IP công khai cụ thể.", '"0.0.0.0:7000"'),
        Field("auth", "endpoint", "Cổng xác thực: đăng ký, đăng nhập lấy vé.", "\"0.0.0.0:7001\".", '"0.0.0.0:7001"'),
    )),
    Group("limits", "Trần chống lạm dụng", (
        count("max_connections", "Tổng số kết nối client cùng lúc.", "≈ 1,2 × số người online dự kiến.", "5000"),
        count("per_ip_connections", "Số kết nối cùng lúc từ một địa chỉ IP (hoặc một dải, xem per_ip_prefix).",
              "4–8 với /32; tăng nếu nhiều người chung NAT.", "8"),
        amount("handshake_timeout_ms", "Hạn xong bắt tay bảo mật; quá hạn thì ngắt.", "3000–5000.", "5000", unit="mili giây"),
        amount("idle_timeout_ms", "Hạn im lặng sau bắt tay; quá hạn thì ngắt.", "10000–30000.", "15000", unit="mili giây"),
        count("client_frame_bytes", "Số byte tối đa của thân một tin từ client.", "Giữ 4096 trừ khi protocol đổi.", "4096", unit="byte"),
        count("messages_per_second", "Số tin tối đa mỗi giây của một client; vượt thì ngắt.", "40–60.", "60"),
        Field("per_ip_prefix", "int", "Gom trần per_ip_connections theo dải /N (32 = từng IP, 24 = cả dải /24).",
              "32 mặc định; 24 khi bị tấn công từ cả dải.", "32", lo=16, hi=32, required=False, default="32"),
    )),
    Group("client", "Bản client", (count("min_version", "Phiên bản protocol thấp nhất được vào; thấp hơn bị từ chối.",
                                        "Nâng khi phát hành client bắt buộc cập nhật.", "1"),)),
    Group("ip_filter", "Lọc địa chỉ IP", (
        Field("allow", "cidr_list", "Dải được nối; rỗng là mọi địa chỉ đều được nối.", "Thường rỗng; dùng khi chỉ mở cho LAN/khu vực.", "[]"),
        Field("deny", "cidr_list", "Dải bị từ chối; xét trước allow.", "Thêm dải đang tấn công.", "[]"),
    )),
    Group("resume", "Nối lại phiên", (
        flag("bind_to_ip", "true: Resume từ IP khác IP đã vào game thì huỷ phiên (token coi như lộ).",
             "true; tắt chỉ khi người chơi di động hay đổi mạng.", "true", required=False, default="true"),
        Field("grace_ms", "int", "Phiên rớt mạng chờ Resume bao lâu; 0 là tắt Resume.", "15000–30000.", "30000",
              lo=0, hi=300000, required=False, default="30000", unit="mili giây"),
    ), required=False, about="Nhóm tuỳ chọn."),
)))

add(FileSpec("log.toml", "CẤU HÌNH LOG", ("Tệp: log.toml. Mọi tiến trình đều đọc tệp này.",), "config::read_log (log.cpp)", (
    Group("", "Chung", (SCHEMA, flag("audit", "true: ghi thêm log thống kê và kiểm toán.", "Production: true.", "true"),
        flag("play_trace", "true: zone ghi một dòng kiểm cho mỗi việc của người chơi (dev/server/README.md).",
             "Production: false; dev: true.", "false", required=False, default="false"))),
    Group("file", "Tệp log", (
        path("dir", "Thư mục chứa tệp log; mỗi tiến trình một tệp.", "Ổ có đủ chỗ, có dọn định kỳ.", '"../log"'),
        count("rotate_mb", "Tệp log lớn quá số MB này thì mở tệp mới.", "64–256.", "128", unit="MB"),
    )),
    Group("level", "Mức log", (Field("default", "choice", "Mức log mặc định: error, warn, info, debug (ít tới nhiều).",
                                    "Production: info; debug chỉ khi điều tra lỗi.", '"info"',
                                    choices=("error", "warn", "info", "debug")),)),
)))

PW = "Không ghi mật khẩu thật vào tệp mẫu. Tệp thật secrets.local.toml do setup_db.py sinh và không bao giờ được mở bởi công cụ."
add(FileSpec("secrets.example.toml", "MẪU TỆP BÍ MẬT", ("Tệp: secrets.example.toml. Chỉ cho thấy hình dạng của secrets.local.toml.",),
    "config::read_secrets (secrets.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    Group("database", "Database", ()),
    *(Group(f"database.{role}", f"Role {role}", (
        Field("password", "text", f"Mật khẩu của role {role}.", PW, '""', lo=0, hi=PASSWORD_MOST, secret=True),))
      for role in ("postgres", "thienlong_auth", "thienlong_billing", "thienlong_store")),
), note="Tệp mẫu: mật khẩu luôn xuất ra rỗng."))

add(FileSpec("store.toml", "CẤU HÌNH TIẾN TRÌNH LƯU TRỮ (STORE)", ("Tệp: store.toml. Chỉ tiến trình store đọc tệp này.",),
    "config::read_store (store.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    db_group("thienlong_game_1", "thienlong_store", "4"),
    Group("flush", "Nhịp ghi", (
        amount("character_ms", "Thay đổi thường của nhân vật (vị trí, kinh nghiệm) nằm trong bộ nhớ tối đa bao lâu.",
               "10000–30000; nhỏ hơn thì sập mất ít hơn nhưng ghi đĩa nhiều hơn.", "15000", unit="mili giây"),
        amount("world_ms", "Thay đổi của dữ liệu world (bang, thư, xếp hạng) nằm trong bộ nhớ tối đa bao lâu.",
               "30000–60000.", "30000", unit="mili giây"),
    )),
    Group("journal", "Nhật ký ghi", (path("dir", "Thư mục chứa nhật ký ghi trước (chống mất dữ liệu khi sập).",
                                        "Ổ SSD, cùng máy với store, có sao lưu.", '"../data/store/journal"'),)),
    Group("security", "Bảo mật", (
        Field("standing_cache_ms", "int", "Store nhớ câu trả lời \"còn được chơi\" của auth chừng này; là cửa sổ tối đa sau khi ban.",
              "1000; 0 là mỗi lệnh đều hỏi auth.", "1000", lo=0, hi=10000, required=False, default="1000", unit="mili giây"),
        Field("name_reserve_days", "int", "Tên nhân vật xoá mềm giữ chỗ cho chủ cũ chừng này ngày.", "7–30.", "30",
              lo=0, hi=3650, required=False, default="30", unit="ngày"),
        Field("female_faces", "int_list", "Id mặt nữ tạo được (creatable = 1 trong faces.tsv).", "Khớp bảng client.",
              "[1, 2, 3, 4, 5, 14]", lo=0, hi=65534, most=256, required=False, default="[1, 2, 3, 4, 5, 14]"),
        Field("male_faces", "int_list", "Id mặt nam tạo được.", "Khớp bảng client.", "[100, 101, 102, 103, 104, 113]",
              lo=0, hi=65534, most=256, required=False, default="[100, 101, 102, 103, 104, 113]"),
        Field("female_hairs", "int_list", "Id tóc nữ tạo được (creatable = 1 trong hairs.tsv).", "Khớp bảng client.",
              "[1, 17, 19]", lo=0, hi=65534, most=256, required=False, default="[1, 17, 19]"),
        Field("male_hairs", "int_list", "Id tóc nam tạo được.", "Khớp bảng client.", "[5, 12, 14]",
              lo=0, hi=65534, most=256, required=False, default="[5, 12, 14]"),
    ), required=False, about="Nhóm tuỳ chọn; thiếu khoá thì dùng mặc định."),
)))

add(FileSpec("supervisor.toml", "CẤU HÌNH TRÌNH GIÁM SÁT (SUPERVISOR)", ("Tệp: supervisor.toml. Chỉ thienlong_server đọc tệp này.",),
    "config::read_supervisor (supervisor.cpp) + config::check_startup (startup.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    Group("postgres", "PostgreSQL", (
        flag("managed", "true: trình giám sát tự chạy và dừng cụm PostgreSQL.", "true khi PostgreSQL cùng máy; false khi dùng cụm riêng.", "true"),
        amount("ready_timeout_seconds", "Chờ cụm sẵn sàng tối đa bao nhiêu giây.", "60–120.", "90", unit="giây"),
    )),
    Group("restart", "Khởi động lại", (amount("max_per_hour", "Số lần chạy lại tối đa mỗi giờ cho một tiến trình.",
                                          "3–5; vượt thì dừng hẳn để người vận hành xem.", "3"),)),
    Group("stop", "Dừng", (amount("timeout_seconds", "Chờ một tiến trình tự thoát tối đa bao nhiêu giây rồi mới buộc dừng.",
                                  "≥ 30 để store kịp ép dữ liệu xuống đĩa.", "60", unit="giây"),)),
    Group("start", "Bước khởi động", (
        Field("process", "choice", "Tiến trình chạy ở bước này.", "Thứ tự chuẩn: store, auth, billing, world, zone, gate; không lặp.",
              '"store"', choices=("store", "auth", "billing", "world", "zone", "gate")),
        amount("ready_timeout_seconds", "Chờ sẵn sàng tối đa bao nhiêu giây.", "60 (store/gate) tới 240 (zone).", "60", unit="giây"),
    ), rows=True, required=True, most=16, about="Ít nhất một khối, tối đa 16; mỗi loại một bước."),
)))

add(FileSpec("world.toml", "CẤU HÌNH DỊCH VỤ THẾ GIỚI (WORLD)", ("Tệp: world.toml. Chỉ tiến trình world đọc tệp này.",),
    "config::read_world (world.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    Group("capacity", "Sức chứa", (
        count("online_users", "Số người chơi online cùng lúc.", "≥ max_connections của gate.", "5000"),
        count("mail_users", "Số người chơi có thư đang giữ trong bộ nhớ.", "≈ 10 × online.", "52000"),
        count("offline_cache", "Số người đã thoát còn giữ thông tin trong bộ nhớ.", "≈ 10 × online.", "50000"),
        count("speakers", "Số tin loa thế giới giữ trong hàng chờ phát.", "128.", "128"),
        count("pet_friend_ads", "Số tin tìm bạn cho trân thú giữ cùng lúc.", "1024.", "1024"),
    )),
    Group("player_count_report", "Báo cáo số người", (Field("hours", "hours", "Các giờ trong ngày ghi log số người ở từng cảnh.",
                                                         "Giờ cao điểm, ví dụ [13, 15, 21].", "[13, 15, 21]", lo=0, hi=23, most=24),)),
    Group("notice", "Thông báo hệ thống", (flag("join_guild", "true: báo lên kênh hệ thống khi có người vào bang.", "Tuỳ ý.", "false"),)),
    Group("platform", "Gặp nhau giữa PC và mobile", (flag("pc_meets_mobile", "true: người PC nhìn thấy người điện thoại.",
                                                        "Theo chính sách phát hành (chung hay tách máy chủ PC/mobile).", "true"),)),
)))

add(FileSpec("zone.toml", "CẤU HÌNH TIẾN TRÌNH CẢNH (ZONE)", ("Tệp: zone.toml. Mọi tiến trình zone đọc tệp này.",),
    "config::read_zone (zone.cpp)", (
    Group("", "Chung", (SCHEMA,)),
    Group("tick", "Nhịp mô phỏng", (count("hz", "Số bước mô phỏng mỗi giây; 20 là mỗi bước 50 mili giây.", "20; không đổi nếu chưa đo.", "20"),)),
    Group("aoi", "Vùng nhìn", (count("cell_size", "Cạnh một ô vùng nhìn, tính bằng đơn vị cảnh.", "10.", "10"),)),
    Group("capacity", "Sức chứa", (
        count("monsters", "Quái và NPC tối đa.", "≥ tổng spawn của mọi cảnh.", "49000"),
        count("pets", "Trân thú đang được gọi ra tối đa.", "≈ 0,7 × online.", "3000"),
        count("special_objects", "Bẫy và vùng hiệu ứng.", "1024.", "1024"),
        count("platforms", "Bàn chế tác của kỹ năng sống.", "1024.", "1024"),
        count("buses", "Xe chở khách.", "1024.", "1024"),
        count("player_shops", "Cửa hàng do người chơi mở.", "256.", "256"),
        count("scene_timers", "Bộ hẹn giờ của cảnh.", "64.", "64"),
        count("human_timers", "Bộ hẹn giờ mỗi người chơi được dùng.", "3.", "3"),
    )),
    Group("session", "Phiên người chơi", (
        amount("linger_after_disconnect_ms", "Nhân vật ở lại cảnh bao lâu sau khi rớt mạng.", "20000 (≥ grace_ms của gate là tốt).", "30000", unit="mili giây"),
        amount("linger_hidden_ms", "Ở lại thêm bao lâu sau khi đã bị ẩn khỏi cảnh.", "20000.", "20000", unit="mili giây"),
        amount("kick_idle_ms", "Client không phản hồi quá lâu thì bị đá.", "300000 (5 phút).", "300000", unit="mili giây"),
    )),
    Group("world_clock", "Đồng hồ thế giới", (amount("period_change_ms", "Một canh giờ trong game dài bao nhiêu mili giây thật.", "150000.", "150000", unit="mili giây"),)),
    Group("drops", "Rơi đồ", (amount("box_recycle_ms", "Gói đồ không ai nhặt biến mất sau bao lâu.", "60000.", "60000", unit="mili giây"),)),
    Group("audit", "Thống kê tin", (amount("packet_stats_ms", "Chu kỳ ghi thống kê tin mạng; 0 là không thống kê.", "0 hoặc 60000 khi theo dõi tải.", "0", unit="mili giây"),)),
)))


def spec_for(name: str) -> FileSpec | None:
    return FILES.get(name)


def is_secret_file(name: str) -> bool:
    """Tệp bí mật thật: máy chủ không bao giờ mở, công cụ cũng vậy."""
    return name.endswith(".local.toml")
