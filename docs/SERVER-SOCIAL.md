# Lõi xã hội của máy chủ: đội, bang, thành phố, quan hệ, thư, chat, xếp hạng, thông báo

Đọc tài liệu này là đủ để nối module `social` vào tiến trình `world` mà không cần mở mã. Mọi thứ ở đây là lõi thuần: không mạng,
không database, không đồng hồ thật, không `<random>`, không `throw`, không đọc đĩa (bảng đến dưới dạng `std::string_view`).
Trạng thái do bên gọi (world) sở hữu; mỗi thao tác trả danh sách sự kiện có kiểu để world phát tới client. Thời gian là `ids::Tick`
(20 tick/giây, `social::kTicksPerSecond`). Mã ở `src/server/social/`, test ở `Test/Social/`, công cụ nhập bảng ở
`TOOLS/server/import_social.py`. Thứ bậc nguồn: client 2026, rồi mã 2008 (`G:\TLBB\_ref\server\Server`), rồi cấu hình XJL7457.

## 1. Bản đồ

| Tệp | Việc |
|---|---|
| `types.hpp` | `Outcome<Event, Error>`, các id mạnh (`MailId`, `CityId`, `BoardId`, `ChannelId`, `CustomChannelId`, `LeagueId`), `Copper`, `add_clamped` |
| `directory.hpp` | `PlayerDirectory` (world cài đặt: `find`, `find_by_name`, `hostile`), `PlayerCard`, cờ cài đặt `setting::*` |
| `policy.hpp`, `text.hpp` | `TextPolicy`/`TextFilter` (cổng kiểm chữ), `is_plain_text`, `codepoint_count`, `has_edge_space`, `fold_name` |
| `wordfilter.hpp` | `WordFilter` (bộ lọc chữ cấm Aho-Corasick), `NamePolicy`, `NameKind` |
| `limits.hpp` | `Limits` (đọc từ `social_limits.tsv`), `GuildRules`, `RelationRules` |
| `team.hpp` | `TeamBook`: đội |
| `relation.hpp` | `RelationBook`, `RelationSheet`, `MentorTable`, `apply_offline_change`: bạn, đen, thù, tạm, vợ chồng, sư đồ |
| `guild.hpp` | `GuildBook`, `WarPointTable`: bang, chức vị, quyền, quỹ, bang chiến, liên minh |
| `city.hpp` | `CityCatalog`, `CityBook`: thành phố, nha môn, công trình |
| `mail.hpp` | `MailBook`, `AttachmentPort`: thư, đồ đính kèm hai pha, thu tiền (COD), trả thư, hết hạn |
| `chat.hpp` | `ChatCatalog`, `ChatBook`: kênh, quyền gửi, nhịp, chống lặp, kênh tự lập |
| `rank.hpp` | `RankBook`: nhiều bảng xếp hạng, ảnh chụp định kỳ |
| `notice.hpp` | `NoticeSchedule`, `NoticeBook`: thông báo theo ngày/thứ, luân phiên, riêng lúc vào game |
| `codec.hpp` | khung bền có phiên bản cho bang, liên minh, sổ quan hệ, hộp thư, bảng xếp hạng, thành phố |

Tầng: `social` chỉ biết `core table ids protocol` (`cmake/GameLayers.cmake`). Nó không include `net`/`store` và không biết kết nối.

## 2. Nguyên tắc chung

**Kết quả có kiểu.** Mọi thao tác ghi trả `Outcome<Event, Error>{events, error}` (`TeamResult`, `RelationResult`, `GuildResult`,
`CityResult`, `MailResult`, `ChatResult`, `RankResult`). `error` có giá trị nghĩa là dữ liệu xã hội KHÔNG đổi, trừ một ngoại lệ:
lời mời/đơn xin đang chờ mà người ra lệnh vừa trả lời thì bị tiêu thụ dù lệnh lỗi (nó đã cũ). Lệnh lỗi vẫn có thể mang sự kiện cho
bên thứ ba (đội đầy: người mời nhận thông báo, người trả lời nhận lỗi). Mỗi sự kiện có `audience`/`recipients`: world chỉ việc
gửi tới đúng những người đó, không tự suy.

