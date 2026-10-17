# Kiểm bộ trích Lua: phân tích cú pháp, đại số điều kiện, hạ hàm, rút nhiệm vụ, bố cục bảng client.
# Các ca dùng script tổng hợp nên chạy không cần G:\XJL7457; ca dữ liệu thật tự bỏ qua khi thiếu.
from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import lua_api as A
import lua_bool as B
import lua_flow as F
import lua_npc as N
import lua_quest as Q
import lua_syntax as S
import lua_tables as T
import lua_units as U
import lua_world as W

TABLES = ROOT.parents[1] / "dev" / "server" / "tables"
DATA_TAIL = "XJL7457/Server/rootfs/home/tlbb/Public/Data"


def find_real_lua() -> Path:
    """Thư mục dữ liệu XJL7457 nếu có trên máy (đặt XJL7457_DATA để chỉ rõ); không thấy thì Path rỗng."""
    named = os.environ.get("XJL7457_DATA")
    if named:
        return Path(named)
    for letter in "GFDE":
        candidate = Path(f"{letter}:/{DATA_TAIL}")
        if candidate.is_dir():
            return candidate
    return Path()


REAL_LUA = find_real_lua()

QUEST_SCRIPT = """
--MisDescBegin
x900001_g_ScriptId = 900001
x900001_g_MissionId = 77
x900001_g_Name = "Lão Tư"
x900001_g_MissionLevel = 10
x900001_g_MoneyBonus = 500
x900001_g_DemandKill = { { id = 1234, name = "Sói", num = 3 } }
x900001_g_ItemBonus = { { id = 10410001, num = 1 } }
function x900001_OnEnumerate( sceneId, selfId, targetId )
  if GetName( sceneId, targetId ) == x900001_g_Name then
    AddNumText( sceneId, x900001_g_ScriptId, "Nhiệm vụ", 3, -1 )
  end
end
function x900001_CheckAccept( sceneId, selfId )
  if GetLevel( sceneId, selfId ) < x900001_g_MissionLevel then
    return 0
  end
  return 1
end
function x900001_OnAccept( sceneId, selfId )
  AddMission( sceneId, selfId, x900001_g_MissionId, x900001_g_ScriptId, 0, 0, 0 )
end
function x900001_CheckSubmit( sceneId, selfId )
  local misIndex = GetMissionIndexByID( sceneId, selfId, x900001_g_MissionId )
  if GetMissionParam( sceneId, selfId, misIndex, 0 ) == 1 then
    return 1
  end
  return 0
end
function x900001_OnSubmit( sceneId, selfId, targetId, selectRadioId )
  if x900001_CheckSubmit( sceneId, selfId ) == 1 then
    AddMoney( sceneId, selfId, x900001_g_MoneyBonus )
    LuaFnAddExp( sceneId, selfId, 900 )
    DelMission( sceneId, selfId, x900001_g_MissionId )
    MissionCom( sceneId, selfId, x900001_g_MissionId )
  end
end
function x900001_OnAbandon( sceneId, selfId )
  DelMission( sceneId, selfId, x900001_g_MissionId )
end
function x900001_OnKillObject( sceneId, selfId, objdataId, objId )
  if GetName( sceneId, objId ) == "Sói" then
    local misIndex = GetMissionIndexByID( sceneId, selfId, x900001_g_MissionId )
    local count = GetMissionParam( sceneId, selfId, misIndex, 1 )
    if count < 3 then
      SetMissionByIndex( sceneId, selfId, misIndex, 1, count + 1 )
    end
  end
end
"""


def lowerer_for(text: str) -> tuple[F.Lowerer, F.Unit]:
    low = F.Lowerer({}, {}, A.API)
    unit = U.load_unit(900001, "event/test/q.lua", text, low)
    low.units[900001] = unit
    return low, unit


