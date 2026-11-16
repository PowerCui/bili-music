#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <cstdint>
#include <memory>
#include <shobjidl.h>
#include <shellapi.h>
#include <string>
#include <vector>
#include <wrl/client.h>

#include "wallpaper_window.h"
#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void InitializeTaskbarThumbnailToolbar();
  void UpdateTaskbarThumbnailToolbar();
  bool HandleTaskbarThumbnailCommand(WORD command);
  void SendTaskbarCommand(const char* command);
  HICON CreateMediaIcon(int glyph);
  void ReleaseTaskbarThumbnailToolbar();

  void HandleWallpaperMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  bool ShowWallpaper(int monitor_index);
  void HideWallpaper();
  void DestroyWallpaperWindow();
  void PushWallpaperState(const flutter::EncodableMap& arguments);
  void SendCachedWallpaperState();
  void ResetWallpaperState();
  void OnWallpaperReady();
  void OnWallpaperControl(const flutter::EncodableMap& arguments);
  void OnWallpaperClosed();
  void HandleWallpaperWindowClosed();

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      taskbar_channel_;
  Microsoft::WRL::ComPtr<ITaskbarList3> taskbar_list_;
  UINT taskbar_button_created_message_ = 0;
  HICON previous_icon_ = nullptr;
  HICON play_icon_ = nullptr;
  HICON pause_icon_ = nullptr;
  HICON next_icon_ = nullptr;
  bool taskbar_toolbar_added_ = false;
  bool taskbar_is_playing_ = false;
  bool taskbar_has_previous_ = false;
  bool taskbar_has_next_ = false;
  bool taskbar_com_initialized_ = false;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      wallpaper_channel_;
  std::unique_ptr<WallpaperWindow> wallpaper_window_;
  std::string wallpaper_payload_;
  std::vector<uint8_t> wallpaper_cover_;
  bool wallpaper_has_state_ = false;
  bool wallpaper_cover_present_ = false;
  bool wallpaper_ready_ = false;
  bool destroying_wallpaper_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
