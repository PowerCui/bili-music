import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:bilimusic/feature/player/ui/cd/cd_control_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _dragTargetFinder() {
  return find.descendant(
    of: find.byType(CdControlBar),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is GestureDetector && widget.onHorizontalDragUpdate != null,
    ),
  );
}

Future<void> _pumpBar(WidgetTester tester, List<Duration> seekCalls) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: CdControlBar(
              playback: NowPlayingPlayback(
                position: const Duration(seconds: 10),
                duration: const Duration(seconds: 100),
                isPlaying: true,
                hasItem: true,
                hasPrevious: true,
                hasNext: true,
              ),
              accentColor: const Color(0xFF3E8EED),
              onSeek: seekCalls.add,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('drag updates preview only and commits seek on release', (
    WidgetTester tester,
  ) async {
    final List<Duration> seeks = <Duration>[];
    await _pumpBar(tester, seeks);

    final Finder target = _dragTargetFinder();
    expect(target, findsOneWidget);
    final Rect rect = tester.getRect(target);

    final TestGesture gesture = await tester.startGesture(
      Offset(rect.left + 8, rect.center.dy),
    );
    await tester.pump();
    await gesture.moveBy(Offset(rect.width * 0.42, 0));
    await tester.pump();
    await gesture.moveBy(Offset(rect.width * 0.3, 0));
    await tester.pump();
    expect(seeks, isEmpty);

    await gesture.up();
    await tester.pump();
    expect(seeks, hasLength(1));
    expect(seeks.single.inMilliseconds, inInclusiveRange(72000, 77000));
  });

  testWidgets('tap on track commits seek immediately', (
    WidgetTester tester,
  ) async {
    final List<Duration> seeks = <Duration>[];
    await _pumpBar(tester, seeks);

    final Rect rect = tester.getRect(_dragTargetFinder());
    await tester.tapAt(Offset(rect.left + rect.width * 0.75, rect.center.dy));
    await tester.pump();

    expect(seeks, hasLength(1));
    expect(seeks.single.inMilliseconds, inInclusiveRange(73000, 77000));
  });

  testWidgets('cancelled drag commits no seek', (WidgetTester tester) async {
    final List<Duration> seeks = <Duration>[];
    await _pumpBar(tester, seeks);

    final Rect rect = tester.getRect(_dragTargetFinder());
    final TestGesture gesture = await tester.startGesture(
      Offset(rect.left + 8, rect.center.dy),
    );
    await tester.pump();
    await gesture.moveBy(Offset(rect.width * 0.5, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(seeks, isEmpty);
  });
}
