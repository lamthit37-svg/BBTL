// Hằng và con trỏ hàm OpenGL mà backend GLES gọi. Không include gl.h: hai header hệ thống khai
// cùng một tên theo hai kiểu, và bản Windows chỉ có GL 1.1. Nạp bằng wglGetProcAddress hoặc
// eglGetProcAddress sau khi context đã current.
#pragma once

#include <cstdint>

namespace game::gpu::gles {

#if defined(_WIN32)
#define GL_APIENTRY __stdcall
#else
#define GL_APIENTRY
#endif

using DebugProc = void(GL_APIENTRY*)(std::uint32_t source, std::uint32_t type, std::uint32_t id, std::uint32_t severity,
    std::int32_t length, const char* message, const void* user);
// Tên kiểu và tên hằng giữ nguyên của đặc tả Khronos để tra tài liệu và đối chiếu với gl.h
// (lệch DD-02).
// NOLINTNEXTLINE(bugprone-reserved-identifier,cert-dcl37-c,cert-dcl51-cpp)
using Sync = struct __GLsync*;

// NOLINTBEGIN(readability-identifier-naming)
inline constexpr std::uint32_t GL_FALSE = 0;
inline constexpr std::uint32_t GL_TRUE = 1;
inline constexpr std::uint32_t GL_TRIANGLES = 0x0004;
inline constexpr std::uint32_t GL_DEPTH_BUFFER_BIT = 0x00000100;
inline constexpr std::uint32_t GL_COLOR_BUFFER_BIT = 0x00004000;
inline constexpr std::uint32_t GL_SRC_ALPHA = 0x0302;
inline constexpr std::uint32_t GL_ONE_MINUS_SRC_ALPHA = 0x0303;
inline constexpr std::uint32_t GL_NONE = 0;
inline constexpr std::uint32_t GL_FRONT = 0x0404;
inline constexpr std::uint32_t GL_BACK = 0x0405;
inline constexpr std::uint32_t GL_CW = 0x0900;
inline constexpr std::uint32_t GL_CCW = 0x0901;
inline constexpr std::uint32_t GL_CULL_FACE = 0x0B44;
inline constexpr std::uint32_t GL_DEPTH_TEST = 0x0B71;
inline constexpr std::uint32_t GL_BLEND = 0x0BE2;
inline constexpr std::uint32_t GL_TEXTURE_2D = 0x0DE1;
inline constexpr std::uint32_t GL_UNSIGNED_BYTE = 0x1401;
inline constexpr std::uint32_t GL_UNSIGNED_SHORT = 0x1403;
inline constexpr std::uint32_t GL_UNSIGNED_INT = 0x1405;
inline constexpr std::uint32_t GL_FLOAT = 0x1406;
inline constexpr std::uint32_t GL_RGBA = 0x1908;
inline constexpr std::uint32_t GL_VENDOR = 0x1F00;
inline constexpr std::uint32_t GL_RENDERER = 0x1F01;
inline constexpr std::uint32_t GL_VERSION = 0x1F02;
inline constexpr std::uint32_t GL_EXTENSIONS = 0x1F03;
inline constexpr std::uint32_t GL_NEAREST = 0x2600;
inline constexpr std::uint32_t GL_LINEAR = 0x2601;
inline constexpr std::uint32_t GL_TEXTURE_MAG_FILTER = 0x2800;
inline constexpr std::uint32_t GL_TEXTURE_MIN_FILTER = 0x2801;
inline constexpr std::uint32_t GL_TEXTURE_WRAP_S = 0x2802;
inline constexpr std::uint32_t GL_TEXTURE_WRAP_T = 0x2803;
inline constexpr std::uint32_t GL_REPEAT = 0x2901;

inline constexpr std::uint32_t GL_DEPTH_COMPONENT = 0x1902;
inline constexpr std::uint32_t GL_CLAMP_TO_EDGE = 0x812F;
inline constexpr std::uint32_t GL_CLAMP_TO_BORDER = 0x812D;
inline constexpr std::uint32_t GL_MIRRORED_REPEAT = 0x8370;
inline constexpr std::uint32_t GL_TEXTURE0 = 0x84C0;
inline constexpr std::uint32_t GL_ARRAY_BUFFER = 0x8892;
inline constexpr std::uint32_t GL_ELEMENT_ARRAY_BUFFER = 0x8893;
inline constexpr std::uint32_t GL_STATIC_DRAW = 0x88E4;
inline constexpr std::uint32_t GL_DYNAMIC_DRAW = 0x88E8;
inline constexpr std::uint32_t GL_STREAM_READ = 0x88E1;
inline constexpr std::uint32_t GL_FRAGMENT_SHADER = 0x8B30;
inline constexpr std::uint32_t GL_VERTEX_SHADER = 0x8B31;
inline constexpr std::uint32_t GL_COMPILE_STATUS = 0x8B81;
inline constexpr std::uint32_t GL_LINK_STATUS = 0x8B82;
inline constexpr std::uint32_t GL_INFO_LOG_LENGTH = 0x8B84;
inline constexpr std::uint32_t GL_ACTIVE_UNIFORM_MAX_LENGTH = 0x8B87;
inline constexpr std::uint32_t GL_TEXTURE_2D_MULTISAMPLE = 0x9100;
inline constexpr std::uint32_t GL_FRAMEBUFFER = 0x8D40;
inline constexpr std::uint32_t GL_READ_FRAMEBUFFER = 0x8CA8;
inline constexpr std::uint32_t GL_DRAW_FRAMEBUFFER = 0x8CA9;
inline constexpr std::uint32_t GL_COLOR_ATTACHMENT0 = 0x8CE0;
inline constexpr std::uint32_t GL_DEPTH_ATTACHMENT = 0x8D00;
inline constexpr std::uint32_t GL_DEPTH_STENCIL_ATTACHMENT = 0x821A;
inline constexpr std::uint32_t GL_FRAMEBUFFER_COMPLETE = 0x8CD5;
inline constexpr std::uint32_t GL_UNIFORM_BUFFER = 0x8A11;
inline constexpr std::uint32_t GL_SHADER_STORAGE_BUFFER = 0x90D2;
inline constexpr std::uint32_t GL_MAP_READ_BIT = 0x0001;
inline constexpr std::uint32_t GL_MAP_WRITE_BIT = 0x0002;
inline constexpr std::uint32_t GL_MAP_PERSISTENT_BIT = 0x0040;
inline constexpr std::uint32_t GL_MAP_COHERENT_BIT = 0x0080;
inline constexpr std::uint32_t GL_SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
inline constexpr std::uint32_t GL_ALREADY_SIGNALED = 0x911A;
inline constexpr std::uint32_t GL_TIMEOUT_EXPIRED = 0x911B;
inline constexpr std::uint32_t GL_CONDITION_SATISFIED = 0x911C;
inline constexpr std::uint32_t GL_WAIT_FAILED = 0x911D;
inline constexpr std::uint64_t GL_TIMEOUT_IGNORED = 0xFFFFFFFFFFFFFFFFULL;
inline constexpr std::uint32_t GL_MAJOR_VERSION = 0x821B;
inline constexpr std::uint32_t GL_MINOR_VERSION = 0x821C;
inline constexpr std::uint32_t GL_NUM_EXTENSIONS = 0x821D;
inline constexpr std::uint32_t GL_MAX_TEXTURE_SIZE = 0x0D33;
inline constexpr std::uint32_t GL_MAX_SAMPLES = 0x8D57;
inline constexpr std::uint32_t GL_MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;
inline constexpr std::uint32_t GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS = 0x90ED;
inline constexpr std::uint32_t GL_MAX_TEXTURE_MAX_ANISOTROPY = 0x84FF;
inline constexpr std::uint32_t GL_TEXTURE_MAX_ANISOTROPY = 0x84FE;
inline constexpr std::uint32_t GL_SRGB8_ALPHA8 = 0x8C43;
inline constexpr std::uint32_t GL_RGBA8 = 0x8058;
inline constexpr std::uint32_t GL_DEPTH_COMPONENT32F = 0x8CAC;
inline constexpr std::uint32_t GL_DEPTH24_STENCIL8 = 0x88F0;
inline constexpr std::uint32_t GL_FRAMEBUFFER_SRGB = 0x8DB9;
inline constexpr std::uint32_t GL_LOWER_LEFT = 0x8CA1;
inline constexpr std::uint32_t GL_ZERO_TO_ONE = 0x935F;
inline constexpr std::uint32_t GL_NEGATIVE_ONE_TO_ONE = 0x935E;
inline constexpr std::uint32_t GL_DEBUG_OUTPUT = 0x92E0;
inline constexpr std::uint32_t GL_DEBUG_OUTPUT_SYNCHRONOUS = 0x8242;
inline constexpr std::uint32_t GL_DEBUG_SEVERITY_HIGH = 0x9146;
inline constexpr std::uint32_t GL_DEBUG_TYPE_ERROR = 0x824C;
inline constexpr std::uint32_t GL_FUNC_ADD = 0x8006;
inline constexpr std::uint32_t GL_GEQUAL = 0x0206;
inline constexpr std::uint32_t GL_ALWAYS = 0x0207;
inline constexpr std::uint32_t GL_NEVER = 0x0200;
inline constexpr std::uint32_t GL_LESS = 0x0201;
inline constexpr std::uint32_t GL_EQUAL = 0x0202;
inline constexpr std::uint32_t GL_LEQUAL = 0x0203;
inline constexpr std::uint32_t GL_GREATER = 0x0204;
inline constexpr std::uint32_t GL_NOTEQUAL = 0x0205;
inline constexpr std::uint32_t GL_ONE = 1;
inline constexpr std::uint32_t GL_ZERO = 0;
inline constexpr std::uint32_t GL_SRC_COLOR = 0x0300;
inline constexpr std::uint32_t GL_ONE_MINUS_SRC_COLOR = 0x0301;
inline constexpr std::uint32_t GL_DST_COLOR = 0x0306;
inline constexpr std::uint32_t GL_ONE_MINUS_DST_COLOR = 0x0307;
inline constexpr std::uint32_t GL_DST_ALPHA = 0x0304;
inline constexpr std::uint32_t GL_ONE_MINUS_DST_ALPHA = 0x0305;
inline constexpr std::uint32_t GL_SRC_ALPHA_SATURATE = 0x0308;
inline constexpr std::uint32_t GL_CONSTANT_COLOR = 0x8001;
inline constexpr std::uint32_t GL_ONE_MINUS_CONSTANT_COLOR = 0x8002;
inline constexpr std::uint32_t GL_FUNC_SUBTRACT = 0x800A;
inline constexpr std::uint32_t GL_FUNC_REVERSE_SUBTRACT = 0x800B;
inline constexpr std::uint32_t GL_MIN = 0x8007;
inline constexpr std::uint32_t GL_MAX = 0x8008;
inline constexpr std::uint32_t GL_COPY_READ_BUFFER = 0x8F36;
inline constexpr std::uint32_t GL_COPY_WRITE_BUFFER = 0x8F37;
inline constexpr std::uint32_t GL_PIXEL_UNPACK_BUFFER = 0x88EC;
inline constexpr std::uint32_t GL_PIXEL_PACK_BUFFER = 0x88EB;
inline constexpr std::uint32_t GL_UNPACK_ALIGNMENT = 0x0CF5;
inline constexpr std::uint32_t GL_PACK_ALIGNMENT = 0x0D05;
inline constexpr std::uint32_t GL_UNPACK_ROW_LENGTH = 0x0CF2;
inline constexpr std::uint32_t GL_PACK_ROW_LENGTH = 0x0D02;
inline constexpr std::uint32_t GL_PROGRAM_BINARY_LENGTH = 0x8741;
inline constexpr std::uint32_t GL_NUM_PROGRAM_BINARY_FORMATS = 0x87FE;
inline constexpr std::uint32_t GL_PROGRAM_BINARY_RETRIEVABLE_HINT = 0x8257;
inline constexpr std::uint32_t GL_COMPUTE_SHADER = 0x91B9;
inline constexpr std::uint32_t GL_ALL_BARRIER_BITS = 0xFFFFFFFF;
inline constexpr std::uint32_t GL_TIMESTAMP = 0x8E28;
inline constexpr std::uint32_t GL_SAMPLES_PASSED = 0x8914;
inline constexpr std::uint32_t GL_QUERY_RESULT = 0x8866;
inline constexpr std::uint32_t GL_QUERY_RESULT_AVAILABLE = 0x8867;
inline constexpr std::uint32_t GL_GPU_MEMORY_INFO_TOTAL_AVAILABLE_MEMORY = 0x9048;
inline constexpr std::uint32_t GL_GPU_MEMORY_INFO_CURRENT_AVAILABLE_VIDMEM = 0x9049;
inline constexpr std::uint32_t GL_SCISSOR_TEST = 0x0C11;
inline constexpr std::uint32_t GL_SAMPLE_ALPHA_TO_COVERAGE = 0x809E;
inline constexpr std::uint32_t GL_POLYGON_OFFSET_FILL = 0x8037;
inline constexpr std::uint32_t GL_LINE = 0x1B01;
inline constexpr std::uint32_t GL_FILL = 0x1B02;
inline constexpr std::uint32_t GL_POINTS = 0x0000;
inline constexpr std::uint32_t GL_LINES = 0x0001;
inline constexpr std::uint32_t GL_LINE_STRIP = 0x0003;
inline constexpr std::uint32_t GL_TRIANGLE_STRIP = 0x0005;
inline constexpr std::uint32_t GL_PATCHES = 0x000E;
inline constexpr std::uint32_t GL_TEXTURE_BORDER_COLOR = 0x1004;
inline constexpr std::uint32_t GL_TEXTURE_MIN_LOD = 0x813A;
inline constexpr std::uint32_t GL_TEXTURE_MAX_LOD = 0x813B;
inline constexpr std::uint32_t GL_TEXTURE_COMPARE_MODE = 0x884C;
inline constexpr std::uint32_t GL_TEXTURE_COMPARE_FUNC = 0x884D;
inline constexpr std::uint32_t GL_COMPARE_REF_TO_TEXTURE = 0x884E;
inline constexpr std::uint32_t GL_LINEAR_MIPMAP_LINEAR = 0x2703;
inline constexpr std::uint32_t GL_LINEAR_MIPMAP_NEAREST = 0x2701;
inline constexpr std::uint32_t GL_NEAREST_MIPMAP_LINEAR = 0x2702;
inline constexpr std::uint32_t GL_NEAREST_MIPMAP_NEAREST = 0x2700;
inline constexpr std::uint32_t GL_COLOR = 0x1800;
inline constexpr std::uint32_t GL_DEPTH = 0x1801;
inline constexpr std::uint32_t GL_TEXTURE_BASE_LEVEL = 0x813C;
inline constexpr std::uint32_t GL_TEXTURE_MAX_LEVEL = 0x813D;
inline constexpr std::uint32_t GL_COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;
inline constexpr std::uint32_t GL_COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;
inline constexpr std::uint32_t GL_COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;
inline constexpr std::uint32_t GL_COMPRESSED_RGB8_ETC2 = 0x9274;
inline constexpr std::uint32_t GL_COMPRESSED_RGBA8_ETC2_EAC = 0x9278;
inline constexpr std::uint32_t GL_COMPRESSED_RGBA_ASTC_4x4_KHR = 0x93B0;
// NOLINTEND(readability-identifier-naming)

struct GlFunctions {
    using GetString = const std::uint8_t*(GL_APIENTRY*)(std::uint32_t);
    using GetStringi = const std::uint8_t*(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using GetIntegerv = void(GL_APIENTRY*)(std::uint32_t, int*);
    using GetError = std::uint32_t(GL_APIENTRY*)();
    using Enable = void(GL_APIENTRY*)(std::uint32_t);
    using Disable = void(GL_APIENTRY*)(std::uint32_t);
    using Viewport = void(GL_APIENTRY*)(int, int, int, int);
    using Scissor = void(GL_APIENTRY*)(int, int, int, int);
    using DepthFunc = void(GL_APIENTRY*)(std::uint32_t);
    using DepthMask = void(GL_APIENTRY*)(std::uint8_t);
    using ColorMask = void(GL_APIENTRY*)(std::uint8_t, std::uint8_t, std::uint8_t, std::uint8_t);
    using CullFace = void(GL_APIENTRY*)(std::uint32_t);
    using FrontFace = void(GL_APIENTRY*)(std::uint32_t);
    using PolygonMode = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using BlendFuncSeparate = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, std::uint32_t, std::uint32_t);
    using BlendEquationSeparate = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using BlendColor = void(GL_APIENTRY*)(float, float, float, float);
    using Clear = void(GL_APIENTRY*)(std::uint32_t);
    using ClearBufferfv = void(GL_APIENTRY*)(std::uint32_t, int, const float*);
    using DrawBuffers = void(GL_APIENTRY*)(int, const std::uint32_t*);
    using DrawBuffer = void(GL_APIENTRY*)(std::uint32_t);
    using ReadBuffer = void(GL_APIENTRY*)(std::uint32_t);
    using GenBuffers = void(GL_APIENTRY*)(int, std::uint32_t*);
    using DeleteBuffers = void(GL_APIENTRY*)(int, const std::uint32_t*);
    using BindBuffer = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using BufferData = void(GL_APIENTRY*)(std::uint32_t, std::intptr_t, const void*, std::uint32_t);
    using BufferSubData = void(GL_APIENTRY*)(std::uint32_t, std::intptr_t, std::intptr_t, const void*);
    using BufferStorage = void(GL_APIENTRY*)(std::uint32_t, std::intptr_t, const void*, std::uint32_t);
    using MapBufferRange = void*(GL_APIENTRY*)(std::uint32_t, std::intptr_t, std::intptr_t, std::uint32_t);
    using UnmapBuffer = std::uint8_t(GL_APIENTRY*)(std::uint32_t);
    using CopyBufferSubData = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, std::intptr_t, std::intptr_t,
        std::intptr_t);
    using BindBufferRange = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, std::uint32_t, std::intptr_t,
        std::intptr_t);
    using GenTextures = void(GL_APIENTRY*)(int, std::uint32_t*);
    using DeleteTextures = void(GL_APIENTRY*)(int, const std::uint32_t*);
    using BindTexture = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using TexImage2D = void(GL_APIENTRY*)(std::uint32_t, int, int, int, int, int, std::uint32_t, std::uint32_t,
        const void*);
    using TexSubImage2D = void(GL_APIENTRY*)(std::uint32_t, int, int, int, int, int, std::uint32_t, std::uint32_t,
        const void*);
    using TexImage2DMultisample = void(GL_APIENTRY*)(std::uint32_t, int, std::uint32_t, int, int, std::uint8_t);
    using TexStorage2D = void(GL_APIENTRY*)(std::uint32_t, int, std::uint32_t, int, int);
    using CompressedTexSubImage2D = void(GL_APIENTRY*)(std::uint32_t, int, int, int, int, int, std::uint32_t, int,
        const void*);
    using TexParameteri = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, int);
    using PixelStorei = void(GL_APIENTRY*)(std::uint32_t, int);
    using ActiveTexture = void(GL_APIENTRY*)(std::uint32_t);
    using GenSamplers = void(GL_APIENTRY*)(int, std::uint32_t*);
    using DeleteSamplers = void(GL_APIENTRY*)(int, const std::uint32_t*);
    using SamplerParameteri = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, int);
    using SamplerParameterf = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, float);
    using SamplerParameterfv = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, const float*);
    using BindSampler = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using GenFramebuffers = void(GL_APIENTRY*)(int, std::uint32_t*);
    using DeleteFramebuffers = void(GL_APIENTRY*)(int, const std::uint32_t*);
    using BindFramebuffer = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using FramebufferTexture2D = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, std::uint32_t, std::uint32_t, int);
    using CheckFramebufferStatus = std::uint32_t(GL_APIENTRY*)(std::uint32_t);
    using BlitFramebuffer = void(GL_APIENTRY*)(int, int, int, int, int, int, int, int, std::uint32_t, std::uint32_t);
    using GenVertexArrays = void(GL_APIENTRY*)(int, std::uint32_t*);
    using DeleteVertexArrays = void(GL_APIENTRY*)(int, const std::uint32_t*);
    using BindVertexArray = void(GL_APIENTRY*)(std::uint32_t);
    using EnableVertexAttribArray = void(GL_APIENTRY*)(std::uint32_t);
    using VertexAttribPointer = void(GL_APIENTRY*)(std::uint32_t, int, std::uint32_t, std::uint8_t, int, const void*);
    using VertexAttribIPointer = void(GL_APIENTRY*)(std::uint32_t, int, std::uint32_t, int, const void*);
    using CreateShader = std::uint32_t(GL_APIENTRY*)(std::uint32_t);
    using ShaderSource = void(GL_APIENTRY*)(std::uint32_t, int, const char* const*, const int*);
    using CompileShader = void(GL_APIENTRY*)(std::uint32_t);
    using GetShaderiv = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, int*);
    using GetShaderInfoLog = void(GL_APIENTRY*)(std::uint32_t, int, int*, char*);
    using DeleteShader = void(GL_APIENTRY*)(std::uint32_t);
    using CreateProgram = std::uint32_t(GL_APIENTRY*)();
    using AttachShader = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using LinkProgram = void(GL_APIENTRY*)(std::uint32_t);
    using GetProgramiv = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, int*);
    using GetProgramInfoLog = void(GL_APIENTRY*)(std::uint32_t, int, int*, char*);
    using UseProgram = void(GL_APIENTRY*)(std::uint32_t);
    using GetUniformLocation = int(GL_APIENTRY*)(std::uint32_t, const char*);
    using Uniform4uiv = void(GL_APIENTRY*)(int, int, const std::uint32_t*);
    using DeleteProgram = void(GL_APIENTRY*)(std::uint32_t);
    using ProgramParameteri = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, int);
    using GetProgramBinary = void(GL_APIENTRY*)(std::uint32_t, int, int*, std::uint32_t*, void*);
    using ProgramBinary = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, const void*, int);
    using DrawArrays = void(GL_APIENTRY*)(std::uint32_t, int, int);
    using DrawElements = void(GL_APIENTRY*)(std::uint32_t, int, std::uint32_t, const void*);
    using DrawArraysInstanced = void(GL_APIENTRY*)(std::uint32_t, int, int, int);
    using DrawElementsInstancedBaseVertex = void(GL_APIENTRY*)(std::uint32_t, int, std::uint32_t, const void*, int,
        int);
    using FenceSync = Sync(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using ClientWaitSync = std::uint32_t(GL_APIENTRY*)(Sync, std::uint32_t, std::uint64_t);
    using DeleteSync = void(GL_APIENTRY*)(Sync);
    using BarrierFn = void(GL_APIENTRY*)(std::uint32_t);
    using DebugMessageCallback = void(GL_APIENTRY*)(DebugProc, const void*);
    using ObjectLabel = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t, int, const char*);
    using ClipControl = void(GL_APIENTRY*)(std::uint32_t, std::uint32_t);
    using ReadPixels = void(GL_APIENTRY*)(int, int, int, int, std::uint32_t, std::uint32_t, void*);
    using Flush = void(GL_APIENTRY*)();
    using PolygonOffset = void(GL_APIENTRY*)(float, float);
    using EnableVertexAttrib = EnableVertexAttribArray;

    GetString get_string = nullptr;
    GetStringi get_stringi = nullptr;
    GetIntegerv get_integer = nullptr;
    GetError get_error = nullptr;
    Enable enable = nullptr;
    Disable disable = nullptr;
    Viewport viewport = nullptr;
    Scissor scissor = nullptr;
    DepthFunc depth_func = nullptr;
    DepthMask depth_mask = nullptr;
    ColorMask color_mask = nullptr;
    CullFace cull_face = nullptr;
    FrontFace front_face = nullptr;
    PolygonMode polygon_mode = nullptr;
    BlendFuncSeparate blend_func = nullptr;
    BlendEquationSeparate blend_equation = nullptr;
    BlendColor blend_color = nullptr;
    Clear clear = nullptr;
    ClearBufferfv clear_buffer = nullptr;
    DrawBuffers draw_buffers = nullptr;
    DrawBuffer draw_buffer = nullptr;
    ReadBuffer read_buffer = nullptr;
    GenBuffers gen_buffers = nullptr;
    DeleteBuffers delete_buffers = nullptr;
    BindBuffer bind_buffer = nullptr;
    BufferData buffer_data = nullptr;
    BufferSubData buffer_sub_data = nullptr;
    BufferStorage buffer_storage = nullptr;
    MapBufferRange map_buffer_range = nullptr;
    UnmapBuffer unmap_buffer = nullptr;
    CopyBufferSubData copy_buffer = nullptr;
    BindBufferRange bind_buffer_range = nullptr;
    GenTextures gen_textures = nullptr;
    DeleteTextures delete_textures = nullptr;
    BindTexture bind_texture = nullptr;
    TexImage2D tex_image = nullptr;
    TexSubImage2D tex_sub_image = nullptr;
    TexImage2DMultisample tex_image_multisample = nullptr;
    // GLES 3.1 có glTexStorage2DMultisample, không có glTexImage2DMultisample của desktop.
    TexImage2DMultisample tex_storage_multisample = nullptr;
    // Lõi của GL 4.2 và ES 3.0. Chỉ texture khối nén dùng hai hàm này; thiếu thì không có khối nén nào.
    TexStorage2D tex_storage = nullptr;
    CompressedTexSubImage2D compressed_tex_sub_image = nullptr;
    TexParameteri tex_parameter = nullptr;
    PixelStorei pixel_store = nullptr;
    ActiveTexture active_texture = nullptr;
    GenSamplers gen_samplers = nullptr;
    DeleteSamplers delete_samplers = nullptr;
    SamplerParameteri sampler_parameter = nullptr;
    SamplerParameterf sampler_parameterf = nullptr;
    SamplerParameterfv sampler_parameterfv = nullptr;
    BindSampler bind_sampler = nullptr;
    GenFramebuffers gen_framebuffers = nullptr;
    DeleteFramebuffers delete_framebuffers = nullptr;
    BindFramebuffer bind_framebuffer = nullptr;
    FramebufferTexture2D framebuffer_texture = nullptr;
    CheckFramebufferStatus check_framebuffer = nullptr;
    BlitFramebuffer blit_framebuffer = nullptr;
    GenVertexArrays gen_vertex_arrays = nullptr;
    DeleteVertexArrays delete_vertex_arrays = nullptr;
    BindVertexArray bind_vertex_array = nullptr;
    EnableVertexAttribArray enable_attrib = nullptr;
    VertexAttribPointer attrib_pointer = nullptr;
    VertexAttribIPointer attrib_ipointer = nullptr;
    CreateShader create_shader = nullptr;
    ShaderSource shader_source = nullptr;
    CompileShader compile_shader = nullptr;
    GetShaderiv get_shader = nullptr;
    GetShaderInfoLog shader_log = nullptr;
    DeleteShader delete_shader = nullptr;
    CreateProgram create_program = nullptr;
    AttachShader attach_shader = nullptr;
    LinkProgram link_program = nullptr;
    GetProgramiv get_program = nullptr;
    GetProgramInfoLog program_log = nullptr;
    UseProgram use_program = nullptr;
    GetUniformLocation get_uniform_location = nullptr;
    Uniform4uiv uniform4uiv = nullptr;
    DeleteProgram delete_program = nullptr;
    ProgramParameteri program_parameter = nullptr;
    GetProgramBinary get_program_binary = nullptr;
    ProgramBinary program_binary = nullptr;
    DrawArrays draw_arrays = nullptr;
    DrawElements draw_elements = nullptr;
    DrawArraysInstanced draw_arrays_instanced = nullptr;
    DrawElementsInstancedBaseVertex draw_elements_instanced = nullptr;
    FenceSync fence_sync = nullptr;
    ClientWaitSync client_wait = nullptr;
    DeleteSync delete_sync = nullptr;
    BarrierFn memory_barrier = nullptr;
    DebugMessageCallback debug_callback = nullptr;
    ObjectLabel object_label = nullptr;
    ClipControl clip_control = nullptr;
    ReadPixels read_pixels = nullptr;
    Flush flush = nullptr;
    PolygonOffset polygon_offset = nullptr;
};

// name rồi thư viện (HMODULE hoặc EGL). Không dùng thread_local: hai context trên một luồng
// không được lấy nhầm module của nhau.
using ProcAddress = void* (*)(const char* name, void* library);

// false khi thiếu hàm mà upload, shot hoặc shader gọi. buffer_storage, clip_control,
// polygon_mode, tex_storage và compressed_tex_sub_image được phép null.
[[nodiscard]] bool load_functions(GlFunctions& functions, ProcAddress proc, void* library);

} // namespace game::gpu::gles
