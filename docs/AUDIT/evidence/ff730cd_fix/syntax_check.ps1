param([string]$Tag)
$ErrorActionPreference='Continue'
$root=(Get-Location).Path
$ev="docs\AUDIT\evidence\ff730cd_fix"
$files='effect','face','frame','play','scene','stream' | % { "src\client\app\client\display\graphic\$_.cpp" }
$inc=@('engine','src\shared','src\client\app','src\client\figure','src\client\place','src\client\face','src\client\book','src\client\pack') | % { '-I'+$_ }
$w=@('-Wall','-Wextra','-Werror')
$sys='--sysroot=C:/Users/myhea/AppData/Local/Android/Sdk/ndk/30.0.16248370/toolchains/llvm/prebuilt/windows-x86_64/sysroot'
$cl='C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\Llvm\x64\bin\clang-cl.exe'
$ndk='C:\Users\myhea\AppData\Local\Android\Sdk\ndk\30.0.16248370\toolchains\llvm\prebuilt\windows-x86_64\bin\clang++.exe'
$targets=[ordered]@{
 'clang-cl-x64'=@($cl,@('/std:c++latest','-fsyntax-only','/EHsc','/W4','/WX','-m64')+$inc);
 'ndk-x86_64'=@($ndk,@('--target=x86_64-none-linux-android29',$sys,'-std=c++23','-fsyntax-only')+$w+$inc);
 'ndk-arm64-v8a'=@($ndk,@('--target=aarch64-none-linux-android29',$sys,'-std=c++23','-fsyntax-only','-isystem','C:/dev/third_party/installed/x64-windows-static-md/include/sse2neon')+$w+$inc);
 'ios-arm64-SYNTAX-ONLY'=@($ndk,@('--target=arm64-apple-ios15','-std=c++23','-fsyntax-only')+$w+$inc)
}
$log="$ev\syntax_$Tag.log"
"sha=$(git rev-parse HEAD) tag=$Tag root=$root time=$(Get-Date -Format s)" | Out-File $log -Encoding utf8
foreach($k in $targets.Keys){ $exe,$a=$targets[$k]
 foreach($f in $files){ $out = & $exe @a $f 2>&1 | Out-String; $rc=$LASTEXITCODE
  "### [$k] rc=$rc :: `"$exe`" $($a -join ' ') $f`n$out" | Out-File $log -Append -Encoding utf8
  "{0,-24} {1,-12} rc={2} err={3}" -f $k,(Split-Path $f -Leaf),$rc,([regex]::Matches($out,'error:').Count) } }


