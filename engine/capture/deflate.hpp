// Nén deflate (RFC 1951) cùng hai tổng kiểm mà PNG và zlib cần. Viết riêng cho đường ghi ảnh: dữ
// liệu là hàng điểm ảnh đã lọc, cần nhanh và chia được cho nhiều luồng. _Ref nén PNG bằng
// stb_image_write trên luồng vẽ, một luồng, mức 4. Ở đây một dòng deflate ghép từ nhiều đoạn nén
// độc lập: đoạn không phải cuối kết bằng một khối stored rỗng nên dừng đúng biên byte, các đoạn nén
// song song rồi nối lại vẫn là một dòng hợp lệ (cách của pigz), và Adler-32 của cả dòng ghép từ
// Adler-32 của từng đoạn. Mỗi khối chọn rẻ nhất trong ba cách mã hoá: Huffman động, Huffman cố
// định, để thô. Chưa có bộ giải nén: đọc PNG là việc của pipeline asset.
// Nguồn: Forge2 src/capture/deflate.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k.
#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

namespace game::capture {

// Công sức tìm chuỗi lặp: số ứng viên thử ở mỗi vị trí.
enum class Effort : std::uint8_t {
    kFast,
    kBalanced,
    kBest,
};

// Nén data thành các khối deflate nối vào cuối out. last: khối cuối mang cờ kết thúc dòng. Không
// last: dòng dừng ở biên byte sau một khối stored rỗng, lần gọi sau nối tiếp được.
void deflate(std::span<const std::byte> data, Effort effort, bool last, std::vector<std::byte>& out);

// Adler-32 của zlib. Nối được: adler32(b, adler32(a)) bằng Adler-32 của a nối b.
[[nodiscard]] std::uint32_t adler32(std::span<const std::byte> data, std::uint32_t seed = 1) noexcept;

// Adler-32 của hai khối nối nhau, tính từ Adler-32 của từng khối (seed 1) và độ dài khối sau.
[[nodiscard]] std::uint32_t adler32_combine(std::uint32_t first, std::uint32_t second,
    std::size_t second_size) noexcept;

// CRC-32 của PNG, zip, gzip (đa thức đảo bit 0xEDB88320); khác CRC-32C của core. Nối được như
// adler32, seed 0 là đầu khối.
[[nodiscard]] std::uint32_t crc32(std::span<const std::byte> data, std::uint32_t seed = 0) noexcept;

} // namespace game::capture
