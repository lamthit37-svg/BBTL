# Đặc tả widget giao diện client 2026 cho bảng nhiệm vụ và sách võ công

> Ghi chú về đường dẫn: tài liệu này viết trong lúc tháo mã máy, khi các bản tháo trung gian nằm ở
> `build/scratch/` (không giữ trong repo: mọi địa chỉ đều tái hiện được bằng
> `python -B TOOLS/port/pe_refs.py <tệp PE> func <địa chỉ>`). Tên tệp `build/scratch/...` còn lại
> trong bài chỉ là tên của bản tháo ấy. Công cụ còn dùng được đã dời vào `TOOLS/port/`
> (đường dẫn trong bài đã đổi theo).

## Mục lục và kết luận chính

| Mục | Nội dung | Mức chắc |
|---|---|---|
| 0 | Quy ước, kiểu dùng chung, bảng kiểu TLBB → lớp → look | đã đối chiếu mã máy |
| 1 | Listbox thường (`TLBB_ListBoxCommon`, QuestLog) | đã đối chiếu mã máy |
| 1B | ListBoxEx (`TLBB_ListBoxTransparent`, MissionTrack) | đã đối chiếu, kiểu item 4..12 chưa |
| 2 | Nút action (`TLBB_ActionButton`, `TLBB_ActionButtonNULL`) | đã đối chiếu, hồi chiêu chưa |
| 3 | Cửa sổ phức hợp (`TLBB_ComplexWindow`) | đã đối chiếu, Item/Option mới lược |
| 4 | Ô tiền (`TLBB_Money`, `TLBB_JiaoZi`) | đã đối chiếu mã máy |
| 5 | Phông, thẻ `#`, đo và bẻ dòng, `SimpleText`, `SimpleMulitiTextFrame`, `StaticText` | đã đối chiếu, FreeType chưa đo |
| 6 | Thanh cuộn và thumb | đã đối chiếu mã máy |
| 7 | StopWatch, DragTitle, ba kiểu checkbox | đã đối chiếu mã máy |
| 8 | Phương thức Lua chung của `Window` | đã đối chiếu mã máy |
| 9 | Ví dụ số cho kiểm thử | tính từ đặc tả |
| 10 | Kiểm chéo giữa các mục | |
| 11 | `SRC/gui`, `SRC/ui` hiện lệch hoặc thiếu gì | |
| 12 | Phần chưa xong theo ưu tiên 1..7 | |

Bảng phương thức Lua → hành vi của từng widget: mục 1.7, 1B.3.10, 2.7, 3.6, 4.4, 6.11, 7.3, 8.

Mười điều bản 2026 khác mã 2008 mà người viết widget cần biết trước:

1. Phông mặc định là `SongTiBmp12` cỡ 12 và trang mã luôn là 936: cao phông 14, bước dòng 17, bẻ
   dòng theo từng ký tự (mục 0, mục 5). Phông cỡ 14 của bản tiếng Việt là lựa chọn của dự án: cao
   phông 16, bước dòng 19.
2. Item của listbox cao `cao phông + 3`, chữ dời xuống 2; nền chọn và màu chọn lấy từ thuộc tính
   `SelectBrush`, `SelectColour` của look chứ không ghi cứng (mục 1.4, 1.5, 1.7).
3. Thanh cuộn dọc hiện thì vùng item co lại theo `ItemRenderingAreaVScroll` (2008 có lỗi nên không
   co) (mục 1.3).
4. Bấm chỗ trống của listbox không bỏ chọn; bấm phải cũng chọn item và phát `ItemSelectionChanged`
   rồi `ListItemRClick` (mục 1.6). `GetFirstSelectItem` trả ID, `GetCurrentFirstItem` trả chỉ số.
5. Icon của mọi nút có look khai `ActionArea` vẽ vào vùng đó: nút action 34x34 có icon 32x32 lệch 1
   điểm ảnh (mục 2.4). Nút action vẽ chồng lớp: nền, icon, `Pushed`/`Hover`/`Disabled`, hoạt ảnh,
   chữ góc, nháy (mục 2.3).
6. Cửa sổ phức hợp dùng cỡ nút 35x35 và khoảng cách 10 tuyệt đối; phần tử chữ `n` dòng chiếm
   `n * bước dòng`; có nhớ vị trí cuộn riêng (`SetScrollPosition`, `ResetScrollPosition`) (mục 3).
7. Ô tiền: số trước icon sau, các phần liền nhau, dán đáy, đồng luôn hiện, canh phải lùi thêm 4
   (mục 4).
8. `SimpleText` vẽ state `Enabled` của look và dùng `NamedArea TextArea` làm ô chữ; phông bitmap dời
   lên 1 điểm ảnh, canh giữa ngang cộng 1; `#R` là FFC0CB, `#B` là 00B4FF, thêm nhiều thẻ (mục 5).
9. Nút lên, xuống của thanh cuộn đổi một bước mỗi lần bấm rồi nhả; thumb cỡ cố định; bánh xe mỗi sự
   kiện một bước `max(1, cao vùng / 10)` điểm ảnh (mục 6).
10. `DragTitle` và `StopWatch` kế thừa `FalagardSimpleText` nên có vẽ chữ; checkbox đang chọn vẽ
    `Pushed` kể cả khi bị vô hiệu (mục 7).

Phạm vi: `QuestLog`, `MissionTrack`, `ActionSkill`, `CommonSkill`, `LifeSkill`. Nguồn: mã máy
`F:\tl 2026\Bin64\CEGUIBase.dll`, `CEGUIFalagard.dll`, `UI_CEGUI.dll` (image base cả ba là
`0x180000000`), đối chiếu mã nguồn 2008 ở `G:\TLBB\_ref\client\Game\Client`.

## 0. Quy ước đọc tài liệu

Nhãn độ tin của từng khẳng định:

- **[M]** đã đối chiếu mã máy 2026, kèm địa chỉ (`Base` = CEGUIBase.dll, `Fal` = CEGUIFalagard.dll,
  `UI` = UI_CEGUI.dll).
- **[08]** chỉ theo mã 2008 (kèm tệp:dòng), chưa đối chiếu mã máy.
- **[look]** đọc thẳng từ scheme hay looknfeel của `CLIENT/data/Interface/Schema`.
- **[?]** chưa xác định.

Các mục 1B, 4, 5, 6, 7 giữ nhãn của lượt phân tích viết ra chúng: `[2026]` và `[26]` nghĩa như
**[M]**; `[2008]` như **[08]**; `[chưa]` như **[?]**; chữ tắt `B`, `F`, `U`, `G` là CEGUIBase.dll,
CEGUIFalagard.dll, UI_CEGUI.dll, Game.exe. Trong mục 1B, "mục n.m" chỉ tiểu mục 1B.n.m; trong mục
5, tiểu mục đánh chữ cái (A..H). Phiên chính đã kiểm chéo các mục đó (mục 10).

Lệnh tái hiện một địa chỉ: `python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/<dll>" func <địa chỉ>`
(hàm bị `.pdata` chia mảnh: `func <đầu>..<địa chỉ export kế tiếp>`). Bảng phương thức Lua → địa chỉ
sinh bằng `TOOLS/port/lua_methods.py` từ hàm đăng ký `UI 0x180029500` (mẫu: `lua_newuserdata(8)`,
ghi con trỏ hàm thành viên, `LuaObject::Register(tên)`); kết quả ở `build/scratch/gui/lua_methods.txt`.

Kiểu dùng chung của bản 2026 (khác CEGUI 0.4.1 của mã 2008 ở chỗ chuỗi là `String32`, bộ vẽ là
`GeometryBuffer`, phông là lớp `Font` kiểu CEGUI 0.5 trở lên):

- `Rect` xếp `{top +0, bottom +4, left +8, right +0xC}` [M: `ListboxTextItem::getPixelSize`
  Base 0x1800d9184 lấy `[4]-[0]` làm cao, `[0xC]-[8]` làm rộng]. Hàm dựng `Rect(left, top, right,
  bottom)` (thứ tự tham số như 0.4.1) [M: `getActionArea` Fal 0x1800abe8b dựng `Rect(0, 0, w, h)`].
- `Size` là `{width, height}`; cỡ điểm ảnh của cửa sổ nằm ở `Window+0x110` (rộng), `+0x114` (cao).
- `TextFormatting`: 0 `LeftAligned`, 1 `RightAligned`, 2 `Centred`, 3 `Justified`, 4
  `WordWrapLeftAligned`, 5 `WordWrapRightAligned`, 6 `WordWrapCentred`, 7 `WordWrapJustified`
  [M: `ListboxTextItem::getPixelSize` chia nhánh `<= 3` và `4..7`, Base 0x1800d91e4].
- `MouseEventArgs`: `handled +8`, `position +0x18`, `button +0x28` (0 trái, 1 phải), `sysKeys +0x2C`
  (Shift = 4, Control = 8), `wheelChange +0x30` [M: Base 0x1800d7010, 0x1800d73b0].
- Hằng của `Font` (Base, `.rdata` 0x1801e7350): `DefaultColour = 0xFFFFFFFF`, `LineSpace = 3`
  (0x1801e7354), `InterGlyphPadSpace = 2` (0x1801e7358), `DefaultFontGlyphImagesetSize = 512` [M].
- Số đo của phông: `ascender = Font+0xA0`, `descender = Font+0xA4`, `lineSpacing = Font+0xA8`;
  `getFontHeight(s) = (ascender - descender) * s` (Base 0x18003b710), `getLineSpacing(s) =
  lineSpacing * s` (0x18003b770), `getBaseline(s) = ascender * s` (0x18003b670) [M].
- Phông bitmap (`SongTiBmp12`): `BitmapFont::constructor_impl` Base 0x18003c3a0 chỉ nhận cỡ 12, 14,
  16 và đặt `ascender = cỡ + InterGlyphPadSpace = cỡ + 2`, `descender = 0`, `lineSpacing = cỡ + 2`
  [M: 0x18003c430..0x18003c45b]. Ô glyph của phông bitmap là hình vuông cạnh `cỡ + 2` (mục 5 A.2),
  nên ảnh glyph không bao giờ cao hơn cao phông. Gọi `S` là cỡ phông bitmap: cao phông `S + 2`,
  bước dòng khi vẽ nhiều dòng `S + 5`.
- Phông mặc định (cửa sổ không có thuộc tính `Font`) là phông đầu tiên được tạo:
  `FontManager::doPostObjectAdditionAction` Base 0x180138870 gọi `System::setDefaultFont` khi bảng
  phông có đúng một phần tử; thẻ `<Font>` đầu của scheme là `SongTiBmp12` [M].
- Mỗi tệp `.font` có hai dòng theo `CodePage`; `Font_xmlHandler` bỏ dòng có `CodePage` khác
  `System+0x118` (Base 0x180134fb9). Giá trị đó là 936 từ constructor của `System` và không tệp nào
  của `Bin64` gọi `System::setCodePage` (chỉ CEGUIBase.dll chứa tên hàm) [M]. **Client 2026 này luôn
  vẽ bằng `SongTiBmp12` cỡ 12 (GBK12.bin): cao phông 14, bước dòng 17, bẻ dòng theo từng ký tự.**
  Dòng 1258 (`VTNAM14.bin`, cỡ 14: cao phông 16, bước dòng 19, bẻ theo từ) là lựa chọn của bản tiếng
  Việt của dự án; mọi công thức dưới đây viết theo `S` để dùng được cho cả hai.
- Cuộn chuột: hàm xử lý sự kiện nhập `UI 0x18006b600` (switch theo `số sự kiện - 2`, bảng nhảy
  0x18006bf5c): sự kiện 18 (lăn lên, số theo `docs/CAMERA-2026.md`) gọi
  `System::injectMouseWheelChange(+1.0f)` (0x18006bb07), sự kiện 19 (lăn xuống) gọi `(-1.0f)`
  (0x18006bb58) [M]. Mỗi sự kiện là đúng 1,0; nhiều nấc trong một nhịp nhập chỉ thành một sự kiện.
  Lăn lên làm vị trí cuộn GIẢM một `stepSize`.
- Chuỗi từ Lua đi qua bộ phân tích `UI 0x18004b170(CUIStringSystem*, mbcs, out String32, bool
  colorTrans, bool = false)`; `colorTrans` lấy ở `Window+0x308`, là thuộc tính `ColorTrans` của
  `Window` (lớp `WindowProperties::ColorTrans`, mặc định 1 trong constructor `Window` Base
  0x1800998a9) [M]. Bảng thẻ `#` ở mục 5.

### 0.1 Kiểu TLBB → lớp Falagard → look [look: `WoWLookSkin.scheme.xml`]

| Kiểu | TargetType | LookNFeel | Tệp looknfeel:dòng | Mục |
|---|---|---|---|---|
| `TLBB_ListBoxCommon` | `Falagard/Listbox` | `TLBB_Look_ListBoxCommon` | `TLBBLook_List.looknfeel.xml`:10 | 1 |
| `TLBB_ListBoxTransparent` | `Falagard/ListBoxEx` | `TLBB_Look_ListBoxTransparent` | `TLBBLook_List.looknfeel.xml`:1849 | 1B |
| `TLBB_ActionButton` | `Falagard/ActionButton` | `TLBB_Look_ActionButton` | `TLBBLook_Button.looknfeel.xml`:5 | 2 |
| `TLBB_ActionButtonNULL` | `Falagard/ActionButton` | `TLBB_Look_ActionButtonNULL` | `TLBBLook_Button.looknfeel.xml`:444 | 2 |
| `TLBB_ComplexWindow` | `Falagard/ComplexWindow` | `TLBB_Look_ComplexWindow` | `TLBBLook_ComplexWindow.looknfeel.xml`:54 | 3 |
| `TLBB_ComplexWindow_ParentWindow` | `Falagard/ComplexWindow/ParentWindow` | `TLBB_Look_ComplexWindow_ParentWindow` (rỗng) | cùng tệp:53 | 3 |
| `TLBB_Money` | `Falagard/Money` | `TLBB_Look_Money` | `TLBBLook_StaticText.looknfeel.xml`:259 | 4 |
| `TLBB_SimpleMulitiTextFrame` | `Falagard/SimpleText` | `TLBB_Look_MuliteTextFrame` | `TLBBLook_StaticText.looknfeel.xml`:83 | 5 |
| `TLBB_SimpleText` | `Falagard/SimpleText` | `TLBB_Look_SimpleText` | `TLBBLook_StaticText.looknfeel.xml`:9 | 5 |
| `TLBB_StaticText` | `Falagard/StaticText` | `TLBB_Look_StaticText` | `TLBBLook_StaticText.looknfeel.xml`:515 | 5 |
| `TLBB_Scrollbar_Common` | `Falagard/Scrollbar` | `TLBB_Look_Scrollbar_Common` | `TLBBLook_ScrollBar.looknfeel.xml`:1323 | 6 |
| `TLBB_Scrollbar_Track` | `Falagard/Scrollbar` | `TLBB_Look_Scrollbar_Track` | `TLBBLook_ScrollBar.looknfeel.xml`:1193 | 6 |
| `TLBB_StopWatch` | `Falagard/StopWatch` | `TLBB_Look_NULL` (rỗng) | `TLBBLook_Common.looknfeel.xml`:3 | 7 |
| `TLBB_ButtonPageDown` | `Falagard/CheckBox` | `TLBB_Look_ButtonPageDown` | `TLBBLook_Button.looknfeel.xml`:3375 | 7 |
| `TLBB_ButtonCheckForRMBShop` | `Falagard/CheckBox` | `TLBB_Look_ButtonCheckRMBShop` | `TLBBLook_Button.looknfeel.xml`:6142 | 7 |
| `TLBB_ButtonCheckNULL` | `Falagard/CheckBox` | `TLBB_Look_ButtonNULL` | `TLBBLook_Button.looknfeel.xml`:736 | 7 |
| `TLBB_DragTitle` | `Falagard/DragTitle` | `TLBB_Look_DragTitle` | `TLBBLook_StaticText.looknfeel.xml`:33 | 7 |

Bảng `kKinds` của `SRC/gui/layout.cpp` so chuỗi con trên TargetType, nên hiện giờ: `Falagard/Listbox`,
`Falagard/ListBoxEx`, `Falagard/ComplexWindow`, `Falagard/Money`, `Falagard/StopWatch`,
`Falagard/DragTitle`, `Falagard/StaticText`, `Falagard/Scrollbar` rơi vào `kPlain`;
`Falagard/ActionButton` khớp `"Button"` thành `kButton`; `Falagard/CheckBox` thành `kCheck`;
`Falagard/SimpleText` thành `kText`. Chú ý thứ tự: thêm `"ActionButton"` phải đứng trước `"Button"`,
`"ListBoxEx"` không chứa `"Listbox"` (chữ B hoa) nên hai kiểu danh sách tự tách nhau.

---

## 1. Listbox thường: `TLBB_ListBoxCommon` (QuestLog_Listbox)

Lớp: `FalagardListbox` (Fal) kế thừa `Listbox` (Base); item là `CEGUI::ListboxTextItem` (Base; lớp
nối tạo bằng `new` 0x178 byte rồi gọi constructor export, `UI 0x18001f126..0x18001f15b`) [M].

### 1.1 Look `TLBB_Look_ListBoxCommon` [look]

- `Property SelectColour = tl:FFFFFFFF tr:FFFFFFFF bl:FFFFFFFF br:FFFFFFFF`
- `Property SelectBrush = set:CommonFrame image:CommonEditBoxBK` (ảnh 60x15 ở (128,48) của
  `Common/CommonFrame.tga`, `all.imageset.xml`:33678)
- `NamedArea ItemRenderingArea`: Left 6, Top 3, Right W-3, Bottom H-3
- `NamedArea ItemRenderingAreaVScroll`: Left 6, Top 3, Right W-3-rộng(`__auto_vscrollbar__`), Bottom H-3
- `Child TLBB_Scrollbar_Common nameSuffix="__auto_vscrollbar__"`: Left 0, Top 1, Width 16, Height
  H-2, `HorzAlignment RightAligned` → ô `{x = W-16, y = 1, w = 16, h = H-2}`
- `StateImagery Enabled` và `Disabled`: `TLBB_Look_Common/Background_Common1` rồi
  `TLBB_Look_Common/Frame_Type_Lace1`
- Không có `__auto_hscrollbar__`: `d_horzScrollbar` luôn null, không cuộn ngang.

`TLBB_Look_ListBoxTransparent` giống hệt về vùng, khác: thanh cuộn kiểu `TLBB_Scrollbar_Track` rộng
11, nền `TLBB_Look_Common/Background_Frame_ListBoxTransparent` (lớp của nó là ListBoxEx, mục 1B).

### 1.2 Thành viên (độ dời) [M]

`Listbox`: `d_sorted +0x3F0`, `d_multiselect +0x3F1`, `d_forceVertScroll +0x3F2`,
`d_forceHorzScroll +0x3F3`, `d_itemTooltips +0x3F4`, `d_vertScrollbar +0x3F8`, `d_horzScrollbar
+0x400`, `d_listItems` (vector con trỏ) `+0x408..+0x410`, `d_lastSelected +0x420`, `d_clickItem
+0x428` (Base 0x1800a0870), `SelectColour` (ColourRect) `+0x430`, `SelectBrush` (Image*) `+0x490`
(Base 0x1800a74f0).

`ListboxItem` / `ListboxTextItem`: chữ `String32 +0x08`, tooltip `+0x30`, `d_itemID +0x58` (64 bit,
Base 0x1800c24b0), `d_selected +0x68` (0x1800c3dc0), `d_autoDelete +0x6A`, `d_owner +0x70`,
`d_selectCols +0x78`, `d_selectBrush +0xD8`, `d_drawOffset +0xE0` (mặc định 0, `setDrawOffset`
0x1800c3cd0 không DLL nào import), cỡ đã nhớ `+0xF8` (rộng) `+0xFC` (cao), cờ "đã tính cỡ" `+0x100`,
`d_textCols +0x108`, `d_font +0x168`, `d_horzFormat +0x170`.

`Scrollbar`: `d_documentSize +0x3F0`, `d_pageSize +0x3F4`, `d_stepSize +0x3F8`, `d_overlapSize
+0x3FC`, `d_position +0x400`, cờ `changeToZero +0x404` (Base 0x1800c4e20..0x1800c4e60).

### 1.3 Vùng item và thanh cuộn

`FalagardListbox::getListRenderArea` (Fal 0x180006ae0) [M]:

```
v = d_vertScrollbar ? d_vertScrollbar->isVisible(true) : false     // cờ hiện của chính thanh cuộn
h = d_horzScrollbar ? d_horzScrollbar->isVisible(true) : false
if (v || h) {
    name = "ItemRenderingArea" + (h ? "H" : "") + (v ? "V" : "") + "Scroll"
    if (look.isNamedAreaDefined(name)) return look.getNamedArea(name).getPixelRect(*this)
}
return look.getNamedArea("ItemRenderingArea").getPixelRect(*this)
```

Khác 2008: `FalListbox.cpp:51-54` chỉ hỏi `d_vertScrollbar` khi `d_horzScrollbar` khác null, nên
với look không có thanh ngang bản 2008 không bao giờ dùng `ItemRenderingAreaVScroll`. Bản 2026 đã
sửa: thanh dọc hiện thì vùng item co mép phải lại đúng bề rộng thanh cuộn.

`Listbox::configureScrollbars` (Base 0x1800d5e90) [M], cùng thuật toán 2008
(`CEGUIListbox.cpp:659`):

```
total  = Σ item.getPixelSize(this).height          // getTotalItemsHeight 0x1800d6800
widest = max item.getPixelSize(this).width         // getWidestItemWidth 0x1800d6880
area   = getListRenderArea()                       // với trạng thái hiện của thanh cuộn lúc này
show_v = total > area.height || d_forceVertScroll  // so sánh chặt (comiss ja)
show_h = widest > area.width || d_forceHorzScroll
if (d_vertScrollbar) d_vertScrollbar->setVisible(show_v)   // nhánh ẩn hiện như 2008
if (d_horzScrollbar) d_horzScrollbar->setVisible(show_h)
area = getListRenderArea()                         // tính lại sau khi đổi ẩn hiện
if (d_vertScrollbar) {
    setDocumentSize(total); setPageSize(area.height)
    setStepSize(max(1.0f, area.height / 10.0f))    // hằng 10 ở Base 0x1801fe5b8, 1 ở 0x1801e1ef8
    setScrollPosition(d_vertScrollbar->d_position) // kẹp lại vào [0, max(total - page, 0)]
}
```

Chiều cao vùng item không đổi theo thanh cuộn (hai NamedArea cùng Top 3, Bottom H-3), nên quyết
định hiện thanh cuộn không dao động. `configureScrollbars` chạy ở `initialise`, `onSized` (Base
0x1800d74b0), `onListContentsChanged` (0x1800d6f80, tức sau mỗi `addItem`, `removeItem`,
`resetList`) và `handleUpdatedItemData`.

`Scrollbar::setScrollPosition(p)` (Base 0x1801037e0) [M]: `max = max(doc - page, 0)`; `p < 0 → 0`;
`p > max → max`; ghi `d_position` (số thực, KHÔNG làm tròn về điểm ảnh); đổi thì phát
`ScrollPositionChanged`; chạm `max` thì phát thêm sự kiện `0x1802e5ef8` (`EventHasScrollToEnd`).

### 1.4 Cỡ một item

`ListboxTextItem::getPixelSize(const Window* parent)` (Base 0x1800d9080) [M]:

```
font = d_font ?? (d_owner ? d_owner->getFont(true) : System::getDefaultFont())   // +0x168, +0x70
if (!font) return Size(0, 0)
if (!sizeCached) {                                   // byte +0x100
    sizeCached = true
    box = parent->testClassName("Listbox")
        ? size(parent->getListRenderArea())          // ô vùng item lúc này
        : parent->pixelSize                          // +0x110, +0x114
    if (0 <= d_horzFormat && d_horzFormat <= 3)
        size = font->getLineSize(d_text, 1.0f, 1.0f)                        // Base 0x18004f050
    else if (d_horzFormat <= 7)
        size = font->getFormattedSize(d_text, Rect(0,0,box), d_horzFormat, 1.0f, 1.0f, null)  // 0x18004e7f0
    size.height += (float)Font::LineSpace            // + 3, Base 0x1800d9249
}
return size
```

Khác 2008 (`CEGUIListboxTextItem.cpp:89`): bản 2026 nhớ cỡ. Cờ nhớ chỉ bị xoá bởi `setText` (Base
0x1800c42cc), `setHorzFomate` (0x1800d9346), `setFont(tên)` (0x1800d9315) và lớp nối khi `AddItem` có
tham số thứ tư (UI 0x18001f1e3) [M]. Cỡ item KHÔNG tính lại khi thanh cuộn hiện ra hay khi cửa sổ
đổi cỡ (chỉ ảnh hưởng item bẻ dòng, định dạng 4..7): bề rộng bẻ dòng là bề rộng vùng item lúc item
được đo lần đầu, tức ngay trong `addItem` → `configureScrollbars`, trước khi thanh cuộn kịp hiện.

`Font::getLineSize(text, sx, sy)` (Base 0x18004f050) [M]:

```
h = ascender - descender; x = 0; extent = 0
với mỗi mã c của text:
    ký tự thường (c < 0x10000, c != '\r', '\n', byte cao = 0) có glyph g (bảng 65536 ô x 24 byte ở
    Font+0xE8: ô +0 = ảnh glyph, ô +0x10 = advance; ô trống thì gọi rasterise(c), vtable +0x20):
        nếu đang trong cặp mã 0xFDxxxxxx ... 0xFExxxxxx: '{' bật ẩn, '}' tắt ẩn, ký tự đang ẩn bỏ qua
        extent = max(extent, x + (g.offsetX [+0x28] + g.width [+0x20]) * sx)
        x += g.advance * sx
        h = max(h, g.height [+0x24] * sy)
    dấu cách không có glyph: phông kiểu 1 (vtable +8) cộng `Font+0xAC` (cỡ phông) * 0.5 * sx,
        kiểu 0 cộng `Font+0xE0` * sx
    mã điều khiển byte cao 0xE3, 0xE9, 0xFA (hoạt ảnh/biểu cảm, id = 24 bit thấp, 0xE3 thì đổi dấu):
        có trong AnimateManager thì h = max(h, cao hoạt ảnh), x += rộng hoạt ảnh * sx
    0xFD bật, 0xFE tắt chế độ ẩn chữ trong ngoặc nhọn; mã khác (màu...) không chiếm chỗ
return Size(max(extent, x), h * sy)
```

Vậy với chữ một dòng không có biểu cảm: **cao item = max(ascender - descender, cao ảnh glyph cao
nhất) + 3 = S + 5** với phông bitmap (ô glyph cao đúng `S + 2`): **17** ở client 2026 (cỡ 12), 19
với phông cỡ 14 của bản tiếng Việt. Item bẻ dòng (định dạng 4..7) có `n` dòng: `getFormattedSize`
trả `n*(S+2) + 3*(n-1)` (mục 5 C.3), cộng 3 thành `n*(S+5)`.

Bề rộng của `getLineSize` không phải `getTextExtent`: glyph cuối đóng góp `offsetX + rộng ảnh =
-1 + (S+2)` thay cho advance, nên chuỗi kết thúc bằng ký tự hẹp có bề rộng đo lớn hơn tổng advance
(mục 5 C.2). Số này chỉ dùng cho `widest`.

### 1.5 Vẽ

`Listbox::populateRenderCache` (Base 0x1800d7560) [M]:

```
cacheListboxBaseImagery()                    // Fal 0x180006900: StateImagery isDisabled() ? "Disabled" : "Enabled"
widest = getWidestItemWidth()
if (d_vertScrollbar && d_vertScrollbar->isVisible(false))
    widest -= d_vertScrollbar->pixelWidth    // MỚI ở 2026 (0x1800d75c0); 2008 không trừ
area = getListRenderArea()
x = area.left; y = area.top
if (d_horzScrollbar) x -= d_horzScrollbar->d_position
if (d_vertScrollbar) y -= d_vertScrollbar->d_position
alpha = getEffectiveAlpha()
với mỗi item i theo thứ tự trong d_listItems:
    h = item.getPixelSize(this).height
    w = max(area.width, widest)
    itemRect = {left = x, top = y, right = x + w, bottom = y + h}
    clip = itemRect ∩ area
    y += h
    if (clip.width != 0) item.draw(geometryBuffer, itemRect, alpha, &clip)   // vtable +0x10
```

`ListboxTextItem::draw(buffer, targetRect, alpha, clipper)` (Base 0x1800d8e00) [M]:

```
if (d_selected && d_selectBrush) {
    r = targetRect; r.left -= d_drawOffset                         // d_drawOffset = 0 ở đây
    d_selectBrush->draw(buffer, owner, r, clipper, d_selectCols * alpha)   // Image::draw 0x180056c40:
}                                                                  // ảnh kéo giãn kín r, cắt theo clipper
font = như getPixelSize
if (font) {
    r = targetRect
    r.top  += (float)(int)(Font::LineSpace * 0.5f + 0.5f)          // = +2 (0x1800d8f29..0x1800d8fb0)
    r.left += d_drawOffset
    font->drawText(owner, d_text, r, clipper, d_horzFormat, d_textCols * alpha, false, 1.0f, 1.0f, true)
}                                                                  // Font::drawText 0x18004aa60
```

Thứ tự lớp: nền `Background_Common1`, khung `Frame_Type_Lace1`, rồi từng item (nền chọn trước, chữ
sau). Item đang chọn: ảnh `CommonFrame/CommonEditBoxBK` kéo giãn kín ô item (rộng = `max(rộng vùng,
widest)`, cao = cao item kể cả 3 điểm ảnh `LineSpace`), nhân màu `SelectColour` (trắng) và alpha
hiệu lực, cắt theo vùng item. Listbox thường KHÔNG có nền hover: `onMouseMove` (Base 0x1800d7210)
chỉ lo tooltip của item khi `d_itemTooltips` bật.

Màu chữ item: bốn góc cùng một màu, mặc định trắng `(1,1,1,1)` (UI 0x18001f01c..0x18001f035), tham
số thứ ba của `AddItem` thay nó (mục 1.7). Thẻ màu trong chuỗi đè lên màu này theo luật của phông
(mục 5 B.2).

Vị trí điểm ảnh của chữ (ghép với `Font::drawText`, mục 5 C.4 và C.5; `trunc` cắt về 0): với item
một dòng có mép trên `T` và mép trái `L` (toạ độ trong listbox), phông bitmap cỡ `S`:

```
ô chữ đưa cho drawText: top = T + 2, left = L
drawText dời phông bitmap lên 1: y_dòng = trunc(T + 2 - 1 + 0.5) = T + 1 (T nguyên, không âm)
ô glyph (S+2)x(S+2) có mép trên y_dòng, mép trái bút - 1; bút bắt đầu ở x = trunc(L + 0.5)
điểm (c, r) của bitmap SxS rơi vào (bút + c, y_dòng + 1 + r) = (L + c, T + 2 + r)
```

Tức hàng bitmap đầu ở `T + 2`, hàng cuối ở `T + S + 1`, còn 3 hàng trống tới mép dưới item (`T + S
+ 5`). Item bẻ dòng (định dạng 4..7) bị dời đúp nên cao hơn 1 điểm ảnh: dòng `k` có hàng bitmap
đầu ở `T + 1 + k*(S+5)`. Khi `T` lẻ (đang cuộn tới vị trí không nguyên) áp đúng phép `trunc` trên.

### 1.6 Chuột

`Listbox::getItemAtPoint(pt)` (Base 0x1800d64e0) [M], như 2008: `pt` phải nằm trong
`getListRenderArea()` (vùng đã co khi thanh cuộn hiện); `y = area.top - d_vertScrollbar->d_position`;
`pt.y < y` thì null; duyệt item: `y += h_i`, item đầu tiên có `y > pt.y` là kết quả.

`Listbox::onMouseButtonDown(e)` (Base 0x1800d7010) [M], KHÁC 2008 (`CEGUIListbox.cpp:958`):

```
Window::onMouseButtonDown(e)
item = getItemAtPoint(toạ độ cửa sổ của e.position)
if (item) {                                         // 2008 xoá vùng chọn kể cả khi bấm chỗ trống
    if (!(e.sysKeys & Control) || !d_multiselect) clearAllSelections_impl()
    if (e.button == LeftButton) { d_clickItem = item; onListItemClicked() }     // sự kiện "ListItemClick"
    if ((e.sysKeys & Shift) && d_lastSelected && d_multiselect) selectRange(index(item), index(d_lastSelected))
    else item.d_selected ^= 1                       // vừa xoá vùng chọn nên thành "đang chọn"
    d_lastSelected = item.d_selected ? item : null
    onSelectionChanged()                            // sự kiện "ItemSelectionChanged", MỌI nút chuột
    if (e.button == RightButton) { d_clickItem = item; onListItemRClicked() }   // "ListItemRClick"
}
e.handled = true
```

