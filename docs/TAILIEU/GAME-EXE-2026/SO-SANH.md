# So sánh Game.exe 2026 với client hiện tại — đã có, chưa có, sai

Sinh bằng `TOOLS/port/rea/compare_client.py` từ bản trích `TAILIEU/GAME-EXE-2026` và mã hiện tại; không sửa tay. Mỗi mục của bản gốc có một hàng trong các bảng ở `so-sanh/*.tsv` (đủ từng mục, kể cả nhỏ nhất); tệp này là bản đọc được của cùng dữ liệu.

## 0. Cách đọc và độ tin cậy

- **CÓ**: có bản đối ứng đã chạy. **MỘT PHẦN**: có nhưng thiếu phần của bản gốc. **CHƯA CÓ**: không thấy bản đối ứng. **KHÁC THIẾT KẾ**: dự án chủ ý làm cách khác. **KHÔNG ÁP DỤNG**: SDK bên thứ ba hay hạ tầng chỉ của bản gốc.
- Phép so là phép KHỚP BẰNG CHỨNG, không phải đọc từng hàm: tệp dữ liệu so theo tên tệp đủ đuôi trong công cụ xuất (`TOOLS/content`); lớp và tệp nguồn so bằng quy tắc thủ công, mỗi quy tắc có `probe` tự kiểm trong mã hiện tại (probe không thấy thì hạ về CHƯA CÓ); gói tin so theo bảng tương đương chức năng (client chưa mở socket nên không gói nào có handler); Lua so theo tên hàm script và địa chỉ cài đặt. Nhóm của gói tin suy từ TỪ KHOÁ trong tên, không phải từ nội dung.
- 57 200 hàm và 56 190 chuỗi không so từng cái: chúng được phủ gián tiếp qua lớp, tệp nguồn, gói tin, tệp dữ liệu và Lua ở trên. Muốn so một hàm cụ thể thì tra `decompile.zip` rồi đọc mã.
- `Game.exe` đã trích là tệp của dự án Ghidra TLBB (cùng SHA-256), nhưng mã và tài liệu của dự án trích địa chỉ của ít nhất hai bản dựng (mục 4.2): đừng dùng địa chỉ trong mã/tài liệu của dự án để tra thẳng vào bản trích.

## 1. Tổng hợp số

| Nhóm | Tổng | CÓ | MỘT PHẦN | KHÁC THIẾT KẾ | KHÔNG ÁP DỤNG | CHƯA CÓ | Tệp chi tiết |
|---|---|---|---|---|---|---|---|
| Tệp dữ liệu client đọc | 692 | 39 | 0 | 0 | 61 (mẫu định dạng) | 592 | `bang-du-lieu.tsv` |
| Gói tin `Packets::*` | 1367 | 0 | 20 | 0 | 0 | 1347 | `goi-tin.tsv` |
| Lớp RTTI (không phải gói tin) | 507 | 10 | 50 | 73 | 62 | 312 | `lop.tsv` |
| Tệp nguồn gốc (suy từ assert) | 261 | 16 | 33 | 4 | 1 | 207 | `tep-nguon.tsv` |
| Hàm script Lua | 6055 | ĐÃ PORT 8 | CÓ TÊN (MÃ) 24 + CHÚ THÍCH 83 | | CHỈ TRỌNG TÀI 27 | 5913 | `lua-api.tsv`, `lua-bang.tsv` |
| Import (DLL) | 835 | 231 | 37 | 273 | 292 | 2 | `import-dll.tsv` |
| Tài nguyên PE (nhóm) | 31 | 22 | 3 | 0 | 0 | 6 | `tai-nguyen-pe.tsv` |

Sai/lệch: 183 trên 458 địa chỉ Game.exe trích dẫn trong mã và tài liệu của dự án không khớp bản trích (`dia-chi-trich-dan.tsv`); 709 chỗ mã tự ghi "Khác gốc:" (`lech-da-ghi.tsv`); 53 mục còn mở trong `docs/NGHI-NGO.md` (`nghi-ngo-mo.tsv`); gói đăng nhập: 19/19 khớp dump tự động (`kiem-goi-dang-nhap.tsv`).

## 2. Đã có

### 2.1 Lớp của bản gốc có bản đối ứng

**CÓ** (10 lớp):

- `CActionItem_LifeAbility`, `CActionItem_Skill`, `CActionItem_XinFa`, `CActionItem_ZhenFaSkill` — book/skill/actions (ActionKind: skill, life, xinfa, formation)
- `CObject_Effect`, `CObject_Static` — place/scene (vật thể tĩnh) và place/fx (hiệu ứng)
- `MAP_POS_DEFINE`, `TD_MAP_POS_DEFINE` — bảng ScenePosDefineEx / SceneDefineEx đã xuất và đọc (app/client/map, ui/panel/scene_table)
- `CActionSetMgr` — bảng ActionSet đã xuất (skill_actions.tsv, anim_sets.tsv) và figure/look
- `CCursorMng` — app/client/viewer/cursors + figure/control/cursor_rules (22 con trỏ đọc từ Game.exe)

**MỘT PHẦN** (50 lớp):

- `CDataPool`, `CUIDataPool`, `MsgBall`, `MsgBallImp`, `MsgBallImp4`, `MsgBallImp5`, `MsgBallImp6`, `MsgBallImpGuild`, `MsgBallImpPlayer`, `MsgBallImpSpecial`, `MsgBallImpSystem` — ui/panel dùng dữ liệu cục bộ; chưa có DataPool chung và bóng tin nhắn
- `CGamePro_Break`, `CGamePro_Camera`, `CGamePro_ChangeScene`, `CGamePro_CharCreate`, `CGamePro_CharSel`, `CGamePro_Enter`, `CGamePro_Login`, `CGamePro_Main` — thủ tục Login/CharSel/CharCreate có ở face/ui/panel; thủ tục Main chỉ là màn chơi không máy chủ
- `CAI_Base`, `CAI_MySelf`, `CCharacterData`, `CDetailAttrib_Base`, `CDetailAttrib_Player`, `SDATA_RELATION_MEMBER`, `SDATA_TRUST_FRIEND` — figure/hero (số liệu nhân vật) và book/skill; chưa có AI, chưa có DetailAttrib từ máy chủ
- `CPath`, `CScene`, `CWorldManager`, `CZone` — place/scene, app/client/world, shared/nav (.path)
- `CDataBase`, `CDataBaseSystem`, `DBC::DBCFile` — shared/table + TOOLS/content/dbc.py; nạp 46 bảng đã xuất, không nạp 598 bảng của bản gốc
- `CNewSoundSystemFMod`, `CSoundBufferFMod`, `CSoundSourceFMod` — engine/audio (miniaudio, nhạc nền theo cảnh); chưa có tiếng hiệu ứng
- `CObject_Character`, `CObject_Dynamic`, `CObject_PlayerMySelf` — app/client/display/player + figure/avatar (xương, dáng đi, đòn đánh, vũ khí); không có logic do máy chủ điều khiển
- `CActionItem`, `CActionSystem` — book/skill/actions (chỉ 5 loại action của sách võ công)
- `CFakeObjSystem`, `CFakeObjSystemEx` — app/client/display/role_stage + role_preview (người mẫu xem trước trên màn tạo nhân vật)
- `CObject_Building`, `CObject_Building2` — vật thể công trình ở place/scene + shared/collision (.WCollision, nâng chân)
- `CObject_Map`, `CObject_Phy` — vị trí/va chạm rải ở figure/control/ground + shared/collision; không có lớp nền chung
- `CTimerManager`, `TimelineLink` — engine/core đồng hồ và FixedStep
- `CInputSystem` — figure/control + app/client/viewer/sdl_input (chuột, phím, cảm ứng, cần gạt)

**KHÁC THIẾT KẾ** (73 lớp; dự án chủ ý làm khác):

- 42 lớp — lớp bọc API Lua của một tính năng; dự án không chạy Lua ở client mà dịch script sang C++ (ui/panel, có số vàng từ trọng tài): `SCRIPT_SANDBOX::AttrCompare`, `SCRIPT_SANDBOX::BWDH`, `SCRIPT_SANDBOX::BWDH2018`, `SCRIPT_SANDBOX::BattleAssistInterface`, `SCRIPT_SANDBOX::BudgetPlanGem`, `SCRIPT_SANDBOX::CachedCharacter`, `SCRIPT_SANDBOX::Character`, `SCRIPT_SANDBOX::CityBase`, `SCRIPT_SANDBOX::CityLoopMission`, `SCRIPT_SANDBOX::CityManage`, `SCRIPT_SANDBOX::CityResearch`, `SCRIPT_SANDBOX::CityResearchElement` và 30 lớp khác
- 8 lớp — shared/link và protocol của dự án: `GameLink`, `GameLinkClient`, `GameLinkServer`, `JsonProtocol::CProtocolDataBase`, `JsonProtocol::DLCClientExtData`, `JsonProtocol::EnterScenePlayerOption`, `JsonProtocol::ReportDataVersion1`, `JsonProtocol::ServerConnectInfo`
- 6 lớp — engine/net (socket TCP không chặn, PollSet) và shared/link; client chưa gọi: `CNetManager`, `MyThread`, `NetThread`, `Socket`, `SocketInputStream`, `SocketOutputStream`
- 5 lớp — engine/io, engine/fs; cấu hình bằng TOML/CLI: `IODataStream`, `IniFile`, `InputStream`, `MsgIODataStream`, `OutputStream`
- 3 lớp — ui/panel gọi trực tiếp; không có bus sự kiện PushEvent (docs ghi SU-KIEN-GAME.tsv): `CEventSystem`, `CGameInterface`, `CUICommandSystem`
- 3 lớp — shared/secure dùng libsodium (bắt tay, bản ghi mã hoá): `CMD5`, `CryptBox`, `CryptionBox::CryptBox`
- 3 lớp — shared/protocol (khung, kênh, danh mục tin sinh từ bảng): `Packet`, `PacketFactory`, `PacketFactoryManager`
- 2 lớp — môi trường Lua; client dự án không nhúng Lua: `CScriptEnvironment`, `CScriptSystem`
- 1 lớp — nút trợ giúp mở trang web (kOpenWeb): `CHelperSystem`

### 2.2 Tệp nguồn gốc có bản đối ứng

**CÓ** (16 tệp):

- `Action\GMActionSystem_LifeAbility.cpp` (1 hàm) — book/skill/actions
- `Action\GMActionSystem_Skill.cpp` (1 hàm) — book/skill/actions
- `Action\GMActionSystem_XinFa.cpp` (1 hàm) — book/skill/actions
- `Action\GMActionSystem_ZhenFaSkill.cpp` (2 hàm) — book/skill/actions
- `Cursor\CursorMng.cpp` (1 hàm) — app/client/viewer/cursors + figure/control/cursor_rules
- `DataPool\GMDP_Struct_Quest.cpp` (5 hàm) — book/quest (log, outline, track)
- `DataPool\GMDP_Struct_Skill.cpp` (4 hàm) — book/skill (sách võ công)
- `Interface\GMGameinterface_Script_GameProduceLogin.cpp` (6 hàm) — ui/panel login_flow, logon, select_server, select_role, create_role
- `Procedure\CharacterFaceMng.cpp` (1 hàm) — figure/look (mặt, tóc)
- `Procedure\FaceModelMng.cpp` (1 hàm) — figure/look (mặt, tóc)
- `Procedure\GamePro_Camera.cpp` (1 hàm) — figure/control camera (port mã máy)
- `Procedure\GamePro_CharCreate.cpp` (2 hàm) — ui/panel login/chọn nhân vật/tạo nhân vật (không máy chủ)
- `Procedure\GamePro_CharSel.cpp` (8 hàm) — ui/panel login/chọn nhân vật/tạo nhân vật (không máy chủ)
- `Procedure\GamePro_Login.cpp` (1 hàm) — ui/panel login/chọn nhân vật/tạo nhân vật (không máy chủ)
- `Procedure\HairModelMng.cpp` (1 hàm) — figure/look (mặt, tóc)
- `World\Path.cpp` (2 hàm) — shared/nav (.path, tìm đường)

**MỘT PHẦN** (33 tệp):

- `Action\GMActionSystem.cpp` (45 hàm) — book/skill/actions (5 loại action)
- `Action\GMActionSystem_PetSkill.cpp` (1 hàm) — bốn action thú cưng cố định (PetAction)
- `DataPool\DetailAttrib_Player.cpp` (5 hàm) — figure/hero (số liệu nhân vật mẫu newcomer()) và dữ liệu cục bộ của ui/panel; chưa có DataPool đầy đủ
- `DataPool\GMDP_CharacterData.cpp` (795 hàm) — figure/hero (số liệu nhân vật mẫu newcomer()) và dữ liệu cục bộ của ui/panel; chưa có DataPool đầy đủ
- `DataPool\GMDataPool.cpp` (227 hàm) — figure/hero (số liệu nhân vật mẫu newcomer()) và dữ liệu cục bộ của ui/panel; chưa có DataPool đầy đủ
- `DataPool\GMUIDataPool.cpp` (5 hàm) — figure/hero (số liệu nhân vật mẫu newcomer()) và dữ liệu cục bộ của ui/panel; chưa có DataPool đầy đủ
- `Dbc\GMDataBase.cpp` (2 hàm) — shared/table + TOOLS/content/dbc.py; đọc 46 trên 598 bảng
- `FakeObject\GMFakeObjSystem.cpp` (1 hàm) — role_stage/role_preview
- `Input\GMInputSystem_AcceFunc.cpp` (1 hàm) — figure/control/player_input (phím)
- `Interface\GMGameInterface.cpp` (5 hàm) — ui/panel + face/gui
- `Interface\GMGameInterface_Script.cpp` (167 hàm) — ui/panel + face/gui
- `Interface\GMGameInterface_Script_Character.cpp` (17 hàm) — ui/panel + face/gui
- `Interface\GMGameInterface_Script_DataPool.cpp` (258 hàm) — ui/panel + face/gui
- `Interface\GMGameInterface_Script_LifeAbility.cpp` (41 hàm) — book/skill (sách võ công, kỹ năng sống)
- `Interface\GMGameInterface_Script_Martial.cpp` (12 hàm) — book/skill (sách võ công, kỹ năng sống)
- `Interface\GMGameInterface_Script_Package.cpp` (43 hàm) — ui/panel/packet.cpp (khung hành trang, mọi ô trống)
- `Interface\GMGameInterface_Script_PlayerMySelf.cpp` (48 hàm) — ui/panel đọc hero::Hero (khung nhân vật, bảng nhân vật)
- `Interface\GMInterface_Script_SystemSetup.cpp` (2 hàm) — ui/panel/system_info (các trang cài đặt là khung)
- `Interface\NGInterface.cpp` (2 hàm) — ui/panel + face/gui
- `Item\GMItem_Equip.cpp` (52 hàm) — figure/look/weapon (vũ khí 7 khe, đá quý, hiệu ứng đồ); không có hệ vật phẩm
- `Item\GMItem_Gem.cpp` (3 hàm) — figure/look/weapon (vũ khí 7 khe, đá quý, hiệu ứng đồ); không có hệ vật phẩm
- `Object\Character\Ai\GMAI_MySelf.cpp` (4 hàm) — đi bằng nhấp chuột + tìm đường (figure/control, shared/nav)
- `Object\Character\Obj_Character.cpp` (30 hàm) — figure/avatar + app/client/display/player
- `Object\Character\Obj_Character_Logic.cpp` (29 hàm) — figure/avatar + app/client/display/player
- `Object\Character\Obj_PlayerMySelf.cpp` (13 hàm) — figure/avatar + app/client/display/player
- `Object\Obj_Building.cpp` (11 hàm) — vật thể công trình + va chạm .WCollision
- `Procedure\GamePro_Main.cpp` (4 hàm) — app/client (boot, màn chơi không máy chủ)
- `Procedure\GameProcedure.cpp` (3 hàm) — app/client (boot, màn chơi không máy chủ)
- `Sound\GMNewSoundSystem.cpp` (3 hàm) — engine/audio miniaudio, nhạc nền theo cảnh
- `TDFunction.cpp` (2 hàm) — engine/core
- `Timer.cpp` (2 hàm) — engine/core
- `World\Scene.cpp` (6 hàm) — place/scene + app/client/world
- `World\WorldManager.cpp` (18 hàm) — place/scene + app/client/world

**KHÁC THIẾT KẾ** (4 tệp):

- `Helper\GMHelperSystem.cpp` (1 hàm) — nút trợ giúp mở trang web
- `Script\GMScriptSystm.cpp` (2 hàm) — không nhúng Lua; script dịch sang C++ + trọng tài
- `Variable\GMVariable.cpp` (1 hàm) — app/client/options (cờ dòng lệnh) thay cho hệ biến
- `helper\..\Interface\GMinterface_Lua.h` (1 hàm) — nút trợ giúp mở trang web

**KHÔNG ÁP DỤNG** (1 tệp):

- `interface\GMInterface_Lua.h` (2 hàm) — khai báo Lua; client dự án không nhúng Lua

### 2.3 Tệp dữ liệu (bảng, cảnh...) đã được công cụ xuất hoặc gom

39 mục (34 tên khác nhau; một số tên xuất hiện ở hai địa chỉ trong Game.exe): `Ability.txt`, `ActionSet.txt`, `ActionSetKV.txt`, `ActionSetLine.txt`, `CampaignItem.txt`, `CharFaceGeo.txt`, `CharHairGeo.txt`, `CharModelEx.txt`, `CharRace.txt`, `CharacterFace.txt`, `Character_3DHead.txt`, `CommonItem.txt`, `EquipBase.txt`, `GemInfo.txt`, `InterfaceEx.txt`, `ItemVisualChar.txt`, `ItemVisualLocator.txt`, `MissionKind.txt`, `MissionOutline.txt`, `NewRoleEquipSet.txt`, `PlayerExpLevel.txt`, `SceneDefineEx.txt`, `SkillData_V1.txt`, `SkillTemplate_V1.txt`, `SoundInfo.txt`, `StrDictionary.txt`, `XinFaStudySpend_V1.txt`, `XinFa_V1.txt`, `ZhenFaStr.txt`, `congren.Scene`, `congrensg.Scene`, `congrentx.Scene`, `erengu_DL.Scene`, `tl3chuangjian.Scene`

### 2.4 Gói tin có tương đương chức năng (client chưa nối, máy chủ có; định dạng dự án khác bản gốc)

- `CGEnterScene` (opcode 17) — EnterGame (server có, client chưa nối; định dạng dự án khác)
- `LCRetCharLogin` (opcode 38) — SessionStart/SceneEnter (server có, client chưa nối; định dạng dự án khác)
- `LCRetLogin` (opcode 223) — Ticket/Reject (server có, client chưa nối; định dạng dự án khác)
- `CLAskDeleteChar` (opcode 240) — DeleteCharacter (server có, client chưa nối; định dạng dự án khác)
- `CLAskLogin` (opcode 299) — SignIn (server có, client chưa nối; định dạng dự án khác)
- `LCRetCharList` (opcode 319) — CharacterList (server có, client chưa nối; định dạng dự án khác)
- `GCEnterScene` (opcode 380) — SceneEnter (server có, client chưa nối; định dạng dự án khác)
- `CLAskCharLogin` (opcode 426) — EnterGame (server có, client chưa nối; định dạng dự án khác)
- `CGConnect` (opcode 456) — Hello+Login/Resume (server có, client chưa nối; định dạng dự án khác)
- `CLAskCreateChar` (opcode 522) — CreateCharacter (server có, client chưa nối; định dạng dự án khác)
- `GCCharBaseAttrib` (opcode 587) — EntityVitals (một phần) (server có, client chưa nối; định dạng dự án khác)
- `CLAskCharList` (opcode 711) — Login/EnterGame (danh sách nhân vật) (server có, client chưa nối; định dạng dự án khác)
- `GCConnect` (opcode 796) — Welcome/SessionStart (server có, client chưa nối; định dạng dự án khác)
- `CGHeartBeat` (opcode 896) — Ping/Pong (server có, client chưa nối; định dạng dự án khác)
- `GCNewPlayer_Move` (opcode 1275) — Position/EntityPos (server có, client chưa nối; định dạng dự án khác)
- `GCNewPlayer` (opcode 2203) — EntityAppear (server có, client chưa nối; định dạng dự án khác)
- `CGCharMove` (opcode 2345) — Move (server có, client chưa nối; định dạng dự án khác)
- `GCCharMove` (opcode 2742) — Position/EntityPos (server có, client chưa nối; định dạng dự án khác)
- `GCDelObject` (opcode 2792) — EntityDisappear (server có, client chưa nối; định dạng dự án khác)
- `GCHeartBeat` (opcode 2822) — Ping/Pong (server có, client chưa nối; định dạng dự án khác)

