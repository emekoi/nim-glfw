when defined(windows):
  switch("define", "GLFW_EXPOSE_NATIVE_WIN32 ")
  switch("define", "GLFW_EXPOSE_NATIVE_WGL")
elif defined(macosx):
  switch("define", "GLFW_EXPOSE_NATIVE_COCOA")
  switch("define", "GLFW_EXPOSE_NATIVE_NSGL")
elif defined(wayland):
  switch("define", "GLFW_EXPOSE_NATIVE_WAYLAND")
elif defined(mir):
  switch("define", "GLFW_EXPOSE_NATIVE_MIR")
else:
  switch("define", "GLFW_EXPOSE_NATIVE_X11")
  switch("define", "GLFW_EXPOSE_NATIVE_GLX")