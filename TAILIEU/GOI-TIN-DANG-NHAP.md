# Trường của gói tin đăng nhập (suy từ hàm Read trong Game.exe)

Sinh bằng `TOOLS/port/ghidra/packet_fields.py` từ `TAILIEU/ghidra/login_packets.txt`.


## Packets::CLConnect

Hàm Read: `FUN_140833910 @ 0x140833910`

```
  đọc gói + 0x18 cỡ 1
  đọc gói + 0x1c cỡ 4
  đọc gói + 0x20 cỡ 0x32
  đọc gói + 0x54 cỡ 4
  đọc gói + 0x58 cỡ 1
  đọc gói + 0x59 cỡ 0x20
  đọc gói + 0x7c cỡ 4
  đọc gói + 0x80 cỡ 4
  đọc gói + 0x84 cỡ 0x18
}
```


## Packets::LCRetConnect

Hàm Read: `FUN_1408371a0 @ 0x1408371a0`

```
  đọc gói + 0x50 cỡ 4
  đọc gói + 0x30 cỡ 4
  đọc gói + 0x18 cỡ 0x18
  đọc gói + 0x4c cỡ 4
  đọc gói + 0x34 cỡ 0x18
  đọc gói + 0x54 cỡ 9
  đọc gói + 0x60 cỡ 4
  đọc gói + 100 cỡ 1
}
```


## Packets::CLAskLogin

Hàm Read: `FUN_140833b30 @ 0x140833b30`

```
  đọc gói + 0x18 cỡ 0x32
  đọc gói + 0x1a0 cỡ 4
  đọc gói + 0x4b cỡ *(undefined4 *)(param_1 + 0x1a0)
  đọc gói + 0x1a4 cỡ 4
  đọc gói + 0x1a8 cỡ 9
  đọc gói + 0x1b1 cỡ 0x20
  đọc gói + 0x1d2 cỡ 0x10
  đọc gói + 0x1e2 cỡ 0x80
  đọc gói + 0x262 cỡ 0x80
  đọc gói + 0x2e8 cỡ 4
  đọc gói + 0x2ec cỡ 4
  đọc gói + 0x2e4 cỡ 4
  đọc gói + 0x2f0 cỡ 1
  đọc gói + 0x2f1 cỡ 1
  đọc gói + 0x2f2 cỡ 1
  đọc gói + 0x2f3 cỡ 0x200
  đọc gói + 0x4f4 cỡ 4
  đọc gói + 0x4f8 cỡ 1
  đọc gói + 0x4f9 cỡ 0x14
  đọc gói + 0x510 cỡ 4
}
```


## Packets::LCRetLogin

Hàm Read: `FUN_1408319e0 @ 0x1408319e0`

```
  đọc gói + 0x18 cỡ 0x32
  đọc gói + 0x4c cỡ 4
  đọc gói + 0x50 cỡ 0xf
  đọc gói + 0x60 cỡ 4
  đọc gói + 100 cỡ 1
  đọc gói + 0x68 cỡ 4
  if ((*(int *)(param_1 + 0x4c) == 0x2f) || (*(int *)(param_1 + 0x4c) == 0x4b)) {
    đọc gói + 0x6c cỡ 4
  }
  đọc gói + 0x70 cỡ 1
  đọc gói + 0x74 cỡ 4
  if (*(int *)(param_1 + 0x4c) == 0x42) {
    đọc gói + 0x78 cỡ 1
    đọc gói + 0x7a cỡ 2
    if ((ushort)(*(short *)(param_1 + 0x7a) - 1U) < 0x100) {
      đọc gói + 0x7c cỡ (longlong)*(short *)(param_1 + 0x7a)
    }
  }
  if (*(int *)(param_1 + 0x4c) == 0x53) {
    đọc gói + 0x180 cỡ 4
  }
}
```


## Packets::CLAskCharList

Hàm Read: `FUN_1408341b0 @ 0x1408341b0`

```
  đọc gói + 0x18 cỡ 0x32
}
```


## Packets::LCRetCharList

Không có hàm đọc trường (gói rỗng hoặc chỉ mang kiểu).


## Packets::CLCheckAllowCreateChar

Không có hàm đọc trường (gói rỗng hoặc chỉ mang kiểu).


## Packets::LCRetCheckAllowCreateChar

Hàm Read: `FUN_14077de90 @ 0x14077de90`

```
  đọc gói + 0x18 cỡ 4
}
```


## Packets::CLAskCreateChar

Hàm Read: `FUN_1408351a0 @ 0x1408351a0`

