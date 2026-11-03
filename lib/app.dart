import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'canvas/paint_controller.dart';
import 'editor/editor_screen.dart';
import 'files/image_clipboard.dart';
import 'files/image_files.dart';
import 'files/system_open.dart';
import 'l10n/app_language.dart';
import 'l10n/l10n.dart';
import 'shell/window_buttons.dart';

const brandColor = Color(0xFFE28F26);

class VogesPencilApp extends StatelessWidget {
  const VogesPencilApp({
    required this.controller,
    required this.files,
    required this.clipboard,
    required this.systemOpen,
    required this.language,
    required this.launchArguments,
    this.windowButtons = WindowButtonsLayout.right,
    super.key,
  });

  final PaintController controller;
  final ImageFiles files;
  final ImageClipboard clipboard;
  final SystemOpen systemOpen;
  final AppLanguage language;
  final List<String> launchArguments;
  final WindowButtonsLayout windowButtons;

  ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: brightness,
    ),
    visualDensity: VisualDensity.standard,
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 400),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: language,
      builder: (context, _) => MaterialApp(
        title: 'Voges Pencil',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        locale: language.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: EditorScreen(
          controller: controller,
          files: files,
          clipboard: clipboard,
          systemOpen: systemOpen,
          language: language,
          launchArguments: launchArguments,
          windowButtons: windowButtons,
        ),
      ),
    );
  }
}
