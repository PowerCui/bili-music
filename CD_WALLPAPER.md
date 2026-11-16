# CD 播放页与桌面壁纸

本文档说明 1.14.0 中新增的「CD 光盘播放页」与「Windows 桌面壁纸」的实现方式、数据流、方案取舍与已知限制。

## 数据流

所有呈现都由播放器的既有状态派生，不存在第二条抓取链路：

```
playerControllerProvider (PlayableItem / duration / queueSourceLabel / playback)
        │
        ├── playerDisplayProvider ────┐             (标题/歌手/封面/来源)
        ├── metadataControllerProvider ┼──> nowPlayingProvider  ──> NowPlaying (标题/歌手/封面/歌词/偏移)
        └── playerSubtitleController ──┘                              │
                                                                      ├──> nowPlayingPlaybackProvider ──> NowPlayingPlayback (进度/时长/播放态/速度/上下首)
                                                                      ├──> playerCoverColorControllerProvider ──> accentColor
                                                                      ▼
                        ┌─────────────────────────────┬──────────────────────────────┐
                        │ 默认播放页（无线行为不变）    │ CD 播放页 CdPlayerContent     │
                        └─────────────────────────────┴──────────────┬───────────────┘
                                                                      │ 同一条 payload（JSON + 封面字节）
                                                                      ▼
                                                     DesktopWallpaperController ──MethodChannel──> 壁纸窗口
```

- `NowPlaying`、`NowPlayingPlayback` 是纯 domain 模型（`lib/feature/player/domain/now_playing.dart`），不含平台依赖。
- CD 视图（`lib/feature/player/ui/cd/`）只接收这两个模型 + accentColor + 若干回调，**不读 Riverpod、不读环境 Theme**，因此主窗口与壁纸窗口拿到相同输入即渲染相同像素。
- 歌词走 `flutter_lyric`：`CdLyricPane` 内部自建 `LyricController` + `_CdLyricProgressSource`（由 `NowPlayingPlayback` 驱动，与 `PlayerLyricPanel` 的进度源同构）。字幕优先于元数据歌词，规则与默认歌词页一致（`nowPlayingProvider` 内统一处理）。

## Windows 壁纸窗口方案

**方案：自研原生第二 Flutter 窗口（同进程，第二 Flutter 引擎）**

- `windows/runner/wallpaper_window.{h,cpp}`：`WallpaperWindow : Win32Window`，`OnCreate` 中 `project.set_dart_entrypoint("wallpaperMain")` 起第二引擎，`FlutterViewController` 铺满客户区。
- 置底：`SendMessageTimeout(Progman, 0x052C, ...)` 后寻找挂有 `SHELLDLL_DefView` 的 WorkerW 的后一个 WorkerW 并 `SetParent` 过去；失败则回退 `FindWindowEx`，再失败则退化为普通无边框窗口（不崩溃）。
- 样式：清除 `WS_CAPTION|WS_THICKFRAME|WS_SYSMENU|WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_POPUP`，嵌入成功补 `WS_CHILD`；`WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE` 保证无任务栏图标、不抢焦点；**不使用 `WS_EX_TRANSPARENT`**，鼠标事件可直达壁纸窗口，因此光盘点击/进度条拖动在桌面上可用。
- 多显示器/DPI：`MonitorBounds` 取 `MONITORINFO.rcMonitor` 物理像素；`WM_DPICHANGED` 后重新 `ApplyBounds()`。
- 生命周期：主窗口关闭 → `HideWallpaper()` 销毁第二引擎；Dart 侧写设置关闭时 `hide` 立即销毁。

为什么不用 `desktop_lyrics` 的悬浮窗：该插件是原生分层窗口 + 单行文字绘制，不能承载 Flutter Widget，无法复用 CD 视图，也无法保证与 CD 页逐像素一致。
为什么不引入 `desktop_multi_window`：本方案需要 `WorkerW` 置底、`WS_EX_TOOLWINDOW`、物理像素 DPI 校正等原生控制，这些在该插件里都得不到；仓库已有「自研 C++ + MethodChannel」先例（任务栏缩略图工具栏），沿用同一范式不新增任何 pub 依赖（`win32`/`ffi` 仅为传递依赖，未直接使用）。

## 跨窗口通信

两个 MethodChannel，均无网络、无端口：

| 通道 | 方向 | 方法 |
| --- | --- | --- |
| `bilimusic/desktop_wallpaper` | Dart（主引擎）→ C++ | `show{monitorIndex}`、`hide`、`pushState{payload,cover}`、`listMonitors` |
| `bilimusic/desktop_wallpaper` | C++ → Dart | `control{type,positionMs}`、`windowClosed` |
| `bilimusic/desktop_wallpaper_view` | Dart（壁纸引擎）→ C++ | `ready`、`control{type,positionMs}` |
| `bilimusic/desktop_wallpaper_view` | C++ → Dart | `state{payload,cover}` |

`type` ∈ `toggle` / `play` / `pause` / `next` / `previous` / `seek`。主引擎把播放状态组装成 `DesktopWallpaperPayload`（JSON，含 schema 版本），封面取本机图片缓存文件的字节一次性推送，壁纸侧不再联网。

## 设置项

`lib/feature/setting/ui/desktop_wallpaper_page.dart`（入口：设置 → 桌面壁纸，仅 Windows 显示）：

- 在桌面显示光盘（开关）
- 显示器选择（多屏时显示，默认按 C++ 返回的 `primary` 标记）

持久化键（`lib/core/hive/hive_keys.dart`）：`desktop.wallpaper.enabled`、`desktop.wallpaper.monitor`；播放页视图选择持久化在 `player.view_mode`。

## 验证方式

本机不具备 Flutter 工具链，全部验证在 GitHub Actions（`.github/workflows/cd-wallpaper-build.yaml`）中完成：`build_runner`（生成 `*.g.dart`/`*.freezed.dart`，本仓库不跟踪新生成物）→ `dart format` 检查与 `flutter analyze`（记录用，不阻塞）→ `flutter test`（非阻塞）→ Windows release 打包 innosetup → Android debug APK。

三个 job 都会先跑 `dart run build_runner build --delete-conflicting-outputs`，因此新增的注解类（`now_playing`、`now_playing_provider`、`player_view_mode_logic`、`desktop_wallpaper_setting_logic`、`desktop_wallpaper_controller`）不需要在本地提交生成文件即可编译通过；若希望本地也保留生成物，执行同一条命令后再一并提交即可。

## 已知限制

1. **窗口不透明**：壁纸窗口铺满整屏绘制自己的背景（模糊封面 + 取色光晕 + 光盘），不做逐像素透明，因此它会完整覆盖桌面图标层之上的壁纸图片。若需要看见原始壁纸，后续可改为按窗口分层透明合成。
2. **枚举顺序**：`listMonitors` 的顺序来自 `EnumDisplayMonitors`，不保证主屏在 index 0；设置页默认按 `primary` 标记选中。
3. **DPI 混合场景**：若引擎内部消费了 `WM_DPICHANGED`，重新摆放可能依赖引擎自身 resize，混合 DPI 多屏下需实测确认。
4. **仅 Windows**：其他平台构建不受影响（相关 Dart 代码全部以 `PlatformUtil.isWindows` 或原生实现隔离），但功能不可用。
5. **点击穿透**：因为未使用 `WS_EX_TRANSPARENT`，壁纸窗口会接收鼠标事件；若用户希望完全穿透到桌面图标，需要再加一个开关（当前未提供）。
