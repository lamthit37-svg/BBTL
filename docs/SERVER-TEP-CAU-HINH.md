# Tệp cấu hình và bảng của máy chủ THIENLONG

Phụ lục của `docs/KE-HOACH-SERVER.md`, soạn 2026-10-06. Liệt kê từng tệp máy chủ cần có: tên mới
bằng tiếng Anh, định dạng, và tệp gốc mà nó thay. Mười một tệp TOML của mục 3 đã có ở
`SERVER/config/` (2026-10-06). Đợt 1 của bước P1 đã sinh bảng của mục 5, 6, 9 và tệp cảnh của mục 7
(2026-10-07); bảng tên máy đọc được là `TOOLS/server/table_names.tsv`. Đợt 2 đã sinh sáu trên mười
ba tệp của mục 4. Bảy tệp còn lại và tên tiếng Anh của phần lớn cột còn là việc của các đợt sau.

Nguồn đã đọc để lập danh sách:

- `tlbb_server/Common/ServerBase/FileDef.h` và `Config.h` của mã nguồn 2008: tệp nào máy chủ nạp.
- `TLBB_0859602_Win10_11/tlbb/Server/Config` (113 tệp), `Public/Config` (91 tệp và 3 thư mục con),
  `Public/Scene` (3.251 tệp), `Public/Data`: đọc dòng tên cột tiếng Trung của từng bảng và từng
  section của từng tệp ini.
- `F:\tl 2026\_raw\Config` (722 tệp của client 2026): đọc đầu DBC và ba dòng đầu của từng bảng.

Dấu `?` ở cột ghi chú nghĩa là tên gốc chưa giải được hoặc mới suy từ tên: phải đọc bảng và Lua giao
diện dùng nó rồi mới chốt tên (bước P1.3).

## 1. Quy tắc đặt tên

- Chữ thường, `snake_case`, ASCII, không pinyin. Danh từ số nhiều khi mỗi dòng là một thực thể
  (`monsters.tsv`), giữ nguyên khi tên là hành động hay một bộ luật (`pet_refine.tsv`).
- `.toml` cho cấu hình có khoá đặt tên; `.tsv` cho bảng theo dòng; `.nav`, `.bin` cho dữ liệu nấu.
- Từ tiếng Anh sẵn có trong tên gốc được giữ khi đúng nghĩa (skill, item, pet, guild, shop, scene).
  Từ tiếng Anh sai nghĩa của bản gốc được sửa theo bảng thuật ngữ dưới.
- Tên riêng của thế giới game giữ nguyên dạng Latin: `chonglou`, `fengming`, `bianjing`, `qixi`,
  `qingming`, `tianji_city`, `guanshanhai`.
- Hậu tố phiên bản của bản gốc (`_V1`) bỏ; phiên bản nằm trong dòng `# schema` đầu tệp.

Bảng thuật ngữ (tên gốc sang từ dùng trong tên tệp, tên cột và mã):

| Bản gốc | Chữ Trung | Từ dùng |
|---|---|---|
| MenPai | 门派 | sect |
| XinFa | 心法 | inner_art |
| Impact | 效果 | effect |
| Refix | 修正 | modifier |
| Ruler | 规则 | rules |
| Attenuation | 衰减 | level_gap_factor |
| Ability | 生活技能 | life_skill |
| Mission, Task | 任务 | quest (bảng 2026 chưa đổi cột thì giữ mission) |
| Husong | 护送 | escort |
| Shimen | 师门 | sect_task |
| Zhuandan, Niudan | 转蛋, 扭蛋 | gacha |
| PaoPao | 冒泡 | speech (bong bóng lời) |
| Dark | 暗器 | hidden_weapon |
| GoodBad | 善恶 | morality |
| Juqing | 剧情 | story_point |
| Boom | 繁荣度 | prosperity |
| XianYa, QianZhuang, XiangFang | 县衙, 钱庄, 厢房 | county_office, bank, guest_wing |
| GenGu | 根骨 | bone_grade |
| Variance, Wileness, Baby | 变异, 野生, 宝宝 | mutant, wild, baby |
| Apperceive | 领悟 | comprehension |
| Domestication | 驯养 | taming |
| HuanTong | 还童 | rejuvenation |
| Commision | 寄售 | consignment |
| PlayerShop, Stall | 玩家商店, 摆摊 | player_shop, stall |
| YuanBao | 元宝 | ingot (tiền nạp trong game) |
| ZengDian | 赠点 | bonus_point |
| JiaoZi | 交子 | bound_coin |
| YuanBaoPiao | 元宝票 | ingot_voucher |
| Point | 点数 | point (số dư nạp của tài khoản, ở billing) |
| MiBao | 密保 | security_card |
| CDK, NewUserCard | 兑换码, 新手卡 | redeem_code |
| MinorPassword | 二级密码 | secondary_password |
| CopyScene, FuBen | 副本 | instance |
| GrowPoint | 生长点 | grow_point |
| Platform | 操作台 | platform (bàn chế tác) |
| SpecialObj | 特殊对象 | special_object (bẫy, vùng hiệu ứng) |
| Fatigue, Wallow | 防沉迷 | fatigue |
| KaJi | 卡级 | level_cap (máy chủ khoá cấp) |
| XingZhen | 星阵 | star_array |
| DiaoWen | 雕纹 | engraving |
| LongWen | 龙纹 | dragon_mark |
| HXY | 豪侠印 | hero_seal |
| KFS | 武魂 | martial_soul (?) |
| ZhenYuan, Pneuma | 真元 | pneuma |
| XiuLian | 修炼 | cultivation |
| ZhenFa | 阵法 | formation |
| CangPin | 藏品 | collectible |
| BieYe | 别业 | villa |
| ZongMen, ZM | 宗门 | clan |
| ZhanLing | 战令 | battle_pass |
| ChengJiu | 成就 | achievement |
| HongBao | 红包 | red_envelope |
| GuiShi | 鬼市 | ghost_market |

Thuật ngữ thuộc tính và chiến đấu, tra theo chữ Trung (thêm 2026-10-07). Đợt 3 của P1 để lộ ra hai
bảng tên cột dịch cùng một chữ thành hai từ (`defence` và `defense`, `cold` và `ice`, `dodge` và
`miss`), nên các từ dưới đây được chốt. Căn cứ là tên enum và chú thích của
`Common/GameDefine_Attr.h` trong mã 2008; chỗ bản gốc dùng từ sai nghĩa thì sửa. Một nhãn chứa chữ
ở cột đầu thì tên tiếng Anh của nó phải có từ ở cột hai và không có từ ở cột ba. Bản máy đọc là
`TOOLS/server/term_morphemes.tsv`.

| Chữ Trung | Từ dùng | Không dùng | Căn cứ |
|---|---|---|---|
| 力量 | strength | str, power | `CATTR_LEVEL1_STR`, chú thích 力量 |
| 灵气 | spirit | spr | `CATTR_LEVEL1_SPR`, chú thích 灵气 |
| 体质 | constitution | con, stamina | `CATTR_LEVEL1_CON`, chú thích 体制 |
| 定力 | intellect | int, concentration | `CATTR_LEVEL1_INT`, chú thích 定力 智力 |
| 身法 | dexterity | dex, agility | `CATTR_LEVEL1_DEX`, chú thích 身法 敏捷 |
| 防御 | defence | defense | `CATTR_LEVEL2_DEFENCE_P`; giữ chính tả của bản gốc |
| 冰 | cold | ice | `CATTR_LEVEL2_ATTACKCOLD` |
| 玄, 电 | lightning | light, electric | bản gốc viết `LIGHT`; hệ này là điện |
| 闪避 | dodge | miss | bản gốc viết `MISS`, sai nghĩa |
| 命中 | hit | accuracy | `CATTR_LEVEL2_HIT` |
| 会心 | critical | crit | `CATTR_LEVEL2_CRITRATE` |
| 抵抗, 抗性 | resist | resistance | tên cột đang dùng thống nhất |
| 几率, 概率 | chance | odds, probability | xác suất một việc xảy ra; `rate` để cho tỉ lệ và hệ số (率) |
| 内力 | mp | mana | bảng gốc viết MP |
| 回复 | restore | regen | `CATTR_LEVEL2_RESTOREHP` |

`odds` vẫn được dùng trong tên bảng đã đặt (`item_quality_odds`, `pet_skill_odds`); luật trên áp cho
tên cột.

## 2. Cây thư mục

Từ 2026-10-12 runtime máy chủ nằm ở `dev/server/` (máy chủ thử) và `release/server/` (bản chính thức), cùng hình;
tài liệu này viết `SERVER/` cho gốc đó (thư mục `SERVER/` ở gốc dự án đã gỡ ngày 2026-10-15). Ai được sửa thư mục
nào (nhà phát hành chỉ sửa `config/`) ở `docs/SERVER-DU-LIEU.md`. Cột phải ghi thứ nào vào git.

```text
SERVER/
  README.md            vào git
  bin/                 exe do cmake --install chép vào; git bỏ qua
  pgsql/               nhị phân PostgreSQL 18.6 do setup_db.py tải; git bỏ qua
  config/              TOML của tiến trình (mục 3); vào git, trừ secrets.local.toml
    rules/             TOML luật chơi (mục 4); vào git
  tables/
    server/            bảng chỉ máy chủ giữ (mục 5) và tệp chữ thoại dialogue.zh.txt; vào git
    shared/            bảng dùng chung, xuất từ client (mục 6, mục 9); git bỏ qua
    variants/<khoá>/   bảng thay theo loại máy chủ (mục 9, cuối); git bỏ qua
  scenes/<scene>/      dữ liệu máy chủ của từng cảnh (mục 7); tệp chữ vào git, .nav và .bin thì không
  sql/<schema>/        tệp migration PostgreSQL, đánh số; vào git
  data/                cụm PostgreSQL (data/pg), khoá danh tính, nhật ký ghi; git bỏ qua
  log/                 git bỏ qua
```

Trạng thái 2026-10-06: đã có `README.md`, `pgsql/`, `config/` với mười một tệp của mục 3, `data/pg`
với ba database rỗng, `log/`. Các thư mục còn lại đã tạo nhưng chưa có nội dung.

Trạng thái 2026-10-08, đếm trên đĩa: `config/rules/` 6 tệp, `tables/server/` 71 bảng,
`tables/shared/` 574 bảng, `tables/variants/` 61 bảng trong sáu bộ, `scenes/` 244 cảnh, `bin/` tám
exe cài lại cùng ngày, `data/gate/identity.key` là khoá danh tính của gate. `sql/auth`,
`sql/game` còn trống tính đến lúc đếm; `sql/billing` có năm tệp `001`…`005` từ 2026-10-14 (`docs/SERVER-BILLING.md`).

## 3. Tệp TOML của tiến trình (`SERVER/config/`)

Mười một tệp, đã có từ ngày 2026-10-06. Bố cục theo `TOOLS/server/config_style.py`, lấy từ mẫu chủ
dự án đưa: khung tiêu đề in hoa kẹp giữa hai dòng `#====` ở đầu tệp, mỗi nhóm cài đặt một khung
tiêu đề, các cài đặt nằm sát nhau, mỗi cài đặt một chú thích tiếng Việt ngang hàng, dấu `=` và
dấu `#` thẳng cột trong nhóm. `python TOOLS/server/lint_config.py` kiểm, thêm `--fix` thì căn
cột lại; cài đặt thiếu chú thích hay lệch cột là lỗi. Mỗi tệp có
`schema = 1`. Mọi thời lượng ghi đơn vị trong tên khoá (`_ms`, `_seconds`). Đường dẫn tương đối
tính từ thư mục của tệp. Mật khẩu chỉ nằm ở tệp cuối. Bộ đọc C++ là module `config` (có từ P2
đợt 1, `config_tests`): khoá lạ, thiếu khoá, sai kiểu, ngoài miền đều là lỗi khởi động kèm số
dòng.

Cổng là số 1 tới 65535. Riêng bên nghe trên đúng `127.0.0.1` được khai cổng 0, nghĩa là hệ điều
hành chọn cổng lúc nghe và tiến trình báo cổng thật ở dòng `ready` (mục 3.1 của
`docs/KE-HOACH-SERVER.md`): `[listen] game`, `auth` của `gate.toml`, `listen` của `admin.toml` và
`port` của `[[process]]` trong `cluster.toml`. Cổng 0 ở địa chỉ khác (kể cả `127.0.0.2` hay
`0.0.0.0`) và ở `[postgres] port` là "ngoài miền". Test và công cụ dùng cổng 0; các tệp trong
`SERVER/config` khai cổng cố định.