class ScriptDatTests(unittest.TestCase):
    """Script.dat: chú thích `;` sau đường dẫn không được dính vào đường dẫn (N0: 147 mục từng bị bỏ)."""

    def test_trailing_comment_is_not_part_of_the_path(self) -> None:
        text = "005117=\\event\\jinghu\\ejinghu_Boss_1.lua ;comment\n401000=\\event\\fuben\\a.lua\t; ghi chú\n"
        found = U.read_script_dat(text)
        self.assertEqual(found[5117], "event/jinghu/ejinghu_Boss_1.lua")
        self.assertEqual(found[401000], "event/fuben/a.lua")

    def test_comment_lines_and_plain_lines_still_work(self) -> None:
        text = "; cả dòng là chú thích\n\n000001=\\obj\\x.lua\nthiếu dấu bằng\nabc=\\bad.lua\n"
        self.assertEqual(U.read_script_dat(text), {1: "obj/x.lua"})


class SyntaxTests(unittest.TestCase):
    def test_upvalue_prefix_and_c_style_not_equal(self) -> None:
        tree = S.parse("local a = 1\nfunction f()\n  local b = %a\n  if b != 2 then b = 3 end\nend\n")
        self.assertEqual(len(tree), 2)

    def test_old_for_in_over_table(self) -> None:
        tree = S.parse("function f()\n for i, item in t do x = item.id end\nend\n")
        self.assertIsInstance(tree[0], S.FuncDef)

    def test_syntax_error_reports_line(self) -> None:
        with self.assertRaises(S.LuaSyntaxError) as raised:
            S.parse("if a = 1 then end")
        self.assertIn("dòng 1", str(raised.exception))


class BoolTests(unittest.TestCase):
    def test_ordered_atoms_contradict(self) -> None:
        low = B.atom("level_at_least", 40)
        high = B.b_not(B.atom("level_at_least", 30))
        self.assertTrue(B.is_false(B.b_and(low, high)))

    def test_ordered_atoms_collapse(self) -> None:
        both = B.b_and(B.atom("level_at_least", 20), B.atom("level_at_least", 30))
        self.assertEqual(both, B.atom("level_at_least", 30))

    def test_two_exact_values_exclude_each_other(self) -> None:
        self.assertTrue(B.is_false(B.b_and(B.atom("sect_is", 1), B.atom("sect_is", 2))))

    def test_double_negation(self) -> None:
        cond = B.b_or(B.atom("quest_done", 5), B.atom("item_count_at_least", 9, 1))
        self.assertEqual(B.b_not(B.b_not(cond)), cond)


class QuestExtractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.low, self.unit = lowerer_for(QUEST_SCRIPT)
        self.rec = Q.extract(self.low, self.unit, "event/test/q.lua")

    def test_clean_extraction(self) -> None:
        self.assertEqual(self.rec.issues, [])
        self.assertEqual(self.rec.quest, 77)
        self.assertEqual(self.rec.repeat, "once")

    def test_accept_condition_is_level_gate(self) -> None:
        self.assertEqual(self.rec.accept_cond, B.atom("level_at_least", 10))

    def test_ready_condition_has_progress_objective(self) -> None:
        self.assertEqual(self.rec.objectives, [(0, "progress", 0, 1)])

    def test_rewards_split_money_and_exp(self) -> None:
        kinds = sorted((r.kind, r.count) for r in self.rec.rewards)
        self.assertEqual(kinds, [("exp", 900), ("money", 500)])

    def test_kill_hook_increments_counter(self) -> None:
        self.assertEqual(len(self.rec.hooks), 1)
        event, effects = self.rec.hooks[0]
        self.assertEqual(event, "kill")
        ops = [step.data for _, step in effects]
        self.assertEqual(ops, [("objective_add", 77, 1, 1)])
        guard = effects[0][0]
        names = {item.op for clause in guard for item in clause}
        self.assertIn("event_monster_name", names)

    def test_unknown_api_is_reported_not_dropped(self) -> None:
        text = QUEST_SCRIPT.replace("LuaFnAddExp( sceneId, selfId, 900 )", "SomeUnknownApi( sceneId )")
        low, unit = lowerer_for(text)
        rec = Q.extract(low, unit, "q.lua")
        self.assertTrue(any("SomeUnknownApi" in issue for issue in rec.issues))