**Đầu vào thù địch.** Id, tên, chữ, số lượng đến từ client hay từ database đều được kiểm tồn tại, quyền, biên và trần trước khi đổi
trạng thái; không nơi nào đưa chúng vào `check`/`assert`/`.at()`. Chữ phải qua `is_plain_text` (UTF-8 chặt RFC 3629, không ký tự
điều khiển) và bộ lọc chữ cấm. Khối đọc từ kho có sai một byte là trả `CodecError`, không bao giờ assert.

**Lời mời được ghi nhớ.** Lời mời đội, xin vào đội, kết bạn, kết hôn, bái sư, xin vào bang, mời liên minh đều có hạn và được lõi nhớ,
nên gói "trả lời" giả mạo cho người chưa từng mời bị từ chối (2008 chỉ chuyển tiếp gói nên lọt).

**Tất định.** Cùng chuỗi lời gọi, cùng bảng cho cùng kết quả. Thứ tự sự kiện cố định; không phụ thuộc `unordered_*`, đồng hồ thật
hay phân phối của `<random>`. Giới hạn nhịp chat dùng GCRA đếm tick.

**Tiền và đồ không biến mất, không nhân đôi.** Lõi không giữ tiền hay đồ của người chơi. Nó kiểm đủ rồi báo world trừ/cộng qua
sự kiện hoặc qua `AttachmentPort`. Chi tiết ở mục 5.4 và 5.5.

**Bất biến.** Mỗi sổ có `validate()` trả `std::expected<void, std::string>` (thông báo tiếng Việt); test mô phỏng gọi nó sau mỗi lô
thao tác. World có thể gọi nó ở bản debug hoặc sau khi nạp.

## 3. Nối vào world

### 3.1 Khởi động

1. Đọc `social_limits.tsv` và gọi `parse_limits` ra `Limits`. Đọc `rules/guild.toml`, `rules/social.toml` rồi điền `GuildRules`,
   `RelationRules` (lõi không đọc TOML để số chỉ nằm một nơi). Điền `GuildRules::battle_minutes` từ `battle_time` (đơn vị phút là giả
   định, mục 7).
2. `WordFilter::parse({text_filter.tsv, full_compare_filters.tsv, chat_blocked_words.tsv})` ra `unique_ptr<WordFilter>` (giữ sống suốt
   đời tiến trình). `NamePolicy{filter, NameKind::kGuild}` cho tên bang/liên minh/chức vị; chính `WordFilter` là `TextFilter` cho chat
   và `TextPolicy` cho tiêu đề/nội dung thư và tâm trạng.
3. Dựng các sổ: `TeamBook{limits}`, `RelationBook{limits, relation_rules}`, `GuildBook{limits, guild_rules, name_policy}`,
   `CityCatalog::parse({guild_cities.tsv, city_buildings.tsv})` rồi `CityBook{guild_rules, catalog}`, `MailBook{limits, policy}`,
   `ChatBook{limits, ChatCatalog::parse(chat_channels.tsv), filter}`, `RankBook{limits}`,
   `NoticeBook{limits, NoticeSchedule::parse(limits, {...}), NoticeRules{rolling_interval_ms, declared_only}}`.
4. `parse_rank_boards(rank_boards.tsv)` rồi `RankBook::define_all(now, defs)`; sau đó `RankBook::load` từng khối đọc từ kho.
5. Nạp từ kho: mọi bang (`decode_guild` rồi `GuildBook::load_guild(guild, now)`), mọi liên minh (`decode_league`, `load_league`), mọi thành
   phố (`decode_city`, `CityBook::load`). Gọi `GuildBook::set_next_ids(...)` và `MailBook::set_next_mail_id(...)` bằng số world đã lưu
   (id không tái sử dụng sau khi khởi động lại). Nạp xong gọi `GuildBook::validate()`, `CityBook::validate(guilds)`, `RankBook::validate()`.
   Một khối không giải mã/nạp được là lỗi dữ liệu: ghi log, KHÔNG ghi đè khối trong kho bằng bản rỗng, và đừng chạy tiếp với bang đó.
6. `NoticeBook::set_last_daily_date(...)` bằng ngày world đã lưu, để khởi động lại sau 08:00 không phát lại thông báo của ngày.

Khởi động lại bắt đầu đếm tick từ 0; mọi hạn được lưu dưới dạng tuổi hoặc thời gian còn lại rồi dựng lại theo `now` lúc nạp.

### 3.2 Người chơi vào/ra

