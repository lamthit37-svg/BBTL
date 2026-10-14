"""So bản trích Game.exe 2026 (TAILIEU/GAME-EXE-2026) với mã client hiện tại, từng mục một.

Sinh ra TAILIEU/GAME-EXE-2026/so-sanh/*.tsv và SO-SANH.md. Nhóm nào so được từng mục thì có bảng riêng (mỗi hàng một mục của bản gốc,
có trạng thái và bằng chứng):
  bang-du-lieu.tsv   692 tên tệp dữ liệu client gốc đọc     <- tìm tên trong TOOLS/content, src/client, src/shared, engine, cmake
  goi-tin.tsv        1 367 gói tin Packets::*                <- client chưa mở socket; ghép theo bảng tương đương chức năng
  lop.tsv            507 lớp RTTI không phải gói tin         <- quy tắc thủ công, mỗi quy tắc có "probe" tự kiểm trong mã hiện tại
  tep-nguon.tsv      261 tệp nguồn gốc (từ chuỗi assert)     <- quy tắc thủ công kèm probe
  lua-api.tsv        định danh Lua mà hàm đăng ký tham chiếu <- tên có nhắc trong src/client hoặc trọng tài Lua hay không
  import-dll.tsv     835 import                              <- theo DLL
  lech-da-ghi.tsv    mọi chú thích "Khác gốc:" trong mã      <- chỗ mã tự ghi là lệch bản gốc
  nghi-ngo-mo.tsv    mục còn mở của docs/NGHI-NGO.md
  kiem-goi-dang-nhap.tsv  đối chiếu GOI-TIN-DANG-NHAP.md (dump thủ công cũ) với packets.tsv (dump tự động)

Trạng thái: CÓ (có bản đối ứng đã chạy), MỘT PHẦN (có nhưng thiếu phần của bản gốc), CHƯA CÓ, KHÁC THIẾT KẾ (dự án chọn cách khác, có chủ đích),
KHÔNG ÁP DỤNG (SDK bên thứ ba, hạ tầng chỉ của bản gốc). Ghi chú về độ tin cậy của từng phép ghép nằm ở cột "cách" của mỗi bảng.
Hàm (57 200) và chuỗi (56 190) không so từng cái: chúng được so qua lớp, tệp nguồn, gói tin và tệp dữ liệu ở trên.
"""

from __future__ import annotations

import bisect
import collections
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # chạy với -I thì thư mục của tệp không tự vào sys.path
from game_exe_dump import WORK, PeImage  # noqa: E402

REPO = Path(__file__).resolve().parents[3]
DUMP = REPO / "TAILIEU" / "GAME-EXE-2026"
OUT = DUMP / "so-sanh"

CLIENT_ROOTS = ["src/client", "src/shared", "engine", "TOOLS/content", "cmake", "CMakeLists.txt", "android", "apple"]
CODE_EXT = {".cpp", ".hpp", ".h", ".mm", ".py", ".cmake", ".toml", ".java", ".kt", ".txt"}


def read_tsv(path: Path) -> tuple[list[str], list[list[str]]]:
    with path.open(encoding="utf-8") as handle:
        header = handle.readline().rstrip("\n").split("\t")
        return header, [line.rstrip("\n").split("\t") for line in handle]


