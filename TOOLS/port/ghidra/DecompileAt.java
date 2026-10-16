// Decompile các hàm của client 2026 trong dự án Ghidra TLBB để port đúng hành vi của mã máy.
// Mỗi đối số sau tệp xuất là một khoá:
//   0x140641210          hàm chứa địa chỉ ảo đó (gốc ảnh 0x140000000 với Game.exe)
//   s:chuỗi              mọi hàm tham chiếu chuỗi ASCII chứa "chuỗi"
//   x:địa chỉ            mọi hàm gọi hay trỏ tới địa chỉ (callers, kèm tên hàm gọi)
//   l:tên                chỉ tên symbol chứa "tên", mỗi tên một dòng kèm địa chỉ (không dump vtable)
//   g:0xthấp-0xcao       mọi hàm có điểm vào trong khoảng địa chỉ [thấp, cao)
//   v:lớp                decompile mọi hàm ảo của "<lớp>::vftable" (ví dụ v:Packets::LCRetLogin)
//   n:tên                symbol có tên chứa "tên"; vtable kèm các hàm ảo của nó (không decompile)
//   i:chuỗi              14 lệnh máy tại mỗi nơi tham chiếu chuỗi (khi hàm chứa quá lớn để decompile)
//   a:địa chỉ            16 lệnh máy quanh địa chỉ (lùi 4 lệnh), khi chỉ cần xem cách nạp đối số
//   e:địa chỉ            bảng đăng ký sự kiện trong hàm chứa địa chỉ: "0xid tên" (Game.exe 0x140a10f2d)
//   m:địa chỉ            bảng đăng ký phương thức Lua trong hàm chứa địa chỉ: "0xhàm tên" (UI_CEGUI.dll 0x18002b600)
//   d:địa chỉ            mọi lệnh máy của hàm chứa địa chỉ (khi decompile làm mất đối số dấu phẩy động: xmm0)
//   r:địa chỉ            16 byte dữ liệu tại địa chỉ: hex, chuỗi ASCII, hai số double và hai số float đầu (hằng số của hàm)
// Kết quả: tên hàm, địa chỉ, decompile, danh sách hàm được gọi. Chương trình chỉ đọc, không lưu.
// Chạy bằng decompile.bat <chương trình> <tệp xuất> <khoá>...

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.program.model.symbol.Symbol;
import ghidra.program.model.symbol.SymbolIterator;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.TreeSet;