| Lúc | Việc |
|---|---|
| Vào game | `RelationBook::load(id, sheet)` (sổ từ kho, `decode_relation`), `MailBook::load(id, box)` (`decode_mailbox`); `RelationBook::on_presence(dir, id, true)` để báo bạn; `NoticeBook::on_login(facts)`; `TeamBook::on_reconnect(id)` nếu còn giữ chỗ trong hạn; `GuildBook::refresh_member(card)` |
| Ra game (rớt mạng) | `TeamBook::on_disconnect(now, id)` (giữ chỗ `team.offline_grace_seconds`) |
| Ra game (thoát hẳn) | `TeamBook::on_logout(id)`, `ChatBook::on_logout(id)`, `RelationBook::on_presence(dir, id, false)`, rồi `RelationBook::unload(id)` và `MailBook::unload(id)` lấy sổ/hộp ra `encode_*` ghi kho |
| Lên cấp, đổi phái | `GuildBook::refresh_member(card)`; nếu là đồ đệ: `RelationBook::on_prentice_level(dir, mentor_table, id, level)` |
| Bị xoá nhân vật | `RankBook::forget(id)` |

Chỉ người đã được world nạp sổ/hộp thì mới nhận được kết quả thật: gửi thư hay kết bạn với người chưa nạp trả `kNotLoaded`. World nạp
sổ/hộp của người trực tuyến, và nạp hộp của người sắp nhận thư (từ kho) trước khi gọi `MailBook::send`.

### 3.3 Nhịp

| Hàm | Gọi |
|---|---|
| `TeamBook::tick(now)`, `GuildBook::tick(now)`, `ChatBook::tick(now)` | mỗi tick hoặc thưa hơn (hạn tính theo tick; việc thật của chat chạy mỗi giây) |
| `RelationBook::tick(now)`, `MailBook::tick(now)` | vài giây một lần (duyệt mọi sổ/hộp đang nạp) |
| `RankBook::tick(now)` | vài giây một lần (chỉ chụp bảng đến hạn) |
| `NoticeBook::tick(now, WallClock)` | mỗi tick, với `WallClock` world đọc từ đồng hồ giờ máy chủ |

Mỗi hàm trả danh sách sự kiện (hoặc `void`) để world phát đi.

### 3.4 Việc world phải làm khi nhận sự kiện

- `RelationEventKind::kOfflineChange` (`audience` rỗng; `subject` = người ra lệnh; `other` = chủ sổ ngoại tuyến; `value` = kiểu mới, 0 = xoá):
  đọc sổ ĐÃ LƯU của `other` từ kho, gọi `apply_offline_change(limits, sheet, event)`, ghi lại. Không làm thì khi `other` vào lại, hai
  phía lệch nhau và `RelationBook::validate()` báo lệch hai chiều.
- `GuildEventKind::kCreated` (`value` = phí): trừ phí của người lập (lõi chỉ kiểm `wallet` đủ). `kDeposited`/`kWithdrawn` (`value`): trừ/cộng
  tiền người chơi. `league_create` cũng chỉ kiểm `wallet`; trừ `league_create_cost` theo sự kiện `kLeagueCreated`.
- `ChatEventKind::kCharge`: trừ `amount` của `resource` (MP, tinh lực, hoạt lực) của `subject`. Kênh có `needs_item` (loa) thì world phải kiểm
  và trừ vật phẩm loa, lõi không biết kho đồ.
- `RelationEventKind::kMentorReward`: cộng `value` kinh nghiệm cho sư phụ.
- `TeamBook::next_looter`, `members_in_scene`: dùng khi zone chia đồ/kinh nghiệm.

## 4. Bảng đọc

