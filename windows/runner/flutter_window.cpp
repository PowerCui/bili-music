#include "flutter_window.h"

#include <cstdio>
#include <cwchar>
#include <optional>
#include <utility>

#include "flutter/generated_plugin_registrant.h"
#include "wallpaper_webview.h"

namespace {
constexpr UINT kPreviousCommand = 1;
constexpr UINT kPlayPauseCommand = 2;
constexpr UINT kNextCommand = 3;
constexpr char kChannelName[] =
    "bilimusic/windows_taskbar_thumbnail_toolbar";
constexpr int kPreviousGlyph = 0;
constexpr int kPlayGlyph = 1;
constexpr int kPauseGlyph = 2;
constexpr int kNextGlyph = 3;
constexpr char kDesktopWallpaperChannel[] = "bilimusic/desktop_wallpaper";
constexpr UINT kWallpaperWindowClosedMessage = WM_APP + 1;
constexpr UINT kWallpaperFailedMessage = WM_APP + 2;
constexpr UINT kWallpaperDestroyMessage = WM_APP + 3;
constexpr UINT_PTR kReattachWallpaperTimerId = 2;
constexpr UINT_PTR kWallpaperPatrolTimerId = 3;
constexpr UINT kReattachWallpaperDelayMs = 3000;
constexpr UINT kWallpaperPatrolIntervalMs = 30000;
int g_wallpaper_push_logs = 0;

bool ReadBool(const flutter::EncodableMap& arguments, const char* key) {
  const auto iterator = arguments.find(flutter::EncodableValue(key));
  return iterator != arguments.end() &&
         std::holds_alternative<bool>(iterator->second) &&
         std::get<bool>(iterator->second);
}

bool ReadInt(const flutter::EncodableMap& arguments, const char* key,
             int* value) {
  const auto iterator = arguments.find(flutter::EncodableValue(key));
  if (iterator == arguments.end()) {
    return false;
  }
  if (std::holds_alternative<int32_t>(iterator->second)) {
    *value = std::get<int32_t>(iterator->second);
    return true;
  }
  if (std::holds_alternative<int64_t>(iterator->second)) {
    *value = static_cast<int>(std::get<int64_t>(iterator->second));
    return true;
  }
  return false;
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }
  WallpaperLog(L"wallpaper: flutter window created");

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  taskbar_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  taskbar_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != "updatePlaybackState" ||
            !call.arguments() ||
            !std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          result->NotImplemented();
          return;
        }
        const flutter::EncodableMap& arguments =
            std::get<flutter::EncodableMap>(*call.arguments());
        taskbar_is_playing_ = ReadBool(arguments, "isPlaying");
        taskbar_has_previous_ = ReadBool(arguments, "hasPrevious");
        taskbar_has_next_ = ReadBool(arguments, "hasNext");
        UpdateTaskbarThumbnailToolbar();
        result->Success();
      });
  wallpaper_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), kDesktopWallpaperChannel,
          &flutter::StandardMethodCodec::GetInstance());
  wallpaper_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        HandleWallpaperMethodCall(call, std::move(result));
      });
  InitializeTaskbarThumbnailToolbar();
  taskbar_created_message_ = RegisterWindowMessage(L"TaskbarCreated");
  if (GetHandle() != nullptr) {
    ::SetTimer(GetHandle(), kWallpaperPatrolTimerId, kWallpaperPatrolIntervalMs,
               nullptr);
  }
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  HideWallpaper();
  wallpaper_channel_.reset();
  ReleaseTaskbarThumbnailToolbar();
  taskbar_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == taskbar_button_created_message_) {
    taskbar_toolbar_added_ = false;
    UpdateTaskbarThumbnailToolbar();
    return 0;
  }

  if (message == kWallpaperWindowClosedMessage) {
    HandleWallpaperWindowClosed(reinterpret_cast<WallpaperWindow*>(wparam));
    return 0;
  }

  if (message == kWallpaperFailedMessage) {
    HandleWallpaperFailed(reinterpret_cast<WallpaperWindow*>(wparam));
    return 0;
  }

  if (message == kWallpaperDestroyMessage) {
    DrainPendingWallpaperDestroys();
    return 0;
  }

  if (taskbar_created_message_ != 0 && message == taskbar_created_message_) {
    if (wallpaper_active_ && hwnd != nullptr) {
      ::SetTimer(hwnd, kReattachWallpaperTimerId, kReattachWallpaperDelayMs,
                 nullptr);
    }
    return 0;
  }

  if (message == WM_TIMER) {
    if (wparam == kReattachWallpaperTimerId) {
      ::KillTimer(hwnd, kReattachWallpaperTimerId);
      if (wallpaper_active_) {
        ShowWallpaper(wallpaper_monitor_index_);
      }
      return 0;
    }
    if (wparam == kWallpaperPatrolTimerId) {
      CheckWallpaperHost();
      return 0;
    }
  }

  if (message == WM_COMMAND && HIWORD(wparam) == THBN_CLICKED &&
      HandleTaskbarThumbnailCommand(LOWORD(wparam))) {
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::InitializeTaskbarThumbnailToolbar() {
  taskbar_button_created_message_ =
      RegisterWindowMessage(L"TaskbarButtonCreated");
  const HRESULT result = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  taskbar_com_initialized_ = SUCCEEDED(result);
  if (FAILED(CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER,
                              IID_PPV_ARGS(&taskbar_list_))) ||
      FAILED(taskbar_list_->HrInit())) {
    taskbar_list_.Reset();
    return;
  }

  previous_icon_ = CreateMediaIcon(kPreviousGlyph);
  play_icon_ = CreateMediaIcon(kPlayGlyph);
  pause_icon_ = CreateMediaIcon(kPauseGlyph);
  next_icon_ = CreateMediaIcon(kNextGlyph);
}

