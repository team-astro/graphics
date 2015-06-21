/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/astro.h>
#include "win32_window.h"
#include "renderer_gl.h"

#define GL_GLEXT_PROTOTYPES
#include <gl/glcorearb.h>


namespace astro
{
namespace graphics
{

  static void* gl_module = nullptr;
  static ATOM dummy_window_atom = -1;
  PFNWGLGETPROCADDRESSPROC wglGetProcAddress;
  PFNWGLMAKECURRENTPROC wglMakeCurrent;
  PFNWGLCREATECONTEXTPROC wglCreateContext;
  PFNWGLDELETECONTEXTPROC wglDeleteContext;
  PFNWGLGETEXTENSIONSSTRINGARBPROC wglGetExtensionsStringARB;
  PFNWGLCHOOSEPIXELFORMATARBPROC wglChoosePixelFormatARB;
  PFNWGLCREATECONTEXTATTRIBSARBPROC wglCreateContextAttribsARB;
  PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT;

  typedef const char *(WINAPI * PFNWGLGETEXTENSIONSSTRINGARBPROC) (HDC hdc);
  typedef const char *(WINAPI * PFNWGLGETEXTENSIONSSTRINGEXTPROC) (void);
  typedef BOOL(WINAPI * PFNWGLCHOOSEPIXELFORMATARBPROC) (HDC hdc, const int *piAttribIList, const FLOAT *pfAttribFList, UINT nMaxFormats, int *piFormats, UINT *nNumFormats);
  typedef HGLRC(WINAPI * PFNWGLCREATECONTEXTATTRIBSARBPROC) (HDC hDC, HGLRC hShareContext, const int *attribList);

#	define GL_IMPORT(_optional, _proto, _func, _import) _proto _func
#	include "glimport.h"

  struct win32_context : public context
  {
    void* gl_handle;
    HDC hdc;
    HGLRC hglrc;
    int format;
    PIXELFORMATDESCRIPTOR pfd;
  };

  template <class T> T
  gl_func(const char* name)
  {
    T p = (T) wglGetProcAddress(name);
    if (p == nullptr || p == (void*)0x1 || p == (void*)0x2 || p == (void*)0x3 || p == (void*)-1)
    {
      astro_assert(gl_module);
      p = (T) dlsym(gl_module, name);
    }

    return p;
  }

  void
  gl_context_on_render(window*, real32)
  {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
  }

