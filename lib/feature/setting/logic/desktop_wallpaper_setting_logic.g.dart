// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_wallpaper_setting_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DesktopWallpaperSettingLogic)
final desktopWallpaperSettingLogicProvider =
    DesktopWallpaperSettingLogicProvider._();

final class DesktopWallpaperSettingLogicProvider
    extends
        $NotifierProvider<
          DesktopWallpaperSettingLogic,
          DesktopWallpaperSettings
        > {
  DesktopWallpaperSettingLogicProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopWallpaperSettingLogicProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopWallpaperSettingLogicHash();

  @$internal
  @override
  DesktopWallpaperSettingLogic create() => DesktopWallpaperSettingLogic();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopWallpaperSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopWallpaperSettings>(value),
    );
  }
}

String _$desktopWallpaperSettingLogicHash() =>
    r'67e5c788d6ca56ceb1403fb5d3d1ec5fba07eb1a';

abstract class _$DesktopWallpaperSettingLogic
    extends $Notifier<DesktopWallpaperSettings> {
  DesktopWallpaperSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<DesktopWallpaperSettings, DesktopWallpaperSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DesktopWallpaperSettings, DesktopWallpaperSettings>,
              DesktopWallpaperSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
