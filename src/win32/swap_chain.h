/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#ifndef ASTRO_GFX_WGL
#define ASTRO_GFX_WGL

#if ASTRO_GFX_USE_WGL

#include <wgl/wglext.h>

namespace astro
{
namespace graphics
{
  typedef PROC(APIENTRY* PFNWGLGETPROCADDRESSPROC) (LPCSTR lpszProc);
  typedef BOOL(APIENTRY* PFNWGLMAKECURRENTPROC) (HDC hdc, HGLRC hglrc);
  typedef HGLRC(APIENTRY* PFNWGLCREATECONTEXTPROC) (HDC hdc);
  typedef BOOL(APIENTRY* PFNWGLDELETECONTEXTPROC) (HGLRC hglrc);
}
}

#endif
#endif
