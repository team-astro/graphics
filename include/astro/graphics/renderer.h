/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#ifndef ASTRO_GFX_RENDERER_H
#define ASTRO_GFX_RENDERER_H

#include <astro/astro.h>
#include <astro/platform.h>

#define ASTRO_GFX_HANDLE(name) \
  struct name { uint16 index; };\
  inline bool is_valid(name handle) { return astro::graphics::invalid_handle != handle.index; }
#define ASTRO_GFX_INVALID_HANDLE { astro::graphics::invalid_handle; }

namespace astro { namespace graphics
{
  struct window;
  struct swap_chain {};

  enum class renderer_type
  {
    null,
    opengl,

    count
  };

  static const uint16 invalid_handle = UINT16_MAX;

  ASTRO_GFX_HANDLE(frame_buffer_handle);
  ASTRO_GFX_HANDLE(vertex_buffer_handle);
  ASTRO_GFX_HANDLE(index_buffer_handle);
  ASTRO_GFX_HANDLE(texture_handle);
  ASTRO_GFX_HANDLE(shader_handle);
  ASTRO_GFX_HANDLE(program_handle);

  /// Returns the name of a renderer.
  const char* get_renderer_name(renderer_type type);

  swap_chain*
  create_swap_chain(window* window);

  void
  swap_chain_make_current(swap_chain* chain, bool resize);

  void
  swap_chain_flush(swap_chain* chain);

  /// Create a framebuffer from an existing window.
  ///
  frame_buffer_handle create_frame_buffer(window* window);

  /// Destroy frame buffer.
  ///
  void destroy_frame_buffer(frame_buffer_handle handle);
}
}

#endif