```
  đọc gói + 0x18 cỡ 0x1e
  đọc gói + 0x38 cỡ 4
  đọc gói + 0x3c cỡ 1
  đọc gói + 0x3d cỡ 1
  đọc gói + 0x40 cỡ 4
  đọc gói + 0x44 cỡ 4
  đọc gói + 0x48 cỡ 1
  đọc gói + 0x4c cỡ 4
  đọc gói + 0x54 cỡ 4
  đọc gói + 0x50 cỡ 4
  đọc gói + 0x58 cỡ 0x20
  đọc gói + 0xb9 cỡ 0x33
  đọc gói + 0x7c cỡ 4
  đọc gói + 0x80 cỡ 4
}
```


## Packets::LCRetCreateChar

Không có hàm đọc trường (gói rỗng hoặc chỉ mang kiểu).


## Packets::CLAskDeleteChar

Hàm Read: `FUN_140834e80 @ 0x140834e80`

```
  đọc gói + 0x1c cỡ 4
  đọc gói + 0x18 cỡ 4
  đọc gói + 0x20 cỡ 0x33
}
```


## Packets::LCRetDeleteChar

Không có hàm đọc trường (gói rỗng hoặc chỉ mang kiểu).


## Packets::CLAskCharLogin

Hàm Read: `FUN_140834f60 @ 0x140834f60`

```
  đọc gói + 0x1c cỡ 4
  đọc gói + 0x18 cỡ 4
  đọc gói + 0x20 cỡ 2
  đọc gói + 0x44 cỡ 4
  đọc gói + 0x22 cỡ *(undefined4 *)(param_1 + 0x44)
  đọc gói + 0x7c cỡ 4
  đọc gói + 0x48 cỡ *(undefined4 *)(param_1 + 0x7c)
  đọc gói + 0xa0 cỡ 4
  đọc gói + 0x80 cỡ *(undefined4 *)(param_1 + 0xa0)
  đọc gói + 0xa4 cỡ 4
  đọc gói + 0xa8 cỡ 1
}
```


## Packets::LCRetCharLogin

Hàm Read: `FUN_140836eb0 @ 0x140836eb0`

```
  đọc gói + 0x18 cỡ 1
  đọc gói + 0x1c cỡ 4
  đọc gói + 0x20 cỡ *(undefined4 *)(param_1 + 0x1c)
  if (*(int *)(param_1 + 0x20) == 0xf) {
  }
}
```


## Packets::LCStatus

Hàm Read: `FUN_140836e50 @ 0x140836e50`

```
  đọc gói + 0x18 cỡ 2
  đọc gói + 0x1c cỡ 4
}
```


## Packets::CGConnect

Hàm Read: `FUN_140836880 @ 0x140836880`

```
  đọc gói + 0x18 cỡ 4
  đọc gói + 0x20 cỡ 4
  đọc gói + 0x1c cỡ 4
  đọc gói + 0x24 cỡ 2
  đọc gói + 0x26 cỡ 0x32
  đọc gói + 0x5c cỡ 4
  đọc gói + 0x60 cỡ 4
  đọc gói + 100 cỡ 4
  đọc gói + 0x68 cỡ 4
  đọc gói + 0x6c cỡ 4
  đọc gói + 0x70 cỡ 4
  đọc gói + 0x74 cỡ 4
  đọc gói + 0x78 cỡ 4
  đọc gói + 0x7c cỡ 4
  đọc gói + 0x80 cỡ 0x20
  đọc gói + 0xa0 cỡ 4
  đọc gói + 0xa4 cỡ 4
}
```


## Packets::GCConnect

Hàm Read: `FUN_14083cfb0 @ 0x14083cfb0`

```
  đọc gói + 0x18 cỡ 2
  đọc gói + 0x1a cỡ 2
  đọc gói + 0x1c cỡ 8
  đọc gói + 0x24 cỡ 2
  đọc gói + 0x28 cỡ 4
}
```


## Packets::CGEnterScene

Hàm Read: `FUN_140835420 @ 0x140835420`

```
  đọc gói + 0x1a cỡ 2
  đọc gói + 0x18 cỡ 1
  đọc gói + 0x1c cỡ 8
}
```


## Packets::GCEnterScene

Hàm Read: `FUN_14083d1e0 @ 0x14083d1e0`

```
  đọc gói + 0x18 cỡ 1
  đọc gói + 0x1a cỡ 2
  đọc gói + 0x1c cỡ 2
  đọc gói + 0x20 cỡ 8
  đọc gói + 0x28 cỡ 4
  đọc gói + 0x2c cỡ 1
  đọc gói + 0x2d cỡ 1
  đọc gói + 0x30 cỡ 4
  đọc gói + 0x34 cỡ 4
  đọc gói + 0x38 cỡ 4
  đọc gói + 0x3c cỡ 1
  đọc gói + 0x40 cỡ 4
  đọc gói + 0x44 cỡ 4
  đọc gói + 0x48 cỡ 4
  đọc gói + 0x4c cỡ 4
  đọc gói + 0x50 cỡ 2
  đọc gói + 0x52 cỡ 2
}
```