Bấm chỗ trống trong 2026 không đổi gì và không phát sự kiện. Bấm phải lên item: item đó thành item
đang chọn, phát `ItemSelectionChanged` trước rồi `ListItemRClick`. `onMouseButtonUp` (Base
0x1800d7190) phát `ItemSelectionByLButton` (nút trái) hoặc `ItemSelectionByRButton` (nút phải) bất
kể có trúng item hay không. Tên sự kiện đọc ở hàm khởi tạo tĩnh Base 0x1801cc690..0x1801cc7e0:
`ListItemsChanged` (0x1801cc690 ghi chuỗi Base 0x1801fd9d8 vào `Listbox::EventListContentsChanged`
ở 0x1802e3808), `ItemSelectionChanged`, `ItemSelectionByLButton`, `ItemSelectionByRButton`,
`ListItemClick`, `ListItemRClick` [M]. Layout QuestLog nối `ItemSelectionChanged` vào
`QuestLog_ListBox_SelectChanged()` và `ListItemRClick` vào `QuestLog_ListBox_RClick()`.

`Listbox::onMouseWheel(e)` (Base 0x1800d73b0) [M], như 2008: thanh dọc tồn tại, hiện và `doc > page`
thì `setScrollPosition(pos - step * e.wheelChange)`; `e.handled = true`. Một nấc bánh xe =
`step = max(1, cao vùng item / 10)` điểm ảnh (QuestLog_Listbox: 376 / 10 = 37,6). Cuộn theo ĐIỂM
ẢNH, không theo dòng; item đầu có thể bị cắt một phần ở mép trên vùng item.

### 1.7 Phương thức Lua của `MetaTable_Control_Listbox` (UI_CEGUI.dll 2026) [M]

| Phương thức | Hàm | Hành vi |
|---|---|---|
| `AddItem(text, id [, colour [, horzFmt]])` | UI 0x18001ef30 (ô vtable +0x10 của `LUA_CONTROL::ListBox`) | `text` phải là chuỗi, `id` phải là số, sai thì bỏ. `text` qua bộ phân tích thẻ (`colorTrans` = thuộc tính `ColorTrans` của listbox). Tạo `ListboxTextItem(text, id = (int)id, data = null, disabled = false, autoDelete = true)`. `colour` là chuỗi `"AARRGGBB"` đọc bằng `PropertyHelper::stringToColour` rồi `setTextColours(colour)` (bốn góc); vắng thì trắng. `item.d_selectCols = listbox.SelectColour (+0x430)`, `item.d_selectBrush = listbox.SelectBrush (+0x490)` (2008 ghi cứng `0xFFC8B88E` và `Common/HoverTextBak`, `UILuaControl.cpp:1370`). `horzFmt` là số: ghi `d_horzFormat` và xoá cờ nhớ cỡ. Cuối cùng `Listbox::addItem` → `ListItemsChanged`, `configureScrollbars`. Không trả gì. |
| `ClearListBox()` | UI 0x180023410 | `Listbox::resetList()` (Base 0x1800d7920): xoá item, `d_lastSelected = d_clickItem = null`, `configureScrollbars` (vị trí cuộn bị kẹp về 0 vì `doc = 0`), phát `ListItemsChanged`. KHÔNG phát `ItemSelectionChanged`. |
| `GetFirstSelectItem()` | UI 0x180025be0 | Trả **ID** (32 bit thấp của `d_itemID`, giá trị đã truyền cho `AddItem`) của item đang chọn đầu tiên theo thứ tự danh sách, không có thì `-1`. Không phải chỉ số. |
| `GetClickItem()` | UI 0x1800258d0 | Trả ID của `d_clickItem` (item vừa bị bấm trái hay phải), không có thì `-1`. |
| `SetItemSelectByItemID(id)` | UI 0x1800393a0 | `Listbox::setItemSelectStateByItemID(id, true)` (Base 0x1800d7da0): tìm item đầu tiên có ID đó; không thấy thì thôi (2008 ném ngoại lệ); đang chọn rồi thì thôi; không multiselect thì bỏ chọn mọi item; đặt chọn; `ensureItemIsVisible(index)`; phát `ItemSelectionChanged` (script nhận lại `QuestLog_ListBox_SelectChanged`). |
| `SetItemSelect(index)` | UI 0x180039350 | `setItemSelectState(index, true)`, chỉ số từ 0. |
| `GetCurrentFirstItem()` | UI 0x180025a90 | CHỈ SỐ (từ 0) của `Listbox::getFirstVisibleItem()` (Base 0x1800d6420): item đầu tiên có mép dưới nằm dưới mép trên vùng item (thấy được ít nhất một phần); không có thì `-1`. |
| `SetCurrentFirstItem(index)` | UI 0x180037be0 | `Listbox::setFirstVisibleItem(index)` (Base 0x1800d7a80): `index >= số item` thì bỏ; `top = Σ h_j (j < index)`, `total = Σ h`; `total == cao vùng` thì bỏ; `cao vùng > total - top` thì `top = total - cao vùng`; `setScrollPosition(top)` (kẹp về 0 khi âm). Tức đưa item lên mép trên, trừ khi đã ở trang cuối. |
| `EnsureItemIsVisable(index)` | UI 0x180024eb0 | [M] Tham số 2 không phải số thì không làm gì và không trả gì. Là số thì `Listbox::ensureItemIsVisible((size_t)(int)n)` (Base 0x1800d61a0, như 2008 `CEGUIListbox.cpp:1077`): `n` là CHỈ SỐ item tính từ 0, không phải ID; số âm thành chỉ số rất lớn nên rơi vào nhánh "quá cuối → item cuối". Script 2026 đã chú thích bỏ lời gọi này. |
| `GetItem`, `DelItem`, `GetItemNumber`, `SetListItemText`, `SetItemTooltip`, `SetItemUserData`, `GetItemUserData`, `ClearSelectState`, `GetItemByText`, `GetItemNumByItemId` | UI 0x180025d80, 0x180024340, 0x180026160, vtable +0x20, vtable +0x18, 0x180039bc0, 0x180026310, 0x180023450, 0x180025f00, 0x1800260e0 | [?] chưa tháo; năm script trong phạm vi không gọi. |

Trình tự của `QuestLog.lua` (dòng 468-486, 682-743): nhớ `GetCurrentFirstItem()`, `ClearListBox()`,
`AddItem` lại cả danh sách, `SetItemSelectByItemID(...)`, `SetCurrentFirstItem(nhớ)`. Vì
`ClearListBox` kẹp vị trí cuộn về 0 và `SetCurrentFirstItem` đặt lại theo chỉ số, vị trí cuộn sau
làm mới luôn rơi đúng mép trên một item.

---

---

## 1B. ListBoxEx: `TLBB_ListBoxTransparent` (MissionTrack_ListBoxTransparent)

Phạm vi: danh sách của `MissionTrack` (`MissionTrack_ListBoxTransparent`). Lớp này chỉ có ở bản 2026;
mã 2008 (`G:\TLBB\_ref`) không có `FalagardListBoxEx`, chỉ có phần nền `Listbox`/`ListboxTextItem`
để gọi tên. Ký hiệu nguồn: **F** = `CEGUIFalagard.dll`, **B** = `CEGUIBase.dll`, **U** = `UI_CEGUI.dll`
(đều ở `F:\tl 2026\Bin64`). Mọi địa chỉ là địa chỉ ảo như `pe_refs.py` in. Bản tháo nằm ở
`build/scratch/gui/lbx_*.txt`.

Mức chắc chắn ghi ở từng mục: **[2026]** = đọc từ mã máy, có địa chỉ; **[2008]** = chỉ theo mã nguồn
2008; **[chưa]** = chưa xác định.

### 1B.0 Tóm tắt một đoạn

FalagardListBoxEx **kế thừa `FalagardListbox` → `CEGUI::Listbox`** và KHÔNG tự vẽ: `populateRenderCache`,
bánh xe, bấm chọn, vùng item, thanh cuộn đều là của `Listbox` nền. Thứ nó thêm: (1) mỗi item có một
"kiểu" (`d_itemType`); kiểu 3 của MissionTrack sinh hai cửa sổ con thật `Falagard/Button` (nút mắt và
nút đóng) đặt đè lên dòng item; (2) `updateLayout()` đặt lại vị trí các nút theo tổng chiều cao item
và vị trí cuộn; (3) nút chỉ hiện sau khi chuột đứng trên item quá 500 ms (`Tick`); (4) hai sự kiện
`ButtonClickedForEye`, `ButtonClickedForClose`. Item là `ListboxTextItem` thường, chữ đi qua bộ phân
tích thẻ `#`, có thể tự xuống dòng theo bề rộng vùng item (tham số Lua thứ 5 = 4).

### 1B.1 Lớp, look, vtable

- Scheme: `TLBB_ListBoxTransparent` → `Falagard/ListBoxEx`, look `TLBB_Look_ListBoxTransparent`
  (`Schema/TLBBLook_List.looknfeel.xml` dòng 1849–1915).
- **[2026]** Kế thừa: constructor F 0x1800cb350 gọi constructor `FalagardListbox` (F 0x1800065f0) rồi
  đặt ba vtable: chính F 0x180129b58, `EventSet` F 0x180129e58, giao diện phụ `IFalagardListBoxEx`
  F 0x180129e88 đặt ở độ dời **+0x498** của cửa sổ. Factory F 0x1800cef40 cấp 0x4d0 byte và đăng ký
  cửa sổ với `CListBoxExManager::AddListBoxEx` (B 0x1800b1590).
- **[2026]** Vtable chính (bảng có tên ở `lbx_vt_named.txt`): chỉ các ô sau là của riêng lớp này —
  `initialise` (+0x40, F 0x1800cf490), `Tick` (+0x70, F 0x1800ceb90), `onMouseLeaves` (+0x180,
  F 0x1800cf820), `onMouseMove` (+0x188, F 0x1800cf840), `SetVScrollbarAlpha` (+0x2c8, F 0x1800ceae0)
  và năm hàm Buff/Bar (+0x2d0..+0x2f0, MissionTrack không dùng). Các ô còn lại trỏ về nền:
  `populateRenderCache` = `Listbox::populateRenderCache` (B 0x1800d7560), `onMouseWheel` =
  `Listbox::onMouseWheel` (B 0x1800d73b0), `onMouseButtonDown` = `Listbox::onMouseButtonDown`
  (B 0x1800d7010), `onSized` = `Listbox::onSized` (B 0x1800d74b0), `getListRenderArea` =
  `FalagardListbox::getListRenderArea` (F 0x180006ae0), `cacheListboxBaseImagery` =
  `FalagardListbox::cacheListboxBaseImagery` (F 0x180006900).
- **[2026]** Vtable giao diện `IFalagardListBoxEx` (+0x498): [0] `AddItemEx` F 0x1800cb4e0, [1]
  `AddItemExWithOutLayout` F 0x1800cb520, [2] `RequestLayOut` F 0x1800ce460, [3] `ResetListEx`
  F 0x1800ce490, [4] `RemoveItemEx` F 0x1800ce290, [5] `GetClickedButtonItem` F 0x1800ce280, [6]
  `updateLayout` F 0x1800cf970, [7] `SetFlash` F 0x1800cead0 (thân rỗng, chỉ `ret`), [8] `ShowButton`
  F 0x1800ceaf0.

#### Thành viên (độ dời trong cửa sổ) **[2026]**

| Độ dời | Kiểu | Nghĩa | Nguồn |
|---|---|---|---|
| +0x110, +0x114 | float | bề rộng, bề cao điểm ảnh của cửa sổ (`Window`) | B 0x1800d9199, B 0x1800d75c0 |
| +0x278 | String | tên cửa sổ | F 0x1800cf4de |
| +0x3f0 / +0x3f1 | bool | `d_sorted` / `d_multiselect` | B 0x1800d5b66 / B 0x1800d708d |
| +0x3f2 / +0x3f3 | bool | `d_forceVertScroll` / `d_forceHorzScroll` | B 0x1800d5ee8 / B 0x1800d5f15 |
| +0x3f8 / +0x400 | Scrollbar* | thanh cuộn dọc / ngang (ngang = null với look này) | F 0x1800cf5bc / F 0x1800cf738 |
| +0x408, +0x410 | con trỏ | đầu, cuối `d_listItems` (vector `ListboxItem*`) | B 0x1800d6800 |
| +0x420 / +0x428 | ListboxItem* | item chọn sau cùng / item bấm sau cùng | B 0x1800d7121 / B 0x1800d70ab |
| +0x430 | ColourRect | màu nền chọn (thuộc tính `SelectColour`) | B 0x1800a1bb0 |
| +0x490 | Image* | ảnh nền chọn (thuộc tính `SelectBrush`) | B 0x1800a1ba0 |
| +0x498 | vptr | giao diện `IFalagardListBoxEx` | F 0x1800cb37a |
| +0x4a0, +0x4a8, +0x4b0 | vector | bản ghi nút của item (con trỏ tới khối 0x68 byte) | F 0x1800cb383 |
| +0x4b8 | int | ID của item có nút vừa bấm (`GetClickedButtonItem`) | F 0x1800cf0d4, F 0x1800ce280 |
| +0x4bc | DWORD | `GetTickCount()` lúc chuột sang item có ID khác | F 0x1800cf8bc |
| +0x4c0 | int | ID của item đang dưới chuột, khởi tạo −1 | F 0x1800cb3a5, F 0x1800cf8b6 |
| +0x4c4 | int | chỉ số của item đang dưới chuột, khởi tạo −1 | F 0x1800cf897 |
| +0x4c8 | bool | "đã cho hiện nút" | F 0x1800cec34 |

Thanh cuộn (`Scrollbar`): +0x3f0 `documentSize`, +0x3f4 `pageSize`, +0x3f8 `stepSize`, +0x400
`position` (B 0x1800d73e3..0x1800d742b).

#### Bản ghi nút của một item (0x68 byte) **[2026]**

`+0x00` cửa sổ nút mắt, `+0x08` cửa sổ nút đóng, `+0x10` nút "sjsl" (kiểu 4), `+0x18` nút
"xuanzhan" (kiểu 9), `+0x20` int chỉ số item lúc tạo, `+0x24` int kiểu (1, 2, 3, 4, 8, 9, 12), `+0x28`
int "sjsl đang hiện", `+0x30..+0x60` bảy cửa sổ của kiểu 9 và 12 (thanh tiến độ, ảnh buff). Nguồn:
F 0x1800ce2fb..0x1800ce3f5 (`RemoveItemEx` huỷ từng cửa sổ theo kiểu), F 0x1800cbcd0, F 0x1800cc203.

### 1B.2 Item

#### 1B.2.1 Cấu trúc `ListboxItem` / `ListboxTextItem` bản 2026 **[2026]**

Lớp nối Lua cấp 0x178 byte và dựng `ListboxTextItem(String32 text, size_t id, void* data=0,
bool disabled=false, bool autoDelete=true)` (U 0x180020b55..0x180020b84; constructor B 0x1800d8ab0,
nền B 0x1800d82c0).

| Độ dời | Trường | Mặc định | Nguồn |
|---|---|---|---|
| +0x08 | `d_itemText` (String32) | | B 0x1800d82f4 |
| +0x58 | `d_itemID` (size_t) | tham số | B 0x1800c24b0 (`getID`) |
| +0x68 | `d_selected` | false | B 0x1800c3670 |
| +0x70 | `d_owner` (Window*) | null, `addItem` gán | B 0x1800d5b62 |
| +0x78 | `d_selectCols` (ColourRect) | `DefaultSelectionColour` | B 0x1800d835f |
| +0xd8 | `d_selectBrush` (Image*) | null | B 0x1800d837a |
| +0xe0 | `d_drawOffset` (float, `setDrawOffset`) | 0 | B 0x1800c3cd0 |
| +0xe4 | `d_itemType` (int, `getItemType`) | 0 | B 0x1800c2550 |
| +0xe8 | `d_SJSLItemType` (int) | 0 | B 0x1800c2690 |
| +0xec | `d_leaverItemType` (int) | 0 | B 0x1800c2560 |
| +0xf4 | int = 3 | 3 | B 0x1800d8396 — **[chưa]** nghĩa |
| +0xf8, +0xfc | cỡ đã đo (rộng, cao) | 0 | B 0x1800d9242 |
| +0x100 | bool "cỡ đã đo" | false | B 0x1800d90ff |
| +0x108 | `d_textCols` (ColourRect) | `DefaultTextColour` | B 0x1800d8ae8 |
| +0x168 | `d_font` (Font*) | null | B 0x1800d8b08 |
| +0x170 | `d_horzFormat` (TextFormatting) | 0 = `LeftAligned` | B 0x1800d8b0f, `setHorzFomate` B 0x1800d9340 |

`TextFormatting` (2008 `CEGUIFontBase.h:64`, khớp các nhánh so sánh `<= 3`, `<= 7` ở B 0x1800d91e4):
0 `LeftAligned`, 1 `RightAligned`, 2 `Centred`, 3 `Justified`, 4 `WordWrapLeftAligned`, 5
`WordWrapRightAligned`, 6 `WordWrapCentred`, 7 `WordWrapJustified`.

#### 1B.2.2 Cỡ item — `ListboxTextItem::getPixelSize(owner)` B 0x1800d9080 **[2026]**

```
font = d_font ?: (d_owner ? d_owner->getFont(true) : System::getDefaultFont())   // B 0x1800d90bb..0x1800d90e1
if (!font) return (0, 0)
if (!d_measured) {                       // +0x100; đo MỘT lần rồi nhớ
    d_measured = true
    if (owner->testClassName("Listbox")) {                 // vtable +0x220
        Rect a = owner->getListRenderArea()                 // vtable +0x268
        box = Rect((0,0), Size(a.right - a.left, a.bottom - a.top))
    } else box = Rect((0,0), Size(owner.pixelWidth, owner.pixelHeight))
    switch (d_horzFormat) {
      case 0..3: size = font->getLineSize(text, 1.0, 1.0)                      // B 0x18004f050
      case 4..7: size = font->getFormattedSize(text, box, fmt, 1.0, 1.0, null)  // B 0x18004e7f0
    }
    size.height += 3            // hằng uint ở B 0x1801e7354 = 3 (2008: FontBase::LineSpace, CEGUIFontBase.cpp:53)
}
return size
```

Khác 2008 (`CEGUIListboxTextItem.cpp:89`): bản 2026 **nhớ cỡ** sau lần đo đầu. Cờ nhớ chỉ bị xoá bởi
`setText` (B 0x1800c42cc), `setFont(tên)` (B 0x1800d9315), `setHorzFomate` (B 0x1800d9346); KHÔNG xoá
khi danh sách đổi cỡ hay khi thanh cuộn hiện/ẩn. Hệ quả cho bản viết lại: bề rộng bẻ dòng của một item
là bề rộng vùng item **tại lúc item được thêm** (`Listbox::addItem` B 0x1800d5b30 gọi
`onListContentsChanged` B 0x1800d6f80 → `configureScrollbars` → `getTotalItemsHeight` B 0x1800d6800
→ đo ngay, trước khi quyết định hiện thanh cuộn). Item làm tràn
danh sách vẫn được đo với vùng rộng (chưa có thanh cuộn); các item thêm sau đó đo với vùng hẹp.
MissionTrack luôn `ClearListBoxEx` rồi thêm lại tất cả nên quy tắc trên áp dụng cho từng lượt dựng.

#### 1B.2.3 Chiều cao dòng và bẻ dòng — hàm phông mà DLL thật sự gọi **[2026]**

- `Font` (B): +0xa0 `d_ascender`, +0xa4 `d_descender`, +0xa8 `d_height`, +0xac cỡ điểm.
  `getFontHeight(s)` = (ascender − descender)·s (B 0x18003b710); `getLineSpacing(s)` = height·s
  (B 0x18003b770); `getBaseline(s)` = ascender·s (B 0x18003b670).
- `BitmapFont::updateFont` (B 0x18003c3a0): chỉ nhận cỡ 12, 14, 16; **ascender = cỡ + 2** (hằng uint
  B 0x1801e7358 = 2), descender = 0, height = cỡ + 2. Ô glyph là hình vuông (cỡ + 2) × (cỡ + 2)
  (B 0x18003baa1..0x18003bc5b). Vậy với phông bitmap, `getFontHeight` = cỡ + 2: **14** cho
  `SongTiBmp12` bản GBK (cỡ 12), **16** cho bản mã trang 1258 (`VTNAM14.bin`, cỡ 14).
- Phông mặc định: `FontManager::doPostObjectAdditionAction` (B 0x180138870) đặt phông ĐẦU TIÊN được
  tạo làm mặc định; scheme khai `SongTiBmp12` đầu tiên. `UI_CEGUI.dll` không import `setDefaultFont`.
  Layout không đặt `Font` cho danh sách nên item dùng phông này.
- `Font::getLineSize(text, xs, ys)` B 0x18004f050: rộng = max(bước cộng dồn, mép phải glyph xa nhất);
  **cao = max(getFontHeight, cao ảnh từng glyph, cao hoạt ảnh biểu cảm)**. Ký tự điều khiển: mã có byte
  cao 0xE3/0xE9/0xFA là hoạt ảnh (cộng bề rộng, lấy max bề cao); 0xFD bật và 0xFE tắt chế độ "liên
  kết", trong đó đoạn nằm giữa `{` và `}` không được tính bề rộng (B 0x18004f2ec..0x18004f329,
  0x18004f3e3..0x18004f3f1). Dấu cách không có glyph: phông bitmap cộng cỡ·0,5; phông khác cộng
  trường +0xe0 (B 0x18004f379..0x18004f3c0).
- `Font::getFormattedSize` B 0x18004e7f0: tách theo `'\n'`; từ đoạn thứ hai cộng 3 trước mỗi đoạn
  (float 3 ở B 0x1801e1f00); đoạn rỗng cộng `getFontHeight`; fmt 0..3 gọi `getLineSize`, fmt 4..7 gọi
  `getWrappedSize` (B 0x18004fd90); rộng = max các đoạn, cao = tổng.
- `Font::getWrappedSize(text, box, xs, ys, …)` B 0x18004fd90 — bẻ dòng:

```
wrap = box.right - box.left
line = ""; extent = 0; height = 0; maxH = getFontHeight()
for c in 0..len-1:
    line += text[c]
    adv = getTextExtent(line, xs)                      // B 0x18004f530
    extent = max(extent, adv)
    maxH = max(maxH, cao glyph hoặc cao hoạt ảnh của text[c])
    if adv > wrap:
        n = line.length                                // đã gồm ký tự làm tràn
        if System.codePage != 936:                     // System +0x118, B 0x18005005d
            // lùi về ký tự ngắt gần nhất trong tối đa min(n, 13) ký tự cuối, kể cả ký tự làm tràn
            for k in 0 .. min(n,13)-1:
                if line[n-1-k] in {' ', ',', '.', '?', '!'}:   // bảng B 0x1801e7368..0x1801e737c
                    n -= k; c -= k; break
        height += maxH + 3; maxH = getFontHeight(); extent = wrap
        if n > 2: c -= 1                               // ký tự làm tràn (hoặc ký tự ngắt) mở đầu dòng sau
        line = ""
return Size(extent, height + maxH)
```

  Nghĩa là: mã trang 936 (GBK) bẻ **theo ký tự** như 2008 (`CEGUIFontBase.cpp:604`); mã trang khác
  (bản tiếng Việt 1258) bẻ **theo từ**, lùi tối đa 13 ký tự tới một trong năm ký tự ngắt, và **ký tự
  ngắt nằm ở đầu dòng sau** (dòng trước kết thúc ngay trước nó). Không thấy ký tự ngắt trong 13 ký tự
  thì bẻ giữa từ. Dòng đã bẻ có bề rộng bằng `wrap`.
- Hệ quả: khi mọi glyph không cao hơn `getFontHeight` (đúng với phông bitmap), một item có N dòng
  nhìn thấy cao **N × (H + 3)**, H = `getFontHeight` — 17 mỗi dòng với cỡ 12, 19 mỗi dòng với cỡ 14.

**[chưa]** Hàm vẽ `Font::drawText` (B 0x18004aa60) có bẻ dòng đúng cùng luật với `getWrappedSize`
không: chưa tháo (thuộc bộ máy chữ). Nghĩa của ảnh glyph +0x24 (dùng làm "cao glyph") chưa đối chiếu
với `Image::getHeight`; với phông bitmap ô glyph là (cỡ+2)² nên không đổi kết quả.

#### 1B.2.4 Chữ item có đi qua thẻ `#` không **[2026]**

Có. Lớp nối đổi chuỗi Lua bằng U 0x180059660 rồi U 0x18004b170 (đối tượng toàn cục U 0x1800b6460,
tham số cờ là byte `cửa sổ + 0x308`) ra `String32` trước khi dựng item — đúng hai hàm mà
`Listbox::AddItem` thường gọi (U 0x18001f004, 0x18001f121); mã 2008 tương ứng là
`CUIStringSystem::ParserString_Runtime` (`UILuaControl.cpp:1366`). Màu, viền (`#e010101` mà script
luôn đặt đầu chuỗi), biểu cảm, liên kết `#{_INFOAIM…}` nằm trong `String32` dưới dạng mã điều khiển;
bề rộng và bề cao ở mục 2.3 tính trên chuỗi đã đổi. Nội dung bộ phân tích: thuộc nhánh bộ máy chữ.

### 1B.3 Lớp nối Lua (`LUA_CONTROL::ListBoxEx`, U)

Metatable `MetaTable_Control_ListBoxEx` (U 0x1800b63d8) **đặt metatable của nó là
`MetaTable_Control_Listbox`** (U 0x18002da25..0x18002da33), nên mọi phương thức của Listbox thường
(`SetCurrentFirstItem`, `GetCurrentFirstItem`, `SetItemSelectByItemID`, `ClearListBox`, `AddItem`…)
gọi được trên `MissionTrack_ListBoxTransparent`; Listbox lại kế thừa metatable Window.

Chỉ số ngăn xếp Lua: 1 = bản thân, 2 = tham số đầu.

#### 1B.3.1 `AddItemExWithoutLayout(text, id, type [, colour [, format [, sjsl, …, leaver]]])` — U 0x180020920 **[2026]**

| Tham số Lua | Điều kiện | Tác dụng | Nguồn |
|---|---|---|---|
| 1 `text` | `lua_isstring`, sai thì bỏ cả lệnh | chữ item, qua bộ phân tích thẻ | U 0x18002097f, 0x180020b50 |
| 2 `id` | phải là số, sai thì bỏ | `d_itemID` (script đưa chỉ số nhiệm vụ) | U 0x18002099b, 0x180020b6c |
| 3 `type` | phải là số, sai thì bỏ | `d_itemType` (+0xe4) | U 0x1800209b0, 0x180020c19 |
| 4 `colour` | nếu là chuỗi | `setTextColours(PropertyHelper::stringToColour)`, chuỗi "AARRGGBB"; vắng thì trắng (1,1,1,1) | U 0x180020a4b..0x180020bae |
| 5 `format` | nếu là số | `d_horzFormat` (+0x170) và xoá cờ nhớ cỡ | U 0x180020bf7..0x180020c12 |
| 6 | nếu là số | `d_SJSLItemType` (+0xe8) | U 0x180020c2e..0x180020c43 |
| 9 | nếu là số | `d_leaverItemType` (+0xec) | U 0x180020c57..0x180020c6c |

Luôn làm thêm: `item.d_selectCols` = ColourRect ở `cửa sổ + 0x430`; `item.d_selectBrush` = Image* ở
`cửa sổ + 0x490` (U 0x180020bb4..0x180020be2) — tức `SelectColour`, `SelectBrush` của look. Khác 2008
(`UILuaControl.cpp:1370`: màu `0xFFC8B88E`, ảnh `Common/HoverTextBak` viết cứng). Cuối cùng gọi ô [1]
của giao diện: `FalagardListBoxEx::AddItemExWithOutLayout(item)`.

`AddItemEx(...)` (U 0x180020570): cùng tham số 1..5, không đọc tham số 6 và 9, gọi ô [0] `AddItemEx`.

MissionTrack.lua dùng ba dạng: tiêu đề nhiệm vụ `("#e010101" .. "  #Y(cấp) tên trạng_thái", chỉ_số,
3, "FFF8A10A", 4)` (dòng 531); dòng nhóm `("#e010101#cff9900Tên nhóm", 100+kind, 0)` (dòng 536, 1971);
dòng mô tả mục tiêu `("#e010101…", chỉ_số, 0, màu, 4)` (dòng 1888, 1977).

#### 1B.3.2 `FalagardListBoxEx::AddItemExWithOutLayout(item)` — F 0x1800cb520 **[2026]**

```
if (!item) { updateLayout(); return }
Listbox::addItem(item)                               // F 0x1800cb570
switch (item->d_itemType):
  1: bản ghi{type=1}; nút mắt                         // F 0x1800cb589
  2: bản ghi{type=2}; nút đóng                        // F 0x1800cb94e
  3: bản ghi{type=3}; nút mắt và nút đóng             // F 0x1800cbc98
  4,5,6,7: bản ghi; (4: thêm nút "__button__sjsl__%02d", Falagard/ActionButton, look TLBB_Look_ButtonFriendPresent)
  8: bản ghi không có cửa sổ                          // F 0x1800cdfb3
  9, 12: nút "xuanzhan", thanh tiến độ, ảnh buff       // F 0x1800cc240, 0x1800cd173
  khác (0…): không có bản ghi
updateLayout()                                        // F 0x1800ce24d — tên hàm nói "không layout" nhưng vẫn gọi
```

Kiểu 3, chi tiết (F 0x1800cbc98..0x1800cc229):

- `index = getItemIndex(item)`; bản ghi +0x20 = index, +0x24 = 3.
- Nút mắt: tên `<tên danh sách> + "__button__eye__%02d"` (index); nếu `WindowManager` chưa có cửa sổ
  tên đó thì `createWindow("Falagard/Button", tên)` và `setLookNFeel("Falagard/Button",
  "TLBB_Look_SingleTrackOpen")`, có rồi thì lấy lại; đăng ký `PushButton::EventClicked` →
  `handleButtonClickedForEye` (F 0x1800cf130). Ghi vào bản ghi +0x00.
- Nút đóng: tên `… "__button__close__%02d"`, look `TLBB_Look_SingleTrackClose`, `EventClicked` →
  `handleButtonClickedForClose` (F 0x1800cf050). Ghi vào bản ghi +0x08.
- `addChildWindow` cả hai vào danh sách (F 0x1800cc20c, 0x1800cc219); đẩy bản ghi vào vector +0x4a0.
- Không đặt cỡ, vị trí, ẩn hiện ở đây: `updateLayout` làm.

Look hai nút (`TLBBLook_Button.looknfeel.xml` dòng 3603 và 3687): state `Normal`/`Hover`/`Pushed`
dùng section `normal`/`hover`/`pushed`, mỗi section một `FrameComponent` phủ cả cửa sổ với ảnh nền
`MissionAtrack/MKEye_{Normal,Hover,Pushed}` (16×10) và `MissionAtrack/MKMiniClose_{…}` (14×13);
`Disabled` = `normal` nhân màu `FF7F7F7F`. Là `Falagard/Button` thường nên bộ vẽ nút hiện có của
`SRC/gui` vẽ được.

#### 1B.3.3 `AddItemEx(item)` — F 0x1800cb4e0 **[2026]**

`AddItemExWithOutLayout(item); updateLayout(); requestRedraw(true)`. Khác bản "WithoutLayout" chỉ ở
lệnh vẽ lại.

#### 1B.3.4 `RequestLayout()` — U 0x180032bb0 → F 0x1800ce460 **[2026]**

`updateLayout(); requestRedraw(false)`.

#### 1B.3.5 `updateLayout()` — F 0x1800cf970 **[2026]** (thuật toán xếp nút)

```
Rect a = getListRenderArea()            // toạ độ trong cửa sổ danh sách; Rect = {top, bottom, left, right}
scroll = d_vertScrollbar->position      // cửa sổ +0x3f8, thanh cuộn +0x400
for rec in bản ghi:
    i = rec.index;  if (i >= số item) continue
    above = Σ_{k<i} item[k].getPixelSize(this).height
    (w, h) = item[i].getPixelSize(this)
    switch (rec.type):
      1: mắt.  pos = (1.5, a.top + 3.5 + above - scroll);        size = (16, 10)
      2: đóng. pos = (a.left + w, a.top + 2.0 + above - scroll); size = (14, 13)
      3: đóng như kiểu 2 rồi mắt như kiểu 1
    với mỗi nút: setPosition(Absolute, pos); setSize(Absolute, size); setAlwaysOnTop(true); setVisible(false)
```

