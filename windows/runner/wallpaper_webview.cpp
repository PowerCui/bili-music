#include "wallpaper_webview.h"

#include <shlobj.h>

#include <atomic>
#include <cstdio>
#include <cwchar>
#include <cwctype>
#include <utility>
#include <vector>

#include <wrl/event.h>

namespace {

Microsoft::WRL::ComPtr<ICoreWebView2Environment> g_environment;
bool g_environment_create_in_flight = false;
std::vector<std::weak_ptr<WallpaperWebview>> g_pending_environment_waiters;

bool g_shim_loaded = false;
std::wstring g_shim_script;

constexpr wchar_t kVirtualHost[] = L"wallpaper.assets";
constexpr wchar_t kWallpaperUrl[] =
    L"https://wallpaper.assets/index.html?offline=1";
constexpr wchar_t kBrowserArguments[] =
    L"--disable-backgrounding-occluded-windows "
    L"--disable-renderer-backgrounding "
    L"--disable-features=CalculateNativeWinOcclusion";
constexpr wchar_t kLanguage[] = L"zh-CN";

void AppendLogFile(const std::wstring& message) {
  wchar_t base[MAX_PATH] = {};
  const DWORD length =
      GetEnvironmentVariableW(L"LOCALAPPDATA", base, MAX_PATH);
  if (length == 0 || length >= MAX_PATH) {
    return;
  }
  const std::wstring directory = std::wstring(base) + L"\\bilimusic";
  CreateDirectoryW(directory.c_str(), nullptr);
  const std::wstring path = directory + L"\\wallpaper.log";
  HANDLE file = CreateFileW(path.c_str(), FILE_APPEND_DATA,
                            FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                            OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return;
  }
  SYSTEMTIME time = {};
  GetLocalTime(&time);
  wchar_t stamp[40] = {};
  swprintf_s(stamp, 40, L"[%02u:%02u:%02u.%03u] ", time.wHour, time.wMinute,
             time.wSecond, time.wMilliseconds);
  const std::wstring line = std::wstring(stamp) + message + L"\r\n";
  const int size = WideCharToMultiByte(CP_UTF8, 0, line.c_str(), -1, nullptr,
                                       0, nullptr, nullptr);
  if (size > 0) {
    std::vector<char> buffer(size);
    WideCharToMultiByte(CP_UTF8, 0, line.c_str(), -1, buffer.data(), size,
                        nullptr, nullptr);
    DWORD written = 0;
    WriteFile(file, buffer.data(), static_cast<DWORD>(size - 1), &written,
              nullptr);
  }
  CloseHandle(file);
}

void Log(const std::wstring& message) {
  OutputDebugStringW(message.c_str());
  OutputDebugStringW(L"\n");
  AppendLogFile(message);
}

std::wstring Utf8ToWide(const std::string& input) {
  if (input.empty()) {
    return std::wstring();
  }
  const int length = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, input.data(),
      static_cast<int>(input.size()), nullptr, 0);
  if (length <= 0) {
    return std::wstring();
  }
  std::wstring output(static_cast<size_t>(length), L'\0');
  MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, input.data(),
      static_cast<int>(input.size()), output.data(), length);
  return output;
}

std::wstring Trim(const std::wstring& input) {
  size_t begin = 0;
  size_t end = input.size();
  while (begin < end && iswspace(input[begin])) {
    begin++;
  }
  while (end > begin && iswspace(input[end - 1])) {
    end--;
  }
  return input.substr(begin, end - begin);
}

std::wstring ExeDirectory() {
  wchar_t buffer[MAX_PATH] = {};
  const DWORD length = GetModuleFileNameW(nullptr, buffer, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return std::wstring();
  }
  std::wstring path(buffer, length);
  const size_t separator = path.find_last_of(L"\\/");
  if (separator == std::wstring::npos) {
    return std::wstring();
  }
  return path.substr(0, separator);
}

std::wstring JoinPath(const std::wstring& base, const wchar_t* relative) {
  if (base.empty()) {
    return std::wstring(relative);
  }
  wchar_t last = base.back();
  if (last == L'\\' || last == L'/') {
    return base + relative;
  }
  return base + L"\\" + relative;
}