### 2.5 Hàm script Lua đã có dấu vết trong client

**ĐÃ PORT** (8): `(globals).IsJYJYSecond`, `(globals).IsLMSJSecond`, `(globals).IsWJQFSecond`, `GameProduceLogin.GetFaceName`, `GameProduceLogin.LoadLaunch`, `GameProduceLogin.SelectLoginServer`, `GameProduceLogin.SetLoginServerKeyword`, `PetTable.Other_GetAttackFire`

**CÓ TÊN (MÃ)** (24): `(globals).CloseWindow`, `(globals).OpenTodayCampaignList`, `(globals).OpenWindow`, `(globals).PushDebugMessage`, `(globals).PushEvent`, `GameProduceLogin.ChangeNewRoleEquipSet`, `GameProduceLogin.ChangeToSelectRoleDlgFromCreateRole`, `GameProduceLogin.CreateRole`, `GameProduceLogin.GameLoginShowSystemInfo`, `GameProduceLogin.ModelRotBegin`, `GameProduceLogin.ModelRotEnd`, `GameProduceLogin.ModelZoom`, `GameProduceLogin.SetFaceId`, `GameProduceLogin.SetFaceModelId`, `GameProduceLogin.SetHairModelId`, `GameProduceLogin.ShowModel`, `Helper.GotoHelper`, `MissionReply.DoAction`, `PetTable.Feed`, `SystemSetup.Display`, `SystemSetup.GameSetup`, `SystemSetup.Sound`, `SystemSetup.SoundSetup`, `SystemSetup.ViewSetup`

**CHÚ THÍCH** (83): `(globals).AutoRunToTarget`, `(globals).CollectMissionOutline`, `(globals).EnumAction`, `(globals).GetActionNum`, `(globals).GetMissionOutlineInfo`, `(globals).GetMissionOutlineNum`, `(globals).GetUplevelXinfaSpendExp`, `(globals).GetUplevelXinfaSpendMoney`, `(globals).GetWeblink`, `(globals).Lua_GetMyMaxLevelLimit`, `(globals).LuaFindRoleByAcc`, `(globals).OpenFreshManGuideNew`, `(globals).PrepearExchange`, `(globals).QuitApplication`, `(globals).ResetCamera`, `(globals).ReturnServerLogin`, `(globals).ScriptGlobal_Format`, `(globals).SetSoftKeyAim`, `(globals).SetTimer`, `(globals).ToggleLargeMap`, `(globals).ToggleSceneMap`, `(globals).ToggleWindow`, `ActionButtonMetaTable.GetDefineID`, `ActionButtonMetaTable.GetEquipDur`, `ActionButtonMetaTable.GetID`, `ActionButtonMetaTable.GetOwnerXinfa`, `ActionButtonMetaTable.IsLevelEnoughEquip`, `ActionButtonMetaTable.Lua_GetEquipZhiZunType`, `ActionSystem.GetDefineID`, `BattleAssist.Stop`, `CharacterMetaTable.AdjustHeadCamera`, `CharacterMetaTable.GetData`, `ClientMovieTable.Play`, `ClientMovieTable.Stop`, `CommisionShop.EnumAction`, `DataPoolMetaTable.GetBaseBag_Num`, `DataPoolMetaTable.GetBaseBag_RealMaxNum`, `DataPoolMetaTable.GetMissionInfo_Kind`, `DataPoolMetaTable.IsTrackFuncShow`, `DataPoolMetaTable.Lua_CheckOpenTalent`, `DataPoolMetaTable.Lua_IsMissionHaveDone`, `DataPoolMetaTable.OpenFriendList`, `DataPoolMetaTable.SetTrackFuncShow`, `GameProduceLogin.CheckAccount`, `GameProduceLogin.ExitToSelectServer`, `GameProduceLogin.GetAreaLoginServerCount`, `GameProduceLogin.GetAreaLoginServerInfo`, `GameProduceLogin.GetEquipSetCount`, `GameProduceLogin.GetEquipSetName`, `GameProduceLogin.GetFaceModelCount`, `GameProduceLogin.GetFaceModelInfo`, `GameProduceLogin.GetFaceModelName`, `GameProduceLogin.GetHairModelCount`, `GameProduceLogin.GetHairModelName`, `GameProduceLogin.GetIsForbidName`, `GameProduceLogin.GetManFaceCountForCreate`, `GameProduceLogin.GetServerAreaCount`, `GameProduceLogin.GetServerAreaDis`, `GameProduceLogin.GetServerAreaName`, `GameProduceLogin.GetServerAreaRecommendLevel`, `GameProduceLogin.GetWomanFaceCountForCreate`, `GameProduceLogin.IsWeGameClient`, `GameProduceLogin.OpenURL`, `GameProduceLogin.StartAccountReg`, `GuildLeagueTable.GetID`, `GuildLeagueTable.Quit`, `LifeAbilityTable.GetLifeAbility_LimitExp`, `LifeAbilityTable.GetLifeAbility_Number`, `PetTable.GetData`, `PetTable.GetID`, `PetTable.GetPetFightAction`, `PlayerMySelfMetaTable.GetAbilityInfo`, `PlayerMySelfMetaTable.GetData`, `PlayerMySelfMetaTable.GetSkillInfo`, `PlayerMySelfMetaTable.GetStrZhenfaSkill`, `PlayerMySelfMetaTable.GetXinfaInfo`, `PlayerMySelfMetaTable.IsCanLevelup`, `PlayerMySelfMetaTable.UseSkill`, `PlayerPackage.Lock`, `SystemSetup.IsClassic`, `TargetPetTable.GetID`, `TLCJ.GetData`, `TLCJ.IsInTLCJScene`

**CHỈ TRỌNG TÀI** (27): `(globals).CloseFreshManGuide`, `(globals).GetFreshManGuideOwner`, `(globals).GetLastSkill_UI`, `(globals).GetXinfaLevel`, `(globals).OpenCommonSkillPage`, `(globals).OpenLifePage`, `(globals).OpenSkillBook`, `(globals).OpenZhenfaFream`, `(globals).ToggleTalentPage`, `ActionButtonMetaTable.GetName`, `BattleAssist.Farm_GetLimitLevel`, `CharacterMetaTable.GetName`, `DataPoolMetaTable.GetPlayerMission_Description`, `DataPoolMetaTable.GetPlayerMission_InUse`, `DataPoolMetaTable.GetPlayerMission_Kind`, `DataPoolMetaTable.GetPlayerMissionTrackType`, `DataPoolMetaTable.Lua_IsNewServerPlayerByZWID`, `DataPoolMetaTable.Lua_SetLastSkill_UI`, `GameProduceLogin.GetSelectLoginServerZWID`, `GuildLeagueTable.GetName`, `PetTable.GetName`, `PetTable.GetPetPossessionAction`, `PetTable.GetPetRelaxAction`, `PetTable.GetPetRestoreAction`, `PlayerMySelfMetaTable.GetDefineHumanMaxLevel`, `PlayerMySelfMetaTable.GetName`, `TargetPetTable.GetName`

`ĐÃ PORT` là bằng chứng mạnh nhất (địa chỉ cài đặt của hàm có trong mã/chú thích của client); `CÓ TÊN (MÃ)` có thể trùng tên ngẫu nhiên (tên chung như `GetLevel`); `CHÚ THÍCH` chỉ mới nhắc; `CHỈ TRỌNG TÀI` chỉ có ở giả lập `TOOLS/port/oracle/*.lua`, không phải mã client.

### 2.6 Import (DLL) đã có thay thế

- `MSVCR110.DLL` (162 import: KHÔNG ÁP DỤNG 162) — CRT MSVC 2012 của bản gốc; dự án dựng với CRT hiện đại
- `KERNEL32.DLL` (138 import: CÓ 138) — engine/core, engine/fs, engine/jobs, engine/window (gọi Win32 trực tiếp hoặc qua SDL3)
- `TENGINE.DLL` (122 import: KHÁC THIẾT KẾ 122) — engine nội bộ của TLBB (122 import, 115 ký hiệu khác nhau) không còn trên đĩa; dự án tự viết engine/ (gpu, render, scene) và port logic từ TLBB Dev
- `MSVCP110.DLL` (84 import: KHÔNG ÁP DỤNG 84) — STL MSVC 2012
- `USER32.DLL` (82 import: CÓ 82) — engine/window (SDL3 + Win32)
- `LUAPLUS.DLL` (80 import: KHÁC THIẾT KẾ 80) — Lua của bản gốc; client dự án không nhúng Lua
- `WS2_32.DLL` (35 import: MỘT PHẦN 35) — engine/net có socket TCP; client chưa gọi
- `ADVAPI32.DLL` (30 import: KHÔNG ÁP DỤNG 12, KHÁC THIẾT KẾ 18) — registry; dự án không dùng registry (cấu hình là TOML/CLI)
- `FMOD64.DLL` (24 import: KHÁC THIẾT KẾ 24) — FMOD; dự án dùng miniaudio và định dạng .tla
- `CRYPT32.DLL` (18 import: KHÁC THIẾT KẾ 18) — chứng chỉ/mã hoá Windows; dự án dùng libsodium
- `WLDAP32.DLL` (18 import: KHÔNG ÁP DỤNG 18) — LDAP, kéo theo bởi WinINet/Crypt32 của bản gốc
- `SHLWAPI.DLL` (8 import: CÓ 8) — xử lý đường dẫn: std::filesystem
- `WININET.DLL` (8 import: KHÁC THIẾT KẾ 8) — HTTP của bản gốc; các nút web mở trang 'Coming soon' ngoài trình duyệt
- `OLE32.DLL` (7 import: KHÔNG ÁP DỤNG 7) — COM
- `OLEAUT32.DLL` (6 import: KHÔNG ÁP DỤNG 6) — COM
- `WINMM.DLL` (3 import: CÓ 3) — engine/core thời gian
- `VERSION.DLL` (3 import: KHÔNG ÁP DỤNG 3) — đọc phiên bản tệp
- `IPHLPAPI.DLL` (2 import: CHƯA CÓ 2) — lấy địa chỉ mạng/MAC (định danh máy)
- `SHELL32.DLL` (2 import: MỘT PHẦN 2) — mở trang web/tệp ngoài; nút web của dự án mở trang 'Coming soon' (kOpenWeb)
- `IMM32.DLL` (2 import: KHÁC THIẾT KẾ 2) — IME: SDL3 text input + bàn phím ảo của dự án
- `BCRYPT.DLL` (1 import: KHÁC THIẾT KẾ 1) — số ngẫu nhiên mật mã; dự án dùng libsodium randombytes

### 2.6b Tài nguyên PE

- RT_GROUP_CURSOR id 129 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 130 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 135 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 136 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 137 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 138 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 139 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 140 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 141 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 145 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 147 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 149 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 150 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 151 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 153 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 154 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 155 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 158 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 159 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 160 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 161 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_CURSOR id 162 (20 byte) — CÓ: export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)
- RT_GROUP_ICON id 107 (90 byte) — MỘT PHẦN: src/client/app/client/app.rc khai 2 icon (client, thanh tiêu đề); chưa so ảnh với hai nhóm icon của bản gốc
- RT_GROUP_ICON id 108 (90 byte) — MỘT PHẦN: src/client/app/client/app.rc khai 2 icon (client, thanh tiêu đề); chưa so ảnh với hai nhóm icon của bản gốc
- RT_MANIFEST id 1 (381 byte) — MỘT PHẦN: có manifest (src/client/pack/seal/package.hpp)

### 2.7 Dự án có mà bản gốc không có

- Bốn backend đồ hoạ (Vulkan, D3D12, D3D11, OpenGL/GLES) và lớp `gpu`; bản gốc chỉ có Direct3D 9 trong Render.dll
- Chạy trên Android arm64 (vỏ `android/`) và iOS arm64 (vỏ `apple/`); bản gốc chỉ Windows
- Âm thanh miniaudio + định dạng .tla và Opus; bản gốc dùng FMOD
- Bắt tay và bản ghi mã hoá bằng libsodium (`shared/secure`); bản gốc dùng MD5 + khoá tĩnh
- Giao thức tự thiết kế, có phiên bản và danh mục sinh từ bảng (`shared/protocol`); bản gốc 1 367 gói viết tay
- Bảy exe máy chủ dưới trình giám sát, cấu hình TOML, PostgreSQL (`src/server`); bản gốc không có phía máy chủ trong Game.exe
- Bản địa hoá dựng cùng client (zh/vi/en) từ `assets/i18n`; bản gốc chỉ tiếng Trung
- Bảng đo nhịp khung `ui/pace` luôn hiện ở màn chơi; bản gốc không có
- Cần gạt và cử chỉ chạm cho điện thoại (`figure/control`); bản gốc chỉ chuột và phím
- Bố cục layout điện thoại `Interface/phone/` và texture ASTC/ETC2
- Công cụ chụp ảnh khung (`--shot`) và công cụ thử `--weapon`, `--skill`, `--gem`, `--auto-strike`
- Trọng tài Lua (`lua_oracle.py`) sinh số vàng từ script gốc chạy trên LuaPlus.dll của bản gốc
- Chuỗi công cụ phân tích Game.exe (REA/Ghidra) và bản trích đầy đủ trong TAILIEU/GAME-EXE-2026

## 3. Chưa có

### 3.1 Gói tin chưa có (1347)

Client chưa mở socket nào, nên mọi gói đều chưa có handler. Danh sách theo nhóm (nhóm suy từ từ khoá trong tên; mỗi gói có opcode, kích thước, trường trong `goi-tin.tsv` và `packets.tsv`):