Hằng số: 1,5 (0x3fc00000 ở F 0x1800cfb05 và 0x1800cfcc5), 3,5 (F 0x180142290), 2,0 (F 0x18012fb5c),
16×10 (0x41800000, 0x41200000 ở F 0x1800cfcef), 14×13 (0x41600000, 0x41500000 ở F 0x1800cfc5e).
`Window::setPosition(Absolute, v)` làm tròn từng toạ độ bằng `(float)(int)(v + 0.5)` (B 0x1800a6f17);
nên nút mắt nằm ở **x = 2**, **y = a.top + above − scroll + 4** (khi các số hạng nguyên), nút đóng ở
**x = a.left + w**, **y = a.top + above − scroll + 2**, đều tính từ góc trái trên của danh sách.
`w` là bề rộng ĐO của item (mục 2.2): chữ một dòng thì nút đóng nằm sát ngay sau chữ; chữ đã bẻ dòng
thì `w` = bề rộng vùng item, nút đóng nằm ở mép phải vùng item (một phần hay cả nút ra ngoài danh
sách và bị cửa sổ cha cắt). Mỗi lần `updateLayout` đều ẩn mọi nút kiểu 1, 2, 3; `Tick` hiện lại.

Kiểu khác (không dùng ở MissionTrack, ghi để đủ): kiểu 4 nút sjsl ở (155,5; a.top + 3,5 + above −
scroll) cỡ 20×20, hiện khi bản ghi +0x28 = 1, `setClippedByParent(true)` (F 0x1800cfd40..0x1800cfde8);
kiểu 9 nút ở (320; a.top + 5 + above − scroll) cỡ 24×24 (F 0x1800cfe00..). Phần còn lại của kiểu 9 và
12 (F 0x1800cfe69..0x1800d074c) **[chưa]** đọc.

`handle_scrollChange` (F 0x1800cf3b0): `updateLayout(); requestRedraw(false)`. `initialise`
(F 0x1800cf490) đăng ký hàm này cho `Scrollbar::EventScrollPositionChanged` của thanh cuộn dọc (và
ngang nếu có), nên mỗi lần cuộn các nút được đặt lại.

#### 1B.3.6 `ClearListBoxEx()` — U 0x180023430 → `ResetListEx` F 0x1800ce490 **[2026]**

`Listbox::resetList()` (B 0x1800d7920), rồi với mỗi bản ghi: `WindowManager::destroyWindow` các cửa
sổ theo kiểu (kiểu 3: đóng rồi mắt), giải phóng bản ghi; xoá rỗng vector; `requestRedraw(false)`.
Không đụng +0x4b8..+0x4c8.

#### 1B.3.7 `GetClickedButtonItem()` — U 0x180025a10 → F 0x1800ce280 **[2026]**

Trả `int` ở cửa sổ +0x4b8: **ID của item** (số script truyền ở tham số 2 của `AddItemEx…`, tức chỉ số
nhiệm vụ) có nút vừa bấm, không phải chỉ số dòng. Gán trong hai handler ở mục 5.

#### 1B.3.8 `SetVScrollbarAlpha(chuỗi)` — U 0x18003b860 → F 0x1800ceae0 **[2026]**

Tham số phải là chuỗi (`lua_isstring`); `PropertyHelper::stringToFloat` rồi gọi ô vtable +0x2c8:
`d_vertScrollbar->setAlpha(a)`. Chỉ thanh cuộn dọc đổi alpha.

#### 1B.3.9 Các phương thức thừa hưởng từ Listbox mà MissionTrack gọi **[2026]**

- `GetCurrentFirstItem()` — U 0x180025a90: `item = Listbox::getFirstVisibleItem()` (B 0x1800d6420),
  trả `getItemIndex(item)` hoặc −1. `getFirstVisibleItem`: `y = a.top − scroll`; duyệt item, `y +=
  cao`; item đầu tiên có `y > a.top` (mép dưới nằm dưới mép trên vùng item).
- `SetCurrentFirstItem(n)` — U 0x180037be0 → `Listbox::setFirstVisibleItem(n)` (B 0x1800d7a80):

```
if (n >= số item) return
areaH = a.bottom - a.top;  above = Σ_{k<n} cao[k];  total = Σ cao
if (total == areaH) return
if (areaH > total - above) above = total - areaH      // không cuộn quá trang cuối
d_vertScrollbar->setScrollPosition(above)
```

  Đơn vị là điểm ảnh; "item đầu" chỉ là cách quy ra vị trí cuộn.
- `SetItemSelectByItemID(id)` — U 0x1800393a0 (chỉ làm khi tham số là số) →
  `Listbox::setItemSelectStateByItemID(id, true)` (B 0x1800d7da0): tìm item ĐẦU TIÊN có `d_itemID ==
  id`; đã chọn rồi thì thôi; không `multiselect` thì bỏ chọn mọi item; đặt `d_selected`;
  `ensureItemIsVisible(chỉ số)` (B 0x1800d61a0); phát `onSelectionChanged` (vtable +0x2a0).
  `ensureItemIsVisible`: `top = above − scroll`, `bottom = top + cao`; nếu `top < 0` hoặc `cao >
  areaH` thì cuộn tới `scroll + top`; ngược lại nếu `bottom >= areaH` thì cuộn tới `scroll + bottom −
  areaH`.
- `GetItemNumByMissionId(id)` — U 0x1800260e0 → `Listbox::getItemNumByItemId(id)` (B 0x1800d6670):
  chỉ số item đầu tiên có ID đó, không có thì −1. Tham số không phải số cũng trả −1.

#### 1B.3.10 Bảng phương thức Lua → hành vi (mọi lời gọi của MissionTrack.lua lên danh sách)

| Phương thức | Tham số | Trả về | Hành vi | Hàm |
|---|---|---|---|---|
| `GetCurrentFirstItem()` | — | chỉ số item đầu đang thấy, −1 | mục 3.9 | U 0x180025a90 |
| `ClearListBoxEx()` | — | — | xoá item, huỷ nút | U 0x180023430 |
| `AddItemExWithoutLayout(text, id, type, colour?, format?)` | mục 3.1 | — | thêm item, tạo nút theo kiểu, `updateLayout` | U 0x180020920 |
| `RequestLayout()` | — | — | `updateLayout`, vẽ lại | U 0x180032bb0 |
| `GetItemNumByMissionId(id)` | số | chỉ số item, −1 | tìm theo ID | U 0x1800260e0 |
| `SetCurrentFirstItem(n)` | số | — | cuộn để item n ở đầu vùng | U 0x180037be0 |
| `SetItemSelectByItemID(id)` | số | — | chọn item đầu tiên có ID, cuộn cho thấy | U 0x1800393a0 |
| `GetClickedButtonItem()` | — | ID item có nút vừa bấm | mục 3.7 | U 0x180025a10 |
| `SetVScrollbarAlpha(s)` | chuỗi số | — | alpha của thanh cuộn dọc | U 0x18003b860 |

Trình tự của script (`MissionTrack_UpdateHaveGetMission`, dòng 468–552): nhớ `GetCurrentFirstItem` →
`ClearListBoxEx` → thêm từng dòng → `RequestLayout` → `SetCurrentFirstItem` (dòng của nhiệm vụ được
chọn hoặc vị trí đã nhớ) → `SetItemSelectByItemID` khi có nhiệm vụ được chọn.

### 1B.4 Vẽ

#### 1B.4.1 Thứ tự — `Listbox::populateRenderCache` B 0x1800d7560 **[2026]**

```
cacheListboxBaseImagery()               // F 0x180006900: state "Enabled", hoặc "Disabled" khi isDisabled
widest = getWidestItemWidth()           // B 0x1800d6880: max bề rộng đo của item
if (vscroll && vscroll->isVisible(false)) widest -= vscroll.pixelWidth
Rect a = getListRenderArea()
x = a.left - (hscroll ? hscroll.position : 0)
y = a.top  - (vscroll ? vscroll.position : 0)
alpha = getEffectiveAlpha()
for item in d_listItems:
    h = item.getPixelSize(this).height
    w = (widest <= a.right - a.left) ? a.right - a.left : widest
    Rect r = {top: y, bottom: y + h, left: x, right: x + w};  y += h
    Rect clip = r ∩ a
    if (clip.right - clip.left == 0) continue
    item.draw(buffer, r, alpha, &clip)   // vtable +0x10
```

Thanh cuộn và các nút là cửa sổ con nên vẽ sau phần trên theo thứ tự cửa sổ con của CEGUI (nút được
đặt `AlwaysOnTop` ở `updateLayout`); thứ tự vẽ cửa sổ con của bản 2026 chưa tháo lại ở đây.

- Nền: look chỉ có `Background_Frame_ListBoxTransparent` của `TLBB_Look_Common`
  (`TLBBLook_Common.looknfeel.xml` dòng 3426): một `ImageryComponent`, vùng trái 1, trên 0, phải =
  rộng, dưới = cao, ảnh `CommonFrame/ListBoxTransparent_BK` (20×15), `VertFormat` và `HorzFormat`
  đều `Tiled`. Không có khung.
- Cuộn dọc **theo điểm ảnh** (`y = a.top − position`), không theo dòng.

#### 1B.4.2 Một item — `ListboxTextItem::draw(buffer, r, alpha, clip)` B 0x1800d8e00 **[2026]**

```
if (d_selected && d_selectBrush):
    Rect s = r;  s.left -= d_drawOffset                      // B 0x1800d8e62
    d_selectBrush->draw(buffer, d_owner, s, clip, modulate(d_selectCols, alpha))   // B 0x180056c40: kéo giãn vào s
font = như getPixelSize;  if (!font) return
Rect t = r
t.top  += PixelAligned(3 * 0.5) = 2                          // B 0x1800d8efd..0x1800d8fb4, hằng 3 ở B 0x1801e7354
t.left += d_drawOffset                                       // 0 với MissionTrack
font->drawText(d_owner, d_itemText, t, clip, d_horzFormat, modulate(d_textCols, alpha), false, 1.0, 1.0, true)   // B 0x18004aa60
```

- Nền item đang chọn: ảnh `CommonFrame/CommonEditBoxBK` (60×15, `SelectBrush` của look) kéo giãn phủ
  **cả ô item** `r` (từ `a.left` tới `a.left + max(widest, bề rộng vùng)`, cao bằng item), màu
  `SelectColour` = `FFFFFFFF` nhân alpha, vẽ TRƯỚC chữ, cắt theo `clip`.
- Chữ: bắt đầu ở mép trái ô item, **cách mép trên ô item 2 điểm ảnh**; màu nền chữ là tham số
  `colour`, thẻ trong chuỗi đổi màu từng đoạn. Khác 2008 chỉ ở `d_drawOffset`.
- Không có nền riêng cho item dưới chuột (hover): `draw` không đọc trạng thái nào ngoài `d_selected`.

#### 1B.4.3 Vùng item — `FalagardListbox::getListRenderArea` F 0x180006ae0 **[2026]**

`v = vscroll && vscroll->isVisible(true)`, `h = hscroll && hscroll->isVisible(true)` (chỉ xét cờ ẩn
hiện của chính thanh cuộn). Có ít nhất một cái thì dựng tên `"ItemRenderingArea" + (h ? "H" : "") +
(v ? "V" : "") + "Scroll"` và dùng nếu look khai; không thì `"ItemRenderingArea"`. Với look này:

- `ItemRenderingArea`: trái 6, trên 3, phải = rộng − 3, dưới = cao − 3.
- `ItemRenderingAreaVScroll`: trái 6, trên 3, phải = rộng − 3 − bề rộng `__auto_vscrollbar__` (11),
  dưới = cao − 3.

#### 1B.4.4 Thanh cuộn dọc **[2026]** (điều kiện, cỡ) và look

- Con `__auto_vscrollbar__` kiểu `TLBB_Scrollbar_Track` (look `TLBB_Look_Scrollbar_Track`,
  `TLBBLook_ScrollBar.looknfeel.xml` dòng 1193): trái 0, trên 1, rộng 11, cao = cao danh sách − 2,
  `HorzAlignment` `RightAligned` → x = rộng danh sách − 11. Look không khai `__auto_hscrollbar__`;
  `initialise` chỉ tạo thanh nào `WindowManager::isWindowPresent` thấy (F 0x1800cf520, 0x1800cf6aa)
  nên thanh ngang là null và mọi chỗ của `Listbox` nền đều kiểm null trước khi dùng.
- `Listbox::configureScrollbars` B 0x1800d5e90, chạy khi danh sách đổi nội dung
  (`onListContentsChanged` B 0x1800d6f80), đổi cỡ (`onSized` B 0x1800d74b0) và cuối `initialise`
  (F 0x1800cf7e0):

```
total = Σ cao item;  widest = max rộng item;  a = getListRenderArea()
if (total > a.height || forceVert):
    vscroll.show();  a = getListRenderArea()
    hscroll: show nếu (widest > a.width || forceHorz), không thì hide
else if (widest > a.width || forceHorz):
    hscroll.show();  a = getListRenderArea()
    vscroll: show nếu (total > a.height || forceVert), không thì hide
else: vscroll.hide(); hscroll.hide()
a = getListRenderArea()
vscroll: setDocumentSize(total); setPageSize(a.height); setStepSize(max(1, a.height / 10)); setScrollPosition(position)
```

  Hằng 10 ở B 0x1801fe5b8, 1 ở B 0x1801e1ef8. Thanh dọc hiện khi **tổng cao item > cao vùng item**
  (so sánh chặt); khi hiện, vùng item hẹp đi 11 điểm ảnh ở mép phải.
- Bánh xe — `Listbox::onMouseWheel` B 0x1800d73b0: nếu thanh dọc đang hiện và `documentSize >
  pageSize` thì `setScrollPosition(position − stepSize × wheelChange)`; bước = max(1, cao vùng
  item / 10) điểm ảnh cho mỗi đơn vị `wheelChange` (MissionTrack 1280×720: 13,3). **[chưa]** độ lớn
  `wheelChange` của một nấc bánh xe (do nơi bơm sự kiện quyết định) và phép kẹp trong
  `Scrollbar::setScrollPosition` (B 0x1801037e0).
- Hình của `TLBB_Look_Scrollbar_Track`: nền `main` = ảnh `MissionAtrack/MKScrollBar_Bar` (11×73) kéo
  giãn trong vùng trái 0, trên 11, rộng 11, dưới = cao − 11; nút giảm `__auto_decbtn__`
  (`TLBB_ButtonNULL`, ảnh `MKUp_*` 11×11) ở trên cùng; nút tăng `__auto_incbtn__` (`MKDown_*` 11×11)
  ở dưới cùng; con trượt `__auto_thumb__` kiểu `TLBB_MissonTrackThumb_Common`, ảnh
  `MKScrollBar_Thumb_*` 11×13; `ThumbTrackArea` trên 11, dưới = cao − 11. Cỡ con trượt theo tỉ lệ và
  bước bấm nút: phần thanh cuộn chung của phiên chính.
- `SetVScrollbarAlpha` đổi alpha của riêng cửa sổ thanh cuộn (mục 3.8).

#### 1B.4.5 Bấm chuột lên item — `Listbox::onMouseButtonDown` B 0x1800d7010 **[2026]**

Bản 2026 không lọc nút chuột ở đầu hàm (2008 chỉ xử lý nút trái). Với item dưới chuột
(`getItemAtPoint`, B 0x1800d64e0: điểm phải nằm trong vùng item; duyệt cộng dồn chiều cao từ `a.top −
scroll`): không giữ Ctrl hoặc không `multiselect` thì bỏ chọn tất cả; nút trái: nhớ item, phát
`onListItemClicked` (vtable +0x290); đảo `d_selected` của item (hoặc chọn dải khi Shift và
`multiselect`); phát `onSelectionChanged` (+0x2a0); nút phải: phát `onListItemRClicked` (+0x298).
Layout MissionTrack không đăng ký các sự kiện này; hiệu ứng thấy được là nền chọn của item.

### 1B.5 Nút của item: hiện, ẩn, sự kiện

#### 1B.5.1 Chuột — `onMouseMove` F 0x1800cf840, `onMouseLeaves` F 0x1800cf820 **[2026]**

```
onMouseMove(e):
    p = relativeToAbsolute(screenToWindow(e.position))
    item = getItemAtPoint(p);  if (!item) return          // không gọi hàm nền
    d_hoverIndex = getItemIndex(item)                      // +0x4c4
    if (item.d_itemID != d_hoverID):                       // +0x4c0
        hideAllButtons();  d_hoverID = item.d_itemID;  d_hoverTick = GetTickCount()
    Listbox::onMouseMove(e)
onMouseLeaves(e): hideAllButtons(); requestRedraw(true)
```

`hideAllButtons` (F 0x1800cf3e0) ẩn nút của mọi bản ghi kiểu 1, 2, 3. So sánh theo **ID**, không theo
chỉ số: tiêu đề nhiệm vụ và các dòng mục tiêu của nó cùng ID, nên rê chuột từ tiêu đề xuống dòng mục
tiêu không ẩn nút và không tính lại thời gian.

#### 1B.5.2 `Tick()` — F 0x1800ceb90 **[2026]**

`CListBoxExManager::Tick` (B 0x1800b1630) gọi ô vtable +0x70 của mọi ListBoxEx đã đăng ký; nơi gọi
nó là U 0x18006e6dd (hàm U 0x18006e65f; **[chưa]** xác nhận đó là vòng mỗi khung).

```
p = vị trí con trỏ (MouseCursor +0x30, +0x34) đổi sang toạ độ cửa sổ
item = getItemAtPoint(p)
if (!item): if (d_buttonsShown) { hideAllButtons(); d_buttonsShown = false };  return
if (GetTickCount() - d_hoverTick <= 500) return          // 0x1f4 ở F 0x1800cec19
if (d_hoverIndex < 0) return
d_buttonsShown = true
rec = bản ghi đầu tiên có index == d_hoverIndex;  if (!rec) return
kiểu 1: mắt.setVisible(true);  kiểu 2: đóng.setVisible(true);  kiểu 3: cả hai
```

Nút của một tiêu đề chỉ hiện khi chuột đứng trên CHÍNH dòng tiêu đề (bản ghi tìm theo chỉ số dòng)
quá 500 ms kể từ lúc chuột sang nhiệm vụ đó; sau đó giữ nguyên tới khi chuột sang item có ID khác,
rời vùng item, rời danh sách, hoặc tới lần `updateLayout` kế (cuộn, thêm item) — lần `Tick` sau lại
hiện.

#### 1B.5.3 Dò ô nút và phát sự kiện **[2026]**

Nút là cửa sổ con thật nên việc dò là dò cửa sổ thông thường trên ô đã đặt ở mục 3.5 (chỉ khi nút
đang hiện). Bấm trọn một lần (nhấn rồi nhả trong nút, `PushButton::EventClicked`):

- `handleButtonClickedForEye` F 0x1800cf130: tìm bản ghi kiểu 1 hoặc 3 có `+0x00 ==` cửa sổ phát sự
  kiện và `0 <= index < số item`; `d_clickedID (+0x4b8) = getListboxItemFromIndex(index)->d_itemID`;
  phát sự kiện `ButtonClickedForEye` (biến `EventButtonClickedForEye` F 0x1801e8a50, namespace
  F 0x1801e8a30) với `WindowEventArgs(cửa sổ nút)`. Layout nối nó với
  `MissionTrack_ItemContextClickedForEye()`.
- `handleButtonClickedForClose` F 0x1800cf050: như trên với bản ghi kiểu 2 hoặc 3 và `+0x08`; sự kiện
  `ButtonClickedForClose` (F 0x1801e8a70) → `MissionTrack_ItemContextClickedForClose()`.

Script lấy ID bằng `GetClickedButtonItem()` ngay trong handler.

### 1B.6 Ví dụ số (1280×720)

Ô cửa sổ `MissionTrack_ListBoxTransparent`: x 1014, y 286, w 212, h 139 (`tests/golden/ui_rects.tsv`
dòng 2251). Chưa có thanh cuộn → `ItemRenderingArea` trong cửa sổ: trái 6, trên 3, phải 209, dưới 136
(rộng 203, cao 133); có thanh cuộn → phải 198 (rộng 192). Thanh cuộn nếu hiện: trong cửa sổ x 201,
y 1, 11×137 → màn hình (1215, 287, 11, 137).

Hai item đầu của một lượt dựng: dòng nhóm `"#e010101#cff9900<Tên nhóm>"` (kiểu 0, format 0), rồi tiêu
đề `"#e010101  #Y(30) <Tên nhiệm vụ> "` (kiểu 3, màu `FFF8A10A`, format 4) vừa một dòng, bề rộng chữ
đo được là W. H = `getFontHeight` của phông mặc định; cao item = H + 3.

| | Phông bitmap cỡ 12 (mã trang 936, H = 14) | Phông bitmap cỡ 14 (mã trang 1258, H = 16) |
|---|---|---|
| Ô item 0 (màn hình x, y, w, h) | 1020, 289, 203, 17 | 1020, 289, 203, 19 |
| Chữ item 0 bắt đầu | x 1020, y 291 | x 1020, y 291 |
| Ô item 1 | 1020, 306, 203, 17 | 1020, 308, 203, 19 |
| Chữ item 1 bắt đầu | x 1020, y 308 | x 1020, y 310 |
| Nút mắt của item 1 | trong cửa sổ (2, 24) → màn hình 1016, 310, 16, 10 | (2, 26) → 1016, 312, 16, 10 |
| Nút đóng của item 1 | trong cửa sổ (6 + W, 22) → màn hình 1020 + W, 308, 14, 13 | (6 + W, 24) → 1020 + W, 310, 14, 13 |

Cách tính nút mắt cỡ 12: x = PixelAligned(1,5) = 2; y = PixelAligned(3 + 3,5 + 17 − 0) =
PixelAligned(23,5) = 24. Nút đóng: y = PixelAligned(3 + 2 + 17) = 22; với W = 120 thì x = 126 → màn
hình 1140. Hai dấu cách đầu chuỗi tiêu đề của script là chỗ cho nút mắt (x 2..18 trong khi chữ bắt
đầu ở x 6). Nếu tiêu đề dài hơn 203 và bẻ thành 2 dòng: item cao 34 (cỡ 12) hoặc 38 (cỡ 14), nút
đóng ở x = 6 + 203 = 209 trong cửa sổ (chỉ còn 3 điểm ảnh nằm trong danh sách rộng 212).

Thanh cuộn hiện khi tổng cao > 133: với item một dòng cỡ 12 là từ item thứ 8 (8 × 17 = 136); cỡ 14 là
từ item thứ 8 (7 × 19 = 133 chưa hiện, 8 × 19 = 152 hiện). Khi đó `documentSize` = tổng cao,
`pageSize` = 133, `stepSize` = 13,3.

Phần W (bề rộng chữ) phụ thuộc bước của từng glyph trong tệp phông và bộ phân tích thẻ: nhánh bộ máy
chữ.

### 1B.7 Chưa xác định (kèm chỗ cần đọc tiếp)

1. `Font::drawText` (B 0x18004aa60): luật bẻ dòng lúc VẼ, khoảng cách giữa các dòng, cách vẽ viền
   `#e`; mới đọc phần ĐO (`getWrappedSize`, `getLineSize`, `getFormattedSize`).
2. Bộ phân tích chuỗi U 0x18004b170 (và bước đổi mã U 0x180059660), nghĩa của cờ byte `cửa sổ +
   0x308`.
3. Giá trị `System + 0x118` (mã trang) của bản client tiếng Việt lúc chạy: mã chỉ cho biết khác 936
   thì bẻ theo từ; tệp `.font` gợi ý 1258.
4. `Window::requestRedraw(bool)`: nghĩa của tham số bool (bản 2026 thêm).
5. `Scrollbar::setScrollPosition` (B 0x1801037e0): phép kẹp; cỡ và vị trí con trượt; độ lớn
   `wheelChange` mỗi nấc.
6. `ListboxItem + 0xf4` (= 3) dùng ở đâu.
7. Kiểu item 4..9 và 12 (nút sjsl, xuanzhan, thanh tiến độ, ảnh buff): mới đọc chỗ tạo và vị trí nút
   của kiểu 4 và 9; phần còn lại của `updateLayout` ở F 0x1800cfe69..0x1800d074c và các hàm
   `SetBuffImage*`, `SetBar*` (F 0x1800ce670..0x1800cead0) chưa đọc. MissionTrack không dùng.
8. Hàm U 0x18006e65f (nơi gọi `CListBoxExManager::Tick`) có phải vòng mỗi khung không.
9. Cửa sổ con có bị danh sách cắt không khi nút đóng ra ngoài mép phải: suy từ mặc định
   `clippedByParent` của CEGUI, chưa đọc cờ của nút kiểu 2 và 3 (kiểu 4 thì mã gọi thẳng
   `setClippedByParent(true)`, F 0x1800cfde8).

---

## 2. Nút action: `TLBB_ActionButton`, `TLBB_ActionButtonNULL`

Lớp: `FalagardActionButton` (Fal) kế thừa `FalagardButton` → `PushButton` → `ButtonBase`, kèm giao
diện `IFalagardActionButton` ở `Window+0x728` (vtable Fal 0x1801232e8: +0x18 `setAnimate`, +0x20
`cleanAnimate`, +0x28 `setPercentageImage`, +0x30 `cleanPercentageImage`, +0x48 `setLogicItemData`,
+0x50 `getLogicItemData`, +0x58 `getDragAcceptName`, +0x60 `setFlashEnable`, +0x68 `FirReSet`, +0x70
`setDrawCorner`) [M].

### 2.1 Look [look]

`TLBB_Look_ActionButton` (`TLBBLook_Button.looknfeel.xml`:5):

- `PropertyDefinition DragThreshold = 8.0`, `FlashAnimate = ProgressFlash`, `Property ClickSound = 17`
- `NamedArea ActionArea`: Left 1, Top 1, Right W-1, Bottom H-1
- `ImagerySection normal`: một ImageryComponent không có ảnh (ô 0,0..W,H) → không vẽ gì
- `ImagerySection hover`: `CommonFrame/ActionButtonHover` (30x30) kéo giãn vào ô 1,1..W-1,H-1
- `ImagerySection pushed`: `CommonFrame/ActionButtonPushed` (30x30) kéo giãn vào ô 1,1..W-1,H-1
- `ImagerySection default`: `Icons0/ButtonActive0` (32x32) kéo giãn vào ô 1,1..W-1,H-1
- `ImagerySection disabled`: `Face_04/Remind_Bak` (32x32) kéo giãn vào ô 1,1..W-1,H-1
- `ImagerySection BackgroundImage`: `CommonItem/ActionBK` (34x34) kéo giãn vào ô 0,0..W,H
- `StateImagery`: `BackgroundImage` → `BackgroundImage`; `Normal` → `normal`; `Hover` → `hover`;
  `Pushed` → `pushed`; `Defaulted` → `default`; `Disabled` → `disabled`

`TLBB_Look_ActionButtonNULL` (cùng tệp:444): `ActionArea` = 0,0..W,H; `hover`, `pushed`, `default`
phủ ô 0,0..W,H (`default` dùng `CommonFrame/ActionButtonHover`); `BackgroundImage` =
`CommonItem/ActionBK`; `StateImagery Disabled` = section `default` nhân màu `88888888` (bốn góc).

`PropertyDefinition` của look ghi thẳng vào thuộc tính thật của lớp [M]: lúc gán look,
`WidgetLookFeel::initialiseWidget` (Base 0x18012d3a0) gọi `window.setProperty(tên,
getDefault())` cho từng `PropertyDefinition` (không `addProperty` như CEGUI gốc), rồi mới áp
các `Property` của look và tạo cửa sổ con. `Window::setProperty` (Base 0x1800a7030) tra tên
qua `Window::getPropertyInstance` (Base 0x1800a1880): bộ thuộc tính của lớp (`Window+0x2B8`)
TRƯỚC, bộ của look sau, không thấy thì ném "There is no Property named". `FalagardActionButton::addActionButtonProperties`
(Fal 0x1800aac00) đã thêm `DragThreshold` (đối tượng tĩnh Fal 0x1801f1820) và `FlashAnimate`
(Fal 0x1801f1700) vào bộ của lớp, nên hai dòng `PropertyDefinition` trên đặt ngưỡng kéo 8,0 và
hoạt ảnh nháy `ProgressFlash` cho mọi nút dùng look này. Tên chỉ có ở look (lớp không có thuộc
tính ấy) thì giá trị nằm trong chuỗi người dùng của cửa sổ (`PropertyDefinition::set` Base
0x180126c10 → `setUserString`), không tới thành viên nào của lớp.

### 2.2 Thành viên [M: constructor Fal 0x1800a9e90, các get/set export]

`ButtonBase`: `d_pushed +0x3F0`, `d_hovering +0x3F1`. `PushButton`: `d_autoscaleImages +0x458`,
`d_useStandardImagery +0x459`, `d_useNormalImage +0x45A`, `d_useHoverImage +0x45B`,
`d_usePushedImage +0x45C`, `d_useDisabledImage +0x45D`; bốn `RenderableImage` ở `+0x460` (normal:
màu `+0x470`, ô `+0x4D0`, định dạng `+0x4E8/+0x4EC`, ảnh `+0x4F8`), `+0x500`, `+0x5A0`, `+0x640`.
`FalagardActionButton`: `d_empty +0x738` (mặc định 1), `d_checked +0x739`, `d_gloom +0x73A`,
`d_default +0x73B`, cờ cho phép nháy `+0x748` (`setFlashEnable`), `d_draggingEnabled +0x749`,
`d_leftMouseDown +0x74A`, `d_dragging +0x74B`, `d_dragPoint +0x74C`, `d_dragThreshold +0x754` (mặc
định 4,0; look đặt 8,0, cơ chế ở mục 2.1), sáu chuỗi góc `String32` ở `+0x778, +0x7A0, +0x7C8, +0x7F0, +0x818, +0x840`,
phông riêng của chuỗi thứ sáu `+0x868`, hoạt ảnh 1 (`d_animate +0x880`, khung hiện tại `+0x890`,
alpha `+0x898`), hoạt ảnh nháy (`+0x8A8`, khung `+0x8B8`, alpha `+0x8C0`), ảnh phần trăm `+0x8D0`,
`BackImage` (RenderableImage) `+0x8D8`, `UseDefaultTooltip +0x978`, cờ `+0x979` (mặc định 1), sáu cờ
vẽ góc `+0x97A..+0x97F` (mặc định 1, `setDrawCorner(pos, bool)` Fal 0x1800ac860).

### 2.3 Thứ tự vẽ: `FalagardActionButton::drawSelf` (Fal 0x1800abac0) [M]

```
if (d_needsRedraw) {
  1. look có StateImagery "BackgroundImage" thì vẽ nó                       // ActionBK kín ô cửa sổ
  2. d_backImage.draw()            // thuộc tính BackImage: kéo giãn (định dạng 3,3) kín ô cửa sổ; thường rỗng
  if (d_empty) {
  3a.   if ((d_hovering || d_pushed) && !isDisabled(true)) drawHover()     // FalagardButton::drawHover
  3b.   drawAcceCorner()           // Fal 0x1800aae90: chỉ chuỗi góc TRÊN PHẢI (+0x7A0), xem 2.5
  } else {
  4.    drawNormal()               // Fal 0x180002aa0, xem 2.4: state "Normal" rồi icon
  5.    if (ảnh phần trăm) drawPercentageImg()   // Fal 0x1800ab9e0: trắng, alpha 0,75, kéo giãn kín ActionArea
        if (d_dragging && !d_gloom) {
  6a.       drawPushed()           // rồi KẾT THÚC: không góc, không nháy
        } else {
            if (!isDisabled(true) && !d_gloom) {
  6b.           if (d_pushed || d_checked) drawPushed()
  6c.           if (d_hovering && !d_checked) drawHover()
  6d.           drawAnimate()      // Fal 0x1800ab030: khung hoạt ảnh (CoolDown...) kín ActionArea
  6e.           if (d_default) drawDefault()   // state "Defaulted"
            } else {
  6f.           drawDisabled()     // state "Disabled" (+ DisabledImage nếu có)
  6g.           if (d_pushed || d_checked) drawPushed()
  6h.           drawAnimate()      // MỚI ở 2026: 2008 không vẽ hoạt ảnh khi mờ
            }
  7.        drawCorner()           // Fal 0x1800ab120, xem 2.5
  8.        drawFlash()            // Fal 0x1800ab8d0: cần cờ +0x748; khung hoạt ảnh nháy kín ActionArea
        }
  }
}
Window::drawSelf()
```