std::wstring WallpaperFolder() {
  return JoinPath(
      JoinPath(
          JoinPath(JoinPath(ExeDirectory(), L"data"), L"flutter_assets"),
          L"assets"),
      L"wallpaper");
}

std::wstring ShimPath() {
  return JoinPath(
      JoinPath(
          JoinPath(JoinPath(ExeDirectory(), L"data"), L"flutter_assets"),
          L"assets"),
      L"wallpaper_host\\shim.js");
}

std::wstring UserDataFolder() {
  PWSTR local_app_data = nullptr;
  if (FAILED(SHGetKnownFolderPath(
          FOLDERID_LocalAppData, KF_FLAG_DEFAULT, nullptr,
          &local_app_data)) ||
      local_app_data == nullptr) {
    return std::wstring();
  }
  std::wstring folder = JoinPath(local_app_data, L"bilimusic\\webview2");
  CoTaskMemFree(local_app_data);
  return folder;
}

void LoadShimScript() {
  if (g_shim_loaded) {
    return;
  }
  g_shim_loaded = true;
  const std::wstring path = ShimPath();
  if (path.empty()) {
    Log(L"wallpaper webview: cannot resolve shim.js path");
    return;
  }
  HANDLE file = CreateFileW(
      path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    Log(L"wallpaper webview: shim.js not found: " + path);
    return;
  }
  std::string bytes;
  char buffer[8192];
  DWORD read = 0;
  while (ReadFile(file, buffer, sizeof(buffer), &read, nullptr) && read > 0) {
    bytes.append(buffer, static_cast<size_t>(read));
  }
  CloseHandle(file);
  const char utf8_bom[3] = {static_cast<char>(0xEF),
                            static_cast<char>(0xBB), static_cast<char>(0xBF)};
  if (bytes.size() >= 3 && bytes[0] == utf8_bom[0] && bytes[1] == utf8_bom[1] &&
      bytes[2] == utf8_bom[2]) {
    bytes.erase(0, 3);
  }
  std::wstring script = Utf8ToWide(bytes);
  if (!script.empty() && script.front() == L'\uFEFF') {
    script.erase(0, 1);
  }
  if (script.empty()) {
    Log(L"wallpaper webview: shim.js is empty: " + path);
    return;
  }
  g_shim_script = std::move(script);
  Log(L"wallpaper webview: shim.js loaded");
}

HRESULT CopyToCoTaskMem(const std::wstring& source, LPWSTR* value) {
  if (value == nullptr) {
    return E_POINTER;
  }
  const size_t char_count = source.size() + 1;
  LPWSTR copy =
      static_cast<LPWSTR>(CoTaskMemAlloc(char_count * sizeof(wchar_t)));
  if (copy == nullptr) {
    return E_OUTOFMEMORY;
  }
  if (wcscpy_s(copy, char_count, source.c_str()) != 0) {
    CoTaskMemFree(copy);
    return E_FAIL;
  }
  *value = copy;
  return S_OK;
}

class WallpaperEnvOptions : public ICoreWebView2EnvironmentOptions {
 public:
  WallpaperEnvOptions() = default;
  ~WallpaperEnvOptions() = default;

