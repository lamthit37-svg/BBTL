@echo off
rem Do lai D2 va D3: nam luot, ghim luong logic 0..11 nhu bao cao cua doi Grok.
for /L %%i in (1,1,5) do start "" /b /wait /affinity FFF build\msvc-release\net_bench.exe