def write_tsv(name: str, header: list[str], rows: list[list[object]]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with (OUT / name).open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("\t".join(header) + "\n")
        for row in rows:
            handle.write("\t".join(str(cell).replace("\t", " ").replace("\n", " ") for cell in row) + "\n")


def load_corpus() -> dict[str, str]:
    corpus: dict[str, str] = {}
    for root in CLIENT_ROOTS:
        base = REPO / root
        files = [base] if base.is_file() else (p for p in base.rglob("*") if p.is_file()) if base.exists() else []
        for path in files:
            rel = path.relative_to(REPO).as_posix()
            if path.suffix.lower() not in CODE_EXT and path.name != "CMakeLists.txt":
                continue
            if "/rea/" in rel or "__pycache__" in rel or rel.startswith(("TOOLS/content/test_",)):
                continue
            if path.suffix.lower() == ".txt" and path.name != "CMakeLists.txt":
                continue
            try:
                corpus[rel] = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
    return corpus


def grep(corpus: dict[str, str], pattern: str, flags: int = re.I, limit: int = 3) -> list[str]:
    rx = re.compile(pattern, flags)
    hits = []
    for rel, text in corpus.items():
        if rx.search(text):
            hits.append(rel)
            if len(hits) >= limit:
                break
    return hits


def count_hits(corpus: dict[str, str], pattern: str, flags: int = re.I) -> int:
    rx = re.compile(pattern, flags)
    return sum(1 for text in corpus.values() if rx.search(text))


# --- 1. tệp dữ liệu --------------------------------------------------------------------------------------------------

def compare_data_files(corpus):
    """Hai bậc bằng chứng. CÓ: tên tệp ĐỦ ĐUÔI nằm trong công cụ xuất/gom (TOOLS/content) — bảng đó thật sự được đọc và xuất.
    CHƯA CÓ (chỉ nhắc): tên chỉ xuất hiện trong mã client (thường là chú thích của đoạn port) hoặc chỉ tên trần, không có công cụ xuất.
    Cảnh `.Scene`: CÓ khi thư mục dev/client/assets/Scene (cục bộ, không vào git) có cảnh đó."""
    _, rows = read_tsv(DUMP / "data_files.tsv")
    tools = {k: v for k, v in corpus.items() if k.startswith("TOOLS/content")}
    scene_dir = REPO / "dev" / "client" / "assets" / "Scene"
    # Cảnh được gom phẳng thành <map>.<đuôi> (GridInfo, Heightmap, hfog, files.tsv...), không còn tệp .Scene gốc
    scenes_local = collections.Counter(p.name.split(".")[0].lower() for p in scene_dir.iterdir()) if scene_dir.exists() else collections.Counter()
    out = []
    for name, address, referrers in rows:
        base = re.sub(r"\.[A-Za-z0-9]+$", "", name)
        if bool(re.search(r"[%\\/]|^\.", name)) or len(base) < 3:
            out.append([name, address, "KHÔNG SO ĐƯỢC", "mẫu định dạng hoặc đường dẫn chung (chứa %, \\, / hoặc chỉ là đuôi)", "", referrers])
            continue
        if name.lower().endswith(".scene"):
            have = scenes_local.get(base.lower(), 0)
            out.append([name, address, "CÓ" if have else "CHƯA CÓ",
                        f"dev/client/assets/Scene có {have} tệp {base}.* (client đọc dữ liệu đã gom, không đọc .Scene gốc)" if have else "chưa gom cảnh này vào dev/client/assets/Scene", "", referrers])
            continue
        full = r"(?<![A-Za-z0-9_])" + re.escape(name) + r"(?![A-Za-z0-9_])"
        bare = r"(?<![A-Za-z0-9_])" + re.escape(base) + r"(?![A-Za-z0-9_])"
        in_tools = grep(tools, full, re.I, 3)
        if in_tools:
            out.append([name, address, "CÓ", "công cụ xuất/gom nhắc đích danh tên tệp", ";".join(in_tools), referrers])
            continue
        mention = grep(corpus, full, re.I, 3) or grep(corpus, bare, re.I, 3)
        out.append([name, address, "CHƯA CÓ", ("chỉ nhắc tên trong mã/chú thích, không có công cụ xuất" if mention else "không có mã hay công cụ nào nhắc tên"), ";".join(mention), referrers])
    write_tsv("bang-du-lieu.tsv", ["name", "address", "status", "evidence", "files", "original_referrers"], out)
    return out


# --- 2. gói tin ---------------------------------------------------------------------------------------------------------

# Nhóm chức năng theo từ khoá trong tên (thứ tự: cụ thể trước).
PACKET_GROUPS = [
    ("đăng nhập/tài khoản", r"Login|Account|Passwd|Password|CharList|CreateChar|DeleteChar|CharLogin|Connect|Version|WorldTrans|Authenticate|WeGame|RegSafe|RegNewLicense|YanZheng|License"),
    ("nhịp tim/hệ thống", r"HeartBeat|Ping|Pong|ClientState|CheckMemory|Crash|Performance|Region|Statistic|SystemMsg|GameCommond|Seraph|Setting|ServerTime|WorldTime|ServerLsCount|RetAskQuit|^GCTest|CYJTest|NetDelay|NetClean|NTP|Anti|Waigua|Report|Recorder|Mobile|LCStatus|FangChenMi|Fangchenmi|GrabMessage|AskNoteLog|x64Info|MiniStat"),
    ("chat/thông báo", r"Chat|Talk|Broadcast|Notify|Msg(?!Ball)|Mood|DirectString|Speak|PopupString"),
    ("vào cảnh/di chuyển", r"EnterScene|LeaveScene|ChangeScene|CharMove|Move|Position|Teleport|Jump|Stop(?!Crash)|TransScene|OpenWorld|MapInfo|SceneInfo|Zone|AutoRun|Follow|Fly|Arrive|CharDoAction|PlayerCallOf|CommonPos"),
    ("đối tượng trong cảnh", r"NewPlayer|NewMonster|NewNPC|NewSpecial|NewItem|NewPet|NewPlatform|Delete.*Object|DelObject|ObjectInfo|Death|LookUpOther|PlayerInfoBySuper|PlayerDie|NameBoard|LockObj"),
    ("chiến đấu/kỹ năng", r"Attack|Skill|Impact|Combat|Magic|Hit|Damage|Cast|Channel|Buff|Relive|Dodge|Target|Talent|XinFa|XingZhen|Pneuma|IA(?=Skill)|Challenge|Duel|StudyXinfa|ResetAttr"),
    ("thuộc tính nhân vật", r"CharBaseAttrib|DetailAttrib|DetailExp|Attrib|Level|Exp\b|Title|Achievement|Ability|Martial|Life|Fatigue|CharCharge|Cooldown|FiveElements|Xiulian"),
    ("vật phẩm/hành trang", r"Item|Bag|Package|Equip|Gem|Pick|Drop|Bank|Mount|Ride|Fashion|Dress|Cangpin|CangPin|Remove|Exchange"),
    ("cửa hàng/giao dịch", r"Shop|Stall|Auction|Trade|YuanBao|Merchandise|Market|Buy|Sell|Repair|Mall"),
    ("nhiệm vụ", r"Mission|Quest|Task|Npc(?!Shop)|Event|Campaign|Activity|Raid|FuBen|Fuben|FYPVE|TLCJ|XBW|PVP|Battle|BWDH|Boss"),
    ("tổ đội/bang/quan hệ", r"Team|Guild|Gang|Faction|Relation|Friend|Mail|Marry|Master|Prentice|Corps|Zhan|Territory|City|Finger|Foe|BlackList|Find"),
    ("thú cưng/nhi", r"Pet|MengChong|Infant|Child|Summon"),
    ("biệt dã", r"BieYe"),
    ("giao diện/script", r"UI|Script|Help|Tutorial|Movie|Hyper|Macro|Setup|Option|Config|Cursor|Sound|Music|Camera|Tips?"),
]

# Gói của bản gốc có bản tương đương chức năng trong protocol của dự án (src/shared/protocol/catalog/messages.tsv).
# Định dạng khác hẳn (protocol dự án tự thiết kế, mã hoá và thương lượng bản): chỉ ghi "tương đương chức năng".
PACKET_EQUIVALENT = [
    (r"^(CGHeartBeat|GCHeartBeat)$", "Ping/Pong"),
    (r"^CGConnect$", "Hello+Login/Resume"),
    (r"^GCConnect$", "Welcome/SessionStart"),
    (r"^CLAskLogin$", "SignIn"),
    (r"^LCRetLogin$", "Ticket/Reject"),
    (r"^CLAskCharList$", "Login/EnterGame (danh sách nhân vật)"),
    (r"^LCRetCharList$", "CharacterList"),
    (r"^CLAskCreateChar$", "CreateCharacter"),
    (r"^CLAskDeleteChar$", "DeleteCharacter"),
    (r"^CLAskCharLogin$", "EnterGame"),
    (r"^LCRetCharLogin$", "SessionStart/SceneEnter"),
    (r"^CGEnterScene$", "EnterGame"),
    (r"^GCEnterScene$", "SceneEnter"),
    (r"^CGCharMove$", "Move"),
    (r"^GCCharMove$|^GCNewPlayer_Move$", "Position/EntityPos"),
    (r"^GCNewPlayer$", "EntityAppear"),
    (r"^GCDelObject$", "EntityDisappear"),
    (r"^GCCharBaseAttrib$", "EntityVitals (một phần)"),
]


def packet_group(name: str) -> str:
    for group, pattern in PACKET_GROUPS:
        if re.search(pattern, name):
            return group
    return "hoạt động/tính năng riêng (không suy được nhóm từ tên)"


def compare_packets():
    _, rows = read_tsv(DUMP / "packets.tsv")
    out = []
    for row in rows:
        name, pid, fixed, vft, kind, nfields, nbytes, branching, read_fn, exec_slot, exec_fn, exec_file, fields = row
        equivalent = next((proj for pattern, proj in PACKET_EQUIVALENT if re.search(pattern, name)), "")
        direction = re.match(r"^([A-Z][A-Za-z]?[A-Z]?)(?=[A-Z][a-z0-9])", name)
        out.append([name, pid, fixed, packet_group(name), "MỘT PHẦN" if equivalent else "CHƯA CÓ",
                    f"tương đương chức năng: {equivalent} (server có, client chưa nối; định dạng dự án khác)" if equivalent else "client không có socket/handler/giải mã gói này",
                    kind, nfields])
    write_tsv("goi-tin.tsv", ["class", "packet_id", "fixed_size", "group", "status", "evidence", "read_kind", "read_fields"], out)
    return out


# --- 3. lớp RTTI ----------------------------------------------------------------------------------------------------------
# (regex tên lớp, trạng thái, bản đối ứng hiện tại, probe regex phải tìm thấy trong mã hiện tại để giữ trạng thái đó)
CLASS_RULES = [
    # hạ tầng không áp dụng
    (r"^(std::|std |Concurrency|type_info|_Facet|stdext)", "KHÔNG ÁP DỤNG", "thư viện chuẩn/CRT của MSVC", None),
    (r"^(reflect::|rail::|CTU::|Seraph::|InstallStatistics::|CYouServerPluginsDlCClient|WeGameEventMgr|DWTestListener|CTDProfile)", "KHÔNG ÁP DỤNG", "SDK/dịch vụ bên thứ ba của bản gốc (Rail, anti-cheat, thống kê, tải crash, WeGame, profiler)", None),
    (r"^(GenericWork|LuaExport<|StreamAutomatic::|PacketFactoryManagerInstance)", "KHÔNG ÁP DỤNG", "mẫu/lambda hạ tầng sinh bởi trình dịch hoặc bọc Lua", None),
    (r"^SCRIPT_SANDBOX::|^SCRIPT_", "KHÁC THIẾT KẾ", "lớp bọc API Lua của một tính năng; dự án không chạy Lua ở client mà dịch script sang C++ (ui/panel, có số vàng từ trọng tài)", r"lua_oracle|oracle"),
    (r"^CScriptEnvironment$|^CScriptSystem$", "KHÁC THIẾT KẾ", "môi trường Lua; client dự án không nhúng Lua", None),
    (r"^(Socket|SocketInputStream|SocketOutputStream|NetThread|CNetManager|MyThread)$", "KHÁC THIẾT KẾ", "engine/net (socket TCP không chặn, PollSet) và shared/link; client chưa gọi", r"PollSet|Reactor"),
    (r"^(Packet|PacketFactory|PacketFactoryManager)$", "KHÁC THIẾT KẾ", "shared/protocol (khung, kênh, danh mục tin sinh từ bảng)", r"protocol"),
    (r"^(CMD5|CryptBox|CryptionBox::CryptBox)$", "KHÁC THIẾT KẾ", "shared/secure dùng libsodium (bắt tay, bản ghi mã hoá)", r"sodium"),
    (r"^(GameLink|GameLinkClient|GameLinkServer|JsonProtocol::.*)$", "KHÁC THIẾT KẾ", "shared/link và protocol của dự án", r"link"),
    (r"^(InputStream|OutputStream|IODataStream|MsgIODataStream|IniFile)$", "KHÁC THIẾT KẾ", "engine/io, engine/fs; cấu hình bằng TOML/CLI", r"engine/io|fs::"),
    (r"^DBC::DBCFile$|^CDataBase$|^CDataBaseSystem$", "MỘT PHẦN", "shared/table + TOOLS/content/dbc.py; nạp 46 bảng đã xuất, không nạp 598 bảng của bản gốc", r"dbc"),
    (r"^(CTimerManager|TimelineLink)$", "MỘT PHẦN", "engine/core đồng hồ và FixedStep", r"FixedStep"),
    (r"^(CVersionSystem|CVariableSystem)$", "CHƯA CÓ", "không có hệ biến cấu hình/phiên bản chạy như bản gốc (client dùng options CLI)", None),
    (r"^(CEventSystem|CUICommandSystem|CGameInterface)$", "KHÁC THIẾT KẾ", "ui/panel gọi trực tiếp; không có bus sự kiện PushEvent (docs ghi SU-KIEN-GAME.tsv)", r"press_|Clicked"),
    (r"^CInputSystem$", "MỘT PHẦN", "figure/control + app/client/viewer/sdl_input (chuột, phím, cảm ứng, cần gạt)", r"SdlInput"),
    (r"^CCursorMng$", "CÓ", "app/client/viewer/cursors + figure/control/cursor_rules (22 con trỏ đọc từ Game.exe)", r"GameCursors"),
    (r"^(CNewSoundSystemFMod|CSoundBufferFMod|CSoundSourceFMod)$", "MỘT PHẦN", "engine/audio (miniaudio, nhạc nền theo cảnh); chưa có tiếng hiệu ứng", r"audio"),
    (r"^(CScene|CZone|CWorldManager|CPath)$", "MỘT PHẦN", "place/scene, app/client/world, shared/nav (.path)", r"SceneFile|PathFinder|nav::"),
    (r"^(CFakeObjSystem|CFakeObjSystemEx)$", "MỘT PHẦN", "app/client/display/role_stage + role_preview (người mẫu xem trước trên màn tạo nhân vật)", r"RoleStage"),
    (r"^CHelperSystem$", "KHÁC THIẾT KẾ", "nút trợ giúp mở trang web (kOpenWeb)", r"kOpenWeb"),
    # nhân vật / đối tượng
    (r"^CObject_(PlayerMySelf|Character|Dynamic)$", "MỘT PHẦN", "app/client/display/player + figure/avatar (xương, dáng đi, đòn đánh, vũ khí); không có logic do máy chủ điều khiển", r"PlayerActor"),
    (r"^CObject_(Static|Effect)$", "CÓ", "place/scene (vật thể tĩnh) và place/fx (hiệu ứng)", r"PlacedProp|fx::"),
    (r"^CObject_(Building|Building2)$", "MỘT PHẦN", "vật thể công trình ở place/scene + shared/collision (.WCollision, nâng chân)", r"WCollision|building"),
    (r"^CObject_(Map|Phy)$", "MỘT PHẦN", "vị trí/va chạm rải ở figure/control/ground + shared/collision; không có lớp nền chung", r"ground"),
    (r"^CObject$|^CObjectManager$|^CServerObjectManager$|^CObjectLoadQueue$", "CHƯA CÓ", "không có bộ quản lý đối tượng trong cảnh (Stage thiếu Actor, kOtherActor còn là stub)", r"kOtherActor"),
    (r"^CObject_(PlayerOther|PlayerNPC|PlayerSummoner|PlayerInfant|Bus|Surface|Special|ProjTex.*|BlueCircle|BieYe.*|AttachBieYeItem|FakeSWItem|Bullet)$", "CHƯA CÓ", "chưa có NPC, quái, người chơi khác, xe, đạn, hiệu ứng bề mặt, vòng chọn", None),
    (r"^(CObjectCommand|CObjectCommand_.*)$", "CHƯA CÓ", "lệnh đối tượng do máy chủ/AI ra (di chuyển, đánh, dùng kỹ năng); client chỉ có WalkOrder/Strike cục bộ", r"WalkOrder"),
    (r"^(CAI_.*|CCharacterData|SDATA_.*|CDetailAttrib_.*)$", "MỘT PHẦN", "figure/hero (số liệu nhân vật) và book/skill; chưa có AI, chưa có DetailAttrib từ máy chủ", r"hero::"),
    (r"^(SObject.*|SImpactEffect|SObjectInit)$", "CHƯA CÓ", "chưa có đối tượng/impact do máy chủ gửi", None),
    (r"^(CTripperObject_.*)$", "CHƯA CÓ", "chưa có vật thể tương tác (bục, tài nguyên)", None),
    (r"^(CGamePro_.*|GameProcedure)$", "MỘT PHẦN", "thủ tục Login/CharSel/CharCreate có ở face/ui/panel; thủ tục Main chỉ là màn chơi không máy chủ", r"LoginFlow|SelectRole|CreateRole"),
    (r"^(CPetPossPositionMgr)$", "CHƯA CÓ", "chưa có thú cưng", None),
    # action / item / kỹ năng
    (r"^CActionItem_(Skill|XinFa|LifeAbility|ZhenFaSkill)$", "CÓ", "book/skill/actions (ActionKind: skill, life, xinfa, formation)", r"ActionKind"),
    (r"^(CActionItem|CActionSystem)$", "MỘT PHẦN", "book/skill/actions (chỉ 5 loại action của sách võ công)", r"ActionKind"),
    (r"^CActionSetMgr$", "CÓ", "bảng ActionSet đã xuất (skill_actions.tsv, anim_sets.tsv) và figure/look", r"ActionSet|anim_sets"),
    (r"^CActionItem_MouseCmd_", "CHƯA CÓ", "con trỏ lệnh của vật phẩm/bán/sửa/giám định chưa có (chưa có vật phẩm)", None),
    (r"^CActionItem_", "CHƯA CÓ", "loại action này chưa có (chỉ có skill, life, xinfa, formation, pet)", None),
    (r"^(CItem|CItem_.*|Citem_.*|CItemSystem|tItem|ItemElement|TableItemElement|CTransferItemSystem|tTransferItemSystem::Element)$", "CHƯA CÓ", "chưa có hệ vật phẩm (hành trang, trang bị thật, chuyển vật phẩm); chỉ có bảng và vũ khí cầm tay thử", r"WeaponItemRow"),
    # danh sách / quan hệ / mạng xã hội
    (r"^(BlackList|EnemyList|FingerList|FoeList|FriendList|RelationList|TempRelationList|TrustFriendList|BossElement|PlayerElement|PetElement|PetNeiDanElement|SectElement|PneumaElement|XingZhenElement|ChannelElement|HttpElement|HyperLinkElement|CElement|ChildFashionDepotElement|FashionDepotElement|ExteriorRideElement|ExteriorShareHyperLinkElement|ExteriorWeaponElement|AchievementElement|BuyFromYBShopElement|YuanBaoShopElement|GongChengZhanBaoElement|TeamZhengZhaoElement)$", "CHƯA CÓ", "phần tử danh sách giao diện/quan hệ chưa có (chưa có bạn bè, đội, thú, shop, thành tích...)", None),
    (r"^(AchievementElement|AnonymousCommonManager|MutiLineTableManager|T300.*|TAnomymousInfoManager|ActivityNotePetTalkTmp|PaoPaoPetTalkImp|SysBroadCastPetTalkImp|CActivePosManager|CAbilityTableManager|QianKunPotManager)$", "CHƯA CÓ", "hệ quản lý tính năng riêng của bản gốc chưa có", None),
    (r"^(Client[A-Za-z]+Manager|ClientMovieBridge|tMovieDataBridge)$", "CHƯA CÓ", "quản lý hoạt động/PVP/phim của bản gốc chưa có", None),
    (r"^(MsgBall.*|CUIDataPool|CDataPool)$", "MỘT PHẦN", "ui/panel dùng dữ liệu cục bộ; chưa có DataPool chung và bóng tin nhắn", r"hero::"),
    (r"^(Find.*|CalcTargetNum|ObjectFilter)$", "CHƯA CÓ", "bộ lọc chọn mục tiêu (quái/NPC/người chơi gần nhất) cho AI/kỹ năng chưa có", None),
    (r"^(ZZFuben.*)$", "CHƯA CÓ", "kiểm tra phó bản chưa có", None),
    (r"^(EPRule.*)$", "CHƯA CÓ", "ExcitPoint (điểm kích hoạt) chưa có", None),
    (r"^(CBRLoop_.*)$", "CHƯA CÓ", "BowlRobbing chưa có", None),
    (r"^(GUILD_.*|_GUILD_.*|DFWGROUP_.*|_DAFUWENGGROUP.*|GangT_.*|_GANGTERRITORY.*)$", "CHƯA CÓ", "cấu trúc gói bang hội/Đại Phú Ông/lãnh địa chưa có", None),
    (r"^(MAP_POS_DEFINE|TD_MAP_POS_DEFINE)$", "CÓ", "bảng ScenePosDefineEx / SceneDefineEx đã xuất và đọc (app/client/map, ui/panel/scene_table)", r"ScenePosDefineEx"),
    (r"^BkThreadChatProcess$", "CHƯA CÓ", "luồng xử lý chat nền; chưa có chat", None),
    (r"^GongChengZhanBaoElement_New$|^Player_AtClient$|^SubActionList<", "CHƯA CÓ", "phần tử/giao diện của tính năng chưa có", None),
]


def compare_classes(corpus):
    _, rows = read_tsv(DUMP / "classes.tsv")
    out = []
    rules_hit: dict[int, int] = collections.Counter()
    for row in rows:
        name = row[0]
        if name.startswith(("Packets::", "PacketPadding<")):
            continue
        status, note, probe_used = "CHƯA CÓ", "không có quy tắc ghép: chưa thấy bản đối ứng", ""
        for index, (pattern, st, counterpart, probe) in enumerate(CLASS_RULES):
            if re.search(pattern, name):
                rules_hit[index] += 1
                status, note = st, counterpart
                if probe is not None:
                    hits = grep(corpus, probe, re.I, 1)
                    probe_used = f"probe {probe!r}: " + ("thấy " + hits[0] if hits else "KHÔNG thấy")
                    if not hits and st in ("CÓ", "MỘT PHẦN", "KHÁC THIẾT KẾ"):
                        status, note = "CHƯA CÓ", f"{counterpart} — nhưng probe không thấy trong mã"
                break
        out.append([name, row[1], row[2], row[3], status, note, probe_used])
    write_tsv("lop.tsv", ["class", "vftable", "slot_count", "bases", "status", "counterpart_or_reason", "probe"], out)
    return out


# --- 4. tệp nguồn ---------------------------------------------------------------------------------------------------------
FILE_RULES = [
    (r"Action\\GMActionSystem\.cpp$", "MỘT PHẦN", "book/skill/actions (5 loại action)", r"ActionKind"),
    (r"Action\\GMActionSystem_(Skill|XinFa|LifeAbility|ZhenFaSkill)\.cpp$", "CÓ", "book/skill/actions", r"ActionKind"),
    (r"Action\\GMActionSystem_PetSkill\.cpp$", "MỘT PHẦN", "bốn action thú cưng cố định (PetAction)", r"PetAction"),
    (r"Action\\", "CHƯA CÓ", "loại action này chưa có", None),
    (r"BowlRobbing\\", "CHƯA CÓ", "BowlRobbing chưa có", None),
    (r"Cursor\\CursorMng\.cpp$", "CÓ", "app/client/viewer/cursors + figure/control/cursor_rules", r"GameCursors"),
    (r"DataPool\\(GMDP_Struct_Quest)\.cpp$", "CÓ", "book/quest (log, outline, track)", r"QuestLog|QuestBook"),
    (r"DataPool\\GMDP_Struct_Skill\.cpp$", "CÓ", "book/skill (sách võ công)", r"OwnedSkill"),
    (r"DataPool\\(GMDP_CharacterData|DetailAttrib_Player|GMUIDataPool|GMDataPool)\.cpp$", "MỘT PHẦN", "figure/hero (số liệu nhân vật mẫu newcomer()) và dữ liệu cục bộ của ui/panel; chưa có DataPool đầy đủ", r"hero::"),
    (r"DataPool\\", "CHƯA CÓ", "cấu trúc dữ liệu này chưa có", None),
    (r"Dbc\\GMDataBase\.cpp$", "MỘT PHẦN", "shared/table + TOOLS/content/dbc.py; đọc 46 trên 598 bảng", r"dbc"),
    (r"ExcitPoint\\|ExtExport\.cpp$", "CHƯA CÓ", "chưa có", None),
    (r"FakeObject\\", "MỘT PHẦN", "role_stage/role_preview", r"RoleStage"),
    (r"GMResourceFilter\.cpp$", "CHƯA CÓ", "chưa có bộ lọc tài nguyên", None),
    (r"Helper\\", "KHÁC THIẾT KẾ", "nút trợ giúp mở trang web", r"kOpenWeb"),
    (r"Input\\", "MỘT PHẦN", "figure/control/player_input (phím)", r"PlayerInput|player_input"),
    (r"Interface\\GMInterface_Lua\.h$|Interface\\GMinterface_Lua\.h$|helper\\\.\.\\Interface\\GMinterface_Lua\.h$", "KHÔNG ÁP DỤNG", "khai báo Lua; client dự án không nhúng Lua", None),
    (r"Interface\\GMGameInterface_Script_PlayerMySelf\.cpp$", "MỘT PHẦN", "ui/panel đọc hero::Hero (khung nhân vật, bảng nhân vật)", r"player_frame"),
    (r"Interface\\GMGameInterface_Script_(DataPool|Character)\.cpp$|Interface\\GMGameInterface_Script\.cpp$|Interface\\GMGameInterface\.cpp$|Interface\\NGInterface\.cpp$", "MỘT PHẦN", "ui/panel + face/gui", r"face/ui|ui::"),
    (r"Interface\\GMGameInterface_Script_Package\.cpp$", "MỘT PHẦN", "ui/panel/packet.cpp (khung hành trang, mọi ô trống)", r"packet"),
    (r"Interface\\GMInterface_Script_SystemSetup\.cpp$", "MỘT PHẦN", "ui/panel/system_info (các trang cài đặt là khung)", r"system_info"),
    (r"Interface\\GMGameInterface_Script_(Martial|LifeAbility)\.cpp$", "MỘT PHẦN", "book/skill (sách võ công, kỹ năng sống)", r"namespace game::skill"),
    (r"Interface\\GMGameinterface_Script_GameProduceLogin\.cpp$", "CÓ", "ui/panel login_flow, logon, select_server, select_role, create_role", r"LoginFlow"),
    (r"Interface\\GMInterface_Script_Talk\.cpp$|Interface\\GMInterface_Script_Tooltip\.cpp$", "CHƯA CÓ", "chat và tooltip chưa có", None),
    (r"Interface\\", "CHƯA CÓ", "cửa sổ/script của tính năng này chưa có", None),
    (r"Item\\GMItem_(Equip|Gem)\.cpp$", "MỘT PHẦN", "figure/look/weapon (vũ khí 7 khe, đá quý, hiệu ứng đồ); không có hệ vật phẩm", r"gem_effect"),
    (r"Item\\", "CHƯA CÓ", "hệ vật phẩm chưa có", None),
    (r"KaJi\\", "CHƯA CÓ", "chưa có", None),
    (r"Network\\PacketHandler\\", "CHƯA CÓ", "client chưa mở socket, chưa có handler gói", None),
    (r"Object\\Character\\Ai\\GMAI_MySelf\.cpp$", "MỘT PHẦN", "đi bằng nhấp chuột + tìm đường (figure/control, shared/nav)", r"PathFinder|nav::"),
    (r"Object\\Character\\Ai\\", "CHƯA CÓ", "AI chưa có", None),
    (r"Object\\Character\\(Obj_Character|Obj_Character_Logic|Obj_PlayerMySelf)\.cpp$", "MỘT PHẦN", "figure/avatar + app/client/display/player", r"PlayerActor"),
    (r"Object\\Obj_Building\.cpp$", "MỘT PHẦN", "vật thể công trình + va chạm .WCollision", r"WCollision"),
    (r"Object\\", "CHƯA CÓ", "đối tượng này (NPC, người chơi khác, xe, đạn, vòng chọn, quản lý đối tượng) chưa có", None),
    (r"Procedure\\(CharacterFaceMng|FaceModelMng|HairModelMng)\.cpp$", "CÓ", "figure/look (mặt, tóc)", r"FaceRow|HairRow"),
    (r"Procedure\\GamePro_(Login|CharSel|CharCreate)\.cpp$", "CÓ", "ui/panel login/chọn nhân vật/tạo nhân vật (không máy chủ)", r"SelectRole|CreateRole"),
    (r"Procedure\\GamePro_Camera\.cpp$", "CÓ", "figure/control camera (port mã máy)", r"FollowCamera|CharCamera"),
    (r"Procedure\\(GamePro_Main|GameProcedure)\.cpp$", "MỘT PHẦN", "app/client (boot, màn chơi không máy chủ)", r"boot"),
    (r"Script\\GMScriptSystm\.cpp$", "KHÁC THIẾT KẾ", "không nhúng Lua; script dịch sang C++ + trọng tài", r"lua_oracle|oracle"),
    (r"Sound\\GMNewSoundSystem\.cpp$", "MỘT PHẦN", "engine/audio miniaudio, nhạc nền theo cảnh", r"audio"),
    (r"TDFunction\.cpp$|Timer\.cpp$", "MỘT PHẦN", "engine/core", r"FixedStep"),
    (r"TransferItem\\", "CHƯA CÓ", "chuyển vật phẩm chưa có", None),
    (r"Variable\\", "KHÁC THIẾT KẾ", "app/client/options (cờ dòng lệnh) thay cho hệ biến", r"Options"),
    (r"World\\Path\.cpp$", "CÓ", "shared/nav (.path, tìm đường)", r"nav::"),
    (r"World\\(Scene|WorldManager)\.cpp$", "MỘT PHẦN", "place/scene + app/client/world", r"SceneFile"),
    (r"World\\Zone\.cpp$|WorldReference\\", "CHƯA CÓ", "vùng (zone) và tham chiếu thế giới chưa có", None),
]


def compare_sources(corpus):
    _, rows = read_tsv(DUMP / "sources.tsv")
    out = []
    for path, functions, first, last in rows:
        status, note, probe_used = "CHƯA CÓ", "không có quy tắc ghép", ""
        for pattern, st, counterpart, probe in FILE_RULES:
            if re.search(pattern, path, re.I):
                status, note = st, counterpart
                if probe is not None:
                    hits = grep(corpus, probe, re.I, 1)
                    probe_used = f"probe {probe!r}: " + ("thấy " + hits[0] if hits else "KHÔNG thấy")
                    if not hits and st in ("CÓ", "MỘT PHẦN", "KHÁC THIẾT KẾ"):
                        status, note = "CHƯA CÓ", f"{counterpart} — nhưng probe không thấy trong mã"
                break
        out.append([path, functions, first, last, status, note, probe_used])
    write_tsv("tep-nguon.tsv", ["file", "functions", "first_fn", "last_fn", "status", "counterpart_or_reason", "probe"], out)
    return out


# --- 5. Lua API ------------------------------------------------------------------------------------------------------------

TOKEN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
ADDRESS = re.compile(r"0x1[34][0-9a-fA-F]{7}\b")


def split_code_comment(text: str) -> tuple[str, str]:
    """Tách một tệp C++ thành phần mã và phần chú thích `//` (đủ cho so khớp tên; không xử lý `//` trong chuỗi)."""
    code, comment = [], []
    for line in text.splitlines():
        position = line.find("//")
        if position < 0:
            code.append(line)
        else:
            code.append(line[:position])
            comment.append(line[position:])
    return "\n".join(code), "\n".join(comment)


def compare_lua(corpus):
    """Mỗi hàm script (bảng, tên) của bản gốc, một hàng. Bằng chứng theo bậc, từ mạnh đến yếu:
      ĐÃ PORT       địa chỉ cài đặt của hàm (impl) xuất hiện trong mã hay chú thích của src/client|src/shared: đã đọc và dịch hàm đó.
      CÓ TÊN (MÃ)   tên script là một định danh trong phần MÃ (không phải chú thích) của src/client|src/shared: có thể trùng tên ngẫu nhiên.
      CHÚ THÍCH     tên chỉ xuất hiện trong chú thích: mới nhắc, chưa chắc có.
      CHỈ TRỌNG TÀI tên chỉ có trong TOOLS/port/oracle/*.lua (giả lập cho số vàng, không phải mã client).
      CHƯA CÓ       không thấy ở đâu."""
    api = [row for row in read_tsv(DUMP / "lua_api.tsv")[1]]
    client = {k: v for k, v in corpus.items() if k.startswith(("src/client", "src/shared"))}
    code_tokens: set[str] = set()
    comment_tokens: set[str] = set()
    address_text = []
    for text in client.values():
        code, comment = split_code_comment(text)
        code_tokens.update(TOKEN.findall(code))
        comment_tokens.update(TOKEN.findall(comment))
        address_text.append(text)
    cited = {a.lower() for a in ADDRESS.findall("\n".join(address_text))}
    oracle_tokens: set[str] = set()
    for path in (REPO / "TOOLS" / "port" / "oracle").glob("*.lua"):
        oracle_tokens.update(TOKEN.findall(path.read_text(encoding="utf-8", errors="replace")))
    out = []
    for table, globals_, name, impl, impl_kind, how, register_fn, label, source_file, note in api:
        if impl.lower() in cited:
            status, why = "ĐÃ PORT", "địa chỉ cài đặt có trong src/client|src/shared"
        elif name in code_tokens:
            status, why = "CÓ TÊN (MÃ)", "tên là định danh trong mã client (có thể trùng ngẫu nhiên)"
        elif name in comment_tokens:
            status, why = "CHÚ THÍCH", "tên chỉ có trong chú thích"
        elif name in oracle_tokens:
            status, why = "CHỈ TRỌNG TÀI", "tên chỉ có trong TOOLS/port/oracle/*.lua"
        else:
            status, why = "CHƯA CÓ", "không thấy"
        out.append([table, name, status, why, impl, impl_kind, label, source_file])
    write_tsv("lua-api.tsv", ["table", "name", "status", "evidence", "impl", "impl_kind", "error_label", "source_file"], out)
    summary = collections.defaultdict(collections.Counter)
    for row in out:
        summary[row[0]][row[2]] += 1
    globals_of = {row[0]: row[1] for row in read_tsv(DUMP / "lua_tables.tsv")[1]}
    statuses = ["ĐÃ PORT", "CÓ TÊN (MÃ)", "CHÚ THÍCH", "CHỈ TRỌNG TÀI", "CHƯA CÓ"]
    tables = []
    for table in sorted(globals_of, key=str.lower):
        counts = summary.get(table, collections.Counter())
        tables.append([table, globals_of[table], sum(counts.values())] + [counts.get(s, 0) for s in statuses])
    write_tsv("lua-bang.tsv", ["table", "lua_globals", "functions"] + statuses, tables)
    return out


# --- 5b. địa chỉ Game.exe mà mã và tài liệu của dự án trích dẫn --------------------------------------------------------------
CITE_ROOTS = ["src", "engine", "TOOLS", "docs", "TAILIEU", "Test", "android", "apple", "cmake", "CMakeLists.txt", "AGENTS.md"]
CITE_EXT = {".cpp", ".hpp", ".h", ".mm", ".md", ".py", ".lua", ".tsv", ".cmake", ".txt", ".java", ".kt"}
CITE_SKIP = ("TAILIEU/GAME-EXE-2026/", "TAILIEU/ghidra/", "docs/KHOI-PHUC-2026-10-09/", "docs/AUDIT/evidence/", "TOOLS/port/rea/", "/__pycache__/", "build/", ".worktrees/")
NAME_BEFORE = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)[ (:]*$")


def check_citations():
    """Mọi địa chỉ 0x14xxxxxxx trong mã/tài liệu của dự án được đối với Game.exe, ba lớp:
      1. vị trí: đầu hàm (có trong dump), trong hàm (theo .pdata, phạm vi chính xác do trình liên kết ghi), dữ liệu, hay ngoài ảnh/khe giữa đoạn;
      2. ranh giới lệnh: địa chỉ trong hàm phải là đầu một lệnh. Quét lệnh bằng capstone từ đầu phạm vi .pdata; địa chỉ rơi GIỮA một lệnh
         thì không thể là mốc mã (đã gặp: một địa chỉ cách đầu hàm 0x40 byte, quét từ đó ra `add byte ptr [rax], al`);
      3. tên đi kèm: nếu ngay trước địa chỉ là tên một hàm script Lua đã biết thì ghi impl của script đó để người đọc đối chiếu.
    Cần Game.exe (WORK/client) và capstone; thiếu thì lớp 2 ghi KHÔNG KIỂM ĐƯỢC."""
    _, functions = read_tsv(DUMP / "functions.tsv")
    internal = sorted((int(row[0], 16), row) for row in functions if row[1] != "external")
    keys = [a for a, _ in internal]
    image = PeImage(WORK / "client" / "Game.exe")
    try:
        from capstone import CS_ARCH_X86, CS_MODE_64, Cs
        disassembler = Cs(CS_ARCH_X86, CS_MODE_64)
    except ImportError:
        disassembler = None
    pdata = sorted(image.runtime_functions())
    pdata_begin = [begin for begin, _ in pdata]
    _, api = read_tsv(DUMP / "lua_api.tsv")
    impls: dict[str, set[str]] = collections.defaultdict(set)
    for row in api:
        impls[row[2]].add(row[3])
    segments = json.loads((DUMP / "overview.json").read_text(encoding="utf-8"))["segments"]
    ranges = [(s["name"], int(s["start"], 16), int(s["end"], 16)) for s in segments if 0x140000000 <= int(s["start"], 16) < 0x150000000]
    image_end = max(r[2] for r in ranges)
    sweeps: dict[int, tuple[list[int], int]] = {}

    def sweep(begin: int, end: int) -> tuple[list[int], int]:
        """Địa chỉ đầu mọi lệnh trong [begin, end) và địa chỉ cuối cùng quét tới (dừng sớm nếu gặp byte không giải mã được)."""
        if begin not in sweeps:
            starts, covered = [], begin
            for instruction in disassembler.disasm(image.read(begin, end - begin), begin):
                starts.append(instruction.address)
                covered = instruction.address + instruction.size
            sweeps[begin] = (starts, covered)
        return sweeps[begin]

    def boundary(value: int, begin: int, end: int) -> tuple[str, str]:
        if disassembler is None or not image.data:
            return "KHÔNG KIỂM ĐƯỢC", "thiếu capstone hoặc Game.exe"
        starts, covered = sweep(begin, end)
        if value in set(starts):
            return "RANH GIỚI LỆNH", ""
        if covered > value:
            at = starts[bisect.bisect_right(starts, value) - 1]
            return "GIỮA LỆNH", f"lệnh chứa nó bắt đầu ở {at:#x} (sớm hơn {value - at} byte)"
        return "KHÔNG KIỂM ĐƯỢC", f"quét dừng ở {covered:#x} (byte không giải mã được)"

    out = []
    for root in CITE_ROOTS:
        base = REPO / root
        files = [base] if base.is_file() else (p for p in base.rglob("*") if p.is_file()) if base.exists() else []
        for path in files:
            rel = path.relative_to(REPO).as_posix()
            if path.suffix.lower() not in CITE_EXT or any(skip in rel for skip in CITE_SKIP) or rel.startswith("build/"):
                continue
            try:
                lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
            except OSError:
                continue
            for number, line in enumerate(lines, 1):
                for match in ADDRESS.finditer(line):
                    address = match.group(0).lower()
                    value = int(address, 16)
                    before = NAME_BEFORE.search(line[:match.start()])
                    mention = before.group(1) if before else ""
                    script = f"script {mention}: impl {','.join(sorted(impls[mention]))}" if mention in impls else ""
                    row = [rel, number, address, mention, None, None, None, None, script]

                    def finish(kind, boundary_kind, detail, verdict):
                        row[4:8] = [kind, boundary_kind, detail, verdict]
                        out.append(row)

                    if value >= image_end or value < 0x140000000:
                        finish("NGOÀI ẢNH", "", f"ngoài 0x140000000..{image_end:#x} của Game.exe", "CẦN XEM")
                        continue
                    segment = next((name for name, start, end in ranges if start <= value < end), None)
                    if segment is None:
                        finish("KHE GIỮA ĐOẠN", "", "không thuộc đoạn nào của Game.exe (đệm giữa hai đoạn)", "CẦN XEM")
                        continue
                    if segment != ".text":
                        finish(f"DỮ LIỆU {segment}", "", "", "OK")
                        continue
                    index = bisect.bisect_right(keys, value) - 1
                    entry_value, entry = internal[index]
                    slot = bisect.bisect_right(pdata_begin, value) - 1
                    in_pdata = slot >= 0 and pdata[slot][0] <= value < pdata[slot][1]
                    if entry_value == value:
                        finish("ĐẦU HÀM", "RANH GIỚI LỆNH", entry[0], "OK")
                    elif in_pdata:
                        begin, end = pdata[slot]
                        kind_of_boundary, why = boundary(value, begin, end)
                        owner = internal[bisect.bisect_right(keys, begin) - 1][0]
                        detail = f"hàm {owner:#x}+{value - owner:#x}; .pdata [{begin:#x},{end:#x})" + (f"; {why}" if why else "")
                        finish("TRONG HÀM", kind_of_boundary, detail, "OK" if kind_of_boundary == "RANH GIỚI LỆNH" else "CẦN XEM")
                    else:
                        end_hint = int(entry[4], 16) if entry[4] else entry_value
                        if value < end_hint:
                            kind_of_boundary, why = boundary(value, entry_value, end_hint)
                            finish("TRONG HÀM (không có .pdata)", kind_of_boundary, f"hàm {entry_value:#x}+{value - entry_value:#x}" + (f"; {why}" if why else ""), "OK" if kind_of_boundary == "RANH GIỚI LỆNH" else "CẦN XEM")
                        else:
                            finish("KHÔNG THUỘC HÀM", "", f"hàm trước {entry_value:#x} kết thúc khoảng {end_hint:#x}, không có .pdata ở đây", "CẦN XEM")
    write_tsv("dia-chi-trich-dan.tsv", ["file", "line", "address", "mention", "kind", "boundary", "detail", "verdict", "lua_script"], [
        [r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8]] for r in out])
    return out


