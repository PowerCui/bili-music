import 'package:bilimusic/core/hive/hive_keys.dart';
import 'package:bilimusic/core/settings/app_settings_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_wallpaper_setting_logic.g.dart';

typedef DesktopWallpaperSettings = ({bool enabled, int monitorIndex});

@riverpod
class DesktopWallpaperSettingLogic extends _$DesktopWallpaperSettingLogic {
  @override
  DesktopWallpaperSettings build() {
    final AppSettingsStore store = ref.read(appSettingsStoreProvider);
    final String rawMonitorIndex = store.readString(
      HiveKeys.desktopWallpaperMonitor,
      defaultValue: '0',
    );
    return (
      enabled: store.readBool(
        HiveKeys.desktopWallpaperEnabled,
        defaultValue: false,
      ),
      monitorIndex: int.tryParse(rawMonitorIndex) ?? 0,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.enabled == enabled) {
      return;
    }
    state = (enabled: enabled, monitorIndex: state.monitorIndex);
    await ref
        .read(appSettingsStoreProvider)
        .writeBool(HiveKeys.desktopWallpaperEnabled, enabled);
  }

  Future<void> setMonitorIndex(int index) async {
    if (state.monitorIndex == index) {
      return;
    }
    state = (enabled: state.enabled, monitorIndex: index);
    await ref
        .read(appSettingsStoreProvider)
        .writeString(HiveKeys.desktopWallpaperMonitor, '$index');
  }
}
