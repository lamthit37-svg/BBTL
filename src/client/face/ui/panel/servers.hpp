// Danh sách máy chủ đăng nhập mà bảng chọn máy chủ (SelectServer) hiện: các vùng, mỗi vùng có
// máy chủ, và cách xếp vùng vào cột trái, mục "đề cử" bên phải và tìm theo tên. Client gốc đọc
// danh sách từ ..\Patch\loginserver.txt do bộ khởi động đưa vào (tệp mã hoá) rồi hỏi qua
// GameProduceLogin:GetServerAreaCount, GetServerAreaName, GetServerAreaDis,
// GetServerAreaRecommendLevel, GetAreaLoginServerCount, GetAreaLoginServerInfo; bản này đọc cùng các
// trường từ bảng Table/login_servers.tsv của thư mục dữ liệu.
// Nguồn: Interface/SelectServer/SelectServer.lua của client 2026, giải bằng TOOLS/content/lua_plain.py
// (SelectServer_Data_GetAreaInfoAndRecommendServerInfo 669, SelectServer_Sort_RecommendServer 2899).
// Khác gốc: tệp là TSV thường chứ không mã hoá; bỏ hai trường GetAreaLoginServerInfo mà script không
// hiện (nhà mạng và số phiên bản); trần số vùng và số máy chủ mỗi vùng chọn ở đây (script chỉ
// kẹp 85 máy chủ mỗi vùng).
#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Trần máy chủ mỗi vùng: g_ServerBn.MAX_SERVER_COUNT của script (85 nút trong layout).
inline constexpr std::size_t kServersPerArea = 85;
// Trần số máy chủ ở mục đề cử: g_RecommendServerBn.MAX_SERVER_COUNT.
inline constexpr std::size_t kRecommendCap = 12;
// Trần số vùng nhận từ bảng.
inline constexpr std::size_t kAreaCap = 256;

// Trạng thái máy chủ (GetAreaLoginServerInfo, giá trị thứ hai): 0 đầy, 1 bận, 2 tốt, 3 rất tốt,
// 4 bảo trì (StateStop); từ 10 (StatMax) là không hiện ở mục đề cử.
inline constexpr std::uint8_t kStatusFull = 0;
inline constexpr std::uint8_t kStatusBusy = 1;
inline constexpr std::uint8_t kStatusGood = 2;
inline constexpr std::uint8_t kStatusBest = 3;
inline constexpr std::uint8_t kStatusStop = 4;
inline constexpr std::uint8_t kStatusHidden = 10;
// Mức thưởng cao nhất mà bảng chữ g_ThreePrizeTip có (mười tám mức, 0 là không thưởng).
inline constexpr std::uint8_t kPrizeLevels = 18;

struct LoginServer {
    std::string name;
    std::uint8_t status = kStatusStop;
    // Mức đề cử; lớn hơn 0 thì máy chủ vào mục đề cử, nhỏ trước.
    std::uint8_t recommend = 0;
    bool is_new = false;
    std::uint8_t prize = 0;
    // Dấu "Vũ Thần Đàn" (nWuShenTan).
    bool has_arena = false;
    // Máy chủ có cổng thật (bảng cổng của client có dòng cho nó): chọn nó thì thủ tục đăng nhập nối máy chủ thay vì dùng
    // sổ nhân vật cục bộ. Không đến từ bảng TSV của danh sách; mark_online đặt sau khi nạp.
    bool is_online = false;

    friend bool operator==(const LoginServer&, const LoginServer&) = default;
};

struct LoginArea {
    // Tên vùng nguyên văn; phần trước dấu '-' chọn đại khu (BigArea), phần sau là tên hiện.
    std::string name;
    // Dòng chú thích hiện ở thanh thông tin khi trỏ vào vùng (GetServerAreaDis).
    std::string tip;
    // Mức đề cử của vùng: lớn hơn 0 thì dòng vùng thụt lề ít hơn để chừa chỗ cho dấu.
    std::uint8_t recommend = 0;
    std::vector<LoginServer> servers;

    friend bool operator==(const LoginArea&, const LoginArea&) = default;
};

struct ServerDirectory {
    std::vector<LoginArea> areas;
};

