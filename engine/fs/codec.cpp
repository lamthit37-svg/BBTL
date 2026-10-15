// lz4 nhận con trỏ char và cỡ int: mọi khối của Buny tối đa 8 MiB nên vừa int, nhưng hàm vẫn chặn
// cỡ quá LZ4_MAX_INPUT_SIZE thay vì ép kiểu cắt bớt như gốc (ép (int) trên bộ đệm người dùng lớn
// hơn 2 GiB thành số âm).
// Nguồn: Forge2 src/fs/codec.cpp@d7fcd76. Khác gốc (so với Forge2): hai biến thread_local const tên
// context thành kContext; hết bộ nhớ cho trạng thái XXH3 thì core::check, không ném bad_alloc.
#include "fs/codec.hpp"

#include "core/check.hpp"
#include "core/error.hpp"
#include "core/thread_slot.hpp"
#include "fs/buny.hpp"
#include "fs/stream.hpp"

#include <lz4.h>
#include <lz4hc.h>
#include <xxhash.h>
#include <zstd.h>
#include <zstd_errors.h>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <utility>

namespace game::fs {

using core::ErrorCode;
using core::fail;

namespace {

constexpr int kLz4AccelerationMax = 65537;

// Thư viện C nhận char; std::byte và char được phép trỏ cùng vùng nhớ.
// NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast)
[[nodiscard]] const char* as_chars(std::span<const std::byte> bytes) noexcept {
    return reinterpret_cast<const char*>(bytes.data());
}

[[nodiscard]] char* as_chars(std::span<std::byte> bytes) noexcept {
    return reinterpret_cast<char*>(bytes.data());
}
// NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast)

[[nodiscard]] bool fits_lz4(std::size_t size) noexcept {
    return size <= static_cast<std::size_t>(LZ4_MAX_INPUT_SIZE);
}

struct DecoderFree {
    void operator()(ZSTD_DCtx* context) const noexcept { ZSTD_freeDCtx(context); }
};

struct EncoderFree {
    void operator()(ZSTD_CCtx* context) const noexcept { ZSTD_freeCCtx(context); }
};

[[nodiscard]] ZSTD_DCtx* zstd_decoder() {
    // unique_ptr có destructor nên đi qua thread_slot, không khai thread_local thẳng (GCC MinGW,
    // xem core/thread_slot.hpp).
    const auto& context =
        core::thread_slot([] { return std::unique_ptr<ZSTD_DCtx, DecoderFree>(ZSTD_createDCtx()); });
    return context.get();
}

[[nodiscard]] ZSTD_CCtx* zstd_encoder() {
    const auto& context =
        core::thread_slot([] { return std::unique_ptr<ZSTD_CCtx, EncoderFree>(ZSTD_createCCtx()); });
    return context.get();
}

// Trạng thái nén của lz4, cấp một lần mỗi luồng; operator new căn 16 byte, đủ cho lz4.
// Bytes giữ unique_ptr nên có destructor: đi qua thread_slot như ngữ cảnh zstd trên.
[[nodiscard]] void* lz4_state(bool high) {
    Bytes& fast = core::thread_slot([] { return Bytes(static_cast<std::size_t>(LZ4_sizeofState())); });
    Bytes& slow = core::thread_slot([] { return Bytes(static_cast<std::size_t>(LZ4_sizeofStateHC())); });
    return high ? slow.data() : fast.data();
}

[[nodiscard]] Status decode_lz4(std::span<const std::byte> packed, std::span<std::byte> out) {
    const std::size_t want = out.size();
    const bool fits = fits_lz4(packed.size()) && fits_lz4(want);
    if (!fits) return fail(ErrorCode::kOutOfRange, "khối lz4 quá lớn");
    const int got =
        LZ4_decompress_safe(as_chars(packed), as_chars(out), static_cast<int>(packed.size()), static_cast<int>(want));
    if (got < 0) return fail(ErrorCode::kCorrupt, "khối lz4 hỏng");
    if (std::cmp_equal(got, want)) return core::ok();
    return fail(ErrorCode::kCorrupt, "khối lz4 sai cỡ", "{} thay vì {}", got, want);
}

[[nodiscard]] Status decode_zstd(std::span<const std::byte> packed, std::span<std::byte> out) {
    ZSTD_DCtx* context = zstd_decoder();
    if (context == nullptr) return fail(ErrorCode::kOutOfMemory, "không tạo được ngữ cảnh zstd");
    const std::size_t want = out.size();
    const std::size_t got = ZSTD_decompressDCtx(context, out.data(), want, packed.data(), packed.size());
    const bool failed = ZSTD_isError(got) != 0;
    if (failed) return fail(ErrorCode::kCorrupt, "khối zstd hỏng", ZSTD_getErrorName(got));
    if (got == want) return core::ok();
    return fail(ErrorCode::kCorrupt, "khối zstd sai cỡ", "{} thay vì {}", got, want);
}

// Mức > 0 là HC (1 và 2 kẹp lên LZ4HC_CLEVEL_MIN như bộ ghi buny), mức <= 0 là chế độ nhanh.
[[nodiscard]] int compress_lz4(int level, std::span<const std::byte> data, std::span<std::byte> out) {
    const auto size = static_cast<int>(data.size());
    const int room = static_cast<int>(std::min(out.size(), data.size()));
    const char* source = as_chars(data);
    char* target = as_chars(out);
    void* state = lz4_state(level > 0);
    if (level <= 0) return LZ4_compress_fast_extState(state, source, target, size, room, -level);
    const int high = std::max(level, LZ4HC_CLEVEL_MIN);
    return LZ4_compress_HC_extStateHC(state, source, target, size, room, high);
}

[[nodiscard]] Result<std::optional<std::size_t>> encode_lz4(int level, std::span<const std::byte> data,
    std::span<std::byte> out) {
    if (!fits_lz4(data.size())) return fail(ErrorCode::kOutOfRange, "khối lz4 quá lớn");
    const int wrote = compress_lz4(level, data, out);
    if (wrote <= 0) return std::nullopt;
    return static_cast<std::size_t>(wrote);
}

[[nodiscard]] Result<std::optional<std::size_t>> encode_zstd(int level, std::span<const std::byte> data,
    std::span<std::byte> out) {
    ZSTD_CCtx* context = zstd_encoder();
    if (context == nullptr) return fail(ErrorCode::kOutOfMemory, "không tạo được ngữ cảnh zstd");
    const std::size_t wrote = ZSTD_compressCCtx(context, out.data(), out.size(), data.data(), data.size(), level);
    if (ZSTD_isError(wrote) == 0) return wrote;
    if (ZSTD_getErrorCode(wrote) == ZSTD_error_dstSize_tooSmall) return std::nullopt;
    return fail(ErrorCode::kInternal, "zstd không nén được", ZSTD_getErrorName(wrote));
}

} // namespace

std::uint64_t checksum(std::span<const std::byte> data) noexcept {
    return XXH3_64bits(data.data(), data.size());
}

void Checksum::Free::operator()(void* state) const noexcept {
    XXH3_freeState(static_cast<XXH3_state_t*>(state));
}

Checksum::Checksum() : state_(XXH3_createState()) {
    core::check(state_ != nullptr, "hết bộ nhớ cho trạng thái XXH3");
    XXH3_64bits_reset(static_cast<XXH3_state_t*>(state_.get()));
}

void Checksum::update(std::span<const std::byte> data) noexcept {
    XXH3_64bits_update(static_cast<XXH3_state_t*>(state_.get()), data.data(), data.size());
}

std::uint64_t Checksum::digest() const noexcept {
    return XXH3_64bits_digest(static_cast<const XXH3_state_t*>(state_.get()));
}

namespace codec {

Levels levels(buny::Format format) noexcept {
    switch (format) {
    case buny::Format::kRaw: return {};
    case buny::Format::kLz4Blocks:
        return {.min = -kLz4AccelerationMax, .max = LZ4HC_CLEVEL_MAX, .standard = LZ4HC_CLEVEL_DEFAULT};
    case buny::Format::kZstdBlocks:
        return {.min = ZSTD_minCLevel(), .max = ZSTD_maxCLevel(), .standard = ZSTD_defaultCLevel()};
    }
    return {};
}

Status decode(buny::Format format, std::span<const std::byte> packed, std::span<std::byte> out) {
    switch (format) {
    case buny::Format::kLz4Blocks: return decode_lz4(packed, out);
    case buny::Format::kZstdBlocks: return decode_zstd(packed, out);
    case buny::Format::kRaw: break;
    }
    return fail(ErrorCode::kInvalidArgument, "định dạng không nén theo khối");
}

Result<std::optional<std::size_t>> encode(buny::Format format, int level, std::span<const std::byte> data,
    std::span<std::byte> out) {
    const Levels range = levels(format);
    const int clamped = std::clamp(level, range.min, range.max);
    switch (format) {
    case buny::Format::kLz4Blocks: return encode_lz4(clamped, data, out);
    case buny::Format::kZstdBlocks: return encode_zstd(clamped, data, out);
    case buny::Format::kRaw: break;
    }
    return fail(ErrorCode::kInvalidArgument, "định dạng không nén theo khối");
}

} // namespace codec

} // namespace game::fs