void FlutterWindow::UpdateTaskbarThumbnailToolbar() {
  if (!taskbar_list_) {
    return;
  }

  THUMBBUTTON buttons[3] = {};
  buttons[0].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
  buttons[0].iId = kPreviousCommand;
  buttons[0].hIcon = previous_icon_;
  buttons[0].dwFlags = taskbar_has_previous_ ? THBF_ENABLED : THBF_DISABLED;
  wcscpy_s(buttons[0].szTip, L"Previous");

  buttons[1].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
  buttons[1].iId = kPlayPauseCommand;
  buttons[1].hIcon = taskbar_is_playing_ ? pause_icon_ : play_icon_;
  buttons[1].dwFlags = THBF_ENABLED;
  wcscpy_s(buttons[1].szTip, taskbar_is_playing_ ? L"Pause" : L"Play");

  buttons[2].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
  buttons[2].iId = kNextCommand;
  buttons[2].hIcon = next_icon_;
  buttons[2].dwFlags = taskbar_has_next_ ? THBF_ENABLED : THBF_DISABLED;
  wcscpy_s(buttons[2].szTip, L"Next");

  if (!taskbar_toolbar_added_) {
    if (SUCCEEDED(taskbar_list_->ThumbBarAddButtons(GetHandle(), 3, buttons))) {
      taskbar_toolbar_added_ = true;
    }
    return;
  }
  taskbar_list_->ThumbBarUpdateButtons(GetHandle(), 3, buttons);
}

bool FlutterWindow::HandleTaskbarThumbnailCommand(WORD command) {
  switch (command) {
    case kPreviousCommand:
      SendTaskbarCommand("previous");
      return true;
    case kPlayPauseCommand:
      SendTaskbarCommand(taskbar_is_playing_ ? "pause" : "play");
      return true;
    case kNextCommand:
      SendTaskbarCommand("next");
      return true;
  }
  return false;
}

void FlutterWindow::SendTaskbarCommand(const char* command) {
  if (taskbar_channel_) {
    taskbar_channel_->InvokeMethod(
        "command", std::make_unique<flutter::EncodableValue>(command));
  }
}

