import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:bilimusic/feature/player/logic/display/now_playing_provider.dart';
import 'package:bilimusic/feature/player/logic/display/player_cover_color_provider.dart';
import 'package:bilimusic/feature/player/logic/player_controller.dart';
import 'package:bilimusic/feature/player/ui/cd/cd_player_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CdPlayerContent extends ConsumerWidget {
  const CdPlayerContent({super.key, this.onExitCdMode});

  final VoidCallback? onExitCdMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NowPlaying? nowPlaying = ref.watch(nowPlayingProvider);
    final NowPlayingPlayback playback = ref.watch(nowPlayingPlaybackProvider);
    final Color accentColor =
        ref.watch(playerCoverColorControllerProvider) ??
        Theme.of(context).colorScheme.primary;
    final PlayerController controller = ref.read(
      playerControllerProvider.notifier,
    );
    final VoidCallback? onExit = onExitCdMode;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CdPlayerView(
          nowPlaying: nowPlaying,
          playback: playback,
          accentColor: accentColor,
          onTogglePlayback: controller.togglePlayback,
          onPrevious: playback.hasPrevious ? controller.skipToPrevious : null,
          onNext: playback.hasNext ? controller.skipToNext : null,
          onSeek: controller.seek,
        ),
        if (onExit != null)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _CdViewModeButton(
                  tooltip: '返回默认视图',
                  icon: Icons.image_outlined,
                  onTap: onExit,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CdViewModeButton extends StatelessWidget {
  const _CdViewModeButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ),
      ),
    );
  }
}