NPC_SCRIPT = """
x901001_g_ScriptId = 901001
x901001_g_Lines = { "Một", "Hai", "Ba" }
function x901001_OnDefaultEvent( sceneId, selfId, targetId )
  BeginEvent( sceneId )
    local pick = random( getn( x901001_g_Lines ) )
    AddText( sceneId, x901001_g_Lines[pick] )
    AddNumText( sceneId, x901001_g_ScriptId, "Hết" )
    SetPos( sceneId, selfId, 10, 20 )
    BeginUICommand( sceneId )
    UICommand_AddInt( sceneId, targetId )
    UICommand_AddInt( sceneId, 5 )
    EndUICommand( sceneId )
    DispatchUICommand( sceneId, selfId, 1000 )
    CallScriptFunction( 999999, "OnEnumerate", sceneId, selfId, targetId )
  EndEvent( sceneId )
  DispatchEventList( sceneId, selfId, targetId )
end
"""


def npc_flow(text: str, script_id: int = 901001) -> F.Flow:
    low = F.Lowerer({}, {}, A.API)
    unit = U.load_unit(script_id, "obj/test/n.lua", text, low)
    low.units[script_id] = unit
    func = Q.func_of(unit, "OnDefaultEvent")
    return low.lower(unit, func.name, low.entry_args(func, -1))


class DialogueApiTests(unittest.TestCase):
    """AddNumText mặc định, random chọn chữ, SetPos, lệnh giao diện và gọi tới script không có."""

    def setUp(self) -> None:
        self.steps = npc_flow(NPC_SCRIPT).root

    def test_random_text_becomes_pick_of_n_texts(self) -> None:
        kinds = [step.kind for step in self.steps]
        self.assertEqual(kinds[:6], ["begin", "pick", "text", "text", "text", "option"])
        self.assertEqual(self.steps[1].data, (3,))
        self.assertEqual([step.text for step in self.steps[2:5]], ["Một", "Hai", "Ba"])

    def test_add_num_text_defaults_icon_and_value_to_minus_one(self) -> None:
        self.assertEqual(self.steps[5].data, (901001, -1, -1))

    def test_set_pos_is_a_same_scene_teleport(self) -> None:
        effects = [step.data for step in self.steps if step.kind == "effect"]
        self.assertIn(("teleport", -1, 10, 20), effects)

    def test_ui_command_keeps_id_and_marks_the_npc(self) -> None:
        effects = [step.data for step in self.steps if step.kind == "effect"]
        self.assertIn(("ui_command", 1000, -1, 5), effects)

    def test_call_to_missing_script_is_a_noted_noop(self) -> None:
        notes = [step.data for step in self.steps if step.kind == "note"]
        self.assertTrue(any("999999" in note[0] for note in notes))
        self.assertEqual(self.steps[-1].kind, "dispatch")

    def test_random_outside_a_text_table_stays_unsupported(self) -> None:
        branch = "if pick == 1 then AddText( sceneId, 'x' ) end"
        text = NPC_SCRIPT.replace("AddText( sceneId, x901001_g_Lines[pick] )", branch)
        with self.assertRaises(F.Unsupported):
            npc_flow(text)

    def test_ui_command_with_a_string_stays_unsupported(self) -> None:
        text = NPC_SCRIPT.replace("UICommand_AddInt( sceneId, 5 )", "UICommand_AddString( sceneId, 'a' )")
        with self.assertRaises(F.Unsupported):
            npc_flow(text)