HICON FlutterWindow::CreateMediaIcon(int glyph) {
  constexpr int kSize = 32;
  BITMAPV5HEADER header = {};
  header.bV5Size = sizeof(header);
  header.bV5Width = kSize;
  header.bV5Height = -kSize;
  header.bV5Planes = 1;
  header.bV5BitCount = 32;
  header.bV5Compression = BI_BITFIELDS;
  header.bV5RedMask = 0x00FF0000;
  header.bV5GreenMask = 0x0000FF00;
  header.bV5BlueMask = 0x000000FF;
  header.bV5AlphaMask = 0xFF000000;

  HDC screen = GetDC(nullptr);
  void* pixels = nullptr;
  HBITMAP color = CreateDIBSection(screen, reinterpret_cast<BITMAPINFO*>(&header),
                                   DIB_RGB_COLORS, &pixels, nullptr, 0);
  ReleaseDC(nullptr, screen);
  if (color == nullptr) {
    return nullptr;
  }

  HDC dc = CreateCompatibleDC(nullptr);
  HGDIOBJ previous = SelectObject(dc, color);
  RECT bounds = {0, 0, kSize, kSize};
  FillRect(dc, &bounds, static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH)));
  SetBkMode(dc, TRANSPARENT);
  SetDCBrushColor(dc, RGB(255, 255, 255));
  SelectObject(dc, GetStockObject(DC_BRUSH));

  if (glyph == kPauseGlyph) {
    Rectangle(dc, 8, 7, 13, 25);
    Rectangle(dc, 19, 7, 24, 25);
  } else {
    const bool reverse = glyph == kPreviousGlyph;
    const POINT triangle[] = {
        {reverse ? 23 : 9, 6}, {reverse ? 9 : 23, 16}, {reverse ? 23 : 9, 26},
    };
    Polygon(dc, triangle, 3);
    if (glyph == kPreviousGlyph || glyph == kNextGlyph) {
      Rectangle(dc, reverse ? 6 : 23, 6, reverse ? 9 : 26, 26);
    }
  }

  auto* icon_pixels = static_cast<DWORD*>(pixels);
  for (int index = 0; index < kSize * kSize; ++index) {
    if ((icon_pixels[index] & 0x00FFFFFF) != 0) {
      icon_pixels[index] |= 0xFF000000;
    }
  }

  SelectObject(dc, previous);
  DeleteDC(dc);
  HBITMAP mask = CreateBitmap(kSize, kSize, 1, 1, nullptr);
  ICONINFO icon_info = {};
  icon_info.fIcon = TRUE;
  icon_info.hbmColor = color;
  icon_info.hbmMask = mask;
  HICON icon = CreateIconIndirect(&icon_info);
  DeleteObject(color);
  DeleteObject(mask);
  return icon;
}

void FlutterWindow::ReleaseTaskbarThumbnailToolbar() {
  for (HICON icon : {previous_icon_, play_icon_, pause_icon_, next_icon_}) {
    if (icon != nullptr) {
      DestroyIcon(icon);
    }
  }
  previous_icon_ = nullptr;
  play_icon_ = nullptr;
  pause_icon_ = nullptr;
  next_icon_ = nullptr;
  taskbar_list_.Reset();
  if (taskbar_com_initialized_) {
    CoUninitialize();
    taskbar_com_initialized_ = false;
  }
}