`drawHover`, `drawPushed`, `drawDisabled` (Fal 0x1800029c0, 0x180002c70, 0x1800028e0):
`doButtonRender(state)` rồi nếu có `HoverImage`/`PushedImage`/`DisabledImage` thì vẽ ảnh đó trong ô
đã đặt sẵn (cả cửa sổ). `doButtonRender(state)` (Fal 0x1800026b0): khi `d_useStandardImagery` thì vẽ
StateImagery `state`, look không có `state` thì vẽ `"Normal"` (như CEGUI 0.4.1).

Khác 2008 (`FalActionButton.cpp:112`): thêm bước 1, 2, 3b, 5, 6h, 8; màu hoạt ảnh là trắng `(1,1,1)`
thay vì vàng `(1,1,0)`; hoạt ảnh và nháy vẽ trong `ActionArea` chứ không phải cả cửa sổ.

Hệ quả cho bộ vẽ của dự án (`draw_button` trong `SRC/gui/paint.cpp` vẽ một state rồi một ảnh): nút
action cần vẽ CHỒNG LỚP: nền, icon, rồi lớp phủ `Pushed`/`Hover`/`Disabled`. `SetPushed(1)` không
thay icon mà phủ `ActionButtonPushed` lên trên; đang `Checked` thì hover không vẽ thêm.

### 2.4 Icon vẽ vào ô nào

`FalagardButton::drawNormal` (Fal 0x180002aa0) [M], MỚI ở 2026 (2008 `FalButton.cpp:63` luôn vẽ
ảnh trong ô đã đặt):

```
doButtonRender("Normal")
if (d_useNormalImage) {
    if (look.isNamedAreaDefined("ActionArea"))
        d_normalImage.rect = look.getNamedArea("ActionArea").getPixelRect(*this)     // ghi +0x4D0
    d_normalImage.colours.alpha = getEffectiveAlpha()
    d_normalImage.draw()
}
```

Ô mặc định của ảnh (khi look không có `ActionArea`) là `Rect(0, 0, W, H)`: `PushButton::
setNormalImage` (Base 0x1800fd540) và `PushButton::onSized` khi `d_autoscaleImages` (0x1800fd020)
[M]. Ảnh kéo giãn kín ô [08: `CEGUIPushButtonProperties.cpp`, `NormalImage::set` đặt
`HorzStretched`/`VertStretched`; lớp nối và dự án đang dùng đúng cách này].

Vậy: **icon của `TLBB_ActionButton` vẽ kéo giãn vào ô (1, 1)..(W-1, H-1)**; nút 34x34 cho icon
32x32, lệch 1 điểm ảnh mỗi cạnh so với ô cửa sổ. `TLBB_ActionButtonNULL`: icon kín cả ô cửa sổ.
Luật này áp cho MỌI `FalagardButton` có `NormalImage` mà look khai `ActionArea` (ví dụ
`TLBB_Look_ActionButtonTooltip`: lề 2). `stretch_property(..., "NormalImage")` của dự án đang vẽ
kín cả ô cửa sổ: lệch 1 điểm ảnh ở mọi nút action của HUD.

### 2.5 Chữ góc: `drawCorner` (Fal 0x1800ab120) và `drawAcceCorner` (0x1800aae90) [M]

Phông: `getFont(true)` của nút (không có thì bỏ cả hàm); màu `ColourRect` trắng (2008: vàng). `fh =
ascender - descender` của phông. `W, H` = cỡ cửa sổ. Mỗi chuỗi chỉ vẽ khi khác rỗng và cờ vẽ góc bật.

| Vị trí | Chuỗi | Cờ | Ô `Rect(left, top, right, bottom)` | Canh | Phông, màu |
|---|---|---|---|---|---|
| 0 TopLeft | +0x778 | +0x97A | `(2, 2, W, H)` | Left | phông nút, trắng |
| 1 TopRight | +0x7A0 | +0x97B | `(0, 2, W-2, H)` | Right | phông nút, trắng |
| 2 BotLeft | +0x7C8 | +0x97C | `(2, H-fh-2, W, H)` | Left | phông nút, trắng |
| 3 BotRight | +0x7F0 | +0x97D | `(0, H-fh-2, W-2, H)` | Right | phông nút, trắng |
| 4 (mới) | +0x818 | +0x97E | `(0, H-fh-18, W, H)` | Centred | phông `YouYuan18`, `0xFFFFF263`; mã đầu chuỗi bị ghi đè `0xFFFFFFFF` |
| 5 (mới) | +0x840 | +0x97F và `+0x979 == 1` | `(0, (H-fh5)*0,5, W, H)` với `fh5` của phông `+0x868` | Centred | phông `+0x868` (phải khác null), `0xFF00FFFF`; mã [0] = `0xFC0E0D26`, [1] = `0xFF00FFFF` |

Hằng: 2 ở Fal 0x18012fb5c, 18 ở 0x18013e134, 0,5 ở 0x1801189cc. Nút trống (`d_empty`) chỉ vẽ vị
trí 1 qua `drawAcceCorner`, không xét cờ `+0x97B`.

`setCornerChar(pos, str)` (Fal 0x1800ac710) [M]: chuỗi lưu = hai mã điều khiển + tối đa 3 ký tự
đầu của `str`; mã [0] = `0xFBFFFFFF` (màu chữ trắng), mã [1] = `0xFC010101` (màu viền `010101`),
như 2008 `FalActionButton.cpp:455` nhưng nhận `pos` 0..5. Ý nghĩa mã `0xFB`/`0xFC`: mục 5.

### 2.6 Chuột, trạng thái, tooltip [M]

- `onMouseButtonDown` (Fal 0x1800ac130), như 2008: nút trái hay phải → `captureInput()` được thì
  `d_pushed = true`, `updateInternalState`, vẽ lại, `handled`. Nút trái và `DraggingEnabled` và
  chưa kéo → nhớ `d_dragPoint`, `d_leftMouseDown = true`.
- `onMouseButtonUp` (Fal 0x1800ac220), như 2008: nút trái, đang `d_pushed` và chuột nhả trên chính
  nút (`getGUISheet()->getChildAtPosition`) → `onClicked` (ô vtable +0x290; bỏ qua khi đang kéo) →
  sự kiện `Clicked` (layout nối vào hàm Lua). Nút phải nhả trên nút → `onRBClicked` (+0x2B8) → sự
  kiện `RBClicked`. Rồi `releaseInput`, `d_leftMouseDown = false`.
- `onMouseMove` (Fal 0x1800ac320) [08 cho phần kéo: `FalActionButton.cpp:386`]: vượt
  `DragThreshold` (8) thì `d_dragging = true`, phát `DragStarted`. `CommonSkill` và `LifeSkill` bật
  `DraggingEnabled`; `ActionSkill` thì không.
- Tên chuỗi sự kiện riêng của lớp đọc ở hàm khởi tạo tĩnh [M]: `EventRBClicked` (Fal 0x1801e7648)
  = `"RBClicked"` (Fal 0x180109f20), `EventDragStarted` (Fal 0x1801e7528) = `"DragStarted"` (Fal
  0x180109dd0); `Clicked` là `PushButton::EventClicked` (Base 0x1802e5668) = `"Clicked"` (Base
  0x1801ce2c0).
- `getTooltip()` (Fal 0x1800ac000): trả tooltip mặc định của `System` chỉ khi `d_empty` hoặc
  `UseDefaultTooltip`; nút đang giữ một action trả null (tooltip là SuperTooltip do logic game mở
  qua sự kiện MouseEnter/MouseLeave mà lớp nối đăng ký). `initialise` rỗng (0x1800ac030).
- `Gloom`: thuộc tính `Gloom` → `d_gloom` → bước 6f (ảnh `Remind_Bak` phủ ô 1,1..W-1,H-1).

### 2.7 Phương thức Lua của `MetaTable_Control_ActionButton` [M]

Lớp nối `LUA_CONTROL::ActionButton` có giao diện `tActionReference` ở `this+0x10` (vtable UI
0x18008a848: +0 `BeDestroyed`, +8 `Update(id)`, +0x10 `SetCheck(bool)`, +0x18 `SetDefault(bool)`,
+0x20 `EnterCoolDown`), cửa sổ CEGUI ở `this+8`, action đang giữ ở `this+0x18`.

| Phương thức | Hàm | Hành vi |
|---|---|---|
| `SetActionItem(id)` | UI 0x180028d70 → `Update` UI 0x18003d980 | `id` phải là số. `item = ActionSystem->GetAction(id)`. Gỡ tham chiếu khỏi action cũ. **`item == null` (ví dụ `-1`)** → `BeDestroyed` (UI 0x180022ae0): `setProperty("Empty", "True")`, `setLogicItemData`, `cleanAnimate`, `requestRedraw` → nút vẽ như ô trống: chỉ `BackgroundImage` (`ActionBK`), lớp `Hover` khi chuột ở trên, và chữ góc trên phải. Icon cũ còn nằm trong `NormalImage` nhưng không vẽ vì `d_empty`. Có action: `item->IsEnabled()` → thuộc tính `Gloom` = False, ngược lại True; `setLogicItemData(item->GetID())`; `setFlashEnable(item->vtable[0xB8]())`; `AddReference`; `setProperty("Empty", "False")`; tên icon khác rỗng thì `setProperty("NormalImage", IconManager::GetIconFullName(item->GetIconName()))`. 2008 còn gọi `show()` (`UILuaControl.cpp:894`), bản 2026 không. |
| `SetPushed(n)` | UI 0x1800290e0 → `SetCheck` UI 0x180036d10 | `setProperty("Checked", n == 1 ? "True" : "False")`, `requestRedraw`. Lớp `Pushed` phủ lên icon (bước 6b/6g). |
| `SetNewFlash()` | UI 0x180029060 | Không tham số. Có action thì `setFlashEnable(item->vtable[0xB8]())` (cờ `+0x748`); không có action thì không làm gì. Ảnh nháy: thuộc tính `FlashAnimate` (look đặt `ProgressFlash`) → `setFlashAnimate` (Fal 0x1800ac880) lấy hoạt ảnh của `AnimateManager`, ghi mốc thời gian; mỗi lượt `updateSelf` (Fal 0x1800ad210) gọi `updateAnimateFlash` (0x1800ad140): khi cờ bật, khung = `Animate::getFrame(now_ms - mốc, tổng)`, alpha = `getFrameAlpha(...)`; `drawFlash` vẽ khung đó trắng, alpha ấy, kéo giãn kín `ActionArea`. |
| `DoAction()` | UI 0x180028990 | [08] `m_pActionItem->DoAction()`. |
| `Gloom()` / `Bright()` | UI 0x180028cf0 / 0x180028970 | Thuộc tính `Gloom` True / False. |
| `ActionDisable()` / `ActionEnable()`, `SetFlash`, `ShowPercentage`, `SetDrawCorner`, `GetActionItem`, `DoSubAction` | UI 0x180028930, 0x180028950, 0x180028ed0, 0x180029140, 0x180028e30, 0x180028c90, 0x180028b10 | [?] chưa tháo kỹ; ba script kỹ năng không gọi. |

Phương thức chung của `Window` mà nút dùng: `SetToolTip(text)` (UI 0x18003b740: chuỗi qua bộ phân
tích thẻ rồi `Window::setTooltipText`), `Show`/`Hide`, `SetProperty`.

---

## 3. Cửa sổ phức hợp: `TLBB_ComplexWindow` (QuestLog_Desc)

Lớp: `FalagardComplexWindow` (Fal) kế thừa `Window`, kèm giao diện `IFalagardComplexWindow` ở
`Window+0x400` (vtable Fal 0x180123998: +0 `AddChildElement_Text`, +8 `_Option`, +0x10
`_HyperLink`, +0x18 `_Item`, +0x20 `_Action`, +0x28 `_Money`, +0x30 `_ChatBoard`, +0x38
`ClearAllElement`, +0x40 `RemoveTopElement`, +0x48 `PageEnd`, +0x60 `_JiaoZi`, +0x68
`SetActionButtonCheck`) [M]. Cửa sổ con chứa nội dung là `FalagardComplexWindow::ParentWindow`
(vtable Fal 0x1801379d8).

### 3.1 Look `TLBB_Look_ComplexWindow` [look]

- `Property ActionButtonSize = w:35 h:35`, `Property ActionButtonDistance = w:10 h:10`
- `Property ChildItem` (khoá → kiểu cửa sổ con): `Option` → `TLBB_QuestButton`, `RewardItem` →
  `TLBB_RewardItem`, `ActionButton` → `TLBB_ActionButton`, `Button` → `TLBB_ButtonNULL`, `Money` →
  `TLBB_Money`, `JiaoZi` → `TLBB_JiaoZi`, `ChatBoard` → `TLBB_ChatBoard`, `Image` →
  `TLBB_StaticImageNULL`
- `Property QuestButtonImage` chỉ số 0..31 (ảnh của nút lựa chọn)
- `Child TLBB_ComplexWindow_ParentWindow nameSuffix="__auto_parent__"`: Left 5, Top 5, Right W-17,
  Bottom H-5 → ô `{x = 5, y = 5, w = W-22, h = H-10}`
- `Child TLBB_Scrollbar_Common nameSuffix="__auto_vscrollbar__"`: Left 0, Top 0, Width 16, Height H,
  `RightAligned` → ô `{x = W-16, y = 0, w = 16, h = H}`
- Không có StateImagery: bản thân cửa sổ không vẽ nền hay khung.

Vùng nội dung luôn chừa 17 điểm ảnh bên phải dù thanh cuộn có hiện hay không (không có vùng thay
thế kiểu `...VScroll`).

### 3.2 Thành viên [M: `performWindowLayout` Fal 0x180074360, constructor 0x18006f500]

`d_ActionButtonSize +0x408` (w) `+0x40C` (h); `d_ActionButtonDistance +0x410` (w) `+0x414` (h);
`d_scrollPosOffset +0x42C` (Fal 0x1800426e0); `d_ParentWindow +0x430`; `d_vertScrollbar +0x438`;
`d_ChildVector +0x448..+0x450`; `d_totalHeight +0x490`; `TextColor` (colour) `+0x494`, mặc định
trắng. Khác 2008: cỡ và khoảng cách nút là ĐIỂM ẢNH TUYỆT ĐỐI (35 và 10), bản 2008 là tỉ lệ của vùng
(`0.129293 x 0.1236715`, `FalagardComplexWindow.cpp:124`).

Phần tử (`ChildElement`): `d_Type +0x28`, `d_rectClient +0x2C` (top) `+0x30` (bottom) `+0x34` (left)
`+0x38` (right), `d_Font +0x40`, `d_Typeset +0x98`, chữ `String32 +0xA0` (loại Text) hoặc cửa sổ con
`+0xA0` (và cửa sổ thứ hai `+0xA8` của loại Option), `d_ReArrange +0xD0`, `d_Radio +0xD1`. Giá trị
`d_Type` (bảng nhảy Fal 0x180074c4c): 0 Text, 1 Option, 2 Item, 3 Action, 4 Money, 5 HyperLink, 6
ChatBoard, 7 JiaoZi.

### 3.3 Xếp dọc: `performWindowLayout` (Fal 0x180074360) [M]

```
area  = d_ParentWindow->getAbsoluteRect()       // chỉ dùng rộng areaW = W-22 và cao areaH = H-10
y = 0; x = 0                                     // fHeightNow, fItemPosition
pos = d_vertScrollbar->d_position
với phần tử e thứ i (bỏ qua nếu e.d_Font == null):
  Text (0):
      x = 0
      h = e.font->getFormattedSize(e.text, area, e.typeset, 1.0f, 1.0f, null).height
      e.rect = {left 0, top y, right areaW, bottom y + h}
      y += h + (float)Font::LineSpace            // h + 3 (0x18007450e); 2008: h * 1.2
  Option (1):
      x = 0
      if (i > 0 && trước != null && trước.type != Option) y += e.font->lineSpacing   // 2008: * 2
      th = e.font->lineSpacing * 1.7f            // hằng Fal 0x180137e64
      e.rect = {0, y, areaW, y + th}
      cửa sổ +0xA0: vị trí (0, y - pos), cỡ (th, th)             // ô vuông (ảnh của lựa chọn)
      cửa sổ +0xA8: vị trí (th, y - pos), cỡ (areaW - th, th)    // nút chữ
      y += (float)((double)th * 1.08)            // hằng double 0x180137e68; 2008 cắt về int
  Item (2), Action (3):
      if (i > 0 && trước.type không phải Item/Action) y += dist.h          // +10
      if (e.reArrange) x = 0
      else {
          if (x + dist.w + size.w > areaW) x = 0                            // hết chỗ: xuống hàng
          else if (x != 0) y -= dist.h + size.h                             // cùng hàng với nút trước
      }
      e.rect = {left x, top y, right x + size.w, bottom y + size.h}
      nút: vị trí (x, y - pos), cỡ (size.w, size.h)                         // 35 x 35, tuyệt đối
      y += dist.h + size.h                                                  // +45
      x += dist.w + size.w                                                  // +45
      Action: if (i == số phần tử - 1) y -= dist.h                          // phần tử cuối: bỏ 10 thừa
      Item:   if (i == số phần tử) y -= dist.h                              // không bao giờ đúng (lỗi giữ từ 2008)
  Money (4), JiaoZi (7):
      x = 0
      th = e.font->lineSpacing * 1.4f            // hằng Fal 0x180137e60
      e.rect = {0, y, areaW, y + th}
      cửa sổ tiền: vị trí (0, y - pos), cỡ (areaW, th)
      y += th
  ChatBoard (6):
      x = 0
      h = cửa sổ->vtable[0x268](areaW)           // tự tính cao theo bề rộng
      cửa sổ: cỡ (areaW, h), vị trí (0, y - pos); y += h
  HyperLink (5): không xếp
d_totalHeight = y
configureScrollbars()
```

Mọi `setPosition`/`setSize` của cửa sổ con dùng `MetricsMode = Absolute (1)`, toạ độ trong
`ParentWindow`. Biến chạy `y` không làm tròn (có thể lẻ, ví dụ sau `lineSpacing * 1.4`), nhưng
`Window::setPosition(Absolute, v)` (Base 0x1800a6ec0, cộng 0,5 ở 0x1800a6f17 và 0x1800a6f49) và
`Window::setSize(Absolute, v)` (Base 0x1800a76d0, 0x1800a7764 và 0x1800a7793) làm tròn từng thành
phần bằng `trunc(v + 0.5)` [M]. Với phông bitmap: Option cao `trunc((S+2)*1.7 + 0.5)` (24 ở cỡ 12,
27 ở cỡ 14), ô tiền cao `trunc((S+2)*1.4 + 0.5)` (20 ở cỡ 12, 22 ở cỡ 14) trong khi `y` tăng đúng
19,6 hoặc 22,4.

Chữ: bề rộng bẻ dòng là `areaW = W - 22`; phông là tham số phông của phần tử, vắng thì
`getFont(true)` của cửa sổ phức hợp (Fal 0x180072cb0), tức phông của thuộc tính `Font` hoặc phông
mặc định; định dạng do lớp nối truyền là 4 (`WordWrapLeftAligned`). `getFormattedSize` (mục 5 C.3)
cho khối `n` dòng phông bitmap cao `n*(S+2) + 3*(n-1)`, nên **một phần tử chữ `n` dòng chiếm đúng
`n*(S+5)`** (17 mỗi dòng ở cỡ 12) và các phần tử chữ liền nhau giữ đều bước dòng. `#r` trong chuỗi
là `
`: mỗi đoạn bẻ riêng, đoạn rỗng cao `S + 2`, giữa hai đoạn thêm 3. Luật bẻ dòng (mục 5 C.6):
client 2026 (trang mã 936) bẻ theo từng ký tự khi `getTextExtent(dòng + ký tự) > areaW`.

### 3.4 Vẽ chữ: `ParentWindow::populateRenderCache` (Fal 0x180074c70) [M]

```
cols = ColourRect(complex.TextColor)             // +0x494, bốn góc cùng màu
với mỗi phần tử e có font và type == Text:
    r = e.rect; r.top -= complex.d_vertScrollbar->d_position     // chỉ dời mép trên, như 2008
    e.font->drawText(this, e.text, r, clip = null, e.typeset, cols, false, 1.0f, 1.0f, true)
```

Vị trí điểm ảnh (ghép với mục 5 C.4, C.6; phông bitmap cỡ `S`, `Y = e.rect.top - pos`, toạ độ
trong `ParentWindow`): `drawText` ngoài tính `t = trunc(Y - 1 + 0.5)`; dòng `k` của phần tử được vẽ
bằng một lời gọi `drawText` lồng với `top = t + k*(S+5)`, lại dời 1: `y_k = trunc(t + k*(S+5) - 1 +
0.5)`; hàng bitmap đầu của dòng ở `y_k + 1`, bút bắt đầu ở `x = 0` (ô glyph từ `x = -1`). Với `Y`
nguyên và `Y >= 2`: `y_k = Y - 2 + k*(S+5)`. Vì `trunc` cắt về 0, phần tử ở sát mép trên lệch quy
luật: `Y = 0` cho `t = trunc(-0.5) = 0`, `y_0 = trunc(-0.5) = 0`, `y_1 = S + 4`; `Y = 1` cho `t = 0`
tương tự. Phần tử chữ đầu tiên của bảng nhiệm vụ (`Y = 0` khi chưa cuộn) vì thế có dòng đầu ở `y =
0` và dòng hai chỉ cách 16 (cỡ 12) thay vì 17.

Chữ cắt theo ô của `ParentWindow` (cửa sổ con cắt theo cha như mọi cửa sổ CEGUI). Phần tử khác là
cửa sổ con thật (`TLBB_ActionButton`, `TLBB_Money`...) nằm trong `ParentWindow`, tự vẽ theo mục 2
và 4; nút action tạo ra được đặt `setClippedByParent(true)` (Fal 0x180070c60; constructor của nút
đặt `false`), nên bị `ParentWindow` cắt khi cuộn.

### 3.5 Thanh cuộn [M]

`configureScrollbars` (Fal 0x180073760): `area = d_ParentWindow->getAbsoluteRect()`;
`setVisible(d_totalHeight > area.height)`; `setDocumentSize(d_totalHeight)`;
`setPageSize(area.height)`; `setStepSize(max(1, area.height / 10))`; `setScrollPosition(pos hiện
tại)` (kẹp lại); rồi cập nhật vị trí nhớ:

```
pos = d_vertScrollbar->d_position
if (pos != 0) d_scrollPosOffset = pos
else if (d_vertScrollbar->changeToZero) { d_scrollPosOffset = 0; setChangeToZero(false) }
```

`handleScrollbarChange` (Fal 0x180074040): `performWindowLayout()` (đặt lại vị trí cửa sổ con theo
`pos` mới), vẽ lại cả hai cửa sổ. `ParentWindow::onMouseWheel` (Fal 0x180074280): thanh cuộn hiện và
`doc > page` thì `if (wheel * step >= pos) setChangeToZero(true)`; `setScrollPosition(pos - wheel *
step)`. Tức cờ `changeToZero` phân biệt "người chơi tự cuộn về 0" với "bị kẹp về 0 vì nội dung vừa
bị xoá". Cuộn theo điểm ảnh, mỗi nấc `max(1, (H-10) / 10)`.

### 3.6 Phương thức Lua của `MetaTable_Control_ComplexWindow` [M]

| Phương thức | Hàm | Hành vi |
|---|---|---|
| `AddTextElement(text [, fontName])` | UI 0x180022410 → Fal 0x180072bc0 | `text` phải là chuỗi; qua bộ phân tích thẻ (`colorTrans` của cửa sổ). `fontName` (chuỗi) → `FontManager::get(tên)`; vắng thì null → phông của cửa sổ. `AddChildElement_Text(text, font, typeset = 4 WordWrapLeftAligned)`: tạo phần tử tên `"text"`, đẩy vào cuối, `performWindowLayout()`. |
| `AddMoneyElement(n)` | UI 0x1800211b0 → Fal 0x1800720e0 | Tạo cửa sổ kiểu của khoá `Money` (`TLBB_Money`) làm con của `ParentWindow`, đặt số tiền `n`, hiện; phần tử loại 4; xếp lại. |
| `AddJiaoZiElement(n)` | UI 0x180020e50 → Fal 0x180071e40 | Như trên với khoá `JiaoZi` (`TLBB_JiaoZi`), phần tử loại 7. |
| `AddActionElement(actionID, num, radio [, reArrange])` | UI 0x18001cfe0 → Fal 0x1800707a0 | Ba tham số đầu phải là số. `num` đọc rồi bỏ (không dùng). `bRadio = (radio == 1)`, `bReArrange = (reArrange == 1)`, vắng thì false. Icon = `IconManager::GetIconFullName(ActionSystem->GetAction(actionID)->GetIconName())`. `AddChildElement_Action(icon, actionID, bRadio, bReArrange, font = null)`: tên con `__reward__%02d` (theo actionID) hoặc `__reward_radio_%02d_%02d`; tạo cửa sổ kiểu của khoá `ActionButton` (`TLBB_ActionButton`), `setLogicItemData(actionID)`, hiện, `Empty = False`, `NormalImage = icon` nếu khác rỗng, thêm vào `ParentWindow`, xếp lại. Lớp nối đăng ký MouseEnter/MouseLeave và `ParentHidden` cho nút (tooltip). Nút 35x35 → icon ở ô 1,1..34,34 (33x33). |
| `AddItemElement(...)` | UI 0x18001ffe0 → Fal 0x180071740 | Khoá `RewardItem` (`TLBB_RewardItem`), phần tử loại 2, đặt `NormalImage` và `Tooltip`. [?] tham số Lua chưa tháo; `QuestLog.lua` đã chú thích bỏ mọi lời gọi. |
| `AddOptionElement(...)` | UI 0x180021bf0 → Fal 0x180072380 | Tạo nút khoá `Option` (`TLBB_QuestButton`, tên `__option__%02d#%d,%d`) và cửa sổ ảnh khoá `Image` (`TLBB_StaticImageNULL`, tên `__optionImage__%02d#%d,%d`). [?] chi tiết chưa tháo; năm script không gọi. |
| `ClearAllElement()` | UI 0x1800231f0 → Fal 0x180072d70 | `_destroyAllElements()` (huỷ cửa sổ con và phần tử), `performWindowLayout()` (tổng cao 0 → thanh cuộn ẩn, vị trí kẹp về 0, `d_scrollPosOffset` GIỮ nguyên vì không phải người chơi cuộn), vẽ lại. |
| `SetScrollPosition()` | UI 0x18003a540 | Không tham số. Thanh cuộn tồn tại, đang hiện và `doc > page` thì `setScrollPosition(d_scrollPosOffset)`: khôi phục vị trí người chơi đã cuộn tới. |
| `ResetScrollPosition()` | UI 0x180032c10 | `d_scrollPosOffset = 0` (ô vtable +0x270 với 0.0). Không tự dời thanh cuộn. |
| `PageEnd()` | UI 0x180029290 → Fal 0x180072dc0 | `setScrollPosition(d_totalHeight - cao vùng)`, `configureScrollbars()`. |
| `SetTextColour`, `SetActionElementCheck`, `AddImpactElement`, `AddChatBoardElement`, `RemoveTopElement` | UI 0x18003b5a0, 0x180034700, 0x18001e660, 0x18001de70, 0x180032b80 | [?] chưa tháo; năm script không gọi. |

`QuestLog.lua` dòng 1463-1467: dựng lại nội dung xong, nếu vẫn là nhiệm vụ vừa xem thì
`SetScrollPosition()` (giữ chỗ đang đọc), khác nhiệm vụ thì `ResetScrollPosition()`.

---

## 4. Ô tiền `TLBB_Money`

### 4.0 Quy ước của các mục 4, 6, 7

Nguồn mã máy: `F:\tl 2026\Bin64\CEGUIBase.dll` (viết tắt **B**), `CEGUIFalagard.dll` (**F**),
`UI_CEGUI.dll` (**U**). Địa chỉ là địa chỉ ảo như `pe_refs.py` in. Bản tháo nháp nằm ở
`build/scratch/gui/sm_*.txt` (tên tệp ghi ở từng mục). Ký hiệu trạng thái:

- **[2026]** đã đọc trong mã máy 2026, kèm địa chỉ.
- **[2008]** chỉ theo mã nguồn 2008, chưa đối chiếu.
- **[?]** chưa xác định.

Quy ước dùng chung, đều **[2026]**:

- `Rect` của CEGUI xếp thành viên theo thứ tự `{top, bottom, left, right}` (thấy ở mọi hàm đọc
  `getUnclippedPixelRect`/`getPixelRect`: F 0x180046553..0x1800465a0, F 0x1800825e5..0x180082600);
  hàm dựng `Rect(left, top, right, bottom)` (B import `??0Rect@CEGUI@@QEAA@MMMM@Z`).
- `MouseEventArgs`: `+0x08 handled`, `+0x18 position (x, y)`, `+0x28 button` (0 = trái, 1 = phải),
  `+0x30 wheelChange` (B 0x180103545, 0x1801035db, 0x18010354e).
- `PixelAligned(v) = (float)(int)(v + 0.5)` cắt về 0 (B 0x18009d78c..0x18009d7dc).
- Vị trí cửa sổ con do look dựng: `WidgetComponent::layout` (B 0x180128c80) gọi
  `child->setRect(Absolute, area.getPixelRect(owner))`; `WidgetComponent::create` (B 0x180128a90)
  gọi `setVerticalAlignment` rồi `setHorizontalAlignment` theo `<VertAlignment>`/`<HorzAlignment>`.
  Nghĩa là ô con = ô điểm ảnh của `<Area>` rồi dời theo neo như `Window::windowToScreen` (đúng công
  thức `box_of`/`anchor_shift` của `SRC/gui/layout.cpp`). Sau lệnh `setRect` hàm này còn một đoạn
  duyệt danh sách (B 0x180128d57..0x180128e05) chưa đọc **[?]**.

Bản tháo: `sm_money_small.txt` (hàm nhỏ), `sm_money_render.txt` (`populateRenderCache`).

### 4.1 Kiểu → lớp → look

- `TLBB_Money` → `Falagard/Money` (`FalagardMoney` : `Window`) + look `TLBB_Look_Money`
  (`TLBBLook_StaticText.looknfeel.xml` dòng 259). Look KHÔNG có `ImagerySection`, `StateImagery`,
  `NamedArea`; chỉ ba thuộc tính: `GoldIcon = set:Button2 image:Icon_GoldCoin`,
  `SilverIcon = set:Button2 image:Icon_SilverCoin`, `CopperIcon = set:Button2 image:Icon_CopperCoin`
  (cả ba 16x16).
- `TLBB_JiaoZi` → cùng lớp `Falagard/Money` + look `TLBB_Look_JiaoZi` (dòng 809):
  `GoldIcon = set:Button6 image:Lace_JiaoziJin`, `SilverIcon = ...Lace_JiaoziYin`,
  `CopperIcon = ...Lace_JiaoziTong` (cả ba 16x16). Cùng bộ vẽ, chỉ khác ảnh.
- `ActionSkill_LearnDemand_Jiaozi` (layout ActionSkill dòng 171) là `TLBB_Money` nhưng tự đặt ba
  icon JiaoZi của `Button6` và `HorzFormatting=LeftAligned`.

Thuộc tính của lớp ở bản 2026 (tên chuỗi trong F): `MoneyNumber`, `HorzFormatting`, `GoldIcon`,
`SilverIcon`, `CopperIcon` (như 2008) và bốn cái mới `MoneyMaxNumber`, `MoneyMaxColour`,
`MoneyColor`, `AlignFix`. Hàm `set` của từng thuộc tính chưa tháo; nghĩa lấy từ hàm thành viên.

Thành viên **[2026]**: `d_MoneyNum +0x3f0` (F 0x180040460), `maxNumber +0x3f4` (F 0x180040450),
`maxColour +0x3f8` (F 0x180040420), `d_horzFormatting +0x410` (F 0x18003fe10), `alignFix +0x414`
(F 0x18003fb40), `goldIcon +0x418`, `silverIcon +0x420`, `copperIcon +0x428` (F 0x18003fdc0,
0x1800405a0, 0x18003fc50), `moneyColour +0x430` (F 0x1800403f0). Mặc định (constructor F
0x1800812b0): số 0, `maxNumber = −1`, `maxColour = FFFFFFFF`, canh trái (0), `alignFix = false`,
ba icon rỗng, `moneyColour = FFFFFFFF`.

