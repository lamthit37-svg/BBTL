# D. Báo cáo clang-tidy toàn dự án (2026-10-13)

Công cụ: clang-tidy 23.1.2 (LLVM), cấu hình `.clang-tidy` của dự án, CSDL lệnh `build/msvc-release/compile_commands.json` (Ninja + cl, CMAKE_EXPORT_COMPILE_COMMANDS=ON). Script: `build/tidy/run_tidy.py`, kết quả thô `build/tidy/out/`, tổng hợp `build/tidy/rows.json`.

**Giới hạn phủ:** compile_commands của Windows KHÔNG phủ nhánh `__ANDROID__`, `__APPLE__`, POSIX (android_main.cpp, context_egl.cpp, surface_android.cpp, ios_main.mm, reactor POSIX…). Cần chạy lại với compile_commands của preset android-arm64 để phủ.

Tổng cảnh báo duy nhất trong mã dự án (src, engine, Test, TOOLS; đã loại header vcpkg `C:/dev` và tệp sinh trong `build/`): **3466**. Header ngoài dự án bị lọc: 3025.

## 1. Gate / parse gói tin (ưu tiên)

- `engine\net\net.hpp:111` [cppcoreguidelines-special-member-functions] class 'TcpStream' defines a copy constructor, a copy assignment operator, a move constructor and a move assignment operator but does not def
- `src\server\gate\motion.hpp:35` [readability-identifier-length] parameter name 'at' is too short, expected at least 3 characters
- `engine\net\shard.hpp:33` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\shard.hpp:35` [readability-identifier-naming] invalid case style for member 'items_'
- `engine\net\shard.hpp:35` [bugprone-invalid-enum-default-initialization] enum value of type 'Op' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `engine\net\shard.hpp:43` [readability-identifier-naming] invalid case style for member 'items_'
- `engine\net\shard.hpp:44` [cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays] do not declare C-style arrays, use 'std::array' instead
- `engine\net\shard.hpp:44` [readability-identifier-naming] invalid case style for member 'pad_'
- `engine\net\shard.hpp:57` [cppcoreguidelines-special-member-functions] class 'SpscMail' defines a copy constructor, a copy assignment operator, a move constructor and a move assignment operator but does not defi
- `engine\net\shard.hpp:135` [cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays] do not declare C-style arrays, use 'std::array' instead
- `engine\net\shard.hpp:135` [readability-identifier-naming] invalid case style for member 'pad_'
- `engine\net\shard.hpp:141` [cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays] do not declare C-style arrays, use 'std::array' instead
- `engine\net\shard.hpp:141` [readability-identifier-naming] invalid case style for member 'pad_'
- `engine\net\shard.hpp:146` [cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays] do not declare C-style arrays, use 'std::array' instead
- `engine\net\shard.hpp:146` [readability-identifier-naming] invalid case style for member 'pad_'
- `engine\net\shard.hpp:228` [readability-function-cognitive-complexity] function 'pick_hot' has cognitive complexity of 12 (threshold 10)
- `src\server\gate\motion.cpp:5` [misc-include-cleaner] no header providing "std::uint32_t" is directly included
- `src\server\gate\motion.cpp:5` [misc-include-cleaner] no header providing "std::int64_t" is directly included
- `src\server\gate\motion.cpp:7` [misc-include-cleaner] no header providing "std::uint64_t" is directly included
- `src\server\gate\motion.cpp:10` [misc-include-cleaner] no header providing "game::protocol::Position" is directly included
- `src\server\gate\motion.cpp:10` [misc-include-cleaner] no header providing "game::guard::Anchor" is directly included
- `src\server\gate\motion.cpp:10` [readability-identifier-length] parameter name 'at' is too short, expected at least 3 characters
- `src\server\gate\motion.cpp:23` [readability-function-size] function 'judge' exceeds recommended size/complexity thresholds
- `src\server\gate\motion.cpp:23` [misc-include-cleaner] no header providing "game::protocol::Move" is directly included
- `src\server\gate\motion.cpp:26` [misc-include-cleaner] no header providing "game::guard::Step" is directly included
- `src\server\gate\motion.cpp:28` [misc-include-cleaner] no header providing "game::guard::Verdict" is directly included
- `src\server\gate\motion.cpp:33` [readability-identifier-length] variable name 'at' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:27` [misc-include-cleaner] included header ws2tcpip.h is not used directly
- `engine\net\reactor_win32.cpp:47` [misc-include-cleaner] no header providing "OVERLAPPED" is directly included
- `engine\net\reactor_win32.cpp:56` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'size_t' (aka 'unsigned long long') of a multiplication performed in type 'DWORD' (aka 'u
- `engine\net\reactor_win32.cpp:79` [misc-include-cleaner] no header providing "game::net::SocketHandle" is directly included
- `engine\net\reactor_win32.cpp:87` [misc-include-cleaner] no header providing "game::net::Endpoint" is directly included
- `engine\net\reactor_win32.cpp:88` [misc-include-cleaner] no header providing "s_addr" is directly included
- `engine\net\reactor_win32.cpp:115` [misc-include-cleaner] no header providing "game::net::Milliseconds" is directly included
- `engine\net\reactor_win32.cpp:125` [misc-include-cleaner] no header providing "HANDLE" is directly included
- `engine\net\reactor_win32.cpp:135` [cppcoreguidelines-prefer-member-initializer] 'port' should be initialized in a member initializer of the constructor
- `engine\net\reactor_win32.cpp:135` [misc-include-cleaner] no header providing "CreateIoCompletionPort" is directly included
- `engine\net\reactor_win32.cpp:135` [misc-include-cleaner] no header providing "INVALID_HANDLE_VALUE" is directly included
- `engine\net\reactor_win32.cpp:160` [misc-const-correctness] variable 'slot' of type 'Slot &' can be declared 'const'
- `engine\net\reactor_win32.cpp:165` [misc-const-correctness] variable 'native' of type 'ReactorNative &' can be declared 'const'
- `engine\net\reactor_win32.cpp:167` [misc-misplaced-const] 'joined' declared with a const-qualified typedef; results in the type being 'void *const' instead of 'const void *'
- `engine\net\reactor_win32.cpp:167` [performance-no-int-to-ptr] integer to pointer cast pessimizes optimization opportunities
- `engine\net\reactor_win32.cpp:173` [misc-include-cleaner] no header providing "GUID" is directly included
- `engine\net\reactor_win32.cpp:177` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'LPFN_ACCEPTEX *' (aka 'int (**)(unsigned long long, unsigned long long, void *, unsigned long, unsigned 
- `engine\net\reactor_win32.cpp:180` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'LPFN_GETACCEPTEXSOCKADDRS *' (aka 'void (**)(void *, unsigned long, unsigned long, unsigned long, struct
- `engine\net\reactor_win32.cpp:184` [readability-identifier-length] parameter name 'op' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:210` [bugprone-exception-escape] an exception may be thrown in function 'post_read' which should not throw exceptions
- `engine\net\reactor_win32.cpp:215` [modernize-use-designated-initializers] use designated initializer list to initialize 'WSABUF' (aka 'struct _WSABUF')
- `engine\net\reactor_win32.cpp:218` [readability-identifier-length] variable name 'rc' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:230` [readability-identifier-length] parameter name 'ok' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:232` [modernize-use-integer-sign-comparison] comparison between 'signed' and 'unsigned' integers
- `engine\net\reactor_win32.cpp:238` [readability-identifier-length] parameter name 'ok' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:238` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'apply_write' of convertible types are easily swapped by mistake
- `engine\net\reactor_win32.cpp:240` [modernize-use-integer-sign-comparison] comparison between 'signed' and 'unsigned' integers
- `engine\net\reactor_win32.cpp:246` [readability-identifier-length] parameter name 'ok' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:247` [modernize-use-integer-sign-comparison] comparison between 'signed' and 'unsigned' integers
- `engine\net\reactor_win32.cpp:256` [misc-include-cleaner] no header providing "OVERLAPPED_ENTRY" is directly included
- `engine\net\reactor_win32.cpp:257` [readability-identifier-length] variable name 'ov' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:265` [readability-identifier-length] variable name 'op' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:270` [misc-include-cleaner] no header providing "GetOverlappedResult" is directly included
- `engine\net\reactor_win32.cpp:270` [performance-no-int-to-ptr] integer to pointer cast pessimizes optimization opportunities
- `engine\net\reactor_win32.cpp:271` [misc-include-cleaner] no header providing "GetLastError" is directly included
- `engine\net\reactor_win32.cpp:298` [misc-include-cleaner] no header providing "GetQueuedCompletionStatusEx" is directly included
- `engine\net\reactor_win32.cpp:305` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\reactor_win32.cpp:319` [readability-function-size] function 'emit' exceeds recommended size/complexity thresholds
- `engine\net\reactor_win32.cpp:319` [readability-function-cognitive-complexity] function 'emit' has cognitive complexity of 17 (threshold 10)
- `engine\net\reactor_win32.cpp:319` [misc-include-cleaner] no header providing "game::net::PollEvents" is directly included
- `engine\net\reactor_win32.cpp:324` [misc-include-cleaner] no header providing "game::net::PollEvent" is directly included
- `engine\net\reactor_win32.cpp:350` [misc-include-cleaner] no header providing "game::net::Accepted" is directly included
- `engine\net\reactor_win32.cpp:359` [modernize-use-integer-sign-comparison] comparison between 'signed' and 'unsigned' integers
- `engine\net\reactor_win32.cpp:369` [misc-include-cleaner] no header providing "game::net::Socket" is directly included
- `engine\net\reactor_win32.cpp:373` [misc-include-cleaner] no header providing "game::net::TcpStream" is directly included
- `engine\net\reactor_win32.cpp:396` [bugprone-exception-escape] an exception may be thrown in function '~ReactorNative' which should not throw exceptions
- `engine\net\reactor_win32.cpp:397` [misc-const-correctness] variable 'item' of type 'value_type &' (aka 'std::pair<const unsigned long long, std::unique_ptr<game::net::(anonymous namespace)::Slot>> &'
- `engine\net\reactor_win32.cpp:403` [misc-include-cleaner] no header providing "CancelIoEx" is directly included
- `engine\net\reactor_win32.cpp:403` [performance-no-int-to-ptr] integer to pointer cast pessimizes optimization opportunities
- `engine\net\reactor_win32.cpp:409` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `engine\net\reactor_win32.cpp:412` [misc-include-cleaner] no header providing "CloseHandle" is directly included
- `engine\net\reactor_win32.cpp:430` [misc-include-cleaner] no header providing "game::net::kNoSocket" is directly included
- `engine\net\reactor_win32.cpp:444` [readability-function-size] function 'unwatch' exceeds recommended size/complexity thresholds
- `engine\net\reactor_win32.cpp:455` [performance-no-int-to-ptr] integer to pointer cast pessimizes optimization opportunities
- `engine\net\reactor_win32.cpp:476` [readability-function-size] function 'note_read' exceeds recommended size/complexity thresholds
- `engine\net\reactor_win32.cpp:476` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'note_read' of similar type are easily swapped by mistake
- `engine\net\reactor_win32.cpp:491` [misc-include-cleaner] no header providing "game::net::TcpListener" is directly included
- `engine\net\reactor_win32.cpp:505` [readability-identifier-length] variable name 'op' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:514` [misc-include-cleaner] no header providing "game::net::NetResult" is directly included
- `engine\net\reactor_win32.cpp:536` [misc-include-cleaner] no header providing "CHAR" is directly included
- `engine\net\reactor_win32.cpp:538` [readability-identifier-length] variable name 'rc' is too short, expected at least 3 characters
- `engine\net\reactor_win32.cpp:551` [misc-include-cleaner] no header providing "std::unexpected" is directly included
- `engine\net\reactor_win32.cpp:551` [misc-include-cleaner] no header providing "game::net::NetError" is directly included
- `engine\net\reactor_win32.cpp:560` [misc-include-cleaner] no header providing "PostQueuedCompletionStatus" is directly included
- `engine\net\shard.hpp:41` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\shard.hpp:177` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\shard.hpp:178` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\shard.hpp:189` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\shard.hpp:224` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\shard.hpp:234` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\shard.hpp:242` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `engine\net\shard.hpp:252` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `TOOLS\server\gate_load.cpp:662` [readability-function-cognitive-complexity] function 'pump_one' has cognitive complexity of 11 (threshold 10)
- `TOOLS\server\gate_load.cpp:893` [readability-redundant-member-init] initializer for member 'began' is redundant
- `TOOLS\server\gate_load.cpp:896` [readability-identifier-length] parameter name 'at' is too short, expected at least 3 characters
- `TOOLS\server\gate_load.cpp:1023` [readability-identifier-length] variable name 'at' is too short, expected at least 3 characters
- `engine\net\shard.hpp:184` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `src\server\gate\table.cpp:62` [misc-include-cleaner] no header providing "game::guard::Anchor" is directly included
- `src\server\gate\table.cpp:68` [misc-include-cleaner] no header providing "game::account::kCapBytes" is directly included
- `src\server\gate\table.cpp:213` [readability-redundant-member-init] initializer for member 'asks' is redundant
- `src\server\gate\table.cpp:214` [readability-redundant-member-init] initializer for member 'answers' is redundant
- `src\server\gate\table.cpp:483` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'send_reject' of convertible types are easily swapped by mistake
- `src\server\gate\table.cpp:626` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `src\server\gate\table.cpp:635` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `src\server\gate\table.cpp:635` [cppcoreguidelines-pro-bounds-constant-array-index] do not use array subscript when the index is not an integer constant expression
- `src\server\gate\table.cpp:680` [readability-function-size] function 'prune_sessions' exceeds recommended size/complexity thresholds
- `src\server\gate\table.cpp:694` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'open_session' of convertible types are easily swapped by mistake
- `src\server\gate\table.cpp:716` [readability-function-size] function 'on_resume' exceeds recommended size/complexity thresholds
- `src\server\gate\table.cpp:716` [readability-function-cognitive-complexity] function 'on_resume' has cognitive complexity of 23 (threshold 10)
- `src\server\gate\table.cpp:796` [readability-function-size] function 'finish_enter' exceeds recommended size/complexity thresholds
- `src\server\gate\table.cpp:796` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'finish_enter' of convertible types are easily swapped by mistake
- `src\server\gate\table.cpp:856` [readability-function-size] function 'ask_password' exceeds recommended size/complexity thresholds
- `src\server\gate\table.cpp:923` [bugprone-branch-clone] switch has 2 consecutive identical branches
- `src\server\gate\table.cpp:930` [readability-function-size] function 'clerk_main' exceeds recommended size/complexity thresholds
- `src\server\gate\table.cpp:930` [readability-function-cognitive-complexity] function 'clerk_main' has cognitive complexity of 12 (threshold 10)
- `src\server\gate\table.cpp:931` [bugprone-unchecked-optional-access] unchecked access to optional value
- `src\server\gate\table.cpp:953` [readability-use-std-min-max] use `std::max` instead of `<`
- `src\server\gate\table.cpp:956` [readability-math-missing-parentheses] '/' has higher precedence than '+'; add parentheses to explicitly specify the order of operations
- `src\server\gate\table.cpp:964` [readability-identifier-length] parameter name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:986` [readability-function-cognitive-complexity] function 'dispatch_game' has cognitive complexity of 12 (threshold 10)
- `src\server\gate\table.cpp:986` [readability-identifier-length] parameter name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1026` [readability-identifier-length] parameter name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1049` [readability-identifier-length] variable name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1066` [readability-identifier-length] parameter name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1081` [readability-identifier-length] variable name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1095` [readability-identifier-length] parameter name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1141` [readability-identifier-length] parameter name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1163` [readability-identifier-length] variable name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1169` [readability-identifier-length] parameter name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1201` [readability-identifier-length] variable name 'in' is too short, expected at least 3 characters
- `src\server\gate\table.cpp:1207` [readability-use-std-min-max] use `std::max` instead of `<`
- `src\server\gate\table.cpp:1210` [readability-math-missing-parentheses] '/' has higher precedence than '+'; add parentheses to explicitly specify the order of operations
- `src\server\gate\table.cpp:1316` [readability-function-size] function 'collect' exceeds recommended size/complexity thresholds
- `src\server\gate\table.cpp:1416` [readability-identifier-length] parameter name 'at' is too short, expected at least 3 characters
- `src\shared\link\link.cpp:13` [misc-include-cleaner] no header providing "std::chrono::steady_clock" is directly included
- `src\shared\link\link.cpp:15` [misc-include-cleaner] no header providing "std::uint64_t" is directly included
- `src\shared\link\link.cpp:22` [misc-include-cleaner] no header providing "game::net::Milliseconds" is directly included
- `src\shared\link\link.cpp:23` [misc-include-cleaner] no header providing "std::chrono::duration_cast" is directly included
- `src\shared\link\link.cpp:29` [misc-include-cleaner] no header providing "std::size_t" is directly included
- `src\shared\link\link.cpp:29` [misc-include-cleaner] no header providing "game::net::TcpStream" is directly included
- `src\shared\link\link.cpp:29` [misc-include-cleaner] no header providing "std::byte" is directly included
- `src\shared\link\link.cpp:30` [misc-include-cleaner] no header providing "game::net::NetResult" is directly included
- `src\shared\link\link.cpp:31` [misc-include-cleaner] no header providing "std::unexpected" is directly included
- `src\shared\link\link.cpp:35` [readability-function-size] function 'send_all' exceeds recommended size/complexity thresholds
- `src\shared\link\link.cpp:35` [misc-include-cleaner] no header providing "game::net::PollSet" is directly included
- `src\shared\link\link.cpp:47` [misc-include-cleaner] no header providing "game::net::PollEvents" is directly included
- `src\shared\link\link.cpp:51` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:61` [misc-include-cleaner] no header providing "std::ptrdiff_t" is directly included
- `src\shared\link\link.cpp:62` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:66` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:73` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:75` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:78` [readability-function-cognitive-complexity] function 'connect_to' has cognitive complexity of 11 (threshold 10)
- `src\shared\link\link.cpp:78` [misc-include-cleaner] no header providing "game::net::Endpoint" is directly included
- `src\shared\link\link.cpp:95` [misc-include-cleaner] no header providing "game::secure::RecordPipe" is directly included
- `src\shared\link\link.cpp:95` [misc-include-cleaner] no header providing "game::secure::PublicKey" is directly included
- `src\shared\link\link.cpp:97` [misc-include-cleaner] no header providing "game::secure::Result" is directly included
- `src\shared\link\link.cpp:97` [misc-include-cleaner] no header providing "game::secure::ClientHandshake" is directly included
- `src\shared\link\link.cpp:99` [misc-include-cleaner] no header providing "game::secure::ByteView" is directly included
- `src\shared\link\link.cpp:101` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:103` [misc-include-cleaner] no header providing "game::secure::kServerHelloBytes" is directly included
- `src\shared\link\link.cpp:104` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:106` [misc-include-cleaner] no header providing "game::secure::SessionKeys" is directly included
- `src\shared\link\link.cpp:113` [misc-include-cleaner] no header providing "game::secure::kMaxRecordBytes" is directly included
- `src\shared\link\link.cpp:114` [misc-include-cleaner] no header providing "game::secure::SealResult" is directly included
- `src\shared\link\link.cpp:119` [readability-function-cognitive-complexity] function 'open_one' has cognitive complexity of 11 (threshold 10)
- `src\shared\link\link.cpp:122` [misc-include-cleaner] no header providing "game::secure::kMaxPlainBytes" is directly included
- `src\shared\link\link.cpp:126` [misc-include-cleaner] no header providing "game::secure::OpenResult" is directly included
- `src\shared\link\link.cpp:133` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:137` [misc-include-cleaner] no header providing "game::protocol::Welcome" is directly included
- `src\shared\link\link.cpp:144` [misc-include-cleaner] no header providing "game::protocol::GameServerResult" is directly included
- `src\shared\link\link.cpp:144` [misc-include-cleaner] no header providing "game::protocol::decode_game_server" is directly included
- `src\shared\link\link.cpp:146` [misc-include-cleaner] no header providing "std::get_if" is directly included
- `src\shared\link\link.cpp:153` [misc-include-cleaner] no header providing "std::string_view" is directly included
- `src\shared\link\link.cpp:179` [misc-include-cleaner] no header providing "game::protocol::Hello" is directly included
- `src\shared\link\link.cpp:180` [misc-include-cleaner] no header providing "game::protocol::kVersion" is directly included
- `src\shared\link\link.cpp:184` [misc-include-cleaner] no header providing "game::protocol::encode" is directly included
- `src\shared\link\link.cpp:186` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:194` [misc-include-cleaner] no header providing "game::protocol::Pong" is directly included
- `src\shared\link\link.cpp:194` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'ping' of similar type are easily swapped by mistake
- `src\shared\link\link.cpp:194` [misc-include-cleaner] no header providing "std::chrono::milliseconds" is directly included
- `src\shared\link\link.cpp:198` [misc-include-cleaner] no header providing "game::protocol::Ping" is directly included
- `src\shared\link\link.cpp:201` [misc-include-cleaner] no header providing "game::protocol::encode" is directly included
- `src\shared\link\link.cpp:203` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:213` [misc-include-cleaner] no header providing "std::get_if" is directly included
- `src\server\gate\front.cpp:246` [readability-function-size] function 'flush_one' exceeds recommended size/complexity thresholds
- `src\server\gate\front.cpp:246` [readability-function-cognitive-complexity] function 'flush_one' has cognitive complexity of 12 (threshold 10)
- `src\server\gate\front.cpp:334` [readability-function-size] function 'handle_event' exceeds recommended size/complexity thresholds
- `src\server\gate\front.cpp:334` [readability-function-cognitive-complexity] function 'handle_event' has cognitive complexity of 13 (threshold 10)
- `src\server\gate\front.cpp:372` [readability-identifier-length] variable name 'at' is too short, expected at least 3 characters
- `src\server\gate\front.cpp:390` [readability-use-std-min-max] use `std::max` instead of `>`
- `src\server\gate\front.cpp:397` [readability-use-std-min-max] use `std::max` instead of `>`
- `src\server\gate\front.cpp:409` [readability-use-std-min-max] use `std::max` instead of `<`
- `src\server\gate\front.cpp:539` [misc-use-internal-linkage] function 'ipc_of' can be made static or moved into an anonymous namespace to enforce internal linkage
- `src\server\gate\front.cpp:551` [misc-use-internal-linkage] function 'open_realm' can be made static or moved into an anonymous namespace to enforce internal linkage
- `src\server\gate\front.cpp:572` [readability-function-cognitive-complexity] function 'serve' has cognitive complexity of 12 (threshold 10)

Đánh giá: không có cảnh báo tràn bộ đệm/đọc ngoài biên trong mã parse gói. `table.cpp:931` (unchecked-optional `*state.realm`): luồng clerk chỉ nhận câu hỏi sau khi mọi đường đẩy câu hỏi đã kiểm `realm.has_value()` (dòng 542–863) — tiền điều kiện đúng, chưa sửa, đề xuất thêm assert. `table.cpp:923` branch-clone: ĐÃ SỬA (gộp case kEnter/kResume).

## 2. Lỗi biên dịch / mã hoá (tách riêng)

- `clang-diagnostic-unused-command-line-argument` `/Zc:preprocessor`: do clang-tidy đọc cờ của cl, không phải lỗi mã.
- `prelude.hpp:7` unterminated `#pragma clang attribute push`: tidy phân tích header đứng riêng; cần kiểm cặp push/pop.
- Mã hoá nguồn: quét 794 tệp (.cpp/.hpp/.h/.mm/.lua/.cmake/.txt trong src, engine, Test, TOOLS, apple, android, cmake): 776 UTF-8 hợp lệ, 18 ASCII, **0 BOM, 0 GBK, 0 mơ hồ**. 23 tệp UTF-8 có ký tự ngoài ASCII trong đường Android/GLES (android_main.cpp, engine/gpu/gles/*, surface_android.cpp, android/probe_vulkan.cpp…), chỉ ở chú thích/chuỗi log. Lưu ý: `cmake/GameWarnings.cmake:15` ĐÃ bật `/utf-8` cho MSVC từ trước; không thay đổi gì thêm. Không đụng tệp dữ liệu (SERVER, DBC).

## 3. Theo check

| Số | Check |
|---:|---|
| 1803 | misc-include-cleaner |
| 219 | readability-identifier-length |
| 188 | modernize-use-designated-initializers |
| 174 | readability-function-size |
| 152 | cppcoreguidelines-pro-bounds-constant-array-index |
| 143 | readability-function-cognitive-complexity |
| 75 | misc-const-correctness |
| 71 | bugprone-easily-swappable-parameters |
| 65 | cppcoreguidelines-pro-bounds-pointer-arithmetic |
| 52 | cppcoreguidelines-avoid-c-arrays |
| 52 | modernize-avoid-c-arrays |
| 48 | cppcoreguidelines-pro-type-reinterpret-cast |
| 40 | readability-uppercase-literal-suffix |
| 27 | readability-math-missing-parentheses |
| 25 | readability-redundant-member-init |
| 23 | readability-use-std-min-max |
| 21 | readability-identifier-naming |
| 19 | bugprone-exception-escape |
| 19 | bugprone-invalid-enum-default-initialization |
| 19 | modernize-use-auto |
| 17 | cppcoreguidelines-special-member-functions |
| 15 | modernize-use-integer-sign-comparison |
| 15 | cppcoreguidelines-pro-bounds-array-to-pointer-decay |
| 15 | readability-container-contains |
| 13 | performance-move-const-arg |
| 12 | bugprone-multi-level-implicit-pointer-conversion |
| 11 | readability-use-anyofallof |
| 11 | cppcoreguidelines-avoid-non-const-global-variables |
| 9 | cppcoreguidelines-avoid-const-or-ref-data-members |
| 9 | misc-no-recursion |
| 8 | bugprone-implicit-widening-of-multiplication-result |
| 8 | readability-avoid-return-with-void-value |
| 8 | concurrency-mt-unsafe |
| 8 | bugprone-unused-return-value |
| 7 | performance-no-int-to-ptr |
| 6 | misc-use-internal-linkage |
| 6 | misc-misplaced-const |
| 5 | performance-string-view-conversions |
| 5 | readability-convert-member-functions-to-static |
| 5 | bugprone-unchecked-optional-access |
| 5 | readability-implicit-bool-conversion |
| 5 | bugprone-bitwise-pointer-cast |
| 5 | bugprone-suspicious-stringview-data-usage |
| 5 | modernize-use-std-numbers |
| 4 | misc-unused-using-decls |
| 4 | readability-simplify-boolean-expr |
| 4 | cert-err33-c |
| 4 | readability-qualified-auto |
| 4 | performance-no-automatic-move |
| 3 | performance-inefficient-vector-operation |
| 3 | readability-avoid-nested-conditional-operator |
| 3 | modernize-use-emplace |
| 2 | readability-container-size-empty |
| 2 | clang-analyzer-optin.performance.Padding |
| 2 | readability-make-member-function-const |
| 2 | bugprone-random-generator-seed |
| 2 | cert-msc32-c |
| 2 | cert-msc51-cpp |
| 2 | bugprone-unchecked-string-to-number-conversion |
| 2 | cert-err34-c |
| 2 | clang-analyzer-deadcode.DeadStores |
| 2 | performance-unnecessary-value-param |
| 2 | modernize-use-ranges |
| 2 | misc-use-anonymous-namespace |
| 2 | readability-suspicious-call-argument |
| 2 | cppcoreguidelines-owning-memory |
| 1 | clang-diagnostic-error |
| 1 | readability-redundant-inline-specifier |
| 1 | cppcoreguidelines-explicit-constructor |
| 1 | misc-explicit-constructor |
| 1 | performance-enum-size |
| 1 | misc-misleading-bidirectional |
| 1 | performance-use-std-move |
| 1 | readability-isolate-declaration |
| 1 | bugprone-command-processor |
| 1 | cert-env33-c |
| 1 | performance-unnecessary-copy-initialization |
| 1 | cppcoreguidelines-prefer-member-initializer |
| 1 | bugprone-branch-clone |
| 1 | readability-redundant-nested-if |
| 1 | modernize-return-braced-init-list |
| 1 | misc-redundant-expression |
| 1 | cppcoreguidelines-pro-type-const-cast |
| 1 | clang-analyzer-core.NullDereference |
| 1 | performance-faster-string-find |
| 1 | performance-prefer-single-char-overloads |
| 1 | bugprone-incorrect-roundings |
| 1 | modernize-pass-by-value |

## 4. Theo module

| Tổng | Module | 3 check lớn nhất |
|---:|---|---|
| 691 | src\client\app | misc-include-cleaner 618, readability-function-size 12, modernize-use-designated-initializers 11 |
| 596 | engine\gpu | misc-include-cleaner 396, misc-const-correctness 44, readability-function-size 23 |
| 534 | src\server\account | misc-include-cleaner 213, modernize-use-designated-initializers 157, readability-identifier-length 59 |
| 348 | src\client\place | misc-include-cleaner 120, cppcoreguidelines-pro-bounds-constant-array-index 97, readability-identifier-length 29 |
| 262 | engine\resource | misc-include-cleaner 110, cppcoreguidelines-pro-bounds-pointer-arithmetic 33, cppcoreguidelines-pro-type-reinterpret-cast 17 |
| 206 | Test\bench | misc-include-cleaner 26, cppcoreguidelines-pro-bounds-constant-array-index 21, readability-function-size 18 |
| 137 | engine\shader | misc-include-cleaner 98, readability-redundant-member-init 11, bugprone-easily-swappable-parameters 6 |
| 92 | engine\net | misc-include-cleaner 28, cppcoreguidelines-pro-bounds-constant-array-index 11, readability-identifier-length 9 |
| 77 | src\client\face | readability-function-size 21, readability-function-cognitive-complexity 16, readability-identifier-length 16 |
| 76 | src\server\config | cppcoreguidelines-avoid-c-arrays 30, modernize-avoid-c-arrays 30, misc-include-cleaner 12 |
| 60 | src\server\gate | readability-identifier-length 16, misc-include-cleaner 10, readability-function-size 9 |
| 51 | src\shared\link | misc-include-cleaner 37, bugprone-invalid-enum-default-initialization 10, readability-function-cognitive-complexity 2 |
| 49 | src\client\figure | readability-uppercase-literal-suffix 39, readability-use-std-min-max 5, readability-identifier-length 3 |
| 36 | src\server\store | misc-include-cleaner 16, cppcoreguidelines-pro-bounds-pointer-arithmetic 4, readability-function-cognitive-complexity 3 |
| 32 | Test\Resource | misc-include-cleaner 9, cppcoreguidelines-pro-type-reinterpret-cast 8, cppcoreguidelines-pro-bounds-pointer-arithmetic 4 |
| 22 | src\client\pack | misc-include-cleaner 17, cppcoreguidelines-pro-type-reinterpret-cast 2, cppcoreguidelines-avoid-c-arrays 1 |
| 22 | engine\audio | misc-include-cleaner 14, misc-const-correctness 5, cppcoreguidelines-owning-memory 2 |
| 21 | Test\Ui | bugprone-implicit-widening-of-multiplication-result 6, misc-include-cleaner 5, readability-function-size 4 |
| 17 | Test\Client | misc-include-cleaner 9, readability-identifier-naming 4, cppcoreguidelines-avoid-c-arrays 1 |
| 16 | src\server\guard | readability-identifier-length 5, readability-math-missing-parentheses 5, misc-include-cleaner 3 |
| 14 | Test\Server | misc-include-cleaner 9, readability-identifier-length 2, misc-misleading-bidirectional 1 |
| 14 | Test\Shared | misc-include-cleaner 10, readability-function-size 2, readability-function-cognitive-complexity 1 |
| 13 | engine\render | readability-use-anyofallof 4, misc-include-cleaner 4, readability-function-size 2 |
| 13 | src\shared\secure | misc-include-cleaner 6, cppcoreguidelines-pro-bounds-array-to-pointer-decay 3, cppcoreguidelines-avoid-c-arrays 1 |
| 12 | Test\Control | modernize-use-std-numbers 5, readability-identifier-length 4, misc-include-cleaner 1 |
| 11 | TOOLS\server | readability-identifier-length 3, readability-function-cognitive-complexity 2, misc-include-cleaner 2 |
| 10 | Test\Collision | readability-identifier-length 8, bugprone-easily-swappable-parameters 1, misc-include-cleaner 1 |
| 10 | Test\Gui | misc-include-cleaner 3, misc-unused-using-decls 3, readability-identifier-length 2 |
| 10 | engine\core | misc-include-cleaner 10 |
| 9 | Test\Metrics | readability-function-size 5, readability-function-cognitive-complexity 1, readability-container-contains 1 |
| 9 | Test\Net | readability-function-size 3, readability-function-cognitive-complexity 3, cppcoreguidelines-pro-bounds-constant-array-index 2 |
| 8 | src\server\metrics | readability-function-size 5, readability-function-cognitive-complexity 2, performance-unnecessary-value-param 1 |
| 8 | engine\capture | readability-identifier-length 4, bugprone-easily-swappable-parameters 2, cppcoreguidelines-avoid-const-or-ref-data-members 2 |
| 7 | Test\Gate | readability-identifier-length 3, misc-include-cleaner 2, misc-const-correctness 1 |
| 5 | engine\io | bugprone-suspicious-stringview-data-usage 2, misc-include-cleaner 1, misc-use-anonymous-namespace 1 |
| 4 | src\client\book | readability-function-cognitive-complexity 2, readability-function-size 1, readability-identifier-length 1 |
| 4 | Test\Gpu | misc-include-cleaner 3, misc-misplaced-const 1 |
| 3 | Test\Xml | bugprone-exception-escape 3 |
| 3 | Test\Render | misc-include-cleaner 3 |
| 2 | Test\support | readability-function-cognitive-complexity 2 |
| 2 | Test\Window | readability-math-missing-parentheses 2 |
| 2 | Test\Config | readability-identifier-length 2 |
| 2 | Test\Skill | readability-container-contains 1, readability-identifier-length 1 |
| 2 | Test\Avatar | readability-function-size 1, readability-function-cognitive-complexity 1 |
| 1 | engine\window | readability-function-size 1 |
| 1 | Test\Supervise | readability-identifier-naming 1 |
| 1 | src\server\supervise | readability-function-size 1 |
| 1 | Test\Process | bugprone-exception-escape 1 |
| 1 | Test\Nav | misc-include-cleaner 1 |

## 5. Bugprone / cert / concurrency / analyzer (đầy đủ)

- `Test\Collision\building_height_tests.cpp:35` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'put_triangle' of similar type ('float') are easily swapped by mistake
- `src\client\app\client\display\graphic\prelude.hpp:461` [bugprone-easily-swappable-parameters] 3 adjacent parameters of 'surface_y' of similar type ('float') are easily swapped by mistake
- `src\client\app\client\display\graphic\prelude.hpp:1239` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'identity_of' of convertible types are easily swapped by mistake
- `TOOLS\server\metrics_snap.cpp:334` [bugprone-exception-escape] an exception may be thrown in function 'main' which should not throw exceptions
- `src\server\account\cap.hpp:19` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'const std::uint64_t' (aka 'const unsigned long long') of a multiplication performed in t
- `src\server\account\realm.cpp:53` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'Realm' of similar type ('net::Endpoint') are easily swapped by mistake
- `src\server\account\realm.cpp:70` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'login' of similar type ('std::string_view') are easily swapped by mistake
- `engine\net\shard.hpp:35` [bugprone-invalid-enum-default-initialization] enum value of type 'Op' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\server\account\rpc.cpp:258` [bugprone-easily-swappable-parameters] 3 adjacent parameters of 'account_call' of similar type ('std::string_view') are easily swapped by mistake
- `src\server\account\rpc.cpp:302` [bugprone-easily-swappable-parameters] 3 adjacent parameters of 'read_account_call' of similar type ('std::string &') are easily swapped by mistake
- `src\server\account\rpc.cpp:323` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'read_character_call' of similar type ('std::uint16_t &') are easily swapped by mistake
- `src\server\account\rpc.cpp:524` [clang-analyzer-optin.performance.Padding] Excessive padding in 'struct game::account::(anonymous namespace)::Shared' (103 padding bytes, where 39 is optimal). Optimal fields order: j
- `engine\shader\spirv.cpp:135` [bugprone-exception-escape] an exception may be thrown in function 'Module' which should not throw exceptions
- `engine\shader\spirv.cpp:261` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'define' of convertible types are easily swapped by mistake
- `engine\shader\spirv.cpp:483` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'numeric' of convertible types are easily swapped by mistake
- `engine\shader\spirv.cpp:527` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'struct_size' of convertible types are easily swapped by mistake
- `src\server\account\standing.hpp:35` [bugprone-exception-escape] an exception may be thrown in function 'StandingCache' which should not throw exceptions
- `src\client\app\client\display\graphic\state.hpp:9` [clang-analyzer-optin.performance.Padding] Excessive padding in 'struct game::client::Display::State' (63 padding bytes, where 15 is optimal). Optimal fields order: world, light, play
- `src\client\place\fx\field.cpp:72` [bugprone-easily-swappable-parameters] 3 adjacent parameters of 'set_size' of similar type ('float') are easily swapped by mistake
- `src\client\place\fx\field.cpp:83` [bugprone-easily-swappable-parameters] 3 adjacent parameters of 'grow' of similar type ('float') are easily swapped by mistake
- `src\client\place\fx\field.cpp:462` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'stage_float' of convertible types are easily swapped by mistake
- `src\client\place\fx\field.cpp:581` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'spawn' of convertible types are easily swapped by mistake
- `src\client\place\fx\field.cpp:601` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'emission_count' of convertible types are easily swapped by mistake
- `Test\bench\gate_attack.cpp:57` [cert-err33-c] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `Test\bench\gate_attack.cpp:128` [cert-err33-c] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `Test\bench\gate_attack.cpp:131` [bugprone-exception-escape] an exception may be thrown in function '~Phase' which should not throw exceptions
- `Test\bench\gate_attack.cpp:143` [cert-err33-c] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `Test\bench\gate_attack.cpp:156` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'open_socket' of convertible types are easily swapped by mistake
- `Test\bench\gate_attack.cpp:207` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'closed_within' of convertible types are easily swapped by mistake
- `Test\bench\gate_attack.cpp:256` [bugprone-unchecked-optional-access] unchecked access to optional value
- `Test\bench\gate_attack.cpp:267` [bugprone-unchecked-optional-access] unchecked access to optional value
- `Test\bench\gate_attack.cpp:400` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'take_ticket' of similar type ('std::string_view') are easily swapped by mistake
- `Test\bench\gate_attack.cpp:425` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'login' of similar type ('std::string_view') are easily swapped by mistake
- `Test\bench\gate_attack.cpp:457` [bugprone-invalid-enum-default-initialization] enum value of type 'ErrorCode' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `Test\bench\gate_attack.cpp:469` [concurrency-mt-unsafe] function is not thread safe
- `Test\bench\gate_attack.cpp:503` [concurrency-mt-unsafe] function is not thread safe
- `Test\bench\gate_attack.cpp:545` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'run_threads' of similar type ('int') are easily swapped by mistake
- `Test\bench\gate_attack.cpp:579` [concurrency-mt-unsafe] function is not thread safe
- `Test\bench\gate_attack.cpp:584` [bugprone-command-processor,cert-env33-c] calling 'system' uses a command processor
- `Test\bench\gate_attack.cpp:584` [concurrency-mt-unsafe] function is not thread safe
- `Test\bench\gate_attack.cpp:613` [bugprone-invalid-enum-default-initialization] enum value of type 'ErrorCode' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `Test\bench\gate_attack.cpp:619` [bugprone-invalid-enum-default-initialization] enum value of type 'ErrorCode' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `Test\bench\gate_attack.cpp:647` [bugprone-invalid-enum-default-initialization] enum value of type 'ErrorCode' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `Test\bench\gate_attack.cpp:669` [bugprone-unchecked-optional-access] unchecked access to optional value
- `Test\bench\gate_attack.cpp:872` [bugprone-random-generator-seed,cert-msc32-c,cert-msc51-cpp] random number generator seeded with a constant value will generate a predictable sequence of values
- `Test\bench\gate_attack.cpp:941` [bugprone-random-generator-seed,cert-msc32-c,cert-msc51-cpp] random number generator seeded with a constant value will generate a predictable sequence of values
- `Test\bench\gate_attack.cpp:965` [concurrency-mt-unsafe] function is not thread safe
- `Test\bench\gate_attack.cpp:1012` [bugprone-invalid-enum-default-initialization] enum value of type 'ErrorCode' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `Test\bench\gate_attack.cpp:1024` [concurrency-mt-unsafe] function is not thread safe
- `Test\bench\gate_attack.cpp:1052` [bugprone-invalid-enum-default-initialization] enum value of type 'ErrorCode' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `Test\bench\gate_attack.cpp:1054` [bugprone-invalid-enum-default-initialization] enum value of type 'ErrorCode' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `Test\bench\gate_attack.cpp:1085` [concurrency-mt-unsafe] function is not thread safe
- `Test\bench\gate_attack.cpp:1104` [concurrency-mt-unsafe] function is not thread safe
- `Test\bench\gate_attack.cpp:1304` [bugprone-exception-escape] an exception may be thrown in function 'main' which should not throw exceptions
- `Test\bench\gate_attack.cpp:1315` [bugprone-unchecked-string-to-number-conversion,cert-err34-c] 'atoi' used to convert a string to an integer value, but function will not report conversion errors; consider using 'strtol' instead
- `Test\bench\gate_attack.cpp:1316` [bugprone-unchecked-string-to-number-conversion,cert-err34-c] 'atoi' used to convert a string to an integer value, but function will not report conversion errors; consider using 'strtol' instead
- `src\client\face\ui\text.cpp:1136` [clang-analyzer-deadcode.DeadStores] Value stored to 'stop' during its initialization is never read
- `engine\net\reactor_win32.cpp:56` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'size_t' (aka 'unsigned long long') of a multiplication performed in type 'DWORD' (aka 'u
- `engine\net\reactor_win32.cpp:177` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'LPFN_ACCEPTEX *' (aka 'int (**)(unsigned long long, unsigned long long, void *, unsigned long, unsigned 
- `engine\net\reactor_win32.cpp:180` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'LPFN_GETACCEPTEXSOCKADDRS *' (aka 'void (**)(void *, unsigned long, unsigned long, unsigned long, struct
- `engine\net\reactor_win32.cpp:210` [bugprone-exception-escape] an exception may be thrown in function 'post_read' which should not throw exceptions
- `engine\net\reactor_win32.cpp:238` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'apply_write' of convertible types are easily swapped by mistake
- `engine\net\reactor_win32.cpp:396` [bugprone-exception-escape] an exception may be thrown in function '~ReactorNative' which should not throw exceptions
- `engine\net\reactor_win32.cpp:409` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `engine\net\reactor_win32.cpp:476` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'note_read' of similar type are easily swapped by mistake
- `engine\shader\manifest.cpp:230` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'parse' of similar type ('std::string_view') are easily swapped by mistake
- `engine\gpu\gles\load.cpp:13` [bugprone-bitwise-pointer-cast] do not use 'memcpy' to cast between pointers
- `engine\gpu\gles\load.cpp:13` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'const unsigned char *(**)(unsigned int)' to 'void *', please use explicit cast
- `engine\gpu\gles\load.cpp:13` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'void **' to 'const void *', please use explicit cast
- `engine\capture\deflate.cpp:397` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'add' of similar type ('std::size_t') are easily swapped by mistake
- `engine\capture\deflate.cpp:793` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'adler32_combine' of convertible types are easily swapped by mistake
- `Test\Ui\ui_text_tests.cpp:89` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'quad_at' of convertible types are easily swapped by mistake
- `Test\Ui\ui_text_tests.cpp:151` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'size_type' (aka 'unsigned long long') of a multiplication performed in type 'int'
- `Test\Ui\ui_text_tests.cpp:229` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'size_type' (aka 'unsigned long long') of a multiplication performed in type 'int'
- `Test\Ui\ui_text_tests.cpp:264` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'size_type' (aka 'unsigned long long') of a multiplication performed in type 'int'
- `Test\Ui\ui_text_tests.cpp:265` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'size_type' (aka 'unsigned long long') of a multiplication performed in type 'int'
- `Test\Ui\ui_text_tests.cpp:342` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'size_type' (aka 'unsigned long long') of a multiplication performed in type 'int'
- `Test\Ui\ui_text_tests.cpp:343` [bugprone-implicit-widening-of-multiplication-result] performing an implicit widening conversion to type 'size_type' (aka 'unsigned long long') of a multiplication performed in type 'int'
- `src\client\app\client\viewer\sdl_input.cpp:100` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'place' of similar type ('float') are easily swapped by mistake
- `src\client\place\fx\system.cpp:14` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'number_of' of convertible types are easily swapped by mistake
- `Test\Xml\xml_tests.cpp:97` [bugprone-exception-escape] an exception may be thrown in function 'parse_reads_utf16_with_bom' which should not throw exceptions
- `Test\Xml\xml_tests.cpp:110` [bugprone-exception-escape] an exception may be thrown in function 'parse_skips_utf8_bom' which should not throw exceptions
- `Test\Xml\xml_tests.cpp:118` [bugprone-exception-escape] an exception may be thrown in function 'parse_rejects_broken_utf16' which should not throw exceptions
- `src\server\account\book.cpp:27` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'summary_of' of similar type ('std::uint16_t') are easily swapped by mistake
- `src\server\gate\table.cpp:483` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'send_reject' of convertible types are easily swapped by mistake
- `src\server\gate\table.cpp:694` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'open_session' of convertible types are easily swapped by mistake
- `src\server\gate\table.cpp:796` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'finish_enter' of convertible types are easily swapped by mistake
- `src\server\gate\table.cpp:923` [bugprone-branch-clone] switch has 2 consecutive identical branches
- `src\server\gate\table.cpp:931` [bugprone-unchecked-optional-access] unchecked access to optional value
- `engine\resource\ogre_mesh.cpp:107` [bugprone-exception-escape] an exception may be thrown in function 'line' which should not throw exceptions
- `engine\resource\ogre_mesh.cpp:738` [bugprone-suspicious-stringview-data-usage] result of a `data()` call may not be null terminated, provide size information to the callee to prevent potential issues
- `engine\resource\ogre_mesh.cpp:741` [bugprone-suspicious-stringview-data-usage] result of a `data()` call may not be null terminated, provide size information to the callee to prevent potential issues
- `engine\resource\ogre_mesh.cpp:842` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'cache_file' of similar type ('std::string_view') are easily swapped by mistake
- `engine\resource\ogre_mesh.cpp:851` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'note_lane' of convertible types are easily swapped by mistake
- `engine\resource\ogre_mesh.cpp:851` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'note_lane' of convertible types are easily swapped by mistake
- `engine\resource\ogre_mesh.cpp:901` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'cache_fresh' of similar type ('std::string_view') are easily swapped by mistake
- `engine\resource\ogre_mesh.cpp:1023` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `engine\resource\ogre_mesh.cpp:1024` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `engine\gpu\gles\context_wgl.cpp:125` [bugprone-bitwise-pointer-cast] do not use 'memcpy' to cast between pointers
- `engine\gpu\gles\context_wgl.cpp:125` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'void **' to 'void *', please use explicit cast
- `engine\gpu\gles\context_wgl.cpp:125` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'PROC *' (aka 'long long (**)()') to 'const void *', please use explicit cast
- `engine\gpu\gles\context_wgl.cpp:272` [bugprone-bitwise-pointer-cast] do not use 'memcpy' to cast between pointers
- `engine\gpu\gles\context_wgl.cpp:272` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'CreateAttribs *' (aka 'struct HGLRC__ *(**)(struct HDC__ *, struct HGLRC__ *, const int *)') to 'void *'
- `engine\gpu\gles\context_wgl.cpp:272` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'void **' to 'const void *', please use explicit cast
- `engine\gpu\gles\context_wgl.cpp:273` [bugprone-bitwise-pointer-cast] do not use 'memcpy' to cast between pointers
- `engine\gpu\gles\context_wgl.cpp:273` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'ChooseFormat *' (aka 'int (**)(struct HDC__ *, const int *, const float *, unsigned int, int *, unsigned
- `engine\gpu\gles\context_wgl.cpp:273` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'void **' to 'const void *', please use explicit cast
- `engine\gpu\gles\context_wgl.cpp:274` [bugprone-bitwise-pointer-cast] do not use 'memcpy' to cast between pointers
- `engine\gpu\gles\context_wgl.cpp:274` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'SwapInterval *' (aka 'int (**)(int)') to 'void *', please use explicit cast
- `engine\gpu\gles\context_wgl.cpp:274` [bugprone-multi-level-implicit-pointer-conversion] multilevel pointer conversion from 'void **' to 'const void *', please use explicit cast
- `Test\Control\pilot_tests.cpp:53` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'map_with_wall' of convertible types are easily swapped by mistake
- `src\client\place\collision\mesh.cpp:34` [bugprone-exception-escape] an exception may be thrown in function 'VertexMap' which should not throw exceptions
- `src\client\face\ui\panel\desk.cpp:588` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'shelf_keys' of similar type ('std::uint8_t') are easily swapped by mistake
- `engine\resource\dds.cpp:111` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'copy_level' of similar type ('std::uint32_t') are easily swapped by mistake
- `src\server\guard\pace.cpp:29` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'measure' of convertible types are easily swapped by mistake
- `src\server\guard\pace.cpp:50` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'reset' of similar type ('std::uint32_t') are easily swapped by mistake
- `Test\Resource\ogre_mesh_tests.cpp:103` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `Test\Resource\ogre_mesh_tests.cpp:136` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `Test\Resource\ogre_mesh_tests.cpp:180` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `Test\Resource\ogre_mesh_tests.cpp:214` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `Test\Resource\ogre_mesh_tests.cpp:258` [cert-err33-c] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `src\client\place\collision\opcode_tree.cpp:226` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'set_axis' of convertible types are easily swapped by mistake
- `src\client\place\collision\opcode_tree.cpp:288` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'fix_extent_reference' of convertible types are easily swapped by mistake
- `src\client\place\collision\opcode_tree.cpp:288` [bugprone-easily-swappable-parameters] 3 adjacent parameters of 'fix_extent_reference' of similar type ('float') are easily swapped by mistake
- `src\client\place\collision\opcode_tree.cpp:306` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'grows' of convertible types are easily swapped by mistake
- `src\client\place\collision\opcode_tree.cpp:306` [bugprone-easily-swappable-parameters] 3 adjacent parameters of 'grows' of similar type ('float') are easily swapped by mistake
- `src\client\place\collision\model.cpp:68` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'test_triangle' of similar type ('Point3') are easily swapped by mistake
- `src\client\place\collision\model.cpp:125` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'clip_axis' of similar type ('float') are easily swapped by mistake
- `src\client\place\collision\model.cpp:155` [bugprone-exception-escape] an exception may be thrown in function 'push_child' which should not throw exceptions
- `src\client\place\collision\model.cpp:178` [bugprone-exception-escape] an exception may be thrown in function 'walk_tree' which should not throw exceptions
- `Test\Resource\dds_tests.cpp:149` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'tltx_file' of convertible types are easily swapped by mistake
- `Test\Process\process_tests.cpp:60` [bugprone-exception-escape] an exception may be thrown in function '~SpacedChild' which should not throw exceptions
- `src\client\place\fx\strip.cpp:140` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'mix_fade' of convertible types are easily swapped by mistake
- `src\client\place\fx\strip.cpp:164` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'push_trail_point' of convertible types are easily swapped by mistake
- `engine\io\file.cpp:115` [bugprone-suspicious-stringview-data-usage] result of a `data()` call may not be null terminated, provide size information to the callee to prevent potential issues
- `engine\io\file.cpp:118` [bugprone-suspicious-stringview-data-usage] result of a `data()` call may not be null terminated, provide size information to the callee to prevent potential issues
- `Test\bench\core_bench.cpp:181` [bugprone-exception-escape] an exception may be thrown in function 'main' which should not throw exceptions
- `src\server\account\rules.cpp:401` [bugprone-exception-escape] an exception may be thrown in function 'look_ok' which should not throw exceptions
- `src\shared\link\link.cpp:51` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:62` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:66` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:73` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:75` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:101` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:104` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:133` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:186` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `src\shared\link\link.cpp:194` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'ping' of similar type are easily swapped by mistake
- `src\shared\link\link.cpp:203` [bugprone-invalid-enum-default-initialization] enum value of type 'LinkError' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `engine\shader\package.cpp:342` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'package_path' of similar type ('std::string_view') are easily swapped by mistake
- `src\client\app\client\world\world.cpp:169` [bugprone-exception-escape] an exception may be thrown in function 'escapes_model' which should not throw exceptions
- `src\client\app\client\world\world.cpp:177` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'add_figure_mesh' of similar type ('const std::filesystem::path &') are easily swapped by mistake
- `engine\gpu\gles\commands.cpp:100` [bugprone-easily-swappable-parameters] 4 adjacent parameters of 'viewport_of' of similar type ('float') are easily swapped by mistake
- `engine\gpu\gles\commands.cpp:274` [clang-analyzer-core.NullDereference] Access to field 'height' results in a dereference of a null pointer (loaded from variable 'first')
- `engine\gpu\gles\commands.cpp:642` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'copy_buffer' of similar type ('BufferHandle') are easily swapped by mistake
- `src\client\place\fx\billboard.cpp:72` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'push_corner' of similar type ('float') are easily swapped by mistake
- `src\client\place\fx\billboard.cpp:185` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'link_side' of similar type ('Vec3') are easily swapped by mistake
- `src\client\place\fx\billboard.cpp:259` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'chain_offset' of similar type ('Vec3') are easily swapped by mistake
- `engine\audio\detail\native.cpp:43` [bugprone-invalid-enum-default-initialization] enum value of type 'ma_device_type' initialized with invalid value of 0, enum doesn't have a zero-value enumerator
- `engine\shader\reflection.cpp:455` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'check_interface' of similar type ('const StageReflection &') are easily swapped by mistake
- `src\client\place\fx\script.cpp:121` [bugprone-suspicious-stringview-data-usage] result of a `data()` call may not be null terminated, provide size information to the callee to prevent potential issues
- `src\client\place\fx\script.cpp:138` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'number' of convertible types are easily swapped by mistake
- `src\shared\secure\password.cpp:53` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'ipc_open' of similar type ('ByteView') are easily swapped by mistake
- `src\client\app\client\display\graphic\play.cpp:347` [bugprone-unchecked-optional-access] unchecked access to optional value
- `engine\gpu\gles\swapchain.cpp:17` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'GlSwapchain' of similar type ('std::uint32_t') are easily swapped by mistake
- `engine\gpu\gles\device.cpp:254` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'set_attribute' of convertible types are easily swapped by mistake
- `src\client\app\client\map\liquid.cpp:304` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'cell_along' of convertible types are easily swapped by mistake
- `src\client\app\client\map\liquid.cpp:387` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'opens_material' of similar type ('std::string_view') are easily swapped by mistake
- `src\client\app\client\display\graphic\frame.cpp:36` [bugprone-exception-escape] an exception may be thrown in function '(lambda at D:\THIENLONG\src\client\app\client\display\graphic\frame.cpp:36:52)' which should not thr
- `src\client\app\client\display\graphic\frame.cpp:38` [bugprone-unused-return-value] the value returned by this function should not be disregarded; neglecting it may lead to errors
- `src\client\app\client\display\graphic\frame.cpp:186` [clang-analyzer-deadcode.DeadStores] Value stored to 'has_astc' during its initialization is never read
- `engine\resource\upload.cpp:781` [bugprone-incorrect-roundings] casting (double + 0.5) to integer leads to incorrect rounding; consider using lround (#include <cmath>) instead
- `src\server\account\sql.cpp:77` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'cell' of similar type ('std::size_t') are easily swapped by mistake
- `src\server\account\sql.cpp:138` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'note_attempt' of similar type ('std::string_view') are easily swapped by mistake
- `src\server\account\sql.cpp:232` [bugprone-easily-swappable-parameters] 3 adjacent parameters of 'insert_account' of similar type ('std::string_view') are easily swapped by mistake
- `src\server\account\sql.cpp:373` [bugprone-easily-swappable-parameters] 2 adjacent parameters of 'create_account' of similar type ('std::string_view') are easily swapped by mistake

## 6. Đã sửa (đợt 1) — sao lưu `build/backup-tidy-fix-20261013-164652/`, `build/backup-asan-20261013-165339/`

| Tệp | Cảnh báo | Sửa |
|---|---|---|
| engine/gpu/gles/commands.cpp:274 | clang-analyzer-core.NullDereference | Thêm kiểm `first == nullptr` (pass không có color lẫn depth) → reject(kBad) thay vì deref null |
| src/server/gate/table.cpp:923 | bugprone-branch-clone | Gộp `case kEnter:` / `case kResume:` |
| engine/resource/upload.cpp:781 | bugprone-incorrect-roundings | `std::lround(clamped * last)` |
| TOOLS/server/gate_load.cpp:1037 | catch(...) nuốt im lặng | Thêm catch `std::exception` ghi what() ra stderr, catch(...) ghi log; thêm `<cstdio>`, `<exception>` |
| cmake/GameSanitize.cmake, CMakePresets.json | — | Preset `msvc-asan` (cl `/fsanitize=address /Zi`, link `/INCREMENTAL:NO /DEBUG`, gỡ /RTC*), test preset đặt PATH tới `clang_rt.asan_dynamic-x86_64.dll` qua `$env{VCToolsInstallDir}` |

## 7. catch(...) — thực tế chỉ có 5 chỗ (không phải 23)

| Vị trí | Loại | Ghi log |
|---|---|---|
| src/client/app/client/display/graphic/frame.cpp:21 | dtor (không được ném) | Có (stderr) |
| src/client/app/client/android_main.cpp:197 | ranh giới (nạp cảnh, NativeActivity) | Có (log_error) |
| src/client/app/client/android_main.cpp:626 | ranh giới (probe nền tảng) | Có |
| src/client/app/client/main.cpp:384 | ranh giới main | Có |
| TOOLS/server/gate_load.cpp:1037 | ranh giới main — trước đó NUỐT IM LẶNG | Đã sửa → Có |

## 8. ASan (MSVC)

Build `build/msvc-asan` thành công (1039 bước). ctest: 86/91 test đã xong không có báo cáo AddressSanitizer nào; các fail giống hệt bản release (ui_quest, ui_create: golden rỗng; config_tests, server_data_lint: thiếu SERVER/scenes, tables). gui_real_tests chạy rất chậm dưới ASan (>40 phút), chưa có kết quả khi viết báo cáo. Chưa cần `_DISABLE_VECTOR_ANNOTATION`.

## 9. Tiến độ đợt 2 (2026-10-13 17:40–17:56)

- ASan `gui_real_tests` (ctest PID 19264 / exe 36640, chạy từ khoảng 17:00) treo hơn 45 phút, không có báo cáo AddressSanitizer nào trước khi treo → ĐÃ DỪNG lúc 17:50. Kết quả ASan: 91/92 test đã chạy xong, 0 lỗi ASan; gui_real_tests không có kết luận (bản release cũng crash ở bài này do thiếu hoạt ảnh).
- ctest PID 26052 (`-C Release -R ui_quest|...|gui_real`, msvc-release) KHÔNG phải của executor tidy-fix, nên không động vào.
- Build `build/tidy-fix` (preset msvc-release, -B riêng, giữ BUILD.lock 17:45–17:54): 1039/1039 bước OK. ctest **88/92** (trước đó 87/92). Fail: ui_quest (golden), gui_real (hoạt ảnh), config_tests và server_data_lint (thiếu SERVER/scenes, tables).

| Module | Check | Đã sửa |
|---|---|---:|
| src/client/app (prelude.hpp) | clang-diagnostic-error: pragma push không có pop | 1 |
| src/client/figure (char_camera.hpp) | readability-uppercase-literal-suffix | 27 dòng (39 cảnh báo) |
| src/client/app, src/client/face | readability-container-contains | 5 |
| engine/resource, engine/shader | redundant-member-init, container-contains | 7 (+10 ở ogre_mesh.cpp, đã có trong cây làm việc nhưng CHƯA commit vì vướng thay đổi chưa commit của người khác) |
| src/server/account, src/server/gate | redundant-member-init, implicit-widening | 4 |
| engine/net | implicit-widening | 1 |
| Test/*, TOOLS/server | uppercase, contains, redundant-member-init | 10 |

Commit (theo thứ tự): 97ed65b (P0), 9d2b4c5 (msvc-asan), ff730cd (prelude pragma), b28ab83 (widening), 5ee414f (readability auto-fix). Chỉ stage phần thay đổi của executor (patch từ bản sao lưu), không kèm các thay đổi chưa commit khác trong cùng tệp.

Không sửa (có lý do): `rpc.cpp` (clang-tidy dừng vì hàm `frame_of`/`read_call` không dùng trên Windows; chúng là nhánh POSIX), `frame.cpp:186` và `text.cpp:1136` dead-store (bị coi là dương tính giả theo nền tảng), `reactor_win32.cpp:409` và `ogre_mesh.cpp:1023` unused-return (bỏ qua có chủ ý: buffer IO đang chờ, cache best-effort), `table.cpp:931` (đúng tiền điều kiện), `file.cpp:115` stringview-data (đã truyền size).
Chưa làm: misc-include-cleaner (1.803; fix-it tự động có thể bỏ include cần cho Android/iOS nên không chạy đại trà), function-size/cognitive-complexity (cần tách hàm), quét lại toàn bộ để có số "sau". clang-format 23 của LLVM báo lệch sẵn có ở metrics_tests, dds_tests, skill_tests, gate_attack, compiler.cpp, slang.cpp (bản sao lưu cũng lệch, không do đợt này).
