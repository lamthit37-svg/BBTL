"""Bộ đánh giá từng phần (partial evaluation) biến hàm Lua thành luồng bước (flow) để xuất bảng.

Không chạy Lua. Mỗi hàm được "chạy" với tham số cụ thể (GetNumText, hằng của script) và trạng thái người
chơi tượng trưng; rẽ nhánh theo trạng thái thành Branch với điều kiện DNF, lời gọi API thành bước
(Text, Option, Effect, Dispatch). Hàm người dùng gọi ở dạng câu lệnh thành khối riêng (Call), gọi trong biểu
thức thì tính ngay giá trị. Cái gì chưa mô hình hoá thì ném Unsupported kèm lý do; không đoán.
"""
from __future__ import annotations

from collections.abc import Iterator
from dataclasses import dataclass, field

import lua_bool as B
import lua_syntax as S
import lua_values as V
from lua_values import Unsupported

MAX_STEPS = 6000
MAX_UNROLL = 64
MAX_DEPTH = 10


@dataclass
class Step:
    kind: str
    data: tuple = ()
    text: object = None
    cond: frozenset = B.TRUE
    then: list | None = None
    other: list | None = None


@dataclass
class Flow:
    root: list
    blocks: dict = field(default_factory=dict)


@dataclass
class Unit:
    """Một tệp script đã nạp: hằng toàn cục và hàm."""

    script_id: int
    path: str
    funcs: dict
    globals: dict


class Env:
    def __init__(self, unit: Unit, local: dict | None = None) -> None:
        self.unit = unit
        self.local: dict = local if local is not None else {}
        self.returns: list | None = None
        self.depth = 0

    def fork(self) -> "Env":
        child = Env(self.unit, dict(self.local))
        child.returns = self.returns
        child.depth = self.depth
        return child


@dataclass
class Tail:
    status: str  # fall, ret, break
    out: list
    env: Env


Api = "callable"