| Tệp | Tiến trình đọc | Khoá | Thay cho |
|---|---|---|---|
| `cluster.toml` | mọi tiến trình | `schema`; `[world] id, zone_group, name, table_variant`; `[postgres] host, port, bin_dir, data_dir, log_file`; `[[machine]] id`; `[[process]] kind, id, machine, host, port` | `ServerInfo.ini` (`[ServerN]`, `[World]`, `[Billing]`), `MachineInfo.ini`, `WorldInfo.ini` (`ZoneID`, `WorldID`), `DBIP` và `DBPort` của `LoginInfo.ini`, `ShareMemInfo.ini`, `BillingInfo.ini` |
| `gate.toml` | gate | `schema, identity_key_file, trusted_proxies`; `[listen] game, auth`; `[limits] max_connections, per_ip_connections, handshake_timeout_ms, idle_timeout_ms, client_frame_bytes, messages_per_second`; `[client] min_version`; `[ip_filter] allow, deny` | `ServerInfo.ini` (`IP0`, `Port0`), `LoginInfo.ini` (`ClientVersion`, `ProxyConnect`), `IPRange.ini`, `proxyIP.txt` |
| `client.toml` | gate | `schema`; `[hud] avatar_frame` (`round` hoặc `square`) | không có tệp gốc: client 2026 chọn khung chân dung bằng `SystemSetup:IsClassic()`; gate gửi giá trị này cho client trong tin `UiConfig` sau `SessionStart` |
| `auth.toml` | auth | `schema`; `[database] name, user, pool`; `[register] auto_register, gift_points`; `[password] ops_limit, mem_limit_kib`; `[ticket] ttl_seconds`; `[login] relogin_limit, relogin_block, relogin_block_ms, queue_turn_size, max_sessions_per_device`; `[captcha] on_create, on_enter`; `[security_card] enabled` | `LoginInfo.ini` (`ReLoginLimit`, `ReLoginStop`, `ReLoginStopTime`, `TurnPlayerCount`, `CreateCodeEnabled`, `LoginCodeEnabled`), `BillingInfo.ini` (`AutoRegister`, `PcMaxClientCount`), bảng `billing_mibao_*` |
| `billing.toml` | billing | `schema`; `[database] name, user, pool`; `[access] allow`; `[limits] max_clients`; `[points] ingot_per_point, register_gift`; `[spend] daily_ingot_cap`; `[orders] pending_timeout_seconds, reconcile_interval_seconds`; `[redeem] attempts_per_hour`; `[webhook] port` (127.0.0.1, cố định vì trình giám sát chỉ nhận các khoá cổng ipc, game, auth, metrics; 0 để test); khi có nhà cung cấp thanh toán thì thêm `[[provider]] key, webhook_path, secret_file, enabled` (`secret_file` tính từ thư mục cấu hình, 64 ký tự hex; xem `docs/SERVER-BILLING.md`); các trần số của billing ở `tables/server/billing_limits.tsv` | `BillingInfo.ini` (`[Access]`, `[Limit]`), `config.yaml` của bản billing khác (`point_fix`), `ConfigInfo.ini` `[YuanBao]` |
| `world.toml` | world | `schema`; `[capacity] online_users, mail_users, offline_cache, speakers, pet_friend_ads`; `[player_count_report] hours`; `[notice] join_guild`; `[platform] pc_meets_mobile` | `ConfigInfo.ini` `[World]`, `[PlayerCountOfScene]`, `[SystemNotice]`. `pc_meets_mobile` là luật mới: APK và iOS cùng phía mobile, PC chỉ gặp khi cờ bật |
| `zone.toml` | zone | `schema`; `[tick] hz`; `[aoi] cell_size`; `[capacity] monsters, pets, special_objects, platforms, buses, player_shops, scene_timers, human_timers`; `[session] linger_after_disconnect_ms, linger_hidden_ms, kick_idle_ms`; `[world_clock] period_change_ms`; `[drops] box_recycle_ms`; `[audit] packet_stats_ms` | `ConfigInfo.ini` `[Zone]`, `[TimeSetting]`, và `MaxCount` của `[Monster]`, `[Pet]`, `[Platform]`, `[SpecialObj]`, `[BusObj]`, `[PlayerShop]`, `[SceneTimer]`, `[HumanTimer]` |
| `store.toml` | store | `schema`; `[database] name, user, pool`; `[flush] character_ms, world_ms`; `[journal] dir` | `ShareMemInfo.ini` (`DBName`, `DBUser`, `DATAInterval`, `SMUInterval`) |
| `log.toml` | mọi tiến trình | `schema, audit`; `[file] dir, rotate_mb`; `[level] default` | `ConfigInfo.ini` (`AuditSwitch`) |
| `admin.toml` | supervisor, công cụ quản trị | `schema, listen, token_file`; khi có công cụ quản trị thì thêm `[[operator]] name, level` | `GMList.ini` (danh sách GM chuyển vào bảng `game.gm_grant`; tệp chỉ giữ người vận hành đầu tiên) |
| `supervisor.toml` | supervisor | `schema`; `[postgres] managed, ready_timeout_seconds`; `[restart] max_per_hour`; `[[start]] process, ready_timeout_seconds` | thứ tự và thời gian chờ của `run.bat`, `xrun.sh` |
| `secrets.local.toml` | theo từng tiến trình | `schema`; `[database.<role>] password` cho `postgres`, `thienlong_auth`, `thienlong_billing`, `thienlong_store`; về sau thêm khoá ký vé, bí mật của nhà cung cấp thanh toán, khoá ipc | `DBPassword` trong `LoginInfo.ini`, `ShareMemInfo.ini`, `BillingInfo.ini`. Git bỏ qua; `setup_db.py init` sinh; hình dạng xem `secrets.example.toml` |

Khoá của bản gốc bị bỏ, kèm lý do:

- `HumanSMKey`, `PlayShopSMKey`, `ItemSerialKey`, `CommisionShopKey`, `GuildSMKey`, `MailSMKey`,
  `PetSMKey`, `CitySMKey`, `GlobalDataSMKey`, `LeagueSMKey`, `FindFriendADKey`, `EnableShareMem`, và
  cả `[ShareMem]`: không còn vùng nhớ dùng chung.
- `[Mother]`, `[Proxy]`, `IP(CNC)`, `IP(CTC)`, `IP(EDU)`: định tuyến theo nhà mạng Trung Quốc.
- `EnableEffAudit*`, `CryptPwd`, `DBConnectCount` (thay bằng `[database] pool`).
- Khoá mà chú thích của bản 0859602 ghi "chỉ nạp, không nơi nào đọc": `PrenticeProfferExp`,
  `RecoverTime`, `DefaultRespawnTime`, `DefaultAIType`, `DefaultRefuseScanTime`,
  `[Portal] MaxCount`, `[SkillObj] MaxCount`.
- `ItemSerial.ini`: số serial vật phẩm do DB cấp theo khối.
- `[Temp] UserPath`.

Khoá của bản gốc chưa đưa vào tệp nào vì chưa đọc mã dùng chúng; quyết ở mốc P3: `SMUKickUserTime`,
`[CacheLogTime] LogInCacheTime`, `NotifySafeSign`.

## 4. Tệp TOML luật chơi (`SERVER/config/rules/`)

Mười ba tệp. `import_rules.py` sinh chúng từ bảng soạn tay `TOOLS/server/legacy_rules.tsv`, đúng
hình thức của mục 3 (mỗi khoá một chú thích tiếng Việt). Bảng đó có một dòng cho mỗi khoá của tám
tệp nguồn, 578 dòng: 131 khoá thành luật, 26 khoá đã nằm ở tệp tiến trình của mục 3 (giá trị trùng
cả 26), 9 khoá bỏ, 412 khoá chưa xếp. Đã sinh (đợt 2, 2026-10-07): `global`, `combat`, `character`,
`new_character`, `monster`, `instances`. Chưa sinh: `pet`, `hidden_weapon`, `pvp`, `guild`,
`social`, `economy`, `fatigue`.

Tỉ lệ và hệ số là số thực của bản gốc đổi sang số nguyên phần nghìn (`_permille`) hoặc phần triệu
(`_ppm`) để phép tính tất định. Toạ độ không phải tỉ lệ: giữ số thực, cùng tên `position_x`,
`position_z` và cùng kiểu với bảng cảnh (chốt 2026-10-07; đợt 2 ghi nhầm thành `pos_x_permille`,
đợt 3 sửa).

| Tệp | Nội dung | Nguồn |
|---|---|---|
| `global.toml` | hệ số rơi đồ, hệ số hồi sinh quái, cấp tối đa được hồi sinh tại chỗ, ngôn ngữ, tự gỡ trân thú lỗi | `ConfigInfo.ini` `[Global]`, `[Localization]` |
| `combat.toml` | dao động sát thương, hằng số trúng đích và chí mạng, giảm sát thương khi PK, trần thuộc tính | `ConfigInfo.ini` `[Combat]`, `PkRefixOfDamage`; `Public/Config/CombatLimits.ini` |
| `character.toml` | tầm nhận kinh nghiệm, thời gian hồn ma, tốc độ đi và đánh mặc định, cấp tối đa của người và tâm pháp, chu kỳ hồi hoạt lực, các hệ số cộng kinh nghiệm, tham số kỹ năng sống | `ConfigInfo.ini` `[Human]`, `[Exp]`, `[Ability]` |
| `new_character.toml` | cảnh và toạ độ sinh, chỉ số, kỹ năng, kỹ năng sống, công thức và thiết lập ban đầu | `DefaultChar.ini` |
| `monster.toml` | tầm sinh lại, thời gian giữ xác thường và boss, xác suất đổi mục tiêu, cấp tối đa, ngưỡng giảm thu nhập khi cày quái | `ConfigInfo.ini` `[Monster]`, `[MonsterIncome]` |
| `pet.toml` | nhịp giảm vui vẻ và tuổi thọ, điều kiện đăng bảng tìm bạn, tham số phối giống, tỉ lệ con non và đột biến, bảng tăng trưởng, dải cốt cách, chỉ số gốc | `ConfigInfo.ini` `[Pet]`; `PetConfigTable.ini` |
| `hidden_weapon.toml` | tỉ lệ phẩm chất tăng trưởng của ám khí theo ba hạng | `DarkConfigTable.ini` |
| `pvp.toml` | thời lượng và điều kiện thách đấu, tuyên chiến cá nhân, trễ đổi cờ PK, phản kích hợp lệ, điểm thiện ác | `ConfigInfo.ini` `[Duel]`, `[Warfare]`, `[PK]`, `[FightBack]`, `[GoodBad]`, `[JuqingPoint]` |
| `guild.toml` | thời hạn lập bang, số thành viên theo cấp nha môn, quỹ theo cấp, phí lập thành, phồn vinh, liên minh | `ConfigInfo.ini` `[Guild]`, `[GuildLeague]` |
| `social.toml` | theo đội, độ thân thiết, mật khẩu cấp hai | `ConfigInfo.ini` `[Team]`, `[Relation]`, `[MinorPassword]` |
| `economy.toml` | thuế, cảnh giao dịch ingot, trần phiếu ingot, phí và mệnh giá ký gửi, phí cửa hàng người chơi, cửa sổ đóng mở từng tính năng | `ConfigInfo.ini` `[Economic]`, `[CommisionShop]`, `[PlayerShop]`, `[EnableYuanBaoPiao]`, `[ActiveRichesCard]`; `MergeConfig.txt` |
| `fatigue.toml` | bật tắt chống nghiện, hai ngưỡng giờ chơi, giờ nghỉ để đặt lại, câu hỏi chống treo máy | `ConfigInfo.ini` `[Fatigue]`, `[AntiCheat]` |
| `instances.toml` | số nhóm phó bản và số cảnh tối đa mỗi nhóm | `CopyScene.ini` |

`announcements.toml` không có: mười câu thông báo luân phiên của `SystemInfo.ini` vào bảng
`rolling_announcements.tsv`, ba mươi mục `[huodongN]` vào `scheduled_events.tsv` (mục 5).

## 5. Bảng chỉ máy chủ giữ (`SERVER/tables/server/`)

Nguồn là 113 tệp của `Server/Config`. Hai mươi mốt tệp đã nằm ở mục 3 và mục 4 hoặc bị bỏ; 92 tệp
còn lại thành các bảng dưới.

Tệp của `Server/Config` không thành bảng:

| Tệp gốc | Số phận |
|---|---|
| `ServerInfo.ini`, `MachineInfo.ini`, `WorldInfo.ini`, `ShareMemInfo.ini`, `LoginInfo.ini`, `BillingInfo.ini`, `ConfigInfo.ini`, `CopyScene.ini`, `GMList.ini`, `IPRange.ini`, `proxyIP.txt`, `DefaultChar.ini`, `PetConfigTable.ini`, `DarkConfigTable.ini`, `MergeConfig.txt` | thành TOML (mục 3, mục 4) |
| `ItemSerial.ini` | bỏ, DB cấp serial |
| `Account.txt` | bỏ: 10.074 dòng tên và mật khẩu thử dạng rõ |
| `AllowableScriptFunc.txt` | không nạp: 196 cặp script id và tên hàm mà client được gọi; chỉ là đầu vào để kiểm kê tin mạng cần có |
| `ascii.cpf`, `chs.cpf` | không dùng: tệp nhị phân, chưa đọc định dạng; luật tên nhân vật viết lại trong module `names` |
| `IPRegionTable.txt` | bỏ: 23.975 dải IP Trung Quốc cho kênh chat cùng thành phố |

Bảng:

| Tệp gốc | Tên mới | Nội dung |
|---|---|---|
| `SceneInfo.ini` | `scenes.tsv` và `scene_hosting.tsv` | 923 section cảnh, nhưng `scenenumber=723` nên máy chủ gốc chỉ nạp 723 cảnh đầu: id, tài nguyên client, tên, loại, luật PvP, hồi sinh tại chỗ; bảng thứ hai gán cảnh cho tiến trình zone và nhóm luồng |
| `SystemInfo.ini` | `rolling_announcements.tsv`, `scheduled_events.tsv` | thông báo luân phiên; sự kiện theo giờ gắn cảnh và script id |
| `GuildMemberAccess.ini` | `guild_position_permissions.tsv` | quyền của năm loại chức vụ bang |
| `BaseValueTable.ini` | `sect_base_values.tsv` | hệ số gốc của mười môn phái theo từng loại chỉ số |
| `AttrLevelUpTable.txt` | `sect_attribute_growth.tsv` | điểm năm chỉ số gốc mỗi cấp của từng môn phái |
| `AttrRefixTable.txt` | `life_skill_attribute_modifiers.tsv` | hệ số nhân và cộng của kỹ năng sống lên chỉ số |
| `MenPaiAttackRefix.txt` | `sect_damage_modifiers.tsv` | hệ số sát thương giữa các môn phái |
| `StandardImpact.txt` | `effects.tsv` | 9.860 bản ghi (tệp 9.906 dòng, trong đó 44 dòng chú thích và 2 dòng đầu), 76 cột: mọi hiệu ứng và buff, mỗi dòng trỏ một logic id |
| `SkillObjData_V1.txt` | `skill_objects.tsv` | vật thể do kỹ năng tạo |
| `DiePenalty.txt` | `death_penalties.tsv` | khoảng mất tiền, kinh nghiệm, độ bền, vật phẩm khi chết |
| `PunishByLevel.txt` | `death_penalty_by_level.tsv` | hệ số phạt theo dải cấp |
| `PunishByPkValue.txt` | `death_penalty_by_pk_value.tsv` | hệ số phạt theo sát khí |
| `PunishByState.txt` | `death_penalty_by_state.tsv` | hệ số phạt theo kiểu chết |
| `PvpRuler.txt` | `pvp_rules.tsv` | luật PvP của từng loại cảnh |
| `ExpAttenuation.txt` | `exp_level_gap_factors.tsv` | hệ số kinh nghiệm theo chênh cấp quái và người |
| `DropAttenuation.txt` | `drop_level_gap_factors.tsv` | hệ số rơi đồ theo chênh cấp |
| `PetExpAttenuation.txt` | `pet_exp_level_gap_factors.tsv` | hệ số kinh nghiệm của trân thú theo chênh cấp |
| `MonsterDropBoxs.txt` | `monster_drops.tsv` | quái nào rơi những gói nào |
| `DropBoxContent.txt` | `drop_packages.tsv` | 2.034 gói rơi, mỗi gói tới 256 cặp vật phẩm và cấp |
| `DropRateOfItemTable.txt` | `item_drop_rates.tsv` | xác suất rơi riêng của từng vật phẩm, có báo tin hay không |
| `ItemQuality.txt` | `item_quality_odds.tsv` | xác suất phẩm chất theo cấp vật phẩm và loại trang bị |
| `ItemValue.txt` | `item_attribute_value_ranges.tsv` | khoảng giá trị của từng thuộc tính theo bậc |
| `ItemSegAffect.txt` | `item_segment_distributions.tsv` | phân bố xác suất chín đoạn phẩm chất |
| `ItemSegQuality.txt` | `item_segment_quality_rules.tsv` | luật chọn phân bố theo nguồn sinh trang bị |
| `ItemSegRate.txt` | `item_segment_rates.tsv` | tỉ lệ của từng thuộc tính theo đoạn phẩm chất |
| `ItemSegValue.txt` | `item_segment_values.tsv` | giá trị thuộc tính theo đoạn; mỗi dòng 129 ô nhưng dòng kiểu chỉ khai 65 cột, nên máy chủ gốc đọc 65 cột đầu (bản client 65 cột nằm ở mục 6) |
| `OnSaleLimit.txt` | `item_sale_limits.tsv` | vật phẩm cấm bày bán hay cấm vào cửa hàng người chơi |
| `ItemAuditFilter.txt` | `audit_item_filter.tsv` | vật phẩm cần ghi sổ kiểm |
| `NpcAuditFilter.txt` | `audit_monster_filter.tsv` | quái cần ghi sổ kiểm |
| `GeneralSets.txt` | `id_sets.tsv` | các tập id đặt tên, ví dụ cảnh có ngân hàng |
| `boxdroplist.txt` và 34 tệp `boxdroplist_*.txt` | `loot_box_entries.tsv` | một bảng, thêm cột `box_key`; mỗi dòng: vật phẩm, tỉ lệ, có báo tin |
| `ZhuandanBase.txt` | `gacha_machines.tsv` | máy gacha: vật phẩm kích hoạt, số loại sản phẩm, chỗ trống cần, mẫu thông báo |
| `ZhuandanOutput.txt` | `gacha_outputs.tsv` | sản phẩm của máy gacha: số lượng, tỉ lệ, khoá, phát thanh |
| `ZhuandanConfig.txt` | `gacha_item_pools.tsv` | bố cục cũ: mỗi dòng một máy với dãy vật phẩm |
| `PetAIStrategyTbl.txt` | `pet_ai_strategies.tsv` | hệ số dùng kỹ năng tự động theo năm tính cách |
| `PetApperceiveSkillTable.txt` | `pet_skill_comprehension_odds.tsv` | xác suất lĩnh ngộ kỹ năng chủ động và bị động |
| `PetAttrPointDistribute.txt` | `pet_attribute_point_plans.tsv` | các phương án chia điểm thuộc tính |
| `PetDieLoss.txt` | `pet_death_happiness_loss.tsv` | vui vẻ mất khi chết theo cấp |
| `PetDomesticationMoney.txt` | `pet_taming_costs.tsv` | tham số phí thuần dưỡng theo cấp |
| `PetSkillDistribute.txt` | `pet_skill_odds.tsv` | xác suất từng kỹ năng của từng loại trân thú |
| `PetSkillIndexTable.txt` | `pet_skill_index.tsv` | chỉ số cột của bảng trên sang id kỹ năng |
| `PetStudySkllTable.txt` | `pet_skill_learn_slots.tsv` | xác suất kỹ năng mới vào ô trống |
| `CreateQualityOfVaryPetTbl.txt` | `pet_mutant_quality_odds.tsv` | xác suất phẩm chất của trân thú đột biến |
| `CreateSkillOfVaryPetTbl.txt` | `pet_breeding_skill_inheritance.tsv` | số kỹ năng con thừa hưởng từ bố và mẹ |
| `DarkSkillList.txt` | `hidden_weapon_skills_by_level.tsv` | kỹ năng ám khí theo mốc cấp 10 tới 160 |
| `DarkSkillStudy.txt` | `hidden_weapon_skill_learn_weights.tsv` | trọng số học kỹ năng ám khí ở ba mốc cấp |
| `ShimenLevelMoneyBonusTable.txt` | `sect_task_rewards_by_level.tsv` | tiền và kinh nghiệm của nhiệm vụ sư môn theo cấp |
| `ShimenRoundMultipleTable.txt` | `sect_task_round_multipliers.tsv` | hệ số theo số vòng |
| `MasterExpBounty.txt` | `mentor_exp_rewards.tsv` | thưởng cho sư phụ khi đồ đệ đạt mốc cấp |
| `GuildWarPoint.txt` | `guild_war_points.tsv` | luật tính điểm bang chiến |
| `Questions.txt` | `quiz_questions.tsv` | 3.703 câu hỏi, sáu lựa chọn, loại câu hỏi |
| `NotifyDate.txt` | `notices_by_date.tsv` | thông báo theo khoảng ngày |
| `NotifyWeek.txt` | `notices_by_weekday.tsv` | thông báo theo thứ |
| `NotifyOnline.txt` | `notices_on_login.tsv` | thông báo lúc vào game |
| `NPCChat.txt` | `npc_chat_lines.tsv` | câu nói của NPC |
| `NPCPaoPaoIndexTable.txt` | `npc_speech_bubbles.tsv` | NPC nào dùng dải bong bóng lời nào |
| `StringTable.txt` | `server_strings.tsv` | 312 chuỗi máy chủ gửi; đổi sang id chuỗi, bản tiếng Việt |
| `ChatConfig.txt` | (trùng bản ở `Public/Config`) | xem `chat_channels.tsv`, mục 6 |

Khoá `box_key` của `loot_box_entries.tsv`:

| Tệp gốc | `box_key` |
|---|---|
| `boxdroplist.txt` | `default` |
| `boxdroplist_baibaoshuxia.txt` | `treasure_tree` (?) |
| `boxdroplist_jubao.txt` | `treasure_gather` (?) |
| `boxdroplist_zhuandan1.txt` tới `_zhuandan6.txt`, `_zhuandan16.txt` tới `_zhuandan24.txt`, `_zhuandan26.txt` tới `_zhuandan33.txt` (23 tệp) | `gacha_1` tới `gacha_33` theo số của tệp |
| `_zhuandansl`, `_zhuandanmj`, `_zhuandangb`, `_zhuandanwd`, `_zhuandanem`, `_zhuandanxx`, `_zhuandantl`, `_zhuandants`, `_zhuandanxy` | `gacha_shaolin`, `gacha_mingjiao`, `gacha_gaibang`, `gacha_wudang`, `gacha_emei`, `gacha_xingxiu`, `gacha_tianlong`, `gacha_tianshan`, `gacha_xiaoyao` |

## 6. Bảng dùng chung với client (`SERVER/tables/shared/`)

Nguồn là 91 tệp của `Public/Config` bản 0859602. Tám mươi ba tệp có bản cùng tên trong client 2026;
bản phát hành xuất từ DBC của client 2026, bản 0859602 chỉ để đối chiếu cột vì nó còn dòng tên cột.
Tám tệp không có ở client: `CampAndStand.txt`, `CombatLimits.ini`, `HairStyle.txt`, `Impact.txt`,
`ImpactCollections.txt`, `MonsterAITable.ini`, `MountFlightMaps.txt`, `SkillBullet.txt`; chúng vào
`tables/server/` hoặc `config/rules/`.

| Tệp gốc | Tên mới | Nội dung |
|---|---|---|
| `SkillTemplate_V1.txt` | `skills.tsv` | kỹ năng: môn phái, tâm pháp, loại chiêu, điều kiện, hồi chiêu id, hình ảnh |
| `SkillData_V1.txt` | `skill_levels.tsv` | dữ liệu theo cấp: logic id, hồi chiêu, tụ khí, dẫn chiêu, tiêu hao, tham số |
| `XinFa_V1.txt` | `inner_arts.tsv` | tâm pháp và hệ số theo dải cấp |
| `XinFaStudySpend_V1.txt` | `inner_art_learn_costs.tsv` | tiền và kinh nghiệm để học từng cấp |
| `ImpactSEData_V1.txt` | `effect_visuals.tsv` | biểu tượng, hiệu ứng hình và tiếng của buff; cờ giữ khi chết, xua được |
| `ImpactDirectly.txt` | `effect_instant_visuals.tsv` | hiệu ứng hình và tiếng của hiệu ứng tức thời |
| `Impact.txt` | `effect_atoms_legacy.tsv` | 19 dòng của hệ hiệu ứng cũ theo thao tác nguyên tử; đọc mã rồi mới biết còn dùng không |
| `ImpactCollections.txt` | `effect_collections.tsv` | nhóm id hiệu ứng đặt tên |
| `IDCollections.txt` | `id_collections.tsv` | nhóm id kỹ năng và hiệu ứng đặt tên |
| `SpecialObjData.txt` | `special_objects.tsv` | bẫy và vùng hiệu ứng: logic id, số lần kích, bán kính, thời gian |
| `Bullet.txt` | `bullets.tsv` | đạn: quỹ đạo, tốc độ, hiệu ứng |
| `SkillBullet.txt` | `skill_bullets.tsv` | đạn của kỹ năng, bố cục cũ |
| `AttackTraits.txt` | `attack_traits.tsv` | đặc tính tấn công: hệ số vật lý, phép và bốn hệ |
| `CampAndStand.txt` | `camp_relations.tsv` | ma trận quan hệ 16 phe |
| `LevelRefix_Hit.txt` | `hit_level_modifiers.tsv` | hệ số trúng đích theo chênh cấp |
| `CombatLimits.ini` | (vào `rules/combat.toml`) | trần thuộc tính và trần một lần kết toán |
| `MonsterAttrExTable.txt` | `monsters.tsv` | quái và NPC: cấp, kinh nghiệm, AI, phe, chỉ số, tầm chia đồ |
| `MonsterAITable.ini` | `monster_ai_types.tsv` | 31 kiểu AI, mỗi kiểu 11 tham số trong tệp; mã 2008 chỉ đọc 9 tham số đầu |
| `MonsterRespawnPos.txt` | `monster_respawn_points.tsv` | các điểm sinh của quái do script gọi |
| `PetAttrTable.txt` | `pets.tsv` | trân thú: loại, cấp mang, kỹ năng và xác suất, tư chất |
| `PetLevelUpTable.txt` | `pet_exp_levels.tsv` | kinh nghiệm lên cấp |
| `PetHuanTongCost.txt` | `pet_rejuvenation_costs.tsv` | chi phí hoàn đồng theo cấp mang |
| `PetMedicineHCCompound.txt` | `pet_pill_compounds.tsv` | ghép linh thú đan |
| `PetSkillBook.txt` | `pet_skill_books.tsv` | sách kỹ năng sang id kỹ năng |
| `PetSkillLevelup.txt` | `pet_skill_upgrades.tsv` | nâng cấp kỹ năng trân thú |
| `PetTitle.txt` | `pet_titles.tsv` | danh hiệu trân thú |
| `PetTypeAttr.txt` | `pet_types.tsv` | loại trân thú và tên hiển thị |
| `PlayerExpLevel.txt` | `player_exp_levels.tsv` | kinh nghiệm lên cấp của người chơi |
| `DarkExpLevel.txt` | `hidden_weapon_exp_levels.tsv` | kinh nghiệm lên cấp của ám khí |
| `LvMaxMoney.txt` | `money_caps_by_level.tsv` | trần tiền mang theo cấp |
| `CommonItem.txt` | `items_common.tsv` | vật phẩm thường: loại, giá, xếp chồng, script, kỹ năng dùng |
| `EquipBase.txt` | `equipment.tsv` | trang bị: vị trí, bộ, yêu cầu, giá, thuộc tính |
| `EquipExtraAttr.txt` | `equipment_extra_attributes.tsv` | hạn dùng, kiểu giao dịch, bán ra tiền gì |
| `EquipSetAttr.txt` | `equipment_sets.tsv` | hiệu ứng bộ trang bị |
| `EquipLevelUp.txt` | `equipment_level_up_odds.tsv` | xác suất nâng cấp theo dải cấp |
| `EquipVisual.txt` | `equipment_visual_groups.tsv` | nhóm hình dạng trang bị |
| `ItemEnhance.txt` | `equipment_enhance.tsv` | cường hoá: phí, tỉ lệ, cấp tụt, chỉ số cộng |
| `SlotCost.txt` | `equipment_slot_costs.tsv` | phí và vật liệu đục lỗ |
| `RepairRate.txt` | `repair_rates.tsv` | hệ số phí sửa theo cấp |
| `ItemRule.txt` | `item_rules.tsv` | luật vứt, chồng, bán, giao dịch, khoá khi nhặt hay mặc, cất ngân hàng |
| `ItemAptRate.txt` | `item_aptitude_rates.tsv` | hệ số theo điểm tư chất |
| `ItemSegValue.txt` | `item_segment_values.tsv` | bản 65 cột của client |
| `ItemCompound.txt` | `recipes.tsv` | công thức chế tạo |
| `GemInfo.txt` | `gems.tsv` | ngọc và thuộc tính |
| `GemCarve.txt` | `gem_carving.tsv` | chạm ngọc |
| `GemMelting.txt` | `gem_melting.tsv` | nung ngọc |
| `StoreMapItem.txt` | `treasure_maps.tsv` | bản đồ kho báu |
| `DropNotify.txt` | `drop_broadcasts.tsv` | mẫu phát thanh khi rơi đồ |
| `ShopTable.txt` | `shops.tsv` | cửa hàng NPC: loại tiền, hệ số giá, làm mới, hàng |
| `ShopSceneLimiti.txt` | `shop_scene_limits.tsv` | cảnh cho phép từng cửa hàng |
| `RecycleItem.txt` | `recycle_items.tsv` | vật phẩm thu hồi |
| `RecycleItemClass.txt` | `recycle_classes.tsv` | lớp thu hồi |
| `RecycleItemType.txt` | `recycle_types.tsv` | loại thu hồi |
| `Ability.txt` | `life_skills.tsv` | kỹ năng sống: cấp, dụng cụ, bàn chế tác, tiêu hao |
| `AbilityExpTable.txt` | `life_skill_proficiency.tsv` | độ thuần thục nhận từ từng đối tượng |
| `GrowPoint.txt` | `grow_point_types.tsv` | loại điểm thu thập: kỹ năng sống, nhiệm vụ, script |
| `Mission_Delivery.txt` | `quests_delivery.tsv` | nhiệm vụ giao vật |
| `Mission_EnterArea.txt` | `quests_enter_area.tsv` | nhiệm vụ vào vùng |
| `Mission_Husong.txt` | `quests_escort.tsv` | nhiệm vụ hộ tống |
| `Mission_KillMonster.txt` | `quests_kill.tsv` | nhiệm vụ diệt quái |
| `Mission_LootItem.txt` | `quests_loot.tsv` | nhiệm vụ nhặt vật |
| `Mission_NpcDefault.txt` | `npc_default_dialogue.tsv` | lời thoại mặc định của NPC |
| `MissionItem_HashTable.txt` | `quest_item_pool.tsv` | kho vật phẩm cho nhiệm vụ ngẫu nhiên |
| `MissionItem_GroupHashTable.txt` | `quest_item_groups.tsv` | nhóm vật phẩm của nhiệm vụ ngẫu nhiên |
| `MissionNPC_HashTable.txt` | `quest_npc_pool.tsv` | kho NPC cho nhiệm vụ ngẫu nhiên |
| `MissionPet_HashTable.txt` | `quest_pet_pool.tsv` | kho trân thú cho nhiệm vụ ngẫu nhiên |
| `StorytellingDuologue.txt` | `storyteller_dialogue.tsv` | lời của người kể chuyện |
| `ActivityNotice.txt` | `activity_notices.tsv` | lịch và lời báo của hoạt động |
| `ActivityRuler.txt` | `activity_rules.tsv` | hoạt động mở ở cảnh nào với tỉ lệ nào |
| `CampaignTable.txt` | `campaigns.tsv` | chiến dịch: lịch, tên, mô tả, theo dõi |
| `SceneAttr.txt` | `scene_attributes.tsv` | loại cảnh, mức an toàn, điểm đứng được, quái của cảnh |
| `LogicSceneAttr.txt` | `scene_trade_zones.tsv` | cảnh thuộc khu thương mại nào |
| `TransportDefine.txt` | `transports.tsv` | điểm và tuyến dịch chuyển |
| `BusInfo.txt` | `bus_types.tsv` | xe chở khách: tốc độ, số chỗ, điểm gắn |
| `CharMount.txt` | `mounts.tsv` | thú cưỡi |
| `MountFlightMaps.txt` | `flight_maps.tsv` | cảnh có bay |
| `CharFaceGeo.txt` | `face_models.tsv` | mặt: giới, tệp, chi phí đổi, chọn được lúc tạo |
| `CharHairGeo.txt` | `hair_models.tsv` | tóc, cùng bố cục |
| `HairStyle.txt` | `hair_style_costs.tsv` | chi phí đổi kiểu tóc |
| `CharHead.txt` | `portraits.tsv` | chân dung |
| `CharTitle.txt` | `titles.tsv` | danh hiệu |
| `ReputationTable.txt` | `reputation_factions.tsv` | thế lực và ma trận quan hệ |
| `ChatConfig.txt` | `chat_channels.tsv` | kênh chat: giãn cách gửi, tiêu hao, cấp tối thiểu |
| `StrFilter.txt` | `text_filter.tsv` | từ cấm |
| `CityInfo.txt` | `guild_cities.tsv` | thành của bang: cảnh, lối vào, đặc sản |
| `CityBuilding.txt` | `city_buildings.tsv` | công trình của thành |
| `CityIdOfChina.txt` | `real_cities_cn.tsv` | thành phố Trung Quốc; chỉ nạp nếu giữ tính năng cùng thành phố |
| `CommerceRelation.txt` | `trade_zone_relations.tsv` | quan hệ giữa các khu thương mại |
| `Condition.txt` | `guild_research_conditions.tsv` | điều kiện nghiên cứu của bang |
| `ResearchItem.txt` | `guild_research_items.tsv` | vật phẩm nghiên cứu của bang |
| `MasterExpAssign.txt` | `mentor_exp_share.tsv` | phần kinh nghiệm đồ đệ góp cho sư phụ |