- **hoạt động/tính năng riêng (không suy được nhóm từ tên)** (381): `CG2023ActivationCDK`, `CGAPPFastCheck`, `CGActiveMonster`, `CGAntagonistReq`, `CGAppWareCheck`, `CGApplyPrivateInfo`, `CGApproveAscendingCode`, `CGAskCheckSOSecond`, `CGAskCheckSafeCode`, `CGAskDaFuWengData`, `CGAskDarkAdjust`, `CGAskDetailXinbiwu_2018`, `CGAskDunJiaShuData`, `CGAskExteriorYiRongGe`, `CGAskFHSXData`, `CGAskForbidIt`, `CGAskGQHYChouJiang`, `CGAskGuiShiBaseData`, `CGAskJoinMenpai`, `CGAskJuqingPoint`, `CGAskMenPaiDiYi`, `CGAskMibaoStatus`, `CGAskOtherSceneMazei`, `CGAskPrivateInfo`, `CGAskPrize`, `CGAskQuit`, `CGAskSBGHumanInfo`, `CGAskSMSCode`, `CGAskSafeCodeInfo`, `CGAskScore`, `CGAskSecKillData`, `CGAskSecKillNum`, `CGAskSetActivePoint`, `CGAskStandData`, `CGAskTujianInfo`, `CGAskWeekcardInfo`, `CGAskZNQfudai`, `CGBBSApply`, `CGBBSSychMessages`, `CGBJJJHZhenJiu`, `CGBugFeedBack`, `CGByname`, `CGCGWPacket`, `CGCTUGabrielCmdRet`, `CGChangePkModeReq`, `CGChangyigeCheck`, `CGCharIdle`, `CGCharSit`, `CGCheckWinActive`, `CGChongLouEffect`, `CGClientLsCount`, `CGClientStatisInfo`, `CGCommand`, `CGDataSmuggler`, `CGDisclosureToGM`, `CGEnvRequest`, `CGExpAssign`, `CGExteriorRequest`, `CGExteriorShareStyle`, `CGExteriorYiRongGe`, `CGGSScore`, `CGGameLog`, `CGGetReturnPage`, `CGGetTujian`, `CGHuaShanMenpai`, `CGJZWLZDCmnData`, `CGKMCorpOper`, `CGKfsOperate`, `CGLegalCheck`, `CGLogSubmit`, `CGLwOperate`, `CGModifyIMStatus`, `CGNeiDanBaoTuData`, `CGNewAskGSInfo`, `CGNewGSScore`, `CGNewServerAskXFSJHumanInfo`, `CGNormal`, `CGOpenFuJiangTianLong`, `CGOrnamentsOperation`, `CGPackUpPacket`, `CGPlayerInfo`, `CGPlayerInfoCollect_2018`, `CGPlayerInfoCollect_WOW`, `CGQRJWordsOperate`, `CGReplyQuery`, `CGReqManualAttr`, `CGRetFFM`, `CGReturnAsk`, `CGSectOper`, `CGSendCapieMessage`, `CGSendGQHYChouJiang`, `CGSyncClientPos`, `CGTelCodeMonitor`, `CGTest`, `CGTestClient`, `CGToyReq`, `CGUnderArmour`, `CGWApplyZhengZhao`, `CGWAskBrotherInfo`, `CGWAskDisclose`, `CGWAskGetBWRankAward`, `CGWAskLuckyCarpName`, `CGWAskServerNewLotteryName`, `CGWAskVipInfo`, `CGWAskXuYuanKaRankData`, `CGWAskZhengZhaoList`, `CGWAskZhengZhaoMemberInfo`, `CGWAskZhouNianYuanName`, `CGWAskfmzoneInfo`, `CGWBinCommonData`, `CGWBinCommonString`, `CGWDFWOperate`, `CGWDfsQueryRankList`, `CGWGAchReq`, `CGWGBrotherRetSpirit`, `CGWGQinmiToTudi`, `CGWInviteBZTXMember`, `CGWInviteMemAnswer`, `CGWJZWLZDAskRankListInfo`, `CGWLZDBaseData`, `CGWNormalRankingListAsk`, `CGWRankingListAsk`, `CGWWLZDRankingListAsk`, `CGXiuChangLogout`, `CGXunzhangOperation`, `CGYingXiong`, `CGZBSCmnData`, `CGZNQSendInsert`, `CGZdZdRequest`, `CLAskQuitQuene`, `CLAskSMSCode`, `CLAskSafeCheck`, `CLCancelDelChar`, `CLRetAskToReCheckCode`, `GC2015QiXiJH`, `GC2019JinLi`, `GC26QXPVEMapData`, `GC7ZhouNianBoxList`, `GCAnniversaryInfo`, `GCAnonymousDecryption`, `GCAppRankListRankData`, `GCAscendingCode`, `GCAskGSBind`, `GCBBSMessages`, `GCBGLiuTongTabMap`, `GCBHSDZDCopySceneBasicData`, `GCBHSDZDCopySceneData`, `GCBHSDZDCopySceneFullData`, `GCBHSDZDCopyScenePKResultData`, `GCBXDBZCmnData`, `GCBXJGeCaoRankList`, `GCBXJGeCaoUpdataPos`, `GCBXJWuHuiMiniMapData`, `GCBXJWuHuiRankList`, `GCBXJWuHuiUpdataPos`, `GCBianJingBidding`, `GCBusAddPassenger`, `GCBusChangeDirection`, `GCByname`, `GCCancelGSBind`, `GCChampionCupInfo`, `GCChangeGSBind`, `GCCharAction`, `GCCharChangeDirection`, `GCCharChangeInteraction`, `GCCharDoContAction`, `GCCharDoNPCSpecialAction`, `GCCharGetDown`, `GCCharHxyEffectWork`, `GCCharModifyAction`, `GCCharTakeOff`, `GCChongLouEffect`, `GCChristmas2015ElkPos`, `GCChristmasThiefPos`, `GCClearDirty`, `GCCommonMonsterSyncMapData`, `GCDarkResult`, `GCDelAllObject`, `GCDetailVipInfo`, `GCDetailXinbiwu_2018`, `GCDetailXueWeiList`, `GCDetailZongMenInfo`, `GCDfsSceneSyncData`, `GCDiGongPos`, `GCDie`, `GCDoubleExpInfo`, `GCDunJiaShuData`, `GCETJCmnData`, `GCETJGameData`, `GCETJSynMembersInfo`, `GCExamRankingListRet`, `GCExpAssign`, `GCExteriorInfo`, `GCExteriorShareStyle`, `GCExteriorYiRongGe`, `GCFFM`, `GCFYJCGRRankListRet`, `GCFYJCTDRankListRet`, `GCFZXXMonsterPos`, `GCFZXXMonsterRem`, `GCFZXXPos`, `GCFanGuangHuiYanAwardInfo`, `GCFanGuangHuiYanCmnData`, `GCFightBgm`, `GCGMVisibleSyncData`, `GCGSScoreRet`, `GCGouWuCheInfo`, `GCGroupingNameRet`, `GCGuanHuaiJueQingGuInfo`, `GCHLSCOpen`, `GCHaoXiaRoad`, `GCHuaShanGRMatchScore`, `GCHuaShanMenpai`, `GCHuaShanPos`, `GCHuaZhaoJieInfo`, `GCIcePrizeDraw`, `GCInnerAlchemy`, `GCJHShituInfo`, `GCJZWLZDCmnData`, `GCJZWLZDRankList`, `GCJoinMenpai`, `GCJuqingPoint`, `GCKMFightSceneData`, `GCKvkMaZeiPosList`, `GCLegalCheck`, `GCLongZhouList`, `GCManorPos`, `GCManualAttrResult`, `GCMengTuFinishPoint`, `GCMenpaiInfo`, `GCModifySpeed`, `GCMsgBall`, `GCNeiDanBaoTuData`, `GCNetCheck`, `GCNewBus`, `GCNewGSLink`, `GCNewPortal`, `GCNewServerRetXFSJHumanInfo`, `GCOpenChangYouJiaPlus`, `GCOpenFuJiangTianLong`, `GCOpenTransitionSceneEffect`, `GCOperateResult`, `GCOrnamentsDataUpdate`, `GCPackUpPacket`, `GCPacketStream`, `GCPandaPosTabMap`, `GCPartyMealPos`, `GCPhoenixPlainWarCampInfo`, `GCPhoenixPlainWarCrystalPos`, `GCPhoenixPlainWarFlagPos`, `GCPhoenixPlainWarScore`, `GCPlayerAge`, `GCPlayerInfo`, `GCPrescription`, `GCPrivateInfo`, `GCPxxInitInfo`, `GCQIXIPVEMonsterInfo`, `GCQIXIPVESyncName`, `GCQIXIPVESyncScore`, `GCQRJWordsOperate`, `GCQuanMin8XingOp`, `GCQuickEnterPoint`, `GCRefreshSuperAttr`, `GCReqMachineCode`, `GCRequestSMSCode`, `GCRetAppWareCheck`, `GCRetApproveAscendingCode`, `GCRetAskScore`, `GCRetCheckSafecode`, `GCRetDaFuwengData`, `GCRetExteriorYiRongGe`, `GCRetFHSXData`, `GCRetGQHYChouJiang`, `GCRetGetBiWuRankSuc`, `GCRetSMSCode`, `GCRetSecKillData`, `GCRetSecKillNum`, `GCRetSetActivePoint`, `GCRetStandData`, `GCRetTujian`, `GCRetZNQfudaiInfo`, `GCReturnResult`, `GCSBGHumanInfo`, `GCSJTXSceneSyncData`, `GCSectDetail`, `GCServerQuery`, `GCSetMouseBJJJH`, `GCShowFeastTaps`, `GCShowShengXiaoTaps`, `GCSongliaoSyncDingInfo`, `GCSongliaoSyncName`, `GCSongliaoSyncScore`, `GCSpecialObj_ActNow`, `GCSpecialObj_FadeOut`, `GCSpringFestivalBidding`, `GCSyncClientPos`, `GCSyncCommanderSceneData`, `GCSyncCommanderSvrData`, `GCSyncLongzhuInfo`, `GCTCWSyncEnvironmentData`, `GCTSLCmnData`, `GCTSLRankList`, `GCTXbwMatchListInfo`, `GCTeQuanKaInfo`, `GCTianJiChengOp`, `GCToyInfo`, `GCTransBWaitInfo`, `GCTujianInfo`, `GCUnderArmour`, `GCUpdateGuiShiBaseData`, `GCUpdateMenPaiDiYi`, `GCUpdatePlayerQuicklyEnter`, `GCUpdateZhaoHuiData`, `GCVerificationCode`, `GCVirtualNPCInfo`, `GCWGAchReq`, `GCWGCPacket`, `GCWLZDBaseData`, `GCWLZDStageState`, `GCWatermelonScorceRank`, `GCWeekcardInfo`, `GCWriteProcessMemory`, `GCWuShenTanHuaChePos`, `GCXFXYCSDPos`, `GCXbwBroadKill`, `GCXbwCopySceneBasicData`, `GCXbwCopySceneData`, `GCXbwCopySceneFullData`, `GCXbwResultData`, `GCXinFuHongBaoDatainfo`, `GCXinShouCarnInfo`, `GCXinShouYueInfo`, `GCXinfaStudyInfo`, `GCXiuChangShutDown`, `GCXunzhangOperationRet`, `GCYingXiong`, `GCZBSCmnData`, `GCZBSGMVisable`, `GCZdZdRequestResult`, `GCZhouNianHuaCheList`, `GCZhuGeCaiYun`, `GCZiweixingluoPos`, `GWGCQinmiToTudi`, `LCAskToRecheckCode`, `LCMibaoReCheckResult`, `LCPxxInitInfo`, `LCRequestSMSCode`, `LCRetCancelDelChar`, `LCRetSMSCode`, `LCRetSafeCheck`, `WGCAskBrotherSpirit`, `WGCAskXuYuanKaRankData`, `WGCCTUGabrielCommond`, `WGCDFWRet`, `WGCDfsError`, `WGCDfsOperResult`, `WGCDismissZhengZhao`, `WGCJZWLZDRankListInfo`, `WGCNormalRankingListRet`, `WGCOpHuaZhaoTopList`, `WGCRankingListRet`, `WGCRetApplyZhengZhao`, `WGCRetAskZhengZhaoList`, `WGCRetBinCommonData`, `WGCRetBinCommonString`, `WGCRetBrotherInfo`, `WGCRetCSRankingAsk`, `WGCRetDfsRankList`, `WGCRetFBRankingAsk`, `WGCRetJiebanPartnerList`, `WGCRetLuckyCarpName`, `WGCRetQueryQixiTopList`, `WGCRetQueryRoseTopList`, `WGCRetQueryYBNewSrvTopList`, `WGCRetQueryYBTopList`, `WGCRetServerNewLotteryName`, `WGCRetVipInfo`, `WGCRetZhengZhaoMemberInfo`, `WGCRetZhouNianYuanName`, `WGCShiMenInfo`, `WGCWLZDRankingListRet`
- **vật phẩm/hành trang** (181): `CGAskBudgetPlanGemInfo`, `CGAskDetailEquipList`, `CGAskFashionDepotData`, `CGAskGemContainer`, `CGAskGetNewAuctionItem`, `CGAskIMDress`, `CGAskIMDressChest`, `CGAskIMDressMail`, `CGAskItemInfo`, `CGAskJPNewAuctionItem`, `CGAskMyBagList`, `CGAskMyBagSize`, `CGAskMyTemBankList`, `CGAskPreIMDressMailInfo`, `CGAskRideBagInfo`, `CGAskWorldItemStoreOpt`, `CGAuctionMultiBuyItem`, `CGBankAcquireList`, `CGBankAddItem`, `CGBankClose`, `CGBankMoney`, `CGBankRemoveItem`, `CGBankSwapItem`, `CGBieYeBankAcquireList`, `CGBieYeFurnitureRemoveItem`, `CGBieYeMengChongRemoveItem`, `CGCangPin`, `CGChangeIMDress`, `CGCharAskEquipment`, `CGCharAutoRide`, `CGCityBankAcquireList`, `CGCityBankAddItem`, `CGCityBankAskForRecord`, `CGCityBankRemoveItem`, `CGCityBankSetAccess`, `CGDRideOperate`, `CGDeleteIMDress`, `CGDiscardEquip`, `CGDiscardItem`, `CGDisplaceGem`, `CGDressTransform`, `CGExchangeApplyI`, `CGExchangeCancel`, `CGExchangeCode`, `CGExchangeOkIII`, `CGExchangeReplyI`, `CGExchangeSynchItemII`, `CGExchangeSynchLock`, `CGExchangeSynchMoneyII`, `CGFashionDepotOperation`, `CGGemChange`, `CGGemCompound`, `CGIMDressChest_SwapItem`, `CGIMDressMultiBuy`, `CGIMDressMultiBuyToOther`, `CGInfantDressOperate`, `CGItemSynch`, `CGMilitaryShopBuyItem`, `CGNobilityShopBuyItem`, `CGOpenItemBox`, `CGOtherEquip`, `CGPackUpBank`, `CGPackUpIMDressChest`, `CGPackage_SwapItem`, `CGPetBankAddPet`, `CGPetUnEquip`, `CGPetUseEquip`, `CGPickBoxItem`, `CGPlayerShopAcquireItemList`, `CGPlayerShopBuyItem`, `CGPlayerShopMultiBuyItem`, `CGRemoveDressGem`, `CGRemoveGem`, `CGRequestNewAuctionItem`, `CGSecKillRemoveItem`, `CGSetOpenWhichBank`, `CGShideShopBuyItem`, `CGShowFashionDepotData`, `CGSplitItem`, `CGStallAddItem`, `CGStallItemPrice`, `CGStallRemoveItem`, `CGTemBankSwap`, `CGUnEquip`, `CGUseEquip`, `CGUseGem`, `CGUseItem`, `CGWorldItemStoreSwap`, `CGYiGuiDressAndWeapon`, `GCAddCanPickMissionItem`, `GCAskFashionDepotData`, `GCBagSizeChange`, `GCBankAcquireList`, `GCBankAddItem`, `GCBankBegin`, `GCBankItemInfo`, `GCBankMoney`, `GCBankRemoveItem`, `GCBankSwapItem`, `GCBoxItemList`, `GCBusRemoveAllPassenger`, `GCBusRemovePassenger`, `GCCanPickMissionItemList`, `GCCangPin`, `GCCangPinRank`, `GCCangPinShop`, `GCCharAutoRide`, `GCCharEquipment`, `GCCityBankBegin`, `GCCityBankItemList`, `GCCityBankRecordList`, `GCCityBankSetAccessResult`, `GCDRideOperate`, `GCDetailEquipList`, `GCDiscardEquipResult`, `GCDiscardItemResult`, `GCDisplaceGemResult`, `GCDressTransform`, `GCEquipUpstageResult`, `GCExchangeApplyI`, `GCExchangeCancel`, `GCExchangeCode`, `GCExchangeConfirm`, `GCExchangeError`, `GCExchangeEstablishI`, `GCExchangeSuccessIII`, `GCExchangeSynchConfirmII`, `GCExchangeSynchII`, `GCExchangeSynchLock`, `GCFYPVESyncItemData`, `GCFanGuangHuiYanItemList`, `GCFashionAuction`, `GCFashionDepotOperation`, `GCGemContainer`, `GCIMDressChest_SwapItem`, `GCItemInfo`, `GCItemList`, `GCItemSynch`, `GCMissionRemove`, `GCMonsterEquipment`, `GCMyBagList`, `GCMyTemBankList`, `GCOtherEquip`, `GCPackUpBank`, `GCPackUpIMDressChest`, `GCPackage_SwapItem`, `GCPetBankAddPet`, `GCPetBankListUPData`, `GCPetUnEquipResult`, `GCPetUseEquipResult`, `GCPickResult`, `GCRefreshEquipAttr`, `GCRefreshEquipZiZhi`, `GCRefreshPetEquipZiZhi`, `GCRemoveCanPickMissionItem`, `GCRemoveGemResult`, `GCRemoveInfant`, `GCRemovePet`, `GCRetAskJPNewAuctionItem`, `GCRetBudgetPlanGemInfo`, `GCRetIMDress`, `GCRetIMDressChest`, `GCRetPreIMDressMailInfo`, `GCRetWorldItemStoreOpt`, `GCReturnItemList`, `GCRideBagInfo`, `GCSecKillRemoveItem`, `GCShowFashionDepotData`, `GCSplitItemResult`, `GCStallAddItem`, `GCStallItemPrice`, `GCStallRemoveItem`, `GCTLCJItemOpt`, `GCTemBankSwap`, `GCUnEquipResult`, `GCUseEquipResult`, `GCUseGemResult`, `GCUseItemResult`, `GCWorldItemStoreSwap`, `GCYiGuiItemList`, `KeyExchange`
- **tổ đội/bang/quan hệ** (173): `CGAlyExpToMaster`, `CGAskDetailPetMaster`, `CGAskFindCatData`, `CGAskMail`, `CGAskTeamInfo`, `CGAskTeamMemberInfo`, `CGAutoCreateTeam`, `CGBXJGeCaoTeamOper`, `CGBXJWuHuiTeamOper`, `CGCityAskAttr`, `CGCommonTeamOper`, `CGCorpsInviteConfirm_2016`, `CGCorpsOper_2016`, `CGCorpsOper_2018`, `CGCreateCorps_2016`, `CGCreateCorps_2018`, `CGCreateGuildLeague`, `CGFinger`, `CGGangTerritory`, `CGGetMailAppend`, `CGGuild`, `CGGuildActValueOp`, `CGGuildApply`, `CGGuildGift`, `CGGuildJoin`, `CGGuildZhanTuanOp`, `CGGuildZhanTuanRankOp`, `CGInviteAddMeFriend`, `CGInviteToGuild`, `CGMail`, `CGPetFriends`, `CGRelation`, `CGSendMailNew`, `CGTCityWarLimitCmnData`, `CGTeamApply`, `CGTeamAppoint`, `CGTeamChangeOption`, `CGTeamDismiss`, `CGTeamInvite`, `CGTeamKick`, `CGTeamLeaderRetInvite`, `CGTeamLeave`, `CGTeamRetApply`, `CGTeamRetInvite`, `CGWApplyZhengZhaoTeam`, `CGWAskGuildOnTime`, `CGWAskMailNew`, `CGWAskMailNewList`, `CGWCorpsVoteOper_2018`, `CGWDfsCreateWTeam`, `CGWDfsQueryWTeamInfo`, `CGWDfsWTeamOper`, `CGWFriendADAskDetailInfo`, `CGWFriendADAskSearch`, `CGWFriendADAskSimpleInfo`, `CGWFriendADAskSimpleVoteInfo`, `CGWFriendADAskVoteInfo`, `CGWFriendADIssueOrEdit`, `CGWGuildActive`, `CGWGuildLeagueAnswerEnter`, `CGWGuildLeagueAskEnter`, `CGWGuildLeagueChangeInfo`, `CGWGuildLeagueInfo`, `CGWGuildLeagueList`, `CGWGuildLeagueMemberApplyList`, `CGWGuildLeagueQuit`, `CGWMailNewDelOrBack`, `CGWQueryCorpsInfo_2016`, `CGWQueryCorpsInfo_2018`, `CGWQueryCorpsRankList_2018`, `CGWQueryCorpsRankingCharts_2016`, `CGWSetCurZhanQi`, `CGWTCityWarLimitMemberList`, `CGWTQueryWTeamMatchInfo`, `CGWTQueryWTeamRankList`, `CGWTTXbwCreateWTeam`, `CGWTTXbwQueryWTeamInfo`, `CGWTTXbwWTeamOper`, `CGWTeamBoardAskInfo`, `CGWTeamBoardControlInfo`, `CGZBSCreateTeam`, `GCCityAttr`, `GCCityError`, `GCCityList`, `GCCityWarRankOp`, `GCCityWarZhanTuanRankOp`, `GCCompeMarryAliveInfo`, `GCCompeMarrySponsorList`, `GCCorpsCopySceneData_2016`, `GCCorpsCopySceneData_2018`, `GCCorpsError_2016`, `GCCorpsError_2018`, `GCCorpsMatchListInfo_2016`, `GCCorpsMatchListInfo_2018`, `GCCorpsOperResult_2016`, `GCCorpsOperResult_2018`, `GCDetailPetMaster`, `GCDfsWTeamListInfo`, `GCFYJCTDTeamJoin`, `GCFinalCorpsListInfo_2016`, `GCFinalCorpsListInfo_2018`, `GCFinger`, `GCGangTerritory`, `GCGuild`, `GCGuildActValueOp`, `GCGuildApply`, `GCGuildBatlePos`, `GCGuildError`, `GCGuildGift`, `GCGuildReturn`, `GCGuildSaoLeiOp`, `GCGuildZhanTuanRankOp`, `GCInviteAddMeFriend`, `GCJZWLZDTeamMemberData`, `GCKMCorpsInfo`, `GCMail`, `GCPetFriends`, `GCRelation`, `GCRetFindCatData`, `GCRetMailNew`, `GCRetMailNewOpt`, `GCRetOffLineRelation`, `GCRetSendMail`, `GCTCityWarLimitCmnData`, `GCTCityWarLimitGuildList`, `GCTeamAskApply`, `GCTeamAskInvite`, `GCTeamError`, `GCTeamLeaderAskInvite`, `GCTeamList`, `GCTeamMemberInfo`, `GCTeamOptionChanged`, `GCTeamResult`, `GCWLZDTeamMemberInfo`, `GCWSTGuideTeamData`, `GCXinShouZhanLing`, `GCZBSTeamInfo`, `GCZBSTeamListInfo`, `GWGCFriendPresent`, `KGCGuild`, `KGCGuildList`, `TWGCRetQueryWTeamInfo`, `TWGCRetQueryWTeamMatchInfo`, `TWGCRetTXbwWTeamRankList`, `TWGCTXbwWTeamError`, `TWGCTXbwWTeamOperResult`, `WGCFriendADGiveDetailInfo`, `WGCFriendADGiveSearchRet`, `WGCFriendADGiveSimpleInfo`, `WGCFriendADGiveSimpleVoteInfo`, `WGCFriendADGiveVoteInfo`, `WGCFriendADIssueOrEditRet`, `WGCGuildActive`, `WGCGuildLeagueInfo`, `WGCGuildLeagueList`, `WGCGuildLeagueMemberApplyList`, `WGCGuildRspTCWRecord`, `WGCGuildZhanTuanOp`, `WGCRetApplyZhengZhaoTeam`, `WGCRetCorpsInfo_2018`, `WGCRetCorpsRankList_2018`, `WGCRetCorpsVoteOper_2018`, `WGCRetDfsWTeamInfo`, `WGCRetGuildOnTime`, `WGCRetMailNewList`, `WGCRetQueryCorpsInfo_2016`, `WGCRetQueryCorpsRankingCharts_2016`, `WGCTCityWarLimitAssistList`, `WGCTeamBoardControlInfoResult`, `WGCTeamBoardGiveInfo`, `WGCZhanQiData`, `WTCTCityWarReturnRankList`, `WTW8RetTCityMemberList`
- **cửa hàng/giao dịch** (117): `CGAllianceShopBuy`, `CGAskChongLouShop`, `CGAskDiGongShopInfo`, `CGAskShowShopCredit`, `CGAskWeekShopInfo`, `CGAskZongMenShopInfo`, `CGAuctionBoxList`, `CGAuctionBuy`, `CGAuctionExpireBack`, `CGAuctionGetYB`, `CGAuctionModify`, `CGAuctionReUp`, `CGAuctionSearch`, `CGAuctionSell`, `CGAuctionTakeBack`, `CGPlayerShopAcquireShopList`, `CGPlayerShopApply`, `CGPlayerShopAskForRecord`, `CGPlayerShopBuyShop`, `CGPlayerShopDesc`, `CGPlayerShopEstablish`, `CGPlayerShopFavorite`, `CGPlayerShopMoney`, `CGPlayerShopName`, `CGPlayerShopOnSale`, `CGPlayerShopOpenStall`, `CGPlayerShopPartner`, `CGPlayerShopSaleOut`, `CGPlayerShopSaleShopAskInfo`, `CGPlayerShopSaleShopOpt`, `CGPlayerShopSearch`, `CGPlayerShopSize`, `CGPlayerShopType`, `CGShopBuy`, `CGShopBuyForFriend`, `CGShopClose`, `CGShopRepair`, `CGShopSell`, `CGStallApply`, `CGStallBuy`, `CGStallClose`, `CGStallDefaultPage`, `CGStallEstablish`, `CGStallOpen`, `CGStallSetStallOffline`, `CGStallShopName`, `CGT3ShopReq`, `CGWAskGuildShop`, `CGYuanBao`, `CGYuanBaoToBind`, `GCAuctionBoxList`, `GCAuctionChangeMoney`, `GCAuctionChangeStatus`, `GCAuctionError`, `GCAuctionSearch`, `GCDaHuaQiXiShopInfo`, `GCDailyShopInfo`, `GCDetailBWShopInfo`, `GCDetailCCShopInfo`, `GCDetailMilitaryShopInfo`, `GCDetailNobilityShopInfo`, `GCDetailShiDeShopInfo`, `GCDiGongShopInfo`, `GCFengMingShopInfo`, `GCGuiShiNpcShopInfo`, `GCGuildAuction`, `GCHuoYueShopInfo`, `GCNeiDanShopInfo`, `GCOpenPlayerShop`, `GCPVPShopInfo`, `GCPlayerShopAcquireShopList`, `GCPlayerShopApply`, `GCPlayerShopBuyShop`, `GCPlayerShopError`, `GCPlayerShopEstablish`, `GCPlayerShopMoney`, `GCPlayerShopOnSale`, `GCPlayerShopOpenStall`, `GCPlayerShopRecordList`, `GCPlayerShopSaleOut`, `GCPlayerShopSaleShopInfo`, `GCPlayerShopSaleShopOptResult`, `GCPlayerShopSearch`, `GCPlayerShopStallStatus`, `GCPlayerShopType`, `GCPlayerShopUpdateFavorite`, `GCPlayerShopUpdatePartners`, `GCQiXiGuideShopLimit`, `GCRetAuctionNewRequest`, `GCRetChongLouShop`, `GCRetKAllianceShopOp`, `GCRetSetStallState`, `GCRetShowShopCredit`, `GCRetWeekShopInfo`, `GCRetZongMenShopInfo`, `GCReturnShopList`, `GCSendFairShopData`, `GCShopBuy`, `GCShopMerchandiseList`, `GCShopRepair`, `GCShopSell`, `GCShopSoldList`, `GCShopUpdateMerchandiseList`, `GCStallApply`, `GCStallBuy`, `GCStallClose`, `GCStallError`, `GCStallEstablish`, `GCStallOpen`, `GCT3ShopInfo`, `GCTLCJShopInfo`, `GCWuShenTanShopLimit`, `GCXFTQShopInfo`, `GCXiaKeShopData`, `GCYuanBao`, `WGCRetGuildShop`, `WGCRetGuildShopError`
- **chiến đấu/kỹ năng** (88): `CGAskAddSkillList`, `CGAskComboSkillOperation`, `CGAskDetailSkillList`, `CGAskDetailXinFaList`, `CGAskMyPneumaExpChip`, `CGAskMyPneumaList`, `CGAskStudyXinfa`, `CGAskSuperWeaponDIYSkill`, `CGAskTargetHuanLing`, `CGAskTargetPneumaList`, `CGAttack`, `CGChallenge`, `CGChannelCreate`, `CGChannelDismiss`, `CGChannelInvite`, `CGChannelKick`, `CGCharAskImpactList`, `CGCharUseSkill`, `CGDispelBuffReq`, `CGLockTarget`, `CGMoneyChallenge`, `CGPneumaOpt`, `CGReqResetAttr`, `CGSelectTargetOfObject`, `CGSkill`, `CGSpouseDressImpact`, `CGWGCDuel`, `CGXingZhen`, `GCAddSkill`, `GCAddSkillList`, `GCAttack`, `GCChallenge`, `GCChallengeListInfo`, `GCChallengeRoomMemberList`, `GCChannelError`, `GCChannelResult`, `GCCharBeHitOut`, `GCCharBuff`, `GCCharDirectImpact`, `GCCharImpactListUpdate`, `GCCharSkill_CreateBullet`, `GCCharSkill_Gather`, `GCCharSkill_Gather_Modify`, `GCCharSkill_Lead`, `GCCharSkill_Lead_Modify`, `GCCharSkill_Missed`, `GCCharSkill_Send`, `GCClearStealSkillInBar`, `GCComboSkillOperation`, `GCDetailBuff`, `GCDetailComboSkillList`, `GCDetailHealsAndDamages`, `GCDetailImpactListUpdate`, `GCDetailSkillList`, `GCDetailXinFaList`, `GCErrorAttack`, `GCErrorSkill`, `GCIASkill`, `GCMoneyChallenge`, `GCMyPneumaExpChip`, `GCMyPneumaList`, `GCNewSkillObj`, `GCNewSummoner_SkillChannel`, `GCOtherAttack`, `GCOtherSkill`, `GCPlayerRelive`, `GCRefreshDarkSkill`, `GCRefreshInfantSkill`, `GCRefreshKFSSkill`, `GCReqResetAttrResult`, `GCRetPneumaOpt`, `GCRetSuperWeaponDIYSkill`, `GCSelectTarget`, `GCSkill`, `GCSkillPrepare`, `GCSpouseDressImpactSend`, `GCStealSkillInfo`, `GCStudyXinfa`, `GCSynPneumaSmeltBag`, `GCT3ZhanGongTarget`, `GCTalentFullData`, `GCTalentSkill`, `GCTargetHuanLingInfo`, `GCTargetListAndHitFlags`, `GCTargetPneumaList`, `GCXingZhen`, `GCXingZhenNpcShopInfo`, `GCXingZhenSkill`
- **nhiệm vụ** (84): `CGAskCampaignCount`, `CGAskCatMission`, `CGAskMissionList`, `CGAskRaidInfo`, `CGAskRaidMemberInfo`, `CGCharDefaultEvent`, `CGDoEvent`, `CGEventRequest`, `CGFYPVECmnData`, `CGMissionAbandon`, `CGMissionAccept`, `CGMissionCheck`, `CGMissionContinue`, `CGMissionRefuse`, `CGMissionSubmit`, `CGPVPCarTeamOper`, `CGRaidApply`, `CGRaidAppoint`, `CGRaidCreate`, `CGRaidInvite`, `CGRaidKick`, `CGRaidLeave`, `CGRaidRetApply`, `CGRaidRetInvite`, `CGRetQuestion`, `CGWASkGuildBattleHisInfo`, `CGWAskGuildBattleRank`, `CGXBWCmnData`, `CGXBWCreateTeam`, `CGXBWJHSCmnData`, `CGZYPVPTeamOper`, `CTWTGuildBattle`, `GC2021Q3SignInActivity`, `GCAskQuestion`, `GCBieYeQiYuNpcPos`, `GCDynActivityTime`, `GCFYPVECmnData`, `GCFYPVECmnInfo`, `GCFYPVESyncMapData`, `GCKSBossMiniMapRefresh`, `GCMissionAdd`, `GCMissionHaveDoneFlag`, `GCMissionList`, `GCMissionModify`, `GCMissionResult`, `GCQXPVPSyncPlayerInfo`, `GCQXPVPSyncRank`, `GCRaidAskApply`, `GCRaidAskInvite`, `GCRaidError`, `GCRaidList`, `GCRaidMemberInfo`, `GCRaidResult`, `GCRetCampaignCount`, `GCRetCatMission`, `GCShowPVPCARTaps`, `GCSyncBossInfo`, `GCSyncXiaKeBossInfo`, `GCTJCPVPMonsterInfo`, `GCTLCJCmnData`, `GCTLCJPlayerInfoOpt`, `GCTLCJSyncBattleData`, `GCTLCJSyncMapData`, `GCTWorldBossMonsterInfo`, `GCTWorldBossSceneRankInfo`, `GCXBWCmnData`, `GCXBWJHSBattleData`, `GCXBWJHSCmnData`, `GCXBWJHSTeamData`, `GCXBWTeamData`, `GCXRZPVPCmnData`, `GCXRZPVPSyncBattleData`, `GCXRZPVPSyncMapData`, `GCZBSBattleInfoToGM`, `GCZJZDPVPOperation`, `GCZMBossRankList`, `GCZYPVPRankList`, `GCZYPVPUpdataPos`, `WGCRetGuildBattleHis`, `WGCRetGuildBattleRank`, `WGCRetQueryXBWRankCharts`, `WGCRetTeamRaidPlayerInfo`, `WGCXBWTeamList`, `WGCXBWTeamRankList`
- **chat/thông báo** (60): `CGAskDoDoubleChatAction`, `CGAskGSChatInfo`, `CGAskGSChitChatInfo`, `CGAskGSChitChatSN`, `CGCharMoodState`, `CGChat`, `CGChatGroupOperate`, `CGChatSymbol`, `CGCreateChatGroup`, `CGGMChat`, `CGGSChat`, `CGMACNotify`, `CGNewPlayer2GMChat`, `CGRefreshShowOffMsg`, `CGRefreshTShowOffMsg`, `CGRemoveRMBChatAction`, `CGRemoveRMBChatFace`, `CGSetMoodToHead`, `CGWAskNewServerBroadcast`, `CGWFriendADPlayerMsg`, `CLAskQueueMsg`, `GCAppChat`, `GCAskDoDoubleChatAction`, `GCChat`, `GCChatGroupResult`, `GCChatSignRedPoint`, `GCChatSymbol`, `GCChitChatFlag`, `GCCityNotify`, `GCDirectString`, `GCExchangeNotifySerial`, `GCGMChat`, `GCGSChat`, `GCGSChatInfoRet`, `GCKvkShowOffMsg`, `GCMonsterSpeak`, `GCNotifyChangeScene`, `GCNotifyEquip`, `GCNotifyGoodBad`, `GCNotifyMail`, `GCNotifyNeiGuaInfo`, `GCNotifyPneuma`, `GCNotifyQXPVPPos`, `GCNotifyQuery`, `GCNotifyRaidInfo`, `GCNotifyTeamInfo`, `GCNotifyTemBank`, `GCNpcTalk`, `GCPopupString`, `GCRMBChatActionInfo`, `GCRMBChatFaceInfo`, `GCRetGMMsg`, `GCRetGSChitChatInfo`, `GCRetGSChitChatSN`, `GCShowOffMsg`, `LCRetQueueMsg`, `WGCFriendADPlayerMsgRet`, `WGCNotifyMailNew`, `WGCRetQueryNewServerBroadcast`, `WGCXiuChangNotify`
- **vào cảnh/di chuyển** (54): `CGAskChangeScene`, `CGAskTeamFollow`, `CGCharFly`, `CGCharJump`, `CGCharPositionWarp`, `CGCharStopLogic`, `CGFlyOperation`, `CGLeaveScene`, `CGPlayerCallOfResult`, `CGPlayerVMMapInfo`, `CGRaidModifyMemberPosition`, `CGReturnTeamFollow`, `CGRideBagMoveItem`, `CGStopPedding`, `CGStopTeamFollow`, `CGTSTestAskChangeScene`, `CGWeaponYiGuiMoveItem`, `CGYiGuiMoveItem`, `GCArrive`, `GCAskTeamFollow`, `GCBusMove`, `GCBusStopMove`, `GCCharDoAction`, `GCCharFly`, `GCCharJump`, `GCCharMoveResult`, `GCCharStopAction`, `GCCommonPos`, `GCDrideStartStop`, `GCFYJCPVPMapInfo`, `GCFollow`, `GCLeaveScene`, `GCMonsterRealMove`, `GCNewBus_Move`, `GCNewInfant_Move`, `GCNewMonster_Move`, `GCNewPet_Move`, `GCNewSummoner_Move`, `GCObjTeleport`, `GCOpenWorldReference`, `GCPlayerAutoRun`, `GCPlayerCallOf`, `GCPlayerRealMove`, `GCRetChangeScene`, `GCRetRaidModifyMemberPosition`, `GCReturnTeamFollow`, `GCRideBagMoveItemResult`, `GCStopPedding`, `GCTeamFollowErr`, `GCTeamFollowList`, `GCWeaponYiGuiMoveItemResult`, `GCWeekPveMapInfo`, `GCYiGuiMoveItemResult`, `GCZBSBattleSceneInfo`
- **nhịp tim/hệ thống** (51): `CGAntiStudio`, `CGAskDynamicRegion`, `CGAskMobilePhoneStatus`, `CGAskNoteLog`, `CGAskServerTime`, `CGAskSetting`, `CGAskx64Info`, `CGCIPRegion`, `CGCYJTest`, `CGClientPerformanceBlock`, `CGClientPerformanceNormal`, `CGClientState`, `CGGameCommond`, `CGGrabMessage`, `CGMiniStat`, `CGModifySetting`, `CGNTPPacket`, `CGNetDelay`, `CGReportWaigua`, `CGRequestMobileApprove`, `CGRetCheckMemory_00`, `CGTLBBRecorderLog`, `CGWaiGuaReportNew`, `CGWaiguaInfo`, `CGXiuChangStopHeartBeat`, `CLAskAntiViolentCode`, `GCAskDynamicRegionResult`, `GCAskServerTime`, `GCCheckMemory_00`, `GCFangChenMiError`, `GCGameCommond`, `GCGrabMessage`, `GCNTPPacket`, `GCNetClean`, `GCRetAskMobilePhoneStatus`, `GCRetAskQuit`, `GCRetMobileApprove`, `GCRetNetDelay`, `GCRetReportWaigua`, `GCRetSetting`, `GCReturnRegion`, `GCSendCheckMobileSafeCode`, `GCServerLsCount`, `GCSetDynamicRegion`, `GCStartCrashUpload`, `GCTest`, `GCTestClient`, `GCWorldTime`, `GCXiuChangRetHeartBeat`, `LCRetAntiViolentCode`, `LCStatus`
- **thuộc tính nhân vật** (39): `CGAskAchievements`, `CGAskDetailAbilityInfo`, `CGAskDetailAttrib`, `CGAskDetailFiveElements`, `CGAskDoubleExp`, `CGAskLeanAbility`, `CGAskMartialAllData`, `CGCharAllTitles`, `CGCharAskBaseAttrib`, `CGCharCharge`, `CGCharUpdateCurTitle`, `CGCharUpdateCurTitleEffect`, `CGReqLevelUp`, `CGSetPetAttrib`, `CGUseAbility`, `GCAbandonAbility`, `GCAbilityAction`, `GCAbilityExp`, `GCAbilityLevel`, `GCAbilityResult`, `GCAbilitySucc`, `GCAbilityTeacherInfo`, `GCAbilityZhuanjing`, `GCChangeFatigueState`, `GCCharAllTitles`, `GCCharCharge`, `GCCooldownUpdate`, `GCDetailAbilityInfo`, `GCDetailAttrib`, `GCDetailAttrib_Infant`, `GCDetailAttrib_Pet`, `GCDetailExp`, `GCDetailFiveElements`, `GCDetailXiulianList`, `GCLevelUp`, `GCLevelUpResult`, `GCMartialExp`, `GCMartialFullData`, `GCRetAchievements`
- **thú cưng/nhi** (37): `CGBieYeAddMengChong`, `CGBieYeMengChongAcquireList`, `CGBieYePetProcreateRegisterUI`, `CGInfantChangeName`, `CGInfantExteriorChange`, `CGIssuePetPlacard`, `CGManipulateInfant`, `CGManipulateMengChong`, `CGManipulatePet`, `CGMengChongOpt`, `CGPetHuanLingCollectionRequest`, `CGPetNeiDan`, `CGPetProcreateRegisterUI`, `CGUseInfantCard`, `GCBieYeCreatePetError`, `GCBieYeMengChongList`, `GCBieYeMengChongOpt`, `GCBieYePetProcreateRegisterUI`, `GCChildrenDayScorceRank`, `GCInfantAttr`, `GCInfantExteriorChange`, `GCInfantHeroCard`, `GCManipulateInfantRet`, `GCManipulateMengChongRet`, `GCManipulatePetRet`, `GCNewInfant`, `GCNewSummoner`, `GCPetHuanLingCollectionInfo`, `GCPetNeiDan`, `GCPetPlacardList`, `GCPetPossBufInfo`, `GCPetPossShowUpdate`, `GCPetProcreateRegisterUI`, `GCReturnPetList`, `GCSummonerObj_ActNow`, `GCUpdateCapturePetOwn`, `GCUseInfantCardResult`
- **đăng nhập/tài khoản** (25): `CGCYJPlusYanZheng`, `CGCancelConnectGMChat`, `CGClientPerformanceLogin`, `CGConnectGMChat`, `CGLoginAcc`, `CGMinorPasswd`, `CGPackGetAccountPacket`, `CGXiuChangLogin`, `CLAskQRCodeLogin`, `CLAskWeGameLogin`, `CLCheckAllowCreateChar`, `CLConnect`, `CLRegNewLicense`, `CLRegSafeSign`, `GCMinorPasswd`, `GCPackGetAccountPacket`, `GCRetAppYanZheng`, `GCRetCYJPlusYanZheng`, `GCRetConnectGMChat`, `GCXiangLongCiFuAccountInfo`, `GCXiuChangRetLogin`, `LCRetCheckAllowCreateChar`, `LCRetConnect`, `LCRetCreateChar`, `LCRetDeleteChar`
- **đối tượng trong cảnh** (22): `CGAskLockObj`, `CGAskPlayerInfoBySuper`, `CGLookUpOther`, `CGNameBoardExOperation`, `CGPlayerDieResult`, `GCAddLockObj`, `GCLookUpOther`, `GCNameBoardExDataUpdate`, `GCNewItem`, `GCNewItemBox`, `GCNewMonster`, `GCNewMonster_Death`, `GCNewMonster_SkillChannel`, `GCNewPet`, `GCNewPet_Death`, `GCNewPet_SkillChannel`, `GCNewPlatform`, `GCNewPlayer_Death`, `GCNewPlayer_SkillChannel`, `GCNewSpecial`, `GCNewSummoner_Death`, `GCPlayerDie`
- **biệt dã** (20): `CGAskBieYeBaseInfo`, `CGAskBieYeJiaYanUser`, `CGAskBieYeResInfo`, `CGBieYeAddFurniture`, `CGBieYeBuildingOperate`, `CGBieYeComfortTopListOperate`, `CGBieYeFurnitureAcquireList`, `CGBieYeFurnitureObjOperate`, `CGBieYeTickScenePlayer`, `GCBieYeAllFurnitureObj`, `GCBieYeBaseInfo`, `GCBieYeBuildingsData`, `GCBieYeComfortTopListData`, `GCBieYeFurnitureList`, `GCBieYeFurnitureListWithCK`, `GCBieYeFurnitureObjOperateResult`, `GCBieYeResUpdate`, `GCBieYeScenePlayerList`, `GCBieYeStyleUpdate`, `GCRetBieYeJiaYanUser`
- **giao diện/script** (15): `CGAskOpenUIState`, `CGAskServerConfigInfo`, `CGExecuteScript`, `CGShadowCursorCommand`, `CGUICommandError`, `CGZbsAskHideUI_2016`, `GCMovieOpr`, `GCQuickEnterPointTip`, `GCRetServerConfigInfo`, `GCScriptCommand`, `GCSetCameraState`, `GCShadowCursorCommand`, `GCUICommand`, `GCUICommandEx`, `GCZbsRetHideUI_2016`

