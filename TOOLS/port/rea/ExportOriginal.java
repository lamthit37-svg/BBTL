import ghidra.app.script.GhidraScript;
import ghidra.app.util.exporter.OriginalFileExporter;
import java.io.File;

// Xuất lại byte của tệp gốc đã nạp vào chương trình Ghidra (FileBytes) ra đĩa; chỉ đọc dự án.
// Dùng khi bản gốc (Game.exe 2026) đã bị xoá khỏi đĩa nhưng dự án Ghidra vẫn giữ — xem export_original.cmd.
public class ExportOriginal extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length != 1) {
            printerr("Cần một tham số: đường dẫn tệp xuất");
            return;
        }
        File out = new File(args[0]);
        OriginalFileExporter exporter = new OriginalFileExporter();
        boolean ok = exporter.export(out, currentProgram, null, monitor);
        println("EXPORT " + currentProgram.getName() + " -> " + out + " ok=" + ok + " size=" + out.length());
    }
}