Ba thư mục con của `Public/Config`:

| Thư mục | Tên mới | Nội dung |
|---|---|---|
| `AbilityLevelUp/` (24 tệp) | `life_skill_levels/<khoá>.tsv` | bảng lên cấp của từng kỹ năng sống: tiền, kinh nghiệm, trần thuần thục |
| `RandShop/` (15 tệp ini) | `random_shop_goods.tsv` | một bảng, thêm cột `shop_key`; mỗi dòng: vật phẩm, số lượng, xác suất, giá |
| `MountFlight/` (141 tệp: `.Fly`, `.mfm`, `.mft` của 47 cảnh) | `scenes/<scene>/flight.*` | dữ liệu bay; nhị phân, chưa đọc định dạng |

Khoá của `life_skill_levels/`: `assistant`, `assistant_menpai` thành `assistant_sect`; `caikuang`
`mining`; `cailiaojiagong` `material_processing`; `caiyao` `herb_gathering`; `diaoyu` `fishing`;
`dingweifu` `locator_charm`; `fengren` `tailoring`; `gaojishenghuo` `advanced_life`; `gongyi`
`crafting`; `menpai` `sect`; `menpaifuzhu` `sect_assist`; `menpaishenghuo` `sect_life`; `normal`;
`pengren` `cooking`; `putongshenghuo` `basic_life`; `shenghuofuzhu` `life_assist`; `xiangqian`
`gem_setting`; `yangsheng` `health`; `yaoli` `pharmacology`; `zhiyao` `medicine_making`; `zhongzhi`
`planting`; `zhuzao` `forging`; `XinFaStudySpend_V1` là bản chép của bảng ở thư mục cha, bỏ.

Khoá `shop_key` của `random_shop_goods.tsv`: `60wufang`, `70wufang`, `80wufang`, `90wufang`,
`100wufang` thành `workshop_60` tới `workshop_100`; `dazaotu` `blueprints`; `randgemshop` `gems`;
`huanglong_randgemshop`, `miaojiang_randgemshop`, `qiongzhou_randgemshop`, `shuhe_randgemshop`
thành `gems_huanglong`, `gems_miaojiang`, `gems_qiongzhou`, `gems_shuhe`; `petskillshop`
`pet_skills`; `shanedian` `morality`; `shide` `mentor_virtue`; `xunluozawu` `patrol_sundries`.

## 7. Tệp theo cảnh (`SERVER/scenes/<scene>/`)

Bản 0859602 có 244 tệp `.scn`; mỗi tệp trỏ các tệp cùng tiền tố. Tên thư mục `<scene>` lấy từ tên
tệp gốc (`luoyang`, `suzhou`, `dali`), vốn đã là tên riêng viết Latin.

| Tệp gốc | Số tệp | Tên mới | Nội dung |
|---|---|---|---|
| `<s>.scn` | 244 | `scene.toml` | danh sách tệp của cảnh; thêm cỡ lưới và phiên bản dữ liệu |
| `<s>.nav` | 231 | `walk.nav` | lưới đi được; đầu tệp là hai u16 cỡ lưới (luoyang: 640 x 640) |
| `<s>.path` | 234 | `paths.bin` | đồ thị đường đi; nhị phân, chưa đọc định dạng |
| `<s>_monster.ini` | 237 | `spawns.tsv` | quái và NPC: guid, loại, tên, toạ độ, hướng, script id, thời gian sinh lại, nhóm, AI, tuyến tuần, cửa hàng, cấp |
| `<s>_monster_level.ini` | 2 | cột `level` của `spawns.tsv` | cấp ghi đè theo từng quái |
| `<s>_monster_<cấp>.ini` và các dạng `<s>_<n>monster_<cấp>.ini` | 1.326 | `spawns.level_<cấp>.tsv` | bản quái của phó bản theo mốc cấp người chơi (10, 20 tới 200) |
| `PCity_monster_<lối vào>.ini` | 18 | `spawns.<entrance>.tsv` | quái của thành bang theo từng lối vào |
| `<s>_area.ini` | 233 | `areas.tsv` | vùng sự kiện hình chữ nhật và script id |
| `<s>_patrolpoint.ini` | 229 | `patrols.tsv` | tuyến tuần: dãy điểm |
| `<s>_growpoint.txt` | 228 | `grow_points.tsv` | điểm thu thập: loại, toạ độ |
| `<s>_growpointsetup.txt` | 61 | `grow_point_rules.tsv` | số lượng, số sinh mỗi lần, nhịp bổ sung |
| `<s>_pet.ini` | 63 | `wild_pets.tsv` | trân thú hoang |
| `<s>_platform.ini` | 39 | `platforms.tsv` | bàn chế tác: loại, toạ độ, hướng, script |
| `<s>_portal.ini` | 2 | `portals.tsv` | cổng dịch chuyển: toạ độ, cảnh đích, toạ độ đích, hướng |
| `<s>_bus.ini` | 1 | `buses.tsv` | xe: loại, tuyến tuần, chiều chạy |
| `<s>_StallInfo.stall` | 73 | `stalls.bin` | lưới ô được bày bán; nhị phân, chưa đọc định dạng |
| `<s>.ObjRegion` | 28 | `object_regions.bin` | vùng vật cản động; các tệp đã xem dài 4 byte |
| `testdata.txt`, `testsetup.txt` | 2 | bỏ | tệp thử |

Thứ đợt 1 của mốc P1 đo được trên đĩa (2026-10-07), bổ sung cho bảng trên:

- Tệp quái còn ba loại section ngoài `[monsterN]`: `[setting]`, `[operateN]`, `[data_defN]`. Chúng
  thành `spawn_operates.tsv` và `spawn_operate_values.tsv` của cảnh.
- `<s>_monster_level.ini` không ghi đè cột `level`: `LoadMonster` của mã 2008 đọc `level` ngay trong
  section quái. Tệp đó xuất riêng thành `spawn_levels.tsv`.
- Tệp quái và tệp vùng của phó bản do script chọn lúc tạo cảnh, bằng `LuaFnSetSceneLoad_Monster`,
  `LuaFnSetSceneLoad_Area`, `LuaFnSetSceneLoad_Map` (255 lời gọi trong `Public/Data/Script`). Tên
  tệp vì vậy không đủ để biết nó thuộc cảnh nào.
- 45 tệp không có `.scn` cha (số 7 và 38 dưới đây là số đo sơ bộ; số đúng ở mục đợt 2 bên dưới): 7
  tệp được script nạp (`_pingpan_40`, `_pingpan_55`, `_pingpan_70`,
  `_pingpan_85` cho cảnh `_pingpan_1`; `gongdishaolinmis`, `jishiemeimis`, `yamentianshanmis` cho
  `gongdi`, `jishi`, `yamen`), 38 tệp của năm cảnh đăng nhập và chọn nhân vật phía client
  (`chuangjian`, `xuanren`, `登陆`, `选人`, `选人11`) không được máy chủ nào trỏ tới.
- 231 tệp `.nav` chỉ có 165 nội dung khác nhau; nhiều cảnh dùng chung một lưới.

Thứ đợt 2 đo được (2026-10-07), Claude đã kiểm lại bằng `docs/giao-viec/P1-DOT-2/kiem-claude/`:

- Số đúng của 45 tệp không có `.scn` cha là 10 và 35, không phải 7 và 38: thêm hai tệp
  `yamentianshanmis` mà script gọi qua hằng chuỗi, và năm cảnh đăng nhập mỗi cảnh 7 tệp. Mười tệp do
  script nạp nằm trong thư mục cảnh dưới tên `spawns.set_<thân tên>.tsv`, `areas.set_<thân tên>.tsv`;
  căn cứ từng tệp ở `TOOLS/server/scene_attach.tsv`.
- `Public/Data/Script` có 4.248 tệp `.lua` với 255 lời gọi `LuaFnSetSceneLoad_*`, 5 lời nằm sau
  `--`. 250 lời còn lại ở `tables/server/scene_load_refs.tsv`: 140 ghi thẳng tên tệp, 48 qua hằng
  chuỗi cùng tệp, 50 dựng tên bằng `format` hay nối chuỗi, 12 không giải được tĩnh.
- Bốn lời gọi của `event/fuben/efuben_3_shuilao.lua` (dòng 314, 318, 322, 326) nạp
  `shuilao_monster_15.ini`, `_25`, `_35`, `_45`. Bốn tệp đó không có trong `Public/Scene`; chỉ có
  các cấp tròn chục.
- Trong mã 2008 (`LuaFnTbl_Scene.h` dòng 238, 268, 298), `LuaFnSetSceneLoad_GrowPointSetup`,
  `LuaFnSetSceneLoad_Area` và `LuaFnSetSceneLoad_Pet` đều gọi `SetSceneLoad_GrowPointData`. Theo mã
  đó thì tên tệp vùng do script chọn không đi vào chỗ nạp vùng. Chưa biết exe bản 0859602 có còn
  như vậy không; khi port việc tạo phó bản (P7) phải quyết theo tên hàm hay theo mã.
- 1.344 tệp quái theo cấp, nhóm và lối vào: script trỏ tới 1.123 tệp, không script nào trỏ tới 221
  tệp. Trong 1.123 tệp có 863 tệp nằm đúng thư mục của cảnh mà script nạp nó vào, 80 tệp lệch (ví
  dụ `murenxiang_monster_<cấp>.ini` được nạp vào cảnh dùng `xingxiu.nav`), 180 tệp không suy được
  cảnh vì lời gọi chọn lưới không giải được tĩnh. Chưa chuyển tệp nào.
- Bốn nguồn khai số lượng ít hơn số section thật: `SceneInfo.ini` (`scenenumber=723`, 923 section),
  `SystemInfo.ini` (`broadcount=0` với 10 thông báo, `huodongcount=0` với 30 hoạt động),
  `RandShop/shide.ini` (`Total=9`, 10 mặt hàng). Năm bảng tương ứng có cột `within_declared_count`:
  1 khi bộ đọc gốc nạp dòng đó, 0 khi không.
- Căn cột 76 cặp bảng đổi bố cục: 4.517 cột phía 2026 và 3.157 cột phía 0859602; 945 cột ghép
  chắc bằng dữ liệu (khớp từ 95% id chung), 779 cột ghép theo vị trí giữa hai cột chắc, 173 cột đổi
  kiểu, 2.620 cột mới ở 2026, 1.260 cột của 0859602 không còn. Tổng kết từng cặp ở
  `TOOLS/server/column_alignment.tsv`.
- Hiệu id của 106 cặp bảng cùng tên, so nguyên văn ô đầu: bản 2026 có 354.614 id, bản 0859602 có
  62.374, chung 61.522; 852 id chỉ có ở 0859602. Quái trong 244 cảnh của bản 0859602 (40.168 dòng,
  3.490 loại) đều có trong bảng quái 2026, trừ loại `3364` ở 10 dòng, loại này cũng không có trong
  bảng quái 0859602.
- 4.014 tệp TSV của `tables` và `scenes` có 22.013.470 ô; 265 ô cột `int` và 26 ô cột `float` chưa ở
  dạng chính tắc (số 0 đứng đầu, dấu cách cuối). Đợt 3 đưa về dạng chính tắc theo giá trị mà `atoi`
  và `atof` của bộ đọc gốc đọc ra.

Với cảnh chỉ có ở client 2026, dữ liệu trên không tồn tại. Lưới đi nấu từ `.region` (469 tệp),
`.wcollision` (435), `.path` (419) và `.heightmap` (473) của client; quái, vùng, tuần, điểm thu thập
phải dựng lại.

## 8. Script và AI

