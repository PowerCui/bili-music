#ifndef RUNNER_WALLPAPER_WEBVIEW_H_
#define RUNNER_WALLPAPER_WEBVIEW_H_

#include <windows.h>

#pragma warning(push, 0)
#include <WebView2.h>
#pragma warning(pop)

#include <functional>
#include <memory>
#include <string>

#include <wrl/client.h>

class WallpaperWebview : public std::enable_shared_from_this<WallpaperWebview> {
 public:
  using ReadyHandler = std::function<void()>;
  using FailedHandler = std::function<void(HRESULT)>;

  WallpaperWebview(HWND host_window, ReadyHandler on_ready, FailedHandler on_failed);
  ~WallpaperWebview();

  WallpaperWebview(const WallpaperWebview&) = delete;
  WallpaperWebview& operator=(const WallpaperWebview&) = delete;

  void StartAsync();
  void Destroy();

  void SetBounds(RECT bounds);
  void PostState(const std::string& payload_json);
  void Reload();
  void OpenDevTools();

  bool page_ready() const { return page_ready_; }

 private:
  static void DrainEnvironmentWaiters(HRESULT error);
  void CreateController();
  void OnControllerCreated(ICoreWebView2Controller* controller);
  void ConfigureWebview();
  void NavigateToWallpaper();
  void HandlePageMessage(ICoreWebView2WebMessageReceivedEventArgs* args);
  void OnProcessFailed(COREWEBVIEW2_PROCESS_FAILED_KIND kind);
  void Fail(HRESULT error);

  HWND host_ = nullptr;
  ReadyHandler on_ready_;
  FailedHandler on_failed_;
  Microsoft::WRL::ComPtr<ICoreWebView2Controller> controller_;
  Microsoft::WRL::ComPtr<ICoreWebView2> webview_;
  EventRegistrationToken message_token_ = {};
  EventRegistrationToken process_failed_token_ = {};
  EventRegistrationToken navigation_token_ = {};
  bool page_ready_ = false;
  bool started_ = false;
  bool failed_ = false;
};

#endif  // RUNNER_WALLPAPER_WEBVIEW_H_