NESTED_IF_SCRIPT = """
x901002_g_ScriptId = 901002
function x901002_OnDefaultEvent( sceneId, selfId, targetId )
  BeginEvent( sceneId )
  local IsNew = GetMissionFlag( sceneId, selfId, 5 )
  if IsNew == 0 then
    AddText( sceneId, "a" )
  elseif IsNew == 1 then
    if GetLevel( sceneId, selfId ) >= 10 and GetMenPai( sceneId, selfId ) == 9 then
      AddText( sceneId, "b" )
    else
      AddText( sceneId, "c" )
    end
  end
  AddNumText( sceneId, x901002_g_ScriptId, "opt", 1, 5 )
  EndEvent( sceneId )
  DispatchEventList( sceneId, selfId, targetId )
end
"""


HELD_QUEST_SCRIPT = """
x901003_g_ScriptId = 901003
function x901003_OnDefaultEvent( sceneId, selfId, targetId )
  BeginEvent( sceneId )
  AddText( sceneId, "x" )
  local held = GetScriptIDByMissionID( sceneId, selfId, 101 )
  if held ~= -1 then
    local name = TGetMissionName( held )
    if name ~= "阿碧任务" and IsMissionHaveDone( sceneId, selfId, 15 ) > 0 then
      AddNumText( sceneId, x901003_g_ScriptId, "阿碧任务", 3, 1 )
    end
  elseif IsMissionHaveDone( sceneId, selfId, 15 ) > 0 then
    AddNumText( sceneId, x901003_g_ScriptId, "阿碧任务", 3, 1 )
  end
  EndEvent( sceneId )
  DispatchEventList( sceneId, selfId, targetId )
end
"""


def atoms_of(steps: list) -> list:
    """Mọi nguyên tử điều kiện (op, đối số) của các nhánh trong `steps`, đi sâu vào hai nhánh."""
    found = []
    for step in steps:
        if step.kind != "branch":
            continue
        found += [(atom.op, atom.args) for clause in step.cond for atom in clause]
        found += atoms_of(step.then or []) + atoms_of(step.other or [])
    return found


class HeldQuestTests(unittest.TestCase):
    """GetScriptIDByMissionID + TGetMissionName: mẫu nhiệm vụ vòng của 12 NPC Lạc Dương, Tô Châu, Đại Lý..."""

    def test_held_quest_and_its_name_become_closed_atoms(self) -> None:
        atoms = atoms_of(npc_flow(HELD_QUEST_SCRIPT, 901003).root)
        self.assertIn(("quest_active", (101,)), atoms)
        self.assertIn(("quest_named", (101, "阿碧任务")), atoms)
        self.assertIn(("quest_done", (15,)), atoms)

    def test_held_script_is_only_compared_with_minus_one(self) -> None:
        text = HELD_QUEST_SCRIPT.replace("held ~= -1", "held ~= 1039250")
        with self.assertRaises(F.Unsupported):
            npc_flow(text, 901003)

    def test_mission_name_needs_a_held_script(self) -> None:
        text = HELD_QUEST_SCRIPT.replace("TGetMissionName( held )", "TGetMissionName( 1039250 )")
        with self.assertRaises(F.Unsupported):
            npc_flow(text, 901003)


EVENT_REQUEST_SCRIPT = """
x901004_g_ScriptId = 901004
function x901004_OnDefaultEvent( sceneId, selfId, targetId )
  BeginEvent( sceneId )
  AddText( sceneId, "root" )
  AddNumText( sceneId, x901004_g_ScriptId, "shop", 7, 5 )
  EndEvent( sceneId )
  DispatchEventList( sceneId, selfId, targetId )
end
function x901004_OnEventRequest( sceneId, selfId, targetId, eventId )
  if eventId == x901004_g_ScriptId and GetNumText() == 5 then
    BeginEvent( sceneId )
    AddText( sceneId, "shop opened" )
    EndEvent( sceneId )
    DispatchEventList( sceneId, selfId, targetId )
  end
end
"""