### 3.2 Tệp dữ liệu chưa có (592)

- Không có mã hay công cụ nào nhắc tên (579): `2606SLevelInfo.txt`, `AccountSafeRef.txt`, `ActionExtInfo.txt`, `ActionSetFile.txt`, `ActiveHaoLi.txt`, `ActivityGift.txt`, `AnonymousCommonInfo.txt`, `AppearanceAchivement.txt`, `AppearanceLevel.txt`, `Appearanceshop.txt`, `AttackTraits.txt`, `AutoSearch.txt`, `AwardTaskList.txt`, `AwardTaskType.txt`, `BeHit.txt`, `BeiWangLu.txt`, `BiWuShop.txt`, `BianJingBiddingItem.txt`, `BianJingExchangeItem.txt`, `BieYeBuildingLevelUp.txt`, `BieYeBuildingRes.txt`, `BieYeFurniture.txt`, `BieYeFurnitureMood.txt`, `BieYeFurnitureShop.txt`, `BieYeHuanZhuang.txt`, `BieYeItemRes.txt`, `BieYeMaterialOutput.txt`, `BieYeMengChong.txt`, `BieYeSceneDefine.txt`, `BuildingDefine.txt`, `BuildingName.txt`, `Bullet.txt`, `BusInfo.txt`, `CJI.txt`, `CJS.txt`, `CJ_EquipInfo.txt`, `CJ_ItemInfo.txt`, `CJ_SkillInfo.txt`, `CXGEnterTips.txt`, `CampaignTable.txt`, `CampaignTableNew.txt`, `CampaignTableNew_KaJi_1.txt`, `CampaignTable_KaJi_1.txt`, `CangPinSetEffect.txt`, `CangPinShop.txt`, `CangPin_ClassLevel.txt`, `CangPin_Item.txt`, `CangPin_Level.txt`, `CangPin_QualUp.txt`, `CangPin_RankBonus.txt`, `CangPin_Set.txt`, `Canyeshop.txt`, `CardRule.txt`, `CatMission.txt`, `Catinfo.txt`, `ChampionCupTeamInfo.txt`, `CharHead.txt`, `CharHeadFrame.txt`, `CharMount.txt`, `CharTitle.txt`, `CharTitleBoard.txt`, `CharTitleNew.txt`, `ChatConfig.txt`, `ChatHelp.txt`, `ChatMood.txt`, `ChatMood_Double.txt`, `ChatSymbol.txt`, `ChengjiuDesc.txt`, `ChengjiuType.txt`, `ChongLouEffect.txt`, `ChongLouShop.txt`, `ChonglouDecor.txt`, `CityBuilding.txt`, `CityIdOfChina.txt`, `CityInfo.txt`, `ClientType.cfg`, `ComboSkillBook.txt`, `ComboSkillRate.txt`, `CrashNoteKeyList.txt`, `DLSH.txt`, `DLSH_KaJi_1.txt`, `DaHuaQiXi_Shop.txt`, `DaHuaQiXi_Shop_kaji.txt`, `DarkBaseQuality.txt`, `DarkExpLevel.txt`, `DarkImpackStr.txt`, `DarkLYCuiDuLevelUP.txt`, `DarkLYStarUpData.txt`, `DaysSign.txt`, `DaysSign_KaJi_1.txt`, `DecoWeaponConvert.txt`, `DecoWeaponLevelUp.txt`, `Di4Shop.txt`, `Di4Shop_KaJi_1.txt`, `Di4Shop_OriginalJD_1.txt`, `DiaowenInfo.txt`, `DiaowenRule.txt`, `DingZhiMenPaiSvr.txt`, `DoubleGemCompound.txt`, `DressColorRate.txt`, `DressColorSpecial.txt`, `DressTransform.txt`, `DuanWeiHonourShop.txt`, `DuanWeiHonourShop_QX.txt`, `DuanWeiYuanBaoShop.txt`, `DuanWeiYuanBaoShop_QX.txt`, `DuanWuBiddingBonus.txt`, `DuanWuChouJiang.txt`, `DuanWuChouJiang_Ori.txt`, `DummyItem.txt`, `DynamicRegion.txt`, `EffectDefine.txt`, `EnchanceSetAttr.txt`, `EquipAttaLevelup.txt`, `EquipChangerate.txt`, `EquipDecompose.txt`, `EquipDetail.txt`, `EquipDress.txt`, `EquipExtraAttr.txt`, `EquipLevelStd.txt`, `EquipMoodAction.txt`, `EquipPriLevelValue.txt`, `EquipPriMpWuqi.txt`, `EquipPriRateValue.txt`, `EquipSetAttr.txt`, `EquipUpstage.txt`, `EquipUpstageChongLou.txt`, `EquipUpstageMat.txt`, `ExcitPoint.txt`, `ExcitPoint.txt`, `ExteriorRideCamera.txt`, `Exterior_BG.txt`, `Exterior_BGTSitem.txt`, `Exterior_DressStyle.txt`, `Exterior_DressStyle_Achivement.txt`, `Exterior_ExchangeItem.txt`, `Exterior_Face.txt`, `Exterior_GemEffect.txt`, `Exterior_Hair.txt`, `Exterior_Head.txt`, `Exterior_HeadFrame.txt`, `Exterior_InfantHair.txt`, `Exterior_Item.txt`, `Exterior_PetPoss.txt`, `Exterior_Ride.txt`, `Exterior_TS.txt`, `Exterior_TuJing.txt`, `Exterior_Weapon.txt`, `Exterior_WeaponGroup.txt`, `FYPVEAchInfo.txt`, `FYPVEItemInfo.txt`, `FYPVETalentInfo.txt`, `FeiPinHuiShou.txt`, `FemaleFirstName.txt`, `FemaleLastName.txt`, `FengMingShop.txt`, `Fengyunlu.txt`, `FengyunluText.txt`, `FiveElementsExtend.txt`, `FiveElementsValue.txt`, `GQHYChouJiang.txt`, `GQHYChouJiang_CT.txt`, `GQHYChouJiang_KaJi_1.txt`, `GQHYChouJiang_QX.txt`, `GSName.txt`, `GSPic.txt`, `GameCamera.txt`, `GemCarve.txt`, `GemEffect_Cloth.txt`, `GemLevelup.txt`, `GemMelting.txt`, `GoodsProtect_Goods.txt`, `GoodsProtect_Pet.txt`, `GouWuCheItem.txt`, `GrowPoint.txt`, `Guanshanhaishop.txt`, `GuiShi_NPCShop.txt`, `GuiShi_NPCShopItem.txt`, `GuildShop.txt`, `GuildShop_KaJi_1.txt`, `GuildShop_QX.txt`, `HLSCMissionInfo.txt`, `HLSCProgressItemInfo.txt`, `HLSCProgressItemInfo_CT.txt`, `HLSCProgressItemInfo_QX.txt`, `HXYBase.txt`, `HXYEffect.txt`, `HXYExAttr.txt`, `HXYLevel.txt`, `HomePetExper.txt`, `HongBaoShop.txt`, `HongBaoWeekInfo.txt`, `HuiLiu2022Shop.txt`, `HuiLiu2022Shop_CT.txt`, `HuiLiu2022Shop_QX.txt`, `HuiLiuShop.txt`, `HuoYue_Shop.txt`, `HuoYue_Shop_KaJi_1.txt`, `HuoyueDaibiClean.txt`, `IDCollections.txt`, `IMDress.txt`, `IMLevelTime.txt`, `ImpactDirectly.txt`, `ImpactPreShow.txt`, `ImpactSEData_V1.txt`, `Infant.txt`, `InfantCard.txt`, `InfantDoubleAction.txt`, `InfantDressColorRate.txt`, `InfantDressConvert.txt`, `InfantEnhance.txt`, `InfantExpMisTable.txt`, `InfantHairGeo.txt`, `InfantHeroLevel.txt`, `InfantLevelUpTable.txt`, `InfantVisualPart.txt`, `Infantskillinfo.txt`, `Infantskillup.txt`, `ItemAptRate.txt`, `ItemCompound.txt`, `ItemEnhance.txt`, `ItemLocatorAction.txt`, `ItemOrnamentsVisual.txt`, `ItemRule.txt`, `ItemVisualChar_iv.txt`, `ItemdescQX.txt`, `JieBanShop.txt`, `JieBanShop_CT.txt`, `JieBanShop_QX.txt`, `KBuildingAttr.txt`, `KBuildingAttrEx.txt`, `KCityShopCommodity.txt`, `KFSAttrEx.txt`, `KFSAttrLevelUp.txt`, `KFSBase.txt`, `KFSCompoudEx.txt`, `KFSLevelupExp.txt`, `KFSSkillLevelup.txt`, `KFSSlot.txt`, `KMSDShop.txt`, `KaJiSvr.txt`, `KillMonsterTasKExp.txt`, `LUT_00gao.png`, `LUT_00gao.png`, `LUT_00gao.png`, `LUT_bianjing1.png`, `LUT_bianjing1.png`, `LUT_bianjing1.png`, `LUT_bianjing1.png`, `LUT_bianjing1.png`, `LUT_bianjing1.png`, `LUT_congren.png`, `LUT_congren.png`, `LUT_congren.png`, `LUT_congren.png`, `LUT_congren.png`, `LUT_congrenfb.png`, `LUT_congrenfb.png`, `LUT_congrenfb.png`, `LiWuDuiHuanShop.txt`, `LimitShop.txt`, `LinkAction.txt`, `LiuboEquipLevelup.txt`, `LiuboEquipStarup.txt`, `LogicSceneAttr.txt`, `LongWenAddAttr.txt`, `LongWenBase.txt`, `LongWenRateBase.txt`, `LvMaxMoney.txt`, `MCDefaultRes.txt`, `MaleFirstName.txt`, `MaleLastName.txt`, `MartialAttr.txt`, `MartialLevel.txt`, `McardInfo.txt`, `Mergeserver.txt`, `MiFaInfo.txt`, `MilitaryDetails.txt`, `MissionDictionary.txt`, `MissionEffect.txt`, `MissionItem_GroupHashTable.txt`, `MissionItem_HashTable.txt`, `MissionNPC_HashTable.txt`, `MissionPet_HashTable.txt`, `MissionRef.txt`, `Mission_Delivery.txt`, `Mission_EnterArea.txt`, `Mission_Husong.txt`, `Mission_KillMonster.txt`, `Mission_LootItem.txt`, `Mission_SceneCycle.txt`, `Model_Parameter.txt`, `MoneyRecycleItem.txt`, `MonsterAttrExTable.txt`, `MonsterLimitedTable.txt`, `MonsterPaoPao.txt`, `MonsterRef.txt`, `MovieAttr.txt`, `MsgBall.txt`, `MsgBallType.txt`, `MultiLine.txt`, `MultiLineEx.txt`, `NameBoardEx.txt`, `NameBoardExItem.txt`, `NameBoardExVisual.txt`, `NationalShop.txt`, `NationalShop_KaJi_1.txt`, `NewActivePoint.txt`, `NewLongZhengShiZai.txt`, `NewLongZhengShiZai_KaJi_1.txt`, `Newserverhm.txt`, `NiudanDuihuan.txt`, `NiudanReward.txt`, `NoPackingItems.txt`, `NobilityDetails.txt`, `NormalRankReward.txt`, `NormalRankingBase.txt`, `NotScalePetModel.txt`, `NpcAttachMission.txt`, `NpcTalk.txt`, `NpcVisible.txt`, `NumberingFashion.txt`, `OptionalGiftBox.txt`, `OtherRef.txt`, `PVPShop.txt`, `PetAttrJinJie.txt`, `PetAttrTable.txt`, `PetEquipBase.txt`, `PetEquipFuse.txt`, `PetEquipItemAptRate.txt`, `PetEquipItemEnhance.txt`, `PetEquipSetAttr.txt`, `PetEquipSuitUp.txt`, `PetHuanLing.txt`, `PetHuanLingItem.txt`, `PetHuanhuaTable.txt`, `PetLevelUpTable.txt`, `PetLianHua.txt`, `PetLingXing.txt`, `PetMaster.txt`, `PetMedicineHCCompound.txt`, `PetNeiDan_Shop.txt`, `PetPaoPaoIndex.txt`, `PetPaoPaoWord.txt`, `PetPossColourRate.txt`, `PetPossPosition.txt`, `PetPossPositionValue.txt`, `PetSkillBook.txt`, `PetSkillLevelup.txt`, `PetTitle.txt`, `PetTypeAttr.txt`, `PlayerQuicklyEnterHide.txt`, `PneumaInfo.txt`, `PneumaSet.txt`, `QiXi_Shop.txt`, `QianKunDai.txt`, `QingmingJackpot.txt`, `QingmingJackpot_CT.txt`, `QingmingJackpot_KaJi_1.txt`, `RLAttrEx.txt`, `RLBase.txt`, `RLStar.txt`, `RMBChatAction.txt`, `RMBChatFace.txt`, `RSInfo.txt`, `RSSkill.txt`, `RankingList.txt`, `RecipeKind.txt`, `RecycleItem.txt`, `RecycleItemClass.txt`, `RecycleItemType.txt`, `RedPointTreeTable.txt`, `RepairRate.txt`, `ReputationTable.txt`, `ResearchItem.txt`, `ResourceFilter.txt`, `RichmanChangeSuipianClient.txt`, `RichmanChangeSuipianClient_KaJi_1.txt`, `RichmanChangeSuipianClient_ori.txt`, `RichmanMap.txt`, `RichmanShop.txt`, `RichmanShop_KaJi_1.txt`, `RichmanShop_ori.txt`, `RideCollection.txt`, `RideCollectionEffect.txt`, `RideSeries.txt`, `RoguePT_Skill.txt`, `SJFHShop.txt`, `SJFHShop_KaJi_1.txt`, `SafeItemList.txt`, `SafeScore.txt`, `SafeScore_KaJi_1.txt`, `SceneAearDefine.txt`, `SceneAreaTransfer.txt`, `SceneFacility.txt`, `ScenePosDefine.txt`, `Scripttalk.txt`, `SecKillBase.txt`, `SecKillHuoDongBase.txt`, `ServerState.txt`, `ShenqiLeveUp.txt`, `ShideShop.txt`, `ShideShop_QX.txt`, `ShopBaodi.txt`, `ShopDuihuan.txt`, `ShopLibao.txt`, `ShopRandom.txt`, `ShopTable.txt`, `ShopTable_KaJi_1.txt`, `ShopVIP.txt`, `ShopVIP_KaJi_1.txt`, `ShouKaiKaItemTable.txt`, `SlotCost.txt`, `SnowItem.txt`, `SoundUI.txt`, `SpecialDressColor.txt`, `SpecialDressEffect.txt`, `SpecialEquipVisiblRule.txt`, `SpecialObjData.txt`, `SpecialPriority.txt`, `SpecialSceneName.txt`, `SpecialServerIDTable.txt`, `SpringFestivalBiddingBonus.txt`, `SpringFestivalBiddingBonus_KaJi_1.txt`, `StrFilter.txt`, `StrReplace.txt`, `StrTalkTemplateTable.txt`, `SummerZhanLingInfo.txt`, `SummerZhanLingInfo_KaJi_1.txt`, `SummonerAttr.txt`, `SuperWeapon9Res.txt`, `SuperWeapon9WG.txt`, `SuperWeaponDownItemBack.txt`, `SuperWeaponDownMaterial.txt`, `SuperWeaponJJ.txt`, `SuperWeaponQH.txt`, `SuperWeaponSkillActivation.txt`, `SuperWeaponSkillLevelUp.txt`, `SuperWeaponTL.txt`, `SuperWeaponUp.txt`, `SuperWeaponWG.txt`, `SystemColour.txt`, `T300Battlefield.txt`, `T300JZWLZDAward.txt`, `T300Line.txt`, `T300SceneIDInfo.txt`, `TAnonymousInfo.txt`, `TLCJPlayerExpLevel.txt`, `TLCJShop.txt`, `TLCJSkillTips.txt`, `TalentInfo.txt`, `TalentLayerLevel.txt`, `TaskCollections.txt`, `TeSeServer.txt`, `TeamBoardGoal.txt`, `TelCode.txt`, `ThanksJackpot.txt`, `ThanksJackpot_KaJi_1.txt`, `TianJiChengShop.txt`, `TianJiChengShop_KaJi_1.txt`, `TitleFlash.txt`, `ToushiSkill.txt`, `ToyItem.txt`, `TransportDefine.txt`, `Tujian.txt`, `UICommandIndex.txt`, `UnderArmour.txt`, `UnderArmourJewel.txt`, `UnderArmourJewelCompound.txt`, `UnderArmourJewelEffect.txt`, `UnderArmourJewelExtra.txt`, `UnderArmourLevel.txt`, `UnderArmourPlate.txt`, `UnderArmourRank.txt`, `UnderArmourStar.txt`, `VipFuncName.txt`, `VipInfo.txt`, `VipMotionBlend.txt`, `WR_BossRef.txt`, `WR_MainPage.txt`, `WeaponVisualLocator.txt`, `WeblinkTable.txt`, `WinterShop.txt`, `WuShenTanShop.txt`, `WuShenTanSvr.txt`, `XBWJHSHonourWall.txt`, `XFTQ_Shop.txt`, `XF_QuanMinBaXing.txt`, `XbwDuanweiTable_2018.txt`, `XbwHonourWall.txt`, `XbwTimeTable_2018.txt`, `XbwTimeTable_JiHouSai.txt`, `XiGuaShop.txt`, `XiGuaShop_CT.txt`, `XiGuaShop_KaJi_1.txt`, `XiaKeShop.txt`, `XiaKeShop_KaJi.txt`, `XinShouHeroesRoad.txt`, `XinShouZhanLing_Award.txt`, `XinShouZhanLing_Award_KaJi.txt`, `XinShouZhanLing_Award_QX.txt`, `XinShouZhanLing_Mission.txt`, `XinShouZhanLing_Mission_KaJi.txt`, `XinShouZhanLing_Mission_QX.txt`, `XingZhen_AttrPriority.txt`, `XingZhen_Chip.txt`, `XingZhen_Interests.txt`, `XingZhen_JiBan_Award.txt`, `XingZhen_Level.txt`, `XingZhen_NPCShop.txt`, `XingZhen_NPCShopItem.txt`, `XingZhen_SkillBook.txt`, `XingZhen_Skill_PingFen.txt`, `XingZhen_YingXiong.txt`, `XingZhen_YingXiong_Award.txt`, `XiuChangNotice.txt`, `XiuLianBook.txt`, `XiuLianDetail.txt`, `XiuLianMiJi.txt`, `XiuLianRate.txt`, `XueWeiBook.txt`, `XunzhangInfo.txt`, `YueLiAttr.txt`, `ZMPTEnter.txt`, `ZM_Shop.txt`, `ZM_dizilevel.txt`, `ZdZdAutoPickType.txt`, `ZdZdPotion.txt`, `ZdZdScene.txt`, `ZdZdSkill.txt`, `ZhanLingInfo.txt`, `ZhanLingInfo_CT.txt`, `ZhanLingInfo_KaJi_1.txt`, `ZhanLingInfo_QX.txt`, `ZhaoHui.txt`, `ZhenFaDemand.txt`, `ZhenShouDanPreView.txt`, `ZhengZhao.txt`, `ZhiZunEquipRate.txt`, `ZhouNianChouJiang.txt`, `ZhouNianChouJiang_KaJi_1.txt`, `ZongmenEquip_Ext.txt`, `ZongmenTalent.txt`, `ZongmenTitle.txt`, `anniversary7hit.txt`, `baoshipingfen.txt`, `bieyemengchongReputation.txt`, `bieyemengchongcolor.txt`, `buffbuchang.txt`, `diaowenpingfen.txt`, `emei.track`, `fengmingBiddingItem.txt`, `fmhostiletime.txt`, `gaibang.track`, `gradeflash.txt`, `gusu.track`, `installgemprice.txt`, `jianzhitianhuangitem.txt`, `jierihuodong.txt`, `jierihuodong_DZD.txt`, `jierihuodong_KaJi_1.txt`, `jierihuodong_QX.txt`, `md5.txt`, `md5l.txt`, `mingjiao.track`, `ngmain.lua`, `rankflash.txt`, `shaolin.track`, `tangmen.track`, `tangmen.track`, `tangmen.track`, `tangmen.track`, `tangmen.track`, `tianlong.track`, `tianshan.track`, `wudang.track`, `xiaoyao.track`, `xingxiu.track`, `zhenyuanpingfen.txt`
- Chỉ nhắc tên trong mã hoặc chú thích, không có công cụ xuất (13): `CangPin.txt`, `Condition.txt`, `MissionTrack.txt`, `PetNeiDan.txt`, `Platform.txt`, `SceneAttr.txt`, `ScenePosDefineEx.txt`, `Script.dat`, `SkillDeplete.txt`, `SpecialSceneCamera.txt`, `Toy.txt`, `XingZhen.txt`, `XingZhen_Skill.txt`
- Cảnh `.Scene` chưa gom vào `dev/client/assets/Scene` (0): 
- Không so được (61, mẫu định dạng hay đường dẫn chung): `%04d_%02d_%02d_%02d_%02d_%02d.txt`, `%04d_%02d_%02d_%02d_%02d_%02d.txt`, `%s.layout.xml`, `%s\%s.lua`, `%s\QKH.cfg`, `%s_%d.%d_%d.%d.csv`, `%s_%d.%d_%d.%d.csv`, `%s_%d.%d_%d.%d.csv`, `../Bin/ClientType.cfg`, `../Bin/ClientType.cfg`, `../Bin/ClientType.cfg`, `../Bin/ClientType.cfg`, `../Bin/ClientType.cfg`, `../Bin/ClientType.cfg`, `../Bin/ClientType.cfg`, `../Bin/ClientType.cfg`, `../Bin/ClientType.cfg`, `../Bin/System.cfg`, `../Data/ndata.dat`, `../Launch.ini`, `../Launch.ini`, `../Launch.ini`, `../Launch.ini`, `..\Accounts\%s\%s.cfg`, `..\Accounts\%s\%s.cfg`, `..\Accounts\%s\%s.cfg`, `..\Accounts\%s\Acce_Custom.ini`, `..\Accounts\System.cfg`, `..\Accounts\System.cfg`, `..\Bin\System.cfg`, `..\Bin\System.cfg`, `..\Bin\System.cfg`, `..\Bin\System.cfg`, `..\Patch\RemoteAddr.txt`, `..\Patch\RemoteAddr.txt`, `..\Patch\loginserver.txt`, `..\Patch\loginserver.txt`, `..\Patch\loginserver.txt`, `..\Patch\loginserver.txt`, `..\Patch\loginserver.txt`, `..\Patch\loginserver.txt`, `..\versionlist.dat`, `.//StreamRecord.dat`, `.//StreamRecord_%d_%d_%d.dat`, `./ClientType.cfg`, `./ClientType.cfg`, `./ClientType.cfg`, `./System.cfg`, `./System.cfg`, `.Scene`, `.Scene`, `.\PlayerOther.bin`, `.\PlayerOther.bin`, `Cast/Cast1.mesh`, `Cast/pilon.mesh`, `\*.bin`, `\*.bin`, `\ClientType.cfg`, `interface\click_fail.wav`, `interface\quest_accet.wav`, `interface\quest_complete.wav`

