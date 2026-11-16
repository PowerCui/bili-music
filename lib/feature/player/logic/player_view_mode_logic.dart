import 'package:bilimusic/core/hive/hive_keys.dart';
import 'package:bilimusic/core/settings/app_settings_store.dart';
import 'package:bilimusic/feature/player/domain/player_view_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_view_mode_logic.g.dart';

@riverpod
class PlayerViewModeLogic extends _$PlayerViewModeLogic {
  @override
  PlayerViewMode build() {
    return PlayerViewMode.fromStorage(
      ref
          .read(appSettingsStoreProvider)
          .readString(
            HiveKeys.playerViewMode,
            defaultValue: PlayerViewMode.standard.name,
          ),
    );
  }

  Future<void> setMode(PlayerViewMode mode) async {
    if (state == mode) {
      return;
    }
    state = mode;
    await ref
        .read(appSettingsStoreProvider)
        .writeString(HiveKeys.playerViewMode, mode.name);
  }

  Future<void> toggle() {
    return setMode(
      state == PlayerViewMode.cd ? PlayerViewMode.standard : PlayerViewMode.cd,
    );
  }
}