  void
  gl_context_import()
  {
    log_debug("Import:");
#	define GL_EXTENSION(_optional, _proto, _func, _import) \
    { \
      if (NULL == _func) \
      { \
        _func = (_proto)wglGetProcAddress(#_import); \
        if (_func == NULL) \
        { \
	        _func = (_proto)dlsym(gl_module, #_import); \
	        log_debug("    %p " #_func " (" #_import ")", _func); \
        } \
        else \
        { \
	        log_debug("wgl %p " #_func " (" #_import ")", _func); \
        } \
        if (!ASTRO_IGNORE_C4127(_optional) && NULL == _func) \
          log_error("Failed to create OpenGL context. wglGetProcAddress(\"%s\")", #_import); \
      } \
    }
#	include "glimport.h"
  }

  static HGLRC
  create_context(HDC hdc)
  {
    PIXELFORMATDESCRIPTOR pfd = {};
    pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
    pfd.nVersion = 1;
    pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
    pfd.iPixelType = PFD_TYPE_RGBA;
    pfd.cColorBits = 32;
    pfd.cAlphaBits = 8;
    pfd.cDepthBits = 24;
    pfd.cStencilBits = 8;
    pfd.iLayerType = PFD_MAIN_PLANE;

    int pixelFormat = ChoosePixelFormat(hdc, &pfd);
    astro_assert(pixelFormat);

    DescribePixelFormat(hdc, pixelFormat, sizeof(PIXELFORMATDESCRIPTOR), &pfd);
    log_debug("Pixel format:\n"
      "\tiPixelType %d\n"
      "\tcColorBits %d\n"
      "\tcAlphaBits %d\n"
      "\tcDepthBits %d\n"
      "\tcStencilBits %d\n",
      pfd.iPixelType,
      pfd.cColorBits,
      pfd.cAlphaBits,
      pfd.cDepthBits,
      pfd.cStencilBits);

    int result = SetPixelFormat(hdc, pixelFormat, &pfd);
    astro_assert(result != 0);

    HGLRC context = wglCreateContext(hdc);
    astro_assert(context);

    result = wglMakeCurrent(hdc, context);
    astro_assert(result != 0);

    return context;
  }

  context*
  create_context(window* window)
  {
    win32_window* win = (win32_window*)window;
    window->on_render = gl_context_on_render;

    if (gl_module == nullptr)
    {
      gl_module = astro::dlopen("opengl32.dll");
      wglGetProcAddress = (PFNWGLGETPROCADDRESSPROC) astro::dlsym(gl_module, "wglGetProcAddress");
      wglMakeCurrent = (PFNWGLMAKECURRENTPROC)astro::dlsym(gl_module, "wglMakeCurrent");
      wglCreateContext = (PFNWGLCREATECONTEXTPROC)astro::dlsym(gl_module, "wglCreateContext");
      wglDeleteContext = (PFNWGLDELETECONTEXTPROC)astro::dlsym(gl_module, "wglDeleteContext");
    }

    HWND handle = CreateWindowA("STATIC", "", WS_POPUP|WS_DISABLED,
      -32000, -32000, 0, 0, nullptr, nullptr, GetModuleHandle(nullptr), nullptr);
    HDC hdc = GetDC(handle);

    auto* stack = &window->app->stack;
    win32_context* ctx = push_struct<win32_context>(stack);
    ctx->gl_handle = dlopen("opengl32.dll");
    ctx->hdc = GetDC(win->handle);

    HGLRC context = create_context(hdc);

    wglGetExtensionsStringARB = (PFNWGLGETEXTENSIONSSTRINGARBPROC)wglGetProcAddress("wglGetExtensionsStringARB");
    wglChoosePixelFormatARB = (PFNWGLCHOOSEPIXELFORMATARBPROC)wglGetProcAddress("wglChoosePixelFormatARB");
    wglCreateContextAttribsARB = (PFNWGLCREATECONTEXTATTRIBSARBPROC)wglGetProcAddress("wglCreateContextAttribsARB");
    wglSwapIntervalEXT = (PFNWGLSWAPINTERVALEXTPROC)wglGetProcAddress("wglSwapIntervalEXT");

    if (wglGetExtensionsStringARB != nullptr)
    {
      const char* extensions = (const char*)wglGetExtensionsStringARB(hdc);
      log_debug("WGL extensions:\n%s", extensions);
    }

    if (wglChoosePixelFormatARB && wglCreateContextAttribsARB)
    {
      // TODO(mtr): See https://www.opengl.org/wiki/Creating_an_OpenGL_Context_%28WGL%29
      // for more info about options to use here...
      const int32 attrs[] =
      {
        WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
        WGL_SUPPORT_OPENGL_ARB, GL_TRUE,
        WGL_DOUBLE_BUFFER_ARB, GL_TRUE,
        WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
        WGL_COLOR_BITS_ARB, 32,
        WGL_DEPTH_BITS_ARB, 24,
        WGL_STENCIL_BITS_ARB, 8,
        0,        //End
      };

      uint32 num_formats = 0;
      int result = wglChoosePixelFormatARB(ctx->hdc, attrs, nullptr, 1, &ctx->format, &num_formats);
      astro_assert(result);

      result = DescribePixelFormat(ctx->hdc, ctx->format, sizeof(PIXELFORMATDESCRIPTOR), &ctx->pfd);
      astro_assert(result != 0);
      log_debug("Pixel format:\n"
        "\tiPixelType %d\n"
        "\tcColorBits %d\n"
        "\tcAlphaBits %d\n"
        "\tcDepthBits %d\n"
        "\tcStencilBits %d\n",
        ctx->pfd.iPixelType,
        ctx->pfd.cColorBits,
        ctx->pfd.cAlphaBits,
        ctx->pfd.cDepthBits,
        ctx->pfd.cStencilBits);

      result = SetPixelFormat(ctx->hdc, ctx->format, &ctx->pfd);
      astro_assert(result != 0);

      int32 flags = WGL_CONTEXT_DEBUG_BIT_ARB;
      int32 context_attrs[] =
      {
        WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
        WGL_CONTEXT_MINOR_VERSION_ARB, 2,
        WGL_CONTEXT_FLAGS_ARB, flags,
        WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
        0
      };

      ctx->hglrc = wglCreateContextAttribsARB(ctx->hdc, 0, context_attrs);
      astro_assert(context);
    }

    wglMakeCurrent(nullptr, nullptr);
    wglMakeCurrent(ctx->hdc, ctx->hglrc);
    DestroyWindow(handle);

    if (ctx->hglrc == nullptr)
    {
      ctx->hglrc = create_context(ctx->hdc);
    }

    int result = wglMakeCurrent(ctx->hdc, ctx->hglrc);
    astro_assert(result != 0);

    if (wglSwapIntervalEXT)
    {
      wglSwapIntervalEXT(0);
    }

    return ctx;
  }

}
}
