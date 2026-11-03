import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voges_pencil/app.dart';
import 'package:voges_pencil/canvas/image_ops.dart';
import 'package:voges_pencil/canvas/paint_controller.dart';
import 'package:voges_pencil/canvas/paint_document.dart';
import 'package:voges_pencil/canvas/tool_settings.dart';
import 'package:voges_pencil/files/image_clipboard.dart';
import 'package:voges_pencil/files/image_files.dart';
import 'package:voges_pencil/files/system_open.dart';
import 'package:voges_pencil/l10n/app_language.dart';

Future<PaintController> _pump(WidgetTester tester, {Locale? locale}) async {
  tester.view.physicalSize = const Size(1400, 900);
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
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

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
}
