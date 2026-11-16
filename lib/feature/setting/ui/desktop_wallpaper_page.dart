import 'package:bilimusic/common/util/platform_util.dart';
import 'package:bilimusic/feature/player/logic/wallpaper/wallpaper_bridge.dart';
import 'package:bilimusic/feature/setting/logic/desktop_wallpaper_setting_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesktopWallpaperPage extends ConsumerStatefulWidget {
  const DesktopWallpaperPage({super.key});

  @override
  ConsumerState<DesktopWallpaperPage> createState() =>
      _DesktopWallpaperPageState();
}

class _DesktopWallpaperPageState extends ConsumerState<DesktopWallpaperPage> {
  List<WallpaperMonitor> _monitors = const <WallpaperMonitor>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonitors();
  }

  Future<void> _loadMonitors() async {
    final List<WallpaperMonitor> monitors = PlatformUtil.isWindows
        ? await DesktopWallpaperBridge.listMonitors()
        : const <WallpaperMonitor>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _monitors = monitors;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DesktopWallpaperSettings settings = ref.watch(
      desktopWallpaperSettingLogicProvider,
    );
    final DesktopWallpaperSettingLogic logic = ref.read(
      desktopWallpaperSettingLogicProvider.notifier,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('桌面壁纸')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('在桌面显示光盘'),
            value: settings.enabled,
            onChanged: logic.setEnabled,
          ),
          if (settings.enabled && _monitors.length > 1) ...<Widget>[
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('显示器', style: theme.textTheme.titleSmall),
            ),
            for (final WallpaperMonitor monitor in _monitors)
              RadioListTile<int>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: monitor.index,
                groupValue: settings.monitorIndex,
                title: Text(monitor.label),
                onChanged: (int? value) {
                  if (value != null) {
                    logic.setMonitorIndex(value);
                  }
                },
              ),
          ],
          if (settings.enabled && _loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