class CapturingSerializer:
    """Thay bộ ghi bảng: giữ luồng bước của từng điểm vào để kiểm hàm Lua nào được hạ."""

    def __init__(self) -> None:
        self.flows: dict = {}

    def flow_root(self, flow: F.Flow, owner: str) -> int:
        self.flows[owner] = flow
        return len(self.flows)


def texts_of(flow: F.Flow) -> list:
    return [step.text for step in N.all_steps(flow) if step.kind == "text"]


class EventRequestTests(unittest.TestCase):
    """Mục của chính NPC chạy OnEventRequest (eventId là script của mục, GetNumText() là chỉ số), lần bấm vào NPC
    chạy OnDefaultEvent."""

    def walk(self, npc_scripts: frozenset) -> CapturingSerializer:
        low = F.Lowerer({}, {}, A.API)
        unit = U.load_unit(901004, "obj/test/n.lua", EVENT_REQUEST_SCRIPT, low)
        low.units[901004] = unit
        serializer = CapturingSerializer()
        walker = N.Walker(low, serializer, npc_scripts)
        walker.seed(901004, -1)
        walker.run()
        self.assertEqual(walker.entries[(901004, 5)].status, "ok")
        return serializer

    def test_own_option_of_an_npc_runs_on_event_request(self) -> None:
        serializer = self.walk(frozenset({901004}))
        self.assertEqual(texts_of(serializer.flows["901004:-1"]), ["root"])
        self.assertEqual(texts_of(serializer.flows["901004:5"]), ["shop opened"])

    def test_script_that_is_not_an_npc_keeps_on_default_event(self) -> None:
        serializer = self.walk(frozenset())
        self.assertEqual(texts_of(serializer.flows["901004:5"]), ["root"])


LOOP_SCRIPT = """
x901005_g_ScriptId = 901005
function x901005_OnDefaultEvent( sceneId, selfId, targetId )
  BeginEvent( sceneId )
  for i = 1, 3 do
    if GetLevel( sceneId, selfId ) >= 10 * i then
      AddText( sceneId, "in loop" )
    end
  end
  AddText( sceneId, "after loop" )
  EndEvent( sceneId )
  DispatchEventList( sceneId, selfId, targetId )
end
"""

FAULT_SCRIPT = """
x901006_g_ScriptId = 901006
x901006_Info = { { name = "甲", mis = 8 }, { name = "乙", mis = 15 } }
function x901006_OnEnumerate( sceneId, selfId, targetId )
  local szName = GetName( sceneId, targetId )
  local nIndex = 0
  for i = 1, 2 do
    if szName == x901006_Info[i].name then
      nIndex = i
    end
  end
  if IsMissionHaveDone( sceneId, selfId, x901006_Info[nIndex].mis ) > 0 then
    AddNumText( sceneId, x901006_g_ScriptId, "交谈", 0, 1 )
  end
end
"""

ADD_ITEM_SCRIPT = """
x901007_g_ScriptId = 901007
x901007_Items = { { id = 111, num = 1 }, { id = 222, num = 2 } }
function x901007_OnSubmit( sceneId, selfId, targetId, selectRadioId )
  BeginAddItem( sceneId )
  for i, item in x901007_Items do
    if item.id == selectRadioId then
      AddItem( sceneId, item.id, item.num )
    end
  end
  local ret = EndAddItem( sceneId, selfId )
  if ret > 0 then
    AddItemListToHuman( sceneId, selfId )
  end
end
"""


def lower_named(text: str, script_id: int, name: str, keep: list | None = None) -> F.Flow:
    low = F.Lowerer({}, {}, A.API)
    unit = U.load_unit(script_id, "obj/test/n.lua", text, low)
    low.units[script_id] = unit
    func = Q.func_of(unit, name)
    flow = low.lower(unit, func.name, low.entry_args(func, -1))
    if keep is not None:
        keep.append(low)
    return flow