| Tệp gốc | Số phận | Ghi chú |
|---|---|---|
| `Public/Data/Script.dat` | `tables/server/script_index.tsv`, chỉ công cụ đọc | 4.957 dòng: script id sang đường dẫn Lua; id này xuất hiện trong `spawns.tsv`, `areas.tsv`, `items_common.tsv`, `scheduled_events.tsv` |
| `Public/Data/Script/obj/*.lua` | đầu vào của công cụ trích | 2.768 tệp: hội thoại và chức năng của NPC |
| `Public/Data/Script/event/*.lua` | đầu vào của công cụ trích | 1.463 tệp: nhiệm vụ, sự kiện, vùng |
| `Public/Data/Script/*.lua` | đầu vào của công cụ trích | 17 tệp: `scene.lua`, `ScriptGlobal.lua`, `mail.lua`, `player_login.lua`, thành bang |
| `Public/Data/AIScript.dat` | `tables/server/monster_ai_scripts.tsv` | số AI sang tệp `.ai` |
| `Public/Data/AIScript/*.ai` | `tables/server/monster_ai_rules.tsv` | 269 tệp ngôn ngữ nhỏ: khối `[skill]`, `[beskill]`, `[damage]`, `[dead]`, mỗi dòng một điều kiện và một dãy lệnh `AIS_*`; chuyển thành dòng bảng với tập lệnh đóng |

Máy chủ không nạp Lua. Các bảng sinh ra từ Lua (hội thoại, bước nhiệm vụ, điều kiện, phần thưởng,
danh sách handler) được định nghĩa ở bước P7 của kế hoạch, sau khi công cụ trích đo được mẫu nào
chiếm bao nhiêu phần trăm số script.

## 9. Bảng chỉ có ở client 2026

Client 2026 có 722 tệp ở tầng trên cùng của `Config`, cộng 24 bảng trong `AbilityLevelUp` và 3 bảng
trong `ActionSet`: 745 bảng DBC. 83 bảng trùng tên với `Public/Config` bản 0859602 (mục 6).
Phần dưới là 574 bảng còn lại và 61 tệp biến thể. Tên mới sinh bằng luật: thay cụm pinyin và viết
tắt đã giải được bằng từ tiếng Anh, rồi tách CamelCase thành `snake_case`. Cột "Cỡ" là số cột và số
bản ghi đọc từ đầu DBC.

Bảng có ở client không có nghĩa là có dữ liệu phía máy chủ: mỗi hệ dưới đây còn thiếu công thức,
xác suất và bảng rơi mà chỉ máy chủ gốc giữ.

### Hệ trưởng thành của bản 2026 (107 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `AbilityZhuanJing` | `life_skill_mastery.tsv` | 8 cột, 1001 dòng | |
| `CangPin` | `collectibles.tsv` | 16 cột, 54 dòng | |
| `CangPin_ClassLevel` | `collectible_class_levels.tsv` | 2 cột, 66 dòng | |
| `CangPin_Item` | `collectible_items.tsv` | 4 cột, 54 dòng | |
| `CangPin_Level` | `collectible_levels.tsv` | 12 cột, 486 dòng | |
| `CangPin_QualUp` | `collectible_quality_up.tsv` | 26 cột, 1 dòng | |
| `CangPin_RankBonus` | `collectible_rank_bonuses.tsv` | 47 cột, 12 dòng | |
| `CangPin_Set` | `collectible_sets.tsv` | 21 cột, 14 dòng | |
| `CangPinSetEffect` | `collectible_set_effects.tsv` | 9 cột, 14 dòng | |
| `CangPinShop` | `collectible_shop.tsv` | 7 cột, 58 dòng | |
| `ChongLouShop` | `chonglou_shop.tsv` | 13 cột, 11 dòng | |
| `ChongLouType` | `chonglou_types.tsv` | 2 cột, 25 dòng | |
| `DarkBaseQuality` | `hidden_weapon_base_quality.tsv` | 2 cột, 8 dòng | |
| `DarkLYCuiDuLevelUP` | `hidden_weapon_ly_poison_level_up.tsv` | 9 cột, 21 dòng | ? không rõ LY |
| `DarkLYStarUpData` | `hidden_weapon_ly_star_up_data.tsv` | 3 cột, 9 dòng | ? không rõ LY |
| `DecoWeaponConvert` | `deco_weapon_convert.tsv` | 5 cột, 381 dòng | |
| `DecoWeaponLevelUp` | `deco_weapon_level_up.tsv` | 26 cột, 214 dòng | |
| `DiaowenInfo` | `engravings.tsv` | 96 cột, 1780 dòng | |
| `diaowenpingfen` | `engraving_scores.tsv` | 4 cột, 1780 dòng | |
| `DiaowenRule` | `engraving_rules.tsv` | 23 cột, 16 dòng | |
| `FiveElementsExtend` | `five_elements_extend.tsv` | 6 cột, 5 dòng | |
| `FiveElementsValue` | `five_elements_values.tsv` | 6 cột, 100 dòng | |
| `HXYBase` | `hero_seal_base.tsv` | 14 cột, 32 dòng | |
| `HXYEffect` | `hero_seal_effects.tsv` | 6 cột, 147 dòng | |
| `HXYExAttr` | `hero_seal_extra_attributes.tsv` | 65 cột, 21 dòng | |
| `HXYLevel` | `hero_seal_levels.tsv` | 3 cột, 100 dòng | |
| `KFSAttrEx` | `martial_soul_extra_attributes.tsv` | 70 cột, 160 dòng | ? KFS suy là võ hồn (cửa sổ Wuhun*), chưa có chuỗi xác nhận |
| `KFSAttrExBook` | `martial_soul_extra_attributes_books.tsv` | 2 cột, 16 dòng | ? như KFSAttrEx |
| `KFSAttrLevelUp` | `martial_soul_attributes_level_up.tsv` | 26 cột, 121 dòng | ? như KFSAttrEx |
| `KFSBase` | `martial_soul_base.tsv` | 35 cột, 4 dòng | ? như KFSAttrEx |
| `KFSCompoudEx` | `martial_soul_compound_ex.tsv` | 2 cột, 10 dòng | ? như KFSAttrEx |
| `KFSLevelupExp` | `martial_soul_level_up_exp.tsv` | 2 cột, 120 dòng | ? như KFSAttrEx |
| `KFSSkillLevelup` | `martial_soul_skill_level_up.tsv` | 5 cột, 294 dòng | ? như KFSAttrEx |
| `KFSSlot` | `martial_soul_slots.tsv` | 6 cột, 10 dòng | ? như KFSAttrEx |
| `LiuboEquipLevelup` | `liubo_equipment_level_up.tsv` | 21 cột, 180 dòng | ? không rõ Liubo |
| `LiuboEquipStarup` | `liubo_equipment_star_up.tsv` | 21 cột, 180 dòng | ? không rõ Liubo |
| `LongWenAddAttr` | `dragon_mark_add_attributes.tsv` | 21 cột, 90 dòng | |
| `LongWenBase` | `dragon_mark_base.tsv` | 13 cột, 100 dòng | |
| `LongWenRateBase` | `dragon_mark_rate_base.tsv` | 12 cột, 9 dòng | |
| `MartialAttr` | `martial_attributes.tsv` | 59 cột, 9 dòng | |
| `MartialLevel` | `martial_levels.tsv` | 7 cột, 151 dòng | |
| `MiFaInfo` | `secret_art.tsv` | 26 cột, 142 dòng | |
| `MilitaryDetails` | `military_details.tsv` | 33 cột, 18 dòng | |
| `MilitaryEffect` | `military_effects.tsv` | 16 cột, 77 dòng | |
| `NobilityDetails` | `nobility_details.tsv` | 10 cột, 7 dòng | |
| `PneumaInfo` | `pneuma.tsv` | 11 cột, 2052 dòng | |
| `PneumaSet` | `pneuma_sets.tsv` | 22 cột, 6 dòng | |
| `RLAttrEx` | `rl_extra_attributes.tsv` | 66 cột, 11 dòng | ? không rõ RL (có cửa sổ RLXZ) |
| `RLBase` | `rl_base.tsv` | 8 cột, 5 dòng | ? không rõ RL |
| `RLSkillBook` | `rl_skill_books.tsv` | 2 cột, 23 dòng | ? không rõ RL |
| `RLStar` | `rl_stars.tsv` | 5 cột, 9 dòng | ? không rõ RL |
| `RSInfo` | `rs.tsv` | 67 cột, 20 dòng | ? không rõ RS |
| `RSSkill` | `rs_skills.tsv` | 23 cột, 23 dòng | ? không rõ RS (kỹ năng hoá kình) |
| `ShenqiLeveUp` | `shenqi_level_up.tsv` | 8 cột, 237 dòng | |
| `SummonerAttr` | `summoner_attributes.tsv` | 87 cột, 25 dòng | ? chưa rõ hệ |
| `SummonerWeapon` | `summoner_weapons.tsv` | 3 cột, 249 dòng | ? chưa rõ hệ |
| `SuperWeapon9skill` | `super_weapon_9_skills.tsv` | 3 cột, 135 dòng | |
| `SuperWeapon9WG` | `super_weapon_9_wg.tsv` | 9 cột, 135 dòng | ? WG suy là ngoại quan |
| `SuperWeaponDownItemBack` | `super_weapon_down_item_back.tsv` | 6 cột, 334 dòng | |
| `SuperWeaponDownMaterial` | `super_weapon_down_material.tsv` | 8 cột, 19 dòng | |
| `SuperWeaponJJ` | `super_weapon_advance.tsv` | 14 cột, 469 dòng | |
| `SuperWeaponQH` | `super_weapon_enhance.tsv` | 13 cột, 79 dòng | |
| `SuperWeaponSkillActivation` | `super_weapon_skill_activation.tsv` | 4 cột, 12 dòng | |
| `SuperWeaponSkillLevelUp` | `super_weapon_skill_level_up.tsv` | 7 cột, 9 dòng | |
| `SuperWeaponSX` | `super_weapon_attributes.tsv` | 23 cột, 81 dòng | |
| `SuperWeaponTL` | `super_weapon_tl.tsv` | 8 cột, 302 dòng | ? không rõ TL |
| `SuperWeaponUp` | `super_weapon_up.tsv` | 25 cột, 699 dòng | |
| `SuperWeaponWG` | `super_weapon_wg.tsv` | 7 cột, 167 dòng | ? WG suy là ngoại quan |
| `SuperWeaponWG_V1` | `super_weapon_wg_v1.tsv` | 9 cột, 135 dòng | ? bảng khác SuperWeaponWG (9 cột, 135 dòng); WG suy là ngoại quan |
| `TalentInfo` | `talents.tsv` | 25 cột, 15 dòng | |
| `TalentLayerLevel` | `talent_layer_levels.tsv` | 6 cột, 10 dòng | |
| `UnderArmour` | `under_armour.tsv` | 16 cột, 3 dòng | |
| `UnderArmourJewel` | `under_armour_jewels.tsv` | 57 cột, 18 dòng | |
| `UnderArmourJewelCompound` | `under_armour_jewel_compound.tsv` | 8 cột, 18 dòng | |
| `UnderArmourJewelEffect` | `under_armour_jewel_effects.tsv` | 7 cột, 16 dòng | |
| `UnderArmourJewelExtra` | `under_armour_jewel_extra.tsv` | 18 cột, 18 dòng | |
| `UnderArmourLevel` | `under_armour_levels.tsv` | 84 cột, 165 dòng | |
| `UnderArmourPlate` | `under_armour_plates.tsv` | 27 cột, 7 dòng | |
| `UnderArmourRank` | `under_armour_ranks.tsv` | 5 cột, 6 dòng | |
| `UnderArmourStar` | `under_armour_stars.tsv` | 7 cột, 10 dòng | |
| `UnderArmourWash` | `under_armour_wash.tsv` | 47 cột, 3 dòng | |
| `XingZhen` | `star_array.tsv` | 17 cột, 98 dòng | |
| `XingZhen_AttrPriority` | `star_array_attributes_priorities.tsv` | 2 cột, 112 dòng | |
| `XingZhen_Chip` | `star_array_chips.tsv` | 5 cột, 196 dòng | |
| `XingZhen_CritXS` | `star_array_crit_coefficients.tsv` | 5 cột, 14 dòng | |
| `XingZhen_Interests` | `star_array_interests.tsv` | 8 cột, 92 dòng | |
| `XingZhen_JiBan_Award` | `star_array_bond_awards.tsv` | 13 cột, 130 dòng | |
| `XingZhen_Level` | `star_array_levels.tsv` | 20 cột, 5390 dòng | |
| `XingZhen_NPCShop` | `star_array_npc_shop.tsv` | 51 cột, 2 dòng | |
| `XingZhen_NPCShopItem` | `star_array_npc_shop_items.tsv` | 11 cột, 40 dòng | |
| `XingZhen_Skill` | `star_array_skills.tsv` | 20 cột, 46 dòng | |
| `XingZhen_Skill_PingFen` | `star_array_skill_scores.tsv` | 5 cột, 230 dòng | |
| `XingZhen_SkillBook` | `star_array_skill_books.tsv` | 8 cột, 276 dòng | |
| `XingZhen_YingXiong` | `star_array_heroes.tsv` | 15 cột, 46 dòng | |
| `XingZhen_YingXiong_Award` | `star_array_hero_awards.tsv` | 5 cột, 184 dòng | |
| `XiuLianBook` | `cultivation_books.tsv` | 4 cột, 3 dòng | |
| `XiuLianDetail` | `cultivation_detail.tsv` | 63 cột, 2416 dòng | |
| `XiuLianMiJi` | `cultivation_manuals.tsv` | 5 cột, 15 dòng | |
| `XiuLianNewScore` | `cultivation_new_scores.tsv` | 16 cột, 16 dòng | |
| `XiuLianRate` | `cultivation_rates.tsv` | 3 cột, 150 dòng | |
| `XiuLianRule` | `cultivation_rules.tsv` | 4 cột, 31 dòng | |
| `XueWeiBook` | `acupoint_books.tsv` | 4 cột, 21 dòng | |
| `YueLiAttr` | `seniority_attributes.tsv` | 34 cột, 36 dòng | ? suy từ pinyin |
| `ZhenFaAttr` | `formation_attributes.tsv` | 7 cột, 20 dòng | ? suy từ pinyin |
| `ZhenFaDemand` | `formation_demand.tsv` | 4 cột, 100 dòng | ? suy từ pinyin |
| `ZhenfaImpact` | `formation_effects.tsv` | 26 cột, 101 dòng | ? suy từ pinyin |
| `zhenyuanpingfen` | `pneuma_scores.tsv` | 4 cột, 2052 dòng | |

