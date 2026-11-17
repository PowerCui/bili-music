#ifndef RUNNER_WALLPAPER_WINDOW_H_
#define RUNNER_WALLPAPER_WINDOW_H_

#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "wallpaper_webview.h"
#include "win32_window.h"

class WallpaperWindow : public Win32Window {
 public:
  struct MonitorEntry {
    RECT bounds;
    bool primary;
  };

  using ReadyHandler = std::function<void()>;
  using FailedHandler = std::function<void(HRESULT)>;
  using ClosedHandler = std::function<void()>;

  WallpaperWindow(const RECT& bounds, ReadyHandler on_ready,
                  FailedHandler on_failed, ClosedHandler on_closed);
  ~WallpaperWindow() override;

  WallpaperWindow(const WallpaperWindow&) = delete;
  WallpaperWindow& operator=(const WallpaperWindow&) = delete;

  static std::vector<MonitorEntry> EnumerateMonitors();
  static RECT MonitorBounds(int monitor_index);

  void SendState(const std::string& payload);
  void Reload();
  void OpenDevTools();
  bool webview_failed() const { return webview_failed_; }

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void EmbedInDesktop();
  void ApplyBounds();

  RECT bounds_;
  ReadyHandler on_ready_;
  FailedHandler on_failed_;
  ClosedHandler on_closed_;
  bool created_ = false;
  bool webview_failed_ = false;
  std::shared_ptr<WallpaperWebview> webview_;
};

#endif  // RUNNER_WALLPAPER_WINDOW_H_