### 3.3 Lớp chưa có (312)

- (77) cấu trúc gói bang hội/Đại Phú Ông/lãnh địa chưa có: `DFWGROUP_CGW_ASKDETAIL`, `DFWGROUP_GW_CREATE`, `DFWGROUP_GW_DISMISS`, `DFWGROUP_GW_JOIN`, `DFWGROUP_GW_KICK`, `DFWGROUP_GW_LEAVE`, `DFWGROUP_GW_LOCK`, `DFWGROUP_GW_SYNCTHROW`, `DFWGROUP_GW_TRYJOIN`, `DFWGROUP_GW_TRYRECIVE`, `GUILD_CGW_ADJUSTAUTH`, `GUILD_CGW_APPOINT`, `GUILD_CGW_ASKCAMPAINERLIST`, `GUILD_CGW_ASKINFO`, `GUILD_CGW_ASKKVKBOSSPARAM`, `GUILD_CGW_ASKLIST`, `GUILD_CGW_ASKLISTWITHCITY`, `GUILD_CGW_ASKNAMELIST`, `GUILD_CGW_ASK_GIFT_LOG`, `GUILD_CGW_BACK_CITY`, `GUILD_CGW_CHANG_DESC`, `GUILD_CGW_CLEAR_JOIN_INFO`, `GUILD_CGW_COM_MISS_COMPLETE`, `GUILD_CGW_CREATE`, `GUILD_CGW_DEMISE`, `GUILD_CGW_DEPOSIT`, `GUILD_CGW_EXPEL`, `GUILD_CGW_FIRSTMAN`, `GUILD_CGW_GET_POSITION_NAME`, `GUILD_CGW_JOIN`, `GUILD_CGW_LEAVE`, `GUILD_CGW_MODIFY_LEAVE_WORD`, `GUILD_CGW_PROMOTE_CHIEF`, `GUILD_CGW_RECRUIT`, `GUILD_CGW_REFLASHEP`, `GUILD_CGW_REQUEST_POSITION_NAME`, `GUILD_CGW_SETCOMMANDER`, `GUILD_CGW_TIANDAO`, `GUILD_CGW_TRY_ELECTION`, `GUILD_CGW_VOTECAMPAIGN`, `GUILD_CGW_WITHDRAW`, `GUILD_CGW_ZHIZUNEQUIP`, `GUILD_GW_ASKFULIPOINTINFO`, `GUILD_GW_OPERFULIPOINT`, `GUILD_POSITION_NAME_LIST`, `GUILD_WGC_APPOINT_INFO`, `GUILD_WGC_FIRSTMAN`, `GUILD_WGC_FULIPOINT_INFO`, `GUILD_WGC_GUILDWITHCITY_LIST`, `GUILD_WGC_GUILD_INFO`, `GUILD_WGC_LIST`, `GUILD_WGC_LISTCAMPAINER`, `GUILD_WGC_MEMBER_LIST`, `GUILD_WGC_NAMELIST`, `GUILD_WGC_REFLASHEP`, `GUILD_WGC_RETELECTIONINFO`, `GUILD_WGC_RETKVKBOSSPARAM`, `GUILD_WGC_RET_OPER_FULIPOINT`, `GUILD_WGC_SELF_GUILD_INFO`, `GUILD_WGC_TIANDAO`, `GUILD_WGC_ZHIZUNEQUIP`, `GUILD_WG_ALLIANCEINFO`, `GUILD_WG_UPDATEEQUIPSCORE`, `GangT_CGW_AskFight`, `GangT_CGW_AskFinalList`, `GangT_CGW_AskJoin`, `GangT_CGW_AskList`, `GangT_CGW_SendFightResult`, `GangT_CGW_SendMail`, `GangT_WGC_RetAskFight`, `GangT_WGC_RetAskFinalList`, `GangT_WGC_RetJoin`, `GangT_WGC_RetList`, `_DAFUWENGGROUP_GW_PACKET`, `_GANGTERRITORY_INIT`, `_GUILD_CGW_PACKET`, `_GUILD_WGC_PACKET`
- (42) loại action này chưa có (chỉ có skill, life, xinfa, formation, pet): `CActionItem_CangPin`, `CActionItem_CangPinChip`, `CActionItem_CangPin_NextLevel`, `CActionItem_CangPin_QualReset`, `CActionItem_CangPin_QualUp`, `CActionItem_ChatMood`, `CActionItem_ChijiEquip`, `CActionItem_ChijiItem`, `CActionItem_ChijiSkill`, `CActionItem_Combo_Book`, `CActionItem_CoolDownItem`, `CActionItem_Double_ChatMood`, `CActionItem_FYPVEItem`, `CActionItem_FYPVETalent`, `CActionItem_Fashion`, `CActionItem_Frame`, `CActionItem_Item`, `CActionItem_KFSSkill`, `CActionItem_MailItem`, `CActionItem_OtherComboSkill`, `CActionItem_Other_CangPin`, `CActionItem_Other_SkillCard`, `CActionItem_Other_XingJuan`, `CActionItem_PND`, `CActionItem_PetFight`, `CActionItem_PetPossession`, `CActionItem_PetRelax`, `CActionItem_PetRestore`, `CActionItem_PetSkill`, `CActionItem_Pneuma`, `CActionItem_Ride`, `CActionItem_SectInfo`, `CActionItem_SkillCard`, `CActionItem_SuperWeaponDIYSkill`, `CActionItem_Toy`, `CActionItem_Weapon`, `CActionItem_Weapon_Group`, `CActionItem_XingJuan`, `CActionItem_XingJuanChip`, `CActionItem_Xiulian_Book`, `CActionItem_Xiulian_Miji`, `CActionItem_XueWei`
- (37) con trỏ lệnh của vật phẩm/bán/sửa/giám định chưa có (chưa có vật phẩm): `CActionItem_MouseCmd_AddCommanderFlag`, `CActionItem_MouseCmd_AddFriend`, `CActionItem_MouseCmd_Archer`, `CActionItem_MouseCmd_Asunder`, `CActionItem_MouseCmd_AttachModel`, `CActionItem_MouseCmd_BJJJH_2022`, `CActionItem_MouseCmd_BuyMult`, `CActionItem_MouseCmd_CallOutMengChong`, `CActionItem_MouseCmd_CatchPet`, `CActionItem_MouseCmd_DFWDismiss`, `CActionItem_MouseCmd_Exchange`, `CActionItem_MouseCmd_ExteriorFitting`, `CActionItem_MouseCmd_Furniture`, `CActionItem_MouseCmd_GiveMessage`, `CActionItem_MouseCmd_HCFurniture`, `CActionItem_MouseCmd_Identify`, `CActionItem_MouseCmd_LuckyLineResolve`, `CActionItem_MouseCmd_Mifa`, `CActionItem_MouseCmd_PND_HQ`, `CActionItem_MouseCmd_QiYuanGiveWine`, `CActionItem_MouseCmd_QianKunPot`, `CActionItem_MouseCmd_QianKunPotDel`, `CActionItem_MouseCmd_RecycleFurniture`, `CActionItem_MouseCmd_RemoveFurniture`, `CActionItem_MouseCmd_RemoveMengChong`, `CActionItem_MouseCmd_Repair`, `CActionItem_MouseCmd_Sale`, `CActionItem_MouseCmd_SaleToRecShop`, `CActionItem_MouseCmd_ShadowCursorCommand`, `CActionItem_MouseCmd_ShareLuckyPoint`, `CActionItem_MouseCmd_ShopDresser`, `CActionItem_MouseCmd_ShopFitting`, `CActionItem_MouseCmd_ShopGift`, `CActionItem_MouseCmd_ShowFurniture`, `CActionItem_MouseCmd_ShowFurniture_InBank`, `CActionItem_MouseCmd_ShowMengChong`, `CActionItem_MouseCmd_ZHFurniture`
- (29) phần tử danh sách giao diện/quan hệ chưa có (chưa có bạn bè, đội, thú, shop, thành tích...): `AchievementElement`, `BlackList`, `BossElement`, `BuyFromYBShopElement`, `CElement`, `ChannelElement`, `ChildFashionDepotElement`, `EnemyList`, `ExteriorRideElement`, `ExteriorShareHyperLinkElement`, `ExteriorWeaponElement`, `FashionDepotElement`, `FingerList`, `FoeList`, `FriendList`, `GongChengZhanBaoElement`, `HttpElement`, `HyperLinkElement`, `PetElement`, `PetNeiDanElement`, `PlayerElement`, `PneumaElement`, `RelationList`, `SectElement`, `TeamZhengZhaoElement`, `TempRelationList`, `TrustFriendList`, `XingZhenElement`, `YuanBaoShopElement`
- (21) bộ lọc chọn mục tiêu (quái/NPC/người chơi gần nhất) cho AI/kỹ năng chưa có: `CalcTargetNum`, `FindAMonster`, `FindAMonsterInRange`, `FindAMonsterOccupateMe`, `FindAliveNPC`, `FindAlivePlayer`, `FindFriendAD_DetailInfo`, `FindFriendAD_VoteInfo_Packets`, `FindMonsterInRange_LessHp`, `FindMonsterInRange_MoreHp`, `FindMonsterInRange_NearestLessHp`, `FindNPCInRange`, `FindNearestMonster`, `FindNearestMonsterInRange`, `FindPetInRange`, `FindPlayerInRange`, `FindPlayerInRangeWithLogicType`, `FindResourceInRange`, `FindTheClosestNPC`, `FindTheClosestPlayer`, `ObjectFilter`
- (16) chưa có hệ vật phẩm (hành trang, trang bị thật, chuyển vật phẩm); chỉ có bảng và vũ khí cầm tay thử: `CItem`, `CItemSystem`, `CItem_Common`, `CItem_Dummy`, `CItem_Equip`, `CItem_Gem`, `CItem_IMDress`, `CItem_PetEquip`, `CItem_Pneuma`, `CTransferItemSystem`, `Citem_CampaignTable`, `Citem_InfantCard`, `ItemElement`, `TableItemElement`, `tItem`, `tTransferItemSystem::Element`
- (16) chưa có NPC, quái, người chơi khác, xe, đạn, hiệu ứng bề mặt, vòng chọn: `CObject_AttachBieYeItem`, `CObject_BieYeBuilding`, `CObject_BieYeItem`, `CObject_BlueCircle`, `CObject_Bullet`, `CObject_Bus`, `CObject_FakeSWItem`, `CObject_PlayerInfant`, `CObject_PlayerNPC`, `CObject_PlayerOther`, `CObject_PlayerSummoner`, `CObject_ProjTex`, `CObject_ProjTex_AuraDure`, `CObject_ProjTex_MouseTarget`, `CObject_Special`, `CObject_Surface`
- (14) lệnh đối tượng do máy chủ/AI ra (di chuyển, đánh, dùng kỹ năng); client chỉ có WalkOrder/Strike cục bộ: `CObjectCommand`, `CObjectCommand_Ability`, `CObjectCommand_Action`, `CObjectCommand_BeHitOut`, `CObjectCommand_Charge`, `CObjectCommand_Fly`, `CObjectCommand_Logic`, `CObjectCommand_MagicChannel`, `CObjectCommand_MagicCharge`, `CObjectCommand_MagicSend`, `CObjectCommand_Move`, `CObjectCommand_StopAction`, `CObjectCommand_StopLogic`, `CObjectCommand_StopMove`
- (13) kiểm tra phó bản chưa có: `ZZFubenBingshengCheck`, `ZZFubenDapiaoCheck`, `ZZFubenGSHCheck`, `ZZFubenHuanjingCheck`, `ZZFubenQijuCheck`, `ZZFubenSanhuanCheck`, `ZZFubenShaoshishanCheck`, `ZZFubenShuilaoCheck`, `ZZFubenSijueCheck`, `ZZFubenXubaoCheck`, `ZZFubenYanziwuCheck`, `ZZFubenlanghuanJDCheck`, `ZZFubenlanghuanKNCheck`
- (11) hệ quản lý tính năng riêng của bản gốc chưa có: `ActivityNotePetTalkTmp`, `AnonymousCommonManager`, `CAbilityTableManager`, `CActivePosManager`, `MutiLineTableManager`, `PaoPaoPetTalkImp`, `QianKunPotManager`, `SysBroadCastPetTalkImp`, `T300JZWLZDAwardManager`, `T300SceneIDManager`, `TAnomymousInfoManager`
- (9) quản lý hoạt động/PVP/phim của bản gốc chưa có: `ClientFYPVEManager`, `ClientMovieBridge`, `ClientQXPVPManager`, `ClientTLCJManager`, `ClientXBWJHSManager`, `ClientXBWManager`, `ClientXRZPVPManager`, `ClientZBSManager`, `tMovieDataBridge`
- (6) chưa có đối tượng/impact do máy chủ gửi: `SImpactEffect`, `SObjectInit`, `SObject_BulletInit`, `SObject_BusInit`, `SObject_EffectInit`, `SObject_SpecialInit`
- (4) không có bộ quản lý đối tượng trong cảnh (Stage thiếu Actor, kOtherActor còn là stub): `CObject`, `CObjectLoadQueue`, `CObjectManager`, `CServerObjectManager`
- (4) chưa có vật thể tương tác (bục, tài nguyên): `CTripperObject_ItemBox`, `CTripperObject_Platform`, `CTripperObject_Resource`, `CTripperObject_Transport`
- (4) ExcitPoint (điểm kích hoạt) chưa có: `EPRule00`, `EPRule00Factory`, `EPRule01`, `EPRule01Factory`
- (3) phần tử/giao diện của tính năng chưa có: `GongChengZhanBaoElement_New`, `Player_AtClient`, `SubActionList<3,115>`
- (2) BowlRobbing chưa có: `CBRLoop_Config<CBRConfig_Farm>`, `CBRLoop_Farm`
- (2) không có hệ biến cấu hình/phiên bản chạy như bản gốc (client dùng options CLI): `CVariableSystem`, `CVersionSystem`
- (1) luồng xử lý chat nền; chưa có chat: `BkThreadChatProcess`
- (1) chưa có thú cưng: `CPetPossPositionMgr`