void FlutterWindow::HandleWallpaperMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method != "pushState" || g_wallpaper_push_logs < 3) {
    if (method == "pushState") {
      ++g_wallpaper_push_logs;
    }
    WallpaperLog(L"wallpaper channel: " +
                 std::wstring(method.begin(), method.end()));
  }
  if (method == "show") {
    bool shown = false;
    if (call.arguments() &&
        std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
      int monitor_index = 0;
      if (ReadInt(std::get<flutter::EncodableMap>(*call.arguments()),
                  "monitorIndex", &monitor_index)) {
        shown = ShowWallpaper(monitor_index);
      }
    }
    result->Success(flutter::EncodableValue(shown));
    return;
  }

  if (method == "hide") {
    HideWallpaper();
    result->Success(flutter::EncodableValue(true));
    return;
  }

  if (method == "pushState") {
    if (call.arguments() &&
        std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
      PushWallpaperState(std::get<flutter::EncodableMap>(*call.arguments()));
    }
    result->Success();
    return;
  }

  if (method == "listMonitors") {
    flutter::EncodableList monitors;
    const std::vector<WallpaperWindow::MonitorEntry> entries =
        WallpaperWindow::EnumerateMonitors();
    int index = 0;
    for (const WallpaperWindow::MonitorEntry& entry : entries) {
      flutter::EncodableMap monitor;
      monitor[flutter::EncodableValue("index")] =
          flutter::EncodableValue(index);
      monitor[flutter::EncodableValue("width")] = flutter::EncodableValue(
          static_cast<int>(entry.bounds.right - entry.bounds.left));
      monitor[flutter::EncodableValue("height")] = flutter::EncodableValue(
          static_cast<int>(entry.bounds.bottom - entry.bounds.top));
      monitor[flutter::EncodableValue("primary")] =
          flutter::EncodableValue(entry.primary);
      monitors.push_back(flutter::EncodableValue(monitor));
      ++index;
    }
    result->Success(flutter::EncodableValue(monitors));
    return;
  }

  if (method == "reload") {
    if (wallpaper_window_) {
      wallpaper_window_->Reload();
    }
    result->Success();
    return;
  }

  if (method == "openDevTools") {
    if (wallpaper_window_) {
      wallpaper_window_->OpenDevTools();
    }
    result->Success();
    return;
  }

  result->NotImplemented();
}

bool FlutterWindow::ShowWallpaper(int monitor_index) {
  WallpaperLog(L"wallpaper: show requested");
  const RECT bounds = WallpaperWindow::MonitorBounds(monitor_index);

  if (wallpaper_window_ != nullptr &&
      wallpaper_window_->GetHandle() != nullptr &&
      !wallpaper_window_->webview_failed()) {
    wallpaper_window_->Restart(bounds);
    wallpaper_active_ = true;
    wallpaper_monitor_index_ = monitor_index;
    WallpaperLog(L"wallpaper: window restarted");
    SendCachedWallpaperState();
    return true;
  }

  DestroyWallpaperWindow();

  auto window = std::make_unique<WallpaperWindow>(
      bounds, [this]() { OnWallpaperReady(); },
      [this](HRESULT error) { OnWallpaperFailed(error); },
      [this]() { OnWallpaperClosed(); });

  if (!window->Create(
          L"bilimusic wallpaper", Win32Window::Point(0, 0),
          Win32Window::Size(
              static_cast<unsigned int>(bounds.right - bounds.left),
              static_cast<unsigned int>(bounds.bottom - bounds.top)))) {
    WallpaperLog(L"wallpaper: window Create failed");
    wallpaper_window_ = std::move(window);
    DestroyWallpaperWindow();
    wallpaper_active_ = false;
    return false;
  }
  if (window->webview_failed()) {
    WallpaperLog(L"wallpaper: webview failed at startup");
    wallpaper_window_ = std::move(window);
    DestroyWallpaperWindow();
    wallpaper_active_ = false;
    return false;
  }
  window->SetQuitOnClose(false);

  wallpaper_window_ = std::move(window);
  wallpaper_active_ = true;
  wallpaper_monitor_index_ = monitor_index;
  WallpaperLog(L"wallpaper: window created");
  SendCachedWallpaperState();
  return true;
}

void FlutterWindow::HideWallpaper() {
  WallpaperLog(L"wallpaper: hide");
  wallpaper_active_ = false;
  if (wallpaper_window_ != nullptr) {
    wallpaper_window_->Shutdown();
    wallpaper_window_->Hide();
  }
  wallpaper_ready_ = false;
  ResetWallpaperState();
}

void FlutterWindow::DestroyWallpaperWindow() {
  wallpaper_ready_ = false;
  if (!wallpaper_window_) {
    return;
  }
  destroying_wallpaper_ = true;
  wallpaper_window_->Shutdown();
  wallpaper_window_->Hide();
  pending_wallpaper_destroys_.push_back(std::move(wallpaper_window_));
  wallpaper_window_ = nullptr;
  destroying_wallpaper_ = false;
  const HWND handle = GetHandle();
  if (handle != nullptr) {
    ::PostMessage(handle, kWallpaperDestroyMessage, 0, 0);
  }
}