class LoopContinuationTests(unittest.TestCase):
    """Lỗi cũ: câu lệnh sau một vòng `for` có `if` tượng trưng chạy tiếp từ khối ban đầu, nên không được chạy trên
    đường nào."""

    def test_statement_after_a_loop_with_symbolic_ifs_is_reached(self) -> None:
        flow = lower_named(LOOP_SCRIPT, 901005, "OnDefaultEvent")
        paths = leaf_paths(flow, flow.root)
        self.assertTrue(paths)
        for path in paths:
            self.assertEqual(path[-1], "dispatch")
            self.assertIn("dispatch", path)
        texts = [step.text for step in N.all_steps(flow) if step.kind == "text"]
        self.assertIn("after loop", texts)


class IndexByConditionTests(unittest.TestCase):
    """bảng[giá trị theo điều kiện] thành Choice; lá nil là lỗi Lua nên có nhánh `if lỗi then return end` đứng
    trước câu lệnh."""

    def test_nil_leaf_becomes_a_guarded_return(self) -> None:
        flow = lower_named(FAULT_SCRIPT, 901006, "OnEnumerate")
        branches = [step for step in N.all_steps(flow) if step.kind == "branch"]
        guards = [step for step in branches if step.then and [s.kind for s in step.then] == ["ret"]]
        self.assertEqual(len(guards), 1)
        atoms = {(atom.op, atom.neg, atom.args) for clause in guards[0].cond for atom in clause}
        self.assertEqual(atoms, {("target_name", True, ("甲",)), ("target_name", True, ("乙",))})
        later = [(atom.op, atom.args) for step in branches for clause in step.cond for atom in clause]
        self.assertIn(("quest_done", (8,)), later)
        self.assertIn(("quest_done", (15,)), later)

    def test_the_option_follows_only_the_matching_name(self) -> None:
        flow = lower_named(FAULT_SCRIPT, 901006, "OnEnumerate")
        options = [step for step in N.all_steps(flow) if step.kind == "option"]
        self.assertEqual(len(options), 1)


class AddItemPathTests(unittest.TestCase):
    """AddItem trong nhánh `item.id == selectRadioId` là phần thưởng chọn của nhánh đó, không phải thưởng cố định."""

    def test_each_item_carries_its_own_radio_guard(self) -> None:
        kept: list = []
        flow = lower_named(ADD_ITEM_SCRIPT, 901007, "OnSubmit", kept)
        found = {}
        effects: list = []
        Q.walk_effects(kept[0], flow.root, lambda atom: None, effects, B.TRUE, [])
        for guard, step in effects:
            found[step.data[1]] = {(atom.op, atom.args) for clause in guard for atom in clause}
        self.assertEqual(set(found), {111, 222})
        self.assertIn(("radio_is", (111,)), found[111])
        self.assertIn(("radio_is", (222,)), found[222])


def leaf_paths(flow: F.Flow, steps: list, prefix: tuple = ()) -> list:
    """Mọi đường chạy từ `steps` tới hết luồng, mỗi đường là bộ loại bước đã đi qua (theo goto và nhánh)."""
    paths = []
    here = prefix
    for index, step in enumerate(steps):
        if step.kind == "branch":
            rest = steps[index + 1:]
            for arm in (step.then or [], step.other or []):
                paths += leaf_paths(flow, [*arm, *rest], here)
            return paths
        if step.kind == "goto":
            return leaf_paths(flow, flow.blocks[step.data[0]], (*here, "goto"))
        here = (*here, step.kind)
    return [*paths, here]