### 3.4 Tệp nguồn chưa có (207)

- (86) client chưa mở socket, chưa có handler gói: `Network\PacketHandler\CGCIPRegionHandler.cpp (1 hàm)`, `Network\PacketHandler\GCAbilityExpHandler.cpp (1 hàm)`, `Network\PacketHandler\GCAbilityLevelHandler.cpp (1 hàm)`, `Network\PacketHandler\GCAbilitySuccHandler.cpp (1 hàm)`, `Network\PacketHandler\GCAbilityZhuanjingHandler.cpp (1 hàm)`, `Network\PacketHandler\GCAskDoDoubleChatActionHandler.cpp (1 hàm)`, `Network\PacketHandler\GCBieYeMengChongListHandler.cpp (1 hàm)`, `Network\PacketHandler\GCBieYeQiYuNpcPosHandler.cpp (1 hàm)`, `Network\PacketHandler\GCChallengeHandler.cpp (1 hàm)`, `Network\PacketHandler\GCCharAllTitlesHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDRideOperateHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDetailAttrib_PetHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDetailBWShopInfoHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDetailExpHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDetailMilitaryShopInfoHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDetailNobilityShopInfoHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDetailShiDeShopInfoHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDetailXiulianListHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDiGongPosHandler.cpp (1 hàm)`, `Network\PacketHandler\GCDrideStartStopHandler.cpp (1 hàm)`, `Network\PacketHandler\GCEnterSceneHandler.cpp (1 hàm)`, `Network\PacketHandler\GCExchangeEstablishIHandler.cpp (1 hàm)`, `Network\PacketHandler\GCExchangeSuccessIIIHandler.cpp (1 hàm)`, `Network\PacketHandler\GCExchangeSynchIIHandler.cpp (1 hàm)`, `Network\PacketHandler\GCFYPVESyncMapDataHandler.cpp (1 hàm)`, `Network\PacketHandler\GCFingerHandler.cpp (1 hàm)`, `Network\PacketHandler\GCGameCommondHandler.cpp (1 hàm)`, `Network\PacketHandler\GCGuiShiNpcShopInfoHandle.cpp (1 hàm)`, `Network\PacketHandler\GCGuildHandler.cpp (1 hàm)`, `Network\PacketHandler\GCGuildReturnHandler.cpp (1 hàm)`, `Network\PacketHandler\GCIASkillHandler.cpp (1 hàm)`, `Network\PacketHandler\GCInnerAlchemyHandler.cpp (1 hàm)`, `Network\PacketHandler\GCItemListHandler.cpp (0 hàm)`, `Network\PacketHandler\GCItemSynchHandler.cpp (1 hàm)`, `Network\PacketHandler\GCLongZhouListHandler.cpp (1 hàm)`, `Network\PacketHandler\GCManipulateMengChongRetHandler.cpp (1 hàm)`, `Network\PacketHandler\GCMartialExpHandler.cpp (1 hàm)`, `Network\PacketHandler\GCMovieOprHandler.cpp (1 hàm)`, `Network\PacketHandler\GCMsgBallHandler.cpp (1 hàm)`, `Network\PacketHandler\GCNewSpecialHandler.cpp (1 hàm)`, `Network\PacketHandler\GCNotifyChangeSceneHandler.cpp (1 hàm)`, `Network\PacketHandler\GCNotifyGoodBadHandler.cpp (1 hàm)`, `Network\PacketHandler\GCNotifyQXPVPPosHandler.cpp (1 hàm)`, `Network\PacketHandler\GCOpenWorldReferenceHandler.cpp (1 hàm)`, `Network\PacketHandler\GCOperateResultHandler.cpp (1 hàm)`, `Network\PacketHandler\GCPetBankListUPDataHandler.cpp (1 hàm)`, `Network\PacketHandler\GCPickResultHandler.cpp (1 hàm)`, `Network\PacketHandler\GCRaidErrorHandler.cpp (1 hàm)`, `Network\PacketHandler\GCRaidListHandler.cpp (1 hàm)`, `Network\PacketHandler\GCRaidResultHandler.cpp (1 hàm)`, `Network\PacketHandler\GCRelationHandler.cpp (2 hàm)`, `Network\PacketHandler\GCRemoveGemResultHandler.cpp (1 hàm)`, `Network\PacketHandler\GCRetAuctionNewRequestHandler.cpp (1 hàm)`, `Network\PacketHandler\GCRetMailNewHandler.cpp (1 hàm)`, `Network\PacketHandler\GCReturnItemListHandler.cpp (0 hàm)`, `Network\PacketHandler\GCReturnTeamFollowHandler.cpp (1 hàm)`, `Network\PacketHandler\GCShopBuyHandler.cpp (1 hàm)`, `Network\PacketHandler\GCShopRepairHandler.cpp (1 hàm)`, `Network\PacketHandler\GCShopSellHandler.cpp (1 hàm)`, `Network\PacketHandler\GCShopSoldListHandler.cpp (1 hàm)`, `Network\PacketHandler\GCShopUpdateMerchandiseListHandler.cpp (1 hàm)`, `Network\PacketHandler\GCShowPVPCARTapsHandler.cpp (1 hàm)`, `Network\PacketHandler\GCShowShengXiaoTapsHandler.cpp (1 hàm)`, `Network\PacketHandler\GCStallBuyHandler.cpp (1 hàm)`, `Network\PacketHandler\GCStartCrashUploadHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTJCPVPMonsterInfoHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTLCJSyncMapDataHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTWorldBossMonsterInfoHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTalentSkillHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTargetListAndHitFlagsHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTeamAskApplyHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTeamAskInviteHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTeamErrorHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTeamOptionChangedHandler.cpp (1 hàm)`, `Network\PacketHandler\GCTransBWaitInfoHandler.cpp (1 hàm)`, `Network\PacketHandler\GCWuShenTanHuaChePosHandler.cpp (1 hàm)`, `Network\PacketHandler\GCXFXYCSDPosHandler.cpp (1 hàm)`, `Network\PacketHandler\GCXingZhenSkillHandler.cpp (1 hàm)`, `Network\PacketHandler\GCZhouNianHuaCheListHandler.cpp (1 hàm)`, `Network\PacketHandler\GCZiweixingluoPosHandler.cpp (1 hàm)`, `Network\PacketHandler\LCRetLoginHandler.cpp (1 hàm)`, `Network\PacketHandler\WGCResultHandler.cpp (1 hàm)`, `Network\PacketHandler\WGCRetApplyZhengZhaoHandler.cpp (1 hàm)`, `Network\PacketHandler\WGCRetApplyZhengZhaoTeamHandler.cpp (1 hàm)`, `Network\PacketHandler\WGCRetGuildShopHandler.cpp (1 hàm)`, `Network\PacketHandler\WGCZhanQiDataHandler.cpp (1 hàm)`
- (60) cửa sổ/script của tính năng này chưa có: `Interface\GMGameInterface_Script_Auction.cpp (1 hàm)`, `Interface\GMGameInterface_Script_BieYe.cpp (24 hàm)`, `Interface\GMGameInterface_Script_BieYeFurniture.cpp (10 hàm)`, `Interface\GMGameInterface_Script_BieYeMengChong.cpp (18 hàm)`, `Interface\GMGameInterface_Script_Corps_2016.cpp (1 hàm)`, `Interface\GMGameInterface_Script_DaFuWeng.cpp (1 hàm)`, `Interface\GMGameInterface_Script_DigongShop.cpp (2 hàm)`, `Interface\GMGameInterface_Script_DressStyle.cpp (14 hàm)`, `Interface\GMGameInterface_Script_ExcitPoint.cpp (5 hàm)`, `Interface\GMGameInterface_Script_FYPVE.cpp (8 hàm)`, `Interface\GMGameInterface_Script_FashionDepot.cpp (2 hàm)`, `Interface\GMGameInterface_Script_FriendSearch.cpp (1 hàm)`, `Interface\GMGameInterface_Script_GuiShi.cpp (3 hàm)`, `Interface\GMGameInterface_Script_NpcShop.cpp (0 hàm)`, `Interface\GMGameInterface_Script_Ornaments.cpp (14 hàm)`, `Interface\GMGameInterface_Script_Pet.cpp (46 hàm)`, `Interface\GMGameInterface_Script_PetEquipSuitDepart.cpp (1 hàm)`, `Interface\GMGameInterface_Script_PetEquipSuitUp.cpp (3 hàm)`, `Interface\GMGameInterface_Script_Raid.cpp (3 hàm)`, `Interface\GMGameInterface_Script_SJTX.cpp (1 hàm)`, `Interface\GMGameInterface_Script_ShenqiUpgrade.cpp (4 hàm)`, `Interface\GMGameInterface_Script_Songliao.cpp (2 hàm)`, `Interface\GMGameInterface_Script_StallBuy.cpp (2 hàm)`, `Interface\GMGameInterface_Script_StallSale.cpp (2 hàm)`, `Interface\GMGameInterface_Script_TLCJ.cpp (5 hàm)`, `Interface\GMGameInterface_Script_TServer.cpp (1 hàm)`, `Interface\GMGameInterface_Script_TargetPet.cpp (4 hàm)`, `Interface\GMGameInterface_Script_WenDing.cpp (3 hàm)`, `Interface\GMGameInterface_Script_XBWJHS.cpp (2 hàm)`, `Interface\GMGameInterface_Script_XBW_Team.cpp (1 hàm)`, `Interface\GMGameInterface_Script_Xunzhang.cpp (13 hàm)`, `Interface\GMGameInterface_Script_YiGui.cpp (2 hàm)`, `Interface\GMInterface_Script_Achievement.cpp (19 hàm)`, `Interface\GMInterface_Script_BWDH.cpp (1 hàm)`, `Interface\GMInterface_Script_BWDH2018.cpp (15 hàm)`, `Interface\GMInterface_Script_BattleAssist.cpp (1 hàm)`, `Interface\GMInterface_Script_BieYePetCreateAndColor.cpp (9 hàm)`, `Interface\GMInterface_Script_BudgetPlanGem.cpp (2 hàm)`, `Interface\GMInterface_Script_DecoWeaponUI.cpp (6 hàm)`, `Interface\GMInterface_Script_DoubleGem.cpp (4 hàm)`, `Interface\GMInterface_Script_DressEnchasing.cpp (3 hàm)`, `Interface\GMInterface_Script_DressGem.cpp (5 hàm)`, `Interface\GMInterface_Script_DressReplaceColor.cpp (16 hàm)`, `Interface\GMInterface_Script_Exterior.cpp (52 hàm)`, `Interface\GMInterface_Script_FactionActionUI.cpp (2 hàm)`, `Interface\GMInterface_Script_GemCarve.cpp (1 hàm)`, `Interface\GMInterface_Script_GemMelting.cpp (1 hàm)`, `Interface\GMInterface_Script_Guild.cpp (2 hàm)`, `Interface\GMInterface_Script_GuildCity.cpp (19 hàm)`, `Interface\GMInterface_Script_GuildLeague.cpp (1 hàm)`, `Interface\GMInterface_Script_Infant.cpp (57 hàm)`, `Interface\GMInterface_Script_KBuildingGroup.cpp (2 hàm)`, `Interface\GMInterface_Script_LuHeXieXiang.cpp (2 hàm)`, `Interface\GMInterface_Script_Movie.cpp (1 hàm)`, `Interface\GMInterface_Script_PetInviteFriend.cpp (2 hàm)`, `Interface\GMInterface_Script_PlayerShop.cpp (4 hàm)`, `Interface\GMInterface_Script_Pneuma.cpp (4 hàm)`, `Interface\GMInterface_Script_WG_Achievement.cpp (9 hàm)`, `Interface\GMInterface_Script_WuLinZhiDian.cpp (4 hàm)`, `Interface\GMInterface_Script_ZhanTuan.cpp (4 hàm)`
- (17) loại action này chưa có: `Action\GMActionSystem_CangPin.cpp (6 hàm)`, `Action\GMActionSystem_ChatMood.cpp (1 hàm)`, `Action\GMActionSystem_ChijiItem.cpp (1 hàm)`, `Action\GMActionSystem_Combo_Book.cpp (3 hàm)`, `Action\GMActionSystem_Double_ChatMood.cpp (1 hàm)`, `Action\GMActionSystem_Exterior.cpp (2 hàm)`, `Action\GMActionSystem_FYPVEItem.cpp (3 hàm)`, `Action\GMActionSystem_Item.cpp (5 hàm)`, `Action\GMActionSystem_KFSSkill.cpp (2 hàm)`, `Action\GMActionSystem_OtherComboSkilll.cpp (2 hàm)`, `Action\GMActionSystem_PND.cpp (6 hàm)`, `Action\GMActionSystem_Pneuma.cpp (1 hàm)`, `Action\GMActionSystem_SectInfo.cpp (2 hàm)`, `Action\GMActionSystem_SuperWeaponDIYSkill.cpp (2 hàm)`, `Action\GMActionSystem_Xiulian_Book.cpp (1 hàm)`, `Action\GMActionSystem_Xiulian_Miji.cpp (1 hàm)`, `Action\GMActionSystem_XueWei.cpp (5 hàm)`
- (13) đối tượng này (NPC, người chơi khác, xe, đạn, vòng chọn, quản lý đối tượng) chưa có: `Object\Bus\Obj_Bus.cpp (3 hàm)`, `Object\Character\Obj_PlayerInfant.cpp (5 hàm)`, `Object\Character\Obj_PlayerNPC.cpp (21 hàm)`, `Object\Character\Obj_PlayerOther.cpp (23 hàm)`, `Object\Character\Obj_PlayerSummoner.cpp (6 hàm)`, `Object\Obj_BlueCircle.cpp (1 hàm)`, `Object\Object.cpp (1 hàm)`, `Object\ObjectManager.cpp (11 hàm)`, `Object\PetPossPositionMgr.cpp (1 hàm)`, `Object\Surface\Obj_Bullet.cpp (1 hàm)`, `Object\Surface\Obj_Special.cpp (1 hàm)`, `Object\TripperObj\GMTripperObj_Platform.cpp (1 hàm)`, `Object\TripperObj\GMTripperObj_Resource.cpp (3 hàm)`
- (10) hệ vật phẩm chưa có: `Item\GMItem.cpp (14 hàm)`, `Item\GMItemSystem.cpp (1 hàm)`, `Item\GMItem_Campaign.cpp (1 hàm)`, `Item\GMItem_Common.cpp (8 hàm)`, `Item\GMItem_Dummy.cpp (1 hàm)`, `Item\GMItem_IMDress.cpp (2 hàm)`, `Item\GMItem_InfantCard.cpp (4 hàm)`, `Item\GMItem_PetEquip.cpp (19 hàm)`, `Item\GMItem_Pneuma.cpp (4 hàm)`, `TransferItem\GMTransferItemSystem.cpp (18 hàm)`
- (9) cấu trúc dữ liệu này chưa có: `DataPool\GMDP_Struct_Gem_Change.cpp (1 hàm)`, `DataPool\GMDP_Struct_IMDress.cpp (7 hàm)`, `DataPool\GMDP_Struct_Infant.cpp (1 hàm)`, `DataPool\GMDP_Struct_MsgBallCore.cpp (2 hàm)`, `DataPool\GMDP_Struct_Pet.cpp (6 hàm)`, `DataPool\GMDP_Struct_QianKunPot.cpp (1 hàm)`, `DataPool\GMDP_Struct_Relation.cpp (2 hàm)`, `DataPool\GMDataPool_PetBank.cpp (2 hàm)`, `DataPool\ZZFubenCheck.cpp (1 hàm)`
- (4) chưa có: `ExcitPoint\EPRule01.cpp (1 hàm)`, `ExcitPoint\ExcitPointMgr.cpp (3 hàm)`, `ExtExport.cpp (1 hàm)`, `KaJi\KaJi_Client_C.cpp (4 hàm)`
- (2) BowlRobbing chưa có: `BowlRobbing\brfarm.cpp (4 hàm)`, `BowlRobbing\brsystem.cpp (4 hàm)`
- (2) chat và tooltip chưa có: `Interface\GMInterface_Script_Talk.cpp (29 hàm)`, `Interface\GMInterface_Script_Tooltip.cpp (58 hàm)`
- (2) vùng (zone) và tham chiếu thế giới chưa có: `WorldReference\WorldReference.cpp (11 hàm)`, `World\Zone.cpp (2 hàm)`
- (1) chưa có bộ lọc tài nguyên: `GMResourceFilter.cpp (1 hàm)`
- (1) AI chưa có: `Object\Character\Ai\GMAI_Base.cpp (1 hàm)`

