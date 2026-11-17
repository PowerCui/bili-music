// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_playing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nowPlaying)
final nowPlayingProvider = NowPlayingProvider._();

final class NowPlayingProvider
    extends $FunctionalProvider<NowPlaying?, NowPlaying?, NowPlaying?>
    with $Provider<NowPlaying?> {
  NowPlayingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowPlayingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowPlayingHash();

  @$internal
  @override
  $ProviderElement<NowPlaying?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NowPlaying? create(Ref ref) {
    return nowPlaying(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NowPlaying? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NowPlaying?>(value),
    );
  }
}

String _$nowPlayingHash() => r'cff290272cb2ceaf21ba75a4682df9b5b0929906';

@ProviderFor(nowPlayingPlayback)
final nowPlayingPlaybackProvider = NowPlayingPlaybackProvider._();

final class NowPlayingPlaybackProvider
    extends
        $FunctionalProvider<
          NowPlayingPlayback,
          NowPlayingPlayback,
          NowPlayingPlayback
        >
    with $Provider<NowPlayingPlayback> {
  NowPlayingPlaybackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowPlayingPlaybackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowPlayingPlaybackHash();

  @$internal
  @override
  $ProviderElement<NowPlayingPlayback> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NowPlayingPlayback create(Ref ref) {
    return nowPlayingPlayback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NowPlayingPlayback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NowPlayingPlayback>(value),
    );
  }
}

String _$nowPlayingPlaybackHash() =>
    r'0ab1699d57fb55d96662b621d9973243c245be13';