### Thành tựu và sưu tập (15 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `ChengjiuAbility` | `achievement_life_skill.tsv` | 3 cột, 11 dòng; cột 2 là id kỹ năng sống | |
| `ChengjiuDesc` | `achievement_descriptions.tsv` | 25 cột, 750 dòng | |
| `ChengjiuExplore` | `achievement_explore.tsv` | 3 cột, 95 dòng | |
| `ChengjiuMission` | `achievement_missions.tsv` | 3 cột, 46 dòng | |
| `ChengjiuPVE` | `achievement_pve.tsv` | 4 cột, 159 dòng | |
| `ChengjiuRule` | `achievement_rules.tsv` | 14 cột, 750 dòng | |
| `ChengjiuSceneMission` | `achievement_scene_missions.tsv` | 3 cột, 490 dòng | |
| `ChengjiuType` | `achievement_types.tsv` | 14 cột, 11 dòng | |
| `RideCollection` | `ride_collections.tsv` | 5 cột, 8 dòng | |
| `RideCollectionEffect` | `ride_collection_effects.tsv` | 19 cột, 1 dòng | |
| `RideSeries` | `ride_series.tsv` | 36 cột, 8 dòng | |
| `Toy` | `toys.tsv` | 11 cột, 43 dòng | |
| `ToyItem` | `toy_items.tsv` | 4 cột, 45 dòng | |
| `Tujian` | `codex.tsv` | 19 cột, 234 dòng | |
| `XunzhangInfo` | `medals.tsv` | 19 cột, 3 dòng | |

### Kỹ năng (7 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `ComboSkillBook` | `combo_skill_books.tsv` | 10 cột, 34 dòng | |
| `ComboSkillRate` | `combo_skill_rates.tsv` | 7 cột, 99 dòng | |
| `RefixComboSkill` | `combo_skill_modifiers.tsv` | 8 cột, 66 dòng | |
| `RoguePT_Skill` | `rogue_tower_skills.tsv` | 6 cột, 45 dòng | ? PT suy là leo tháp |
| `SkillAddImpact` | `skill_add_effects.tsv` | 10 cột, 2 dòng | |
| `SkillDeplete` | `skill_costs.tsv` | 6 cột, 5399 dòng | |
| `ToushiSkill` | `toushi_skills.tsv` | 22 cột, 36 dòng | ? suy từ pinyin (thâu sư) |

### Vật phẩm, trang bị, ngoại quan (74 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `89kajiforbiditem` | `level_cap_89_forbidden_items.tsv` | 1 cột, 195 dòng | |
| `AbnormalItemList` | `abnormal_item_list.tsv` | 2 cột, 304 dòng | |
| `AbnormalPetList` | `abnormal_pet_list.tsv` | 2 cột, 1016 dòng | |
| `AppearanceAchivement` | `appearance_achievement.tsv` | 25 cột, 4980 dòng | |
| `AppearanceLevel` | `appearance_levels.tsv` | 3 cột, 11 dòng | |
| `Appearanceshop` | `appearance_shop.tsv` | 23 cột, 96 dòng | |
| `BanShengShuLiangRule` | `byproduct_quantity_rules.tsv` | 18 cột, 20 dòng | ? suy từ pinyin |
| `baoshiduihuan` | `gem_exchange.tsv` | 5 cột, 13 dòng | |
| `baoshipingfen` | `gem_scores.tsv` | 4 cột, 964 dòng | |
| `BlueEquipBase` | `equipment_blue.tsv` | 91 cột, 248 dòng | |
| `CampaignItem` | `campaign_items.tsv` | 12 cột, 5229 dòng | |
| `CardConflict` | `card_conflict.tsv` | 5 cột, 1178 dòng | |
| `CardRule` | `card_rules.tsv` | 19 cột, 59 dòng | |
| `CharHeadFrame` | `character_head_frames.tsv` | 42 cột, 108 dòng | |
| `CommonGiftBox` | `common_gift_boxs.tsv` | 108 cột, 469 dòng | |
| `Copyitemrecovery` | `instance_item_recovery.tsv` | 5 cột, 91 dòng | |
| `DoubleGemCompound` | `double_gem_compound.tsv` | 4 cột, 280 dòng | |
| `DressColorRate` | `dress_color_rates.tsv` | 34 cột, 166 dòng | |
| `DressColorSpecial` | `dress_color_special.tsv` | 2 cột, 25 dòng | |
| `DressGem` | `dress_gem.tsv` | 6 cột, 32 dòng | |
| `DressTransform` | `dress_transforms.tsv` | 26 cột, 1 dòng | |
| `DummyItem` | `dummy_items.tsv` | 4 cột, 6 dòng | |
| `EnchanceSetAttr` | `enhance_set_attributes.tsv` | 8 cột, 10 dòng | |
| `EquipAttaLevelup` | `equipment_atta_level_up.tsv` | 8 cột, 100 dòng | ? không rõ Atta |
| `EquipBase_TM` | `equipment_tm.tsv` | 102 cột, 106 dòng | ? không rõ TM |
| `EquipBase_TM9` | `equipment_tm9.tsv` | 102 cột, 106 dòng | ? không rõ TM9 |
| `EquipChangerate` | `equipment_change_rates.tsv` | 3 cột, 3 dòng | |
| `EquipDecompose` | `equipment_decompose.tsv` | 8 cột, 16 dòng | |
| `EquipDress` | `equipment_dress.tsv` | 7 cột, 1052 dòng | |
| `EquipLevelStd` | `equipment_level_standards.tsv` | 14 cột, 139 dòng | |
| `EquipPriLevelValue` | `equipment_pri_level_values.tsv` | 2 cột, 238 dòng | ? không rõ Pri |
| `EquipPriMpWuqi` | `equipment_pri_sect_weapons.tsv` | 3 cột, 13 dòng | ? không rõ Pri |
| `EquipPriRateValue` | `equipment_pri_rate_values.tsv` | 3 cột, 9 dòng | ? không rõ Pri |
| `EquipUpstage` | `equipment_upstage.tsv` | 2 cột, 38 dòng | |
| `EquipUpstageAttrWeight` | `equipment_upstage_attributes_weight.tsv` | 3 cột, 64 dòng | |
| `EquipUpstageChongLou` | `equipment_upstage_chonglou.tsv` | 7 cột, 41 dòng | |
| `EquipUpstageMat` | `equipment_upstage_materials.tsv` | 34 cột, 5 dòng | |
| `Exterior_BG` | `exterior_back_decor.tsv` | 26 cột, 27 dòng | |
| `Exterior_BGTSitem` | `exterior_back_top_decor_items.tsv` | 4 cột, 117 dòng | |
| `Exterior_DressStyle` | `exterior_dress_styles.tsv` | 21 cột, 316 dòng | |
| `Exterior_DressStyle_Achivement` | `exterior_dress_style_achievement.tsv` | 11 cột, 364 dòng | |
| `Exterior_ExchangeItem` | `exterior_exchange_items.tsv` | 4 cột, 3676 dòng | |
| `Exterior_Face` | `exterior_faces.tsv` | 9 cột, 219 dòng | |
| `Exterior_GemEffect` | `exterior_gem_effects.tsv` | 10 cột, 48 dòng | |
| `Exterior_Hair` | `exterior_hair.tsv` | 10 cột, 303 dòng | |
| `Exterior_Head` | `exterior_head.tsv` | 8 cột, 75 dòng | |
| `Exterior_HeadFrame` | `exterior_head_frames.tsv` | 11 cột, 108 dòng | |
| `Exterior_InfantHair` | `exterior_infant_hair.tsv` | 9 cột, 9 dòng | |
| `Exterior_Item` | `exterior_items.tsv` | 5 cột, 1413 dòng | |
| `Exterior_PetPoss` | `exterior_pet_possession.tsv` | 23 cột, 18 dòng | |
| `Exterior_Ride` | `exterior_rides.tsv` | 28 cột, 297 dòng | |
| `Exterior_TS` | `exterior_top_decor.tsv` | 27 cột, 72 dòng | |
| `Exterior_Weapon` | `exterior_weapons.tsv` | 9 cột, 966 dòng | |
| `Exterior_WeaponGroup` | `exterior_weapon_group.tsv` | 14 cột, 197 dòng | |
| `FeiPinHuiShou` | `junk_recycle.tsv` | 4 cột, 292 dòng | |
| `GemLevelup` | `gem_level_up.tsv` | 5 cột, 245 dòng | |
| `GoodsProtect_Goods` | `goods_protect_goods.tsv` | 2 cột, 4381 dòng | |
| `GoodsProtect_Pet` | `goods_protect_pets.tsv` | 2 cột, 0 dòng | |
| `GreenEquipBase` | `equipment_green.tsv` | 93 cột, 8197 dòng | |
| `installgemprice` | `gem_install_prices.tsv` | 2 cột, 100 dòng | |
| `ItemCardRule` | `item_card_rules.tsv` | 21 cột, 404 dòng | |
| `McardInfo` | `monthly_cards.tsv` | 65 cột, 2 dòng | |
| `MoneyRecycleItem` | `money_recycle_items.tsv` | 26 cột, 7 dòng | |
| `NewRoleEquipset` | `new_role_equipment_sets.tsv` | 5 cột, 3 dòng | |
| `NoPackingItems` | `no_packing_items.tsv` | 2 cột, 917 dòng | |
| `NumberingFashion` | `numbering_fashion.tsv` | 3 cột, 100 dòng | |
| `OptionalGiftBox` | `optional_gift_boxs.tsv` | 31 cột, 208 dòng | |
| `QianKunDai` | `qiankun_bag.tsv` | 7 cột, 8 dòng | |
| `RecipeKind` | `recipe_kinds.tsv` | 2 cột, 200 dòng | |
| `SafeItemList` | `safe_item_list.tsv` | 4 cột, 270 dòng | |
| `SpecialDressColor` | `special_dress_colors.tsv` | 67 cột, 8 dòng | |
| `WhiteEquipBase` | `equipment_white.tsv` | 93 cột, 354 dòng | |
| `ZhiZunEquipRate` | `supreme_equipment_rates.tsv` | 4 cột, 10 dòng | |
| `ZhuCaiShuLiangRule` | `main_material_quantity_rules.tsv` | 16 cột, 20 dòng | ? suy từ pinyin |

### Trân thú (25 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `HomePetExper` | `home_pet_exp.tsv` | 5 cột, 101 dòng | |
| `PetAttrJinJie` | `pet_attributes_advance.tsv` | 6 cột, 10 dòng | |
| `PetEquipBase` | `pet_equipment_base.tsv` | 104 cột, 875 dòng | |
| `PetEquipFuse` | `pet_equipment_fuse.tsv` | 8 cột, 6 dòng | |
| `PetEquipItemAptRate` | `pet_equipment_item_aptitude_rates.tsv` | 7 cột, 255 dòng | |
| `PetEquipItemEnhance` | `pet_equipment_item_enhance.tsv` | 12 cột, 45 dòng | |
| `PetEquipItemSegValue` | `pet_equipment_item_segment_values.tsv` | 59 cột, 300 dòng | |
| `PetEquipSetAttr` | `pet_equipment_set_attributes.tsv` | 20 cột, 164 dòng | |
| `PetEquipSlotCost` | `pet_equipment_slot_costs.tsv` | 10 cột, 480 dòng | |
| `PetEquipSuitUp` | `pet_equipment_suit_up.tsv` | 22 cột, 680 dòng | |
| `PetHuanhuaReverse` | `pet_transform_reverse.tsv` | 3 cột, 328 dòng | |
| `PetHuanhuaTable` | `pet_transforms.tsv` | 6 cột, 7039 dòng | |
| `PetHuanLing` | `pet_spirit_skins.tsv` | 11 cột, 242 dòng | |
| `PetHuanLingItem` | `pet_spirit_skin_items.tsv` | 3 cột, 277 dòng | |
| `PetLianHua` | `pet_refine.tsv` | 3 cột, 595 dòng | |
| `PetLingXing` | `pet_spirituality.tsv` | 24 cột, 23138 dòng | |
| `PetMaster` | `pet_master.tsv` | 12 cột, 116 dòng | |
| `PetNeiDan` | `pet_core.tsv` | 66 cột, 110 dòng | |
| `PetNeiDan_Shop` | `pet_core_shop.tsv` | 15 cột, 131 dòng | |
| `PetNeiDanItem` | `pet_core_items.tsv` | 4 cột, 220 dòng | |
| `PetNeiDanLianhua` | `pet_core_refine.tsv` | 20 cột, 85 dòng | |
| `PetNeiDanPool` | `pet_core_pool.tsv` | 6 cột, 442 dòng | |
| `PetPossColourRate` | `pet_possession_color_rates.tsv` | 43 cột, 131 dòng | |
| `PetPossPosition` | `pet_possession_position.tsv` | 6 cột, 26 dòng | |
| `PetPossPositionValue` | `pet_possession_position_values.tsv` | 9 cột, 9 dòng | |

### Con cái (10 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `Infant` | `infant.tsv` | 90 cột, 6 dòng | |
| `InfantCard` | `infant_cards.tsv` | 15 cột, 251 dòng | |
| `InfantDressColorRate` | `infant_dress_color_rates.tsv` | 31 cột, 49 dòng | |
| `InfantDressConvert` | `infant_dress_convert.tsv` | 4 cột, 39 dòng | |
| `InfantEnhance` | `infant_enhance.tsv` | 8 cột, 9 dòng | |
| `InfantExpMisTable` | `infant_exp_missions.tsv` | 9 cột, 72 dòng | |
| `InfantHeroLevel` | `infant_hero_levels.tsv` | 13 cột, 120 dòng | |
| `InfantLevelUpTable` | `infant_level_up.tsv` | 4 cột, 119 dòng | |
| `Infantskillinfo` | `infant_skills.tsv` | 15 cột, 8 dòng | |
| `Infantskillup` | `infant_skill_up.tsv` | 9 cột, 2 dòng | |

### Trang viên và động phủ (11 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `BieYeBuildingLevelUp` | `villa_building_level_up.tsv` | 12 cột, 24 dòng | |
| `BieYeFurniture` | `villa_furniture.tsv` | 33 cột, 414 dòng | |
| `BieYeFurnitureShop` | `villa_furniture_shop.tsv` | 4 cột, 24 dòng | |
| `BieYeHuanZhuang` | `villa_skins.tsv` | 46 cột, 2 dòng | |
| `BieYeHuanZhuangID` | `villa_skin_ids.tsv` | 14 cột, 2 dòng | |
| `BieYeMaterialOutput` | `villa_material_output.tsv` | 13 cột, 90 dòng | |
| `BieYeMengChong` | `villa_cute_pets.tsv` | 35 cột, 23 dòng | |
| `bieyemengchongcolor` | `villa_cute_pet_colors.tsv` | 5 cột, 111 dòng | |
| `bieyemengchongReputation` | `villa_cute_pet_reputation.tsv` | 4 cột, 18 dòng | |
| `BieYeSceneDefine` | `villa_scene_definitions.tsv` | 8 cột, 6 dòng | |
| `DongFuSceneInfo` | `cave_dwelling_scenes.tsv` | 5 cột, 15 dòng | |

