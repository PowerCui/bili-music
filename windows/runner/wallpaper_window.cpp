#include "wallpaper_window.h"

#include <cstddef>
#include <optional>
#include <utility>

namespace {
constexpr char kViewChannelName[] = "bilimusic/desktop_wallpaper_view";
constexpr UINT kSpawnWorkerMessage = 0x052C;
constexpr wchar_t kProgmanClass[] = L"Progman";
constexpr wchar_t kWorkerClass[] = L"WorkerW";
constexpr wchar_t kShellViewClass[] = L"SHELLDLL_DefView";

struct MonitorCapture {
  RECT bounds;
  bool primary;
};

BOOL CALLBACK CollectMonitor(HMONITOR monitor, HDC device_context, LPRECT rect,
                             LPARAM data) {
  auto* monitors = reinterpret_cast<std::vector<MonitorCapture>*>(data);
  if (monitors == nullptr) {
    return TRUE;
  }
  MONITORINFO info = {};
  info.cbSize = static_cast<DWORD>(sizeof(info));
  MonitorCapture capture = {};
  if (::GetMonitorInfo(monitor, &info)) {
    capture.bounds = info.rcMonitor;
    capture.primary = (info.dwFlags & MONITORINFOF_PRIMARY) != 0;
  }
  monitors->push_back(capture);
  return TRUE;
}

HWND FindDesktopWorker() {
  HWND progman = ::FindWindow(kProgmanClass, nullptr);
  if (progman != nullptr) {
    ::SendMessageTimeout(progman, kSpawnWorkerMessage, 0, 0, SMTO_NORMAL, 1000,
                         nullptr);
  }

  HWND worker = ::FindWindowEx(nullptr, nullptr, kWorkerClass, nullptr);
  while (worker != nullptr) {
    if (::FindWindowEx(worker, nullptr, kShellViewClass, nullptr) != nullptr) {
      HWND host = ::FindWindowEx(nullptr, worker, kWorkerClass, nullptr);
      if (host != nullptr) {
        return host;
      }
      break;
    }
    worker = ::FindWindowEx(nullptr, worker, kWorkerClass, nullptr);
  }

  if (progman != nullptr) {
    return ::FindWindowEx(progman, nullptr, kWorkerClass, nullptr);
  }
  return nullptr;
}
}  // namespace

WallpaperWindow::WallpaperWindow(const flutter::DartProject& project,
                                 const RECT& bounds, ReadyHandler on_ready,
                                 ControlHandler on_control,
                                 ClosedHandler on_closed)
    : project_(project),
      bounds_(bounds),
      on_ready_(std::move(on_ready)),
      on_control_(std::move(on_control)),
      on_closed_(std::move(on_closed)) {}

WallpaperWindow::~WallpaperWindow() {
  Destroy();
}

std::vector<WallpaperWindow::MonitorEntry>
WallpaperWindow::EnumerateMonitors() {
  std::vector<MonitorCapture> captures;
  ::EnumDisplayMonitors(nullptr, nullptr, CollectMonitor,
                        reinterpret_cast<LPARAM>(&captures));

  std::vector<MonitorEntry> entries;
  entries.reserve(captures.size());
  for (const MonitorCapture& capture : captures) {
    MonitorEntry entry = {capture.bounds, capture.primary};
    entries.push_back(entry);
  }
  return entries;
}

