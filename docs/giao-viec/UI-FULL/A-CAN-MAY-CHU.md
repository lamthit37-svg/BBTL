# Làn A: dữ liệu và gói máy chủ mà giao diện túi, cửa hàng, ngân hàng, giao dịch, quầy hàng cần

Đo trên Game.exe 9001 (`D:\rea\work\client\Game.exe`, khớp `decompile.zip`). Client hiện chạy script nguyên văn, nhưng các hàm
dưới đây trả trạng thái "kho trống" hoặc bỏ phần gửi gói (ghi `Khác gốc:` trong `native_a_vcall.cpp`, `native_a_trade.cpp`).

## Gói client gửi lên (chưa có đường gửi gói từ script)

| Hàm Lua | Địa chỉ | Gói | Khi nào |
|---|---|---|---|
| `CloseBooth()` | 0x14023acf0 -> 0x140229020 | `CGShopClose` | đóng cửa hàng NPC (Shop, YuanbaoShop) |
| `Exchange:ExchangeCancel()` | 0x140333680 | `CGExchangeCancel` | cửa sổ Exchange đang hiện mà bị đóng |
| `DataPool:AskMyBagList()` | 0x1402e92d0 | `CGAskMyBagList` (hai trường 0) | xin danh sách túi, chặn lặp trong 30000 ms |
| `StallSale:OpenMessageSale()` | 0x1403bd120 | `CGBBSApply` | mở bảng tin quầy (chưa port) |
| `StallSale:ModifStallName(s)` | 0x1403bbe40 | `CGStallShopName` | đổi tên quầy, tên dài quá 0x22 byte thì cắt (chưa port) |

## Dữ liệu máy chủ cấp mà CDataPool giữ (getter đọc qua Facts::pool, nay toàn giá trị của hàm dựng)

- Túi: số ô túi thường `+0x13b30` (u8), túi nguyên liệu `+0x13b31` (u8); vật phẩm trong túi (EnumAction trả ActionItem rỗng).
- Ngân hàng: id NPC `+0x13f50`, kho đồ thế giới `+0x14064`, `+0x14070`; ô thuê đang chọn (Bank:SetCurRentIndex, chưa port).
- Cửa hàng NPC: id NPC `+0x13f20`, loại cửa hàng ("repair" `+0x13de0`, "callback" `+0x13e60`), giá từng món, số chồng tối đa.
- Quầy hàng (StallSale/StallBuy): trang mặc định, thuế, loại tiền, loại máy chủ ở khoảng `+0x15b28..+0x15df0`.
- Giao dịch: tên người bên kia (Exchange:GetOthersName), cờ an toàn đã uỷ quyền.
- Nhân vật: race id (`GetMySelfRaceId`, dữ liệu nhân vật + 0x1c), trạng thái thử đồ (+0x7a4..+0x824 của đối tượng người chơi).
- Thú cưng gửi kho: `Pet:GetIsBaiShou` đọc `+0x5df058`, `+0x5df284`.
