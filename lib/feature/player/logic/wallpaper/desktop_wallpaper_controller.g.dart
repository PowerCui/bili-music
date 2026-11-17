// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_wallpaper_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DesktopWallpaperController)
final desktopWallpaperControllerProvider =
    DesktopWallpaperControllerProvider._();

final class DesktopWallpaperControllerProvider
    extends $NotifierProvider<DesktopWallpaperController, bool> {
  DesktopWallpaperControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopWallpaperControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopWallpaperControllerHash();

  @$internal
  @override
  DesktopWallpaperController create() => DesktopWallpaperController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$desktopWallpaperControllerHash() =>
    r'7b997f278ee9e6c30e008eb51bf0f321c65440bc';

abstract class _$DesktopWallpaperController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
