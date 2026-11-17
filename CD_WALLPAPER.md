# CD 播放页与桌面壁纸（v2）

本文档说明 1.14.0 中「CD 光盘播放页」与「Windows 桌面壁纸」的实现方式、数据流、方案取舍与已知限制。v2 版本用一个纯 Win32 + WebView2 宿主窗口替换了早期的第二 Flutter 引擎窗口，并直接复用 Wallpaper Engine 工坊交互壁纸《Click-Interactive CD》的前端本体（仅个人使用，素材不随源码分发）。

## 总体架构

```
┌─ Flutter 主引擎（唯一的播放器状态源） ──────────────────────────────┐
│ playerControllerProvider                                            │
│   ├─ nowPlayingProvider        (标题/歌手/封面/歌词 NowPlaying)      │
│   └─ nowPlayingPlaybackProvider (进度/时长/播放态 NowPlayingPlayback)│
│        │                                                            │
│        ▼                                                            │
│ DesktopWallpaperController（180ms 去抖 + 1Hz 进度分频 + 变化门控）   │
│        │  MethodChannel: bilimusic/desktop_wallpaper                │
│        │  show / hide / pushState{payload} / listMonitors / reload  │
└────────┼────────────────────────────────────────────────────────────┘
         ▼
┌─ C++ 原生层（windows/runner） ──────────────────────────────────────┐
│ FlutterWindow ── WallpaperWindow（WorkerW 置底） ── WallpaperWebview │
│  · payload 按不透明 JSON 透传，不做字段过滤                          │
│  · PostWebMessageAsJson({"topic":"state","body":<payload>})          │
│  · WebMessageReceived 只识别 {"topic":"ready"}（DOMContentLoaded 上报）│
└────────┼────────────────────────────────────────────────────────────┘
         ▼
┌─ WebView2 渲染进程 ─────────────────────────────────────────────────┐
│ https://wallpaper.assets/index.html?offline=1                        │
│  ← AddScriptToExecuteOnDocumentCreated 提前注入 wallpaper_host/shim.js│
│  shim 实现 WPE 媒体桥 7 个全局函数 → 工坊壁纸 JS（bundle/case/media/…）│
│  完全无改动驱动：旋转 CD、歌词、色晕、视差                            │
└──────────────────────────────────────────────────────────────────────┘
```

- 单一数据源不变：壁纸与 CD 页共用 `NowPlaying` + `NowPlayingPlayback`；CD 页是 Flutter Widget（`lib/feature/player/ui/cd/`），壁纸是工坊壁纸本体，两者内容一致、观感不同（用户已确认不要求逐像素一致）。
- 播放内核只读：宿主→网页方向只有状态推送；网页→宿主方向 v1 只有 `ready` 握手，不存在页面反控。

## Windows 壁纸窗口（纯 Win32 + WebView2）

**为什么替换第二 Flutter 引擎**：上一版在同一进程里跑两个 Flutter 引擎（`set_dart_entrypoint("wallpaperMain")`），真机上出现 0xC000041D（用户回调越界异常）崩溃，两个不同构建的崩溃转储签名一致且都落在第二引擎窗口过程附近；第二引擎还带来全量重建开销与内存翻倍。WebView2（Edge 内核）是 Windows 10/11 自带运行时的工业方案，宿主窗口只是普通 Win32 容器。

- `windows/runner/wallpaper_window.{h,cpp}`：WorkerW 置底骨架保留——`SendMessageTimeout(Progman, 0x052C)` → 找挂 `SHELLDLL_DefView` 的 WorkerW 的**后一个** WorkerW `SetParent`；失败退 Progman 子 WorkerW；再失败退普通 `WS_POPUP` 无边框窗口（不巡检重建，防 30s churn）。样式 `WS_CHILD|WS_CLIPCHILDREN|WS_CLIPSIBLINGS` + `WS_EX_TOOLWINDOW|WS_EX_NOACTIVATE`（无任务栏图标、不抢焦点、无 `WS_EX_TRANSPARENT`）。
- `windows/runner/wallpaper_webview.{h,cpp}`：WebView2 宿主。
  - **Environment 进程级单例**（含 in-flight 标志 + pending waiters，并发 show 安全）；User Data Folder `%LOCALAPPDATA%\bilimusic\webview2`。
  - **虚拟主机** `SetVirtualHostNameToFolderMapping(L"wallpaper.assets", ...data\flutter_assets\assets\wallpaper, ALLOW)`，导航 `https://wallpaper.assets/index.html?offline=1`（规避 file:// 的 ES module/CORS 限制；`offline=1` 关掉壁纸自身的在线元数据兜底）。
  - **shim 注入**：`AddScriptToExecuteOnDocumentCreated(wallpaper_host/shim.js)`，先于页面一切脚本执行。
  - **反节流**：`--disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=CalculateNativeWinOcclusion`（壁纸永远被遮挡/不可见，默认策略会停帧）。
  - `ProcessFailed → Reload` 自动复活；DevTools 预留（Dart `openDevTools`）。
- SDK vendored：`windows/third_party/webview2/`（1.0.4314.35，WebView2.h + x64 WebView2Loader.dll/.lib + LICENSE/NOTICE）。`runner/CMakeLists.txt` 链接 `WebView2Loader.dll.lib`，POST_BUILD `copy_if_different` loader DLL、`copy_directory` 素材与垫片到 `data/flutter_assets/assets/`（**Windows 专用补包，pubspec 不声明素材目录，Android 不嵌素材**）。
- **素材合规**：`assets/wallpaper/` 平时只有 README 占位（`.gitignore` 挡其余文件），CI 从 GitHub **draft release**（tag `wallpaper-assets`，本人可见）用 `WALLPAPER_ASSETS_TOKEN` secret 拉取 zip 解包——工坊素材既不进 git 历史，也不进公开 release。
- 韧性：`TaskbarCreated`（Explorer 重启）→ 3s 后重建壁纸窗；30s 巡检父级失效自动重建；窗口身份 tag 防 stale 消息误杀新窗；WebView2 运行时缺失时创建失败 → `WM_APP+2` → 通知 Dart 关闭开关（不崩溃）。运行前可用 `GetAvailableCoreWebView2BrowserVersionString` 预检（未默认启用，依赖 Win10/11 预装）。