# --- 6. import theo DLL ----------------------------------------------------------------------------------------------------
DLL_MAP = {
    "MSVCR110.DLL": ("KHÔNG ÁP DỤNG", "CRT MSVC 2012 của bản gốc; dự án dựng với CRT hiện đại"),
    "MSVCP110.DLL": ("KHÔNG ÁP DỤNG", "STL MSVC 2012"),
    "KERNEL32.DLL": ("CÓ", "engine/core, engine/fs, engine/jobs, engine/window (gọi Win32 trực tiếp hoặc qua SDL3)"),
    "USER32.DLL": ("CÓ", "engine/window (SDL3 + Win32)"),
    "ADVAPI32.DLL": ("CHƯA CÓ", "ký hiệu ADVAPI32 chưa có quy tắc ghép"),
    "TENGINE.DLL": ("KHÁC THIẾT KẾ", "engine nội bộ của TLBB (122 import, 115 ký hiệu khác nhau) không còn trên đĩa; dự án tự viết engine/ (gpu, render, scene) và port logic từ TLBB Dev"),
    "LUAPLUS.DLL": ("KHÁC THIẾT KẾ", "Lua của bản gốc; client dự án không nhúng Lua"),
    "FMOD64.DLL": ("KHÁC THIẾT KẾ", "FMOD; dự án dùng miniaudio và định dạng .tla"),
    "WS2_32.DLL": ("MỘT PHẦN", "engine/net có socket TCP; client chưa gọi"),
    "CRYPT32.DLL": ("KHÁC THIẾT KẾ", "chứng chỉ/mã hoá Windows; dự án dùng libsodium"),
    "WLDAP32.DLL": ("KHÔNG ÁP DỤNG", "LDAP, kéo theo bởi WinINet/Crypt32 của bản gốc"),
    "WININET.DLL": ("KHÁC THIẾT KẾ", "HTTP của bản gốc; các nút web mở trang 'Coming soon' ngoài trình duyệt"),
    "OLE32.DLL": ("KHÔNG ÁP DỤNG", "COM"), "OLEAUT32.DLL": ("KHÔNG ÁP DỤNG", "COM"),
    "SHLWAPI.DLL": ("CÓ", "xử lý đường dẫn: std::filesystem"),
    "VERSION.DLL": ("KHÔNG ÁP DỤNG", "đọc phiên bản tệp"),
    "IPHLPAPI.DLL": ("CHƯA CÓ", "lấy địa chỉ mạng/MAC (định danh máy)"),
    "IMM32.DLL": ("KHÁC THIẾT KẾ", "IME: SDL3 text input + bàn phím ảo của dự án"),
    "WINMM.DLL": ("CÓ", "engine/core thời gian"),
}


