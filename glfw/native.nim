import wrapper
import macros
from strutils import toUpperAscii

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
      proc getWin32Adapter(monitor: Monitor): cstring
      proc getWin32Monitor(monitor: Monitor): cstring
      proc getWin32Window(window: Window): Handle
    elif defined(GLFW_EXPOSE_NATIVE_COCOA):
      proc getCocoaMonitor(monitor: Monitor): uint32
      proc getCocoaWindow(window: Window): pointer
    elif defined(GLFW_EXPOSE_NATIVE_X11):
      proc getX11Display(): pointer
      proc getX11Adapter(monitor: Monitor): uint32
      proc getX11Monitor(monitor: Monitor): uint32
      proc getX11Window(window: Window): uint32
    elif defined(GLFW_EXPOSE_NATIVE_WAYLAND):
      proc getWaylandDisplay(): pointer
      proc getWaylandMonitor(monitor: Monitor): pointer
      proc getWaylandWindow(window: Window): pointer
    elif defined(GLFW_EXPOSE_NATIVE_MIR):
      proc getMirDisplay(): pointer
      proc getMirMonitor(monitor: Monitor): cint
      proc getMirWindow(window: Window): pointer

    when defined(GLFW_EXPOSE_NATIVE_WGL):
      proc getWGLContext(window: Window): Handle
    elif defined(GLFW_EXPOSE_NATIVE_NSGL):
      proc getNSGLContext(window: Window): pointer
    elif defined(GLFW_EXPOSE_NATIVE_GLX):
      proc getGLXContext(window: Window): pointer
      proc getGLXWindow(window: Window): pointer
    elif defined(GLFW_EXPOSE_NATIVE_EGL):
      proc getEGLDisplay(): pointer
      proc getEGLContext(window: Window): pointer
      proc getEGLSurface(window: Window): pointer

  result = getAst(getProcs())
  renameProcs(result)

generateProcs()