## WPE 垫片（shim.js，assets/wallpaper_host/shim.js）

工坊壁纸 JS 无改动。shim 在页面脚本前提供 Wallpaper Engine 媒体桥全套全局函数：

- `wallpaperRegisterAudioListener`（bundle 的门槛函数）+ 5 个 `wallpaperRegisterMedia*Listener`（Properties/Thumbnail/Playback/Timeline/Status）——全部可重入（壁纸约 0.6-24s 周期重注册），每次注册即补发快照。
- `wallpaperMediaIntegration`/`MI` 常量（PLAYING=1/PAUSED=2/STOPPED=3）。
- 宿主反向调 `wallpaperPropertyListener.applyUserProperties`（壁纸自己赋值该对象；shim 只调不定义）：加载 `project.json` 的 general.properties 默认值并多次投递。
- 音频：合成 128 bin 伪频谱（40ms 周期，播放时才有 timer）。
- 歌词：接收 LRC 后轮询 `window.__lyrics.demo(lrc)` 注入（lyrics.js 晚加载）。
- 断网三保险：C++ `?offline=1` 参数 + shim 启动即调 `CD_NET.setOffline(true)` + 页面自然无外网需求（虚拟主机只映射本地文件夹，外网 fetch 仍会被 WebView2 放行——`offline=1`/`setOffline` 负责让壁纸逻辑不去尝试）。

## 跨窗口通信（v2 收敛为单通道）

`bilimusic/desktop_wallpaper`（主引擎 Dart ↔ C++）：

| 方向 | 方法/事件 | 说明 |
| --- | --- | --- |
| Dart → C++ | `show{monitorIndex}` | 建窗（WorkerW）+ 建 WebView2 + 导航 |
| Dart → C++ | `hide` | 关 controller（Environment 保活） |
| Dart → C++ | `pushState{payload}` | payload = JSON 字符串，C++ 不透明转发 |
| Dart → C++ | `listMonitors` | 返回 `[{name, index, primary}]` |
| Dart → C++ | `reload` / `openDevTools` | 调试便利 |
| C++ → Dart | `ready` | 网页 shim 上报（状态缓存重放） |
| C++ → Dart | `control{payload}` | 预留（v1 页面不发起控制） |
| C++ → Dart | `windowClosed` | 壁纸窗死亡（WebView2 失败）→ Dart 自动关开关 |

payload body（`DesktopWallpaperPayload`，`lib/feature/player/logic/wallpaper/desktop_wallpaper_payload.dart`）：`title/artist/albumTitle/subTitle/genres/contentType/thumbnail(data URL，封面字节经魔数嗅探编码)/position/duration`（秒）`/state`(1/2/3)`/lyrics`（LRC，变化才带）。封面 180ms 去抖、进度 1Hz、元数据/缩略图/歌词各自 change-gating。

## CD 播放页修复（本轮顺带）

- 进度条 `Alignment(x, double.infinity)` 越界 → `_CdProgressTrack` 转 StatefulWidget：拖动中只本地预览，`dragEnd`/点击才 commit seek。
- 暂停恢复从 0° 重转 → 记录 `_turnsOffset` 续转；RepeatBoundary 用 `Transform.rotate` 替代 RotationTransition 避免边界跳变。

## 设置项

设置 → 桌面壁纸（仅 Windows 显示，`lib/feature/setting/ui/desktop_wallpaper_page.dart`）：开关 + 显示器选择。Hive 键不变：`desktop.wallpaper.enabled`、`desktop.wallpaper.monitor`、`player.view_mode`。

## 验证方式（GitHub Actions）

`.github/workflows/cd-wallpaper-build.yaml`，push `feat/cd-wallpaper-v2` 触发：

- `verify`（ubuntu）：build_runner → `flutter analyze --no-fatal-infos`（门禁）→ `flutter test`（记录）。
- `build-windows`（需 verify）：**Fetch wallpaper assets**（draft release 拉取，见上文素材合规）→ build_runner → `flutter build windows --release` → Inno Setup → artifact `bilimusic-cd-wallpaper-windows`（**retention 1 天**，含减少公开暴露的考虑）。
- `build-android`（需 verify，JDK 17）：不拉素材，验证 Android 不回归。

## 已知限制（v2）

1. **桌面图标层挡住鼠标交互**：WorkerW 布局中图标层（SysListView32）在壁纸窗之上，真实鼠标事件到不了壁纸窗。壁纸的点击/拖动交互（开盒、转盘拨动）在桌面上默认不可用——需要宿主轮询光标+按键并合成 pointer 事件（约 60 行，未在本轮范围）。CD 播放页（应用内）不受影响。
2. **依赖 WebView2 Runtime**：Win10/11 绝大多数预装（Edge 同源）；缺失时壁纸开关自动关闭并记日志，应用本体不受影响。
3. **WorkerW 缺失退化**：极端桌面环境下退化为普通置底窗口（不巡检重建）。
4. **素材不随源码分发**：克隆本仓库直接 `flutter build windows` 得到的是无素材构建（壁纸开启后页面 404）；走 CI（draft release 拉取）才有完整产物。个人使用用途。
5. **仅 Windows**：其他平台构建不受影响，功能不可用。