# Quy tắc theo ký hiệu, thử trước DLL_MAP: cùng một DLL có ký hiệu thay bằng thư viện khác, có ký hiệu không áp dụng.
SYMBOL_RULES = [
    ("ADVAPI32.DLL", r"^Crypt", "KHÁC THIẾT KẾ", "CryptoAPI (băm, mã hoá, ký) của bản gốc; dự án dùng libsodium (shared/secure)"),
    ("ADVAPI32.DLL", r"^Reg", "KHÔNG ÁP DỤNG", "registry; dự án không dùng registry (cấu hình là TOML/CLI)"),
    ("ADVAPI32.DLL", r"EventLog|EventSource|ReportEvent", "KHÔNG ÁP DỤNG", "ghi nhật ký sự kiện Windows; dự án ghi log tệp/console (core::Log)"),
    ("ADVAPI32.DLL", r"Privilege|OpenProcessToken", "KHÔNG ÁP DỤNG", "nâng quyền tiến trình (kiểu crash-dump/anti-cheat của bản gốc)"),
    ("SHELL32.DLL", r"^ShellExecute", "MỘT PHẦN", "mở trang web/tệp ngoài; nút web của dự án mở trang 'Coming soon' (kOpenWeb)"),
    ("BCRYPT.DLL", r"^BCryptGenRandom", "KHÁC THIẾT KẾ", "số ngẫu nhiên mật mã; dự án dùng libsodium randombytes"),
]