  WallpaperEnvOptions(const WallpaperEnvOptions&) = delete;
  WallpaperEnvOptions& operator=(const WallpaperEnvOptions&) = delete;

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv_object) {
    if (ppv_object == nullptr) {
      return E_POINTER;
    }
    if (riid == IID_IUnknown || riid == IID_ICoreWebView2EnvironmentOptions) {
      *ppv_object = static_cast<ICoreWebView2EnvironmentOptions*>(this);
      AddRef();
      return S_OK;
    }
    *ppv_object = nullptr;
    return E_NOINTERFACE;
  }

  ULONG STDMETHODCALLTYPE AddRef() {
    return ++ref_count_;
  }

  ULONG STDMETHODCALLTYPE Release() {
    const ULONG count = --ref_count_;
    if (count == 0) {
      delete this;
    }
    return count;
  }

  HRESULT STDMETHODCALLTYPE get_AdditionalBrowserArguments(LPWSTR* value) {
    return CopyToCoTaskMem(browser_arguments_, value);
  }

  HRESULT STDMETHODCALLTYPE put_AdditionalBrowserArguments(LPCWSTR value) {
    browser_arguments_ = value != nullptr ? value : L"";
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE get_Language(LPWSTR* value) {
    return CopyToCoTaskMem(language_, value);
  }

  HRESULT STDMETHODCALLTYPE put_Language(LPCWSTR value) {
    language_ = value != nullptr ? value : L"";
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE get_TargetCompatibleBrowserVersion(LPWSTR* value) {
    return CopyToCoTaskMem(compatible_version_, value);
  }

  HRESULT STDMETHODCALLTYPE put_TargetCompatibleBrowserVersion(LPCWSTR value) {
    compatible_version_ = value != nullptr ? value : L"";
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE get_AllowSingleSignOnUsingOSPrimaryAccount(
      BOOL* value) {
    if (value == nullptr) {
      return E_POINTER;
    }
    *value = allow_single_sign_on_;
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE put_AllowSingleSignOnUsingOSPrimaryAccount(
      BOOL value) {
    allow_single_sign_on_ = value;
    return S_OK;
  }

 private:
  std::atomic<ULONG> ref_count_{1};
  std::wstring browser_arguments_;
  std::wstring language_;
  std::wstring compatible_version_;
  BOOL allow_single_sign_on_ = FALSE;
};

}  // namespace

void WallpaperLog(const std::wstring& message) {
  Log(message);
}

void WallpaperWebview::DrainEnvironmentWaiters(HRESULT error) {
  std::vector<std::weak_ptr<WallpaperWebview>> waiters;
  waiters.swap(g_pending_environment_waiters);
  for (const auto& weak : waiters) {
    std::shared_ptr<WallpaperWebview> webview = weak.lock();
    if (!webview) {
      continue;
    }
    if (g_environment) {
      webview->CreateController();
    } else {
      webview->Fail(error);
    }
  }
}

WallpaperWebview::WallpaperWebview(
    HWND host_window, ReadyHandler on_ready, FailedHandler on_failed)
    : host_(host_window),
      on_ready_(std::move(on_ready)),
      on_failed_(std::move(on_failed)) {}

WallpaperWebview::~WallpaperWebview() {
  Destroy();
}

void WallpaperWebview::StartAsync() {
  if (started_) {
    return;
  }
  started_ = true;
  if (host_ == nullptr) {
    Fail(E_HANDLE);
    return;
  }
  if (g_environment) {
    CreateController();
    return;
  }
  if (g_environment_create_in_flight) {
    g_pending_environment_waiters.push_back(weak_from_this());
    return;
  }
  g_environment_create_in_flight = true;
  g_pending_environment_waiters.push_back(weak_from_this());
  Microsoft::WRL::ComPtr<WallpaperEnvOptions> options;
  options.Attach(new WallpaperEnvOptions());
  options->put_AdditionalBrowserArguments(kBrowserArguments);
  options->put_Language(kLanguage);
  wchar_t* available_version = nullptr;
  if (GetAvailableCoreWebView2BrowserVersionString(
          nullptr, &available_version) == S_OK &&
      available_version != nullptr) {
    options->put_TargetCompatibleBrowserVersion(available_version);
    CoTaskMemFree(available_version);
  }
  const std::wstring user_data_folder = UserDataFolder();
  Log(L"wallpaper webview: user data folder: " + user_data_folder);
  const HRESULT error = CreateCoreWebView2EnvironmentWithOptions(
      nullptr,
      user_data_folder.empty() ? nullptr : user_data_folder.c_str(),
      options.Get(),
      Microsoft::WRL::Callback<
          ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
          [](HRESULT result, ICoreWebView2Environment* environment)
              -> HRESULT {
            g_environment_create_in_flight = false;
            wchar_t code[16] = {};
            swprintf_s(code, 16, L"%08lX",
                       static_cast<unsigned long>(result));
            if (SUCCEEDED(result) && environment != nullptr) {
              g_environment = environment;
              Log(L"wallpaper webview: environment created");
            } else {
              Log(L"wallpaper webview: environment creation failed hr=0x" +
                  std::wstring(code));
            }
            WallpaperWebview::DrainEnvironmentWaiters(result);
            return S_OK;
          })
          .Get());
  if (FAILED(error)) {
    g_environment_create_in_flight = false;
    DrainEnvironmentWaiters(error);
  }
}

void WallpaperWebview::CreateController() {
  if (!g_environment || controller_ || host_ == nullptr) {
    return;
  }
  std::weak_ptr<WallpaperWebview> weak = weak_from_this();
  const HRESULT error = g_environment->CreateCoreWebView2Controller(
      host_,
      Microsoft::WRL::Callback<
          ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
          [weak](HRESULT result, ICoreWebView2Controller* controller)
              -> HRESULT {
            std::shared_ptr<WallpaperWebview> self = weak.lock();
            if (!self) {
              return S_OK;
            }
            if (FAILED(result) || controller == nullptr) {
              self->Fail(FAILED(result) ? result : E_FAIL);
              return S_OK;
            }
            self->OnControllerCreated(controller);
            return S_OK;
          })
          .Get());
  if (FAILED(error)) {
    Fail(error);
  }
}