// Đại khu ở cột trái (g_AreaUI.AreaCtrlID_*). Số thứ tự là số của script; kRecommend không chứa vùng.
enum class BigArea : std::uint8_t {
    kRecommend = 1,
    kContest = 2,
    kTelecom = 3,
    kUnicom = 4,
    kDual = 5,
    kSpecial = 6,
    kLight = 7,
    kBraveGathering = 8,
    kWorldMartial = 9,
    kPeak = 10,
    kWeGameOnly = 11,
};

inline constexpr std::size_t kBigAreaCount = 11;

// Đại khu của vùng theo phần trước dấu '-' trong tên; không có dấu '-' là điện tín. Tiền tố lạ thì
// không thuộc đại khu nào (vùng vẫn góp máy chủ cho mục đề cử).
[[nodiscard]] std::optional<BigArea> big_area_of(std::string_view area_name) noexcept;
// Tên vùng hiện ở cột trái: phần sau dấu '-' của đại khu nhận ra; vùng không dấu '-' giữ nguyên.
[[nodiscard]] std::string_view area_title(std::string_view area_name) noexcept;
// Tên vùng đi trước tên máy chủ ở mục đề cử ("vùng-máy chủ"): bỏ tiền tố đại khu (điện tín, mạng
// thông, hai đường, tranh bá, đặc sắc, nhẹ nhàng, WG riêng) khi có dấu '-' đứng không cuối tên.
[[nodiscard]] std::string_view recommend_label(std::string_view area_name) noexcept;

// Một máy chủ trong danh sách: chỉ số vùng và chỉ số máy chủ trong vùng (đều từ 0).
struct ServerRef {
    std::size_t area = 0;
    std::size_t server = 0;

    friend bool operator==(const ServerRef&, const ServerRef&) = default;
};

// Mục đề cử: tối đa kRecommendCap máy chủ có mức đề cử lớn hơn 0 và trạng thái khác kStatusHidden,
// lấy theo thứ tự vùng rồi máy chủ, rồi xếp mức đề cử tăng dần (sắp ổn định, như bubble sort của
// script). Khác gốc: dấu Vũ Thần Đàn đi theo máy chủ; script hoán đổi mọi trường trừ trường ấy, nên
// dấu nằm lại ở chỗ cũ khi các dòng đổi chỗ.
[[nodiscard]] std::vector<ServerRef> recommended(const ServerDirectory& directory);
// Máy chủ có tên chứa keyword (so từng byte, phân biệt hoa thường: SetLoginServerKeyword so chuỗi
// bằng strstr nhận cả ký tự hai byte, Game.exe 0x140628240 và 0x1407671e0) và trạng thái khác
// kStatusHidden, theo thứ tự vùng rồi máy chủ. keyword rỗng thì không có kết quả. Khác gốc: gốc bỏ
// máy chủ trùng id và tên đã có trong kết quả; một máy chủ ở bảng này chỉ nằm trong một vùng.
[[nodiscard]] std::vector<ServerRef> search(const ServerDirectory& directory, std::string_view keyword);
// Máy chủ ở ref; nullptr khi ref ngoài danh sách.
[[nodiscard]] const LoginServer* server_at(const ServerDirectory& directory, ServerRef ref) noexcept;

// Bảng TSV: dòng đầu là tên các cột, dòng bắt đầu bằng '#' là chú thích, mỗi dòng sau là một máy
// chủ (các dòng cùng tên vùng liền nhau gộp vào một vùng; dòng chỉ có vùng, ô máy chủ rỗng, là vùng
// chưa có máy chủ). Dòng sai số cột hay sai số bị bỏ; vượt trần thì phần thừa bị bỏ. Không có khi
// dòng tên cột khác kServerColumns.
[[nodiscard]] std::optional<ServerDirectory> decode_servers(std::string_view text);
// Máy chủ vào game lần trước, nhớ giữa hai lần chạy (Login_Area và Login_Server của client gốc lưu
// chỉ số; ở đây lưu tên để danh sách đổi thứ tự không làm nhớ nhầm): tệp TSV, dòng đầu "1", dòng
// sau "tên vùng<tab>tên máy chủ". decode_last không có khi tệp sai dạng hay máy chủ không còn trong
// danh sách.
[[nodiscard]] std::string encode_last(const ServerDirectory& directory, ServerRef server);
[[nodiscard]] std::optional<ServerRef> decode_last(const ServerDirectory& directory, std::string_view text);
inline constexpr std::string_view kServerColumns =
    "area\ttip\tarea_recommend\tserver\tstatus\trecommend\tis_new\tprize\thas_arena";

} // namespace game::ui::panel
