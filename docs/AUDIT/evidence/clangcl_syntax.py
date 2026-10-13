import json,subprocess,shlex,sys,re
db=json.load(open(r"D:\THIENLONG\build\xt-db\compile_commands.json",encoding="utf-8"))
CL=r"C:\Program Files\LLVM\bin\clang-cl.exe"
out=open(sys.argv[2],"w",encoding="utf-8")
for name in sys.argv[3:]:
    e=[x for x in db if x["file"].replace("\\","/").lower().endswith(name.lower())][0]
    cmd=e["command"]
    exe_end=cmd.index(".exe\"")+5
    rest=cmd[exe_end:]
    rest=re.sub(r"\s/Fo\S+|\s/Fd\S+|\s/FS\b|\s-c\b"," ",rest)
    full=f'"{CL}" -fsyntax-only -Werror=pragma-clang-attribute -Wno-unused-command-line-argument {rest}'
    r=subprocess.run(full,capture_output=True,text=True,encoding="utf-8",errors="replace",cwd=e["directory"],shell=False)
    out.write(f"### [{sys.argv[1]}] {name}\n$ {full}\nexit={r.returncode}\n{r.stdout}{r.stderr}\n")
    print(sys.argv[1],name,"exit",r.returncode); print((r.stdout+r.stderr)[:1500])