public class DecompileAt extends GhidraScript {
    private static final int DECOMPILE_SECONDS = 600;

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 2) {
            throw new IllegalArgumentException("cần: tệp xuất, rồi ít nhất một khoá");
        }
        FunctionManager functions = currentProgram.getFunctionManager();
        DecompInterface decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        StringBuilder text = new StringBuilder();
        Set<Long> done = new LinkedHashSet<>();
        for (int i = 1; i < args.length; i++) {
            String key = args[i];
            text.append("\n######## ").append(key).append('\n');
            Set<Long> entries = new TreeSet<>();
            if (key.startsWith("l:")) {
                listNames(key.substring(2), text);
                continue;
            } else if (key.startsWith("v:")) {
                entries.addAll(vtableFunctions(key.substring(2), functions));
            } else if (key.startsWith("n:")) {
                listSymbols(key.substring(2), text);
                continue;
            } else if (key.startsWith("i:")) {
                listAround(key.substring(2), text);
                continue;
            } else if (key.startsWith("a:")) {
                listInstructions(address(key.substring(2)), text);
                continue;
            } else if (key.startsWith("e:")) {
                listEvents(address(key.substring(2)), text);
                continue;
            } else if (key.startsWith("m:")) {
                listMethods(address(key.substring(2)), text);
                continue;
            } else if (key.startsWith("d:")) {
                listFunction(address(key.substring(2)), text);
                continue;
            } else if (key.startsWith("r:")) {
                listData(address(key.substring(2)), text);
                continue;
            } else if (key.startsWith("g:")) {
                entries.addAll(inRange(key.substring(2), functions));
            } else if (key.startsWith("s:")) {
                entries.addAll(byString(key.substring(2), functions));
            } else if (key.startsWith("x:")) {
                entries.addAll(callersOf(address(key.substring(2)), functions, text));
            } else {
                Function function = functions.getFunctionContaining(address(key));
                if (function == null) {
                    text.append("không có hàm chứa ").append(key).append('\n');
                    continue;
                }
                entries.add(function.getEntryPoint().getOffset());
            }
            for (long entry : entries) {
                if (!done.add(entry)) {
                    text.append("(đã in) ").append(Long.toHexString(entry)).append('\n');
                    continue;
                }
                write(text, decomp, functions.getFunctionAt(toAddr(entry)));
            }
        }
        decomp.dispose();
        Files.writeString(Path.of(args[0]), text.toString(), StandardCharsets.UTF_8);
        println("xuất " + args[0]);
    }

    // Mọi hàm có điểm vào trong [thấp, cao) của "0xthấp-0xcao" (khoá g:). Dùng để đọc trọn một lớp khi
    // các hàm của nó nằm liền nhau (Render.dll EnSky 0x180235000-0x180240000).
    private Set<Long> inRange(String text, FunctionManager functions) {
        Set<Long> entries = new TreeSet<>();
        String[] bounds = text.split("-");
        Address low = address(bounds[0]);
        Address high = address(bounds[1]);
        for (Function function : functions.getFunctions(low, true)) {
            if (function.getEntryPoint().compareTo(high) >= 0) {
                break;
            }
            entries.add(function.getEntryPoint().getOffset());
        }
        return entries;
    }

    // Hàm của vtable có tên đúng "<lớp>::vftable" (tối đa 24 ô); dừng ở ô không phải hàm. Dùng để đọc
    // hàm Read/Write/Execute của một gói tin (Packets::LCRetCharList).
    private Set<Long> vtableFunctions(String className, FunctionManager functions) throws Exception {
        Set<Long> entries = new TreeSet<>();
        Memory memory = currentProgram.getMemory();
        SymbolIterator symbols = currentProgram.getSymbolTable().getAllSymbols(false);
        while (symbols.hasNext()) {
            Symbol symbol = symbols.next();
            if (!symbol.getName(true).equals(className + "::vftable")) {
                continue;
            }
            Address slot = symbol.getAddress();
            for (int index = 0; index < 24; index++) {
                Function function = functions.getFunctionAt(toAddr(memory.getLong(slot)));
                if (function == null) {
                    break;
                }
                entries.add(function.getEntryPoint().getOffset());
                slot = slot.add(8);
            }
        }
        return entries;
    }

    // Chỉ tên của symbol có tên chứa needle (không dump vtable), mỗi tên một dòng kèm địa chỉ.
    private void listNames(String needle, StringBuilder text) {
        SymbolIterator symbols = currentProgram.getSymbolTable().getAllSymbols(false);
        Set<String> seen = new TreeSet<>();
        while (symbols.hasNext()) {
            Symbol symbol = symbols.next();
            String name = symbol.getName(true);
            if (name.contains(needle)) {
                seen.add(name + " @ " + symbol.getAddress());
            }
        }
        for (String line : seen) {
            text.append(line).append('\n');
        }
    }

    // Mỗi nơi tham chiếu tới chuỗi ASCII chứa needle: in 14 lệnh máy bắt đầu từ lệnh tham chiếu. Dùng
    // khi hàm chứa quá lớn để decompile (bảng đăng ký sự kiện): id đứng ngay sau tham chiếu chuỗi.
    private void listAround(String needle, StringBuilder text) throws Exception {
        Memory memory = currentProgram.getMemory();
        byte[] pattern = needle.getBytes(StandardCharsets.UTF_8);
        Address from = memory.getMinAddress();
        while (from != null) {
            Address hit = memory.findBytes(from, pattern, null, true, monitor);
            if (hit == null) {
                break;
            }
            ReferenceIterator refs = currentProgram.getReferenceManager().getReferencesTo(hit);
            while (refs.hasNext()) {
                Address site = refs.next().getFromAddress();
                text.append("-- tham chiếu từ ").append(site).append(" chuỗi ").append(cstring(hit)).append('\n');
                ghidra.program.model.listing.Instruction instruction = currentProgram.getListing().getInstructionAt(site);
                // Lùi 3 lệnh: bảng sự kiện ghi id (hằng số) ngay TRƯỚC khi nạp con trỏ tên.
                for (int back = 0; instruction != null && back < 3 && instruction.getPrevious() != null; back++) {
                    instruction = instruction.getPrevious();
                }
                for (int count = 0; instruction != null && count < 14; count++) {
                    text.append(instruction.getAddress()).append(": ").append(instruction).append('\n');
                    instruction = instruction.getNext();
                }
            }
            from = hit.add(1);
        }
    }

    // 12 lệnh máy bắt đầu từ địa chỉ (lùi 4 lệnh trước để thấy cách nạp đối số).
    private void listInstructions(Address start, StringBuilder text) {
        ghidra.program.model.listing.Instruction instruction = currentProgram.getListing().getInstructionAt(start);
        text.append("-- từ ").append(start).append('\n');
        for (int back = 0; instruction != null && back < 4 && instruction.getPrevious() != null; back++) {
            instruction = instruction.getPrevious();
        }
        for (int count = 0; instruction != null && count < 16; count++) {
            text.append(instruction.getAddress()).append(": ").append(instruction).append('\n');
            instruction = instruction.getNext();
        }
    }

    // 16 byte tại địa chỉ: hex, chuỗi ASCII (tới byte 0), số double ở +0, float ở +0 và +4.
    private void listData(Address at, StringBuilder text) throws Exception {
        Memory memory = currentProgram.getMemory();
        byte[] bytes = new byte[16];
        memory.getBytes(at, bytes);
        StringBuilder hex = new StringBuilder();
        for (byte value : bytes) {
            hex.append(String.format("%02x", value & 0xFF));
        }
        java.nio.ByteBuffer buffer = java.nio.ByteBuffer.wrap(bytes).order(java.nio.ByteOrder.LITTLE_ENDIAN);
        text.append(at).append(": ").append(hex).append(" \"").append(cstring(at)).append("\" double=")
            .append(buffer.getDouble(0)).append(" float=").append(buffer.getFloat(0)).append(',').append(buffer.getFloat(4))
            .append(" int=").append(buffer.getInt(0)).append('\n');
    }

    // Mọi lệnh máy của hàm chứa địa chỉ, mỗi lệnh một dòng "địa chỉ: lệnh".
    private void listFunction(Address inside, StringBuilder text) {
        Function function = currentProgram.getFunctionManager().getFunctionContaining(inside);
        if (function == null) {
            text.append("không có hàm chứa ").append(inside).append('\n');
            return;
        }
        for (ghidra.program.model.listing.Instruction instruction
            : currentProgram.getListing().getInstructions(function.getBody(), true)) {
            text.append(instruction.getAddress()).append(": ").append(instruction).append('\n');
        }
    }

    // Bảng đăng ký phương thức Lua của UI_CEGUI.dll: mỗi `LEA RDX,[chuỗi]` là tên được đăng ký, và con trỏ hàm của nó là
    // `LEA reg,[địa chỉ trong khối mã]` gần nhất trước đó (đo ở 0x18002b600: con trỏ nạp vào RCX hay RSI rồi ghi vào [RAX] trước
    // khi nạp R8 và RDX của lời gọi đăng ký). In "0xhàm tên" theo thứ tự lệnh; tên lớp cũng hiện, kèm
    // con trỏ cũ (không có nghĩa).
    private void listMethods(Address inside, StringBuilder text) throws Exception {
        Function function = currentProgram.getFunctionManager().getFunctionContaining(inside);
        if (function == null) {
            text.append("không có hàm chứa ").append(inside).append('\n');
            return;
        }
        Memory memory = currentProgram.getMemory();
        Address pending = null;
        for (ghidra.program.model.listing.Instruction instruction
            : currentProgram.getListing().getInstructions(function.getBody(), true)) {
            if (!"LEA".equals(instruction.getMnemonicString()) || instruction.getRegister(0) == null) {
                continue;
            }
            Address target = null;
            for (Reference reference : instruction.getReferencesFrom()) {
                target = reference.getToAddress();
            }
            if (target == null) {
                continue;
            }
            ghidra.program.model.mem.MemoryBlock block = memory.getBlock(target);
            if (block == null) {
                continue;
            }
            if (block.isExecute()) {
                // R8 giữ bộ nối chung 0x18001cca0 của mọi phương thức, không phải hàm riêng.
                if (!"R8".equals(instruction.getRegister(0).getName())) {
                    pending = target;
                }
            } else if ("RDX".equals(instruction.getRegister(0).getName())) {
                String name = cstring(target);
                if (name.length() > 2 && pending != null) {
                    text.append("0x").append(Long.toHexString(pending.getOffset())).append(' ').append(name).append('\n');
                }
            }
        }
    }

    // Bảng đăng ký sự kiện của client: trong hàm chứa địa chỉ, mỗi `MOV dword [..], imm` ngay trước một
    // `LEA reg,[chuỗi]` là id của sự kiện mang tên chuỗi đó. In "0xid tên" theo thứ tự lệnh.
    private void listEvents(Address inside, StringBuilder text) throws Exception {
        Function function = currentProgram.getFunctionManager().getFunctionContaining(inside);
        if (function == null) {
            text.append("không có hàm chứa ").append(inside).append('\n');
            return;
        }
        Long lastId = null;
        for (ghidra.program.model.listing.Instruction instruction
            : currentProgram.getListing().getInstructions(function.getBody(), true)) {
            String mnemonic = instruction.getMnemonicString();
            if ("MOV".equals(mnemonic) && instruction.getNumOperands() == 2
                && instruction.getScalar(1) != null && instruction.toString().contains("dword ptr")) {
                lastId = instruction.getScalar(1).getUnsignedValue();
            } else if ("LEA".equals(mnemonic) && lastId != null) {
                Address target = null;
                for (Reference reference : instruction.getReferencesFrom()) {
                    target = reference.getToAddress();
                }
                if (target != null) {
                    String name = cstring(target);
                    if (name.length() > 3) {
                        text.append("0x").append(Long.toHexString(lastId)).append(' ').append(name).append('\n');
                        lastId = null;
                    }
                }
            }
        }
    }

    // Chuỗi C (tối đa 120 byte, ASCII) bắt đầu tại địa chỉ.
    private String cstring(Address start) throws Exception {
        StringBuilder out = new StringBuilder();
        Memory memory = currentProgram.getMemory();
        for (int index = 0; index < 120; index++) {
            int value = memory.getByte(start.add(index)) & 0xFF;
            if (value == 0) {
                break;
            }
            out.append(value >= 32 && value < 127 ? (char) value : '?');
        }
        return out.toString();
    }

    // Symbol có tên chứa needle; vtable (tên chứa "vftable") kèm các ô con trỏ hàm của nó.
    private void listSymbols(String needle, StringBuilder text) throws Exception {
        Memory memory = currentProgram.getMemory();
        FunctionManager functions = currentProgram.getFunctionManager();
        SymbolIterator symbols = currentProgram.getSymbolTable().getAllSymbols(false);
        int shown = 0;
        while (symbols.hasNext() && shown < 400) {
            Symbol symbol = symbols.next();
            String name = symbol.getName(true);
            if (!name.contains(needle)) {
                continue;
            }
            shown++;
            text.append(symbol.getAddress()).append(' ').append(symbol.getSymbolType()).append(' ').append(name)
                .append('\n');
            if (!name.contains("vftable")) {
                continue;
            }
            Address slot = symbol.getAddress();
            for (int index = 0; index < 64; index++) {
                long target = memory.getLong(slot);
                Function function = functions.getFunctionAt(toAddr(target));
                if (function == null) {
                    break;
                }
                text.append("  [").append(Integer.toHexString(index * 8)).append("] ").append(function.getName())
                    .append(" @ ").append(function.getEntryPoint()).append('\n');
                slot = slot.add(8);
            }
        }
    }

    private Address address(String text) {
        String digits = text.startsWith("0x") ? text.substring(2) : text;
        return toAddr(Long.parseUnsignedLong(digits, 16));
    }

    private Set<Long> byString(String needle, FunctionManager functions) throws Exception {
        Set<Long> entries = new TreeSet<>();
        Memory memory = currentProgram.getMemory();
        byte[] pattern = needle.getBytes(StandardCharsets.UTF_8);
        Address from = memory.getMinAddress();
        while (from != null) {
            Address hit = memory.findBytes(from, pattern, null, true, monitor);
            if (hit == null) {
                break;
            }
            ReferenceIterator refs = currentProgram.getReferenceManager().getReferencesTo(hit);
            while (refs.hasNext()) {
                Function function = functions.getFunctionContaining(refs.next().getFromAddress());
                if (function != null) {
                    entries.add(function.getEntryPoint().getOffset());
                }
            }
            from = hit.add(1);
        }
        return entries;
    }

    private Set<Long> callersOf(Address target, FunctionManager functions, StringBuilder text) {
        Set<Long> entries = new TreeSet<>();
        ReferenceIterator refs = currentProgram.getReferenceManager().getReferencesTo(target);
        while (refs.hasNext()) {
            Reference ref = refs.next();
            Function function = functions.getFunctionContaining(ref.getFromAddress());
            text.append("ref ").append(ref.getFromAddress()).append(' ').append(ref.getReferenceType()).append(' ')
                .append(function == null ? "(không hàm)" : function.getName()).append('\n');
            if (function != null) {
                entries.add(function.getEntryPoint().getOffset());
            }
        }
        return entries;
    }

    private void write(StringBuilder text, DecompInterface decomp, Function function) {
        text.append("\n==== ").append(function.getName()).append(" @ 0x")
            .append(Long.toHexString(function.getEntryPoint().getOffset())).append('\n');
        DecompileResults result = decomp.decompileFunction(function, DECOMPILE_SECONDS, monitor);
        if (!result.decompileCompleted()) {
            text.append("decompile hỏng: ").append(result.getErrorMessage()).append('\n');
            return;
        }
        text.append(result.getDecompiledFunction().getC());
        Set<String> called = new TreeSet<>();
        for (Function callee : function.getCalledFunctions(monitor)) {
            called.add(callee.getName() + "@" + Long.toHexString(callee.getEntryPoint().getOffset()));
        }
        text.append("// gọi: ").append(String.join(", ", called)).append('\n');
    }
}