### 4.2 Thuật toán vẽ — `FalagardMoney::populateRenderCache` (F 0x180082510) **[2026]**

```
copper = money % 100                    # 0x180082566..0x180082580
gold   = money / 10000                  # 0x180082583..0x180082598
silver = (money % 10000) / 100          # 0x18008259b..0x1800825bc
fmt2   = alignFix ? "%2d" : "%d"        # 0x1800825bf..0x1800825d4; chuỗi ở F 0x180139614, 0x180137748
W = rộng cửa sổ;  H = cao cửa sổ        # areaTotal = (0, 0, W, H)
font = getFont(); không có thì thôi
size(s) = font.getFormattedSize(s, areaTotal, d_horzFormatting, 1.0, 1.0)   # (rộng, cao) một dòng

# Lượt 1: đo tổng bề rộng (disp_w) — phần nào hiện thì cộng
disp_w = 0
if gold > 0:               sg = size("%d" % gold);    disp_w += sg.w + goldIcon.w   + GAP
if gold > 0 or silver > 0: ss = size(fmt2 % silver);  disp_w += ss.w + silverIcon.w + GAP
sc = size(fmt2 % copper);                             disp_w += sc.w + copperIcon.w + GAP
# GAP = 0.0 ở bản 2026: lệnh cộng thêm là "addss xmm1, xmm8" với xmm8 = 0 (0x180082781,
# 0x180082869, 0x180082949). Mã 2008 có GAP_TEXT_ICON = 2 nhưng chỉ cộng vào bề rộng đo, không
# chèn giữa các phần (FalMoney.cpp:76,102,115).

# Canh ngang
if d_horzFormatting == RightAligned (1):  x = W - disp_w - 4.0     # 0x180082968..0x180082986
else:                                     x = 0                    # LeftAligned và mọi giá trị khác
# Số 4.0 (F 0x1801319c0) chỉ có ở 2026; 2008 là W - disp_w (FalMoney.cpp:135).

# Màu chữ
text_col = moneyColour                                             # 0x180082993
if maxNumber >= 0 and maxNumber < money: text_col = maxColour      # 0x1800829a4..0x1800829c1
icon_col = trắng FFFFFFFF (không nhân alpha riêng)                 # ColourRect ở rbp+0x60

# Lượt 2: vẽ, từ trái sang phải
vẽ_phần(text, sz, icon):
    chữ   ở ô (x, H - sz.h) .. (x + sz.w, H), canh phải trong ô, cắt theo chính ô đó, màu text_col
    x += sz.w
    icon  ở ô (x, H - goldIcon.h) .. (x + icon.w, H), kéo giãn, màu icon_col
    x += icon.w
if gold > 0:               vẽ_phần("%d" % gold,   sg, goldIcon)    # 0x1800829c7..0x180082b24
if silver > 0 or gold > 0: vẽ_phần(fmt2 % silver, ss, silverIcon)  # 0x180082b3b..0x180082c99
vẽ_phần(fmt2 % copper, sc, copperIcon)                             # 0x180082cb0..0x180082df4
```

Các điểm đáng chú ý, đều **[2026]**:

- Mép trên của CẢ BA icon dùng chiều cao của icon VÀNG: `H − goldIcon.h` (F 0x180082a51,
  0x180082bb7..0x180082bc6, 0x180082d1e..0x180082d2d). Giống lỗi của mã 2008 (`FalMoney.cpp:161,176`).
  Với look gốc ba icon cùng cao 16 nên không lộ.
- Chữ và icon đều dán sát đáy cửa sổ; không canh giữa theo chiều dọc.
- Phần bằng 0: vàng ẩn khi `gold == 0`; bạc ẩn khi `gold == 0 và silver == 0`; đồng LUÔN hiện. Tổng
  bằng 0 thì hiện `0` kèm icon đồng.
- Thứ tự mỗi phần: số trước, icon sau; các phần liền nhau, không khoảng hở.
- `AlignFix=true`: bạc và đồng in `%2d` (đệm dấu cách cho đủ hai ký tự), vàng vẫn `%d`.
- Phông là phông của cửa sổ (`getFont(true)`, F 0x180082645); cửa sổ không đặt `Font` thì là phông
  mặc định. `size().h` là chiều cao `Font::getFormattedSize` trả cho một dòng (nhánh bộ máy chữ đặc
  tả; ở đây ghi `th`).
- `modifyFinalColor` (F 0x1800824e0) là cùng phép đổi màu khi vượt `MoneyMaxNumber`.
- `setMoneyNumber` (F 0x180082f20), `setMoneyMaxNumber` (F 0x180082f10),
  `setHorizontalFormatting` (F 0x180082e40): ghi rồi `requestRedraw`.

### 4.3 Ví dụ số

`ActionSkill_LearnDemand_Jiaozi` ở 1280x720 = `(240, 317, 131, 18)` (tính bằng
`build/scratch/gui/sm_rects.py ActionSkill 1280 720`, dùng bộ tính của `ui_rects.py`); `W = 131`,
`H = 18`, canh trái, icon `Button6/Lace_Jiaozi*` 16x16. Gọi `w(s)` là bề rộng chuỗi `s` theo phông
mặc định, `th` là chiều cao một dòng.

`MoneyNumber = 12345` → vàng 1, bạc 23, đồng 45 (toạ độ trong cửa sổ, cộng `(240, 317)` ra màn hình):

| Thứ | x | y | rộng | cao |
|---|---|---|---|---|
| chữ `1` | 0 | 18 − th | w("1") | th |
| icon vàng | w("1") | 2 | 16 | 16 |
| chữ `23` | w("1") + 16 | 18 − th | w("23") | th |
| icon bạc | w("1") + 16 + w("23") | 2 | 16 | 16 |
| chữ `45` | w("1") + 32 + w("23") | 18 − th | w("45") | th |
| icon đồng | w("1") + 32 + w("23") + w("45") | 2 | 16 | 16 |

`MoneyNumber = 0`: chỉ chữ `0` ở `(0, 18 − th, w("0"), th)` và icon đồng ở `(w("0"), 2, 16, 16)`.

Nếu cùng cửa sổ canh phải: mọi `x` cộng thêm `131 − disp_w − 4`.

### 4.4 Phương thức Lua

| Gọi trong script | Tác dụng |
|---|---|
| `ActionSkill_LearnDemand_Jiaozi:SetProperty("MoneyNumber", tostring(n))` (`ActionSkill.lua:336`) | `Window:SetProperty` (U 0x18003f570, nhánh chính đặc tả) đặt thuộc tính `MoneyNumber` → `d_MoneyNum = n`, vẽ lại |

Trong `ComplexWindow` (`AddMoneyElement`, `AddJiaoZiElement`) ô tiền là cửa sổ con kiểu `TLBB_Money`
/ `TLBB_JiaoZi` (`ChildItem key:Money`, `key:JiaoZi`): phần đặt ô và số thuộc nhánh chính.

### 4.5 `SRC/gui` hiện có

Chưa có gì: `Falagard/Money` rơi vào `kPlain`, look không có state nên không vẽ. Cần một `Kind`
mới ra hai loại đầu ra (chữ số, quad icon) theo 4.2; đo bề rộng chữ phải làm lúc dàn (hiện
`TextRun` chỉ mang ô và để bộ vẽ chữ đo sau).

---

## 5. Bộ máy chữ và các widget chữ (`TLBB_SimpleText`, `TLBB_SimpleMulitiTextFrame`, `TLBB_StaticText`)

Phạm vi: phông, thẻ `#`, đo và bẻ dòng, `TLBB_SimpleText`, `TLBB_SimpleMulitiTextFrame`,
`TLBB_StaticText`, `TextComponent` của look. Mọi địa chỉ là VA trong `F:\tl 2026\Bin64`.
Ký hiệu nguồn: **[26]** đã đối chiếu mã máy 2026 (kèm địa chỉ) — **[08]** chỉ theo mã 2008
(tệp:dòng dưới `G:\TLBB\_ref\client\Game\Client`) — **[?]** chưa xác định.
B = `CEGUIBase.dll`, F = `CEGUIFalagard.dll`, U = `UI_CEGUI.dll`, G = `Game.exe`.

Tóm tắt một dòng mỗi thứ:

- Phông mặc định: `SongTiBmp12`, dòng `CodePage="936"` (GBK12.bin, cỡ 12). Bản Bin64 này KHÔNG bao
  giờ nạp dòng 1258.
- Phông bitmap cỡ S: `getFontHeight` = `getLineSpacing` = `getBaseline` = S + 2. Bước dòng thật khi
  vẽ nhiều dòng = S + 2 + 3 = **S + 5** (17 với cỡ 12, 19 với cỡ 14). Khối n dòng cao
  n·(S+2) + (n−1)·3.
- Bẻ dòng: trang mã 936 bẻ **theo từng ký tự** (không theo từ); trang mã khác lùi tối đa 12 ký tự
  tìm một trong `' ' , . ? !` rồi bẻ trước ký tự đó.
- Phông bitmap bị dời lên 1 px so với ô chữ (2 px khi là kiểu WordWrap), canh giữa ngang cộng 1 px.

### A. Phông

#### A.1 Chọn phông và chọn dòng theo CodePage

- [26] `Window::getFont(useDefault)` B 0x1800a08e0: `d_font` (`[win+0x88]`) khác null thì dùng nó,
  không thì `System::getDefaultFont()` (`[System+0x40]`).
- [26] Phông mặc định là phông ĐẦU TIÊN được tạo: `FontManager::doPostObjectAdditionAction`
  B 0x180138870 gọi `System::setDefaultFont(Font*)` (B 0x18008bf20) khi bảng phông có đúng 1 phần
  tử. U không import `setDefaultFont`; hàm khởi tạo giao diện U 0x18006a1f0 chỉ nạp
  `Schema/WoWLookSkin.scheme.xml` (U 0x18006a8f8). Thẻ `<Font>` đầu tiên của scheme là
  `SongTiBmp12` → phông mặc định của mọi cửa sổ không có thuộc tính `Font`.
- [26] Mỗi tệp `.font` có hai thẻ `<Font>` cùng tên. `Font_xmlHandler::elementFontStart`
  B 0x180134f70 đọc `CodePage` (mặc định 936 khi thiếu, 0x180134f9d) và **bỏ qua thẻ** khi nó khác
  `System::d_codePage` (`[System+0x118]`, so ở 0x180134fb9).
- [26] `System::d_codePage` được đặt 936 trong hàm dựng (B 0x180088d48) và chỉ đổi qua
  `System::setCodePage` (B 0x180028c60). Không tệp nào trong `Bin64` import hay gọi hàm này
  (`grep -a setCodePage Bin64/*` chỉ ra CEGUIBase.dll; `pe_refs calls 0x180028c60` rỗng). Biến
  `System_CodePage` (G 0x1406950f0 đọc `./System.cfg`, mặc định 936) chỉ đi vào biến riêng của U
  (U 0x180059b10 ghi 0x1800b5a90, dùng cho đổi mbcs sang utf8), không đi vào CEGUI.
  **Hệ quả:** với bộ DLL này, dòng `CodePage="936"` luôn thắng: `SongTiBmp12` = `GBK12.bin` cỡ 12;
  dòng 1258 (`VTNAM14.bin` cỡ 14, `tahoma.ttf`) không bao giờ được tạo. Dự án đang vẽ bằng
  VTNAM14 cỡ 14 là lựa chọn của dự án; mọi công thức dưới đây viết theo cỡ S để dùng được cho cả hai.

#### A.2 Số đo của phông (bố cục đối tượng Font)

[26] `Font`: `+0xa0` ascender, `+0xa4` descender, `+0xa8` height, `+0xac` cỡ điểm (thuộc tính Size),
`+0xe0` bề rộng dấu cách dự phòng, `+0xe8` bảng glyph 65536 ô × 24 byte (`+0` ảnh, `+8` ảnh viền,
`+0x10` advance). Hàm ảo `vtable[1]` trả loại: BitmapFont 1 (B 0x18003b800), FreeTypeFont 0
(B 0x180052580).

| Hàm | Địa chỉ B | Trả |
|---|---|---|
| `getLineSpacing(s)` | 0x18003b770 | `[+0xa8]·s` |
| `getFontHeight(s)` | 0x18003b710 | `([+0xa0] − [+0xa4])·s` |
| `getBaseline(s)` | 0x18003b670 | `[+0xa0]·s` |
| `GetSpaceAdvance()` | 0x1800381a0 | `[+0xe0]` |

Hằng tĩnh [26]: `Font::LineSpace` = 3 (B 0x1801e7354), `Font::InterGlyphPadSpace` = 2
(B 0x1801e7358), `Font::DefaultColour` = 0xFFFFFFFF (B 0x1801e7350). Trong F các getter trên được
inline (F chỉ import `drawText`, `getFormattedSize`, `getTextExtent`, `getCharAtPixel`,
`getWrapedCharAtPoint`, `prepareChar`, `LineSpace`), nên trong mã F cứ thấy `[font+0xa0]`,
`[font+0xa4]`, `[font+0xa8]` là ba số đo này.

**BitmapFont** (AXFT) — `constructor_impl` B 0x18003c3a0 [26]:

- Size phải là 12, 14 hoặc 16 (0x18003c3ca..0x18003c401), khác thì ném lỗi.
- ascender = Size + InterGlyphPadSpace = **S + 2** (0x18003c430..0x18003c446); descender = 0
  (0x18003c44e); height = ascender − 0 = **S + 2** (0x18003c45b).
- Vậy `getFontHeight` = `getLineSpacing` = `getBaseline` = S + 2: 14 với `SongTiBmp12`/936,
  16 với dòng 1258.

**Glyph bitmap** — `BitmapFont::rasterise` B 0x18003ba60 [26]:

- Ô ảnh trong atlas là hình vuông cạnh C = S + 2 (0x18003baa1..0x18003baa9, 0x18003bc17..0x18003bc5b).
- Độ dời ảnh: `offsetX = −1`, `offsetY = −(C − 3) = −(S − 1)` (0x18003bc61..0x18003bc82).
- Điểm (cột c, hàng r) của bitmap S×S nằm ở ô (c+1, r+1); quanh mỗi điểm sáng ghi một vòng 3×3
  làm viền (cỡ 14: B 0x180133055..0x18013308e; cỡ 12: B 0x180132cd6..0x180132d0b). Điểm chữ ghi
  0xFFFF, vòng viền ghi 0x00FF (texture 16 bit hai kênh).
- **advance** = u16 đầu bản ghi glyph (B 0x180133440; mã không có bản ghi lấy cỡ phông S). Lúc
  rasterise: advance bằng 0 thì đọc lại (0x18003bda4..0x18003bdd1); **advance == S thì cộng 1**
  (0x18003bdda..0x18003be00). GBK12: chữ Hán và dấu câu toàn giác 12 → **13**; ASCII 6 giữ 6.
  VTNAM14: không glyph nào rộng 14 nên giữ nguyên; mã không có trong phông → 15 kèm ô vuông.
- Không có khoảng cách thêm giữa các ký tự: bút tiến đúng `advance · x_scale` (B 0x18004bde5).
  `InterGlyphPadSpace` chỉ là lề của ô atlas và số trừ khi tính đường cơ sở.
- Mọi mã < 0x10000 đều có ảnh sau rasterise, nên dấu cách của phông bitmap đi đường glyph thường
  (advance lấy từ tệp: 6 ở GBK12, 4 ở VTNAM14). Nhánh riêng cho mã 0x20 (dưới) chỉ chạy khi glyph
  không có ảnh.

**FreeTypeFont** — `updateFont` B 0x180052ef0, `rasterise` B 0x1800525a0 [26]:

- `FT_Set_Char_Size(face, Size·64, Size·64, dpiX, dpiY)` (0x1800530d7..0x180053116), DPI lấy từ
  renderer (`vtable+0x98`). Phông co giãn: `k = (size->metrics.y_scale >> 6) / 65536`
  (0x1800532a8..0x1800532be); ascender = `face->ascender·k`, descender = `face->descender·k`,
  height = `face->height·k` (0x1800532c2..0x1800532ff). Là số thực, không làm tròn.
- Glyph: `offsetX = horiBearingX >> 6` (0x180052926), `offsetY = −(horiBearingY >> 6)`
  (0x18005293f..0x180052953), advance = `horiAdvance >> 6` (0x180052a78..0x180052a85). Ảnh rộng
  `bitmap.width`, cao bằng số hàng bitmap lớn nhất đã gặp của phông (`[font+0xdc]`,
  0x180052631..0x18005263c, 0x180052905).
- [?] Giá trị số: tính theo công thức trên với DPI 96 (số của `TOOLS/content/ui_font.py`, tôi chưa
  tự kiểm lại trong CEGUIOgreRenderer.dll) và `han_main.ttf` (hhea 220/−36/gap 36, em 256):
  `YouYuan11.25` (Size 15) ascender 17,1875, descender −2,8125, fontHeight 20,0, height 22,8125;
  `YouYuan9.75`/`TLNA__` (14,1) 16,1536 / −2,6433 / 18,7969 / 21,4402; `YouYuan13` 14,8914 /
  −2,4368 / 17,3281 / 19,7649; `YouYuan18` 20,625 / −3,375 / 24,0 / 27,375; `VDA_M` (16) 18,3289 /
  −2,9993 / 21,3281 / 24,3274. Chưa đo trên client thật.

### B. Chuỗi từ Lua tới phông

#### B.1 Đường đi

[26] `LUA_CONTROL::Window::SetText` U 0x180040310:

- Tham số là số (lua_type == 3): `sprintf("%d")` rồi `setText`, không đọc thẻ (0x18004037b..).
- Cửa sổ là `Editbox`, `MultiLineEditBox`, `FalagardMultiIMEEditBox`: đổi mbcs sang utf8 rồi
  `setText` nguyên văn (0x1800404e7..0x1800406b7).
- Còn lại: `parse(src, out, window[+0x308], false)` = U 0x18004b170..0x1800541b8 (tương đương
  `CUIStringSystem::ParserString_RuntimeNew`, UIString.cpp:399 của 2008), rồi
  `window->setText(String32)` (`vtable+0x48`, B 0x1800a7890). Chuỗi nằm ở `[window+0xc0]`.

Kết quả là `String32` (utf32); mã điều khiển nằm ở byte cao (bit 24..31), 24 bit thấp là tham số.

#### B.2 Bảng thẻ 2026 (U 0x18004b170) và mã điều khiển (xử lý ở `drawTextLine` B 0x18004b250, bảng nhảy B 0x18004ced0 + 0x18004cf04)

| Thẻ | Mã sinh ra | Tác dụng lúc vẽ | So với 2008 / `SRC/ui/text.cpp` |
|---|---|---|---|
| `#R` | 0xFBFFC0CB | màu chữ FFC0CB (hồng) | 2008 và dự án: FF0000 — **sai màu** |
| `#G` | 0xFB00FF00 | 00FF00 | giống |
| `#B` | 0xFB00B4FF | 00B4FF | 2008 và dự án: 0000FF — **sai màu** |
| `#K` | 0xFB000000 | 000000 | giống |
| `#Y` | 0xFBFFFF00 | FFFF00 | giống |
| `#W` | 0xFBFFFFFF | FFFFFF | giống |
| `#P` | 0xFBFF99CC | FF99CC | mới; dự án bỏ dấu `#` và in chữ `P` |
| `#H` | 0xFB00FFFF | 00FFFF | mới; dự án bỏ thẻ, giữ màu cũ |
| `#I` | 0xFBFFFFCC | FFFFCC | mới; dự án in chữ `I` |
| `#L` | 0xFB6A3906 | 6A3906 | mới; dự án in chữ `L` |
| `#M` | 0xFB1F941E | 1F941E | mới; dự án in chữ `M` |
| `#N` | 0xFBE4007F | E4007F | mới; dự án in chữ `N` |
| `#cRRGGBB` | 0xFB000000 \| rgb | màu chữ; alpha lấy từ màu cửa sổ (B 0x18004ca4d) | giống |
| `#gXXXXXX` | 0xD0000000 \| v | **gradient dọc** 12 bit × 2: nibble 5,4,3 = R,G,B màu TRÊN, nibble 2,1,0 = R,G,B màu DƯỚI, mỗi nibble nhân 0x11 (B 0x18004cbc8..0x18004cc55) | dự án bỏ qua |
| `#l` | lặp lại mã màu TRƯỚC đó | quay về màu ngay trước lần đổi gần nhất (U 0x18004bc5c) | mới; dự án in chữ `l` |
| `#eRRGGBB` | 0xFC000000 \| rgb | màu viền; đồng thời xoá gradient (B 0x18004caab..0x18004cbc3) | giống về thẻ |
| `#b` | 0xE0000000 | nháy bật; cuối chuỗi tự thêm 0xE1000000 | dự án bỏ qua |
| `#iHH` | 0xE2000000 \| HH | alpha ép 0..FF cho màu chữ và viền (B 0x18004cd12); cuối chuỗi thêm 0xE2FF0000 để tắt | mới; dự án in chữ `i` |
| `#u` | 0xE6000000 / 0xE7000000 xen kẽ | gạch chân bật / tắt (U 0x18004bd83); cuối chuỗi tự tắt | dự án bỏ qua |
| `#n` | 0xE1000000 rồi 0xE7000000 | tắt nháy và gạch chân; **KHÔNG trả màu về mặc định** (U 0x18004bdd9) | 2008 không làm gì; dự án trả màu về gốc và xoá viền — **khác** |
| `#r` | `\n` | xuống dòng | giống |
| `##` | `#` | | giống |
| `#aB` / `#aE` | 0xFD000000 / 0xFE000000 | bắt đầu / hết liên kết; chữ trong `{...}` ngay sau `#aB` là khoá, không vẽ, không tính bề rộng | dự án bỏ 3 ký tự nhưng vẫn vẽ phần `{khoá}` |
| `#{ID}` | tra từ điển rồi đọc tiếp (đệ quy) | hơn 60 tiền tố `_XXX` riêng (`_ITEM`, `_TIME`, `_MONEY`, `_INFOMSG`, `_SKILL`...) | dự án chỉ biết 3 tiền tố |
| `#-NN` (đúng 2 chữ số, khác 01) | 0xE3000000 \| NN | hoạt ảnh id âm (U 0x180053cbe) | giống về độ dài |
| `#N`, `#NN`, `#NNN` | 0xFA000000 \| n | biểu cảm; đọc tham lam 1..3 chữ số liền nhau (U 0x180053d1a..0x180053d4e); hợp lệ khi n trong 1..100 hoặc 801..804 (0x180053dac..0x180053dbd); không hợp lệ thì chỉ bỏ dấu `#`, các chữ số thành chữ thường (0x180053dbf), không thử lại với ít chữ số hơn | 2008 và dự án: tối đa 2 chữ số, 0..99, luôn nuốt |
| `#vNNNN` | 0xFA000000 \| n | hoạt ảnh 4 chữ số nếu `AnimateManager::isAnimatePresent` (U 0x180053e55..0x180053e87); [?] số ký tự bị bỏ khi không hợp lệ chưa đọc | mới |
| `#+NNNN` (1000..9999) | 0xE9000000 \| n | hoạt ảnh (U 0x180053f2e..0x180053f6c) | mới |

Ghi chú [26]:

- Trạng thái màu là biến toàn cục của B: màu chữ 0x1802e9090, màu viền 0x1802e9050, gradient trên
  0x1802e9038 và dưới 0x1802e9020, nháy 0x1802e9010, gạch chân 0x1802e9012, liên kết 0x1802e9008.
  `drawText` với tham số bool cuối = true đặt lại: màu chữ = màu truyền vào, viền = 0, gradient = 0
  (B 0x18004acec..0x18004ad96). Các lời gọi lồng (từng dòng của chữ bẻ dòng) truyền false nên màu
  kéo dài qua dòng.
- Glyph vẽ bằng gradient khi hai màu gradient khác nhau, ngược lại vẽ bằng màu chữ
  (B 0x18004c395..0x18004c5c0). `#c` sau `#g` không tắt gradient; chỉ `#e` hoặc lần `drawText` kế
  mới tắt. Ví dụ `INTERFACE_XML_52` = `#gFF0FA0任务日志`: trên FFFF00, dưới FFAA00.
- Viền: màu viền có RGB khác 0 thì vẽ. Phông bitmap dùng vòng viền đã ghi sẵn trong ô glyph (một
  điểm ảnh, tám hướng) khi renderer hỗ trợ (cờ B 0x1802e9013, đặt ở 0x18004cb00..0x18004cb59),
  không thì vẽ ảnh viền riêng một lần (`drawExternBorder` B 0x18004a730). Dự án vẽ bốn bản lệch
  (bốn hướng): thiếu bốn góc chéo.
- [?] Mã 0xE8 (màu ở B 0x1802e90a8; bộ phân tích sinh 0xE80099E5 và 0xE800CCFF quanh các liên kết
  `_INFO...`), 0xE4, 0xE5 (U 0x18004d6a1, 0x18004d70d): chưa đọc công dụng; `drawTextLine` không có
  nhánh cho 0xE4, 0xE5.
- [?] Chuỗi `Text` viết trong layout XML đi qua bộ phân tích ở đâu (2008 làm ở lớp quản lý cửa sổ
  sau khi nạp layout): chưa tháo ở bản 2026. Thuộc tính `TextOriginal` (B 0x1802eb090) có vẻ giữ
  bản thô.

### C. Đo và dàn chữ

Rect của bản này xếp `top@0, bottom@4, left@8, right@0xc`. `trunc(x)` dưới đây là phép đổi
float sang int tự viết của DLL: cắt về 0. `PixelAligned(x) = trunc(x + 0,5)`.

#### C.1 `getTextExtent(text, xs)` — B 0x18004f530 [26]

```
w = 0
với mỗi mã c:
  nếu c < 0x10000, c khác \r \n, glyph có ảnh (chưa có thì rasterise):
      trong liên kết: '{' bật bỏ qua, '}' tắt, ký tự giữa hai dấu bỏ qua
      w += glyph.advance * xs                         (0x18004f848)
  ngược lại nếu c == 0x20:  w += (ascender − descender) * xs * 0,5      (0x18004f85a)
  ngược lại theo byte cao: 0xE3/0xE9/0xFA: w += bề rộng hoạt ảnh * xs; 0xFD/0xFE: bật/tắt liên kết
trả max(0, w)
```

Mã màu, `\r`, `\n` rộng 0.

#### C.2 `getLineSize(text, xs, ys)` — B 0x18004f050 [26]

`height = max(fontHeight, cao ảnh glyph·ys, cao hoạt ảnh)`; với phông bitmap = S + 2.
`width = max(adv, max_i(adv_trước_i + (offsetX_i + rộng ảnh_i)·xs))` (0x18004f32f..0x18004f355).
Với phông bitmap glyph cuối đóng góp `−1 + (S+2)`, nên bề rộng của `getLineSize` LỚN hơn
`getTextExtent` khi ký tự cuối hẹp: "12/20" ở GBK12 ra 24 + 13 = 37 trong khi extent là 30. Ai dùng
bề rộng này (tooltip tự co, `ListboxTextItem::getPixelSize`) sẽ thấy số đó.

#### C.3 `getFormattedSize(text, area, fmt, xs, ys, float* dòngĐầu)` — B 0x18004e7f0 [26]

```
rỗng → (0, 0)
tách theo '\n'; với đoạn thứ k:
  k > 0: H += 3                                         (LineSpace, 0x18004ea98)
  đoạn rỗng: H += fontHeight                            (0x18004eae2..0x18004eaf9)
  fmt 0..3: sz = getLineSize(đoạn)
  fmt 4..7: sz = getWrappedSize(đoạn, area); area.top += sz.h
  H += sz.h; W = max(W, sz.w)
```

`getWrappedSize` B 0x18004fd90: cùng luật bẻ với C.6; mỗi lần bẻ `H += cao dòng + 3`, dòng cuối
`H += cao dòng`; `W = bề rộng ô` nếu đã bẻ. **Khối n dòng phông bitmap cao n·(S+2) + (n−1)·3**:
cỡ 12 → 14, 31, 48, 65…; cỡ 14 → 16, 35, 54…

#### C.4 `drawText(win, text, area, clip, fmt, colours, bool a, xs, ys, bool reset)` — B 0x18004aa60 [26]

```
d = (font là BitmapFont) ? 1 : 0                        (0x18004aacb..0x18004aad9)
t.top = trunc(area.top − d + 0,5);  t.bottom = trunc(area.bottom − d + 0,5)
t.left = trunc(area.left + 0,5);    t.right  = trunc(area.right + 0,5)     (0x18004aadc..0x18004ac59)
reset: đặt lại trạng thái màu (B.2)
y = t.top; tổng = 0; số dòng = 0
tách text theo '\n' (0x18004ae17); với mỗi đoạn, theo fmt (bảng nhảy 0x18004b228):
  0 LeftAligned : drawTextLine(đoạn, (t.left, y));                         y += r.h
  1 RightAligned: drawTextLine(đoạn, (t.right − extent, y));               y += r.h
  2 Centred     : x = trunc(t.left + (t.right − t.left − extent)·0,5 + 0,5) + 1    (0x18004af5a..0x18004afdb)
                  drawTextLine(đoạn, (x, y));                              y += r.h
  3 Justified   : ném "Unknown or unsupported TextFormatting"
  4..7 WordWrap*: r = drawWrappedText(đoạn, t, kiểu trong = fmt − 4);      t.top += r.h
  tổng += r.h; số dòng += r.dòng
trả (max(số dòng, 1), max(tổng, fontHeight))            (0x18004b189..0x18004b1e2)
```

Khác 2008 (CEGUIFontBase.cpp:809): thêm bước dời `d` cho phông bitmap, kiểu Justified ném lỗi, kết
quả chiều cao kẹp dưới bởi fontHeight. Giữ nguyên: Centred cộng 1 px (2008 dòng 855), Right không
làm tròn thêm.

#### C.5 `drawTextLine(win, text, pos, clip, colours, bool a, xs, ys)` — B 0x18004b250 [26]

```
cao = fontHeight; quét trước: cao = max(cao, cao ảnh glyph·ys, cao hoạt ảnh)   (0x18004b3cd..0x18004b4d7)
base_y = pos.y + cao − 2 − 1                              (0x18004b4eb..0x18004b505)
với mỗi mã:
  glyph có ảnh: y = base_y − (offY − offY·ys); ô đích (pen.x, y, pen.x + rộng·xs, y + cao ảnh·ys);
                Image::draw cộng (offsetX, offsetY) của ảnh (B 0x180056c40 → 0x180061430);
                pen.x += advance·xs                       (0x18004bde5)
  mã 0x20 không có ảnh: bitmap pen.x += xs·Size·0,5; FreeType pen.x += [font+0xe0]·xs   (0x18004c777..0x18004c7e7)
  mã điều khiển: bảng B.2; hoạt ảnh vẽ ở y = base_y − cao hoạt ảnh + 3 (0x18004c864)
trả (1, cao + 3)                                           (0x18004ce5c..0x18004ce69)
```

Với phông bitmap cỡ S ở tỉ lệ 1: cao = S + 2, ô glyph có mép trên = `pos.y` và mép trái =
`pen.x − 1`; **điểm (c, r) của bitmap S×S rơi vào màn hình (pen.x + c, pos.y + 1 + r)**. Mỗi dòng
chiếm S + 5 px. Đây là phần `ui_font.py` còn ghi "suy đoán"; nay đã khớp mã máy 2026.

Với FreeType: đường cơ sở ở `pos.y + cao − 3`, glyph đặt tại (pen.x + bearingX, đường cơ sở −
bearingY); không có bước dời `d`.

#### C.6 `drawWrappedText(win, text, area, clip, fmt, colours, bool a, xs, ys)` — B 0x18004cf40 [26]

```
rộng = area.right − area.left; dòng = ""; dest = area
với c = 0..n−1:
  nếu getTextExtent(dòng + text[c]) > rộng:               (so nghiêm ngặt, 0x18004d209)
      nếu System.codePage != 936 và text[c] không thuộc D:          (0x18004d218..0x18004d252)
          lùi k = 0..min(len(dòng), 12)−1 từ cuối dòng; gặp dòng[len−1−k] thuộc D:
              dòng = dòng[0 .. len−k−1)   (bỏ cả ký tự phân cách);  c −= k + 1   (0x18004d2e4..0x18004d327)
      r = drawText(dòng, dest, fmt trong, reset = false)
      nếu len(dòng) > 1: c −= 1          (ký tự làm tràn, hoặc ký tự phân cách, mở đầu dòng sau)
      dòng = ""; dest.top += r.h; dest.bottom += r.h
  ngược lại: dòng += text[c]
vẽ phần còn lại với fmt trong (Justified đổi thành Left)
```