def compare_imports():
    _, rows = read_tsv(DUMP / "imports.tsv")
    out = []
    for address, dll, symbol in rows:
        rule = next(((st, why) for d, pattern, st, why in SYMBOL_RULES if d == dll.upper() and re.search(pattern, symbol)), None)
        status, note = rule or DLL_MAP.get(dll.upper(), ("CHƯA CÓ", "DLL chưa có quy tắc ghép"))
        out.append([address, dll, symbol, status, note])
    write_tsv("import-dll.tsv", ["address", "dll", "symbol", "status", "reason"], out)
    return out


# --- 7. "Khác gốc:" đã ghi trong mã -------------------------------------------------------------------------------------------

def collect_declared_deviations():
    out = []
    for root in ("src", "engine", "TOOLS", "cmake", "Test"):
        for path in (REPO / root).rglob("*"):
            if not path.is_file() or path.suffix.lower() not in {".cpp", ".hpp", ".h", ".py", ".cmake", ".mm"}:
                continue
            rel = path.relative_to(REPO).as_posix()
            if "/rea/" in rel or "__pycache__" in rel:
                continue
            try:
                lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
            except OSError:
                continue
            for number, line in enumerate(lines, 1):
                position = line.find("Khác gốc")
                if position >= 0:
                    text = line[position:].strip()
                    # nối các dòng chú thích liền sau để không cụt câu
                    follow = number
                    while follow < len(lines) and lines[follow].lstrip().startswith(("//", "#")) and "Khác gốc" not in lines[follow] and follow - number < 4:
                        text += " " + lines[follow].lstrip("/# ").strip()
                        follow += 1
                    out.append([rel, number, deviation_kind(text), text[:600]])
    write_tsv("lech-da-ghi.tsv", ["file", "line", "kind", "text"], out)
    return out


def deviation_kind(text: str) -> str:
    """Phân loại thô theo từ khoá trong câu "Khác gốc:"; chỉ để đếm, không thay việc đọc từng dòng."""
    if re.search(r"\bchưa\b|\bthiếu\b|\bbỏ\b|không (có|giữ|port|vẽ|hiện)", text):
        return "thiếu phần của bản gốc"
    if re.search(r"(mã gốc|bản gốc|gốc).{0,80}(tràn|không kiểm|ném|assert|chia cho 0|đọc ra|nil|ngoại lệ|không trần|dùng số chưa|đệ quy)|trần|kẹp|kiểm", text):
        return "chặt hơn/an toàn hơn bản gốc"
    if re.search(r"namespace|luật|vòng lặp|struct|gom thành|viết thành hàm|đặt tên|enumerator", text):
        return "hình thức/kiến trúc (không đổi hành vi)"
    return "khác"


# --- 8. mục còn mở của NGHI-NGO ------------------------------------------------------------------------------------------------

def collect_open_suspicions():
    text = (REPO / "docs" / "NGHI-NGO.md").read_text(encoding="utf-8")
    items = re.split(r"\n(?=\d+\. \*\*)", text)
    out = []
    for item in items:
        match = re.match(r"(\d+)\. \*\*(.+?)\*\*", item, re.S)
        if not match:
            continue
        closed = bool(re.search(r"Đã đóng|đã đóng|ĐÃ ĐÓNG", item[:400]))
        out.append([match.group(1), "ĐÃ ĐÓNG" if closed else "MỞ", re.sub(r"\s+", " ", match.group(2))[:220]])
    write_tsv("nghi-ngo-mo.tsv", ["no", "status", "title"], out)
    return out


# --- 9. đối chiếu dump thủ công cũ với dump tự động -------------------------------------------------------------------------------

