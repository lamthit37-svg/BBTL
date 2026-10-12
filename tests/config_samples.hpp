#pragma once
// Ca sai của config_tests, mỗi dòng một tệp cấu hình cụt và lỗi nó phải sinh, cùng hai văn bản tối
// thiểu. Nằm riêng để tệp .cpp không quá 500 dòng. Tệp cụt cố ý thiếu khoá: test chỉ tìm đúng một
// lỗi ở đúng dòng, các lỗi "thiếu khoá" đi kèm không được xét.

#include <array>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace game::test {

enum class Which : std::uint8_t {
    kCluster,
    kSupervisor,
    kLog,
    kGate,
    kAuth,
    kBilling,
    kWorld,
    kZone,
    kStore,
    kAdmin,
    kSecrets,
    kLoose,
};

using View = std::string_view;

// text là nội dung tệp; lỗi mong đợi nằm ở dòng line và câu của nó chứa part. Có constructor để mỗi
// dòng của bảng dưới viết gọn theo vị trí.
struct Sample {
    constexpr Sample(Which reader, View content, std::size_t row, View piece) noexcept
        : which(reader), text(content), line(row), part(piece) {}

    Which which;
    View text;
    std::size_t line;
    View part;
};

inline constexpr auto kSamples = std::to_array<Sample>({
    {Which::kCluster, "[world]\nid = 0\n", 2, "khoá id ngoài miền"},
    {Which::kCluster, "[world]\nzone_group = -1\n", 2, "zone_group ngoài miền"},
    {Which::kCluster, "[world]\nname = \"\"\n", 2, "khoá name ngoài miền"},
    {Which::kCluster, "[world]\nname = \"a\\u0001b\"\n", 2, "khoá name ngoài miền"},
    {Which::kCluster, "[postgres]\nport = 0\n", 2, "khoá port ngoài miền"},
    {Which::kCluster, "[postgres]\nport = 65536\n", 2, "khoá port ngoài miền"},
    {Which::kCluster, "[postgres]\nhost = \"01.2.3.4\"\n", 2, "khoá host ngoài miền"},
    {Which::kCluster, "[postgres]\nhost = \"1.2.3\"\n", 2, "khoá host ngoài miền"},
    {Which::kCluster, "[postgres]\nhost = \"1.2.3.256\"\n", 2, "khoá host ngoài miền"},
    {Which::kCluster, "[[process]]\nid = -1\n", 2, "khoá id ngoài miền"},
    {Which::kCluster, "[[machine]]\nid = -1\n", 2, "khoá id ngoài miền"},
    {Which::kCluster, "[[process]]\nkind = \"gate\"\n", 2, "khoá kind ngoài miền"},
    {Which::kCluster, "[[process]]\nkind = 1\n", 2, "khoá kind sai kiểu"},
    {Which::kCluster, "[[process]]\nhost = \"localhost\"\n", 2, "khoá host ngoài miền"},
    {Which::kCluster, "[[process]]\nhost = \"0.0.0.0\"\nport = 0\n", 3, "khoá port ngoài miền"},
    {Which::kCluster, "[[process]]\nhost = \"127.0.0.2\"\nport = 0\n", 3, "khoá port ngoài miền"},
    {Which::kCluster, "[[process]]\nhost = \"127.0.0.1\"\nport = 65536\n", 3, "khoá port ngoài miền"},
    {Which::kCluster, "[[process]]\nport = 0\n", 2, "khoá port ngoài miền"},
    {Which::kCluster, "[postgres]\nbin_dir = \"\"\n", 2, "bin_dir ngoài miền"},
    {Which::kCluster, "schema = 1\n[foo]\nx = 1\n", 2, "nhóm lạ foo"},
    {Which::kCluster, "schema = 1\n[[foo]]\nx = 1\n", 2, "nhóm lạ foo"},
    {Which::kCluster, "world = 1\n", 1, "khoá world sai kiểu"},
    {Which::kCluster, "machine = [1]\n", 1, "phần tử của machine sai kiểu"},
    {Which::kCluster, "[[machine]]\nid = 0\n[[machine]]\nid = 0\n", 3, "id máy lặp"},
    {Which::kSupervisor, "[stop]\ntimeout_seconds = -1\n", 2, "timeout_seconds ngoài miền"},
    {Which::kSupervisor, "[stop]\ntimeout_seconds = 2147483648\n", 2, "timeout_seconds ngoài miền"},
    {Which::kSupervisor, "[restart]\nmax_per_hour = -1\n", 2, "max_per_hour ngoài miền"},
    {Which::kSupervisor, "[restart]\nmax_per_hour = 4294967296\n", 2, "max_per_hour ngoài miền"},
    {Which::kSupervisor, "[[start]]\nprocess = \"nope\"\n", 2, "khoá process ngoài miền"},
    {Which::kSupervisor, "[postgres]\nmanaged = 1\n", 2, "khoá managed sai kiểu"},
    {Which::kLog, "[file]\nrotate_mb = 0\n", 2, "rotate_mb ngoài miền"},
    {Which::kLog, "[level]\ndefault = \"trace\"\n", 2, "khoá default ngoài miền"},
    {Which::kLog, "[file]\ndir = \"\"\n", 2, "khoá dir ngoài miền"},
    {Which::kLog, "audit = 1979-05-27\n", 1, "khoá audit sai kiểu"},
    {Which::kGate, "[listen]\ngame = \"nope\"\n", 2, "khoá game ngoài miền"},
    {Which::kGate, "[listen]\ngame = \"0.0.0.0:0\"\n", 2, "khoá game ngoài miền"},
    {Which::kGate, "[listen]\ngame = \"127.0.0.2:0\"\n", 2, "khoá game ngoài miền"},
    {Which::kGate, "[listen]\nauth = \"127.0.0.1:00\"\n", 2, "khoá auth ngoài miền"},
    {Which::kGate, "[listen]\ngame = \"0.0.0.0:65536\"\n", 2, "khoá game ngoài miền"},
    {Which::kGate, "[limits]\nmax_connections = 0\n", 2, "max_connections ngoài miền"},
    {Which::kGate, "[limits]\nmax_connections = 1.5\n", 2, "max_connections sai kiểu"},
    {Which::kGate, "[limits]\nhandshake_timeout_ms = -1\n", 2, "handshake_timeout_ms ngoài miền"},
    {Which::kGate, "[client]\nmin_version = 0\n", 2, "min_version ngoài miền"},
    {Which::kGate, "[ip_filter]\nallow = [\"nope\"]\n", 2, "khoá allow ngoài miền"},
    {Which::kGate, "[ip_filter]\nallow = [\"10.0.0.0/33\"]\n", 2, "khoá allow ngoài miền"},
    {Which::kGate, "[ip_filter]\ndeny = \"10.0.0.0/8\"\n", 2, "khoá deny sai kiểu"},
    {Which::kGate, "trusted_proxies = [\"nope\"]\n", 1, "trusted_proxies ngoài miền"},
    {Which::kAuth, "[database]\npool = 0\n", 2, "khoá pool ngoài miền"},
    {Which::kAuth, "[database]\nname = \"9abc\"\n", 2, "khoá name ngoài miền"},
    {Which::kAuth, "[database]\nname = \"a b\"\n", 2, "khoá name ngoài miền"},
    {Which::kAuth, "[register]\ngift_points = -1\n", 2, "gift_points ngoài miền"},
    {Which::kAuth, "[ticket]\nttl_seconds = -1\n", 2, "ttl_seconds ngoài miền"},
    {Which::kAuth, "[database]\nname = \"\"\n", 2, "khoá name ngoài miền"},
    {Which::kBilling, "[access]\nallow = [\"nope\"]\n", 2, "khoá allow ngoài miền"},
    {Which::kBilling, "[limits]\nmax_clients = 0\n", 2, "max_clients ngoài miền"},
    {Which::kBilling, "[points]\ningot_per_point = 0\n", 2, "ingot_per_point ngoài miền"},
    {Which::kBilling, "[points]\nregister_gift = -1\n", 2, "register_gift ngoài miền"},
    {Which::kBilling, "[spend]\ndaily_ingot_cap = -1\n", 2, "daily_ingot_cap ngoài miền"},
    {Which::kBilling, "[orders]\npending_timeout_seconds = -1\n", 2, "timeout_seconds ngoài miền"},
    {Which::kBilling, "[redeem]\nattempts_per_hour = -1\n", 2, "attempts_per_hour ngoài miền"},
    {Which::kBilling, "[access]\nallow = [\"127.0.0.1\", 1]\n", 2, "phần tử của allow sai kiểu"},
    {Which::kBilling, "[[provider]]\nkey = \"k\"\n", 1, "thiếu khoá enabled"},
    {Which::kWorld, "[capacity]\nonline_users = 0\n", 2, "online_users ngoài miền"},
    {Which::kWorld, "[player_count_report]\nhours = [24]\n", 2, "khoá hours ngoài miền"},
    {Which::kWorld, "[player_count_report]\nhours = [1, 1]\n", 2, "có giờ lặp"},
    {Which::kWorld, "[player_count_report]\nhours = [\"1\"]\n", 2, "phần tử của hours sai kiểu"},
    {Which::kZone, "[tick]\nhz = 0\n", 2, "khoá hz ngoài miền"},
    {Which::kZone, "[aoi]\ncell_size = 0\n", 2, "cell_size ngoài miền"},
    {Which::kZone, "[capacity]\nmonsters = 9223372036854775807\n", 2, "monsters ngoài miền"},
    {Which::kZone, "[session]\nlinger_after_disconnect_ms = -1\n", 2, "linger_after_disconnect_ms"},
    {Which::kStore, "[database]\npool = 0\n", 2, "khoá pool ngoài miền"},
    {Which::kStore, "[flush]\ncharacter_ms = -1\n", 2, "character_ms ngoài miền"},
    {Which::kStore, "[journal]\ndir = \"\"\n", 2, "khoá dir ngoài miền"},
    {Which::kAdmin, "listen = \"nope\"\n", 1, "khoá listen ngoài miền"},
    {Which::kAdmin, "token_file = \"\"\n", 1, "token_file ngoài miền"},
    {Which::kAdmin, "[[operator]]\nname = \"gm\"\nlevel = -1\n", 3, "khoá level ngoài miền"},
    {Which::kSecrets, "[database.postgres]\npassword = 1\n", 2, "khoá password sai kiểu"},
    {Which::kSecrets, "[database.other]\npassword = \"\"\n", 1, "nhóm lạ other"},
    {Which::kLoose, "schema = true\n", 1, "khoá schema sai kiểu"},
    {Which::kLoose, "schema = 2\n", 1, "khoá schema ngoài miền"},
    {Which::kLoose, "", 1, "thiếu khoá schema"},
    {Which::kLoose, "schema =\n", 1, "lỗi cú pháp: "},
    {Which::kLoose, "schema = 1\n[world\n", 2, "lỗi cú pháp: "},
    {Which::kLoose, "schema = 9223372036854775808\n", 1, "lỗi cú pháp: "},
    {Which::kLoose, "schema = 1\nschema = 1\n", 2, "lỗi cú pháp: "},
    {Which::kLoose, "[world]\nid = 1\n[world]\nid = 2\n", 3, "lỗi cú pháp: "},
    {Which::kLoose, "schema = \"\xff\"\n", 1, "lỗi cú pháp: "},
});

