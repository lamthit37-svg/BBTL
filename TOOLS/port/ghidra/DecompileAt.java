// Decompile các hàm của client 2026 trong dự án Ghidra TLBB để port đúng hành vi của mã máy.
// Mỗi đối số sau tệp xuất là một khoá:
//   0x140641210          hàm chứa địa chỉ ảo đó (gốc ảnh 0x140000000 với Game.exe)
//   s:chuỗi              mọi hàm tham chiếu chuỗi ASCII chứa "chuỗi"
//   x:địa chỉ            mọi hàm gọi hay trỏ tới địa chỉ (callers, kèm tên hàm gọi)
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

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.TreeSet;

public class DecompileAt extends GhidraScript {
    private static final int DECOMPILE_SECONDS = 120;

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
            if (key.startsWith("s:")) {
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
