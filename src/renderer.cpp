/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/renderer.h>
#include "renderer_imp.h"

namespace astro { namespace graphics
{
  // typedef render_driver* (*driver_create_func)();
  // typedef void (*driver_destroy_func)();

#define ASTRO_GFX_RENDER_DRIVER(ns) \
  namespace ns \
  { \
    extern render_driver* create_render_driver(); \
    extern void destroy_render_driver(); \
  }

  // ASTRO_GFX_RENDER_DRIVER(noop);
  // ASTRO_GFX_RENDER_DRIVER(gl);

#undef ASTRO_GFX_RENDER_DRIVER

  // struct render_driver_info
  // {
  //   driver_create_func create_func;
  //   driver_destroy_func destroy_func;
  //   const char* name;
  //   bool32 supported;
  // };

  // static const render_driver_info s_render_driver_infos[] =
  // {
  //   { noop::create_render_driver, noop::destroy_render_driver, ASTRO_GFX_RENDERER_NULL_NAME, !!ASTRO_GFX_CONFIG_RENDERER_NULL },
  //   { gl::create_render_driver, gl::destroy_render_driver, ASTRO_GFX_RENDERER_OPENGL_NAME, !!ASTRO_GFX_CONFIG_RENDERER_OPENGLES },
  //   { gl::create_render_driver, gl::destroy_render_driver, ASTRO_GFX_RENDERER_OPENGL_NAME, !!ASTRO_GFX_CONFIG_RENDERER_OPENGL },
  // };

  const char* get_renderer_name(renderer_type type)
  {
    // ASTRO_CHECK(type < renderer_type::count, "Invalid renderer type %d", type);
    // return s_render_driver_infos[type].name;
    return ASTRO_GFX_RENDERER_OPENGL_NAME;
  }

  // void renderer_init(renderer_type type)
  // {
  //   ASTRO_CHECK(nullptr == s_ctx, "Renderer already initialized.");
  //   log_debug("renderer_init");
  //
  //   // s_ctx = ASTRO_ALIGNED_ALLOC(default_allocator, command_builder, 16);
  // }
  //
  // void renderer_shutdown()
  // {
  //
  // }

  // uint32 renderer_end_frame()
  // {
  //
  // }

  frame_buffer_handle create_frame_buffer(window* window)
  {
    return { invalid_handle };
  }

  void destroy_frame_buffer(frame_buffer_handle handle)
  {

  }
}
}
