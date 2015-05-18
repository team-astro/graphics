/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/window.h>
#include <astro/graphics/context.h>

namespace astro
{
namespace graphics
{
  struct win32_window : public window
  {
    HWND handle;
  };

  static WNDCLASSW window_class = {};

  void
  null_on_render(window*, real32)
  {
  }

  void null_on_key_change(window*, key_state) { }
  void null_on_mouse_change(window*, mouse_state) { }
  void null_on_touch_change(window*, touch_state) { }

  static LRESULT CALLBACK AstroWndProc(HWND handle, UINT msg, WPARAM wParam, LPARAM lParam)
  {
    win32_window* window = (win32_window *)GetWindowLongPtr(handle, GWLP_USERDATA);
    switch (msg)
    {
    case WM_CREATE:
    {
      // Hook up wrapper with HWND in both directions.
      CREATESTRUCT* cs = (CREATESTRUCT*)lParam;
      if (cs != nullptr && cs->lpCreateParams != nullptr)
      {
        window = (win32_window*)cs->lpCreateParams;
        SetWindowLongPtr(handle, GWLP_USERDATA, (LONG_PTR)window);
        ShowWindow(handle, SW_SHOW);
        UpdateWindow(handle);
      }
    }
    return 0;
    case WM_DESTROY:
    {
    }
    return 0;
    case WM_CLOSE:
    {
    }
    return 0;
    case WM_SIZE:
    {
      int w = LOWORD(lParam);
      int h = HIWORD(lParam);

      //pWindow->OnResized(w, h);
    }
    return 0;
    case WM_INPUT:
    {
      /*RawInputEventArgs e;
      e.IsForeground = (wParam == RIM_INPUT);
      e.InputHandle = (HRAWINPUT)lParam;

      uint32 buffer_size;
      if (GetRawInputData(e.InputHandle, RID_INPUT, nullptr, &buffer_size, sizeof(RAWINPUTHEADER)) == 0 && buffer_size > 0)
      {
        PRAWINPUT raw_input = (PRAWINPUT)malloc(buffer_size);
        uint32 bytes_copied = GetRawInputData(e.InputHandle, RID_INPUT, raw_input, &buffer_size, sizeof(RAWINPUTHEADER));
        if (bytes_copied == (uint32)-1)
        {
          DWORD error = GetLastError();
          astro_assert(error);
        }
        else if (bytes_copied > 0)
        {
          e.RawInputData = raw_input;
        }

        pWindow->OnRawInput(e);
        free(raw_input);
      }*/
    }
    break; // WM_INPUT requires a call to DefWindowProc
    }

    return DefWindowProc(handle, msg, wParam, lParam);
  }

  window* create_window(application* app, const char* title, uint16 width, uint16 height)
  {
    WNDCLASSA window_class = { 0 };
    window_class.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    window_class.lpfnWndProc = AstroWndProc;
    window_class.cbClsExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon = LoadIcon(0, IDI_APPLICATION);
    window_class.hCursor = LoadCursor(0, IDC_ARROW);
    window_class.hbrBackground = nullptr;
    window_class.lpszMenuName = 0;
    window_class.lpszClassName = "AstroWindow";

    // Allocate a pointer-sized chunk to be stored on the HWND, for our Window instance.
    window_class.cbWndExtra = sizeof(window*);

    auto class_reg_result = RegisterClassA(&window_class);
    astro_assert(class_reg_result);

    win32_window* window = push_struct<win32_window>(&app->stack);
    *window = {};
    window->title = push_string(&app->stack, title);
    window->width = width;
    window->height = height;
    window->on_render = null_on_render;
    window->on_key_change = null_on_key_change;
    window->on_mouse_change = null_on_mouse_change;
    window->on_touch_change = null_on_touch_change;
    window->app = app;

    push_list(&app->stack, &app->windows);
    app->windows->window = window;

    RECT rClient = { 0 };
    rClient.bottom = height;
    rClient.right = width;

    AdjustWindowRect(&rClient, WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_CLIPCHILDREN | WS_CLIPSIBLINGS, FALSE);
    window->handle = CreateWindowA(window_class.lpszClassName, title, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, CW_USEDEFAULT, rClient.right - rClient.left, rClient.bottom - rClient.top, nullptr, nullptr, GetModuleHandle(nullptr), window);

    create_context(window);

    return window;
  }

  void draw_window(window* window, real32 delta_time, bool32 resize)
  {

  }
}
}