### 3.5 Hàm script Lua chưa có (5913 trên 6055)

Bản gốc đăng ký các hàm script này cho giao diện Lua (script chạy trong CEGUI). Dự án không nhúng Lua: script được dịch sang C++ ở `ui/panel` (28 bảng). Bảng dưới là số hàm theo bảng/đối tượng Lua; từng hàm có hàng riêng trong `lua-api.tsv` (kèm địa chỉ cài đặt, nhãn lỗi `LUA:`, tệp nguồn) và từng bảng trong `lua-bang.tsv`.

| Bảng Lua | Biến toàn cục | Hàm | ĐÃ PORT | CÓ TÊN | CHÚ THÍCH | CHỈ TRỌNG TÀI | CHƯA CÓ |
|---|---|---|---|---|---|---|---|
| `DataPoolMetaTable` | DataPool | 1207 | 0 | 0 | 8 | 6 | 1193 |
| `(globals)` |  | 1025 | 3 | 5 | 22 | 9 | 986 |
| `PetTable` | Pet | 332 | 1 | 1 | 3 | 4 | 323 |
| `PlayerMySelfMetaTable` | Player | 217 | 0 | 0 | 7 | 2 | 208 |
| `PlayerPackage` | PlayerPackage | 172 | 0 | 0 | 1 | 0 | 171 |
| `ExteriorMetaTable` | Exterior | 159 | 0 | 0 | 0 | 0 | 159 |
| `LifeAbilityTable` | LifeAbility | 150 | 0 | 0 | 2 | 0 | 148 |
| `InfantTable` | Infant | 149 | 0 | 0 | 0 | 0 | 149 |
| `CharacterMetaTable` | CachedTarget,Target | 115 | 0 | 0 | 2 | 1 | 112 |
| `GuildTable` | Guild | 115 | 0 | 0 | 0 | 0 | 115 |
| `PlayerShop` | PlayerShop | 111 | 0 | 0 | 0 | 0 | 111 |
| `Talk` | Talk | 98 | 0 | 0 | 0 | 0 | 98 |
| `CityTable` | City | 96 | 0 | 0 | 0 | 0 | 96 |
| `GameProduceLogin` | GameProduceLogin | 96 | 4 | 11 | 21 | 1 | 59 |
| `TargetPetTable` | TargetPet | 82 | 0 | 0 | 1 | 1 | 80 |
| `ActionButtonMetaTable` |  | 76 | 0 | 0 | 6 | 1 | 69 |
| `SystemSetup` | SystemSetup | 73 | 0 | 5 | 1 | 0 | 67 |
| `NpcShop` | NpcShop | 72 | 0 | 0 | 0 | 0 | 72 |
| `SuperTooltips` | SuperTooltips,SuperTooltips2,SuperTooltips2_Cmp1,SuperTooltips2_Cmp2,SuperTooltips_Cmp1,SuperTooltips_Cmp2 | 70 | 0 | 0 | 0 | 0 | 70 |
| `BieYeUI` | BieYeUI | 63 | 0 | 0 | 0 | 0 | 63 |
| `BWDH2018Table` | BWDH2018 | 59 | 0 | 0 | 0 | 0 | 59 |
| `GuildLeagueTable` | GuildLeague | 52 | 0 | 0 | 2 | 1 | 49 |
| `BieYeMengChong` | BieYeMengChong | 50 | 0 | 0 | 0 | 0 | 50 |
| `BieYeFurniture` | BieYeFurniture | 47 | 0 | 0 | 0 | 0 | 47 |
| `XunzhangSysScript` | XunzhangSysScript | 45 | 0 | 0 | 0 | 0 | 45 |
| `CorpsUI_2018` | CorpsUI_2018 | 44 | 0 | 0 | 0 | 0 | 44 |
| `CorpsUI_2016` | CorpsUI_2016 | 42 | 0 | 0 | 0 | 0 | 42 |
| `BankTable` | Bank | 39 | 0 | 0 | 0 | 0 | 39 |
| `PneumaTable` | Pneuma | 38 | 0 | 0 | 0 | 0 | 38 |
| `StallSale` | StallSale | 38 | 0 | 0 | 0 | 0 | 38 |
| `AuctionMetaTable` | Auction | 34 | 0 | 0 | 0 | 0 | 34 |
| `DFS` | DFS | 34 | 0 | 0 | 0 | 0 | 34 |
| `ZBS` | ZBS | 34 | 0 | 0 | 0 | 0 | 34 |
| `Friend` | Friend | 32 | 0 | 0 | 0 | 0 | 32 |
| `Raid` | Raid | 32 | 0 | 0 | 0 | 0 | 32 |
| `DressReplaceColor` | DressReplaceColor | 29 | 0 | 0 | 0 | 0 | 29 |
| `ExchangeTable` | Exchange | 29 | 0 | 0 | 0 | 0 | 29 |
| `MailSystem` | MailSystem | 29 | 0 | 0 | 0 | 0 | 29 |
| `Macro` | Macro | 28 | 0 | 0 | 0 | 0 | 28 |
| `MaritialSys` | MaritialSys | 28 | 0 | 0 | 0 | 0 | 28 |
| `FYPVE` | FYPVE | 27 | 0 | 0 | 0 | 0 | 27 |
| `StallBuy` | StallBuy | 27 | 0 | 0 | 0 | 0 | 27 |
| `Achievement` | Achievement | 26 | 0 | 0 | 0 | 0 | 26 |
| `DaFuWengMetaTable` | DaFuWeng | 25 | 0 | 0 | 0 | 0 | 25 |
| `OrnamentsScript` | OrnamentsScript | 25 | 0 | 0 | 0 | 0 | 25 |
| `QianKunPotScript` | QianKunPotScript | 25 | 0 | 0 | 0 | 0 | 25 |
| `YiGuiTable` | YiGui | 25 | 0 | 0 | 0 | 0 | 25 |
| `GuildZhanTuanUI` | GuildZhanTuanUI | 22 | 0 | 0 | 0 | 0 | 22 |
| `SJTX` | SJTX | 21 | 0 | 0 | 0 | 0 | 21 |
| `BudgetPlanGemTable` | BudgetPlanGem | 20 | 0 | 0 | 0 | 0 | 20 |
| `FindFriendDataPool` | FindFriendDataPool | 20 | 0 | 0 | 0 | 0 | 20 |
| `TCWL` | TCWL | 20 | 0 | 0 | 0 | 0 | 20 |
| `BattleAssist` | BattleAssist | 19 | 0 | 0 | 1 | 1 | 17 |
| `CSongliaoWarData` | CSongliaoWarData | 19 | 0 | 0 | 0 | 0 | 19 |
| `FashionDepot` | FashionDepot | 19 | 0 | 0 | 0 | 0 | 19 |
| `GuiShiUI` | GuiShiUI | 19 | 0 | 0 | 0 | 0 | 19 |
| `DressStyleScript` | DressStyleScript | 18 | 0 | 0 | 0 | 0 | 18 |
| `NewXBW` | NewXBW | 18 | 0 | 0 | 0 | 0 | 18 |
| `WuLinZhiDian` | WuLinZhiDian | 18 | 0 | 0 | 0 | 0 | 18 |
| `BieYePetCreateColor` | BieYePetCreateColor | 17 | 0 | 0 | 0 | 0 | 17 |
| `ReturnTool` | ReturnTool | 16 | 0 | 0 | 0 | 0 | 16 |
| `CityBankTable` | CityBank | 15 | 0 | 0 | 0 | 0 | 15 |
| `DressEnchasing` | DressEnchasing | 15 | 0 | 0 | 0 | 0 | 15 |
| `KMCorps` | KMCorps | 15 | 0 | 0 | 0 | 0 | 15 |
| `WenDingUI` | WenDingUI | 15 | 0 | 0 | 0 | 0 | 15 |
| `TLCJ` | TLCJ | 14 | 0 | 0 | 2 | 0 | 12 |
| `GangTTable` | GangT | 13 | 0 | 0 | 0 | 0 | 13 |
| `XBWJHS` | XBWJHS | 13 | 0 | 0 | 0 | 0 | 13 |
| `JueZhanWuLinZhiDian` | JueZhanWuLinZhiDian | 12 | 0 | 0 | 0 | 0 | 12 |
| `DecoWeaponUI` | DecoWeaponUI | 11 | 0 | 0 | 0 | 0 | 11 |
| `DressGem` | DressGem | 11 | 0 | 0 | 0 | 0 | 11 |
| `FriendSearcher` | FriendSearcher | 11 | 0 | 0 | 0 | 0 | 11 |
| `ZhanTuanInterface` | ZhanTuanInterface | 11 | 0 | 0 | 0 | 0 | 11 |
| `TeamBoardDataPool` | TeamBoardDataPool | 10 | 0 | 0 | 0 | 0 | 10 |
| `FanGuangHuiYan` | FanGuangHuiYan | 9 | 0 | 0 | 0 | 0 | 9 |
| `FashionActionUI` | FashionActionUI | 9 | 0 | 0 | 0 | 0 | 9 |
| `PetInviteFriendTable` | PetInviteFriend | 9 | 0 | 0 | 0 | 0 | 9 |
| `WGAch` | WGAch | 9 | 0 | 0 | 0 | 0 | 9 |
| `BWDHTable` | BWDH | 8 | 0 | 0 | 0 | 0 | 8 |
| `Helper` | Helper | 8 | 0 | 1 | 0 | 0 | 7 |
| `AbilityTeacherTable` | AbilityTeacher | 7 | 0 | 0 | 0 | 0 | 7 |
| `ClientMovieTable` | ClientMovie | 7 | 0 | 0 | 2 | 0 | 5 |
| `CommanderFlag` | CommanderFlag | 7 | 0 | 0 | 0 | 0 | 7 |
| `CommisionShop` | CommisionShop | 7 | 0 | 0 | 1 | 0 | 6 |
| `KAllianceShop` | KAllianceShop | 7 | 0 | 0 | 0 | 0 | 7 |
| `DoubleGemTable` | DoubleGem | 6 | 0 | 0 | 0 | 0 | 6 |
| `LuHeXieXiang` | LuHeXieXiang | 6 | 0 | 0 | 0 | 0 | 6 |
| `MissionReply` | MissionReply | 6 | 0 | 1 | 0 | 0 | 5 |
| `XRZPVP` | XRZPVP | 6 | 0 | 0 | 0 | 0 | 6 |
| `DiGongShop` | DiGongShop | 5 | 0 | 0 | 0 | 0 | 5 |
| `ExcitPointMetaTable` | ExcitPoint | 5 | 0 | 0 | 0 | 0 | 5 |
| `GuildActValueUI` | GuildActValueUI | 5 | 0 | 0 | 0 | 0 | 5 |
| `PetEquipSuitUp` | PetEquipSuitUp | 5 | 0 | 0 | 0 | 0 | 5 |
| `StallBbs` | StallBbs | 5 | 0 | 0 | 0 | 0 | 5 |
| `CGemChangeDataPool` | CGemChangeDataPool | 4 | 0 | 0 | 0 | 0 | 4 |
| `KMSDShop` | KMSDShop | 4 | 0 | 0 | 0 | 0 | 4 |
| `KVKInterface` | KVKInterface | 4 | 0 | 0 | 0 | 0 | 4 |
| `Match` | Match | 4 | 0 | 0 | 0 | 0 | 4 |
| `PetEquipSuitDepart` | PetEquipSuitDepart | 4 | 0 | 0 | 0 | 0 | 4 |
| `ShenqiUpgrade` | ShenqiUpgrade | 4 | 0 | 0 | 0 | 0 | 4 |
| `Sound` |  | 4 | 0 | 0 | 0 | 0 | 4 |
| `(tham số param_2 của hàm 0x14032ee30)` |  | 3 | 0 | 0 | 0 | 0 | 3 |
| `AccountSafe` | AccountSafe | 3 | 0 | 0 | 0 | 0 | 3 |
| `CQIXIPVEWarData` | CQIXIPVEWarData | 3 | 0 | 0 | 0 | 0 | 3 |
| `GemCarve` | GemCarve | 3 | 0 | 0 | 0 | 0 | 3 |
| `KaJi` | KaJi | 3 | 0 | 0 | 0 | 0 | 3 |
| `OSAPIMetaTable` | OSAPI | 3 | 0 | 0 | 0 | 0 | 3 |
| `Transfiguration` | Transfiguration | 3 | 0 | 0 | 0 | 0 | 3 |
| `ANS` | ANS | 2 | 0 | 0 | 0 | 0 | 2 |
| `FPUMetaTable` | FPU | 2 | 0 | 0 | 0 | 0 | 2 |
| `GemMelting` | GemMelting | 2 | 0 | 0 | 0 | 0 | 2 |
| `QXPVP` | QXPVP | 2 | 0 | 0 | 0 | 0 | 2 |
| `TServerUI` | TServerUI | 2 | 0 | 0 | 0 | 0 | 2 |
| `Variable` |  | 2 | 0 | 0 | 0 | 0 | 2 |
| `ZYPVP_RankList` | ZYPVP_RankList | 2 | 0 | 0 | 0 | 0 | 2 |
| `ActionSystem` | ActionSystem | 1 | 0 | 0 | 1 | 0 | 0 |
| `AppRankList` | AppRankList | 1 | 0 | 0 | 0 | 0 | 1 |
| `AttrCompare` | AttrCompare1_1,AttrCompare1_2,AttrCompare2_1,AttrCompare2_2 | 1 | 0 | 0 | 0 | 0 | 1 |
| `CachedCharacterMetaTable` |  | 0 | 0 | 0 | 0 | 0 | 0 |
| `ZJZDPVPAct` | ZJZDPVPAct | 0 | 0 | 0 | 0 | 0 | 0 |