### Bang hội, thành, tông môn (20 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `CityWarRankSeason` | `city_war_rank_seasons.tsv` | 8 cột, 20 dòng | |
| `DingZhiMenPaiSvr` | `custom_sect_servers.tsv` | 34 cột, 8 dòng | |
| `fmhostiletime` | `fengming_hostile_times.tsv` | 9 cột, 30 dòng | |
| `GuildBattleCDInfo` | `guild_battle_cooldown.tsv` | 3 cột, 4 dòng | |
| `GuildShop` | `guild_shop.tsv` | 151 cột, 5 dòng | |
| `GuildTaskPrize` | `guild_task_prizes.tsv` | 15 cột, 50 dòng | |
| `GuildZhaoHui_AwardLevel` | `guild_recall_award_levels.tsv` | 4 cột, 50 dòng | |
| `KajiGuildBattleGift` | `level_cap_guild_battle_gifts.tsv` | 3 cột, 2 dòng | |
| `KBuildingAttr` | `k_building_attributes.tsv` | 11 cột, 30 dòng | ? không rõ K |
| `KBuildingAttrEx` | `k_building_extra_attributes.tsv` | 13 cột, 150 dòng | ? không rõ K (mẫu: Vô Cực Điện) |
| `KCityShopCommodity` | `k_city_shop_commodities.tsv` | 4 cột, 3 dòng | ? không rõ K |
| `NewBangHuiFuli` | `new_guild_welfare.tsv` | 8 cột, 5 dòng | |
| `ZM_CharTitle` | `clan_character_titles.tsv` | 34 cột, 5 dòng | |
| `ZM_dizilevel` | `clan_disciple_levels.tsv` | 9 cột, 50 dòng | |
| `ZM_Shop` | `clan_shop.tsv` | 12 cột, 3 dòng | |
| `ZMPTEnter` | `clan_tower_enter.tsv` | 57 cột, 100 dòng | |
| `ZongMenBuffClean` | `clan_buff_clean.tsv` | 4 cột, 615 dòng | |
| `ZongmenEquip_Ext` | `clan_equipment_ext.tsv` | 12 cột, 75 dòng | |
| `ZongmenTalent` | `clan_talents.tsv` | 37 cột, 255 dòng | |
| `ZongmenTitle` | `clan_titles.tsv` | 4 cột, 21 dòng | |

### Nhiệm vụ, chiến lệnh (22 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `AwardTaskList` | `award_task_list.tsv` | 12 cột, 62 dòng | |
| `AwardTaskType` | `award_task_types.tsv` | 15 cột, 32 dòng | |
| `Catinfo` | `cat.tsv` | 10 cột, 10 dòng | |
| `CatMission` | `cat_missions.tsv` | 7 cột, 9 dòng | |
| `HLSCMissionInfo` | `hlsc_missions.tsv` | 16 cột, 150 dòng | ? không rõ HLSC |
| `HLSCProgressItemInfo` | `hlsc_progress_items.tsv` | 15 cột, 24 dòng | ? không rõ HLSC |
| `KillMonsterTaskExp` | `kill_monster_task_exp.tsv` | 4 cột, 100 dòng | |
| `Mission_SceneCycle` | `mission_scene_cycle.tsv` | 11 cột, 33 dòng | |
| `MissionData` | `mission_data.tsv` | 6 cột, 1 dòng | |
| `MissionDictionary` | `mission_dictionary.tsv` | 18 cột, 2139 dòng | |
| `MissionKind` | `mission_kinds.tsv` | 2 cột, 200 dòng | |
| `MissionOutline` | `mission_outline.tsv` | 26 cột, 994 dòng | |
| `NpcAttachMission` | `npc_attach_missions.tsv` | 7 cột, 876 dòng | |
| `SimplenessTaskManager` | `simpleness_task_manager.tsv` | 110 cột, 2 dòng | |
| `SummerZhanLingInfo` | `summer_battle_pass.tsv` | 30 cột, 20 dòng | |
| `TaskCollections` | `task_collections.tsv` | 59 cột, 1472 dòng | |
| `XinShouHeroesRoad` | `newbie_heroes_road.tsv` | 13 cột, 67 dòng | |
| `XinShouZhanLing_Award` | `newbie_battle_pass_awards.tsv` | 17 cột, 100 dòng | |
| `XinShouZhanLing_Mission` | `newbie_battle_pass_missions.tsv` | 7 cột, 166 dòng | |
| `ZhanLingInfo` | `battle_pass.tsv` | 75 cột, 407 dòng | |
| `ZhaoHui` | `resource_retrieval.tsv` | 9 cột, 10 dòng | |
| `ZhengZhao` | `recruitment.tsv` | 11 cột, 20 dòng | |

### Cửa hàng (45 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `BiWuShop` | `tournament_shop.tsv` | 33 cột, 10 dòng | |
| `Canyeshop` | `page_fragment_shop.tsv` | 8 cột, 22 dòng | |
| `ConvenientBuyShopTable` | `convenient_buy_shop.tsv` | 19 cột, 49 dòng | |
| `DaHuaQiXi_Shop` | `qixi_tale_shop.tsv` | 9 cột, 11 dòng | |
| `Di4Shop` | `palace4_shop.tsv` | 10 cột, 11 dòng | ? Di4 suy là địa cung tầng 4 |
| `DuanWeiHonourShop` | `rank_tier_honour_shop.tsv` | 241 cột, 11 dòng | |
| `DuanWeiYuanBaoShop` | `rank_tier_ingot_shop.tsv` | 241 cột, 11 dòng | |
| `FengMingShop` | `fengming_shop.tsv` | 12 cột, 35 dòng | |
| `gdxblsshop` | `gdxb_ls_shop.tsv` | 5 cột, 14 dòng | ? không rõ gdxb |
| `Guanshanhaishop` | `guanshanhai_shop.tsv` | 4 cột, 94 dòng | |
| `Guishi_Jiaoyihang` | `ghost_market_trading_house.tsv` | 7 cột, 48 dòng | |
| `GuiShi_NPCShop` | `ghost_market_npc_shop.tsv` | 51 cột, 9 dòng | |
| `GuiShi_NPCShopItem` | `ghost_market_npc_shop_items.tsv` | 21 cột, 151 dòng | |
| `HongBaoShop` | `red_envelope_shop.tsv` | 13 cột, 240 dòng | |
| `HuiLiu2022Shop` | `returnee_2022_shop.tsv` | 22 cột, 18 dòng | |
| `HuiLiuShop` | `returnee_shop.tsv` | 19 cột, 12 dòng | |
| `HuoYue_Shop` | `activeness_shop.tsv` | 19 cột, 74 dòng | |
| `JieBanShop` | `companion_shop.tsv` | 8 cột, 26 dòng | |
| `KMSDShop` | `kmsd_shop.tsv` | 4 cột, 3 dòng | ? không rõ KMSD |
| `LimitShop` | `limit_shop.tsv` | 5 cột, 105 dòng | |
| `LiWuDuiHuanShop` | `gift_exchange_shop.tsv` | 8 cột, 33 dòng | |
| `NationalShop` | `national_shop.tsv` | 14 cột, 18 dòng | |
| `PVPShop` | `pvp_shop.tsv` | 19 cột, 29 dòng | |
| `QiXi_Shop` | `qixi_shop.tsv` | 8 cột, 50 dòng | |
| `RichmanShop` | `monopoly_shop.tsv` | 7 cột, 11 dòng | |
| `ShideShop` | `mentor_virtue_shop.tsv` | 81 cột, 4 dòng | |
| `ShopBaodi` | `shop_pity.tsv` | 15 cột, 6 dòng | |
| `ShopDuihuan` | `shop_exchange.tsv` | 9 cột, 61 dòng | |
| `ShopLibao` | `shop_bundles.tsv` | 8 cột, 4 dòng | |
| `ShopRandom` | `shop_random.tsv` | 11 cột, 76 dòng | |
| `ShopTime` | `shop_time.tsv` | 7 cột, 1 dòng | |
| `ShopVIP` | `shop_vip.tsv` | 11 cột, 66 dòng | |
| `SJFHShop` | `sjfh_shop.tsv` | 7 cột, 17 dòng | ? không rõ SJFH |
| `SnsShop` | `sns_shop.tsv` | 7 cột, 0 dòng | |
| `T3ShopTable` | `t3_shop.tsv` | 282 cột, 5 dòng | ? không rõ T3 |
| `TianJiChengShop` | `tianji_city_shop.tsv` | 9 cột, 9 dòng | |
| `TLCJShop` | `tlcj_shop.tsv` | 12 cột, 5 dòng | ? TLCJ suy là cùng chế độ CJ |
| `VipStoneShopRule` | `vip_stone_shop_rules.tsv` | 23 cột, 33 dòng | |
| `WeekShopCommon` | `week_shop_common.tsv` | 23 cột, 0 dòng | |
| `WeekShopSpecial` | `week_shop_special.tsv` | 10 cột, 0 dòng | |
| `WinterShop` | `winter_shop.tsv` | 9 cột, 10 dòng | |
| `WuShenTanShop` | `war_god_altar_shop.tsv` | 10 cột, 14 dòng | |
| `XFTQ_Shop` | `xftq_shop.tsv` | 14 cột, 31 dòng | ? không rõ XFTQ |
| `XiaKeShop` | `knight_shop.tsv` | 10 cột, 52 dòng | |
| `XiGuaShop` | `watermelon_shop.tsv` | 16 cột, 75 dòng | |

### Chiến trường, giải đấu, phó bản đặc biệt (47 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `BianJingBiddingItem` | `bianjing_bidding_items.tsv` | 13 cột, 7 dòng | |
| `BianJingExchangeItem` | `bianjing_exchange_items.tsv` | 6 cột, 7 dòng | |
| `BianJingTokenAuction` | `bianjing_token_auctions.tsv` | 81 cột, 1 dòng | |
| `ChampionCupTeamInfo` | `champion_cup_teams.tsv` | 33 cột, 32 dòng | |
| `CJ_EquipInfo` | `cj_equipment.tsv` | 5 cột, 135 dòng | ? chế độ CJ có 22 cửa sổ CJ_* (ba lô, hấp hối, bảng hạ gục); nghĩa của CJ chưa chốt |
| `CJ_ItemInfo` | `cj_items.tsv` | 4 cột, 4 dòng | ? chế độ CJ |
| `CJ_SkillInfo` | `cj_skills.tsv` | 6 cột, 0 dòng | ? chế độ CJ |
| `CJI` | `cji.tsv` | 13 cột, 13 dòng | ? không rõ CJI |
| `CJS` | `cjs.tsv` | 10 cột, 9 dòng | ? không rõ CJS |
| `DiGong4SceneInfo` | `underground_palace4_scenes.tsv` | 8 cột, 72 dòng | |
| `DiGong4ServerInfo` | `underground_palace4_servers.tsv` | 4 cột, 38 dòng | |
| `fengmingBiddingItem` | `fengming_bidding_items.tsv` | 15 cột, 13 dòng | |
| `fengmingTokenAuction` | `fengming_token_auctions.tsv` | 115 cột, 74 dòng | |
| `FubenJiankong` | `instance_monitor.tsv` | 4 cột, 20 dòng | |
| `FYPVEAchInfo` | `fengyun_pve_achievements.tsv` | 7 cột, 15 dòng | ? FY suy là Phong Vân |
| `FYPVEItemInfo` | `fengyun_pve_items.tsv` | 6 cột, 37 dòng | ? như trên |
| `FYPVETalentInfo` | `fengyun_pve_talents.tsv` | 16 cột, 31 dòng | ? như trên |
| `gaoxiaobenrule` | `efficient_instance_rules.tsv` | 18 cột, 34 dòng | ? suy từ pinyin |
| `PVPCarSceneInfo` | `pvp_car_scenes.tsv` | 5 cột, 136 dòng | ? không rõ Car |
| `PVPCarServerInfo` | `pvp_car_servers.tsv` | 4 cột, 34 dòng | ? không rõ Car |
| `SecKillBase` | `sec_kill_base.tsv` | 35 cột, 9 dòng | ? SecKill suy là càn quét |
| `SecKillHuoDongBase` | `sec_kill_event_base.tsv` | 54 cột, 6 dòng | ? như trên |
| `T300Battlefield` | `t300_battlefields.tsv` | 12 cột, 28 dòng | ? T300 suy là chiến trường liên máy chủ |
| `T300JZWLZDAward` | `t300_jzwlzd_awards.tsv` | 30 cột, 8 dòng | ? không rõ JZWLZD |
| `T300JZWLZDSeasonInfo` | `t300_jzwlzd_seasons.tsv` | 3 cột, 7 dòng | ? không rõ JZWLZD |
| `T300Line` | `t300_lines.tsv` | 5 cột, 96 dòng | ? như trên |
| `T300SceneIDInfo` | `t300_scene_id.tsv` | 7 cột, 3441 dòng | ? như trên |
| `TeamBoardGoal` | `team_board_goals.tsv` | 2 cột, 33 dòng | |
| `TianJiChengSceneInfo` | `tianji_city_scenes.tsv` | 4 cột, 204 dòng | |
| `TianJiChengServerInfo` | `tianji_city_servers.tsv` | 4 cột, 34 dòng | |
| `TLCJPlayerExpLevel` | `tlcj_player_exp_levels.tsv` | 2 cột, 150 dòng | ? TLCJ suy là cùng chế độ CJ |
| `TPVEDefaultRestInfo` | `tpve_default_rest.tsv` | 4 cột, 34 dòng | ? không rõ TPVE |
| `WuShenTanSvr` | `war_god_altar_servers.tsv` | 1 cột, 1 dòng | |
| `XbwDuanweiTable_2018` | `xbw_rank_tier_2018.tsv` | 5 cột, 17 dòng | ? Xbw suy là giải đấu Thí Kiếm Thiên Hạ |
| `XbwHonourWall` | `xbw_honour_wall.tsv` | 9 cột, 271 dòng | ? như trên |
| `XBWJHSHonourWall` | `xbw_playoff_honour_wall.tsv` | 7 cột, 12 dòng | ? như trên |
| `XbwSceneInfo` | `xbw_scenes.tsv` | 6 cột, 240 dòng | ? như trên |
| `XbwServerInfo` | `xbw_servers.tsv` | 8 cột, 40 dòng | ? như trên |
| `XbwTimeTable_2018` | `xbw_timetable_2018.tsv` | 17 cột, 8 dòng | ? như trên |
| `XbwTimeTable_JiHouSai` | `xbw_playoff_timetable.tsv` | 21 cột, 11 dòng | ? như trên |
| `XiaKeFuBenInfo` | `knight_instances.tsv` | 23 cột, 6 dòng | |
| `ZdZdAutoPickType` | `auto_fight_auto_pick_types.tsv` | 4 cột, 32 dòng | |
| `ZdZdPotion` | `auto_fight_potions.tsv` | 5 cột, 29 dòng | |
| `ZdzdScene` | `auto_fight_scenes.tsv` | 4 cột, 137 dòng | |
| `ZdZdSkill` | `auto_fight_skills.tsv` | 10 cột, 113 dòng | |
| `ZYPVPSceneInfo` | `zypvp_scenes.tsv` | 6 cột, 228 dòng | ? không rõ ZY |
| `ZYPVPServerInfo` | `zypvp_servers.tsv` | 6 cột, 59 dòng | ? không rõ ZY |

