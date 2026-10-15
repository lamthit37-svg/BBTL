/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/host/host.hpp
 *  PHÂN HỆ   : Client / Host
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Việc mỗi khung của vỏ điện thoại (Android, iOS) ngoài vòng sự kiện của
 *    hệ điều hành: nối chuỗi đăng nhập với phiên mạng, vào game theo chỗ máy
 *    chủ đặt, nhạc nền và âm thanh đòn, đọc bảng cổng máy chủ.
 *  - Không include API hệ điều hành: Android và iOS gọi cùng một mã, vỏ chỉ
 *    ghi các Note ra kênh log của nền tảng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Cách hỏng đã tính trước (CL-03):
//   thiếu Table/gates.tsv                -> bảng rỗng, mọi máy chủ là cục bộ; không phải lỗi.
//   gates.tsv có mà sai                  -> bảng rỗng và một Note lỗi, không đoán địa chỉ (client/session/gates.hpp).
//   cảnh máy chủ đặt không có trong gói  -> Online::abandon: chuỗi đăng nhập nhận Lost, phiên được trả.
//   ứng dụng xuống nền giữa màn chơi     -> Display bị huỷ, phiên vẫn sống; Display mới nhận lại cảnh, chỗ đứng cuối và mọi
//                                           thực thể đang thấy (máy chủ không gửi lại thứ đã báo).
//   ứng dụng xuống nền giữa đăng nhập    -> chuỗi đăng nhập của Display mới bắt đầu lại ở bảng tài khoản: phiên cũ bị trả.
//   loa không mở / thiếu tệp âm thanh    -> một Note lỗi, không chặn vào cảnh.

#pragma once

#include "client/cast/cast.hpp"
#include "client/display/display.hpp"
#include "client/online/bridge.hpp"
#include "client/session/gates.hpp"
#include "client/world/world.hpp"
#include "core/ground_point.hpp"

#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace game::audio {
class Engine;
}

namespace game::client::host {

// Một dòng báo cáo; vỏ ghi ra kênh log của nền tảng (is_problem thì kênh lỗi).
struct Note {
    bool is_problem = false;
    std::string text;
};

using Notes = std::vector<Note>;

// Bảng cổng máy chủ của một lần chạy: bảng đã đọc và các dòng báo cáo.
struct GateBookLoad {
    session::GateBook book;
    Notes notes;
};

// Đọc <data_root>/Table/gates.tsv. Không có tệp là bình thường (chỉ máy chủ cục bộ); tệp có mà sai thì bảng rỗng kèm một
// Note lỗi.
[[nodiscard]] GateBookLoad load_gate_book(const std::filesystem::path& data_root);

// Phần mạng của vỏ điện thoại: chuỗi đăng nhập với phiên mạng (online::Bridge), tin thế giới sang Display, chỗ đứng sang
// máy chủ, đổi cảnh khi máy chủ đưa nhân vật đi. Sống suốt tiến trình; Display thì huỷ và dựng lại theo vòng đời ứng dụng.
// Mọi hàm gọi từ luồng của vỏ, không chặn, không I/O mạng (phiên chạy ở luồng nền của session::Session).
class Online {
public:
    explicit Online(session::GateBook book);

    // Máy chủ có cổng thật, cho DisplayDesc::online_servers.
    [[nodiscard]] std::vector<ui::panel::ServerName> servers() const;
    // Display vừa dựng. Chưa chơi: chuỗi đăng nhập mới bắt đầu lại ở bảng tài khoản nên phiên cũ (nếu có) bị trả. Đang
    // chơi: Display mới nhận lại cảnh, chỗ đứng cuối đã báo máy chủ và mọi thực thể đang thấy.
    void on_display_made(Display& display, bool is_playing);
    // Mỗi khung khi có Display. playing là thế giới của màn chơi khi đang chơi, nullptr khi chưa; scenes là thư mục
    // Scene của dữ liệu. seconds là thời gian từ khung trước (dời bản nhớ thực thể như nơi vẽ dời).
    void on_frame(Display& display, world::World* playing, const std::filesystem::path& scenes, float seconds,
        Notes& notes);
    // Vào game trực tuyến không được (cảnh máy chủ nói không có trong gói): chuỗi đăng nhập nhận Lost và phiên được trả,
    // thay vì để người chơi đứng ở bảng chọn khi máy chủ tưởng họ đã vào game.
    void abandon(Display& display);

private:
    void follow(Display& display, world::World& playing, const std::filesystem::path& scenes,
        const cast::Arrive& arrive, Notes& notes);

    online::Bridge bridge_;
    // Bản nhớ thế giới đang thấy, cùng tin với Display; dùng để phát lại cho Display dựng lại.
    cast::Cast seen_;
    // Chỗ đứng cuối cùng đã báo máy chủ (hay máy chủ đặt), mét của game.
    std::optional<core::GroundPoint> spot_;
};

// Âm thanh của màn chơi: nhạc nền theo cảnh và âm thanh của khối Sound trong kịch bản đòn.
class Soundscape {
public:
    // Gọi mỗi khung. scene là cảnh đang chơi (nullptr khi chưa vào game); đổi cảnh thì chuyển nhạc, id nhạc 0 giữ bài
    // đang phát. speaker nullptr hoặc chưa mở thiết bị thì không làm gì (vẫn rút hàng đợi âm thanh của display).
    void on_frame(audio::Engine* speaker, Display& display, const world::ShownScene* scene, Notes& notes);

private:
    int shown_id_ = -1;
};

} // namespace game::client::host
