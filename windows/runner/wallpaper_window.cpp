#include "wallpaper_window.h"

#include "wallpaper_webview.h"

#include <cstddef>
#include <utility>

namespace {
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

WallpaperWindow::WallpaperWindow(const RECT& bounds, ReadyHandler on_ready,
                                 FailedHandler on_failed,
                                 ClosedHandler on_closed)
    : bounds_(bounds),
      on_ready_(std::move(on_ready)),
      on_failed_(std::move(on_failed)),
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
  WallpaperLog(L"wallpaper window: created");

  created_ = true;
  EmbedInDesktop();
  ApplyBounds();

  WallpaperLog(L"wallpaper window: embedded, starting webview");

  StartWebview();

  return true;
}

void WallpaperWindow::StartWebview() {
  if (webview_) {
    return;
  }
  webview_ = std::make_shared<WallpaperWebview>(
      GetHandle(), on_ready_, [this](HRESULT error) {
        webview_failed_ = true;
        if (on_failed_) {
          on_failed_(error);
        }
      });
  webview_->StartAsync();
}

void WallpaperWindow::Shutdown() {
  if (webview_) {
    webview_->Destroy();
  }
  webview_.reset();
}

void WallpaperWindow::Restart(const RECT& bounds) {
  HWND handle = GetHandle();
  if (handle == nullptr) {
    return;
  }
  bounds_ = bounds;
  webview_failed_ = false;
  EmbedInDesktop();
  ApplyBounds();
  ::ShowWindow(handle, SW_SHOWNOACTIVATE);
  StartWebview();
}

void WallpaperWindow::Hide() {
  HWND handle = GetHandle();
  if (handle != nullptr) {
    ::ShowWindow(handle, SW_HIDE);
  }
}

void WallpaperWindow::Destroy() {
  Shutdown();
  Win32Window::Destroy();
}

void WallpaperWindow::OnDestroy() {
  webview_.reset();

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
  const LRESULT result =
      Win32Window::MessageHandler(hwnd, message, wparam, lparam);
  if (message == WM_DPICHANGED || message == WM_SIZE) {
    ApplyBounds();
  }
  return result;
}

void WallpaperWindow::SendState(const std::string& payload) {
  if (webview_) {
    webview_->PostState(payload);
  }
}

void WallpaperWindow::Reload() {
  if (webview_) {
    webview_->Reload();
  }
}

void WallpaperWindow::OpenDevTools() {
  if (webview_) {
    webview_->OpenDevTools();
  }
}

void WallpaperWindow::EmbedInDesktop() {
  HWND handle = GetHandle();
  if (handle == nullptr) {
    return;
  }

  HWND host = FindDesktopWorker();
  if (host != nullptr) {
    ::SetParent(handle, host);
    WallpaperLog(L"wallpaper window: attached to WorkerW");
  } else {
    WallpaperLog(L"wallpaper window: WorkerW not found, popup fallback");
  }

  LONG_PTR style = ::GetWindowLongPtr(handle, GWL_STYLE);
  style &= ~static_cast<LONG_PTR>(WS_CAPTION | WS_THICKFRAME | WS_SYSMENU |
                                  WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_POPUP);
  if (host != nullptr && ::GetParent(handle) == host) {
    style |= static_cast<LONG_PTR>(WS_CHILD | WS_CLIPCHILDREN |
                                   WS_CLIPSIBLINGS);
  } else {
    style |= static_cast<LONG_PTR>(
        WS_POPUP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS);
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

  if (webview_) {
    webview_->SetBounds(GetClientArea());
  }
}
