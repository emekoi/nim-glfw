static:
  assert cshort.sizeof == int16.sizeof and cint.sizeof == int32.sizeof,
    "not binary compatible with GLFW. Please report this"

when not defined(glfwStaticLib):
  when defined(windows):
    const GlfwDll = "glfw3.dll"
  elif defined(macosx):
    const GlfwDll = "libglfw.3.dylib"
  else:
    const GlfwDll = "libglfw.so.3"
  {.pragma: glfwImport, dynlib: GlfwDll.}
  {.deadCodeElim: on.}
else:
  {.compile: "glfw/src/vulkan.c".}

  when defined(windows):
    {.passC: "-D_GLFW_WIN32", passL: "-lopengl32 -lgdi32",
      compile: "glfw/src/win32_init.c",   compile: "glfw/src/win32_monitor.c",
      compile: "glfw/src/win32_time.c",   compile: "glfw/src/win32_tls.c",
      compile: "glfw/src/win32_window.c", compile: "glfw/src/win32_joystick.c",
      compile: "glfw/src/wgl_context.c",  compile: "glfw/src/egl_context.c".}
  elif defined(macosx):
    {.passC: "-D_GLFW_COCOA -D_GLFW_USE_CHDIR -D_GLFW_USE_MENUBAR -D_GLFW_USE_RETINA",
      passL: "-framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo",
      compile: "glfw/src/cocoa_init.m",   compile: "glfw/src/cocoa_monitor.m",
      compile: "glfw/src/cocoa_time.c",   compile: "glfw/src/posix_tls.c",
      compile: "glfw/src/cocoa_window.m", compile: "glfw/src/cocoa_joystick.m",
      compile: "glfw/src/nsgl_context.m".}
  else:
    {.passL: "-pthread -lGL -lX11 -lXrandr -lXxf86vm -lXi -lXcursor -lm -lXinerama".}

    when defined(wayland):
      {.passC: "-D_GLFW_WAYLAND",
        compile: "glfw/src/wl_init.c",   compile: "glfw/src/wl_monitor.c",
        compile: "glfw/src/wl_window.c", compile: "glfw/src/egl_context.c".}
    elif defined(mir):
      {.passC: "-D_GLFW_MIR",
        compile: "glfw/src/mir_init.c",   compile: "glfw/src/mir_monitor.c",
        compile: "glfw/src/mir_window.c", compile: "glfw/src/egl_context.c".}
    else:
      {.passC: "-D_GLFW_X11",
        compile: "glfw/src/x11_init.c",   compile: "glfw/src/x11_monitor.c",
        compile: "glfw/src/x11_window.c", compile: "glfw/src/glx_context.c",
        compile: "glfw/src/egl_context.c".}

    {.compile: "glfw/src/xkb_unicode.c", compile: "glfw/src/linux_joystick.c",
      compile: "glfw/src/posix_time.c",  compile: "glfw/src/posix_tls.c".}

  {.compile: "glfw/src/context.c", compile: "glfw/src/init.c",
    compile: "glfw/src/input.c",   compile: "glfw/src/monitor.c",
    compile: "glfw/src/window.c".}

  {.pragma: glfwImport.}

import wrapper
import macros
from strutils import toUpperAscii

# *  The available window API macros are:
# *  * `GLFW_EXPOSE_NATIVE_MIR`
# *
# *  The available context API macros are:
# *  * `GLFW_EXPOSE_NATIVE_EGL`

when defined(GLFW_EXPOSE_NATIVE_WIN32):
  import winlean
  export winlean.Handle

proc renameProcs(n: NimNode) {.compileTime.} =
  template pragmas(n: string) = {.glfwImport, cdecl, importc: n.}
  for s in n:
    case s.kind
    of nnkProcDef:
      let oldName = $s.name
      let newName = "glfw" & (oldName[0]).toUpperAscii & oldName[1..^1]
      s.pragma = getAst(pragmas(newName))
    else:
      renameProcs(s)

macro generateProcs(): typed =
  template getProcs {.dirty.} =
    when defined(GLFW_EXPOSE_NATIVE_WIN32):
      proc getWin32Adapter*(monitor: Monitor): cstring
      proc getWin32Monitor*(monitor: Monitor): cstring
      proc getWin32Window*(window: Window): Handle
    elif defined(GLFW_EXPOSE_NATIVE_COCOA):
      proc getCocoaMonitor*(monitor: Monitor): uint32
      proc getCocoaWindow*(window: Window): pointer
    elif defined(GLFW_EXPOSE_NATIVE_X11):
      proc getX11Display*(): pointer
      proc getX11Adapter*(monitor: Monitor): uint32
      proc getX11Monitor*(monitor: Monitor): uint32
      proc getX11Window*(window: Window): uint32
    elif defined(GLFW_EXPOSE_NATIVE_WAYLAND):
      proc getWaylandDisplay*(): pointer
      proc getWaylandMonitor*(monitor: Monitor): pointer
      proc getWaylandWindow*(window: Window): pointer
    elif defined(GLFW_EXPOSE_NATIVE_MIR):
      proc getMirDisplay*(): pointer
      proc getMirMonitor*(monitor: Monitor): cint
      proc getMirWindow*(window: Window): pointer

    when defined(GLFW_EXPOSE_NATIVE_WGL):
      proc getWGLContext*(window: Window): Handle
    elif defined(GLFW_EXPOSE_NATIVE_NSGL):
      proc getNSGLContext*(window: Window): pointer
    elif defined(GLFW_EXPOSE_NATIVE_GLX):
      proc getGLXContext*(window: Window): pointer
      proc getGLXWindow*(window: Window): pointer
    elif defined(GLFW_EXPOSE_NATIVE_EGL):
      proc getEGLDisplay(): pointer
      proc getEGLContext*(window: Window): pointer
      proc getEGLSurface*(window: Window): pointer

  result = getAst(getProcs())
  renameProcs(result)

generateProcs()