def check_login_packet_doc():
    text = (REPO / "TAILIEU" / "GOI-TIN-DANG-NHAP.md").read_text(encoding="utf-8")
    sections = re.split(r"\n## Packets::", text)[1:]
    _, packets = read_tsv(DUMP / "packets.tsv")
    auto = {row[0]: row for row in packets}
    out = []
    for section in sections:
        name = section.split("\n", 1)[0].strip()
        manual = []
        for match in re.finditer(r"đọc gói \+ (0x[0-9a-fA-F]+|\d+) cỡ (0x[0-9a-fA-F]+|\d+)", section):
            manual.append((int(match.group(1), 0), int(match.group(2), 0)))
        row = auto.get(name)
        if row is None:
            out.append([name, "THIẾU Ở DUMP TỰ ĐỘNG", len(manual), "", ""])
            continue
        fields = [tuple(int(part, 16 if i == 0 else 10) for i, part in enumerate(item.split(":"))) for item in row[12].split()] if row[12] else []
        same = manual == fields
        out.append([name, "KHỚP" if same else ("DUMP TỰ ĐỘNG KHÔNG PHẲNG: " + row[4] if row[4] != "flat" else "LỆCH"), len(manual), len(fields), row[1]])
    write_tsv("kiem-goi-dang-nhap.tsv", ["class", "result", "manual_fields", "auto_fields", "packet_id"], out)
    return out


# --- 9b. tài nguyên PE ------------------------------------------------------------------------------------------------------
RT_NAMES = {1: "RT_CURSOR", 3: "RT_ICON", 4: "RT_MENU", 5: "RT_DIALOG", 6: "RT_STRING", 9: "RT_ACCELERATOR", 12: "RT_GROUP_CURSOR",
            14: "RT_GROUP_ICON", 16: "RT_VERSION", 24: "RT_MANIFEST"}


def compare_resources(corpus):
    """Tài nguyên PE của Game.exe (resources.json). Con trỏ: so id nhóm với bảng RESOURCES của export_cursors.py. Loại khác: dò mã."""
    data = json.loads((DUMP / "resources.json").read_text(encoding="utf-8"))
    exporter = (REPO / "TOOLS" / "content" / "export_cursors.py").read_text(encoding="utf-8")
    block = exporter[exporter.index("RESOURCES:"):exporter.index("class CursorError")]
    used = {int(value, 16) for value in re.findall(r'\("[a-z_]+",\s*(0x[0-9A-Fa-f]+)\)', block)}
    # .rc chỉ của Windows: tìm ở nguồn client/engine, không quét android/apple (cây build Gradle rất lớn)
    rc_files = [p for root in ("src", "engine", "cmake") for p in (REPO / root).rglob("*.rc")]
    rc_text = "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in rc_files)
    rc_name = rc_files[0].relative_to(REPO).as_posix() if rc_files else ""
    has_version = "VERSIONINFO" in rc_text
    icon_count = len(re.findall(r"^\s*\w+\s+ICON\b", rc_text, re.M))
    manifest_code = grep(corpus, r"\.manifest\b|/MANIFEST|RT_MANIFEST|<assembly", re.I, 1)
    rows = []
    for item in data["resources"]:
        type_id = item["type"].get("id")
        name = item["name"].get("id", item["name"].get("name", "?"))
        size = item["payload"]["location"]["bytes"]
        label = RT_NAMES.get(type_id, f"loại {type_id}")
        if type_id == 12:
            if name in used:
                status, why = "CÓ", "export_cursors.py xuất nhóm này (CursorKind trong control/cursor_rules.hpp)"
            else:
                status, why = "CHƯA CÓ", "CCursorMng::Initial của bản gốc không nạp nhóm này; chưa thấy chỗ nào khác của bản gốc dùng nó"
        elif type_id == 1:
            status, why = "THEO NHÓM", "ảnh con trỏ đơn lẻ, thuộc một RT_GROUP_CURSOR"
        elif type_id == 3:
            status, why = "THEO NHÓM", "ảnh icon đơn lẻ, thuộc một RT_GROUP_ICON"
        elif type_id == 14:
            status, why = (("MỘT PHẦN", f"{rc_name} khai {icon_count} icon (client, thanh tiêu đề); chưa so ảnh với hai nhóm icon của bản gốc") if icon_count
                           else ("CHƯA CÓ", "không có tài nguyên ICON"))
        elif type_id == 16:
            status, why = (("CÓ", f"{rc_name} có VERSIONINFO") if has_version
                           else ("CHƯA CÓ", "dự án không có tài nguyên VERSIONINFO (bản gốc: FileVersion 0,85,0,0, Changyou)"))
        elif type_id == 24:
            status, why = (("MỘT PHẦN", f"có manifest ({manifest_code[0]})") if manifest_code
                           else ("CHƯA CÓ", "không thấy manifest Windows (bản gốc: asInvoker, uiAccess=false)"))
        else:
            status, why = "CHƯA CÓ", "dự án không đọc loại tài nguyên này; nội dung chưa giải mã"
        rows.append([label, name, size, status, why])
    write_tsv("tai-nguyen-pe.tsv", ["type", "id", "bytes", "status", "evidence"], rows)
    return rows


# --- 10. báo cáo SO-SANH.md -----------------------------------------------------------------------------------------------------

EXTRAS = [
    ("Bốn backend đồ hoạ (Vulkan, D3D12, D3D11, OpenGL/GLES) và lớp `gpu`; bản gốc chỉ có Direct3D 9 trong Render.dll", "engine/gpu"),
    ("Chạy trên Android arm64 (vỏ `android/`) và iOS arm64 (vỏ `apple/`); bản gốc chỉ Windows", "android"),
    ("Âm thanh miniaudio + định dạng .tla và Opus; bản gốc dùng FMOD", "engine/audio"),
    ("Bắt tay và bản ghi mã hoá bằng libsodium (`shared/secure`); bản gốc dùng MD5 + khoá tĩnh", "src/shared/secure"),
    ("Giao thức tự thiết kế, có phiên bản và danh mục sinh từ bảng (`shared/protocol`); bản gốc 1 367 gói viết tay", "src/shared/protocol"),
    ("Bảy exe máy chủ dưới trình giám sát, cấu hình TOML, PostgreSQL (`src/server`); bản gốc không có phía máy chủ trong Game.exe", "src/server"),
    ("Bản địa hoá dựng cùng client (zh/vi/en) từ `assets/i18n`; bản gốc chỉ tiếng Trung", "assets/i18n"),
    ("Bảng đo nhịp khung `ui/pace` luôn hiện ở màn chơi; bản gốc không có", "src/client/face/ui/pace.cpp"),
    ("Cần gạt và cử chỉ chạm cho điện thoại (`figure/control`); bản gốc chỉ chuột và phím", "src/client/figure/control"),
    ("Bố cục layout điện thoại `Interface/phone/` và texture ASTC/ETC2", "src/client"),
    ("Công cụ chụp ảnh khung (`--shot`) và công cụ thử `--weapon`, `--skill`, `--gem`, `--auto-strike`", "src/client/app"),
    ("Trọng tài Lua (`lua_oracle.py`) sinh số vàng từ script gốc chạy trên LuaPlus.dll của bản gốc", "TOOLS/port/lua_oracle.py"),
    ("Chuỗi công cụ phân tích Game.exe (REA/Ghidra) và bản trích đầy đủ trong TAILIEU/GAME-EXE-2026", "TOOLS/port/rea"),
]


def names(items, limit=None):
    shown = items if limit is None else items[:limit]
    return ", ".join(f"`{item}`" for item in shown)


def by_group(rows, key_index, name_index):
    groups: dict[str, list[str]] = collections.defaultdict(list)
    for row in rows:
        groups[row[key_index]].append(row[name_index])
    return groups


def short_source(path: str) -> str:
    return re.sub(r"^(?:client\\game\\|Client\\Game\\)", "", path, flags=re.I)