void WallpaperWebview::OnControllerCreated(
    ICoreWebView2Controller* controller) {
  controller_ = controller;
  const HRESULT core_result = controller_->get_CoreWebView2(&webview_);
  if (FAILED(core_result) || !webview_) {
    Fail(core_result != S_OK ? core_result : E_FAIL);
    return;
  }
  ConfigureWebview();
  NavigateToWallpaper();
  Log(L"wallpaper webview: controller created");
}

void WallpaperWebview::ConfigureWebview() {
  RECT client = {};
  if (::GetClientRect(host_, &client)) {
    controller_->put_Bounds(client);
  }

  Microsoft::WRL::ComPtr<ICoreWebView2Settings> settings;
  if (SUCCEEDED(webview_->get_Settings(&settings)) && settings) {
    settings->put_AreDefaultContextMenusEnabled(FALSE);
    settings->put_AreDevToolsEnabled(TRUE);
    settings->put_IsStatusBarEnabled(FALSE);
    Microsoft::WRL::ComPtr<ICoreWebView2Settings3> settings3;
    if (SUCCEEDED(settings.As(&settings3)) && settings3) {
      settings3->put_AreBrowserAcceleratorKeysEnabled(FALSE);
    }
  }

  Microsoft::WRL::ComPtr<ICoreWebView2_3> webview3;
  if (SUCCEEDED(webview_.As(&webview3)) && webview3) {
    const std::wstring folder = WallpaperFolder();
    webview3->SetVirtualHostNameToFolderMapping(
        kVirtualHost, folder.c_str(),
        COREWEBVIEW2_HOST_RESOURCE_ACCESS_KIND_ALLOW);
  }

  std::weak_ptr<WallpaperWebview> weak = weak_from_this();
  webview_->add_WebMessageReceived(
      Microsoft::WRL::Callback<ICoreWebView2WebMessageReceivedEventHandler>(
          [weak](ICoreWebView2* sender,
                 ICoreWebView2WebMessageReceivedEventArgs* args) -> HRESULT {
            std::shared_ptr<WallpaperWebview> self = weak.lock();
            if (!self) {
              return S_OK;
            }
            self->HandlePageMessage(args);
            return S_OK;
          })
          .Get(),
      &message_token_);

  webview_->add_ProcessFailed(
      Microsoft::WRL::Callback<ICoreWebView2ProcessFailedEventHandler>(
          [weak](ICoreWebView2* sender,
                 ICoreWebView2ProcessFailedEventArgs* args) -> HRESULT {
            std::shared_ptr<WallpaperWebview> self = weak.lock();
            if (!self) {
              return S_OK;
            }
            COREWEBVIEW2_PROCESS_FAILED_KIND kind =
                COREWEBVIEW2_PROCESS_FAILED_KIND_BROWSER_PROCESS_EXITED;
            if (args != nullptr) {
              args->get_ProcessFailedKind(&kind);
            }
            self->OnProcessFailed(kind);
            return S_OK;
          })
          .Get(),
      &process_failed_token_);

  webview_->add_NavigationCompleted(
      Microsoft::WRL::Callback<ICoreWebView2NavigationCompletedEventHandler>(
          [](ICoreWebView2* sender,
             ICoreWebView2NavigationCompletedEventArgs* args) -> HRESULT {
            BOOL success = FALSE;
            if (args != nullptr) {
              args->get_IsSuccess(&success);
            }
            if (!success) {
              Log(L"wallpaper webview: navigation failed");
            }
            return S_OK;
          })
          .Get(),
      &navigation_token_);

  LoadShimScript();
  if (!g_shim_script.empty()) {
    webview_->AddScriptToExecuteOnDocumentCreated(
        g_shim_script.c_str(),
        Microsoft::WRL::Callback<
            ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandler>(
            [](HRESULT result, LPCWSTR id) -> HRESULT { return S_OK; })
            .Get());
  }
}

