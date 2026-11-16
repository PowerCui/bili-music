import 'package:bilimusic/feature/player/logic/player_view_mode_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CdViewModeButton extends ConsumerWidget {
  const CdViewModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: '光盘视图',
      onPressed: () => ref.read(playerViewModeLogicProvider.notifier).toggle(),
      icon: const Icon(Icons.album_outlined),
    );
  }
}
