// Nạp bảng hàm GL. Con trỏ hàm không ép qua void*: chép byte của con trỏ, đúng cách tải thư viện
// động mà không đụng quy tắc alias.
#include "gpu/gles/gl_api.hpp"

#include <cstring>

namespace game::gpu::gles {
namespace {

template <class Function>
void store(Function& target, ProcAddress proc, void* library, const char* name) {
    void* address = proc(name, library);
    std::memcpy(&target, &address, sizeof(address));
}

template <class Function>
[[nodiscard]] bool required(Function function) noexcept {
    return function != nullptr;
}

} // namespace

bool load_functions(GlFunctions& functions, ProcAddress proc, void* library) {
    store(functions.get_string, proc, library, "glGetString");
    store(functions.get_stringi, proc, library, "glGetStringi");
    store(functions.get_integer, proc, library, "glGetIntegerv");
    store(functions.get_error, proc, library, "glGetError");
    store(functions.enable, proc, library, "glEnable");
    store(functions.disable, proc, library, "glDisable");
    store(functions.viewport, proc, library, "glViewport");
    store(functions.scissor, proc, library, "glScissor");
    store(functions.depth_func, proc, library, "glDepthFunc");
    store(functions.depth_mask, proc, library, "glDepthMask");
    store(functions.color_mask, proc, library, "glColorMask");
    store(functions.cull_face, proc, library, "glCullFace");
    store(functions.front_face, proc, library, "glFrontFace");
    store(functions.polygon_mode, proc, library, "glPolygonMode");
    store(functions.blend_func, proc, library, "glBlendFuncSeparate");
    store(functions.blend_equation, proc, library, "glBlendEquationSeparate");
    store(functions.blend_color, proc, library, "glBlendColor");
    store(functions.clear, proc, library, "glClear");
    store(functions.clear_buffer, proc, library, "glClearBufferfv");
    store(functions.draw_buffers, proc, library, "glDrawBuffers");
    store(functions.draw_buffer, proc, library, "glDrawBuffer");
    store(functions.read_buffer, proc, library, "glReadBuffer");
    store(functions.gen_buffers, proc, library, "glGenBuffers");
    store(functions.delete_buffers, proc, library, "glDeleteBuffers");
    store(functions.bind_buffer, proc, library, "glBindBuffer");
    store(functions.buffer_data, proc, library, "glBufferData");
    store(functions.buffer_sub_data, proc, library, "glBufferSubData");
    store(functions.buffer_storage, proc, library, "glBufferStorage");
    store(functions.map_buffer_range, proc, library, "glMapBufferRange");
    store(functions.unmap_buffer, proc, library, "glUnmapBuffer");
    store(functions.copy_buffer, proc, library, "glCopyBufferSubData");
    store(functions.bind_buffer_range, proc, library, "glBindBufferRange");
    store(functions.gen_textures, proc, library, "glGenTextures");
    store(functions.delete_textures, proc, library, "glDeleteTextures");
    store(functions.bind_texture, proc, library, "glBindTexture");
    store(functions.tex_image, proc, library, "glTexImage2D");
    store(functions.tex_sub_image, proc, library, "glTexSubImage2D");
    store(functions.tex_image_multisample, proc, library, "glTexImage2DMultisample");
    store(functions.tex_storage_multisample, proc, library, "glTexStorage2DMultisample");
    store(functions.tex_parameter, proc, library, "glTexParameteri");
    store(functions.pixel_store, proc, library, "glPixelStorei");
    store(functions.active_texture, proc, library, "glActiveTexture");
    store(functions.gen_samplers, proc, library, "glGenSamplers");
    store(functions.delete_samplers, proc, library, "glDeleteSamplers");
    store(functions.sampler_parameter, proc, library, "glSamplerParameteri");
    store(functions.sampler_parameterf, proc, library, "glSamplerParameterf");
    store(functions.sampler_parameterfv, proc, library, "glSamplerParameterfv");
    store(functions.bind_sampler, proc, library, "glBindSampler");
    store(functions.gen_framebuffers, proc, library, "glGenFramebuffers");
    store(functions.delete_framebuffers, proc, library, "glDeleteFramebuffers");
    store(functions.bind_framebuffer, proc, library, "glBindFramebuffer");
    store(functions.framebuffer_texture, proc, library, "glFramebufferTexture2D");
    store(functions.check_framebuffer, proc, library, "glCheckFramebufferStatus");
    store(functions.blit_framebuffer, proc, library, "glBlitFramebuffer");
    store(functions.gen_vertex_arrays, proc, library, "glGenVertexArrays");
    store(functions.delete_vertex_arrays, proc, library, "glDeleteVertexArrays");
    store(functions.bind_vertex_array, proc, library, "glBindVertexArray");
    store(functions.enable_attrib, proc, library, "glEnableVertexAttribArray");
    store(functions.attrib_pointer, proc, library, "glVertexAttribPointer");
    store(functions.attrib_ipointer, proc, library, "glVertexAttribIPointer");
    store(functions.create_shader, proc, library, "glCreateShader");
    store(functions.shader_source, proc, library, "glShaderSource");
    store(functions.compile_shader, proc, library, "glCompileShader");
    store(functions.get_shader, proc, library, "glGetShaderiv");
    store(functions.shader_log, proc, library, "glGetShaderInfoLog");
    store(functions.delete_shader, proc, library, "glDeleteShader");
    store(functions.create_program, proc, library, "glCreateProgram");
    store(functions.attach_shader, proc, library, "glAttachShader");
    store(functions.link_program, proc, library, "glLinkProgram");
    store(functions.get_program, proc, library, "glGetProgramiv");
    store(functions.program_log, proc, library, "glGetProgramInfoLog");
    store(functions.use_program, proc, library, "glUseProgram");
    store(functions.get_uniform_location, proc, library, "glGetUniformLocation");
    store(functions.uniform4uiv, proc, library, "glUniform4uiv");
    store(functions.delete_program, proc, library, "glDeleteProgram");
    store(functions.program_parameter, proc, library, "glProgramParameteri");
    store(functions.get_program_binary, proc, library, "glGetProgramBinary");
    store(functions.program_binary, proc, library, "glProgramBinary");
    store(functions.draw_arrays, proc, library, "glDrawArrays");
    store(functions.draw_elements, proc, library, "glDrawElements");
    store(functions.draw_arrays_instanced, proc, library, "glDrawArraysInstanced");
    store(functions.draw_elements_instanced, proc, library, "glDrawElementsInstancedBaseVertex");
    store(functions.fence_sync, proc, library, "glFenceSync");
    store(functions.client_wait, proc, library, "glClientWaitSync");
    store(functions.delete_sync, proc, library, "glDeleteSync");
    store(functions.memory_barrier, proc, library, "glMemoryBarrier");
    store(functions.debug_callback, proc, library, "glDebugMessageCallback");
    store(functions.object_label, proc, library, "glObjectLabel");
    store(functions.clip_control, proc, library, "glClipControl");
    store(functions.read_pixels, proc, library, "glReadPixels");
    store(functions.flush, proc, library, "glFlush");
    store(functions.polygon_offset, proc, library, "glPolygonOffset");
    const bool core = required(functions.get_string) && required(functions.get_integer) &&
        required(functions.gen_buffers) && required(functions.map_buffer_range) && required(functions.unmap_buffer) &&
        required(functions.copy_buffer) && required(functions.tex_image) && required(functions.tex_sub_image) &&
        required(functions.framebuffer_texture) && required(functions.read_pixels) && required(functions.use_program) &&
        required(functions.create_shader) && required(functions.create_program) && required(functions.draw_arrays) &&
        required(functions.draw_elements) && required(functions.fence_sync) && required(functions.bind_buffer_range) &&
        required(functions.gen_vertex_arrays) && required(functions.bind_framebuffer) &&
        required(functions.blit_framebuffer) && required(functions.gen_samplers) &&
        required(functions.attrib_pointer) && required(functions.attrib_ipointer) &&
        required(functions.get_uniform_location) && required(functions.uniform4uiv);
    return core;
}

} // namespace game::gpu::gles