void WallpaperWebview::NavigateToWallpaper() {
  webview_->Navigate(kWallpaperUrl);
}

void WallpaperWebview::HandlePageMessage(
    ICoreWebView2WebMessageReceivedEventArgs* args) {
  PWSTR json = nullptr;
  if (FAILED(args->get_WebMessageAsJson(&json)) || json == nullptr) {
    return;
  }
  const std::wstring message(json);
  CoTaskMemFree(json);
  if (message.find(L"\"topic\":\"ready\"") != std::wstring::npos) {
    page_ready_ = true;
    Log(L"wallpaper webview: page ready");
    if (on_ready_) {
      on_ready_();
    }
  }
}

void WallpaperWebview::OnProcessFailed(
    COREWEBVIEW2_PROCESS_FAILED_KIND kind) {
  Log(L"wallpaper webview: process failed, reloading");
  Reload();
}

void WallpaperWebview::SetBounds(RECT bounds) {
  if (controller_) {
    controller_->put_Bounds(bounds);
  }
}

void WallpaperWebview::PostState(const std::string& payload_json) {
  if (!webview_ || !page_ready_) {
    return;
  }
  std::wstring body = Trim(Utf8ToWide(payload_json));
  if (body.empty()) {
    body = L"{}";
  }
  const std::wstring message =
      L"{\"topic\":\"state\",\"body\":" + body + L"}";
  webview_->PostWebMessageAsJson(message.c_str());
}

void WallpaperWebview::Reload() {
  if (webview_) {
    webview_->Reload();
  }
}

void WallpaperWebview::OpenDevTools() {
  if (webview_) {
    webview_->OpenDevToolsWindow();
  }
}

void WallpaperWebview::Destroy() {
  if (webview_) {
    if (message_token_.value != 0) {
      webview_->remove_WebMessageReceived(message_token_);
    }
    if (process_failed_token_.value != 0) {
      webview_->remove_ProcessFailed(process_failed_token_);
    }
    if (navigation_token_.value != 0) {
      webview_->remove_NavigationCompleted(navigation_token_);
    }
  }
  message_token_ = {};
  process_failed_token_ = {};
  navigation_token_ = {};
  if (controller_) {
    controller_->Close();
  }
  controller_ = nullptr;
  webview_ = nullptr;
  page_ready_ = false;
}

void WallpaperWebview::Fail(HRESULT error) {
  if (failed_) {
    return;
  }
  failed_ = true;
  std::wstring detail = L"wallpaper webview: failed hr=0x";
  wchar_t code[16] = {};
  swprintf_s(code, 16, L"%08lX", static_cast<unsigned long>(error));
  detail += code;
  Log(detail);
  if (on_failed_) {
    on_failed_(error);
  }
}