D = `{0x20 ' ', 0x2C ',', 0x2E '.', 0x3F '?', 0x21 '!'}` (B 0x1801e7368, 5 mục); trần lùi 12
(B 0x1801e737c). `getWrappedSize` dùng cùng luật (trần 13 tính cả ký tự làm tràn, B 0x180050070).

- Trang mã 936 (bản Bin64 này): **bẻ theo ký tự**, kể cả giữa một từ Latin. Y hệt 2008
  (CEGUIFontBase.cpp:908).
- Trang mã khác: bẻ trước ký tự phân cách gần nhất trong 12 ký tự cuối; ký tự phân cách KHÔNG bị
  nuốt mà mở đầu dòng sau (dòng sau bắt đầu bằng dấu cách). Từ dài hơn 12 ký tự bị bẻ giữa từ.
- Mã màu là phần tử của chuỗi, rộng 0, đi theo dòng chứa nó.
- **Dời đúp:** `drawText` đã dời `t` lên `d`, rồi mỗi dòng lại gọi `drawText` và dời thêm `d`. Chữ
  bẻ dòng của phông bitmap nằm cao hơn chữ một dòng 1 px: dòng k vẽ ở `y = top − 2 + k·(S+5)` (top là
  mép trên nguyên của ô chữ), bitmap bắt đầu ở `y + 1`.

### D. Widget

#### D.1 `TLBB_SimpleText` và `TLBB_SimpleMulitiTextFrame` — lớp `FalagardSimpleText` (Falagard/SimpleText)

Scheme: `TLBB_SimpleText` → look `TLBB_Look_SimpleText`; `TLBB_SimpleMulitiTextFrame` → look
`TLBB_Look_MuliteTextFrame` (`TLBBLook_StaticText.looknfeel.xml` dòng 9 và 83). Cùng một lớp, khác
look: bản "Muliti" chỉ thêm khung và lề, **không có thanh cuộn, không tự bẻ dòng** (bẻ dòng chỉ khi
layout đặt `HorzFormatting` là `WordWrap*`).

Look `TLBB_Look_MuliteTextFrame`: `NamedArea "TextArea"` = trái 7, trên 3, phải W − 7, dưới H − 3;
`StateImagery "Enabled"` = `TLBB_Look_Common/Background_Common1` rồi `TLBB_Look_Common/Frame_Type_Lace3`;
không có state `Disabled`. Look `TLBB_Look_SimpleText`: hai state rỗng, không có `TextArea`.

Mặc định [26] (hàm dựng F 0x18004d5f0): `d_horzFormatting` (`+0x3f0`) = 0 LeftAligned,
`d_vertFormatting` (`+0x3f4`) = 2 VertCentred, tỉ lệ (`+0x3f8`, `+0x3fc`) = 1, `d_TextColour`
(`+0x400`) = trắng. Enum dọc của lớp này: 0 TopAligned, 1 BottomAligned, 2 VertCentred. Tên giá trị
thuộc tính [08] (FalSimpleTextProperties.cpp:53..131; các chuỗi có trong F): `LeftAligned`,
`RightAligned`, `HorzCentred`, `HorzJustified`, `WordWrapLeftAligned`, `WordWrapRightAligned`,
`WordWrapCentred`, `WordWrapJustified`; `TopAligned`, `BottomAligned`, `VertCentred`; `TextColor` là
AARRGGBB.

`getTextRenderArea` F 0x18004e130 [26]: look có `NamedArea "TextArea"` thì lấy nó, không thì
`Rect(0, 0, W, H)`. **Khác 2008** (FalSimpleText.h:115 luôn trả cả cửa sổ).

`populateRenderCache` F 0x18004e300 [26]:

```
nếu isDisabled và look có state "Disabled": vẽ "Disabled"
ngược lại nếu look có state "Enabled": vẽ "Enabled"       (2008 không vẽ state nào)
nếu không có phông hoặc chữ rỗng: xong
area = getTextRenderArea(); clip = area                   (cắt theo ô chữ CHƯA dời)
h = font.getFormattedSize(text, area, horz, sx, sy).height
dọc: 0 Top    : area.top += 1                              (0x18004e5d9)
     1 Bottom : area.top = area.bottom − h                 (0x18004e5cd)
     2 Centre : area.top += trunc((area.bottom − area.top − h)·0,5 + 0,5)   (0x18004e552..0x18004e5c5)
font.drawText(this, text, area, &clip, horz, ColourRect(TextColor), a, sx, sy, reset = true)
```

Toạ độ là cục bộ của cửa sổ (gốc ở góc trái trên cửa sổ).

#### D.2 `TLBB_StaticText` — lớp `FalagardStaticText` (Falagard/StaticText), look `TLBB_Look_StaticText` (dòng 515)

Look: `BackgroundEnabled` và `FrameEnabled` = True; `TextRenderArea` = (4, 4, W−4, H−4);
`TextRenderAreaHScroll` giống hệt; `TextRenderAreaVScroll` = (4, 4, **W−16**, H−4); con
`__auto_vscrollbar__` kiểu `TLBB_Scrollbar_Common`: canh phải, trên 1, rộng 16, cao H; không có
thanh ngang. State `EnabledFrame` = `TLBB_Look_Common/Frame_Type2`, `EnabledBackground` =
`TLBB_Look_Common/Background_Frame_Type2`, `Enabled`/`Disabled` rỗng, `Disabled*` rỗng.

[26] `FalagardStaticText::populateRenderCache` F 0x180048390: `d_frameEnabled` thì vẽ
`EnabledFrame`/`DisabledFrame`, `d_backgroundEnabled` thì `EnabledBackground`/`DisabledBackground`,
rồi `Enabled`/`Disabled`, rồi `StaticText::populateRenderCache`. `getTextRenderArea` F 0x1800481b0:
thanh nào đang hiện thì ghép tên `TextRenderArea` + `H` + `V` + `Scroll`, có trong look thì dùng,
không thì `TextRenderArea`. Giống 2008 (FalStaticText.cpp).

[26] `StaticText::populateRenderCache` B 0x180111480 (giống CEGUIStaticText.cpp:131 của 2008):

```
area = getTextRenderArea(); clip = area
h = getFormattedSize(text, area, horz).height
có thanh ngang đang hiện: dời area theo scrollPosition (trái/giữa trừ, phải cộng)
nếu có thanh dọc (`[this+0x608]`), theo d_vertFormatting (`+0x5a4`; 0 Top, 1 Bottom, 2 Centre):
  Top   : area.top −= vscroll.pos
  Bottom: area.top = area.bottom − h + vscroll.pos
  Centre: thanh dọc đang hiện ? area.top −= vscroll.pos
                               : area.top += trunc((cao area − h)·0,5 + 0,5)
drawText(text, area, &clip, horz, màu chữ nhân alpha hiệu dụng, …, reset = true)
```

Thanh cuộn — `configureScrollbars` B 0x1801109a0 [26] (giống 2008 dòng 297): thanh dọc hiện khi
`h > cao area` **và** thuộc tính `VertScrollbar` = true (`[this+0x618]`; thanh ngang: `[+0x619]`,
`HorzScrollbar`). Rồi `documentSize = h`, `pageSize = cao area`, `stepSize = max(1, cao area / 10)`
(hằng 10 ở 0x180110c0d). Bánh xe (`onMouseWheel` B 0x180111390): `pos −= stepSize · wheelChange`.
Mặc định [08] (CEGUIStaticText.cpp hàm dựng): LeftAligned, VertCentred, hai thanh tắt. Cuộn theo
điểm ảnh, không theo dòng. Khi thanh dọc hiện, ô chữ hẹp lại (W−16) nên chữ WordWrap bẻ lại theo
bề rộng mới.

Trong ba layout sách võ công, `TLBB_StaticText` luôn đi với `WordWrapLeftAligned`, `TopAligned`,
`VertScrollbar=true` (`ActionSkill_Explain`, `CommonSkill_Target_Skill_Explain`,
`LifeSkill_Target_Skill_Explain`).

#### D.3 `TextComponent` của look (nhãn nút, chữ trong ImagerySection) — B 0x1801281e0 [26]

Phông: tên ghi trong component, rỗng thì `window.getFont(true)`. Chữ: của component, rỗng thì chữ
cửa sổ. `h = getFormattedSize(text, dest, horz).height`. Dọc: 0 trên (không đổi), 1 giữa
`dest.top += (cao dest − h)·0,5` (KHÔNG làm tròn ở đây; `drawText` làm tròn), 2 dưới
`dest.top = dest.bottom − h`. Rồi `drawText(…, reset = true)`. Ngang dùng thẳng số TextFormatting
(0 trái, 1 phải, 2 giữa, 4..7 bẻ dòng).

### E. Ví dụ số (1280×720, toạ độ cục bộ của cửa sổ; cộng góc trái trên của cửa sổ để ra màn hình)

Ô cửa sổ lấy ở `tests/golden/ui_rects.tsv`. Advance đọc từ tệp AXFT bằng
`TOOLS/port/text_wrap_sim.py` (mô phỏng đúng C.1 và C.6).

**E.1 `QuestLog_Amount`** — `TLBB_SimpleMulitiTextFrame`, cửa sổ (683, 143,66, 60×24), HorzCentred,
VertCentred, chữ "12/20".

| Bước | Phông 936: GBK12, S = 12 | Phông 1258: VTNAM14, S = 14 |
|---|---|---|
| TextArea (trái, trên, phải, dưới) | 7, 3, 53, 21 | như bên |
| extent ("1" "2" "/" "2" "0") | 6·5 = 30 | 7+7+5+7+7 = 33 |
| h = S + 2 | 14 | 16 |
| top = 3 + trunc((18 − h)·0,5 + 0,5) | 3 + 2 = 5 | 3 + 1 = 4 |
| `drawText`: t.top = top − 1 | 4 | 3 |
| x = trunc(7 + (46 − extent)·0,5 + 0,5) + 1 | trunc(15,5) + 1 = 16 | trunc(14,0) + 1 = 15 |
| ô glyph đầu (trái, trên, cạnh) | 15, 4, 14 | 14, 3, 16 |
| bitmap chữ: cột, hàng | x 16..45, y 5..16 | x 15..47, y 4..17 |
| ô cắt | 7..53 × 3..21 | như bên |

**E.2 `ActionSkill_EffectNotice`** — `TLBB_SimpleMulitiTextFrame`, cửa sổ (12, 382, 362×53),
`WordWrapLeftAligned`, dọc mặc định VertCentred, chữ `#{BSZJPF_130311_10}` =
`#cfff263当前宝石修炼等级效果：最多增加第八本心法控制技能效果#G%s0#cfff263秒，受到第八本心法控制技能效果最多减少#G%s1#cfff263秒。`
(nguyên văn trong `StrDictionary`, chưa thay `%s0`, `%s1`).

- TextArea = (7, 3, 355, 50): rộng 348, cao 47.
- GBK12, trang mã 936: extent cả chuỗi 647. Dòng 0 = 26 chữ toàn giác × 13 + `%` 6 = 344 (thêm `s`
  thành 350 > 348 nên bẻ trước `s`): `当前…技能效果%`; dòng 1 = `s0秒，受到…减少%s1秒。` rộng 303.
  **2 dòng.**
- h = 2·14 + 3 = 31; top = 3 + trunc((47 − 31)·0,5 + 0,5) = 3 + 8 = 11.
- Dời đúp: dòng k vẽ ở y = 11 − 2 + 17k → **y0 = 9, y1 = 26**; bitmap hàng 10..21 và 27..38; bút
  bắt đầu x = 7 (ô glyph từ x = 6).
- Màu: `#cfff263` vàng FFF263 tới `#G`, `%s0` xanh 00FF00, rồi vàng lại; màu giữ qua chỗ bẻ dòng.
- Bảng tra nhanh số dòng n → (h, top, y dòng đầu) cho ô cao 47, cỡ 12: 1 → (14, 20, 18);
  2 → (31, 11, 9); 3 → (48, 3 + trunc(0) = 3, 1); 4 → (65, 3 + trunc(−8,5) = −5, −7) — tràn lên trên
  và bị ô cắt 3..50 xén.
- Cùng ô với VTNAM14, trang mã khác 936, chuỗi Việt thử "Hiệu quả cấp tu luyện bảo thạch hiện tại:
  tăng tối đa hiệu quả khống chế của tâm pháp thứ tám 3 giây, giảm tối đa 2 giây." (extent 676):
  bẻ trước dấu cách sau "hiệu quả" → dòng 0 rộng 342, dòng 1 bắt đầu bằng dấu cách, rộng 334;
  h = 2·16 + 3 = 35; top = 3 + trunc(6,5) = 9; y0 = 7, y1 = 7 + 19 = 26.

### F. Chỗ dự án đang thiếu hoặc lệch (so với mã máy 2026)

`SRC/ui/text.cpp` (TextWriter):

1. Bước dòng: đang dùng `S + 2` cho cả bước lẫn khối (`line_height`, `write`). 2026: bước S + 5,
   khối n·(S+2) + 3·(n−1) (C.3, C.5).
2. Canh dọc: `block_top` rồi `kGlyphDrop = 1` cho bitmap hàng 0 ở `top + 1`. 2026: hàng 0 ở đúng
   `top` đã canh (canh giữa, canh dưới: dự án thấp hơn 1 px); kiểu WordWrap ở `top − 1` (thấp hơn
   2 px). Riêng TopAligned của SimpleText thì trùng (2026 cộng 1 rồi trừ 1 rồi cộng 1).
3. Canh giữa ngang thiếu `+ 1` (C.4).
4. Advance: thiếu luật "advance == S thì + 1" (chữ Hán 13 chứ không phải 12) và mã không có trong
   phông (rộng S + 1, vẽ ô vuông; dự án bỏ qua không vẽ).
5. Bẻ dòng: dự án bẻ ở dấu cách không giới hạn độ lùi và nuốt dấu cách. 2026: 936 bẻ theo ký tự;
   trang khác lùi tối đa 12, năm ký tự phân cách, không nuốt (C.6). Bề rộng giới hạn phải là bề
   rộng ô chữ (TextArea), không phải cả cửa sổ.
6. Thẻ: sai màu `#R`, `#B`; thiếu `#P #H #I #L #M #N #l #i #g #u #b #v #+`, chữ số thứ ba của biểu
   cảm; `#n` không được trả màu về mặc định; `{khoá}` sau `#aB` không được vẽ (bảng B.2).
7. Viền: bốn hướng thay vì vòng tám hướng.

`SRC/gui/text.cpp`:

8. `simple_text()` lấy cả ô cửa sổ làm ô chữ và ô cắt. 2026 dùng `NamedArea "TextArea"` khi look có
   (`TLBB_Look_MuliteTextFrame`: 7, 3, −7, −3) và cắt theo đúng ô đó.
9. `Falagard/StaticText` hiện là `Kind::kPlain`: khung và nền có vẽ, nhưng CHỮ của cửa sổ không ra
   (look không có TextComponent) và không có thanh cuộn. Cần bộ vẽ riêng theo D.2.
10. Canh dọc của `TextComponent` (nhãn nút) ở 2026 không làm tròn trước khi vào `drawText` (D.3):
    khi (cao − h) lẻ, kết quả là trunc(top + 0,5·lẻ − d + 0,5), khác với làm tròn rồi mới trừ.

### G. Chưa xác định, cần đọc tiếp

- Vị trí màn hình của cửa sổ có phần lẻ (QuestLog y = 60,9; `QuestLog_Amount` y = 143,66): bộ đệm
  hình học của cửa sổ (`Window::getGeometryBuffer` B 0x1800a0910) cộng toạ độ cửa sổ thế nào, có
  làm tròn không — chưa đọc; mọi số ở E là cục bộ.
- Tham số `bool a` của `drawText` (SimpleText truyền `!byte[win+0x16f]`, TextComponent truyền
  false) đi xuống `Image::draw`: chưa biết nghĩa.
- DPI mà renderer trả cho FreeType và số đo FreeType thật (A.2): chưa kiểm trong
  CEGUIOgreRenderer.dll, chưa đo trên client.
- Mã 0xE8, 0xE4, 0xE5; nháy (0xE0) dùng `FontManager::getBlinkAlphaValue` (`[FontManager+0x84]`).
- Gạch chân: vẽ ảnh `[font+0xd0]` kéo theo advance của glyph (B 0x18004bfc7..0x18004c0c5, cờ
  0x1802e9012); chưa đọc toạ độ dọc chi tiết.
- Hàm `set` của các thuộc tính `HorzFormatting`, `VertFormatting`, `TextColor` bản 2026 (chỉ theo
  mã 2008 và chuỗi có trong F).
- Ngoài phạm vi, ghi cho phiên chính: `ListboxTextItem::draw` B 0x1800d8e00 dời ô chữ
  `top += trunc(LineSpace·0,5 + 0,5) = 2` và `left += [item+0xe0]` trước khi gọi `drawText`;
  `ListboxTextItem::getPixelSize` B 0x1800d9080 cộng `LineSpace` (3) vào chiều cao (0x1800d9249):
  một item một dòng phông cỡ 12 cao 14 + 3 = 17. Phiên chính tự kiểm lại.

### H. Tệp nháp và lệnh tái hiện

Bản tháo ở `build/scratch/gui/txt_*.txt` (tên theo hàm: `txt_drawText`, `txt_drawTextLine`,
`txt_drawWrapped`, `txt_getTextExtent`, `txt_getLineSize`, `txt_getFormattedSize`,
`txt_getWrappedSize`, `txt_bmpfont_load`, `txt_bmp_rasterise`, `txt_axft_blit12/14`,
`txt_ft_update`, `txt_ft_rasterise`, `txt_fontxml_start`, `txt_system_ctor`, `txt_simple_area`,
`txt_simple_populate`, `txt_static_populate2`, `txt_static_scrollcfg`, `txt_falstatic_*`,
`txt_textcomp_render`, `txt_ui_settext`, `txt_ui_parser`, `txt_ui_init`, `txt_extern_border`).
Script nháp: `txt_wrap_sim.py` (đo và bẻ dòng theo C.1, C.6), `txt_short_strings.py` (đọc khoá thẻ
một ký tự của bộ phân tích), `txt_scan_disp.py` (tìm lệnh ghi vào một độ dời).

```
python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/CEGUIBase.dll" func 0x18004aa60          # drawText
python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/CEGUIBase.dll" func 0x18004b250..0x18004cf40   # drawTextLine
python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/CEGUIBase.dll" jump 4b228:8               # switch TextFormatting
python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/CEGUIBase.dll" jump 4ced0:13:4cf04:47:208 # mã điều khiển 0xD0..0xFE
python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/UI_CEGUI.dll" func 0x18004b170             # bộ phân tích thẻ
PYTHONUTF8=1 python -B TOOLS/port/text_wrap_sim.py CLIENT/data/Interface/Schema/GBK12.bin 348 936 "<chuỗi đã bỏ thẻ>"
```

---

## 6. Thanh cuộn dọc

Bản tháo: `sm_scrollbar_base.txt` (B, lớp `Scrollbar`), `sm_scrollbar_fal.txt` (F,
`FalagardScrollbar`), `sm_thumb_base.txt` (B, `Thumb`), `sm_thumb_fal.txt` (F, `FalagardThumb`),
`sm_btn_anim.txt`, `sm_button.txt` (F, `FalagardButton`), `sm_vt_falscrollbar.txt`,
`sm_vt_falthumb.txt`, `sm_vt_scrollbar_base.txt` (vtable).

### 6.1 Kiểu → lớp → look (`WoWLookSkin.scheme.xml`)

| Kiểu TLBB | TargetType (lớp) | Look | Dùng ở |
|---|---|---|---|
| `TLBB_Scrollbar_Common` (dòng 674) | `Falagard/Scrollbar` (`FalagardScrollbar` : `Scrollbar`) | `TLBB_Look_Scrollbar_Common` | con `__auto_vscrollbar__` của `TLBB_Look_ListBoxCommon` (rộng 16) và `TLBB_Look_ComplexWindow` (rộng 16) |
| `TLBB_Scrollbar_Track` (684) | `Falagard/Scrollbar` | `TLBB_Look_Scrollbar_Track` | con `__auto_vscrollbar__` của `TLBB_Look_ListBoxTransparent` (rộng 11) |
| `TLBB_ScrollbarThumb_Common` (679) | `Falagard/Thumb` (`FalagardThumb` : `Thumb` : `PushButton`) | `TLBB_Look_ScrollbarThumb_Common` | thumb của `Scrollbar_Common` |
| `TLBB_MissonTrackThumb_Common` (688) | `Falagard/Thumb` | `TLBB_Look_MissonTrackThumb_Common` | thumb của `Scrollbar_Track` |
| `TLBB_ScrollbarThumb_Track` (685) | `Falagard/Thumb` | `TLBB_Look_ScrollbarThumb_Track` | không look nào trong `TLBBLook_ScrollBar.looknfeel.xml` dùng kiểu này, và tệp đó cũng không có `WidgetLook` tên `TLBB_Look_ScrollbarThumb_Track` |
| `TLBB_ButtonNULL` (52) | `Falagard/Button` (`FalagardButton`) | `TLBB_Look_ButtonNULL` | nút lên, nút xuống của cả hai thanh |

### 6.2 Look `TLBB_Look_Scrollbar_Common` (`TLBBLook_ScrollBar.looknfeel.xml` dòng 1323)

Cỡ ảnh lấy ở `all.imageset.xml`: `Button1/ScrollBar_Up_Normal|Hover|Pushed` 15x15,
`Button1/ScrollBar_Down_Normal|Hover|Pushed` 15x15, `Button1/ScrollBar_Bar` 16x30,
`Button4/ScrollBar_Thumb_Normal|Hover|Pushed|Disabled` 15x18. Gọi cỡ thanh cuộn là `W x H`.

- `Property VerticalScrollbar = True`.
- `NamedArea ThumbTrackArea`: Left 0; Top = cao `ScrollBar_Up_Normal` = 15; RightEdge =
  `UnifiedDim scale=1 type=TopEdge` (kiểu dọc nên ra `H`, thanh dọc không dùng); BottomEdge =
  `H` − **rộng** `ScrollBar_Down_Normal` = `H − 15`.
- `Child TLBB_ButtonNULL` hậu tố `__auto_incbtn__` (nút XUỐNG, tăng vị trí): ô `(0, H − 15, 15, 15)`;
  thuộc tính `MouseButtonDownAutoRepeat=True`, `ClickSound=19`, `BtnAnimation=ScrollBar_Flash`,
  `UseStandardImagery=False`, `NormalImage=set:Button1 image:ScrollBar_Down_Normal`,
  `HoverImage=...ScrollBar_Down_Hover`, `PushedImage=...ScrollBar_Down_Pushed`.
- `Child TLBB_ButtonNULL` hậu tố `__auto_decbtn__` (nút LÊN): ô `(0, 0, 15, 15)`; `ClickSound=20`,
  còn lại như trên với ảnh `ScrollBar_Up_Normal|Hover|Pushed`.
- `Child TLBB_ScrollbarThumb_Common` hậu tố `__auto_thumb__`: ô `(1, 0, 15, 18)` (rộng, cao lấy
  `ImageDim` của `Button4/ScrollBar_Thumb_Normal`). Số 1 ở LeftEdge bị `updateThumb` ghi đè thành 0
  (mục 6.5).
- `ImagerySection main`: một `ImageryComponent`, vùng Left 0, Top 15, RightEdge = rộng
  `ScrollBar_Bar` = 16, BottomEdge = `H − 15`; ảnh `Button1/ScrollBar_Bar`; `VertFormat Tiled`,
  `HorzFormat CentreAligned`.
- `StateImagery Enabled`: `main`. `StateImagery Disabled`: `main` nhân màu `FF7F7F7F`.

Look `TLBB_Look_ScrollbarThumb_Common` (dòng 9): `Property VertFree = True`; các `ImagerySection`
`normal`, `Hover`, `Pushed`, `Disabled`, `SpecialNormal`, mỗi cái một ảnh
`Button4/ScrollBar_Thumb_<Normal|Hover|Pushed|Disabled|Normal>` kéo giãn (`Stretched`) trong ô
`(0, 0, rộng ảnh, cao ảnh)` = 15x18. `StateImagery`: `Normal`→`normal`, `Hover`→`Hover`,
`Pushed`→`Pushed`, `Disabled`→`Disabled` nhân `FF7F7F7F`; `SpecialNormal`, `SpecialHover`,
`SpecialPushed`→`SpecialNormal`; `SpecialDisabled`→`SpecialNormal` nhân `FF7F7F7F`.

### 6.3 Look `TLBB_Look_Scrollbar_Track` (dòng 1193)

Ảnh: `MissionAtrack/MKUp_Normal|Hover|Pushed` 11x11, `MKDown_Normal|Hover|Pushed` 11x11,
`MKScrollBar_Bar` 11x73, `MKScrollBar_Thumb_Normal|Hover|Pushed|Disabled` 11x13.

- `VerticalScrollbar = True`.
- `ThumbTrackArea`: Left 0; Top = 11; RightEdge = `H` (như trên); BottomEdge = `H − 11`.
- `__auto_incbtn__` (`TLBB_ButtonNULL`): ô `(0, H − 11, 11, 11)`, ảnh `MKDown_*`, cùng bộ thuộc tính.
- `__auto_decbtn__`: ô `(0, 0, 11, 11)`, ảnh `MKUp_*`.
- `__auto_thumb__` kiểu `TLBB_MissonTrackThumb_Common`: ô `(0, 0, 11, 13)`.
- `ImagerySection main`: vùng Left 0, Top 11, Width 11, BottomEdge `H − 11`; ảnh `MKScrollBar_Bar`
  kéo giãn cả hai chiều (`Stretched`).
- `Enabled`: `main`; `Disabled`: `main` nhân `FF7F7F7F`.

Look `TLBB_Look_MissonTrackThumb_Common` (dòng 2318): `VertFree = True`; section `normal` ở
`(0,0,11,13)`, các section `Hover`, `Pushed`, `Disabled`, `SpecialNormal` ở `(1,0,11,13)`. Nhưng
`StateImagery Normal`, `Hover`, `Pushed` đều chỉ vẽ section `normal`, `Disabled` vẽ `normal` nhân
`FF7F7F7F`: thumb của thanh Track KHÔNG đổi hình khi rê hay nhấn. `Special*`→`SpecialNormal`.

### 6.4 Lớp `Scrollbar` (B) — thành viên, mặc định, thuật toán

Độ dời thành viên **[2026]** (các hàm get một lệnh): `d_documentSize +0x3f0` (B 0x1800c4e20),
`d_pageSize +0x3f4` (B 0x1800c4e40), `d_stepSize +0x3f8` (B 0x1800c4e60), `d_overlapSize +0x3fc`
(B 0x1800c4e30), `d_position +0x400` (B 0x1800c4e50), cờ `changeToZero +0x404` (B 0x1800c4dd0, chỉ
có ở 2026), `d_thumb +0x408`, `d_increase +0x410`, `d_decrease +0x418` (B 0x180103150, 0x1801033ab,
0x1801034aa). `FalagardScrollbar`: `d_vertical +0x420` (F 0x180046790), cờ thumb đặc biệt `+0x421`
(F 0x180043760).

Mặc định **[2026]** — constructor B 0x180102760: `documentSize = 1.0`, `pageSize = 0.0` (một lệnh
ghi 8 byte ở 0x180102794), `stepSize = 1.0`, `overlapSize = 0.0` (0x1801027a1), `position = 0`,
`changeToZero = false`. Giống mã 2008 (`CEGUIScrollbar.cpp:57-63`). `FalagardScrollbar` (F
0x180045f90) đặt `d_vertical = false`, cờ đặc biệt `false`; look đặt `VerticalScrollbar=True`.

```
# B 0x1801037e0  Scrollbar::setScrollPosition(pos)                          [2026]
old      = position
max_pos  = max(documentSize - pageSize, 0)
position = pos < 0 ? 0 : (pos > max_pos ? max_pos : pos)     # NaN cũng về 0
updateThumb()                                               # ảo, vtable +0x280
if position != old:
    onScrollPositionChanged()                               # sự kiện "ScrollPosChanged"
    if position == max_pos: fireEvent(EventHasScrollToEnd)  # 0x18010389e, chỉ có ở 2026
changeStateOfButtons()                                      # ảo, vtable +0x2c0, chỉ có ở 2026

# B 0x1801036b0 setDocumentSize(v), B 0x180103780 setPageSize(v):            [2026]
#   khác giá trị cũ thì ghi, updateThumb(), onScrollConfigChanged().
# B 0x1801038e0 setStepSize, B 0x180103730 setOverlapSize: ghi rồi onScrollConfigChanged().
#   Các hàm này KHÔNG kẹp lại position.

# B 0x180103530  Scrollbar::onMouseButtonDown(e)  — bấm vào RÃNH (chính cửa sổ thanh cuộn)  [2026]
Window::onMouseButtonDown(e)
if e.button == Left:
    adj = getAdjustDirectionFromPoint(e.position)           # ảo +0x290: +1, -1 hoặc 0
    if adj != 0:
        new = position + (pageSize - overlapSize) * adj
        if new <= 0: changeToZero = true
        setScrollPosition(new)
    e.handled = true

# B 0x1801035b0  Scrollbar::onMouseWheel(e)                                   [2026]
Window::onMouseWheel(e)
new = position - stepSize * e.wheelChange
if new <= 0: changeToZero = true
setScrollPosition(new)
e.handled = true

# B 0x180102ff0 handleIncreaseClicked(e): nếu e.button == Left: setScrollPosition(position + stepSize)
# B 0x180102fb0 handleDecreaseClicked(e): nếu e.button == Left:
#     if stepSize >= position: changeToZero = true
#     setScrollPosition(position - stepSize)
# B 0x180103020 handleThumbMoved: v = getValueFromThumb(); if v <= 0: changeToZero = true;
#     setScrollPosition(getValueFromThumb())
```

Một nấc bánh xe là `wheelChange = +1` hoặc `−1`: U 0x18006bb07 và 0x18006bb58 gọi
`System::injectMouseWheelChange(1.0f)` / `(−1.0f)` **[2026]**. Nấc nào là lăn lên chưa đối chiếu
**[?]**; theo quy ước CEGUI thì +1 là lăn lên nên vị trí giảm `stepSize`.

Khác 2008 ở cách nối nút lên/xuống **[2026]**: `Scrollbar::initialise` (B 0x1801030e0) đăng ký
`handleIncreaseClicked`, `handleDecreaseClicked` vào `Window::EventMouseClick` (B 0x1802e0ab0, thấy ở
0x1801033bd và 0x1801034bc), mã 2008 đăng ký vào `EventMouseButtonDown` (`CEGUIScrollbar.cpp:92,97`).
`onMouseClicked` (vtable +0x1a8) chỉ được `System::injectMouseButtonUp` gọi (B 0x18008aee2), còn sự
kiện tự lặp `Window::generateAutoRepeatEvent` (B 0x1800a0230) gọi `onMouseButtonDown` (vtable +0x198)
và `Window::onMouseButtonDown` (B 0x1800a3f80) không phát `EventMouseClick`. Hệ quả: ở bản 2026 nút
lên/xuống đổi đúng một `stepSize` mỗi lần BẤM RỒI NHẢ; giữ nút không cuộn tiếp dù look đặt
`MouseButtonDownAutoRepeat=True` (trễ 0,3 s, nhịp 0,06 s: B 0x1800999f4, 0x1800999ff). Kết luận
"giữ nút không cuộn" là suy từ ba địa chỉ trên, chưa chạy thử trên client thật.

Sự kiện thumb: `EventThumbPositionChanged` → `handleThumbMoved`, `EventThumbTrackStarted`,
`EventThumbTrackEnded` (B 0x1801031e4, 0x180103251, 0x1801032be) như 2008.

### 6.5 `FalagardScrollbar` (F)