| Tệp (dev/server/tables) | Ai đọc | Số dòng dữ liệu |
|---|---|---|
| `server/social_limits.tsv` | `parse_limits` | 57 khoá |
| `shared/chat_channels.tsv` | `ChatCatalog::parse` | 25 kênh |
| `shared/text_filter.tsv` | `WordFilter` | 147205 dòng (type 1 từ cấm; 2/3 tên dành riêng; 11/12 mẫu lớp ký tự) |
| `shared/full_compare_filters.tsv` | `WordFilter` (tên dành riêng, so toàn chuỗi) | 679 dòng |
| `server/chat_blocked_words.tsv` | `WordFilter` | 340 từ (bảng sinh) |
| `shared/guild_cities.tsv` | `CityCatalog` | 216 thành phố |
| `shared/city_buildings.tsv` | `CityCatalog` | 4104 công trình |
| `server/guild_war_points.tsv` | `WarPointTable` | 7 mã sự kiện |
| `server/mentor_exp_rewards.tsv` | `MentorTable` | 6 hàng thưởng |
| `shared/mentor_exp_share.tsv` | `MentorTable` | 150 hàng hệ số chia |
| `server/notices_by_date.tsv` | `NoticeSchedule` | 40 dòng |
| `server/notices_by_weekday.tsv` | `NoticeSchedule` | 7 dòng |
| `server/notices_on_login.tsv` | `NoticeSchedule` | 12 dòng |
| `server/rolling_announcements.tsv` | `NoticeSchedule` | 10 dòng |
| `server/rank_boards.tsv` | `parse_rank_boards` | 4 bảng (sinh) |
| `config/rules/guild.toml`, `rules/social.toml` | world điền `GuildRules`, `RelationRules` | không thuộc bảng này |

`Test/Social/social_tables_tests.cpp` nạp đúng các bảng thật này và so với số vàng độc lập (nó bỏ qua và in thông báo nếu thiếu thư mục
bảng, không đỏ giả).

### 4.1 Bảng sinh bởi `import_social.py`

```
python TOOLS/server/import_social.py <gốc dev/server> <gốc tlbb của XJL7457>          # ghi bảng
python TOOLS/server/import_social.py <gốc dev/server> <gốc tlbb của XJL7457> --check  # chỉ kiểm, lệch thì mã thoát 1
python -B -m unittest discover -s TOOLS/server -p "test_import_social.py"
```

- `chat_blocked_words.tsv`: từ cấm của máy chủ gốc (`Server/Config/Filt.txt` 2-cột GBK và `FiltV2.txt`) mà `text_filter.tsv` của client
  (dòng type 1) chưa có. 683 từ ở hai tệp, 2 lượt đã có ở client, nhập 340 (339 ở cả hai tệp, 1 chỉ ở `Filt.txt`). Từ quá 256 ký tự bị bỏ
  (trần của `WordFilter`). Cột `origin` ghi `filt`, `filt_v2` hoặc `filt+filt_v2`.
- `rank_boards.tsv`: khung các bảng mà `ScriptGlobal.lua` (`SetPaimingold`/`GetPaimingold`) đọc/ghi, khoá bảng 1/11/12/13 tới tệp
  `chongzi`/`axchongzi`/`bxchongzi`/`cxchongzi`, 10 dòng mỗi bảng. Hai hàm phải ánh xạ giống nhau, không thì dừng. Dòng người chơi trong
  tệp `Paiming/*.txt` là dữ liệu vận hành của một máy chủ đã chạy, không nhập.
- Đầu vào hỏng dừng với thông báo `tệp:dòng`, không ghi gì.

### 4.2 Đăng ký bảng

Ba bảng mới của module này CHƯA có hàng trong `TOOLS/server/table_names.tsv` (cấm sửa trong đợt này): `chat_blocked_words`, `rank_boards`,
`social_limits`. Điều phối cần thêm ba hàng đó. `thienlong_lint` chạy trên gốc chỉ có ba bảng này không báo lỗi nội dung nào.

## 5. Từng module

### 5.1 Đội (`TeamBook`)

- Lệnh: `invite`, `answer_invite`, `leader_answer_invite`, `apply`, `answer_apply`, `leave`, `dismiss`, `kick`, `appoint`, `set_exp_mode`,
  `set_loot_mode`, `report_vitals`, `set_scene`, `start_follow`, `stop_follow`.
- Vòng đời: `on_disconnect`, `on_reconnect`, `on_logout`, `tick`.
- Truy vấn: `team_of`, `find`, `leader_of`, `applicants_of`, `inviters_of`, `members_in_scene`, `next_looter`.
- Tối đa `team.max_members` = 6; đội trưởng luôn đứng đầu danh sách. Mời từ thành viên thường đi qua đội trưởng trước
  (`kLeaderAskInvite`, `leader_answer_invite`). Tự mời mình là "tự lập đội".
- Đội trưởng rớt mạng: nhường cho người trực tuyến kế tiếp (`kLeaderChanged`). Người rớt mạng giữ chỗ tới hết `offline_grace`.
- Mã lỗi `client_code(TeamError)`: 0..20 là `TEAM_ERROR_*` của 2008, 255 cho lỗi lõi tự thêm.
- Chia đồ (`LootMode`) là cơ chế tối thiểu của lõi (mục 7.1).
- Không có khối bền: đội là trạng thái tạm, mất khi world dừng.

