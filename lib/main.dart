import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'canvas/image_ops.dart';
import 'canvas/paint_controller.dart';
import 'canvas/paint_document.dart';
import 'canvas/tool_settings.dart';
import 'files/image_clipboard.dart';
import 'files/image_files.dart';
import 'files/system_open.dart';
import 'l10n/app_language.dart';
import 'shell/platform.dart';
import 'shell/title_bar.dart';
import 'shell/window_buttons.dart';

/// Size of the image the app starts with.
const _startWidth = 1280, _startHeight = 720;

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktopPlatform) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'Voges Pencil',
        size: Size(1280, 860),
        minimumSize: Size(640, 480),
        center: true,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: true,
      ),
      () async {
        await placeNativeWindowButtons(titleBarHeight);
        await windowManager.setPreventClose(true);
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  final language = AppLanguage();
  await language.load();
  final files = ImageFiles();
  final controller = PaintController(
    document: PaintDocument(
      blankImage(_startWidth, _startHeight, const Color(0xFFFFFFFF)),
    ),
    settings: ToolSettings(),
  );

  runApp(
    VogesPencilApp(
      controller: controller,
      files: files,
      clipboard: ImageClipboard(),
      systemOpen: SystemOpen(files),
      language: language,
      launchArguments: arguments,
      windowButtons: await WindowButtonsLayout.forPlatform(),
    ),
  );
}
