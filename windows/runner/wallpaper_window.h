#ifndef RUNNER_WALLPAPER_WINDOW_H_
#define RUNNER_WALLPAPER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "win32_window.h"

class WallpaperWindow : public Win32Window {
 public:
  struct MonitorEntry {
    RECT bounds;
    bool primary;
  };

  using ReadyHandler = std::function<void()>;
  using ControlHandler = std::function<void(const flutter::EncodableMap&)>;
  using ClosedHandler = std::function<void()>;

  WallpaperWindow(const flutter::DartProject& project, const RECT& bounds,
                  ReadyHandler on_ready, ControlHandler on_control,
                  ClosedHandler on_closed);
  ~WallpaperWindow() override;

  static std::vector<MonitorEntry> EnumerateMonitors();
  static RECT MonitorBounds(int monitor_index);

  void SendState(const std::string& payload, const std::vector<uint8_t>* cover);

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void EmbedInDesktop();
  void ApplyBounds();

  flutter::DartProject project_;
  RECT bounds_;
  ReadyHandler on_ready_;
  ControlHandler on_control_;
  ClosedHandler on_closed_;
  bool created_ = false;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      view_channel_;
};

#endif  // RUNNER_WALLPAPER_WINDOW_H_