void FlutterWindow::DrainPendingWallpaperDestroys() {
  if (pending_wallpaper_destroys_.empty()) {
    return;
  }
  destroying_wallpaper_ = true;
  for (auto& window : pending_wallpaper_destroys_) {
    if (window != nullptr) {
      window->Destroy();
    }
    window.reset();
  }
  pending_wallpaper_destroys_.clear();
  destroying_wallpaper_ = false;
}

void FlutterWindow::PushWallpaperState(
    const flutter::EncodableMap& arguments) {
  wallpaper_has_state_ = false;
  wallpaper_payload_.clear();

  const auto payload = arguments.find(flutter::EncodableValue("payload"));
  if (payload != arguments.end() &&
      std::holds_alternative<std::string>(payload->second)) {
    wallpaper_payload_ = std::get<std::string>(payload->second);
    wallpaper_has_state_ = true;
  }

  SendCachedWallpaperState();
}

void FlutterWindow::SendCachedWallpaperState() {
  if (!wallpaper_window_ || !wallpaper_ready_ || !wallpaper_has_state_) {
    return;
  }
  wallpaper_window_->SendState(wallpaper_payload_);
}

void FlutterWindow::ResetWallpaperState() {
  wallpaper_has_state_ = false;
  wallpaper_payload_.clear();
  wallpaper_ready_ = false;
}

void FlutterWindow::OnWallpaperReady() {
  WallpaperLog(L"wallpaper: page ready callback");
  wallpaper_ready_ = true;
  if (wallpaper_channel_) {
    wallpaper_channel_->InvokeMethod(
        "ready", std::make_unique<flutter::EncodableValue>());
  }
  SendCachedWallpaperState();
}

void FlutterWindow::OnWallpaperFailed(HRESULT error) {
  std::wstring detail = L"wallpaper: webview failed hr=0x";
  wchar_t code[16] = {};
  swprintf_s(code, 16, L"%08lX", static_cast<unsigned long>(error));
  detail += code;
  WallpaperLog(detail);
  HWND handle = GetHandle();
  if (destroying_wallpaper_ || handle == nullptr || !wallpaper_window_) {
    return;
  }
  ::PostMessage(handle, kWallpaperFailedMessage,
                reinterpret_cast<WPARAM>(wallpaper_window_.get()), 0);
}

void FlutterWindow::OnWallpaperClosed() {
  HWND handle = GetHandle();
  if (destroying_wallpaper_ || handle == nullptr || !wallpaper_window_) {
    return;
  }
  ::PostMessage(handle, kWallpaperWindowClosedMessage,
                reinterpret_cast<WPARAM>(wallpaper_window_.get()), 0);
}

void FlutterWindow::HandleWallpaperWindowClosed(WallpaperWindow* source) {
  if (!wallpaper_window_ || wallpaper_window_.get() != source) {
    return;
  }
  DestroyWallpaperWindow();
  if (wallpaper_channel_) {
    wallpaper_channel_->InvokeMethod(
        "windowClosed", std::make_unique<flutter::EncodableValue>());
  }
}

void FlutterWindow::HandleWallpaperFailed(WallpaperWindow* source) {
  if (!wallpaper_window_ || wallpaper_window_.get() != source) {
    return;
  }
  wallpaper_active_ = false;
  DestroyWallpaperWindow();
  ResetWallpaperState();
  if (wallpaper_channel_) {
    wallpaper_channel_->InvokeMethod(
        "windowClosed", std::make_unique<flutter::EncodableValue>());
  }
}

void FlutterWindow::CheckWallpaperHost() {
  if (!wallpaper_active_) {
    return;
  }
  if (!wallpaper_window_) {
    ShowWallpaper(wallpaper_monitor_index_);
    return;
  }
  const HWND handle = wallpaper_window_->GetHandle();
  if (handle == nullptr) {
    ShowWallpaper(wallpaper_monitor_index_);
    return;
  }
  const HWND parent = ::GetParent(handle);
  if (parent != nullptr && !::IsWindow(parent)) {
    ShowWallpaper(wallpaper_monitor_index_);
  }
}