### 5.2 Quan hệ (`RelationBook`)

- Sổ gồm bạn (4 nhóm, 20 người/nhóm, tối đa 80), đen (20), thù (20), tạm (20), vợ/chồng, sư phụ, đồ đệ (tối đa 2), tâm trạng (25 byte), điểm sư đức.
- Lệnh: `request`/`answer` (BondKind: kết bạn, kết hôn, nhận đồ đệ, bái sư), `remove`, `blacklist`, `note_enemy`, `note_temp`, `move_group`,
  `set_mood`, `add_point`, `divorce`, `leave_master`, `expel_prentice`, `on_prentice_level`, `on_presence`.
- Xoá bạn từ mức thân thiết `password_intimacy` (500, `social.toml`) cần `verified = true` (world đã kiểm mật khẩu cấp hai), không thì `kNeedVerify`.
- Báo lên/xuống tuyến cho bạn có thân thiết >= `presence_intimacy`.
- Đổi quan hệ với người ngoại tuyến: xem mục 3.4 (`kOfflineChange` + `apply_offline_change`).
- Thưởng sư đồ: `MentorTable` (6 hàng thưởng theo cấp đồ đệ, 150 hệ số chia). Mỗi hàng chỉ nhận một lần (bit trong `milestones`).
- Khối bền: `encode_relation`/`decode_relation` (`blob::kRelation`, phiên bản 1). Hạn chờ phản sư lưu là số tick còn lại.

### 5.3 Bang, thành phố

`GuildBook`:
- Bang: `create`, `apply`, `cancel_application`, `answer_application`, `expel`, `leave`, `appoint`, `toggle_power`, `demise`, `dismiss`,
  `set_description`, `rename_position`, `deposit`, `withdraw`, `refresh_member`.
- Bang chiến: `declare_war`, `add_war_points` (`WarPointTable`). Liên minh: `league_create`, `league_invite`, `league_answer`, `league_leave`,
  `league_kick`, `league_disband`.
- Chín chức (`GuildPosition`), mười quyền (`power::*`; `power_string` cho `GetMyGuildPower` của client). Người bổ nhiệm phải cao chức hơn cả người được bổ nhiệm
  lẫn chức mới. Bốn quyền gắn với chức (`kReserved`) không trao/thu bằng điều chỉnh quyền.
- Hạn ngạch chức: tinh anh 10, thương/nông/công/nhân sự mỗi chức 4. Trần thành viên theo cấp nha môn (`member_cap`), trần quỹ (`funds_cap`).
- `client_code(GuildError)`: số âm của `GUILD_ERROR_*`, 0 cho lỗi lõi tự thêm.
- Khối bền: `encode_guild`/`decode_guild` (`blob::kGuild`), `encode_league`/`decode_league` (`blob::kLeague`), phiên bản 1. Thành viên bang nằm trong khối bang.

`CityBook`: `claim`, `release`, `upgrade_county`, `upgrade_building`. Nó tự gọi `GuildBook::set_county` nên world không cần. Phí lập thành
(`city_cost`) trừ thẳng quỹ bang, không về túi ai. Khối bền: `encode_city`/`decode_city` (`blob::kCity`, phiên bản 1), mỗi thành phố một khối.

### 5.4 Thư (`MailBook`)

- `send` (chỉ cho bạn, cấp 50, phí 2000), `send_system` (không phí, đồ do hệ thống tạo), `mark_read`, `remove`, `claim`, `return_to_sender`, `tick`.
- Hộp tối đa 15 thư. Đính kèm tối đa 5 vật phẩm, 1 trân thú, tiền kèm, tiền thu (COD).
- **`AttachmentPort` (world cài đặt) hai pha:** `reserve` (kiểm chủ sở hữu, đủ tiền cho tiền kèm + phí, khoá), rồi `commit` khi thư đã vào hộp người nhận
  hoặc `release` khi không giao được. Đồ không bao giờ vừa mất vừa nhân đôi. `claim(recipient, payload, cod)` do người nhận lấy đồ: world kiểm chỗ và tiền COD, chuyển, trừ COD.
  Giữ chỗ nhiều lần cho cùng người gửi phải cộng dồn (bản giả của test `social_port.hpp` làm mẫu).
