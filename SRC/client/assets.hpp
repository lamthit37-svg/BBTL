// Sổ assets của bản cài di động. package_apk.py ghi assets/manifest.txt, mỗi dòng
// "<nhóm> <dấu> <đường dẫn>": nhóm D là dữ liệu, S là gói shader; dấu là CRC và cỡ của tệp nên đổi
// khi nội dung đổi. Vỏ Android giải nén assets sang bộ nhớ trong một lần, giữ lại sổ của lần đó,
// và ở lần chạy sau chỉ chép những tệp có dấu khác sổ đã giữ.
// Quyết định: không dùng một dấu đời tăng bằng tay nữa. Dấu ấy bị quên một lần là máy chạy mã mới
// với gói shader cũ (bố cục khối hằng lệch, PowerVR huỷ cả khung, màn hình đen) hoặc thiếu tệp dữ
// liệu mới thêm.
#pragma once

#include <string_view>
#include <vector>

namespace game::client {

struct AssetEntry {
    // 'D': assets/data/<path> ra <gốc dữ liệu>/<path>. 'S': assets/shaders/<path> ra
    // <gốc dữ liệu>/shaders/<path>.
    char group = 'D';
    std::string_view stamp;
    std::string_view path;

    [[nodiscard]] bool operator==(const AssetEntry&) const = default;
};

// Các dòng hợp lệ của một sổ, theo thứ tự trong tệp; dòng không đủ ba phần hoặc nhóm lạ bị bỏ.
// View trỏ vào text.
[[nodiscard]] std::vector<AssetEntry> read_asset_book(std::string_view text);

// Hai sổ đem so: sổ đã giữ của lần giải nén trước (rỗng khi chưa có) và sổ của gói đang cài.
struct AssetBooks {
    std::string_view installed;
    std::string_view packed;
};

// Những mục của sổ trong gói cài phải chép lại: mục chưa có trong sổ đã giữ hoặc có dấu khác. Sổ
// đã giữ rỗng thì chép hết.
[[nodiscard]] std::vector<AssetEntry> assets_to_copy(const AssetBooks& books);

} // namespace game::client