def write_report(tables, packets, classes, sources, lua, imports, deviations, suspicions, logins, citations, resources):
    out: list[str] = []
    add = out.append
    count = collections.Counter
    t_tab, t_pkt, t_cls, t_src, t_lua, t_imp = (count(r[2] for r in tables), count(r[4] for r in packets), count(r[4] for r in classes),
                                                  count(r[4] for r in sources), count(r[2] for r in lua), count(r[3] for r in imports))
    cite_total = len(citations)
    cite_bad = [r for r in citations if r[7] == "CẦN XEM"]
    cite_mid = [r for r in citations if r[5] == "GIỮA LỆNH"]
    dev_kind = count(r[2] for r in deviations)

    add("# So sánh Game.exe 2026 với client hiện tại — đã có, chưa có, sai")
    add("")
    add("Sinh bằng `TOOLS/port/rea/compare_client.py` từ bản trích `TAILIEU/GAME-EXE-2026` và mã hiện tại; không sửa tay. Mỗi mục của bản gốc "
        "có một hàng trong các bảng ở `so-sanh/*.tsv` (đủ từng mục, kể cả nhỏ nhất); tệp này là bản đọc được của cùng dữ liệu.")
    add("")
    add("## 0. Cách đọc và độ tin cậy")
    add("")
    add("- **CÓ**: có bản đối ứng đã chạy. **MỘT PHẦN**: có nhưng thiếu phần của bản gốc. **CHƯA CÓ**: không thấy bản đối ứng. **KHÁC THIẾT KẾ**: dự án chủ ý làm cách khác. "
        "**KHÔNG ÁP DỤNG**: SDK bên thứ ba hay hạ tầng chỉ của bản gốc.")
    add("- Phép so là phép KHỚP BẰNG CHỨNG, không phải đọc từng hàm: tệp dữ liệu so theo tên tệp đủ đuôi trong công cụ xuất (`TOOLS/content`); lớp và tệp nguồn so bằng "
        "quy tắc thủ công, mỗi quy tắc có `probe` tự kiểm trong mã hiện tại (probe không thấy thì hạ về CHƯA CÓ); gói tin so theo bảng tương đương chức năng "
        "(client chưa mở socket nên không gói nào có handler); Lua so theo tên hàm script và địa chỉ cài đặt. Nhóm của gói tin suy từ TỪ KHOÁ trong tên, "
        "không phải từ nội dung.")
    add("- 57 200 hàm và 56 190 chuỗi không so từng cái: chúng được phủ gián tiếp qua lớp, tệp nguồn, gói tin, tệp dữ liệu và Lua ở trên. Muốn so một hàm cụ thể "
        "thì tra `decompile.zip` rồi đọc mã.")
    add("- `Game.exe` đã trích là tệp của dự án Ghidra TLBB (cùng SHA-256), nhưng mã và tài liệu của dự án trích địa chỉ của ít nhất hai bản dựng (mục 4.2): "
        "đừng dùng địa chỉ trong mã/tài liệu của dự án để tra thẳng vào bản trích.")
    add("")
    add("## 1. Tổng hợp số")
    add("")
    add("| Nhóm | Tổng | CÓ | MỘT PHẦN | KHÁC THIẾT KẾ | KHÔNG ÁP DỤNG | CHƯA CÓ | Tệp chi tiết |")
    add("|---|---|---|---|---|---|---|---|")
    add(f"| Tệp dữ liệu client đọc | {len(tables)} | {t_tab['CÓ']} | 0 | 0 | {t_tab['KHÔNG SO ĐƯỢC']} (mẫu định dạng) | {t_tab['CHƯA CÓ']} | `bang-du-lieu.tsv` |")
    add(f"| Gói tin `Packets::*` | {len(packets)} | 0 | {t_pkt['MỘT PHẦN']} | 0 | 0 | {t_pkt['CHƯA CÓ']} | `goi-tin.tsv` |")
    add(f"| Lớp RTTI (không phải gói tin) | {len(classes)} | {t_cls['CÓ']} | {t_cls['MỘT PHẦN']} | {t_cls['KHÁC THIẾT KẾ']} | {t_cls['KHÔNG ÁP DỤNG']} | {t_cls['CHƯA CÓ']} | `lop.tsv` |")
    add(f"| Tệp nguồn gốc (suy từ assert) | {len(sources)} | {t_src['CÓ']} | {t_src['MỘT PHẦN']} | {t_src['KHÁC THIẾT KẾ']} | {t_src['KHÔNG ÁP DỤNG']} | {t_src['CHƯA CÓ']} | `tep-nguon.tsv` |")
    add(f"| Hàm script Lua | {len(lua)} | ĐÃ PORT {t_lua['ĐÃ PORT']} | CÓ TÊN (MÃ) {t_lua['CÓ TÊN (MÃ)']} + CHÚ THÍCH {t_lua['CHÚ THÍCH']} | | CHỈ TRỌNG TÀI {t_lua['CHỈ TRỌNG TÀI']} | {t_lua['CHƯA CÓ']} | `lua-api.tsv`, `lua-bang.tsv` |")
    add(f"| Import (DLL) | {len(imports)} | {t_imp['CÓ']} | {t_imp['MỘT PHẦN']} | {t_imp['KHÁC THIẾT KẾ']} | {t_imp['KHÔNG ÁP DỤNG']} | {t_imp['CHƯA CÓ']} | `import-dll.tsv` |")
    res_group = count(r[3] for r in resources if r[0] in ("RT_GROUP_CURSOR", "RT_GROUP_ICON", "RT_MENU", "RT_DIALOG", "RT_STRING", "RT_ACCELERATOR", "RT_VERSION", "RT_MANIFEST"))
    add(f"| Tài nguyên PE (nhóm) | {sum(res_group.values())} | {res_group['CÓ']} | {res_group['MỘT PHẦN']} | 0 | 0 | {res_group['CHƯA CÓ']} | `tai-nguyen-pe.tsv` |")
    add("")
    add(f"Sai/lệch: {len(cite_bad)} trên {cite_total} địa chỉ Game.exe trích dẫn trong mã và tài liệu của dự án không khớp bản trích (`dia-chi-trich-dan.tsv`); "
        f"{len(deviations)} chỗ mã tự ghi \"Khác gốc:\" (`lech-da-ghi.tsv`); {sum(1 for s in suspicions if s[1] == 'MỞ')} mục còn mở trong `docs/NGHI-NGO.md` (`nghi-ngo-mo.tsv`); "
        f"gói đăng nhập: {count(r[1] for r in logins)['KHỚP']}/{len(logins)} khớp dump tự động (`kiem-goi-dang-nhap.tsv`).")
    add("")

    # --- 2. ĐÃ CÓ ---
    add("## 2. Đã có")
    add("")
    add("### 2.1 Lớp của bản gốc có bản đối ứng")
    add("")
    for status in ("CÓ", "MỘT PHẦN"):
        add(f"**{status}** ({t_cls[status]} lớp):")
        add("")
        groups: dict[str, list[str]] = collections.defaultdict(list)
        for row in classes:
            if row[4] == status:
                groups[row[5]].append(row[0])
        for counterpart, items in sorted(groups.items(), key=lambda kv: -len(kv[1])):
            add(f"- {names(sorted(items))} — {counterpart}")
        add("")
    add(f"**KHÁC THIẾT KẾ** ({t_cls['KHÁC THIẾT KẾ']} lớp; dự án chủ ý làm khác):")
    add("")
    groups = collections.defaultdict(list)
    for row in classes:
        if row[4] == "KHÁC THIẾT KẾ":
            groups[row[5]].append(row[0])
    for counterpart, items in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        add(f"- {len(items)} lớp — {counterpart}: {names(sorted(items)[:12])}" + (f" và {len(items) - 12} lớp khác" if len(items) > 12 else ""))
    add("")
    add("### 2.2 Tệp nguồn gốc có bản đối ứng")
    add("")
    for status in ("CÓ", "MỘT PHẦN", "KHÁC THIẾT KẾ", "KHÔNG ÁP DỤNG"):
        rows = [r for r in sources if r[4] == status]
        if not rows:
            continue
        add(f"**{status}** ({len(rows)} tệp):")
        add("")
        for row in rows:
            add(f"- `{short_source(row[0])}` ({row[1]} hàm) — {row[5]}")
        add("")
    add("### 2.3 Tệp dữ liệu (bảng, cảnh...) đã được công cụ xuất hoặc gom")
    add("")
    have = sorted({r[0] for r in tables if r[2] == "CÓ"})
    add(f"{t_tab['CÓ']} mục ({len(have)} tên khác nhau; một số tên xuất hiện ở hai địa chỉ trong Game.exe): " + names(have))
    add("")
    add("### 2.4 Gói tin có tương đương chức năng (client chưa nối, máy chủ có; định dạng dự án khác bản gốc)")
    add("")
    for row in packets:
        if row[4] == "MỘT PHẦN":
            add(f"- `{row[0]}` (opcode {row[1]}) — {row[5].split(': ', 1)[1]}")
    add("")
    add("### 2.5 Hàm script Lua đã có dấu vết trong client")
    add("")
    for status in ("ĐÃ PORT", "CÓ TÊN (MÃ)", "CHÚ THÍCH", "CHỈ TRỌNG TÀI"):
        rows = [r for r in lua if r[2] == status]
        add(f"**{status}** ({len(rows)}): " + (", ".join(f"`{r[0]}.{r[1]}`" for r in rows) if rows else "không có"))
        add("")
    add("`ĐÃ PORT` là bằng chứng mạnh nhất (địa chỉ cài đặt của hàm có trong mã/chú thích của client); `CÓ TÊN (MÃ)` có thể trùng tên ngẫu nhiên "
        "(tên chung như `GetLevel`); `CHÚ THÍCH` chỉ mới nhắc; `CHỈ TRỌNG TÀI` chỉ có ở giả lập `TOOLS/port/oracle/*.lua`, không phải mã client.")
    add("")
    add("### 2.6 Import (DLL) đã có thay thế")
    add("")
    by_dll = collections.defaultdict(count)
    for row in imports:
        by_dll[row[1]][row[3]] += 1
    for dll, tally_ in sorted(by_dll.items(), key=lambda kv: -sum(kv[1].values())):
        reason = next(r[4] for r in imports if r[1] == dll)
        add(f"- `{dll}` ({sum(tally_.values())} import: " + ", ".join(f"{k} {v}" for k, v in tally_.items()) + f") — {reason}")
    add("")
    add("### 2.6b Tài nguyên PE")
    add("")
    for row in resources:
        if row[3] in ("CÓ", "MỘT PHẦN"):
            add(f"- {row[0]} id {row[1]} ({row[2]} byte) — {row[3]}: {row[4]}")
    add("")
    add("### 2.7 Dự án có mà bản gốc không có")
    add("")
    for label, probe in EXTRAS:
        present = (REPO / probe).exists()
        add(f"- {label}" + ("" if present else f" — **cảnh báo: `{probe}` không còn**"))
    add("")

    # --- 3. CHƯA CÓ ---
    add("## 3. Chưa có")
    add("")
    add(f"### 3.1 Gói tin chưa có ({t_pkt['CHƯA CÓ']})")
    add("")
    add("Client chưa mở socket nào, nên mọi gói đều chưa có handler. Danh sách theo nhóm (nhóm suy từ từ khoá trong tên; mỗi gói có opcode, kích thước, trường trong `goi-tin.tsv` và `packets.tsv`):")
    add("")
    groups = collections.defaultdict(list)
    for row in packets:
        if row[4] == "CHƯA CÓ":
            groups[row[3]].append(row[0])
    for group, items in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        add(f"- **{group}** ({len(items)}): " + names(sorted(items)))
    add("")
    add(f"### 3.2 Tệp dữ liệu chưa có ({t_tab['CHƯA CÓ']})")
    add("")
    nothing = [r for r in tables if r[2] == "CHƯA CÓ" and r[3].startswith("không có mã")]
    mention = [r for r in tables if r[2] == "CHƯA CÓ" and r[3].startswith("chỉ nhắc")]
    scene = [r for r in tables if r[2] == "CHƯA CÓ" and r[3].startswith("chưa gom")]
    add(f"- Không có mã hay công cụ nào nhắc tên ({len(nothing)}): " + names(sorted(r[0] for r in nothing)))
    add(f"- Chỉ nhắc tên trong mã hoặc chú thích, không có công cụ xuất ({len(mention)}): " + names(sorted(r[0] for r in mention)))
    add(f"- Cảnh `.Scene` chưa gom vào `dev/client/assets/Scene` ({len(scene)}): " + names(sorted(r[0] for r in scene)))
    add(f"- Không so được ({t_tab['KHÔNG SO ĐƯỢC']}, mẫu định dạng hay đường dẫn chung): " + names(sorted(r[0] for r in tables if r[2] == "KHÔNG SO ĐƯỢC")))
    add("")
    add(f"### 3.3 Lớp chưa có ({t_cls['CHƯA CÓ']})")
    add("")
    groups = collections.defaultdict(list)
    for row in classes:
        if row[4] == "CHƯA CÓ":
            groups[row[5]].append(row[0])
    for reason, items in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        add(f"- ({len(items)}) {reason}: " + names(sorted(items)))
    add("")
    add(f"### 3.4 Tệp nguồn chưa có ({t_src['CHƯA CÓ']})")
    add("")
    groups = collections.defaultdict(list)
    for row in sources:
        if row[4] == "CHƯA CÓ":
            groups[row[5]].append(f"{short_source(row[0])} ({row[1]} hàm)")
    for reason, items in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        add(f"- ({len(items)}) {reason}: " + names(sorted(items)))
    add("")
    add(f"### 3.5 Hàm script Lua chưa có ({t_lua['CHƯA CÓ']} trên {len(lua)})")
    add("")
    add("Bản gốc đăng ký các hàm script này cho giao diện Lua (script chạy trong CEGUI). Dự án không nhúng Lua: script được dịch sang C++ ở `ui/panel` (28 bảng). "
        "Bảng dưới là số hàm theo bảng/đối tượng Lua; từng hàm có hàng riêng trong `lua-api.tsv` (kèm địa chỉ cài đặt, nhãn lỗi `LUA:`, tệp nguồn) và từng bảng trong `lua-bang.tsv`.")
    add("")
    _, lua_tables = read_tsv(OUT / "lua-bang.tsv")
    add("| Bảng Lua | Biến toàn cục | Hàm | ĐÃ PORT | CÓ TÊN | CHÚ THÍCH | CHỈ TRỌNG TÀI | CHƯA CÓ |")
    add("|---|---|---|---|---|---|---|---|")
    for row in sorted(lua_tables, key=lambda r: -int(r[2])):
        add(f"| `{row[0]}` | {row[1]} | {row[2]} | {row[3]} | {row[4]} | {row[5]} | {row[6]} | {row[7]} |")
    add("")
    add("### 3.6 Import chưa có thay thế")
    add("")
    for row in imports:
        if row[3] == "CHƯA CÓ":
            add(f"- `{row[1]}::{row[2]}` — {row[4]}")
    add("")
    add("### 3.7 Tài nguyên PE chưa dùng")
    add("")
    for row in resources:
        if row[3] == "CHƯA CÓ":
            add(f"- {row[0]} id {row[1]} ({row[2]} byte) — {row[4]}")
    add("")

    # --- 4. SAI / LỆCH ---
    add("## 4. Sai và lệch")
    add("")
    add("### 4.1 Đã sửa trong lượt này (kiểm bằng bản trích)")
    add("")
    add("- `TAILIEU/GOI-TIN-DANG-NHAP.md`: `LCRetCreateChar` (opcode 440) và `LCRetDeleteChar` (707) ghi sai hàm `Read` và kích thước; đã sửa theo `FUN_14077de90` (đọc +0x18, 4 byte, `GetPacketSize` 4) và ghi chú giới hạn của `packet_fields.py` (hàm `Read` dùng chung chỉ hiện ở lớp đầu tiên).")
    add("- `AGENTS.md`: danh mục protocol ghi 22 tin version 2; thực tế 27 tin version 3 của năm nhóm (`docs/PROTOCOL-TIN.md`, `kVersion` = 3).")
    add("- `src/client/book/skill/actions.hpp`, `TOOLS/port/oracle/skill_api.lua`: bảng tên loại action ghi `0x140ed78d0` (nằm ngoài mọi đoạn), đúng là `0x140ed88d0` (16 con trỏ chuỗi `skill`, `life`, `packageitem`... đọc từ byte).")
    add("- `src/client/book/skill/actions.hpp`, `TOOLS/port/oracle/skill_api.lua`: `IsLMSJSecond`/`IsJYJYSecond`/`IsWJQFSecond` ghi `0x14023f8f0`/`0x14023f980`/`0x14023fa10`, đúng là `0x14023fdf0`/`0x14023fe80`/`0x14023ff10` (bảng id 821..826, 827..834 ở `0x140b1f8f4`, `0x140b1fa54`; hàm cuối so với 0x1171 và 0x1172).")
    add("- `src/client/figure/motion/jump.hpp`: `CObject_Character::Jump` ghi bắt đầu ở `0x1405ea2f0` (giữa một lệnh); đúng là `0x1405ea2b0` (đã khớp `gait.hpp` và `docs/TIEN-DO.md`).")
    add("")
    add("### 4.2 Địa chỉ Game.exe trích dẫn trong mã và tài liệu không khớp bản đã trích")
    add("")
    add(f"Đối chiếu {cite_total} địa chỉ `0x14xxxxxxx` trong `src`, `engine`, `TOOLS`, `docs`, `TAILIEU`, `Test` với `Game.exe` (SHA-256 `3f8bb47de0bc...`): "
        f"quét lệnh bằng capstone theo phạm vi hàm của `.pdata`. Kết quả: {sum(1 for r in citations if r[4] == 'ĐẦU HÀM')} đầu hàm, "
        f"{sum(1 for r in citations if r[4].startswith('TRONG HÀM') and r[5] == 'RANH GIỚI LỆNH')} nằm trong hàm đúng ranh giới lệnh, "
        f"**{len(cite_mid)} nằm GIỮA một lệnh** (không thể là mốc mã), {sum(1 for r in citations if r[4].startswith('DỮ LIỆU'))} trỏ vào dữ liệu, "
        f"{sum(1 for r in citations if r[4] in ('KHE GIỮA ĐOẠN', 'NGOÀI ẢNH', 'KHÔNG THUỘC HÀM'))} ngoài mọi đoạn/hàm (trước khi sửa ở mục 4.1 có 2).")
    add("")
    aligned = sum(1 for r in cite_mid if int(r[2], 16) % 16 == 0)
    add(f"Trong {len(cite_mid)} địa chỉ giữa lệnh, {aligned} chia hết cho 16 — dạng địa chỉ ĐẦU HÀM của một bố cục khác. Hai bằng chứng nghiêng về hai hướng: "
        "(a) `IsLMSJSecond`, `IsJYJYSecond`, `IsWJQFSecond` nội dung đúng bản này (bảng id khớp) nhưng địa chỉ trích lệch đúng 0x500 so với hàm trong bản trích; "
        "(b) `docs/AUDIT/evidence/jump_re.log` tháo `0x1405ea2f0` ra `add byte ptr [rax], al`, tức byte tại đó giống bản này và địa chỉ trích sai từ đầu. "
        "Đo thêm 2026-10-15: một phần địa chỉ là đầu hàm của bản dựng 2026-08-11 (`D:\\XTLBB\\Bin64\\Game.exe`, 3.71.9509), vài địa chỉ là offset tệp "
        "viết nhầm thành địa chỉ ảo (thiếu 0xc00), phần còn lại chưa giải thích được: số đo và lệnh ở `docs/NGHI-NGO.md` mục 53.")
    add("")
    add("Số địa chỉ giữa lệnh theo tệp (từng địa chỉ: `dia-chi-trich-dan.tsv`, cột `detail` ghi lệnh chứa nó bắt đầu ở đâu):")
    add("")
    per_file = count(r[0] for r in cite_mid)
    for path, number in per_file.most_common():
        add(f"- `{path}`: {number}")
    add("")
    client_dev = [r for r in deviations if r[0].startswith(("src/client", "src/shared", "TOOLS/", "Test/"))]
    other_dev = [r for r in deviations if r not in client_dev]
    add(f"### 4.3 Chỗ mã tự ghi \"Khác gốc:\" ({len(deviations)})")
    add("")
    add("\"Gốc\" tuỳ chỗ: ở `src/client`, `src/shared`, `TOOLS`, `Test` là client 2026 hay TLBB Dev (port); ở `engine/` là mã chép từ Forge2 "
        "(`docs/NGUON-FORGE2.md`); ở `src/server` là bản máy chủ gốc suy ra. Chỉ nhóm đầu CÓ THỂ là lệch so với Game.exe (chưa đọc từng dòng để loại những dòng nói về nguồn khác như TLBB Dev hay PathLib). Mỗi mục là một chỗ mã tự nói là lệch "
        "(đủ từng dòng, kèm câu giải thích, ở `lech-da-ghi.tsv`; cột `kind` là phân loại thô theo từ khoá, chỉ để đếm).")
    add("")
    add(f"- Lệch so với client 2026/TLBB Dev: **{len(client_dev)}** — " + ", ".join(f"{k} {v}" for k, v in count(r[2] for r in client_dev).most_common()))
    add(f"- Lệch so với Forge2 hay nguồn khác (không phải Game.exe): {len(other_dev)} — " + ", ".join(f"`{k}` {v}" for k, v in count("/".join(r[0].split("/")[:2]) for r in other_dev).most_common()))
    add("")
    add("Lệch so với client 2026/TLBB Dev theo thư mục:")
    add("")
    for path, number in count("/".join(r[0].split("/")[:4]) for r in client_dev).most_common():
        add(f"- `{path}`: {number}")
    add("")
    add("### 4.4 Mục còn mở trong `docs/NGHI-NGO.md`")
    add("")
    for row in suspicions:
        if row[1] == "MỞ":
            add(f"- {row[0]}. {row[2]}")
    add("")
    add("### 4.5 Gói đăng nhập: tài liệu thủ công so với dump tự động")
    add("")
    for row in logins:
        add(f"- `{row[0]}` (opcode {row[4]}): {row[1]} ({row[2]} trường thủ công, {row[3]} trường tự động)")
    add("")
    add("## 5. Giới hạn của bản so này")
    add("")
    add("- Gói tin chỉ phân nhóm theo từ khoá của tên; không so định dạng trường với `src/shared/protocol` (hai giao thức không cùng định dạng).")
    add("- Lớp và tệp nguồn do quy tắc thủ công ghép: một lớp rơi vào quy tắc rộng có thể ghép nhầm trạng thái (mỗi hàng ghi quy tắc và probe).")
    add("- Hàm script Lua so theo tên và địa chỉ; `CÓ TÊN (MÃ)` có thể trùng tên ngẫu nhiên; chưa so chữ ký hay hành vi từng hàm.")
    add("- Chuỗi tiếng Trung (GBK) của bản gốc chưa giải mã; 5 hàm lớn nhất (mã nạp bảng, hàm đăng ký Lua lớn) chỉ có disassembly; mọi lần đăng ký Lua của hàm lớn nhất (`0x1406557c0`, hơn 5 700 lần) đọc từ disassembly bằng bộ giải riêng (`game_exe_dump.py lua`), kiểm chéo bằng nhãn lỗi `LUA:` (660 hàm) và bằng 5 887 định danh của `lua_register.tsv` (còn 21 định danh không phải tên hàm: biến cấu hình, tên sự kiện).")
    add("- Không có dữ liệu thời gian chạy: so tĩnh, chưa chạy bản gốc để đối chiếu hành vi.")
    add("")
    (DUMP / "SO-SANH.md").write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")