class Lowerer:
    def __init__(self, units: dict, consts: dict, api: dict) -> None:
        self.units = units
        self.consts = consts
        self.api = api
        self.steps = 0
        self.flow = Flow([])
        self.memo: dict = {}
        self.dropped: dict = {}
        self.next_block = 1
        self.num: int | None = None
        self.sink: list | None = None
        self.visiting: set = set()
        self.faults: list = []  # điều kiện dẫn tới lỗi chạy của Lua (chỉ mục của nil) trong câu lệnh đang đánh giá

    # --- tiện ích ---
    def count(self, amount: int = 1) -> None:
        self.steps += amount
        if self.steps > MAX_STEPS:
            raise Unsupported("luồng quá lớn")

    def drop(self, reason: str) -> None:
        self.dropped[reason] = self.dropped.get(reason, 0) + 1

    def new_block(self) -> tuple[int, list]:
        block_id = self.next_block
        self.next_block += 1
        out: list = []
        self.flow.blocks[block_id] = out
        return block_id, out

    # --- biểu thức ---
    def eval(self, node: object, env: Env) -> object:
        self.count()
        handler = _EVAL.get(type(node))
        if handler is None:
            raise Unsupported(f"biểu thức {type(node).__name__}")
        return handler(self, node, env)

    def ev_name(self, node: S.Name, env: Env) -> object:
        name = node.id
        for scope in (env.local, env.unit.globals, self.consts):
            if name in scope:
                value = scope[name]
                if isinstance(value, Poison):
                    raise Unsupported(f"biến {name} không tính được")
                return value
        return None

    def ev_index(self, node: S.Index, env: Env) -> object:
        obj = self.eval(node.obj, env)
        raw_key = self.eval(node.key, env)
        if isinstance(raw_key, V.RandIdx):
            return self.pick_of(obj, raw_key)
        if isinstance(obj, V.Choice) or isinstance(raw_key, V.Choice):
            return self.index_choice(obj, raw_key)
        if isinstance(raw_key, V.SYMBOLIC):
            raise Unsupported("chỉ mục là giá trị theo điều kiện")
        key = V.key_of(raw_key)
        if obj is None:
            raise Unsupported("chỉ mục của nil")
        if not isinstance(obj, V.LTable):
            raise Unsupported("chỉ mục của giá trị không phải bảng")
        return obj.items.get(key)

    def index_choice(self, obj: object, key: object) -> object:
        """bảng[khoá] khi bảng hoặc khoá là Choice của hằng (khoá do vòng `for` chọn theo tên NPC chẳng hạn):
        Choice của từng ô.

        Lá mà bảng là nil là lỗi chạy của Lua (chỉ mục của nil): điều kiện dẫn tới lá đó gom vào self.faults để
        câu lệnh chứa
        nó chặn bằng `if lỗi then return end` trước khi chạy, y như script gốc bị ngắt ở đó. Lá lỗi mang giá
        trị của một lá
        hợp lệ khác để biểu thức vẫn tính được; giá trị ấy không bao giờ được dùng vì nhánh lỗi đã thoát."""
        faults: list = []
        result = self.index_leaves(obj, key, B.TRUE, faults)
        if not faults:
            return result
        fault = B.FALSE
        for cond in faults:
            fault = B.b_or(fault, cond)
        valid = _first_valid(result)
        if valid is _FAULT:
            raise Unsupported("chỉ mục của nil")
        self.faults.append(fault)
        return _fill_faults(result, valid)

    def index_leaves(self, obj: object, key: object, cond: frozenset, faults: list) -> object:
        if isinstance(obj, V.Choice):
            return V.Choice(
                obj.cond,
                self.index_leaves(obj.then, key, B.b_and(cond, obj.cond), faults),
                self.index_leaves(obj.other, key, B.b_and(cond, B.b_not(obj.cond)), faults),
            )
        if isinstance(key, V.Choice):
            return V.Choice(
                key.cond,
                self.index_leaves(obj, key.then, B.b_and(cond, key.cond), faults),
                self.index_leaves(obj, key.other, B.b_and(cond, B.b_not(key.cond)), faults),
            )
        if isinstance(key, (*V.SYMBOLIC, *V.RANDOM)):
            raise Unsupported("chỉ mục là giá trị theo điều kiện")
        if obj is None:
            faults.append(cond)
            return _FAULT
        if not isinstance(obj, V.LTable):
            raise Unsupported("chỉ mục của giá trị không phải bảng")
        return obj.items.get(V.key_of(key))

    def pick_of(self, table: object, index: V.RandIdx) -> V.Pick:
        """bảng[random(n)] với bảng có đúng n phần tử chữ: một trong n chữ, chọn lúc chạy."""
        if not isinstance(table, V.LTable) or table.length() != index.count or len(table.items) != index.count:
            raise Unsupported("random chỉ mục một bảng không đúng cỡ")
        options = tuple(table.items[position] for position in range(1, index.count + 1))
        if not all(isinstance(option, (str, V.Tpl)) for option in options):
            raise Unsupported("random chọn giá trị không phải chữ hằng")
        return V.Pick(options)

    def ev_table(self, node: S.Table, env: Env) -> V.LTable:
        items: dict = {}
        position = 1
        for key_node, value_node in node.items:
            value = self.eval(value_node, env)
            if key_node is None:
                items[position] = value
                position += 1
            else:
                items[V.key_of(self.eval(key_node, env))] = value
        return V.LTable(items)

    def ev_unop(self, node: S.UnOp, env: Env) -> object:
        value = self.eval(node.operand, env)
        if node.op == "not":
            return B.b_not(V.truthy(value)) if not isinstance(value, V.Choice) else self.bad("not Choice")
        number = V._num(value)
        if number is None:
            raise Unsupported("dấu âm trên giá trị không phải hằng số")
        return -number if not float(-number).is_integer() else int(-number)

    def bad(self, why: str) -> object:
        raise Unsupported(why)

    def ev_binop(self, node: S.BinOp, env: Env) -> object:
        op = node.op
        if op in ("and", "or"):
            return self.logic(op, node, env)
        left = self.eval(node.left, env)
        right = self.eval(node.right, env)
        if op == "..":
            return V.concat(left, right)
        if op in ("==", "~=", "<", "<=", ">", ">="):
            return V.compare(op, left, right)
        return V.arith(op, left, right)

    def logic(self, op: str, node: S.BinOp, env: Env) -> object:
        left = self.eval(node.left, env)
        lbool = V.truthy(left)
        if B.is_true(lbool) or B.is_false(lbool):
            decided = B.is_true(lbool)
            if (op == "or") == decided:
                return left
            return self.eval(node.right, env)
        right = self.eval(node.right, env)
        rbool = V.truthy(right)
        if not (isinstance(left, frozenset) and isinstance(right, frozenset)):
            raise Unsupported("and/or giá trị trộn với điều kiện")
        return B.b_and(lbool, rbool) if op == "and" else B.b_or(lbool, rbool)

    def ev_call(self, node: S.Call, env: Env) -> object:
        return self.call(node, env, None)

    # --- lời gọi ---
    def call(self, node: S.Call, env: Env, out: list | None) -> object:
        """Gọi hàm. out=None là chế độ giá trị (không được có hiệu ứng); ngược lại phát bước vào out."""
        if not isinstance(node.fn, S.Name):
            raise Unsupported("gọi hàm qua biểu thức khác tên")
        name = node.fn.id
        args = [self.eval(arg, env) for arg in node.args]
        func = env.unit.funcs.get(name)
        if func is not None:
            return self.call_user(env.unit, func, args, out)
        handler = self.api.get(name)
        if handler is None:
            raise Unsupported(f"API {name}")
        sink = out if out is not None else self.sink
        scratch: list = [] if sink is None else sink
        before = len(scratch)
        try:
            result = handler(self, env, args, scratch)
        except Unsupported:
            # Nhiều API tự xử lý tham số theo điều kiện (AddText rẽ nhánh theo chữ). Cái nào không xử lý được mà
            # tham số là
            # Choice của hằng thì gọi từng lá rồi gộp; bước dở dang của lần thử đầu bị bỏ.
            del scratch[before:]
            if not any(isinstance(arg, V.Choice) for arg in args):
                raise
            return self.call_lifted(handler, env, args, name)
        if sink is None:
            self.value_mode_check(name, scratch)
        return result

    def call_lifted(self, handler: object, env: Env, args: list, name: str) -> object:
        """API chỉ đọc (vị từ trạng thái) gọi với tham số là Choice của hằng: gọi từng lá rồi gộp kết quả theo
        điều kiện."""
        position = next(index for index, arg in enumerate(args) if isinstance(arg, V.Choice))
        choice = args[position]
        leaves = []
        for leaf in (choice.then, choice.other):
            rest = list(args)
            rest[position] = leaf
            if any(isinstance(arg, V.Choice) for arg in rest):
                leaves.append(self.call_lifted(handler, env, rest, name))
                continue
            scratch: list = []
            leaves.append(handler(self, env, rest, scratch))
            if scratch:
                raise Unsupported(f"API {name} có hiệu ứng với tham số theo điều kiện")
        first, second = leaves
        if isinstance(first, V.Dom01) and isinstance(second, V.Dom01):
            return V.Dom01(B.b_or(B.b_and(choice.cond, first.cond), B.b_and(B.b_not(choice.cond), second.cond)))
        if _same(first, second) and not isinstance(first, V.SYMBOLIC):
            return first
        raise Unsupported(f"API {name} trả kết quả khác nhau theo điều kiện")

    def value_mode_check(self, name: str, scratch: list) -> None:
        self.check_pure(scratch, name)

    def check_pure(self, steps: list, name: str) -> None:
        """Hàm giá trị chỉ được có bước hiển thị (thông báo, hộp chữ), không đổi trạng thái."""
        for step in _walk(steps):
            if step.kind in ("note", "begin", "text", "option", "branch", "pick"):
                continue
            if step.kind == "dispatch" and step.data[0] in ("tips", "box"):
                continue
            if step.kind == "effect" and step.data[0] == "notify":
                continue
            if step.kind == "call" and self.cosmetic_block(step.data[0]):
                continue
            raise Unsupported(f"hiệu ứng {step.kind} trong hàm giá trị ({name})")

    def cosmetic_block(self, block_id: int) -> bool:
        """Khối chỉ có bước hiển thị. Khối đang kiểm (vòng gọi) coi là hiển thị: vòng không thêm hiệu ứng."""
        if block_id in self.visiting:
            return True
        self.visiting.add(block_id)
        try:
            self.check_pure(self.flow.blocks[block_id], "khối")
        except Unsupported:
            return False
        finally:
            self.visiting.discard(block_id)
        return True

    def call_user(self, unit: Unit, func: S.FuncDef, args: list, out: list | None) -> object:
        if out is None:
            return self.call_value(unit, func, args)
        block = self.call_block(unit, func, args)
        out.append(Step("call", (block,)))
        return None

    def bind(self, unit: Unit, func: S.FuncDef, args: list, depth: int) -> Env:
        if depth > MAX_DEPTH:
            raise Unsupported("gọi hàm quá sâu")
        env = Env(unit)
        env.depth = depth
        for position, param in enumerate(func.params):
            env.local[param] = args[position] if position < len(args) else None
        return env

    def call_block(self, unit: Unit, func: S.FuncDef, args: list) -> int:
        try:
            key = (unit.script_id, func.name, tuple(_hashable(arg) for arg in args))
        except TypeError as exc:
            raise Unsupported("tham số bảng cho hàm con") from exc
        if key in self.memo:
            return self.memo[key]
        block_id, out = self.new_block()
        self.memo[key] = block_id
        env = self.bind(unit, func, args, 1)
        self.run(func.body, env, out, B.TRUE)
        return block_id

    def call_value(self, unit: Unit, func: S.FuncDef, args: list) -> object:
        env = self.bind(unit, func, args, 1)
        env.returns = []
        scratch: list = []
        saved, self.sink = self.sink, None
        try:
            tail = self.run(func.body, env, scratch, B.TRUE)
        finally:
            self.sink = saved
        self.check_pure(scratch, func.name)
        results = list(env.returns)
        if tail.status == "fall":
            results.append((B.TRUE, None))
        return _piecewise(results)

    # --- câu lệnh ---
    def run(self, stmts: tuple, env: Env, out: list, path: frozenset) -> Tail:
        index = 0
        current = Tail("fall", out, env)
        while index < len(stmts):
            node = stmts[index]
            rest = stmts[index + 1 :]
            self.count()
            if isinstance(node, S.If):
                return self.run_if(node, rest, current, path)
            current = self.run_statement(node, current, path)
            if current.status != "fall":
                return current
            index += 1
        return current

    def run_statement(self, node: object, tail: Tail, path: frozenset) -> Tail:
        env, out = tail.env, tail.out
        handler = _EXEC.get(type(node))
        if handler is None:
            raise Unsupported(f"câu lệnh {type(node).__name__}")
        self.sink = out
        outer, self.faults = self.faults, []
        mark = len(out)
        status = handler(self, node, env, out, path)
        mine, self.faults = self.faults, outer
        if mine:
            out.insert(mark, _fault_guard(mine))
        if isinstance(status, Tail):
            # Câu lệnh phức hợp (do, for) có thể rẽ nhánh bằng điều kiện tượng trưng: phần còn lại của khối phải
            # chạy tiếp
            # từ khối nối và môi trường đã hợp nhất mà thân vòng trả về, không phải từ `out` và `env` ban đầu.
            return status
        return Tail(status or "fall", out, env)

    def ex_local(self, node: S.Local, env: Env, out: list, path: frozenset) -> None:
        values = self.values_of(node.values, env, out, len(node.names))
        for position, name in enumerate(node.names):
            env.local[name] = values[position]

    def ex_assign(self, node: S.Assign, env: Env, out: list, path: frozenset) -> None:
        values = self.values_of(node.values, env, out, len(node.targets))
        for position, target in enumerate(node.targets):
            self.store(target, values[position], env)

    def store(self, target: object, value: object, env: Env) -> None:
        if isinstance(target, S.Name):
            env.local[target.id] = value
            return
        if isinstance(target, S.Index):
            obj = self.eval(target.obj, env)
            if not isinstance(obj, V.LTable):
                raise Unsupported("gán vào chỉ mục của giá trị không phải bảng")
            obj.items[V.key_of(self.eval(target.key, env))] = value
            return
        raise Unsupported("đích gán lạ")

    def values_of(self, nodes: tuple, env: Env, out: list, wanted: int) -> list:
        if len(nodes) == 1 and isinstance(nodes[0], S.Call) and wanted > 1:
            return self.multi_call(nodes[0], env, wanted)
        values = [self.eval(node, env) for node in nodes]
        values = values[:wanted]
        return values + [None] * (wanted - len(values))

    def multi_call(self, node: S.Call, env: Env, wanted: int) -> list:
        """Hàm trả nhiều giá trị: chỉ API đã khai báo (self.api) mới trả danh sách."""
        if not isinstance(node.fn, S.Name):
            raise Unsupported("gọi nhiều giá trị qua biểu thức")
        handler = self.api.get(node.fn.id)
        if handler is None:
            raise Unsupported(f"API {node.fn.id} (nhiều giá trị)")
        args = [self.eval(arg, env) for arg in node.args]
        result = handler(self, env, args, [])
        if not isinstance(result, list):
            raise Unsupported(f"API {node.fn.id} không trả nhiều giá trị")
        return (result + [None] * wanted)[:wanted]

    def ex_call(self, node: S.CallStmt, env: Env, out: list, path: frozenset) -> None:
        self.call(node.call, env, out)

    def ex_return(self, node: S.Return, env: Env, out: list, path: frozenset) -> str:
        value = self.eval(node.values[0], env) if node.values else None
        if env.returns is not None:
            if path is None:
                raise Unsupported("điều kiện đường đi tới return quá phức tạp")
            env.returns.append((path, value))
        else:
            out.append(Step("ret", (), value if isinstance(value, (int, float, str)) else None))
        return "ret"

    def ex_break(self, node: S.Break, env: Env, out: list, path: frozenset) -> str:
        return "break"

    def ex_do(self, node: S.Do, env: Env, out: list, path: frozenset) -> Tail:
        return self.run(node.body, env, out, path)

    def ex_fornum(self, node: S.ForNum, env: Env, out: list, path: frozenset) -> Tail:
        start, stop, step = (V._num(self.eval(x, env)) for x in (node.start, node.stop, node.step))
        if start is None or stop is None or not step:
            raise Unsupported("vòng for có cận không phải hằng số")
        count = int((stop - start) // step) + 1
        if count > MAX_UNROLL:
            raise Unsupported("vòng for dài quá")
        values = [start + step * k for k in range(max(count, 0))]
        return self.unroll(node.var, None, [(v, None) for v in values], node.body, env, out, path)

    def ex_forin(self, node: S.ForIn, env: Env, out: list, path: frozenset) -> Tail:
        source = self.eval(node.source, env)
        if not isinstance(source, V.LTable):
            raise Unsupported("for-in trên giá trị không phải bảng")
        pairs = _ordered(source)
        if len(pairs) > MAX_UNROLL:
            raise Unsupported("vòng for-in dài quá")
        return self.unroll(node.key, node.value, pairs, node.body, env, out, path)

    def unroll(self, key_name: str, value_name: str | None, pairs: list, body: tuple, env: Env, out: list,
               path: frozenset) -> Tail:
        current = Tail("fall", out, env)
        for key, value in pairs:
            current.env.local[key_name] = int(key) if isinstance(key, float) and key.is_integer() else key
            if value_name is not None:
                current.env.local[value_name] = value
            current = self.run(body, current.env, current.out, path)
            if current.status == "break":
                break
            if current.status == "ret":
                return current
        return Tail("fall", current.out, current.env)

    def ex_while(self, node: S.While, env: Env, out: list, path: frozenset) -> None:
        raise Unsupported("vòng while")

    def ex_repeat(self, node: S.Repeat, env: Env, out: list, path: frozenset) -> None:
        raise Unsupported("vòng repeat")

    def ex_funcdef(self, node: S.FuncDef, env: Env, out: list, path: frozenset) -> None:
        raise Unsupported("định nghĩa hàm lồng nhau")

    # --- if ---
    def cond_of(self, node: object, env: Env) -> frozenset:
        return V.truthy(self.eval(node, env))

    def run_if(self, node: S.If, rest: tuple, tail: Tail, path: frozenset) -> Tail:
        ends: list = []
        status = self.chain(list(node.arms), node.orelse, tail.env, tail.out, path, ends)
        if status in ("ret", "break") and not ends:
            return Tail(status, tail.out, tail.env)
        if status == "break":
            raise Unsupported("break trong nhánh điều kiện tượng trưng")
        return self.after_ends(ends, rest, path, tail)

    def chain(self, arms: list, orelse: tuple | None, env: Env, out: list, path: frozenset, ends: list) -> str:
        """Dựng chuỗi if/elseif/else vào out. ends nhận (list, env, điều kiện) của các nhánh còn chạy tiếp."""
        if not arms:
            return self.chain_else(orelse, env, out, path, ends)
        self.sink = out
        outer, self.faults = self.faults, []
        cond = self.cond_of(arms[0][0], env)
        mine, self.faults = self.faults, outer
        if mine:
            out.append(_fault_guard(mine))
        if B.is_true(cond):
            return self.chain_body(arms[0][1], env, out, path, ends)
        if B.is_false(cond):
            return self.chain(arms[1:], orelse, env, out, path, ends)
        then_out: list = []
        other_out: list = []
        then_env, other_env = env.fork(), env.fork()
        before = len(ends)
        st1 = self.chain_body(arms[0][1], then_env, then_out, _and(path, cond), ends)
        middle = len(ends)
        st2 = self.chain(arms[1:], orelse, other_env, other_out, _and(path, _not(cond)), ends)
        out.append(Step("branch", (), None, cond, then_out, other_out))
        self.count(2)
        self.tag_ends(ends, before, middle, cond)
        self.tag_ends(ends, middle, len(ends), _not(cond))
        if st1 == "ret" and st2 == "ret":
            return "ret"
        if "break" in (st1, st2):
            return "break"
        return "fall"

    def tag_ends(self, ends: list, start: int, stop: int, cond: frozenset) -> None:
        """Gắn điều kiện rẽ vào các nhánh còn chạy tiếp [start, stop), để hợp nhất biến thành Choice."""
        for position in range(start, stop):
            tail, env, path, inner = ends[position]
            ends[position] = (tail, env, path, _and(inner, cond))

    def chain_body(self, body: tuple, env: Env, out: list, path: frozenset, ends: list) -> str:
        tail = self.run(body, env, out, path)
        if tail.status == "fall":
            ends.append((tail.out, tail.env, path, B.TRUE))
        return tail.status

    def chain_else(self, orelse: tuple | None, env: Env, out: list, path: frozenset, ends: list) -> str:
        if orelse is None:
            ends.append((out, env, path, B.TRUE))
            return "fall"
        return self.chain_body(orelse, env, out, path, ends)

    def after_ends(self, ends: list, rest: tuple, path: frozenset, tail: Tail) -> Tail:
        """Nối phần còn lại của khối sau if vào các nhánh còn chạy tiếp."""
        if not ends:
            return Tail("ret", tail.out, tail.env)
        if len(ends) == 1:
            # Một nhánh còn chạy tiếp: nối thẳng vào cuối nhánh đó (không cần khối nối).
            if not rest:
                return Tail("fall", ends[0][0], ends[0][1])
            return self.run(rest, ends[0][1], ends[0][0], ends[0][2])
        # Nhiều nhánh còn chạy tiếp (kể cả khi if là câu lệnh CUỐI của thân nhánh cha): phải hợp nhất ở một khối
        # nối, nếu không thì chỉ nhánh đầu được chạy tiếp và phần sau của cha biến mất khỏi mọi nhánh còn lại.
        merged = merge_envs(ends)
        block_id, block_out = self.new_block()
        for end in ends:
            end[0].append(Step("goto", (block_id,)))
        result = self.run(rest, merged, block_out, path)
        return Tail(result.status, result.out, result.env)

    def entry_args(self, func: S.FuncDef, num: int | None = None) -> list:
        """Tham số mặc định của hàm vào: sceneId, selfId, targetId là dấu hiệu; selectRadioId là lựa chọn thưởng."""
        known = {
            "sceneId": V.Marker("scene"),
            "selfId": V.Marker("self"),
            "playerId": V.Marker("self"),
            "objId": V.Marker("self"),
            "targetId": V.Marker("target"),
            "selectRadioId": V.NumSym("radio"),
        }
        self.num = num
        return [known.get(param) for param in func.params]

    def lower(self, unit: Unit, func_name: str, args: list) -> Flow:
        func = unit.funcs.get(func_name)
        if func is None:
            raise Unsupported(f"không có hàm {func_name}")
        self.flow = Flow([])
        self.faults = []
        self.memo = {}
        self.steps = 0
        self.next_block = 1
        env = self.bind(unit, func, args, 0)
        try:
            self.run(func.body, env, self.flow.root, B.TRUE)
        except B.TooComplex as exc:
            raise Unsupported(str(exc)) from exc
        return self.flow


def merge_envs(ends: list) -> Env:
    """Hợp nhất môi trường của nhiều nhánh: biến khác nhau thành Choice theo điều kiện, hoặc không dùng được."""
    base = ends[0][1]
    merged = Env(base.unit, {})
    merged.returns = base.returns
    merged.depth = base.depth
    names = set().union(*(set(end[1].local) for end in ends))
    for name in names:
        values = [end[1].local.get(name) for end in ends]
        if all(_same(values[0], other) for other in values[1:]):
            merged.local[name] = values[0]
        else:
            merged.local[name] = _choose(ends, values)
    return merged


def _and(left: frozenset | None, right: frozenset | None) -> frozenset | None:
    """VÀ của hai điều kiện đường đi; None khi vượt trần mệnh đề. Đường đi chỉ cần cho hợp nhất biến và return
    trong hàm giá trị,
    nên điều kiện nở quá lớn (phủ định của một OR dài) chỉ làm hỏng khi thật sự được dùng, không làm hỏng cả hàm."""
    if left is None or right is None:
        return None
    try:
        return B.b_and(left, right)
    except B.TooComplex:
        return None


def _not(cond: frozenset | None) -> frozenset | None:
    if cond is None:
        return None
    try:
        return B.b_not(cond)
    except B.TooComplex:
        return None


_FAULT = object()  # lá của Choice mà phép lấy chỉ mục gặp nil


def _first_valid(value: object) -> object:
    if isinstance(value, V.Choice):
        found = _first_valid(value.then)
        return found if found is not _FAULT else _first_valid(value.other)
    return value


def _fill_faults(value: object, fill: object) -> object:
    """Thay lá lỗi bằng `fill` và gộp Choice có hai nhánh giống nhau (điều kiện thừa làm nở DNF)."""
    if not isinstance(value, V.Choice):
        return fill if value is _FAULT else value
    then, other = _fill_faults(value.then, fill), _fill_faults(value.other, fill)
    if not isinstance(then, V.Choice) and not isinstance(other, V.Choice) and _same(then, other):
        return then
    return V.Choice(value.cond, then, other)


def _fault_guard(faults: list) -> Step:
    """`if lỗi then return end`: Lua ngắt hàm đang chạy tại chỗ lỗi (ret thoát khối call gần nhất, hoặc cả điểm vào)."""
    fault = B.FALSE
    for cond in faults:
        fault = B.b_or(fault, cond)
    return Step("branch", (), None, fault, [Step("ret")], [])


def _choose(ends: list, values: list) -> object:
    """Choice theo điều kiện rẽ của từng nhánh (loại trừ nhau, đủ cả); thiếu điều kiện thì không dùng được."""
    if any(isinstance(value, V.LTable) for value in values):
        return Poison()
    conds = [end[3] for end in ends]
    if any(cond is None or not cond or B.is_true(cond) for cond in conds[:-1]):
        return Poison()
    result = values[-1]
    for cond, value in zip(reversed(conds[:-1]), reversed(values[:-1])):
        result = V.Choice(cond, value, result)
    return result


class Poison:
    """Biến có giá trị khác nhau giữa các nhánh: dùng sau đó là không mô hình hoá được."""


def _same(left: object, right: object) -> bool:
    if isinstance(left, V.LTable) or isinstance(right, V.LTable):
        return left is right
    return type(left) is type(right) and left == right


def _hashable(value: object) -> object:
    if isinstance(value, V.LTable):
        raise TypeError("bảng")
    hash(value)
    return value


def _ordered(table: V.LTable) -> list:
    numeric = sorted((k, v) for k, v in table.items.items() if isinstance(k, (int, float)))
    named = sorted(((k, v) for k, v in table.items.items() if isinstance(k, str)), key=lambda kv: kv[0])
    return [*numeric, *named]


def _walk(steps: list) -> Iterator:
    for step in steps:
        yield step
        if step.kind == "branch":
            yield from _walk(step.then)
            yield from _walk(step.other)


def _piecewise(results: list) -> object:
    if not results:
        return None
    value = results[-1][1]
    for path, item in reversed(results[:-1]):
        value = V.Choice(path, item, value) if not _same(item, value) else item
    return value


_EVAL = {
    S.Num: lambda self, node, env: int(node.value) if float(node.value).is_integer() else node.value,
    S.Str: lambda self, node, env: node.value,
    S.Nil: lambda self, node, env: None,
    S.Name: Lowerer.ev_name,
    S.Index: Lowerer.ev_index,
    S.Table: Lowerer.ev_table,
    S.UnOp: Lowerer.ev_unop,
    S.BinOp: Lowerer.ev_binop,
    S.Call: Lowerer.ev_call,
}
_EXEC = {
    S.Local: Lowerer.ex_local,
    S.Assign: Lowerer.ex_assign,
    S.CallStmt: Lowerer.ex_call,
    S.Return: Lowerer.ex_return,
    S.Break: Lowerer.ex_break,
    S.Do: Lowerer.ex_do,
    S.ForNum: Lowerer.ex_fornum,
    S.ForIn: Lowerer.ex_forin,
    S.While: Lowerer.ex_while,
    S.Repeat: Lowerer.ex_repeat,
    S.FuncDef: Lowerer.ex_funcdef,
}