- Tiền COD người nhận trả được gửi cho người gửi bằng một thư hệ thống có tiền.
- Thư có đồ không xoá được và không tự hết hạn: hết hạn thì trả người gửi; người gửi không nhận được (hộp đầy hay chưa nạp) thì thư ở lại, nhịp sau thử lại.
- Khối bền: `encode_mailbox`/`decode_mailbox` (`blob::kMailbox`, phiên bản 1). Tuổi thư lưu là số tick đã trôi.

### 5.5 Chat (`ChatBook`)

- `send` (kiểm câm, cấp, tiêu hao, UTF-8, độ dài, nhịp riêng kênh + nhịp chung, chống lặp, quyền kênh, lọc chữ cấm, vô hiệu token), `announce`
  (máy chủ phát, không lọc, không nhịp), `mute`/`muted`, kênh tự lập (`create_channel`, `invite`, `kick`, `leave`, `dismiss`, `on_logout`), `tick`.
- `ChatAudience`: `kRecipients` (lõi tự liệt kê: đội, bang, liên minh, kênh tự lập, thì thầm, tự thân) hoặc `kNearby`/`kEverybody`/`kSect`/`kExternal` (world phân phối theo vị trí/hệ thống).
- Kênh chỉ-máy-chủ (hệ thống, thông báo cảnh, loa máy chủ) trả `kServerOnly` cho client.
- Số thứ tự tin `ChatEvent::serial` tăng dần toàn thế giới. Không có khối bền: câm và kênh tự lập mất khi world dừng.

### 5.6 Xếp hạng (`RankBook`)

- `define`/`define_all`, `submit` (ghi điểm; người đã có dòng thì thay điểm), `forget`, `tick` (chụp ảnh đến hạn), `settle` (chốt kỳ), `rank_of`, `published_rank_of`, `load`, `validate`.
- Client xem ảnh đã công bố (`published`), không xem bảng sống. Hoà điểm: ai đạt điểm trước (tick `since`) đứng trên, rồi id nhỏ trước.
- Khối bền: `encode_rank`/`decode_rank` (`blob::kRank`, phiên bản 1), mỗi bảng một khối, chừng 300 dòng (khối tối đa 64 KiB); lớn hơn trả `kTooLarge` và bên gọi chia bảng.
  Khi nạp lại sau khi bộ đếm tick về 0, `since` bị kẹp về 0 và thứ tự hoà điểm được dựng lại theo `restore_tie_order`.

### 5.7 Thông báo (`NoticeBook`)

- `tick(now, WallClock)`: phát thông báo theo ngày/thứ khi đồng hồ qua phút `notice.daily_broadcast_minute`, mỗi ngày một lần; thông báo luân phiên mỗi `rolling_interval_ms`.
- `on_login(LoginFacts)`: dòng riêng lúc vào game theo mode (0 hiện thẳng; 1/2 chỉ khi có chữ; 3 đúng ngày sinh nhật; 4 và 5 "lần đăng nhập trước" cần 8 chỗ `%d`).
- Chữ trong bảng là chữ của máy chủ nên giữ nguyên `#` và màu; không bao giờ ghép chữ người chơi vào.
- `last_daily_date()`/`set_last_daily_date()`: world lưu để khởi động lại giữa ngày không phát lại.

## 6. Khối bền

| Khối | `kind` | Hàm | Ghi chú |
|---|---|---|---|
| Bang | 0x5101 | `encode_guild`, `decode_guild` | gồm thành viên và đơn xin vào |
| (bỏ trống) | 0x5102 | | thành viên bang nằm trong khối bang |
| Sổ quan hệ | 0x5103 | `encode_relation`, `decode_relation` | một khối mỗi nhân vật |
| Hộp thư | 0x5104 | `encode_mailbox`, `decode_mailbox` | một khối mỗi nhân vật |
| Bảng xếp hạng | 0x5105 | `encode_rank`, `decode_rank` | một khối mỗi bảng |
| Thành phố | 0x5106 | `encode_city`, `decode_city` | một khối mỗi thành phố |
| Liên minh | 0x5107 | `encode_league`, `decode_league` | một khối mỗi liên minh |