RECT WallpaperWindow::MonitorBounds(int monitor_index) {
  const std::vector<MonitorEntry> monitors = EnumerateMonitors();
  if (monitor_index >= 0 &&
      static_cast<std::size_t>(monitor_index) < monitors.size()) {
    const RECT bounds =
        monitors[static_cast<std::size_t>(monitor_index)].bounds;
    if (bounds.right > bounds.left && bounds.bottom > bounds.top) {
      return bounds;
    }
  }

  const POINT origin = {0, 0};
  const HMONITOR monitor = ::MonitorFromPoint(origin, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO info = {};
  info.cbSize = static_cast<DWORD>(sizeof(info));
  RECT bounds = {0, 0, ::GetSystemMetrics(SM_CXSCREEN),
                 ::GetSystemMetrics(SM_CYSCREEN)};
  if (monitor != nullptr && ::GetMonitorInfo(monitor, &info)) {
    bounds = info.rcMonitor;
  }
  if (bounds.right <= bounds.left || bounds.bottom <= bounds.top) {
    bounds.left = 0;
    bounds.top = 0;
    bounds.right = ::GetSystemMetrics(SM_CXSCREEN);
    bounds.bottom = ::GetSystemMetrics(SM_CYSCREEN);
  }
  return bounds;
}

bool WallpaperWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  created_ = true;
  EmbedInDesktop();
  ApplyBounds();

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  view_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), kViewChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  view_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const std::string& method = call.method_name();
        if (method == "ready") {
          if (on_ready_) {
            on_ready_();
          }
          result->Success();
          return;
        }
        if (method == "control") {
          if (call.arguments() &&
              std::holds_alternative<flutter::EncodableMap>(
                  *call.arguments()) &&
              on_control_) {
            on_control_(std::get<flutter::EncodableMap>(*call.arguments()));
          }
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([this]() {
    Show();
    ApplyBounds();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void WallpaperWindow::OnDestroy() {
  if (view_channel_) {
    view_channel_->SetMethodCallHandler(nullptr);
    view_channel_.reset();
  }
  flutter_controller_.reset();

  if (created_) {
    created_ = false;
    ClosedHandler on_closed = std::move(on_closed_);
    on_closed_ = nullptr;
    if (on_closed) {
      on_closed();
    }
  }

  Win32Window::OnDestroy();
}

LRESULT
WallpaperWindow::MessageHandler(HWND hwnd, UINT const message,
                                WPARAM const wparam,
                                LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  const LRESULT result =
      Win32Window::MessageHandler(hwnd, message, wparam, lparam);
  if (message == WM_DPICHANGED) {
    ApplyBounds();
  }
  return result;
}

void WallpaperWindow::SendState(const std::string& payload,
                                const std::vector<uint8_t>* cover) {
  if (!view_channel_) {
    return;
  }

  flutter::EncodableMap arguments;
  arguments[flutter::EncodableValue("payload")] =
      flutter::EncodableValue(payload);
  if (cover != nullptr) {
    arguments[flutter::EncodableValue("cover")] =
        flutter::EncodableValue(*cover);
  } else {
    arguments[flutter::EncodableValue("cover")] = flutter::EncodableValue();
  }
  view_channel_->InvokeMethod(
      "state", std::make_unique<flutter::EncodableValue>(arguments));
}

void WallpaperWindow::EmbedInDesktop() {
  HWND handle = GetHandle();
  if (handle == nullptr) {
    return;
  }

  HWND host = FindDesktopWorker();
  if (host != nullptr) {
    ::SetParent(handle, host);
  }

  LONG_PTR style = ::GetWindowLongPtr(handle, GWL_STYLE);
  style &= ~static_cast<LONG_PTR>(WS_CAPTION | WS_THICKFRAME | WS_SYSMENU |
                                  WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_POPUP);
  if (host != nullptr && ::GetParent(handle) == host) {
    style |= static_cast<LONG_PTR>(WS_CHILD);
  } else {
    style |= static_cast<LONG_PTR>(WS_POPUP);
  }
  ::SetWindowLongPtr(handle, GWL_STYLE, style);

  LONG_PTR ex_style = ::GetWindowLongPtr(handle, GWL_EXSTYLE);
  ex_style &= ~static_cast<LONG_PTR>(WS_EX_APPWINDOW);
  ex_style |= static_cast<LONG_PTR>(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE);
  ::SetWindowLongPtr(handle, GWL_EXSTYLE, ex_style);
}

void WallpaperWindow::ApplyBounds() {
  HWND handle = GetHandle();
  if (handle == nullptr) {
    return;
  }

  RECT bounds = bounds_;
  HWND parent = ::GetParent(handle);
  if (parent != nullptr) {
    ::MapWindowPoints(HWND_DESKTOP, parent, reinterpret_cast<LPPOINT>(&bounds),
                      2);
  }
  ::SetWindowPos(handle, HWND_TOP, bounds.left, bounds.top,
                 bounds.right - bounds.left, bounds.bottom - bounds.top,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW | SWP_FRAMECHANGED);
}