```
# F 0x1800468c0  updateThumb()   (dọc)                                        [2026]
area   = ThumbTrackArea.getPixelRect(this)        # toạ độ trong thanh cuộn
thumb  = cửa sổ <tên>__auto_thumb__
ext    = documentSize - pageSize                  # có thể âm hay 0
if special (+0x421):                              # chỉ FalagardChatHistory bật, xem dưới
    thumb.useSpecialImg(|position - ext| > 1e-8)  # 0x180046a20: hằng 9.99999994e-09
slide  = (area.bottom - area.top) - thumb.height
thumb.setVertRange(relY(area.top), relY(area.top + slide))
if |ext| <= 1e-8:  y = area.top                   # 0x180046ac5: chặn chia cho 0, 2008 không có
else:              y = area.top + (slide / ext) * position     # divss, mulss, addss theo thứ tự này
thumb.setPosition(Point(relX(area.left), relY(y)))

# relY(v) = PixelAligned(v) / cao thanh cuộn (B 0x18009d750); setPosition theo chế độ Relative.
# Kết quả: thumb đứng ở x = area.left = 0, y = (int)(y + 0.5) trong thanh cuộn.

# F 0x1800465c0  getValueFromThumb()   (dọc)                                  [2026]
slide = (area.bottom - area.top) - thumb.height
return (thumb.getAbsoluteYPosition() - area.top) / (slide / (documentSize - pageSize))

# F 0x180046490  getAdjustDirectionFromPoint(pt)                              [2026]
r = thumb.getUnclippedPixelRect()                 # toạ độ màn hình
dọc:  pt.y > r.bottom → +1;  pt.y < r.top → -1;  còn lại 0

# F 0x1800467a0  performChildWindowLayout(): Window::performChildWindowLayout(); updateThumb()
# F 0x1800467d0  populateRenderCache(): vẽ StateImagery "Disabled" nếu isDisabled(), không thì "Enabled"

# F 0x1800462a0  changeStateOfButtons()                                       [2026, 2008 không có]
max_pos = max(documentSize - pageSize, 0)
if d_increase == null or d_decrease == null: return
if max_pos <= 0:          inc.enableAnimate(false); dec.enableAnimate(false)
elif position == 0:       inc.enableAnimate(true);  dec.enableAnimate(false)
else:                     inc.enableAnimate(position != max_pos); dec.enableAnimate(true)
```

Cỡ thumb CỐ ĐỊNH theo look (15x18 và 11x13), không co theo tỉ lệ `pageSize / documentSize`:
`updateThumb` chỉ đặt vị trí và khoảng chạy, không đặt cỡ **[2026]** (giống 2008,
`FalScrollbar.cpp:87-109`).

`useSpecialThumb(true)` trong F chỉ có `FalagardChatHistory::initialise` gọi (F 0x180057d49); trong
B không hàm nào gọi ô vtable +0x2b8 của thanh cuộn. Với listbox và cửa sổ phức hợp cờ này là `false`
nên thumb luôn dùng state `Normal`/`Hover`/`Pushed`/`Disabled`. Module khác (`UI_CEGUI.dll`,
`Game.exe`) chưa rà **[?]**.

### 6.6 `Thumb` (B) và `FalagardThumb` (F)

Thành viên **[2026]**: `d_hotTrack +0x6f0`, `d_vertFree +0x6f1`, `d_horzFree +0x6f2`,
`d_vertMin +0x6f4`, `d_vertMax +0x6f8`, `d_horzMin +0x6fc`, `d_horzMax +0x700`,
`d_beingDragged +0x704`, `d_dragPoint +0x708`; `FalagardThumb` thêm cờ ảnh đặc biệt `+0x710`.
Mặc định (B 0x1801189a0): `hotTrack = true`, `vertFree = horzFree = false`, khoảng `[0, 1]`,
không kéo. Look đặt `VertFree=True`.

```
# B 0x1801191e0  Thumb::onMouseButtonDown(e)                                  [2026]
PushButton::onMouseButtonDown(e)
if e.button == Left:
    beingDragged = true
    dragPoint = screenToWindow(e.position)        # đổi ra điểm ảnh nếu đang ở chế độ Relative
    onThumbTrackStarted();  e.handled = true

# B 0x1801192a0  Thumb::onMouseMove(e)                                        [2026]
PushButton::onMouseMove(e)
if beingDragged:
    delta  = screenToWindow(e.position) (điểm ảnh) - dragPoint
    newPos = vị trí hiện tại của thumb trong cha (điểm ảnh)
    if horzFree: newPos.x = clamp(newPos.x + delta.x, horzMin, horzMax)   # khoảng đổi ra điểm ảnh
    if vertFree: newPos.y = clamp(newPos.y + delta.y, vertMin, vertMax)
    if newPos != vị trí cũ:
        setPosition(newPos)
        if hotTrack: onThumbPositionChanged()     # → Scrollbar::handleThumbMoved
e.handled = true

# B 0x180119180  onCaptureLost: beingDragged = false; onThumbTrackEnded(); onThumbPositionChanged()
# B 0x1801195e0  setVertRange(min, max): min > max thì max = min; ghi; kẹp lại vị trí y hiện tại
```

Giống mã 2008 (`CEGUIThumb.cpp:169-294`).

```
# F 0x1800494c0  FalagardThumb::doThumbRender(state)                          [2026]
if !needsRedraw: return
xoá hình cũ; needsRedraw = false
if useStandardImagery (+0x459):
    name = (special +0x710 ? "Special" : "") + state      # 0x180049564..0x180049591, 2008 không có
    vẽ StateImagery name nếu look có, không thì "Normal"
# drawNormal/Hover/Pushed/Disabled (F 0x180049760, 0x1800496f0, 0x1800497d0, 0x180049680) gọi với
# "Normal", "Hover", "Pushed", "Disabled". Chọn hàm nào là ButtonBase::drawSelf (mục 7.3).
```

### 6.7 Nút lên, nút xuống (`TLBB_ButtonNULL`)

`UseStandardImagery=False` nên `doButtonRender` bỏ qua look (F 0x1800026da); chỉ còn ảnh thuộc tính,
kéo giãn kín ô nút (15x15 hoặc 11x11, bằng đúng cỡ ảnh): thường `NormalImage`, rê `HoverImage`, nhấn
`PushedImage`; bị vô hiệu thì KHÔNG vẽ gì vì không có `DisabledImage` (F 0x18000294c). Chi tiết ở
mục 7.3.

Hoạt ảnh `BtnAnimation=ScrollBar_Flash` (`wowanimate.xml` dòng 146: một khung
`set:stall07 image:ScrollBar.gif_00` 19x21, `Loop=true`, `AlphaMode=true`, `PlayTime=800`,
`AlphaType=1`) **[2026]**:

- `FalagardButton::setBtnAnimation` (F 0x1800033b0) giữ con trỏ hoạt ảnh (+0x700), tổng thời gian
  `PlayTime` (+0x70c) và khung đầu (+0x710).
- `enableAnimate(on)` (F 0x180002dc0): ghi cờ +0x720; bật thì ghi mốc thời gian (ms) vào +0x708.
- `updateAnimate` (F 0x180003470): `t = now_ms − mốc`; khung = `Animate::getFrame(t, PlayTime)`;
  alpha (+0x718) = `Animate::getFrameAlpha(t, PlayTime)`; `requestRedraw`.
- `Animate::getFrameAlpha` (B 0x1800b7dd0): không `AlphaMode` thì 1; `p = (Loop ? t mod T : t) / T`;
  `AlphaType 1`: `p >= 0.5 ? (1 − p) * 2 : p * 2` (sóng tam giác 0→1→0 mỗi 800 ms); `AlphaType 2`:
  `1 − p`; khác: `p`.
- `drawAnimate` (F 0x1800027d0, gọi từ `FalagardButton::drawSelf` F 0x180002da8 sau hình thường):
  vẽ khung hiện tại kéo giãn kín ô nút `(0, 0, w, h)`, màu trắng, alpha = alpha trên.

Theo `changeStateOfButtons` (6.5): nút xuống nháy khi còn cuộn xuống được, nút lên nháy khi còn
cuộn lên được, không nháy khi nội dung vừa khít.

### 6.8 Chỗ 2026 khác 2008 (tóm tắt)

| Chỗ | 2008 | 2026 |
|---|---|---|
| Nút lên/xuống nghe sự kiện | `EventMouseButtonDown` (`CEGUIScrollbar.cpp:92,97`) | `EventMouseClick` (B 0x1801033bd, 0x1801034bc) |
| `updateThumb` khi `doc == page` | chia cho 0 (`FalScrollbar.cpp:101`) | đặt thumb ở đầu rãnh (F 0x180046ac5) |
| Tới cuối | không | phát `EventHasScrollToEnd` (B 0x1801038a5) |
| Nút nháy | không | `changeStateOfButtons` + `BtnAnimation` (F 0x1800462a0) |
| Thumb `Special*` | không | `useSpecialThumb`/`useSpecialImg` (F 0x180043760, 0x180043740) |
| Cờ `changeToZero` | không | đặt khi thao tác người dùng đưa vị trí về ≤ 0 (B 0x180102fcf, 0x18010303a, 0x180103586, 0x1801035ec); nơi đọc `IsChangeToZero` chưa rà **[?]** |

Mặc định, công thức vị trí thumb, `getValueFromThumb`, `getAdjustDirectionFromPoint`, bước bấm rãnh
`(pageSize − overlapSize)`, bước bánh xe `stepSize × wheelChange`, kéo thumb: giống 2008.

### 6.9 Ví dụ số (1280x720)

`QuestLog_Listbox` = `(222, 167.66, 240, 382)` (`tests/golden/ui_rects.tsv`). Con
`__auto_vscrollbar__` của `TLBB_Look_ListBoxCommon`: `<Area>` Left 0, Top 1, Width 16, Height =
`382 − 2` = 380, `HorzAlignment RightAligned`.

| Thứ | Ô trong cha (x, y, w, h) | Ô màn hình |
|---|---|---|
| thanh cuộn (trong listbox) | (224, 1, 16, 380) | (446, 168.66, 16, 380) |
| nút lên `__auto_decbtn__` (trong thanh cuộn) | (0, 0, 15, 15) | (446, 168.66, 15, 15) |
| nút xuống `__auto_incbtn__` | (0, 365, 15, 15) | (446, 533.66, 15, 15) |
| `ThumbTrackArea` | y từ 15 tới 365 (cao 350) | y từ 183.66 tới 533.66 |
| rãnh (`main`) | (0, 15, 16, 350) | (446, 183.66, 16, 350); `ScrollBar_Bar` 16x30 lát dọc từ trên xuống, 12 viên, viên cuối cắt còn 20 (số viên theo `CEGUIFalImageryComponent.cpp:156` **[2008]**) |
| thumb, `doc=600 page=376 pos=0` | (0, 15, 15, 18) | (446, 183.66, 15, 18) |
| thumb, `pos = max = 224` | (0, 347, 15, 18) | (446, 515.66, 15, 18) |
| thumb, `pos = 100` (thêm) | (0, 163, 15, 18) | (446, 331.66, 15, 18) |

Tính: `slide = 350 − 18 = 332`, `ext = 600 − 376 = 224`; `y = 15 + (332/224) × pos`; `pos=100` ra
163,214 → 163 (đã tính bằng float32 đúng thứ tự phép toán).

Thêm cho thanh Track: `MissionTrack_ListBoxTransparent` = `(1014, 286, 212, 139)`; thanh cuộn
`(201, 1, 11, 137)` → màn hình `(1215, 287, 11, 137)`; nút lên `(0, 0, 11, 11)`, nút xuống
`(0, 126, 11, 11)`; rãnh `(0, 11, 11, 115)` kéo giãn; `slide = 115 − 13 = 102`; thumb 11x13 ở
`y = 11 + (102/ext) × pos`.

### 6.10 `SRC/gui` hiện có thiếu gì cho thanh cuộn

- `layout()` chưa dựng cửa sổ con của look: `GuiChild` đã được nạp vào `GuiAsset::children`
  (`SRC/gui/asset.hpp:203`) nhưng không tệp `.cpp` nào của `SRC/gui` đọc nó ngoài bộ nạp. Thanh
  cuộn, nút và thumb đều là `Child`, và `WidgetDim widget="__auto_vscrollbar__"` trong
  `ItemRenderingAreaVScroll` cần cửa sổ con đã đặt (`widget_dim` tìm theo tên cha + hậu tố).
- `kind_of`: `Falagard/Scrollbar` rơi vào `kPlain` và vẽ `Enabled` (đúng với
  `populateRenderCache`). `Falagard/Thumb` cũng rơi vào `kPlain` nhưng look thumb không có state
  `Enabled`, nên phải vẽ như nút (state `Normal`/`Hover`/`Pushed`/`Disabled`, không ảnh thuộc tính).
- Cần trạng thái mỗi thanh: `documentSize`, `pageSize`, `stepSize`, `overlapSize`, `position`.
- Hoạt ảnh nháy của nút (`BtnAnimation`) chưa có (chú thích đầu `sheet.hpp` đã ghi Animate chưa có).

### 6.11 Phương thức Lua

Năm script không gọi phương thức nào của metatable thanh cuộn. Bảng `MetaTable_Control_ScrollBar`
(`lua_methods.txt`) có: `SetPosition(n)` U 0x180039ec0 → `Scrollbar::setScrollPosition((float)n)`
(0x180039efa) **[2026]**; `GetPosition()` U 0x180026ee0 → một số; `GetThumbPositionX()` U
0x180027580 (chưa tháo). `SetVScrollbarAlpha`, `SetCurrentFirstItem`... thuộc ListBox/ListBoxEx
(nhánh khác).

---

## 7. `TLBB_StopWatch`, `TLBB_DragTitle`, ba kiểu `Falagard/CheckBox`

### 7.1 `TLBB_StopWatch`

Bản tháo: `sm_stopwatch.txt`, `sm_simpletext.txt`.

`TLBB_StopWatch` → `Falagard/StopWatch` (`FalagardStopWatch` : `FalagardSimpleText`, constructor F
0x1800ba9d0 gọi F 0x18004d5f0) + look `TLBB_Look_NULL` (`TLBBLook_Common.looknfeel.xml` dòng 3, look
rỗng: không section, state, vùng nào).

Vẽ: không có hàm vẽ riêng; chữ của cửa sổ do `FalagardSimpleText::populateRenderCache` (F
0x18004e300) vẽ. Với look rỗng: `isStateImageryPresent("Enabled"/"Disabled")` sai nên không vẽ nền
(F 0x18004e3ab, 0x18004e42c); look không có `NamedArea TextArea` nên vùng chữ là cả cửa sổ
(`getTextRenderArea` F 0x18004e130). Canh dọc trong hàm đó **[2026]** (F 0x18004e534..0x18004e5e7):
`TopAligned (0)`: `top += 1`; `BottomAligned (1)`: `top = bottom − textH`; `VertCentred (2)`:
`top += PixelAligned((cao vùng − textH) × 0.5)`; với `textH = getFormattedSize(...).h`. Mặc định của
`FalagardSimpleText` (F 0x18004d62a, 0x18004d634): `HorzFormatting = LeftAligned (0)`,
`VertFormatting = VertCentred (2)`, tỉ lệ chữ 1 x 1. Phần còn lại của `FalagardSimpleText` thuộc
nhánh bộ máy chữ.

Thuộc tính (tên chuỗi trong F): `Timer`, `Step` (như 2008), và mới ở 2026: `Flash`, `HourText`,
`DayText`, `TimerShowType`. Thành viên **[2026]**: `secondText +0x418`, `minuteText +0x440`,
`hourCNText +0x468`, `hourText +0x490` (F 0x1800bb850), `dayText +0x4b8` (F 0x1800bb830),
`f_lastSecond +0x4e0` (double, giây), `d_timeStep +0x4e8` (F 0x1800405c0), `d_currentTime +0x4ec`
(F 0x1800406a0), `flash +0x4f0` (F 0x18003fdb0), alpha nháy `+0x4f4`, chiều nháy `+0x4f8`,
`showType +0x4fc` (F 0x180040580).

Mặc định (constructor F 0x1800ba9d0): `Step = −1` (đếm LÙI một giây mỗi giây), `Timer = 0`,
`TimerShowType = 0`, `Flash = 0`, `hourText = " h"`, `dayText = "天"`, `hourCNText = "时"`,
`minuteText = "分"`, `secondText = "秒"` (chuỗi UTF-8 ở F 0x180140434..0x180140444),
`f_lastSecond = System::getCurTimeElapsedEx()`.

```
định_dạng(t):                                   # dùng chung, F 0x1800bb8f3.. và F 0x1800bbf23..  [2026]
    day = t / 86400;  hour = t / 3600           # hour KHÔNG trừ ngày
    rem = t - hour*3600;  minute = rem / 60;  second = rem - minute*60
    hour24 = hour % 24
    showType 0:  day != 0  → "%d%s" (day, dayText)
                 hour != 0 → "%d%s" (hour, hourText)                    # "1 h", bỏ phút
                 else      → second < 10 ? "%d:%d%d" (minute, 0, second) : "%d:%d" (minute, second)
    showType 1:  day != 0  → "%d%s" (day, dayText)
                 hour != 0 → minute < 10 ? "%d%s:%d%d" (hour, hourText, 0, minute)
                                         : "%d%s:%d" (hour, hourText, minute)
                 else      → như showType 0
    showType 2:  "%ds" (t)                                               # chuỗi ở F 0x180140478
    showType 3:  r = d_currentTime (số thô, không kẹp: F 0x1800bc141); m = r/60; s = r - m*60;
                 s < 10 ? "%d:0%d" (m, s) : "%d:%d" (m, s)
    showType 4:  day == 0: hour24 == 0 ? "%d%s" (minute, minuteText)
                                       : "%d%s%d%s" (hour24, hourCNText, minute, minuteText)
                 day != 0: hour24 == 0 ? "%d%s%d%s" (day, dayText, minute, minuteText)
                                       : "%d%s%d%s%d%s" (day, dayText, hour24, hourCNText, minute, minuteText)
    showType 5:  day != 0  → "%d%s" (day, dayText)
                 hour != 0 → "%d%s" (hour, hourCNText)
                 else      → second < 10 ? "%d%s%d%d%s" (minute, minuteText, 0, second, secondText)
                                         : "%d%s%d%s" (minute, minuteText, second, secondText)

# F 0x1800bb880  setTimer(time)   (thuộc tính Timer)                                         [2026]
d_currentTime = time
f_lastSecond  = System::getCurTimeElapsedEx()
if time == 0 or time < -1: setText("")
else:                      setText(định_dạng(time))     # time == -1 cũng đi nhánh này
requestRedraw()

# F 0x1800bbda0  updateSelf(elapsed)                                                         [2026]
if flash != 0:                                   # thuộc tính Flash
    a = lên ? a + elapsed : a - elapsed          # a ở +0x4f4, cờ lên ở +0x4f8
    if a <= 0:   lên = true;  a = 0
    if a >= 0.5: lên = false; a = 0.5
    setAlpha(a * 2)                              # nháy 0→1→0, chu kỳ 1 giây
t = d_currentTime
if t == 0 or t < -1:  nếu chữ khác "" thì setText(""); return
if t == -1:           nếu chữ khác "N/A" thì setText("N/A"); return
now = System::getCurTimeElapsedEx();  d = now - f_lastSecond
if d >= 1.0:
    n = (int)d
    d_currentTime += d_timeStep * n
    f_lastSecond   = now - (d - n)               # giữ phần lẻ
    shown = d_currentTime
    if d_currentTime < 0 and d_timeStep < 0: shown = 0     # 0x1800bbf1c..0x1800bbf20
    chữ = định_dạng(shown)
    if d_currentTime <= 0: fireEvent("ReachedZero")        # EventReachedZero, 0x1800bc344..0x1800bc37d
    setText(chữ); requestRedraw()
Window::updateSelf(elapsed)
```

`setFlash(n)` (F 0x180041e00): ghi `flash`; `n == 0` thì `setAlpha(1.0)`. `setStep` (F 0x1800bb870).

Khác 2008 (`FalStopWatch.cpp`):

- 2008: `setTimer` chỉ ghi số; chữ đổi ở `updateSelf` sau một giây. 2026: `setTimer` định dạng ngay.
- 2008: `second = (t % 3600) % 60 − d_timeStep` (cộng bù 1 khi đếm lùi); 2026: không bù.
- 2008: chỉ một kiểu hiện (`m:ss`, có giờ thì `h:m:s` không đệm số 0); 2026: sáu `TimerShowType`,
  có ngày, có chữ đơn vị.
- 2008: không có sự kiện về 0, không nháy, cộng đúng một `d_timeStep` mỗi lần đủ một giây; 2026:
  cộng `d_timeStep × (int)d` và giữ phần lẻ.

Hệ quả cần biết khi port: `Timer` lùi về đúng 0 thì khung đó hiện `0:00` và phát `ReachedZero`, khung
kế thấy `t == 0` nên chữ thành rỗng. Nếu một bước nhảy qua 0 xuống đúng −1 (ví dụ từ 1 lùi 2 giây)
thì khung kế hiện `N/A`; xuống dưới −1 thì rỗng.

`QuestLog_Watch` (layout dòng 140): `(327, 552.66, 50, 20)` ở 1280x720, `LeftAligned`, `VertCentred`,
`MouseHollow`, chữ khởi đầu `00:00:00`. Vì `Timer` mặc định 0, lần `updateSelf` đầu xoá chữ đó thành
rỗng. Script chỉ gọi `QuestLog_Watch:SetProperty("Timer", DT)` (`QuestLog.lua:197`, `DT` là số giây
còn lại của giờ kinh nghiệm đôi) → `setTimer(DT)`, kiểu hiện 0, lùi mỗi giây.

`SRC/gui` hiện có: `Falagard/StopWatch` không chứa chuỗi `SimpleText` nên rơi vào `kPlain`, không ra
chữ. Cần coi nó là `kText` và có trạng thái `Timer`/`Step` cùng đồng hồ (`Place::clock`) để tự đổi
chữ.

### 7.2 `TLBB_DragTitle`

Bản tháo: `sm_dragtitle.txt`, `sm_boundwindow.txt`.

`TLBB_DragTitle` → `Falagard/DragTitle` (`FalagardDragTitle`) + look `TLBB_Look_DragTitle`
(`TLBBLook_StaticText.looknfeel.xml` dòng 33): `Property HorzFormatting = HorzCentred`; hai
`StateImagery` `Enabled`, `Disabled` đều rỗng; không section, không vùng.

Khác 2008 ở lớp cha **[2026]**: constructor F 0x1800ad420 gọi constructor `FalagardSimpleText` (F
0x18004d5f0); mã 2008 kế thừa `Window` (`FalDragTitle.cpp:21`) nên không vẽ chữ. Ở 2026 tiêu đề vẽ
chữ của nó bằng `FalagardSimpleText::populateRenderCache` (như 7.1): vùng chữ là cả cửa sổ, canh
ngang theo `HorzFormatting` (look cho `HorzCentred`, layout có thể ghi đè), canh dọc theo
`VertFormatting` (mặc định `VertCentred`), phông theo thuộc tính `Font`, màu theo `TextColor`.
Constructor còn gọi `setAlwaysOnTop(true)` (F 0x1800ad470).

Thành viên: `d_dragTarget +0x418`, `d_dragging +0x420`, `d_dragPoint +0x424`.

```
# F 0x1800ad9e0  setDragTarget(name)   (thuộc tính DragTarget)                               [2026]
w = WindowManager.getWindow(name)
d_dragTarget = (w != null and w.testClassName("FalagardBoundWindow")) ? w : null

# F 0x1800ad810  onMouseButtonDown(e)
Window::onMouseButtonDown(e)
if e.button == Left and d_dragTarget != null and captureInput():
    d_dragging = true
    d_dragPoint = screenToWindow(e.position)          # điểm ảnh trong tiêu đề
e.handled = true

# F 0x1800ad930  onMouseMove(e)
Window::onMouseMove(e)
if d_dragging and d_dragTarget != null:
    delta = screenToWindow(e.position) (điểm ảnh) - d_dragPoint
    d_dragTarget.offsetPixelPosition(delta)           # F 0x18006c6a0
    e.handled = true

# F 0x1800ad8c0  onMouseButtonUp(e): nút trái thì releaseInput(); e.handled = true
# F 0x1800ad7f0  onCaptureLost: d_dragging = false
# F 0x1800ad900  onMouseLeaves: nếu đang kéo thì releaseInput(); d_dragging = false   (2008 không có)

# F 0x18006c6a0  FalagardBoundWindow::offsetPixelPosition(offset)                            [2026]
if getMetricsMode() == Relative:  u = (scale = offset / cỡ cha (0 nếu cỡ cha 0), offset = 0)
else:                             u = (scale = 0, offset = PixelAligned(offset))
setWindowPosition(d_area.getPosition() + u)
# rồi, chỉ có ở 2026 (0x18006c82c..0x18006c872): theo cờ +0x6e0 của cửa sổ đích,
#   đặt lại vị trí bằng setPosition(Absolute, vị trí.asAbsolute(cỡ cha)) hoặc
#   setPosition(Relative, vị trí.asRelative(cỡ cha)). Nghĩa của cờ +0x6e0 chưa đọc [?].
```

Cửa sổ đích phải là `Falagard/BoundWindow` (`TLBB_MainFrameNULL`); kiểu khác thì tiêu đề không kéo
được gì. Kẹp cửa sổ trong màn hình (nếu có) không nằm trong các hàm trên **[?]**.

Ví dụ: `QuestLog_Text` = `(294, 96.9, 406, 20)` ở 1280x720, chữ `#{INTERFACE_XML_52}`, phông
`YouYuan11.25`, `HorzCentred`, `VertCentred`, `DragTarget = QuestLog_Frame`.
`MissionTrack_DragTitle` = `(1094, 269, 100, 20)`, không chữ, chứa ảnh `MK_Mission`.

`SRC/gui` hiện có: `Falagard/DragTitle` rơi vào `kPlain` nên chữ tiêu đề không được vẽ (look không
có `TextComponent`). Cần coi là `kText`. `effective()` đã lùi về thuộc tính của look nên
`HorzFormatting=HorzCentred` của look sẽ có tác dụng khi layout không ghi. Kéo cửa sổ là việc của
tầng nhập liệu (`Hub::hit` + dời `UnifiedPosition` qua `Override`).

Lua: script chỉ dùng phương thức chung của `Window` (`SetText`...), không có phương thức riêng.

### 7.3 Ba kiểu `Falagard/CheckBox` (`FalagardCheckButton` : `FalagardButton` : `PushButton`)

Bản tháo: `sm_check.txt`, `sm_button.txt`, `sm_vt_check.txt`, `sm_lua_small.txt`.

| Kiểu TLBB | Look | Ở layout |
|---|---|---|
| `TLBB_ButtonPageDown` | `TLBB_Look_ButtonPageDown` (`TLBBLook_Button.looknfeel.xml` dòng 3375) | sáu thẻ trang dưới đáy `ActionSkill`, `CommonSkill`, `LifeSkill` (35x18, `CheckMode=1`, `HorzLabelFormatting=WordWrapCentreAligned`) |
| `TLBB_ButtonCheckForRMBShop` | `TLBB_Look_ButtonCheckRMBShop` (dòng 6142) | `QuestLog_CurrentMission`, `QuestLog_AcceptMission` (65x24, `CheckMode=1`) |
| `TLBB_ButtonCheckNULL` | `TLBB_Look_ButtonNULL` (dòng 736) | `MissionTrack_HaveGet`, `MissionTrack_WillGet` (40x18, `CheckMode=1`, bốn ảnh thuộc tính) |

**Look `TLBB_Look_ButtonPageDown`**: `PropertyDefinition VertLabelFormatting`, `HorzLabelFormatting`
(đều `CentreAligned`), `Property ClickSound=17`. `ImagerySection label`: một `TextComponent` vùng
`(0, 1, w, h)` (Top = 1, cao bằng cửa sổ nên tràn đáy 1 điểm ảnh), canh theo hai thuộc tính trên.
`ImagerySection normal|hover|pushed|disabled`: mỗi cái một `FrameComponent` kín cửa sổ chỉ có ba
ảnh `LeftEdge`, `RightEdge`, `Background` của `Button5`:
`BtnPageDown_<Normal|Hover|Pushed|Disabled><L|R|M>` (L và R 9x18, M 17x18). `StateImagery`:
`Normal` = `normal` + `label` màu `FFFDEB78`; `Hover` = `hover` + `label` `FFFFFF00`; `Pushed` =
`pushed` + `label` `FFFFFF00`; `Disabled` = `disabled` + `label` `FFBBBBBB`.

**Look `TLBB_Look_ButtonCheckRMBShop`**: `PropertyDefinition WantsMultiClickEvents=true`, hai
`*LabelFormatting = CentreAligned`, `ClickSound=435`. `label`: `TextComponent` kín cửa sổ
`(0, 0, w, h)`. `normal`: `FrameComponent` chín mảnh `Button1/BtnCommon_<1..9>_Normal` (góc 3x3, cạnh
trên/dưới 34x3, cạnh trái/phải 3x14, nền 34x14). `hover`: ba mảnh
`Button4/BtnCommon_Green_<Left|Right|Mid>_Hover` (10x21, 10x21, 19x21). `pushed`: ba mảnh
`Button4/BtnCommon_Green_<Left|Right|Mid>_Normal`. `disabled`: chín mảnh
`Button1/BtnCommon_<1..9>_Disable`. `StateImagery` và màu nhãn y như `ButtonPageDown`.

**Look `TLBB_Look_ButtonNULL`**: hai `*LabelFormatting = CentreAligned`, `ClickSound=17`; chỉ có
`ImagerySection label` (`TextComponent` kín cửa sổ). `Normal` = `label` màu `FFFDEB78`; `Hover`,
`Pushed`, `Disabled` = `label` không ghi màu. Hình của nút là ảnh thuộc tính
`NormalImage`/`HoverImage`/`PushedImage`/`DisabledImage` của layout.

Thành viên **[2026]**: `d_pushed +0x3f0`, `d_hovering +0x3f1` (`ButtonBase`),
`d_useStandardImagery +0x459`, `d_useNormalImage +0x45a`, `d_useHoverImage +0x45b`,
`d_usePushedImage +0x45c`, `d_useDisabledImage +0x45d`, bốn `RenderableImage` ở `+0x460`, `+0x500`,
`+0x5a0`, `+0x640` (`PushButton`); `d_bIsSelected +0x728` (F 0x180040770), `d_nCheckMode +0x72c`
(F 0x1800d2e40), `showPush +0x730` (F 0x1800407f0), `d_selectImage +0x738`. Mặc định (constructor F
0x1800d23c0): chưa chọn, `CheckMode = 0`, `ShowPush = true`. Thuộc tính của lớp: `SelectImage`,
`Selected`, `CheckMode` (như 2008) và `ShowPush` (mới).

```
# F 0x1800d2ce0  FalagardCheckButton::drawSelf()                                             [2026]
if needsRedraw:
    if d_bIsSelected and !d_pushed:
        xoá hình cũ; needsRedraw = false
        showPush ? drawPushed() : drawHover()     # vtable +0x278 / +0x270; nhánh Hover chỉ có ở 2026
    else:
        FalagardButton::drawSelf()                # F 0x180002d50 → ButtonBase::drawSelf
Window::drawSelf()

# B 0x1800bd110  ButtonBase::drawSelf()                                                      [2026]
# (đầu hàm, chỉ có ở 2026: đang hovering mà cửa sổ dưới con trỏ không còn là mình và mình không
#  phải cửa sổ ở biến B 0x1802e9730 thì xoá cả d_pushed lẫn d_hovering — 0x1800bd12b..0x1800bd16d)
if d_hovering and !isDisabled(): drawHover()      # +0x270
elif d_pushed:                   drawPushed()     # +0x278
elif isDisabled():               drawDisabled()   # +0x280
else:                            drawNormal()     # +0x268
# d_hovering = (chuột trên nút) XOR d_pushed  [2008: CEGUIButtonBase.cpp:95]: nhấn giữ trên nút
# thì vẽ Pushed, nhấn rồi kéo ra ngoài thì vẽ Hover.

# F 0x1800026b0  FalagardButton::doButtonRender(state)                                       [2026]
if d_useStandardImagery: vẽ StateImagery state nếu look có, không thì "Normal"

# F 0x180002aa0 drawNormal:   doButtonRender("Normal");   if d_useNormalImage:
#       look có NamedArea "ActionArea" thì đặt ô ảnh = vùng đó (0x180002b4e..0x180002c01, chỉ 2026);
#       vẽ NormalImage
# F 0x1800029c0 drawHover:    doButtonRender("Hover");    if d_useHoverImage:    vẽ HoverImage
# F 0x180002c70 drawPushed:   doButtonRender("Pushed");   if d_usePushedImage:   vẽ PushedImage
# F 0x1800028e0 drawDisabled: doButtonRender("Disabled"); if d_useDisabledImage: vẽ DisabledImage
# Ảnh thuộc tính kéo giãn kín cửa sổ, alpha = getEffectiveAlpha(). Thiếu ảnh của state nào thì state
# đó KHÔNG vẽ ảnh thuộc tính nào (không lùi về NormalImage); cờ d_use*Image chỉ bật ở hàm set tương
# ứng (PushButton::setNormalImage B 0x1800fd559).
```

Bảng state theo trạng thái (đúng cho cả ba kiểu, `ShowPush` mặc định):