Mỗi khối là một khung `protocol` (đầu 8 byte: độ dài thân u32, `kind` u16, cờ u16; little-endian) rồi thân bắt đầu bằng số phiên bản u16 (hiện tất cả là 1). Các `kind` chỉ nằm
trong database, không đi qua mạng. Bản đọc từ chối phiên bản chưa hiểu; đổi bố cục thì tăng phiên bản. Thời gian lưu dạng tương đối (tuổi hoặc còn lại) và dựng lại theo `now`.
`CodecError`: `kTruncated`, `kBadKind`, `kBadVersion`, `kBadValue`, `kTrailing`, `kTooLarge`. Mỗi khối có test cắt cụt ở mọi vị trí, lật byte, sai kind/phiên bản, thừa byte.

## 7. Giả định và phần chưa làm

### 7.1 Đã quyết khác gốc hay tự đặt cơ chế

- **Đội:** lời mời được nhớ và có hạn; thành viên rớt mạng giữ chỗ 300 giây (2008 cho rời ngay); đội còn một người vẫn tồn tại. `LootMode` (tự do, xoay vòng, đội trưởng) là cơ chế tối thiểu tự đặt vì 2008 và client không có luật chia đồ chung.
- **Quan hệ:** ngưỡng cấp sư phụ (40), cấp đồ đệ (29), độ thân thiết kết hôn (1000), chờ sau phản sư (3 ngày) là tự đặt (2008 để kịch bản quyết định).
- **Bang:** giai đoạn "chuẩn bị lập bang" chờ người hưởng ứng (`ResponseUserCount`/`FoundDuration` của ConfigInfo.ini) và đột kích ("Union") KHÔNG làm. Bang lập xong là chính thức. Giải tán bị chặn khi quỹ còn tiền, còn thành phố hoặc còn liên minh/bang chiến. Quyền của người được bổ nhiệm về mặc định của chức mới (2008 giữ quyền cũ). Đơn xin vào bang hết hạn sau 3 ngày. Ba tay cầm rỗng của 2008 (điều chỉnh quyền, rút tiền, nộp tiền) được làm đầy đủ.
- **Thành phố:** cột `city_id` của `city_buildings.tsv` là SCENE id (khớp `scene_id` của `guild_cities.tsv`). Nâng nha môn cần quỹ bang >= `standard_money` của cấp hiện tại nhưng quỹ KHÔNG bị trừ. Chi phí nâng công trình và nghiên cứu (`level_require`, `research_item`, `maintain`) chưa rõ nghĩa cột nên chưa thực thi.
- **Thư:** trần hộp 15 (client 2026; 2008 là 20). Thư có đồ không tự xoá; hết hạn thì trả.
- **Chat:** tiêu hao chỉ trừ khi tin được gửi (2008 trừ trước). Token trong chữ người chơi bị vô hiệu: `%` thành `?`, `#{` thành `##{`. Whisper cho người trong danh sách đen của mình hoặc người chặn mình im lặng. Chủ kênh tự lập rời mạng thì kênh giải tán. Không có vòng lịch sử tin. Nhịp bị tiêu trước khi định tuyến nên tin hỏng đường vẫn tốn một token (chống flood).
- **Bộ lọc chữ:** che bằng `*` từng điểm mã trùng (2008: client thay cả dòng). Từ có ký hiệu (`G*M`, `#666`) khớp nguyên văn. Từ ASCII dài tối đa 3 ký tự cần ranh giới cụm. Tên dành riêng so toàn chuỗi. Mẫu type 11/12 chỉ hỗ trợ dãy lớp ký tự. Không gập chữ Hán phồn/giản hay bộ thủ, không đổi vần pinyin. Quét tối đa 16384 byte.
- **Xếp hạng:** hoà điểm theo tick rồi id (tất định); tổng quát cho mọi loại điểm.
- **Thông báo:** thứ 0 là Chủ nhật (giả định theo `tm_wday`). Mã 2008 không có bộ nạp các tệp thông báo nên cách phát là thiết kế của lõi. Thông báo luân phiên mặc định không chạy (bảng thật khai 0 dòng; `declared_only = false` để phát cả mười dòng). Khởi động sau 08:00 mà chưa `set_last_daily_date` thì phát ngay.

### 7.2 Chưa làm

