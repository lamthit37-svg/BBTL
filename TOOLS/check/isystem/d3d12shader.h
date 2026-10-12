#pragma once
// MinGW 16.2 has an older d3d12shader.h. Do not -isystem the whole SDK um tree:
// its windows.h does not compile with GCC. ole2.h from MinGW must come first.
#include <ole2.h>
#ifndef COM_NO_WINDOWS_H
#define COM_NO_WINDOWS_H
#endif
#include "C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/um/d3d12shader.h"