inline constexpr std::string_view kStoreOnlyCluster = "schema = 1\n"
                                                      "[world]\n"
                                                      "id = 1\n"
                                                      "zone_group = 0\n"
                                                      "name = \"n\"\n"
                                                      "table_variant = \"\"\n"
                                                      "[postgres]\n"
                                                      "host = \"127.0.0.1\"\n"
                                                      "port = 5432\n"
                                                      "bin_dir = \"b\"\n"
                                                      "data_dir = \"d\"\n"
                                                      "log_file = \"l\"\n"
                                                      "[[machine]]\n"
                                                      "id = 0\n"
                                                      "[[process]]\n"
                                                      "kind = \"store\"\n"
                                                      "id = 0\n"
                                                      "machine = 0\n"
                                                      "host = \"127.0.0.1\"\n"
                                                      "port = 7010\n";

inline constexpr std::string_view kSixStepSupervisor = "schema = 1\n"
                                                       "[postgres]\n"
                                                       "managed = true\n"
                                                       "ready_timeout_seconds = 60\n"
                                                       "[restart]\n"
                                                       "max_per_hour = 3\n"
                                                       "[stop]\n"
                                                       "timeout_seconds = 30\n"
                                                       "[[start]]\n"
                                                       "process = \"store\"\n"
                                                       "ready_timeout_seconds = 60\n"
                                                       "[[start]]\n"
                                                       "process = \"auth\"\n"
                                                       "ready_timeout_seconds = 60\n"
                                                       "[[start]]\n"
                                                       "process = \"billing\"\n"
                                                       "ready_timeout_seconds = 60\n"
                                                       "[[start]]\n"
                                                       "process = \"world\"\n"
                                                       "ready_timeout_seconds = 60\n"
                                                       "[[start]]\n"
                                                       "process = \"zone\"\n"
                                                       "ready_timeout_seconds = 60\n"
                                                       "[[start]]\n"
                                                       "process = \"gate\"\n"
                                                       "ready_timeout_seconds = 60\n";

} // namespace game::test
