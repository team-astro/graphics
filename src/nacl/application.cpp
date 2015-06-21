/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/application.h>
#include <astro/os.h>

#include <ppapi/cpp/instance.h>
#include <ppapi/cpp/module.h>
#include <ppapi/cpp/var.h>
#include <ppapi/utility/completion_callback_factory.h>

class CoreInstance : public pp::Instance
{
public:
  explicit CoreInstance(PP_Instance instance)
    : pp::Instance(instance)
  {
  }

private:
  virtual void HandleMessage(const pp::Var& var_message)
  {
    int32_t delay = var_message.AsInt();
    if (delay)
    {
      m_last_recieve_time = pp::Module::Get()->core()->GetTimeTicks();
      pp::Module::Get()->core()->CallOnMainThread(
        delay, m_callback_factory.NewCallback(&CoreInstance::DelayedPost));
    }
    else
    {
      pp::Var msg(0);
      PostMessage(msg);
    }
  }

  void DelayedPost(int32_t)
  {
    pp::Var msg(pp::Module::Get()->core()->GetTimeTicks() - m_last_recieve_time);
    PostMessage(msg);
  }

private:
  pp::CompletionCallbackFactory<CoreInstance> m_callback_factory;
  PP_TimeTicks m_last_recieve_time;
};

class CoreModule : public pp::Module
{
public:
  CoreModule() : pp::Module() {}
  virtual ~CoreModule() {}

  virtual pp::Instance* CreateInstance(PP_Instance instance)
  {
    return new CoreInstance(instance);
  }
};

namespace pp
{
  Module* CreateModule() { return new CoreModule(); }
}

namespace astro
{
namespace graphics
{
  struct nacl_application : application
  {
  };

  static void
  null_app_event(application* app) { }

  application* create_application(uintptr heap_size)
  {
    uint8* heap = (uint8*)malloc(heap_size);
    if (!heap)
    {
      exit(EXIT_FAILURE);
    }

    nacl_application* app = (nacl_application*) heap;
    app->on_startup = null_app_event;
    app->on_shutdown = null_app_event;

    heap += sizeof(nacl_application);
    heap_size -= sizeof(nacl_application);

    initialize_memory_stack(&app->stack, heap_size, heap);

    return app;
  }

  void update_application(application* app)
  {
    astro_assert(false);
  }

  void quit_application(application* app)
  {
    app->is_running = false;
  }

  void dispose_application(application* app)
  {
    app->is_running = false;
  }

  void set_clipboard_text(const char* text)
  {
    astro_assert(false);
  }

  const char* get_clipboard_text(memory_stack* stack)
  {
    astro_assert(false);
    return nullptr;
  }
}
}