class NestedIfTests(unittest.TestCase):
    """Lỗi cũ: if là câu lệnh cuối của thân một nhánh thì chỉ nhánh đầu được chạy tiếp, phần sau của nhánh cha mất."""

    def test_every_path_reaches_the_statement_after_the_chain(self) -> None:
        flow = npc_flow(NESTED_IF_SCRIPT, 901002)
        paths = leaf_paths(flow, flow.root)
        self.assertGreaterEqual(len(paths), 4)
        for path in paths:
            self.assertIn("option", path)
            self.assertEqual(path[-1], "dispatch")


class TableLayoutTests(unittest.TestCase):
    @unittest.skipUnless((TABLES / "shared" / "quests_kill.tsv").is_file(), "thiếu bảng client")
    def test_known_rows_match_client_files(self) -> None:
        quests = {q.index: q for q in T.read_all(TABLES)}
        wolf = quests[1000050]
        self.assertEqual((wolf.quest, wolf.level, wolf.accept_name), (520, 30, "周无畏"))
        self.assertEqual([(o.kind, o.name, o.count) for o in wolf.objectives], [("kill", "西北狼", 5)])
        rewards = {(r.kind, r.count) for r in wolf.rewards}
        self.assertEqual(rewards, {("bound_money", 8925), ("exp", 28895)})
        letter = quests[1010060]
        self.assertEqual(letter.prereq, [530, 532])
        self.assertIn(("deliver", 40002058), {(o.kind, o.item) for o in letter.objectives})
        area = quests[1020070]
        self.assertEqual((area.objectives[0].scene, area.objectives[0].area), (26, 2611))
        self.assertIn(("choice", 10412070), {(r.group, r.ref) for r in area.rewards})

    @unittest.skipUnless((TABLES / "shared" / "quests_kill.tsv").is_file(), "thiếu bảng client")
    def test_every_row_has_exp_or_relation_and_a_target(self) -> None:
        for quest in T.read_all(TABLES):
            kinds = {r.kind for r in quest.rewards}
            self.assertTrue({"exp", "relation"} & kinds, f"nhiệm vụ {quest.quest} không có thưởng exp/quan hệ")
            self.assertTrue(quest.objectives, f"nhiệm vụ {quest.quest} không có mục tiêu")


class RealDataTests(unittest.TestCase):
    @unittest.skipUnless(REAL_LUA.name == "Data" and (TABLES / "shared").is_dir(), "thiếu dữ liệu XJL7457")
    def test_kill_script_210213_lowers_clean(self) -> None:
        import lua_scan as L

        dat = U.read_script_dat(U.read_text(REAL_LUA / "Script.dat"))
        low = L.build_lowerer(REAL_LUA / "Script")
        path = dat[210213]
        text = U.read_text(REAL_LUA / "Script" / path)
        unit = U.load_unit(210213, path, text, low)
        low.units[210213] = unit
        rec = Q.extract(low, unit, path)
        self.assertEqual(rec.quest, 453)
        self.assertEqual(rec.issues, [])
        self.assertTrue(rec.rewards)

    @unittest.skipUnless(REAL_LUA.name == "Data" and (TABLES / "shared").is_dir(), "thiếu dữ liệu XJL7457")
    def test_extraction_is_deterministic(self) -> None:
        import lua_extract as X

        first = X.build(REAL_LUA, TABLES, ROOT.parents[1] / "dev" / "server" / "scenes")
        second = X.build(REAL_LUA, TABLES, ROOT.parents[1] / "dev" / "server" / "scenes")
        self.assertEqual(sorted(first.regs.conds.rows), sorted(second.regs.conds.rows))
        self.assertEqual(first.regs.effects.rows, second.regs.effects.rows)
        self.assertEqual(first.regs.blocks.rows, second.regs.blocks.rows)
        self.assertEqual([q.script for q in first.quests], [q.script for q in second.quests])


class WorldTests(unittest.TestCase):
    def test_name_normalisation_strips_spaces_and_colour_codes(self) -> None:
        self.assertEqual(W.norm_name(" #R君 还珠 "), "君还珠")


if __name__ == "__main__":
    unittest.main()