### 3.6 Import chưa có thay thế

- `IPHLPAPI.DLL::GetAdaptersAddresses` — lấy địa chỉ mạng/MAC (định danh máy)
- `IPHLPAPI.DLL::GetIpAddrTable` — lấy địa chỉ mạng/MAC (định danh máy)

### 3.7 Tài nguyên PE chưa dùng

- RT_MENU id 109 (74 byte) — dự án không đọc loại tài nguyên này; nội dung chưa giải mã
- RT_DIALOG id 131 (512 byte) — dự án không đọc loại tài nguyên này; nội dung chưa giải mã
- RT_STRING id 7 (48 byte) — dự án không đọc loại tài nguyên này; nội dung chưa giải mã
- RT_ACCELERATOR id 109 (16 byte) — dự án không đọc loại tài nguyên này; nội dung chưa giải mã
- RT_GROUP_CURSOR id 152 (20 byte) — CCursorMng::Initial của bản gốc không nạp nhóm này; chưa thấy chỗ nào khác của bản gốc dùng nó
- RT_VERSION id 1 (824 byte) — dự án không có tài nguyên VERSIONINFO (bản gốc: FileVersion 0,85,0,0, Changyou)

## 4. Sai và lệch

### 4.1 Đã sửa trong lượt này (kiểm bằng bản trích)

- `TAILIEU/GOI-TIN-DANG-NHAP.md`: `LCRetCreateChar` (opcode 440) và `LCRetDeleteChar` (707) ghi sai hàm `Read` và kích thước; đã sửa theo `FUN_14077de90` (đọc +0x18, 4 byte, `GetPacketSize` 4) và ghi chú giới hạn của `packet_fields.py` (hàm `Read` dùng chung chỉ hiện ở lớp đầu tiên).
- `AGENTS.md`: danh mục protocol ghi 22 tin version 2; thực tế 27 tin version 3 của năm nhóm (`docs/PROTOCOL-TIN.md`, `kVersion` = 3).
- `src/client/book/skill/actions.hpp`, `TOOLS/port/oracle/skill_api.lua`: bảng tên loại action ghi `0x140ed78d0` (nằm ngoài mọi đoạn), đúng là `0x140ed88d0` (16 con trỏ chuỗi `skill`, `life`, `packageitem`... đọc từ byte).
- `src/client/book/skill/actions.hpp`, `TOOLS/port/oracle/skill_api.lua`: `IsLMSJSecond`/`IsJYJYSecond`/`IsWJQFSecond` ghi `0x14023f8f0`/`0x14023f980`/`0x14023fa10`, đúng là `0x14023fdf0`/`0x14023fe80`/`0x14023ff10` (bảng id 821..826, 827..834 ở `0x140b1f8f4`, `0x140b1fa54`; hàm cuối so với 0x1171 và 0x1172).
- `src/client/figure/motion/jump.hpp`: `CObject_Character::Jump` ghi bắt đầu ở `0x1405ea2f0` (giữa một lệnh); đúng là `0x1405ea2b0` (đã khớp `gait.hpp` và `docs/TIEN-DO.md`).

### 4.2 Địa chỉ Game.exe trích dẫn trong mã và tài liệu không khớp bản đã trích

Đối chiếu 458 địa chỉ `0x14xxxxxxx` trong `src`, `engine`, `TOOLS`, `docs`, `TAILIEU`, `Test` với `Game.exe` (SHA-256 `3f8bb47de0bc...`): quét lệnh bằng capstone theo phạm vi hàm của `.pdata`. Kết quả: 99 đầu hàm, 99 nằm trong hàm đúng ranh giới lệnh, **183 nằm GIỮA một lệnh** (không thể là mốc mã), 77 trỏ vào dữ liệu, 0 ngoài mọi đoạn/hàm (trước khi sửa ở mục 4.1 có 2).

Trong 183 địa chỉ giữa lệnh, 133 chia hết cho 16 — dạng địa chỉ ĐẦU HÀM của một bố cục khác. Hai bằng chứng nghiêng về hai hướng: (a) `IsLMSJSecond`, `IsJYJYSecond`, `IsWJQFSecond` nội dung đúng bản này (bảng id khớp) nhưng địa chỉ trích lệch đúng 0x500 so với hàm trong bản trích; (b) `docs/AUDIT/evidence/jump_re.log` tháo `0x1405ea2f0` ra `add byte ptr [rax], al`, tức byte tại đó giống bản này và địa chỉ trích sai từ đầu. Đo thêm 2026-10-15: một phần địa chỉ là đầu hàm của bản dựng 2026-08-11 (`D:\XTLBB\Bin64\Game.exe`, 3.71.9509), vài địa chỉ là offset tệp viết nhầm thành địa chỉ ảo (thiếu 0xc00), phần còn lại chưa giải thích được: số đo và lệnh ở `docs/NGHI-NGO.md` mục 53.

Số địa chỉ giữa lệnh theo tệp (từng địa chỉ: `dia-chi-trich-dan.tsv`, cột `detail` ghi lệnh chứa nó bắt đầu ở đâu):

- `docs/TAO-NHAN-VAT-2026.md`: 31
- `TOOLS/port/oracle/skill_api.lua`: 20
- `docs/CAMERA-2026.md`: 18
- `src/client/figure/control/player_input.cpp`: 11
- `src/client/book/skill/book.hpp`: 10
- `TOOLS/port/oracle/create_role_api.lua`: 10
- `src/client/book/quest/outline.cpp`: 8
- `src/client/book/skill/actions.hpp`: 8
- `docs/DUONG-DI-2026.md`: 6
- `src/client/face/ui/panel/create_role.cpp`: 5
- `docs/TIEN-DO.md`: 5
- `src/shared/nav/route.hpp`: 4
- `src/client/book/quest/outline.hpp`: 4
- `src/client/book/skill/tables.hpp`: 4
- `src/client/app/client/display/role_stage.hpp`: 4
- `docs/NGHI-NGO.md`: 4
- `src/client/figure/control/player_input.hpp`: 3
- `src/client/face/ui/panel/role_cast.hpp`: 3
- `src/client/figure/control/follow_camera.hpp`: 2
- `src/client/face/ui/panel/self_equip.hpp`: 2
- `src/client/book/quest/log.hpp`: 2
- `TAILIEU/DANG-NHAP-GOC.md`: 2
- `src/shared/nav/route.cpp`: 1
- `src/client/figure/control/char_camera.hpp`: 1
- `src/client/figure/look/sect.hpp`: 1
- `src/client/face/ui/panel/logon.hpp`: 1
- `src/client/face/ui/panel/packet.hpp`: 1
- `src/client/face/ui/panel/role_cast.cpp`: 1
- `src/client/face/ui/panel/role_pose.hpp`: 1
- `src/client/book/quest/track.hpp`: 1
- `src/client/book/skill/actions.cpp`: 1
- `src/client/book/skill/book.cpp`: 1
- `src/client/app/client/display/role_preview.hpp`: 1
- `src/client/app/client/viewer/client_size.hpp`: 1
- `TOOLS/port/lua_native.py`: 1
- `TOOLS/port/pe_refs.py`: 1
- `docs/BAY-DA-BIET.md`: 1
- `docs/GIAO-DIEN-2026.md`: 1
- `Test/Client/client_tests.cpp`: 1

### 4.3 Chỗ mã tự ghi "Khác gốc:" (709)

"Gốc" tuỳ chỗ: ở `src/client`, `src/shared`, `TOOLS`, `Test` là client 2026 hay TLBB Dev (port); ở `engine/` là mã chép từ Forge2 (`docs/NGUON-FORGE2.md`); ở `src/server` là bản máy chủ gốc suy ra. Chỉ nhóm đầu CÓ THỂ là lệch so với Game.exe (chưa đọc từng dòng để loại những dòng nói về nguồn khác như TLBB Dev hay PathLib). Mỗi mục là một chỗ mã tự nói là lệch (đủ từng dòng, kèm câu giải thích, ở `lech-da-ghi.tsv`; cột `kind` là phân loại thô theo từ khoá, chỉ để đếm).

- Lệch so với client 2026/TLBB Dev: **171** — thiếu phần của bản gốc 88, khác 42, hình thức/kiến trúc (không đổi hành vi) 24, chặt hơn/an toàn hơn bản gốc 17
- Lệch so với Forge2 hay nguồn khác (không phải Game.exe): 538 — `engine/gpu` 188, `src/server` 71, `engine/core` 54, `engine/shader` 44, `engine/fs` 42, `engine/resource` 36, `engine/jobs` 32, `engine/math` 25, `engine/window` 19, `engine/render` 13, `engine/capture` 9, `engine/net` 4, `engine/shadertool` 1

Lệch so với client 2026/TLBB Dev theo thư mục:

- `src/client/face/ui`: 47
- `src/client/face/gui`: 21
- `src/client/figure/control`: 14
- `src/client/figure/look`: 10
- `src/client/book/skill`: 9
- `src/shared/collision/building_file.cpp`: 7
- `src/client/place/fx`: 5
- `src/client/figure/anim`: 5
- `src/client/figure/avatar`: 5
- `src/client/app/client`: 5
- `TOOLS/content/ui_rects.py`: 5
- `src/client/book/quest`: 4
- `src/client/place/ogre`: 3
- `src/client/figure/motion`: 3
- `src/client/place/scene`: 2
- `TOOLS/bake/audio_cook.py`: 2
- `src/shared/collision/mesh.hpp`: 1
- `src/shared/collision/opcode_tree.hpp`: 1
- `src/shared/ids/ids.hpp`: 1
- `src/shared/nav/finder.cpp`: 1
- `src/shared/nav/mesh.cpp`: 1
- `src/shared/protocol/channel.cpp`: 1
- `src/shared/protocol/channel.hpp`: 1
- `src/shared/protocol/wire.cpp`: 1
- `src/shared/protocol/wire.hpp`: 1
- `TOOLS/bake/tree.py`: 1
- `TOOLS/content/export_weapons.py`: 1
- `TOOLS/content/letter_labels.py`: 1
- `Test/Anim/anim_tests.cpp`: 1
- `Test/Avatar/avatar_tests.cpp`: 1
- `Test/Control/control_tests.cpp`: 1
- `Test/Control/touch_tests.cpp`: 1
- `Test/fuzz/targets.hpp`: 1
- `Test/Gui/gui_loader_tests.cpp`: 1
- `Test/Gui/gui_sheet_tests.cpp`: 1
- `Test/Gui/gui_value_tests.cpp`: 1
- `Test/Look/look_tests.cpp`: 1
- `Test/Motion/motion_tests.cpp`: 1
- `Test/Ogre/ogre_tests.cpp`: 1
- `Test/Render/camera_tests.cpp`: 1

### 4.4 Mục còn mở trong `docs/NGHI-NGO.md`

- 1. Kéo hoặc đổi cỡ cửa sổ bằng chuột làm đứng vòng lặp.
- 2. Ảnh màu là sRGB hay không.
- 3. Mã chép còn `throw`
- 4. Trạng thái toàn cục khả biến trong mã chép
- 5. Log đa luồng chưa chạy ThreadSanitizer.
- 6. Chữ ký bẻ dòng trong mã chép.
- 7. Phần `.cpp` của core chỉ có bản Win32.
- 8. Client chưa tạo `core::Log`.
- 9. Nhánh tự cài của `core/function.hpp` chưa chạy.
- 10. Hai cách xử lý `misc-include-cleaner` với Win32 cùng tồn tại.
- 12. `log_tests` trên gcc-debug thỉnh thoảng thoát 0xC0000374.
- 13. Context EGL không hỏi mức anisotropy.
- 14. Ba chỗ của bộ âm thanh còn chặn hoặc còn thô
- 15. Nút tự chiến đấu của HUD hiện theo suy đoán
- 16. Ba chỗ của bộ dàn chữ chưa có căn cứ đo
- 17. Nhãn thẻ kênh chat bị cắt sau khi dịch
- 18. Dải hiệu ứng của thanh trượt vẽ cùng màu với thanh
- 19. Sáu cửa sổ con của khung nhân vật bị giấu theo suy đoán
- 20. Bảng cảnh client đang nạp không phải bảng của bản 2026
- 21. `Falagard/MapImage` và `Falagard/AnimateImage` không có mã nguồn
- 22. Giờ trong game của minimap đứng ở giờ Tý
- 23. Texture ghi thẳng đường dẫn trong look chưa được gom
- 24. Ảnh đầu 3D của khung người chơi: phần còn ngờ
- 25. D3D12 và D3D11 không khởi tạo được phần hiển thị trên máy dựng
- 26. Nhịp khung của backend GL
- 27. Số "Vừa rồi" trên tablet dao động dù hình hiện đều
- 28. Ánh sáng theo shader gốc: phần còn ngờ
- 29. Backend GL màu thô lệch Vulkan ở phần trong suốt
- 30. GLES tính ánh sáng ở đỉnh
- 31. Sổ assets Android và dữ liệu vào APK
- 32. Gợi ý cho mục 25 từ mã bgfx
- 33. Chữ Việt và vùng chữ của nút
- 34. Một khung dài 87–100 ms khi lần đầu mở bảng
- 35. Ảnh con trỏ `Interface/cursor` không có công cụ nào sinh ra
- 36. Bảng nhân vật: phần chưa theo hết script 2026
- 37. Ca vòng kéo của cửa sổ thỉnh thoảng không có nhịp nào
- 38. Camera và chuột theo mã máy 2026: phần còn ngờ
- 39. Đường đi và vật cản theo `PathLib.dll` 2026: phần còn ngờ
- 40. Màn đăng nhập: phần chưa theo hết bản gốc
- 41. Module `collision` gộp từ việc dở của đợt DH 1
- 42. Nút còn không nối vì chưa đo được đích
- 43. Sổ nhiệm vụ, sách võ và widget cuộn: phần đã port chưa nối vào màn chơi
- 44. Máy chủ sau P2 đợt 3 phần đầu: nợ và chỗ ngờ của `gate`, `secure` và test của chúng
- 45. Lỗ hổng của hạ tầng và của cổng dựng, thấy khi đối chiếu mã với tài liệu
- 46. Bảng chuyển cảnh: lúc nào bản gốc phát `PLAYER_LEAVE_WORLD`
- 47. Máy chủ: review cuối 2026-10-12 — đã sửa và còn mở
- 48. Giao diện màn chơi 2026-10-13: các chỗ chưa đọc được từ mã máy hay chưa làm
- 49. iOS: dọn nguồn 2026-10-13 và những gì chỉ kiểm được trên máy Apple
- 50. Shader chuyển sang Slang 2026-10-13: các chỗ chưa kiểm
- 51. Vũ khí, hiệu ứng đồ, đòn đánh, tuyệt chiêu 2026-10-14: đã có và CHƯA làm
- 52. Xương/animation (figure/anim, avatar/rig, model clip): review sâu 2026-10-14 — đã xác minh và kẽ hở còn mở
- 53. Địa chỉ `Game.exe` trong mã và tài liệu không khớp bản `Game.exe` đã trích
- 54. Máy chủ gameplay 2026-10-15: các chỗ chưa kết luận được

### 4.5 Gói đăng nhập: tài liệu thủ công so với dump tự động

- `CLConnect` (opcode 355): KHỚP (9 trường thủ công, 9 trường tự động)
- `LCRetConnect` (opcode 311): KHỚP (8 trường thủ công, 8 trường tự động)
- `CLAskLogin` (opcode 299): KHỚP (19 trường thủ công, 19 trường tự động)
- `LCRetLogin` (opcode 223): KHỚP (12 trường thủ công, 12 trường tự động)
- `CLAskCharList` (opcode 711): KHỚP (1 trường thủ công, 1 trường tự động)
- `LCRetCharList` (opcode 319): KHỚP (0 trường thủ công, 0 trường tự động)
- `CLCheckAllowCreateChar` (opcode 1250): KHỚP (0 trường thủ công, 0 trường tự động)
- `LCRetCheckAllowCreateChar` (opcode 1251): KHỚP (1 trường thủ công, 1 trường tự động)
- `CLAskCreateChar` (opcode 522): KHỚP (14 trường thủ công, 14 trường tự động)
- `LCRetCreateChar` (opcode 440): KHỚP (1 trường thủ công, 1 trường tự động)
- `CLAskDeleteChar` (opcode 240): KHỚP (3 trường thủ công, 3 trường tự động)
- `LCRetDeleteChar` (opcode 707): KHỚP (1 trường thủ công, 1 trường tự động)
- `CLAskCharLogin` (opcode 426): KHỚP (8 trường thủ công, 8 trường tự động)
- `LCRetCharLogin` (opcode 38): KHỚP (2 trường thủ công, 2 trường tự động)
- `LCStatus` (opcode 554): KHỚP (2 trường thủ công, 2 trường tự động)
- `CGConnect` (opcode 456): KHỚP (17 trường thủ công, 17 trường tự động)
- `GCConnect` (opcode 796): KHỚP (5 trường thủ công, 5 trường tự động)
- `CGEnterScene` (opcode 17): KHỚP (3 trường thủ công, 3 trường tự động)
- `GCEnterScene` (opcode 380): KHỚP (17 trường thủ công, 17 trường tự động)

## 5. Giới hạn của bản so này

- Gói tin chỉ phân nhóm theo từ khoá của tên; không so định dạng trường với `src/shared/protocol` (hai giao thức không cùng định dạng).
- Lớp và tệp nguồn do quy tắc thủ công ghép: một lớp rơi vào quy tắc rộng có thể ghép nhầm trạng thái (mỗi hàng ghi quy tắc và probe).
- Hàm script Lua so theo tên và địa chỉ; `CÓ TÊN (MÃ)` có thể trùng tên ngẫu nhiên; chưa so chữ ký hay hành vi từng hàm.
- Chuỗi tiếng Trung (GBK) của bản gốc chưa giải mã; 5 hàm lớn nhất (mã nạp bảng, hàm đăng ký Lua lớn) chỉ có disassembly; mọi lần đăng ký Lua của hàm lớn nhất (`0x1406557c0`, hơn 5 700 lần) đọc từ disassembly bằng bộ giải riêng (`game_exe_dump.py lua`), kiểm chéo bằng nhãn lỗi `LUA:` (660 hàm) và bằng 5 887 định danh của `lua_register.tsv` (còn 21 định danh không phải tên hàm: biến cấu hình, tên sự kiện).
- Không có dữ liệu thời gian chạy: so tĩnh, chưa chạy bản gốc để đối chiếu hành vi.