### Hoạt động và sự kiện (39 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `2606SLevelInfo` | `s2606_levels.tsv` | 3 cột, 13 dòng | ? không rõ 2606S |
| `ActiveHaoLi` | `active_gifts.tsv` | 10 cột, 19 dòng | |
| `ActivePoint` | `active_points.tsv` | 3 cột, 20 dòng | |
| `ActivePointRatio` | `active_point_ratios.tsv` | 3 cột, 16 dòng | |
| `ActivityGift` | `activity_gifts.tsv` | 55 cột, 7 dòng | |
| `anniversary7hit` | `anniversary_7_hit.tsv` | 30 cột, 3 dòng | ? không rõ 7hit |
| `buffbuchang` | `buff_compensation.tsv` | 8 cột, 132 dòng | |
| `CaiDengMi` | `lantern_riddles.tsv` | 7 cột, 60 dòng | |
| `CampaignTableNew` | `campaign_new.tsv` | 44 cột, 502 dòng | |
| `DaysSign` | `days_sign.tsv` | 23 cột, 2 dòng | |
| `DLSH` | `dlsh.tsv` | 67 cột, 21 dòng | ? không rõ DLSH |
| `DuanWuBiddingBonus` | `dragon_boat_bidding_bonuses.tsv` | 6 cột, 8 dòng | |
| `DuanWuChouJiang` | `dragon_boat_lottery.tsv` | 7 cột, 34 dòng | |
| `gdxbchoujiang` | `gdxb_lottery.tsv` | 9 cột, 3 dòng | ? không rõ gdxb |
| `GouWuCheItem` | `shopping_cart_items.tsv` | 6 cột, 32 dòng | |
| `GQHYChouJiang` | `gqhy_lottery.tsv` | 9 cột, 91 dòng | ? không rõ GQHY |
| `HongBaoWeekInfo` | `red_envelope_week.tsv` | 18 cột, 1928 dòng | |
| `HuoyueDaibiClean` | `activeness_token_cleanup.tsv` | 2 cột, 82 dòng | |
| `JDGameQuestion` | `jd_game_questions.tsv` | 6 cột, 22 dòng | |
| `jianzhitianhuangitem` | `tianhuang_event_items.tsv` | 11 cột, 54 dòng | ? suy từ pinyin |
| `jierihuodong` | `festival_events.tsv` | 21 cột, 182 dòng | |
| `NewActivePoint` | `new_active_points.tsv` | 25 cột, 138 dòng | |
| `NewActivePointGuding` | `new_active_point_fixed.tsv` | 6 cột, 1 dòng | |
| `NewActivePointRatio` | `new_active_point_ratios.tsv` | 2 cột, 119 dòng | |
| `NewLongZhengShiZai` | `long_zheng_decade.tsv` | 12 cột, 31 dòng | ? suy từ pinyin |
| `NiudanDuihuan` | `gacha_exchange.tsv` | 10 cột, 25 dòng | |
| `NiudanReward` | `gacha_rewards.tsv` | 72 cột, 5 dòng | |
| `QingmingJackpot` | `qingming_jackpot.tsv` | 8 cột, 36 dòng | |
| `RefluencePrivilegeItemTable` | `refluence_privilege_items.tsv` | 5 cột, 9 dòng | |
| `RichmanChangeSuipianClient` | `monopoly_fragment_exchange.tsv` | 8 cột, 20 dòng | |
| `RichmanMap` | `monopoly_map.tsv` | 2 cột, 30 dòng | |
| `ShouKaiKaItemTable` | `first_open_card_items.tsv` | 25 cột, 3 dòng | |
| `SnowItem` | `snow_items.tsv` | 8 cột, 16 dòng | |
| `SpringFestivalBiddingBonus` | `spring_festival_bidding_bonuses.tsv` | 61 cột, 8 dòng | |
| `SVMakeUpTable` | `sv_make_up.tsv` | 10 cột, 36 dòng | ? không rõ SV |
| `ThanksJackpot` | `thanks_jackpot.tsv` | 8 cột, 36 dòng | |
| `XF_QuanMinBaXing` | `xf_all_eight_stars.tsv` | 8 cột, 70 dòng | ? không rõ XF |
| `ZhouNianChouJiang` | `anniversary_lottery.tsv` | 8 cột, 91 dòng | |
| `ZKInfo` | `zk.tsv` | 3 cột, 24 dòng | ? không rõ ZK |

### Cảnh, NPC, nhân vật (18 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `CharRace` | `character_races.tsv` | 10 cột, 8 dòng | |
| `CharTitleNew` | `character_title_new.tsv` | 53 cột, 1186 dòng | |
| `DynamicRegion` | `dynamic_regions.tsv` | 3 cột, 59 dòng | |
| `MonsterLimitedTable` | `monster_limited.tsv` | 3 cột, 1 dòng | |
| `MultiLine` | `multi_lines.tsv` | 11 cột, 22 dòng | |
| `MultiLineEx` | `multi_line_ex.tsv` | 3 cột, 2 dòng | |
| `NpcPosLimit` | `npc_positions_limit.tsv` | 39 cột, 26 dòng | |
| `NpcTalk` | `npc_talk.tsv` | 7 cột, 316 dòng | |
| `NPCVisible` | `npc_visible.tsv` | 6 cột, 38 dòng | |
| `Platform` | `platform.tsv` | 5 cột, 17 dòng | |
| `SceneAearDefine` | `scene_area_defs.tsv` | 6 cột, 149 dòng | |
| `SceneAreaTransfer` | `scene_area_transfer.tsv` | 10 cột, 525 dòng | |
| `SceneDefineEx` | `scene_definitions.tsv` | 25 cột, 680 dòng | |
| `SceneFacility` | `scene_facilities.tsv` | 34 cột, 44 dòng | |
| `ScenePosDefine` | `scene_positions.tsv` | 6 cột, 151 dòng | |
| `ScenePosDefineEx` | `scene_positions_extended.tsv` | 12 cột, 1957 dòng | |
| `Scripttalk` | `script_talk.tsv` | 7 cột, 1 dòng | |
| `ZiWeiNpc` | `ziwei_npc.tsv` | 6 cột, 3 dòng | |

### Chat, lọc chữ, xếp hạng (17 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `AnonymousCommonInfo` | `anonymous_common.tsv` | 17 cột, 9 dòng | |
| `ChatMood` | `chat_moods.tsv` | 14 cột, 402 dòng | |
| `ChatMood_Double` | `chat_mood_double.tsv` | 46 cột, 667 dòng | |
| `ChatSymbol` | `chat_symbols.tsv` | 16 cột, 130 dòng | |
| `FullCompareFilter` | `full_compare_filters.tsv` | 3 cột, 679 dòng | |
| `NormalRankingBase` | `normal_ranking_base.tsv` | 21 cột, 12 dòng | |
| `NormalRankReward` | `normal_rank_rewards.tsv` | 20 cột, 50 dòng | |
| `RankingList` | `ranking_list.tsv` | 312 cột, 44 dòng | |
| `RMBChatAction` | `rmb_chat_actions.tsv` | 8 cột, 28 dòng | |
| `RMBChatFace` | `rmb_chat_faces.tsv` | 6 cột, 34 dòng | |
| `SafeScore` | `safe_scores.tsv` | 11 cột, 1 dòng | |
| `SnsInfo` | `sns.tsv` | 6 cột, 75 dòng | |
| `SnsInfo_Boss` | `sns_boss.tsv` | 2 cột, 893 dòng | |
| `SnsInfo_Equip` | `sns_equipment.tsv` | 3 cột, 771 dòng | |
| `StrReplace` | `text_replacements.tsv` | 3 cột, 2265 dòng | |
| `StrTalkTemplateTable` | `talk_templates.tsv` | 5 cột, 196 dòng | |
| `TAnonymousInfo` | `t_anonymous.tsv` | 6 cột, 44 dòng | ? không rõ T |

### Loại máy chủ và đặc quyền (8 bảng)

| Tên gốc | Tên mới | Cỡ | Ghi chú |
|---|---|---|---|
| `KaJiSvr` | `level_cap_servers.tsv` | 13 cột, 546 dòng | |
| `Mergeserver` | `merge_servers.tsv` | 20 cột, 4 dòng | |
| `SCServerList` | `sc_server_list.tsv` | 2 cột, 17 dòng | ? không rõ SC |
| `ServerState` | `server_state.tsv` | 8 cột, 84 dòng | |
| `SpecialServerIDTable` | `special_server_id.tsv` | 2 cột, 8 dòng | |
| `TeSeServer` | `special_servers.tsv` | 40 cột, 604 dòng | |
| `VipFuncName` | `vip_functions_names.tsv` | 2 cột, 23 dòng | |
| `VipInfo` | `vip.tsv` | 63 cột, 10 dòng | |

### Bảng chỉ client dùng, server không nạp (109 bảng)

`AccountSafeRef`, `ActionExtInfo`, `ActionSetFile`, `AutoSearch`, `BeHit`, `BeiWangLu`,
`BieYeBuildingRes`, `BieYeFurnitureMood`, `BieYeItemRes`, `BuildingDefine`, `BuildingName`,
`CXGEnterTips`, `CharActionSet`, `CharEffect`, `CharHeadGeo`, `CharModelEx`, `CharTitleBoard`,
`CharacterFace`, `Character_3DHead`, `ChatHelp`, `ChongLouEffect`, `ChonglouDecor`, `CodeConvert`,
`CrashNoteKeyList`, `CreatureSound`, `CreatureSpeak`, `DarkImpackStr`, `EffectDefine`,
`EquipDetail`, `EquipMoodAction`, `ExcitPoint`, `ExteriorRideCamera`, `Exterior_TuJing`,
`FemaleFirstName`, `FemaleLastName`, `Fengyunlu`, `FengyunluText`, `GMVisible_Impact`,
`GMVisible_Skill`, `GSName`, `GSPic`, `GameCamera`, `GemEffect_Cloth`, `GradeFlash`,
`HuiguiActivity`, `IMDress`, `IMLevelTime`, `ImpactPreShow`, `InfantDoubleAction`, `InfantHairGeo`,
`InfantVisualPart`, `InterfaceEx`, `ItemLocatorAction`, `ItemOrnamentsVisual`, `ItemVisualChar`,
`ItemVisualChar_iv`, `ItemVisualLocator`, `ItemdescQX`, `LinkAction`, `MCDefaultRes`,
`MCResouceList`, `MaleFirstName`, `MaleLastName`, `MissionEffect`, `MissionRef`, `MissionTrack`,
`Model_Parameter`, `MonsterPaoPao`, `MonsterRef`, `MovieAttr`, `MsgBall`, `MsgBallType`,
`NameBoardEx`, `NameBoardExItem`, `NameBoardExVisual`, `Newserverhm`, `NotScalePetModel`,
`OtherRef`, `PetPaoPaoIndex`, `PetPaoPaoWord`, `PlayerQuicklyEnterHide`, `RankFlash`,
`RedPointTreeTable`, `ResOptStat`, `ResourceFilter`, `SoundInfo`, `SoundUI`, `SpecialDressEffect`,
`SpecialEquipVisiblRule`, `SpecialPriority`, `SpecialSceneCamera`, `SpecialSceneName`,
`StrDictionary`, `SuperWeapon9Res`, `SystemColour`, `TLCJSkillTips`, `TelCode`, `TitleFlash`,
`TransferColor`, `UICommandIndex`, `VipMotionBlend`, `WR_BossRef`, `WR_MainPage`,
`WeaponVisualLocator`, `WeblinkTable`, `WishString`, `XiuChangNotice`, `ZhenFaStr`,
`ZhenShouDanPreView`.

### Biến thể theo loại máy chủ (61 tệp)

| Hậu tố gốc | Khoá biến thể | Số tệp | Bảng gốc bị thay |
|---|---|---|---|
| `_KaJi_1`, `_KaJi`, `_kaji` | `level_cap` | 37 | `CampaignTable`, `CampaignTableNew`, `DLSH`, `DaHuaQiXi_Shop`, `DaysSign`, `Di4Shop`, `DiGong4ServerInfo`, `GQHYChouJiang`, `GuildBattleCDInfo`, `GuildShop`, `HuoYue_Shop`, `NationalShop`, `NewLongZhengShiZai`, `PVPCarServerInfo`, `QingmingJackpot`, `RichmanChangeSuipianClient`, `RichmanShop`, `SJFHShop`, `SafeScore`, `ShopTable`, `ShopVIP`, `SpringFestivalBiddingBonus`, `SummerZhanLingInfo`, `TPVEDefaultRestInfo`, `ThanksJackpot`, `TianJiChengServerInfo`, `TianJiChengShop`, `XbwServerInfo`, `XiGuaShop`, `XiaKeFuBenInfo`, `XiaKeShop`, `XinShouZhanLing_Award`, `XinShouZhanLing_Mission`, `ZYPVPServerInfo`, `ZhanLingInfo`, `ZhouNianChouJiang`, `jierihuodong` |
| `_OriginalJD_1` | `original_jd` | 1 | `Di4Shop` |
| `_QX` | `qx` | 12 | `DuanWeiHonourShop`, `DuanWeiYuanBaoShop`, `GQHYChouJiang`, `GuildShop`, `HLSCProgressItemInfo`, `HuiLiu2022Shop`, `JieBanShop`, `ShideShop`, `XinShouZhanLing_Award`, `XinShouZhanLing_Mission`, `ZhanLingInfo`, `jierihuodong` |
| `_ori`, `_Ori` | `original` | 3 | `DuanWuChouJiang`, `RichmanChangeSuipianClient`, `RichmanShop` |
| `_CT` | `ct` | 7 | `GQHYChouJiang`, `HLSCProgressItemInfo`, `HuiLiu2022Shop`, `JieBanShop`, `QingmingJackpot`, `XiGuaShop`, `ZhanLingInfo` |
| `_DZD` | `dzd` | 1 | `jierihuodong` |

Kiểm bằng máy: 574 bảng gốc mới, 61 biến thể và 83 bảng đã có ở
máy chủ 0859602 là 718 tệp `.txt`. Cộng bốn tệp không phải bảng
(`AIScript.dat`, `Script.dat`, `city0_LevelUp.lua`, `city0_Research.lua`) là đủ 722 tệp.
