import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voges_updater/voges_updater.dart'
    show
        LaunchAvailability,
        LaunchResult,
        ReleaseFeed,
        ReleaseVersion,
        UpdateCheck,
        UpdaterLauncher,
        vogesPencil;
import 'package:voges_pencil/app.dart';
import 'package:voges_pencil/canvas/image_ops.dart';
import 'package:voges_pencil/canvas/paint_controller.dart';
import 'package:voges_pencil/canvas/paint_document.dart';
import 'package:voges_pencil/canvas/tool_settings.dart';
import 'package:voges_pencil/files/image_clipboard.dart';
import 'package:voges_pencil/files/image_files.dart';
import 'package:voges_pencil/files/system_open.dart';
import 'package:voges_pencil/l10n/app_language.dart';

Future<PaintController> _pump(
  WidgetTester tester, {
  Locale? locale,
  Size size = const Size(1400, 900),
  UpdateCheck? updates,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = PaintController(
    document: PaintDocument(blankImage(200, 100, const Color(0xFFFFFFFF))),
    settings: ToolSettings(),
  );
  final files = ImageFiles();
  await tester.pumpWidget(
    VogesPencilApp(
      controller: controller,
      files: files,
      clipboard: ImageClipboard(),
      systemOpen: SystemOpen(files),
      language: AppLanguage(locale),
      launchArguments: const [],
      updates: updates,
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

final class _Feed implements ReleaseFeed {
  const _Feed(this.version);

  final ReleaseVersion version;

  @override
  Future<ReleaseVersion> latest(String repository) async => version;
}

final class _OfflineFeed implements ReleaseFeed {
  const _OfflineFeed();

  @override
  Future<ReleaseVersion> latest(String repository) async =>
      throw const SocketException('offline');
}

final class _Launcher implements UpdaterLauncher {
  _Launcher(this.result, {this.opening});

  final LaunchResult result;

  /// Holds the launch open until completed, like the Windows copy does.
  final Completer<LaunchResult>? opening;
  var launches = 0;

  @override
  LaunchAvailability get availability => LaunchAvailability.here;

  @override
  Future<LaunchResult> launch() async {
    launches++;
    return opening?.future ?? result;
  }

  @override
  Future<void> cleanUp() async {}
}

UpdateCheck _updates(
  _Launcher launcher, {
  ReleaseFeed feed = const _Feed(ReleaseVersion(9, 9, 9)),
}) => UpdateCheck(
  app: vogesPencil,
  current: const ReleaseVersion(1, 0, 0),
  feed: feed,
  launcher: launcher,
);

/// The calls the app makes to the window, such as `destroy`.
List<String> _recordWindowCalls() {
  final calls = <String>[];
  const channel = MethodChannel('window_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    calls.add(call.method);
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  return calls;
}

void _change(PaintController controller) =>
    controller.document.commit(blankImage(200, 100, const Color(0xFF000000)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the ribbon picks tools and drawing marks the image', (
    tester,
  ) async {
    final controller = await _pump(tester);
    expect(find.text('Untitled'), findsOneWidget);

    await tester.tap(find.byTooltip('Brush'));
    expect(controller.settings.tool, PaintTool.brush);

    final canvas = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.size == const Size(200, 100),
    );
    final center = tester.getCenter(canvas);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(30, 10));
    await gesture.up();
    await tester.pump();
    expect(controller.document.dirty, isTrue);
    expect(find.byTooltip('Unsaved changes'), findsOneWidget);
  });

  testWidgets('the status bar shows the size and the zoom', (tester) async {
    await _pump(tester);
    expect(find.text('200 × 100 px'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(find.text('150%'), findsOneWidget);
  });

  testWidgets('the ribbon follows the chosen language', (tester) async {
    await _pump(tester, locale: const Locale('pt'));
    expect(find.text('Arquivo'), findsOneWidget);
    expect(find.byTooltip('Balde de tinta'), findsOneWidget);
    expect(find.text('Sem título'), findsOneWidget);
  });

  group('updates', () {
    testWidgets('the status bar says when the app is up to date', (
      tester,
    ) async {
      await _pump(
        tester,
        updates: _updates(
          _Launcher(LaunchResult.started),
          feed: const _Feed(ReleaseVersion(1, 0, 0)),
        ),
      );

      expect(find.text('Up to date'), findsOneWidget);
    });

    testWidgets('a long status fits the smallest window', (tester) async {
      await _pump(
        tester,
        size: const Size(640, 480),
        locale: const Locale('pt'),
        updates: _updates(
          _Launcher(LaunchResult.started),
          feed: const _OfflineFeed(),
        ),
      );

      expect(
        find.text('Não foi possível procurar atualizações'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with unsaved work, Cancel keeps the app open', (tester) async {
      final launcher = _Launcher(LaunchResult.started);
      final calls = _recordWindowCalls();
      final controller = await _pump(tester, updates: _updates(launcher));
      _change(controller);
      await tester.pump();

      await tester.tap(find.text('Update to 9.9.9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(launcher.launches, 0);
      expect(calls, isNot(contains('destroy')));
    });

    testWidgets("Don't save opens the updater and closes the app", (
      tester,
    ) async {
      final launcher = _Launcher(LaunchResult.started);
      final calls = _recordWindowCalls();
      final controller = await _pump(tester, updates: _updates(launcher));
      _change(controller);
      await tester.pump();

      await tester.tap(find.text('Update to 9.9.9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Don't save"));
      // the indicator spins until the window is gone
      await tester.pump();
      await tester.pump();

      expect(launcher.launches, 1);
      expect(calls, contains('destroy'));
    });

    testWidgets('a change made while the updater opens is asked about again', (
      tester,
    ) async {
      final opening = Completer<LaunchResult>();
      final launcher = _Launcher(LaunchResult.started, opening: opening);
      final calls = _recordWindowCalls();
      final controller = await _pump(tester, updates: _updates(launcher));
      _change(controller);
      await tester.pump();

      await tester.tap(find.text('Update to 9.9.9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Don't save"));
      await tester.pump();
      _change(controller);
      opening.complete(LaunchResult.started);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Don't save"), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(calls, isNot(contains('destroy')));
    });

    testWidgets('when the updater does not open, the app stays open', (
      tester,
    ) async {
      final launcher = _Launcher(LaunchResult.failed);
      final calls = _recordWindowCalls();
      final controller = await _pump(tester, updates: _updates(launcher));
      _change(controller);
      await tester.pump();

      await tester.tap(find.text('Update to 9.9.9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Don't save"));
      await tester.pumpAndSettle();

      expect(launcher.launches, 1);
      expect(calls, isNot(contains('destroy')));
      expect(find.text("Couldn't open the updater."), findsOneWidget);
      expect(find.text('Update to 9.9.9'), findsOneWidget);
    });
  });
}
