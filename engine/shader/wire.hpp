// Ghi và đọc little-endian cho gói shader và phản chiếu. Không phải API của module: chỉ tệp .cpp
// trong src/shader include nó. Reader coi dữ liệu là thù địch: đọc quá cuối trả 0 và ghi nhớ thất
// bại, người gọi kiểm failed() một lần ở cuối thay vì sau từng trường; count() chặn số phần tử theo
// số byte còn lại trước khi ai đó cấp phát theo nó.
// Nguồn: Forge2 src/shader/wire.hpp@d7fcd76. Khác gốc: biến và tham số tên at của Writer đổi thành
// start.
#pragma once

#include <algorithm>
#include <bit>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <span>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace game::shader {

static_assert(std::endian::native == std::endian::little, "gói shader ghi little-endian");

class Writer {
public:
    template <std::unsigned_integral T>
    void put(T value) {
        const std::size_t start = bytes_.size();
        bytes_.resize(start + sizeof(T));
        std::memcpy(std::span(bytes_).subspan(start).data(), &value, sizeof(T));
    }

    void put_flag(bool value) { put<std::uint8_t>(value ? 1 : 0); }

    // Độ dài u32 rồi byte của chuỗi.
    void put_text(std::string_view text) {
        put(static_cast<std::uint32_t>(text.size()));
        put_bytes(std::as_bytes(std::span(text)));
    }

    void put_bytes(std::span<const std::byte> data) { bytes_.insert(bytes_.end(), data.begin(), data.end()); }

    // Đệm byte 0 tới bội số của alignment. alignment 0 là chia cho không, không phải "không đệm".
    void align(std::size_t alignment) {
        if (alignment == 0) return;
        const std::size_t rest = bytes_.size() % alignment;
        if (rest != 0) bytes_.resize(bytes_.size() + (alignment - rest));
    }

    // Thêm count byte 0: chỗ đặt trước cho một bản ghi sẽ ghi đè sau.
    void fill(std::size_t count) { bytes_.resize(bytes_.size() + count); }

    // Ghi đè data vào vùng đã đặt chỗ ở offset start; vùng ấy phải nằm trọn trong phần đã ghi.
    void overwrite(std::size_t start, std::span<const std::byte> data) {
        const std::span<std::byte> target = std::span(bytes_).subspan(start, data.size());
        std::ranges::copy(data, target.begin());
    }

    [[nodiscard]] std::size_t size() const noexcept { return bytes_.size(); }
    [[nodiscard]] std::span<const std::byte> bytes() const noexcept { return bytes_; }
    [[nodiscard]] std::vector<std::byte> take() noexcept { return std::move(bytes_); }

private:
    std::vector<std::byte> bytes_;
};

class Reader {
public:
    explicit Reader(std::span<const std::byte> data) noexcept : data_(data) {}

    template <std::unsigned_integral T>
    [[nodiscard]] T get() noexcept {
        T value = 0;
        const std::span<const std::byte> raw = take(sizeof(T));
        if (raw.size() == sizeof(T)) std::memcpy(&value, raw.data(), sizeof(T));
        return value;
    }

    [[nodiscard]] bool get_flag() noexcept { return get<std::uint8_t>() != 0; }

    // Chuỗi của put_text, chép ra: byte sang char không qua reinterpret_cast.
    [[nodiscard]] std::string get_text() {
        const std::span<const std::byte> raw = take(get<std::uint32_t>());
        std::string text(raw.size(), '\0');
        if (!raw.empty()) std::memcpy(text.data(), raw.data(), raw.size());
        return text;
    }

    // Số phần tử của một mảng mà mỗi phần tử chiếm ít nhất least byte; nhiều hơn số byte còn lại
    // cho phép là thất bại và trả 0.
    [[nodiscard]] std::uint32_t count(std::size_t least) noexcept {
        const auto value = get<std::uint32_t>();
        if (value <= remaining() / std::max<std::size_t>(least, 1)) return value;
        failed_ = true;
        return 0;
    }

    // size byte kế tiếp; thiếu thì thất bại và trả vùng rỗng.
    [[nodiscard]] std::span<const std::byte> take(std::size_t size) noexcept {
        if (size > remaining()) failed_ = true;
        if (failed_) return {};
        const std::span<const std::byte> out = data_.subspan(at_, size);
        at_ += size;
        return out;
    }

    void skip(std::size_t size) noexcept { std::ignore = take(size); }

    void fail() noexcept { failed_ = true; }
    [[nodiscard]] bool failed() const noexcept { return failed_; }
    [[nodiscard]] std::size_t remaining() const noexcept { return failed_ ? 0 : data_.size() - at_; }

private:
    std::span<const std::byte> data_;
    std::size_t at_ = 0;
    bool failed_ = false;
};

} // namespace game::shader