# --- tổng hợp -------------------------------------------------------------------------------------------------------------

def tally(rows, index):
    return collections.Counter(row[index] for row in rows)


def main() -> int:
    corpus = load_corpus()
    print(f"corpus client: {len(corpus)} tệp, {sum(len(v) for v in corpus.values()) // 1024} KB")
    tables = compare_data_files(corpus)
    packets = compare_packets()
    classes = compare_classes(corpus)
    sources = compare_sources(corpus)
    lua = compare_lua(corpus)
    imports = compare_imports()
    deviations = collect_declared_deviations()
    suspicions = collect_open_suspicions()
    logins = check_login_packet_doc()
    citations = check_citations()
    resources = compare_resources(corpus)
    write_report(tables, packets, classes, sources, lua, imports, deviations, suspicions, logins, citations, resources)
    summary = {
        "bang_du_lieu": dict(tally(tables, 2)),
        "goi_tin": dict(tally(packets, 4)),
        "goi_tin_theo_nhom": dict(tally(packets, 3)),
        "lop": dict(tally(classes, 4)),
        "tep_nguon": dict(tally(sources, 4)),
        "lua_api": dict(tally(lua, 2)),
        "import": dict(tally(imports, 3)),
        "tai_nguyen_pe": dict(tally(resources, 3)),
        "khac_goc_da_ghi": len(deviations),
        "khac_goc_theo_loai": dict(tally(deviations, 2)),
        "nghi_ngo": dict(tally(suspicions, 1)),
        "kiem_goi_dang_nhap": dict(tally(logins, 1)),
        "dia_chi_trich_dan": {"tong": len(citations), "theo_loai": dict(collections.Counter(f"{r[4]} / {r[5]}" for r in citations)),
                              "can_xem": sum(1 for r in citations if r[7] == "CẦN XEM")},
    }
    (OUT / "tong-hop.json").write_text(json.dumps(summary, ensure_ascii=False, indent=1), encoding="utf-8", newline="\n")
    print(json.dumps(summary, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