- Kênh phụ thuộc hệ thống ngoài lõi (cận, thế giới, môn phái, đột kích, tiểu đội, thế tộc, chiến minh, cùng thành, khu vực): lõi chỉ kiểm quyền/nhịp/lọc và trả `audience` để world phân phối.
- Kiểm vật phẩm loa (`needs_item`): world.
- Trừ tiền người chơi cho phí lập bang và liên minh: world theo sự kiện.
- Không có khối bền cho đội và chat; câm không lưu.
- Chi phí nâng công trình, nghiên cứu; đột kích; giai đoạn chuẩn bị lập bang.
- `GuildRules::battle_minutes`: đơn vị của `battle_time` (120) là phút theo giả định, chưa kiểm với mã gốc.

## 8. Số tự đặt

30 khoá của `social_limits.tsv` mang `basis = made_up` (cột `basis` là `source_2008` 16 khoá, `client_2026` 11 khoá, `made_up` 30 khoá). Chờ chủ dự án duyệt; không số nào rải trong mã.

| Nhóm | Khoá = giá trị |
|---|---|
| team | `pending_ttl_seconds` 60, `max_pending_per_target` 8, `max_pending_per_sender` 16, `offline_grace_seconds` 300 |
| relation | `max_enemies` 20, `max_temp_friends` 20, `betray_cooldown_seconds` 259200, `pending_ttl_seconds` 60, `max_pending` 16, `marry_min_friend_point` 1000, `master_min_level` 40, `prentice_max_level` 29, `moral_per_milestone` 10 |
| guild | `name_min_codepoints` 2, `position_name_max_bytes` 23, `war_min_members` 5, `league_max_members` 8, `proposer_ttl_seconds` 259200, `league_invite_ttl_seconds` 300 |
| mail | `expire_seconds` 2592000 |
| chat | `burst` 2, `global_interval_ms` 500, `global_burst` 4, `repeat_window_seconds` 30, `repeat_max` 2 |
| rank | `default_capacity` 100, `snapshot_interval_seconds` 300, `max_boards` 256 |
| notice | `daily_broadcast_minute` 480, `max_text_bytes` 1024 |

## 9. Test

Mỗi cái dưới đây là một target `ctest` (`cmake/server/social.tests.cmake`), tên `social_<m>_tests`. Số vàng của golden được tính độc lập (tay hoặc bảng gốc), không sao từ đầu ra của mã.

| Test | Phủ |
|---|---|
| `social_team` | mời/xin/trả lời, hết hạn, rớt mạng và nhường đội trưởng, chia đồ, lỗi thù địch, trần |
| `social_relation` | kết bạn/đen/thù/tạm, vợ chồng, sư đồ, thưởng, ngoại tuyến + `apply_offline_change`, khối bền (golden, cắt cụt, lật byte) |
| `social_guild` | lập/xin/nhận/đuổi/bổ nhiệm/nhường/giải tán, quyền, quỹ, bang chiến, liên minh, khối bền |
| `social_city` | bảng thành phố, chiếm/trả/nâng cấp, khối bền |
| `social_mail` | gửi hai pha, COD, trả, hết hạn, bảo toàn đồ/tiền, khối bền |
| `social_wordfilter` | khớp lỏng/nghiêm, ranh giới cụm, tên dành riêng, che, UTF-8 hỏng |
| `social_chat` | quyền, nhịp, lặp, kênh tự lập, token, lọc, định tuyến theo bang, tin hỏng |
| `social_rank` | thứ tự, thay điểm, bảng đầy, ảnh chụp, forget, khối bền (golden 71 byte, khôi phục thứ tự hoà điểm, rác) |
| `social_notice` | nạp bảng, lỗi bảng, phát hằng ngày, khởi động lại không phát lại, luân phiên, vào game |
| `social_sim` | 200 người chơi, 30000 thao tác tất định trên cả sáu sổ, bất biến sau mỗi 250 bước, bảo toàn đồ/tiền, hai hạt giống |
| `social_tables` | nạp các bảng thật và so số vàng |

`social_sim` đã được thử đột biến: bỏ lệnh xoá vật phẩm ở `FakePort::commit`, bỏ `member_index_.erase` của sổ bang, bỏ `member_team_.erase` của sổ đội, mỗi lần đều bị mô phỏng bắt.
Công cụ nhập: `TOOLS/server/test_import_social.py` (8 ca).

Chạy:
```
cmake --preset msvc-release -B build\<cây riêng>      (trong with_dev.bat)
cmake --build build\<cây riêng> --target social_sim_tests ...
ctest --test-dir build\<cây riêng> -R "^social_"
python ~/.claude/cpp23/tools/check.py --run Test/Social/<tệp>_tests.cpp --with <mỗi .cpp của social>
```
