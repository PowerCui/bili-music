// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_view_mode_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlayerViewModeLogic)
final playerViewModeLogicProvider = PlayerViewModeLogicProvider._();

final class PlayerViewModeLogicProvider
    extends $NotifierProvider<PlayerViewModeLogic, PlayerViewMode> {
  PlayerViewModeLogicProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerViewModeLogicProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerViewModeLogicHash();

  @$internal
  @override
  PlayerViewModeLogic create() => PlayerViewModeLogic();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerViewMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerViewMode>(value),
    );
  }
}

String _$playerViewModeLogicHash() =>
    r'20e13e7f55c37987ab35b215c201a43b4497189b';

abstract class _$PlayerViewModeLogic extends $Notifier<PlayerViewMode> {
  PlayerViewMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayerViewMode, PlayerViewMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerViewMode, PlayerViewMode>,
              PlayerViewMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