| Trạng thái | State của look | Ảnh thuộc tính |
|---|---|---|
| thường | `Normal` | `NormalImage` |
| rê chuột, chưa chọn | `Hover` | `HoverImage` |
| đang nhấn giữ trên nút | `Pushed` | `PushedImage` |
| đang chọn, không nhấn (kể cả đang rê, kể cả đang bị vô hiệu) | `Pushed` | `PushedImage` |
| vô hiệu, chưa chọn | `Disabled` | `DisabledImage` |

`MissionTrack_HaveGet`/`WillGet` cố ý tráo: `HoverImage = MK*_Pushed`, `PushedImage = MK*_Hover`;
nên thẻ đang chọn hiện ảnh `MK*_Hover`.

```
# F 0x1800d2e50  onMouseButtonDown(e)                                                        [2026]
PushButton::onMouseButtonDown(e)
if e.button == Left and captureInput():
    if (d_nCheckMode == 1 or d_nCheckMode == 2) and d_bIsSelected: return   # mode 2 chỉ có ở 2026
    d_pushed = true
    d_bIsSelected = !d_bIsSelected
    updateInternalState(e.position); requestRedraw()
    e.handled = true

# F 0x1800d2ed0  onMouseButtonUp(e)                                                          [2026]
PushButton::onMouseButtonUp(e)                    # B 0x1800fcf80: nút trái (hoặc nút phải khi cờ +0x6e9
                                                  # bật), đang d_pushed và cửa sổ dưới con trỏ là mình
                                                  # thì onClicked() → sự kiện "Clicked" (0x1800fcff8)
if d_nCheckMode == 1 and d_bIsSelected:
    với mọi cửa sổ anh em c của cùng cha, c.testClassName("FalagardCheckButton"), c != this:
        c.d_bIsSelected = false; c.requestRedraw()
if e.button == Right and cửa sổ dưới con trỏ là mình: onRBClicked()   # sự kiện "RBClicked", chỉ 2026

# F 0x1800d31a0  setCheck(b)   (thuộc tính Selected)                                         [2026]
d_bIsSelected = b
if d_nCheckMode == 1 and b: mọi anh em FalagardCheckButton khác: setCheck(false)
requestRedraw()
```

`CheckMode`: 0 = ô đánh dấu (bấm là đảo); 1 = nút radio (bấm khi đang chọn không bỏ chọn; khi được
chọn thì bỏ chọn mọi `FalagardCheckButton` anh em cùng cha); 2 (chỉ 2026) = bấm khi đang chọn không
bỏ chọn nhưng KHÔNG bỏ chọn anh em. Chú ý trạng thái chọn đổi ngay lúc NHẤN xuống, trong khi layout
`QuestLog`, `MissionTrack` nghe `MouseLButtonDown` còn các thẻ trang nghe `Clicked`. Bấm lại thẻ
đang chọn (`CheckMode=1`) không đổi trạng thái chọn nhưng `ButtonBase::onMouseButtonDown` vẫn đặt
`d_pushed` (B 0x1800bd3de) nên `Clicked` vẫn phát lúc nhả.

`drawCheck` (F 0x1800d2c70, vẽ `SelectImage`) không được `drawSelf` gọi ở cả hai bản; `SelectImage`
không có tác dụng lên hình.

Phương thức Lua (`MetaTable_Control_ImageCheckbox`, `lua_methods.txt`):

| Phương thức | Địa chỉ | Hành vi **[2026]** |
|---|---|---|
| `SetCheck(n)` | U 0x180036e30 | tham số phải là số; `(int)n == 1` thì `setProperty("Selected", "True")`, khác thì `"False"` (0x180036e9b..0x180036f50) → `setCheck` |
| `GetCheck()` | U 0x1800255a0 | `stringToBool(getProperty("Selected"))` → trả số 1 hoặc 0 |

Năm script dùng: `SetCheck(0|1)` trên các thẻ trang (`ActionSkill.lua:570,628,631`...,
`CommonSkill.lua:541`, `LifeSkill.lua:510`), trên `QuestLog_CurrentMission`/`AcceptMission`
(`QuestLog.lua:461,669,676,677`), `MissionTrack_HaveGet`/`WillGet` (`MissionTrack.lua:478,1909`...);
`GetCheck()` chỉ trên `QuestLog_Mode1/2` (kiểu `TLBB_ButtonCheck`, ngoài ba kiểu này).

**`Kind::kCheck` hiện có của `SRC/gui` so với mã máy** (`SRC/gui/paint.cpp:511-535`, `632-636`,
`SRC/gui/text.cpp:102-108`):

- Đúng: cả ba kiểu vào `kCheck` (TargetType chứa `CheckBox`); đang chọn mà không nhấn → `Pushed`;
  nhấn giữ trên nút → `Pushed`; rê → `Hover`; look thiếu state thì lùi về `Normal`
  (`button_look_state`); nhãn lấy `TextComponent` của đúng state đang vẽ nên màu nhãn đổi theo state;
  ảnh thuộc tính kéo giãn kín cửa sổ.
- Lệch 1: `button_state` xét `Disabled` trước `Selected`. Mã máy: đang chọn và không nhấn thì vẽ
  `Pushed` kể cả khi bị vô hiệu (F 0x1800d2cf2..0x1800d2d30).
- Lệch 2: `button_image` không có `DisabledImage` (state `Disabled` lấy `NormalImage`). Mã máy vẽ
  `DisabledImage`, không có thì không vẽ ảnh thuộc tính (F 0x18000294c).
- Lệch 3: `draw_button` lùi về `NormalImage` khi thiếu `HoverImage`/`PushedImage`. Mã máy không lùi
  (F 0x180002a2c, 0x180002cdc). Điều này áp cho mọi `Falagard/Button`, không riêng checkbox; với
  `MissionTrack_HaveGet`/`WillGet` (đủ bốn ảnh) chỉ Lệch 2 lộ ra.
- Thiếu: `ShowPush=false` (đang chọn vẽ `Hover`). Năm layout và `TLBBLook_Button.looknfeel.xml`
  không chỗ nào đặt `ShowPush`, nên chưa cần.
- Thiếu (việc của tầng nhập liệu, không phải bộ vẽ): luật radio của `CheckMode=1` (bỏ chọn anh em
  cùng cha) và việc chọn đổi lúc nhấn xuống.
- Chưa xác định **[?]**: thứ tự chồng giữa ảnh thuộc tính và chữ nhãn ở bản 2026. Mã 2008 vẽ mọi
  ảnh trước rồi mới tới chữ (bộ đệm `RenderCache`), `SRC/gui` cũng vậy (quad trước, chữ sau). Bản
  2026 vẽ thẳng vào `GeometryBuffer` theo thứ tự gọi và ảnh thuộc tính được gọi SAU `label`; chữ có
  đi vào bộ đệm riêng hay không thì chưa đọc. Ba kiểu ở đây không dính: hai kiểu có khung thì không
  có ảnh thuộc tính, `TLBB_ButtonCheckNULL` có ảnh thì không có chữ.

### 7.4 Phần chưa xong của các mục 6, 4, 7

1. (6) Chưa chạy client thật để xác nhận "giữ nút lên/xuống không cuộn tiếp"; chưa đối chiếu dấu của
   `wheelChange` với chiều lăn; chưa rà `UI_CEGUI.dll`/`Game.exe` xem có nơi gọi `useSpecialThumb`
   hay đọc `IsChangeToZero`; số viên lát của rãnh `Scrollbar_Common` chỉ theo mã 2008; đoạn cuối
   `WidgetComponent::layout` (B 0x180128d57..) chưa đọc.
2. (4) `th` và `w(s)` của ô tiền phụ thuộc `Font::getFormattedSize` (nhánh bộ máy chữ); hàm `set`
   của các thuộc tính `Money*`, `AlignFix` chưa tháo (tên có trong F, nghĩa suy từ hàm thành viên).
3. (7) Nghĩa cờ `+0x6e0` trong `offsetPixelPosition`; có kẹp cửa sổ trong màn hình khi kéo hay
   không; thứ tự chồng ảnh thuộc tính và chữ nhãn của nút ở bản 2026; `ButtonBase::drawSelf` 2026 có
   đoạn đầu so cửa sổ dưới con trỏ với biến B 0x1802e9730 (chưa tra đó là cửa sổ gì).

---

## 8. Phương thức Lua chung của `Window` mà năm script gọi lên widget

Bảng `MetaTable_Control_Window` của `UI_CEGUI.dll` 2026 (38 phương thức, đủ danh sách ở
`build/scratch/gui/lua_methods.txt`). Mọi metatable widget (`Listbox`, `ListBoxEx`, `ActionButton`,
`ComplexWindow`, `ImageCheckbox`...) đặt metatable này làm cha nên các phương thức dưới gọi được
trên mọi widget. Lớp nối giữ cửa sổ CEGUI ở `this+8`.

| Phương thức | Hàm (UI) | Hành vi [M] |
|---|---|---|
| `SetText(v)` | 0x180040310 | Số thì `sprintf("%d")`, không đọc thẻ. `Editbox`, `MultiLineEditBox`, `FalagardMultiIMEEditBox`: đổi mbcs sang utf8, đặt nguyên văn. Còn lại: qua bộ phân tích thẻ (cờ `ColorTrans` của cửa sổ) rồi `Window::setText`. Chi tiết ở mục 5 B.1. |
| `SetToolTip(text)` | 0x18003b740 | `text` phải là chuỗi; qua bộ phân tích thẻ; `Window::setTooltipText`. |
| `Show()` / `Hide()` | 0x18003c270 / 0x180027930 | `setVisible(true)` / `setVisible(false)`; `Hide` còn `releaseInput` khi cửa sổ là `Editbox`. |
| `IsVisible()` | 0x1800288f0 | `isVisible(false)` (xét cả cha), trả boolean. |
| `Enable()` / `Disable()` | 0x180024e90 / 0x180024d20 | `setEnabled(true/false)`. |
| `SetProperty(name, value)` | 0x18003f570 | Hai tham số phải là chuỗi. `name == "ShortImage"`: đổi `value` qua `IconManager::GetIconFullName` rồi đặt thuộc tính `Image`. Còn lại `Window::setProperty(name, value)` [?: đoạn giữa hàm 0x18003f760..0x18003faba chưa tháo hết, có thể còn tên đặc biệt khác]. |
| `GetProperty(name)` | 0x18003ec00 | `Window::getProperty(name)`, trả chuỗi. |
| `SetCheck(n)` / `GetCheck()` | 0x180036e30 / 0x1800255a0 (`MetaTable_Control_ImageCheckbox`) | Thuộc tính `Selected` = `True` khi `(int)n == 1`, ngược lại `False`; đọc lại thành số 1 hoặc 0. Chi tiết mục 7.3. |

`this:GetChildOffset(...)`, `this:TogleShow()`, `this:RegisterEvent(...)`, `this:Show()`,
`this:Hide()` là phương thức của đối tượng cửa sổ layout (`CUIWindowItem`), không phải của widget:
ngoài phạm vi, chưa tháo [?].

---

## 9. Ví dụ số cho kiểm thử

Ô cửa sổ lấy ở `tests/golden/ui_rects.tsv` (màn hình 1280x720). Mọi ô dưới đây là toạ độ TRONG cửa
sổ nêu tên (gốc ở góc trái trên cửa sổ đó); cộng góc cửa sổ để ra màn hình. Cách bộ vẽ của client
cộng phần lẻ của góc cửa sổ (ví dụ `y = 167,66`) chưa đọc [?] (mục 5 G), nên số màn hình ghi nguyên
phần lẻ. Hai cột phông: `S = 12` là client 2026 thật (GBK12, trang mã 936), `S = 14` là phông
`VTNAM14` của bản tiếng Việt của dự án.

### 9.1 `QuestLog_Listbox` (`TLBB_ListBoxCommon`), cửa sổ (222, 167.66, 240, 382)

| Thứ | Ô trong listbox (x, y, w, h) | Ô màn hình |
|---|---|---|
| `ItemRenderingArea` (chưa có thanh cuộn) | (6, 3, 231, 376) | (228, 170.66, 231, 376) |
| `ItemRenderingAreaVScroll` (thanh cuộn hiện) | (6, 3, 215, 376) | (228, 170.66, 215, 376) |
| `__auto_vscrollbar__` | (224, 1, 16, 380) | (446, 168.66, 16, 380) |

Item một dòng, chưa cuộn, chưa có thanh cuộn, mọi item hẹp hơn 231 (`w = max(231, widest) = 231`):

| | `S = 12` (cao item 17) | `S = 14` (cao item 19) |
|---|---|---|
| Ô item 0 | (6, 3, 231, 17) → màn hình (228, 170.66, 231, 17) | (6, 3, 231, 19) → (228, 170.66, 231, 19) |
| Ô item 1 | (6, 20, 231, 17) → (228, 187.66, 231, 17) | (6, 22, 231, 19) → (228, 189.66, 231, 19) |
| Ô item 2 | (6, 37, 231, 17) → (228, 204.66, 231, 17) | (6, 41, 231, 19) → (228, 208.66, 231, 19) |
| Ô chữ đưa cho `drawText` của item 0, 1, 2 (mép trên) | 5, 22, 39 | 5, 24, 43 |
| Mép trên ô glyph (`y_dòng`) của item 0, 1, 2 | 4, 21, 38 | 4, 23, 42 |
| Hàng bitmap của chữ item 0, 1, 2 | 5..16, 22..33, 39..50 | 5..18, 24..37, 43..56 |
| Cột bitmap đầu của chữ | x = 6 (ô glyph từ x = 5) | x = 6 |
| Nền item đang chọn (`CommonEditBoxBK` kéo giãn) | đúng ô item | đúng ô item |
| Thanh cuộn hiện từ item thứ | 23 (22 x 17 = 374 ≤ 376; 23 x 17 = 391) | 20 (19 x 19 = 361; 20 x 19 = 380) |
| Bước bánh xe | 37,6 | 37,6 |

Khi thanh cuộn hiện: ô item rộng `max(215, widest - 16)`; ví dụ 23 item cỡ 12: `doc = 391`, `page =
376`, vị trí tối đa 15; cuộn một nấc xuống đưa vị trí về 15 (kẹp), item 0 nằm ở `y = 3 - 15 = -12`
và bị vùng item cắt từ `y = 3`. Ô thanh cuộn, nút, rãnh và thumb của chính listbox này: mục 6.9.

`AddItem("...", 7, "FF00FF00")` rồi `GetFirstSelectItem()` sau khi bấm vào `y` cục bộ 25 (cỡ 12):
`getItemAtPoint` duyệt `3 + 17 = 20 ≤ 25`, `20 + 17 = 37 > 25` → item chỉ số 1; hàm trả ID của item
đó (số đã truyền cho `AddItem`), không trả 1.

### 9.2 Nút action `ActionSkill_Xinfa1` (`TLBB_ActionButton`), cửa sổ (94, 148, 34, 34)

| Lớp vẽ (theo thứ tự) | Ảnh | Ô trong nút | Ô màn hình |
|---|---|---|---|
| 1. `BackgroundImage` | `CommonItem/ActionBK` (34x34) | (0, 0, 34, 34) | (94, 148, 34, 34) |
| 4. icon (`NormalImage`) | icon của action, kéo giãn | (1, 1, 32, 32) | (95, 149, 32, 32) |
| 6b. `Pushed` khi `SetPushed(1)` hoặc đang nhấn | `CommonFrame/ActionButtonPushed` (30x30) | (1, 1, 32, 32) | (95, 149, 32, 32) |
| 6c. `Hover` khi chuột ở trên và không `Checked` | `CommonFrame/ActionButtonHover` (30x30) | (1, 1, 32, 32) | (95, 149, 32, 32) |
| 6f. `Disabled` khi `Gloom` hoặc bị vô hiệu | `Face_04/Remind_Bak` (32x32) | (1, 1, 32, 32) | (95, 149, 32, 32) |
| 6d/8. hoạt ảnh hồi chiêu, nháy | khung hoạt ảnh | `ActionArea` = (1, 1, 32, 32) | (95, 149, 32, 32) |

`SetActionItem(-1)`: chỉ còn lớp 1 (và `Hover` khi rê chuột). Chữ góc với phông cỡ `S` (`fh = S +
2`): góc dưới phải có ô `Rect(0, 34 - fh - 2, 32, 34)`, canh phải: `S = 12` → ô chữ từ `y = 18`,
`y_dòng = trunc(18 - 1 + 0.5) = 17`, hàng bitmap 18..29, mép phải của bút ở `x = 32`; `S = 14` → ô từ
`y = 16`, hàng bitmap 16..29. Góc trên trái: ô `Rect(2, 2, 34, 34)`, `y_dòng = 1`, hàng bitmap từ 2,
cột bitmap từ `x = 2`.

Nút action trong `QuestLog_Desc` (mục 9.3) cỡ 35x35: icon ở (1, 1, 33, 33).

### 9.3 `QuestLog_Desc` (`TLBB_ComplexWindow`), cửa sổ (473, 192.66, 260, 347)

| Thứ | Ô trong `QuestLog_Desc` | Ô màn hình |
|---|---|---|
| `__auto_parent__` (vùng nội dung) | (5, 5, 238, 337) | (478, 197.66, 238, 337) |
| `__auto_vscrollbar__` | (244, 0, 16, 347) | (717, 192.66, 16, 347) |

Bề rộng bẻ dòng 238; thanh cuộn hiện khi tổng cao > 337; bước bánh xe 33,7.

Một chuỗi dựng mẫu (toạ độ trong `__auto_parent__`, chưa cuộn), theo đúng thứ tự gọi của script:
`AddTextElement` 1 dòng, `AddTextElement` 3 dòng, `AddMoneyElement`, hai `AddActionElement(id, n,
0)` liền nhau (phần tử cuối):

| Phần tử | `y` trước | `S = 12` | `S = 14` |
|---|---|---|---|
| Text 1 dòng | 0 | rect (0, 0, 238, 14); `y` → 17 | rect (0, 0, 238, 16); `y` → 19 |
| Text 3 dòng | 17 / 19 | rect (0, 17, 238, 48); `y` → 68 | rect (0, 19, 238, 54); `y` → 76 |
| Money | 68 / 76 | `th = 19,6`; cửa sổ tiền (0, 68, 238, 20); `y` → 87,6 | `th = 22,4`; (0, 76, 238, 22); `y` → 98,4 |
| Action 1 (trước nó là Money: +10) | 87,6 / 98,4 | `y = 97,6`; nút (0, 98, 35, 35); `y` → 142,6; `x` → 45 | `y = 108,4`; nút (0, 108, 35, 35); `y` → 153,4 |
| Action 2 (cùng hàng: `y -= 45`; cuối: `y -= 10`) | 142,6 / 153,4 | nút (45, 98, 35, 35); `y` → 132,6 | nút (45, 108, 35, 35); `y` → 143,4 |
| `d_totalHeight` | | 132,6 (≤ 337: không thanh cuộn) | 143,4 |

Một hàng chứa được 5 nút (`x` = 0, 45, 90, 135, 180; nút thứ sáu có `225 + 45 > 238` nên xuống
hàng). Dòng chữ (cỡ 12): Text 1 dòng ở `Y = 0` có `y_0 = 0`, hàng bitmap 1..12; Text 3 dòng ở `Y =
17` có `t = 16`, `y_k = 15, 32, 49`, hàng bitmap 16..27, 33..44, 50..61.

### 9.4 Ví dụ nằm trong các mục khác

- `MissionTrack_ListBoxTransparent`, hai item đầu và hai nút của item: mục 1B.6 (cột "cỡ 12" là
  client thật; ở trang mã 936 chữ bẻ theo ký tự).
- Thanh cuộn của `QuestLog_Listbox` và của MissionTrack (ô thanh, nút, rãnh, thumb): mục 6.9.
- `QuestLog_Amount` ("12/20") và `ActionSkill_EffectNotice` (2 dòng): mục 5 E.
- Ô tiền `ActionSkill_LearnDemand_Jiaozi`: mục 4.3 để dạng công thức theo `w(s)`, `th`. Thay số
  (ghép mục 4.2 với mục 5 C.2, C.4; chữ số ASCII của GBK12 có advance 6): cửa sổ (240, 317, 131,
  18), canh trái, `S = 12`, `th = 14`, bề rộng đo của `getLineSize` là `(số ký tự - 1)*6 + 13`:

| `MoneyNumber = 12345` | Ô (x, y, w, h) trong cửa sổ | Ghi chú |
|---|---|---|
| ô chữ `1` | (0, 4, 13, 14) | chữ canh phải trong ô: bút ở `x = 13 - 6 = 7`; `y_dòng = 3`, hàng bitmap 4..15 |
| icon vàng | (13, 2, 16, 16) | |
| ô chữ `23` | (29, 4, 19, 14) | bút ở `x = 48 - 12 = 36` |
| icon bạc | (48, 2, 16, 16) | |
| ô chữ `45` | (64, 4, 19, 14) | bút ở `x = 83 - 12 = 71` |
| icon đồng | (83, 2, 16, 16) | tổng rộng 99 |

  `MoneyNumber = 0`: ô chữ `0` (0, 4, 13, 14) với bút ở `x = 7`, icon đồng (13, 2, 16, 16).

---

## 10. Ghép các phần: chỗ mục này trả lời "chưa xác định" của mục kia

Các mục 1B, 4, 5, 6, 7 do ba lượt phân tích song song viết; phiên chính đã kiểm chéo bằng cách tháo
lại một số địa chỉ (mục 1B: hằng 1,5 ở Fal 0x1800cfb05, cỡ nút 14x13 và 16x10 ở 0x1800cfc5e và
0x1800cfcef, 500 ms ở 0x1800cec19, bảng ký tự ngắt Base 0x1801e7368; mục 4: hằng 4,0 ở Fal
0x18008297e, `MoneyMaxNumber` ở 0x1800829a4; mục 7: `Step = -1` ở Fal 0x1800baa58, `drawSelf` của
checkbox ở 0x1800d2cf2..0x1800d2d45; mục 5: dời 1 điểm ảnh của phông bitmap ở Base
0x18004aac4..0x18004aaf5, lọc `CodePage` ở 0x180134fb9). Phần Listbox nền được hai lượt đọc độc lập
(mục 1 và mục 1B) và khớp nhau từng độ dời. Các điểm sau đọc mục này mới trả lời được mục kia:

- Mục 1B.7 khoản 5 và mục 6.4 ("độ lớn và dấu của `wheelChange`"): mỗi sự kiện là `+1` (lăn lên) hoặc
  `-1` (lăn xuống), mục 0. Lăn lên giảm vị trí cuộn.
- Mục 1B.7 khoản 5 ("phép kẹp của `setScrollPosition`"): mục 1.3 và mục 6.4. Cỡ thumb cố định theo
  look: mục 6.5.
- Mục 1B.2.3 và 1B.7 khoản 3 (trang mã lúc chạy): luôn 936 ở bộ DLL này (mục 0, mục 5 A.1), nên
  MissionTrack của client thật bẻ dòng THEO KÝ TỰ; nhánh "lùi tới ký tự ngắt" chỉ chạy khi dự án tự
  chọn trang mã khác. Trần lùi 13 của `getWrappedSize` tính cả ký tự làm tràn, bằng trần 12 của
  `drawWrappedText` (mục 5 C.6): hai hàm bẻ cùng chỗ.
- Mục 1B.7 khoản 1 (`Font::drawText` lúc vẽ): mục 5 C.4 đến C.6.
- Mục 1B.7 khoản 2 (cờ `Window+0x308`): thuộc tính `ColorTrans` (mục 0).
- Mục 6.8 ("nơi đọc `IsChangeToZero` chưa rà"): `FalagardComplexWindow::configureScrollbars` đọc
  thẳng `Scrollbar+0x404` (Fal 0x180073941) và `ParentWindow::onMouseWheel` đặt nó (Fal 0x1800742ee),
  mục 3.5.
- Mục 4.3 (`w(s)`, `th`): mục 9.4.
- Mục 7.3 mô tả `ButtonBase::drawSelf` cho nút thường và checkbox; nút action KHÔNG đi qua hàm đó mà
  có `drawSelf` riêng chồng lớp (mục 2.3). Luật `ActionArea` của `drawNormal` được mục 2.4 và mục
  7.3 đọc độc lập và khớp nhau.
- Mục 5 G (ghi chú cho phiên chính về `ListboxTextItem`): đã có ở mục 1.4, 1.5.

---

## 11. `SRC/gui` và `SRC/ui` hiện có so với mã máy 2026 (tổng hợp)

Chi tiết và địa chỉ ở các mục đã dẫn; đây chỉ là danh sách để lên việc.

Đối chiếu với mã ngày 2026-10-08 (`main` ở `501743a`, sau các commit `108a504`, `5934a9a`,
`63fe94d`, `386607b`): danh sách dưới viết TRƯỚC khi các việc ấy vào mã, nên một phần đã xong.

- Điểm 1 đã làm cho năm kiểu chủ: `kChildHosts` của `SRC/gui/loader.cpp` dựng `<Child>` cho
  Listbox, ListBoxEx, ComplexWindow, StaticText, Scrollbar; Combobox, ChatHistory, Star thì chưa.
- Điểm 2: `Falagard/Listbox` nay là `kList` (`kExactKinds` của `SRC/gui/layout.cpp`), có bộ vẽ ở
  `SRC/gui/widgets.cpp`; `Falagard/ListBoxEx` vẫn `kPlain`.
- Điểm 3 đã làm: nút action đi `draw_action` và đặt icon vào `ActionArea`; chữ góc, hồi chiêu và
  nháy thì chưa.
- Điểm 5: `Falagard/ComplexWindow` nay là `kComplex`.
- Điểm 6: `Falagard/Thumb` là `kThumb`; `Falagard/Money` vẫn chưa có bộ vẽ.
- Điểm 7: `Falagard/DragTitle` là `kText`; `StaticText` và `StopWatch` vẫn `kPlain`.
- Điểm 8 đã làm: chữ SimpleText đặt trong `NamedArea TextArea` của look khi có (`SRC/gui/text.cpp`).
- Điểm 9 đã làm: bộ viết chữ port lại theo mục 5 (dòng "Khác gốc" đầu `SRC/ui/text.hpp` ghi phần
  còn lệch).
- Điểm 4 chưa đối chiếu lại. Bộ vẽ danh sách và cửa sổ phức hợp mới chạy trong test: client thật
  chưa đưa mục nào vào (`docs/NGHI-NGO.md` mục 43).

1. `layout()` chưa dựng cửa sổ con `<Child>` của look (thanh cuộn, `__auto_parent__`, nút, thumb);
   `WidgetDim widget="__auto_vscrollbar__"` cần ô của con đó (mục 6.10).
2. Listbox (`Falagard/Listbox`, `Falagard/ListBoxEx`) đang là `kPlain`: nền và khung vẽ được, chưa
   có item, chọn, cuộn (mục 1, 1B). Cần trạng thái ngoài bộ vẽ: danh sách item (chữ, ID, màu, định
   dạng, kiểu), item đang chọn, item vừa bấm, vị trí cuộn.
3. Nút action đang đi `draw_button` (một state + một ảnh, icon kín cửa sổ): phải chồng lớp theo mục
   2.3 và đặt icon vào `ActionArea` (mục 2.4). Lệch 1 điểm ảnh này đang có ở mọi nút action của HUD.
4. Nút thường và checkbox: không lùi về `NormalImage` khi thiếu `HoverImage`/`PushedImage`; có
   `DisabledImage`; checkbox đang chọn vẽ `Pushed` kể cả khi bị vô hiệu (mục 7.3).
5. `Falagard/ComplexWindow` là `kPlain` và look không có state: hiện không vẽ gì (mục 3).
6. `Falagard/Money`, `Falagard/Thumb` chưa có bộ vẽ (mục 4.5, 6.10).
7. `Falagard/StaticText`, `Falagard/DragTitle`, `Falagard/StopWatch` là `kPlain` nên không ra chữ của
   cửa sổ (mục 5 D.2, 7.1, 7.2).
8. `simple_text()` lấy cả cửa sổ làm ô chữ; mã máy dùng `NamedArea TextArea` khi look có và vẽ state
   `Enabled` (mục 5 D.1).
9. Bộ viết chữ `SRC/ui/text.cpp`: bước dòng `S + 2` thay vì `S + 5`, vị trí dọc, `+1` khi canh giữa
   ngang, advance `+1` của glyph rộng đúng `S`, luật bẻ dòng, bảng thẻ (mục 5 F, mười điểm).

---

## 12. Phần chưa xong, theo thứ tự ưu tiên của đề bài

1. **Listbox.** Đã chắc: lớp, look, vùng item, cao item, thứ tự vẽ, nền chọn, điều kiện và cỡ thanh
   cuộn, cuộn theo điểm ảnh, bánh xe, dò item, sự kiện, toàn bộ phương thức Lua mà script gọi. Chưa:
   các phương thức Lua script không gọi (`GetItem`, `DelItem`, `SetListItemText`...); cách cộng phần
   lẻ của toạ độ cửa sổ ra màn hình; hành vi vẽ khi vị trí cuộn lẻ chỉ suy từ công thức `trunc` (chưa
   chụp client thật). ListBoxEx (mục 1B): kiểu item 4..9 và 12, nút đóng có bị cắt ở mép phải không,
   hàm gọi `CListBoxExManager::Tick` có phải mỗi khung không.
2. **Nút action.** Đã chắc: thứ tự vẽ, ô icon, lớp phủ, chữ góc, chuột, `SetActionItem`,
   `SetPushed`, `SetNewFlash`. Chưa: `updateAnimate` (Fal 0x1800acb40, hồi chiêu, `setShowCD`,
   `CoolDownEnd`), `setAnimate`, `setPercentageImage`; ý nghĩa `item->vtable[0xB8]()` trong Game.exe
   (điều kiện nháy); ý nghĩa cờ `+0x979`; mã `0xFFFFFFFF`/`0xFF00FFFF` ghi vào đầu chuỗi góc thứ 5, 6;
   kiểu kéo giãn của `NormalImage` chỉ theo mã 2008; SuperTooltip (do Game.exe mở) ngoài phạm vi.
3. **Cửa sổ phức hợp.** Đã chắc: xếp dọc mọi loại phần tử, hằng số, thanh cuộn, nhớ vị trí cuộn,
   vẽ chữ, `AddTextElement`, `AddActionElement`, `AddMoneyElement`, `AddJiaoZiElement`,
   `ClearAllElement`, `SetScrollPosition`, `ResetScrollPosition`, `PageEnd`. Chưa: tham số Lua và
   chi tiết dựng của `AddItemElement`, `AddOptionElement` (cửa sổ nào ở `+0xA0`, `+0xA8` chỉ suy từ
   cỡ), `AddChatBoardElement`, `AddImpactElement`, `SetActionElementCheck`, `RemoveTopElement`,
   `SetTextColour`; look của `TLBB_QuestButton`, `TLBB_RewardItem`; xử lý khi tên cửa sổ con đã tồn
   tại.
4. **Ô tiền.** Xem cuối mục 7 (khoản 2): hàm `set` của các thuộc tính `Money*`, `AlignFix` chưa tháo.
5. **Chữ.** Xem mục 5 G: số đo phông FreeType thật (DPI), mã `0xE8`/`0xE4`/`0xE5`, gạch chân, nháy,
   đường đi của chuỗi `Text` trong layout XML qua bộ phân tích, tham số `bool a` của `drawText`.
6. **Thanh cuộn.** Xem cuối mục 7 (khoản 1): "giữ nút lên/xuống không cuộn tiếp" là suy luận chưa
   thử trên client; số viên lát của rãnh chỉ theo mã 2008; đoạn cuối `WidgetComponent::layout`.
7. **StopWatch, DragTitle, checkbox.** Xem cuối mục 7 (khoản 3): cờ `+0x6E0` khi kéo cửa sổ, kẹp
   trong màn hình, thứ tự chồng ảnh thuộc tính và chữ nhãn.

Chưa làm ở mọi mục: chạy client thật để chụp đối chiếu từng điểm ảnh. Mọi kết luận ở đây là đọc mã
máy tĩnh; chỗ nào là suy luận từ nhiều hàm đã ghi rõ tại chỗ.

Tệp nháp (bản tháo theo hàm, script đọc bảng) nằm ở `build/scratch/gui/`: tiền tố `lb_`, `ab_`,
`cw_`, `fal_`, `font_`, `ui_`, `vt_` (phiên chính), `lbx_` (mục 1B), `txt_` (mục 5), `sm_` (mục 4,
6, 7); `lua_table.py` và `lua_methods.txt` (bảng phương thức Lua), `peek.py` (đọc byte của PE).
