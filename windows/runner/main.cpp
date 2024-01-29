#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// ******* ADDED *******
#include "win32_window.h"                     // where flag to hide gui is added
#pragma comment(linker, "/subsystem:console") // tells the linker to use console subsystem

/*
  New main, because the app is now a console app
*/
int main(int argc, char *argv[]) {

  // if any arguments are passed run in commandline mode
  if (argc > 1) {
    H_HIDE_WINDOW = true;
  } else {
    ::ShowWindow(::GetConsoleWindow(), SW_HIDE);
  }
  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Revision Tool", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
