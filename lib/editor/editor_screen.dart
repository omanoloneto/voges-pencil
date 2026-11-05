// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voges_updater/voges_updater.dart'
    show LaunchResult, UpdateCheck, UpdateStatusChip, UpdaterLocalizations;
import 'package:window_manager/window_manager.dart';

import '../canvas/canvas_view.dart';
import '../canvas/image_ops.dart';
import '../canvas/paint_controller.dart';
import '../canvas/zoom.dart';
import '../files/image_clipboard.dart';
import '../files/image_files.dart';
import '../files/system_open.dart';
import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../painting/image_formats.dart';
import '../painting/rgba_image.dart';
import '../shell/platform.dart';
import '../shell/ribbon_style.dart';
import '../shell/title_bar.dart';
import '../shell/window_buttons.dart';
import 'color_dialog.dart';
import 'dialogs.dart';
import 'file_panel.dart';
import 'ribbon.dart';
import 'status_bar.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    required this.controller,
    required this.files,
    required this.clipboard,
    required this.systemOpen,
    required this.language,
    required this.launchArguments,
    this.windowButtons = WindowButtonsLayout.right,
    this.updates,
    super.key,
  });

  final PaintController controller;
  final ImageFiles files;
  final ImageClipboard clipboard;
  final SystemOpen systemOpen;
  final AppLanguage language;
  final List<String> launchArguments;
  final WindowButtonsLayout windowButtons;

  /// Null off the desktop.
  final UpdateCheck? updates;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with WindowListener {
  final _focus = FocusNode(debugLabel: 'canvas');
  final _canvas = GlobalKey<CanvasViewState>();
  late final AppLifecycleListener _lifecycle;
  var _zoom = 1.0;
  var _closing = false;
  var _maximized = false;
  var _fullScreen = false;
  String? _title;

  PaintController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.document.addListener(_updateTitle);
    _lifecycle = AppLifecycleListener(onExitRequested: _onExitRequested);
    if (isDesktopPlatform) windowManager.addListener(this);
    widget.systemOpen.listen(_openFromSystem);
    _fitAfterLoad();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _updateTitle();
      if (widget.updates case final updates?) {
        updates.check().ignore();
        updates.cleanUp().ignore();
      }
      final pending = await widget.systemOpen.pending(widget.launchArguments);
      if (pending.isNotEmpty) _load(pending.first);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;
    widget.files.titles = FileDialogTitles(
      open: l10n.openImageTitle,
      save: l10n.saveImageTitle,
    );
    _updateTitle();
  }

  @override
  void dispose() {
    controller.document.removeListener(_updateTitle);
    _lifecycle.dispose();
    if (isDesktopPlatform) windowManager.removeListener(this);
    _focus.dispose();
    super.dispose();
  }

  String get _name => controller.document.name ?? context.l10n.untitled;

  void _updateTitle() {
    if (!mounted) return;
    final dirty = controller.document.dirty;
    final title = '${dirty ? '• ' : ''}$_name — Voges Pencil';
    if (title == _title) return;
    _title = title;
    if (isDesktopPlatform) windowManager.setTitle(title).ignore();
  }

  Future<ui.AppExitResponse> _onExitRequested() async {
    if (_closing || await _confirmDiscard()) return ui.AppExitResponse.exit;
    return ui.AppExitResponse.cancel;
  }

  @override
  Future<void> onWindowClose() async {
    if (_closing || await _confirmDiscard()) {
      _closing = true;
      await windowManager.destroy();
    }
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  void onWindowEnterFullScreen() => setState(() => _fullScreen = true);

  @override
  void onWindowLeaveFullScreen() => setState(() => _fullScreen = false);

  /// The app closes for the updater to replace it, so unsaved work is
  /// handled first, exactly as when closing the window.
  Future<void> _startUpdate() async {
    final updates = widget.updates;
    if (updates == null || !await _confirmDiscard()) return;
    final revision = controller.document.revision;
    if (await updates.startUpdater() == LaunchResult.started) {
      // Windows copies the app for the updater first, and the image may
      // change meanwhile; if the user keeps it open, the updater waits
      if (!mounted ||
          (controller.document.revision != revision &&
              !await _confirmDiscard())) {
        return;
      }
      _closing = true;
      await windowManager.destroy();
      return;
    }
    if (!mounted) return;
    final l10n = UpdaterLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.updateLaunchFailed),
        action: SnackBarAction(
          label: l10n.updateDownloadPage,
          onPressed: () => updates.openDownloadPage().ignore(),
        ),
      ),
    );
  }

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmDiscard() async {
    if (!controller.document.dirty) return true;
    switch (await askToSave(context, _name)) {
      case UnsavedChoice.save:
        return _save();
      case UnsavedChoice.discard:
        return true;
      case UnsavedChoice.cancel:
        return false;
    }
  }

  Future<void> _newImage() async {
    if (!await _confirmDiscard() || !mounted) return;
    final document = controller.document;
    final size = await askNewImageSize(
      context,
      Size(document.width.toDouble(), document.height.toDouble()),
    );
    if (size == null) return;
    controller.newImage(size.width, size.height);
    _fitAfterLoad();
  }

  Future<void> _open() async {
    if (!await _confirmDiscard()) return;
    final OpenedFile? file;
    try {
      file = await widget.files.pick();
    } catch (_) {
      if (mounted) _tell(context.l10n.openFailed);
      return;
    }
    if (file != null) await _load(file);
  }

  Future<void> _openFromSystem(OpenedFile file) async {
    if (await _confirmDiscard()) await _load(file);
  }

  Future<void> _load(OpenedFile file) async {
    final ui.Image image;
    try {
      image = await decodeImageBytes(file.bytes);
    } catch (_) {
      if (mounted) _tell(context.l10n.openFailed);
      return;
    }
    if (!mounted) return image.dispose();
    if (image.width > maxImageSide || image.height > maxImageSide) {
      image.dispose();
      _tell(context.l10n.imageTooLarge(maxImageSide));
      return;
    }
    final format = SaveFormat.of(file.name);
    controller.load(
      image,
      name: file.name,
      // a GIF or WebP is saved as a new PNG, never over the original
      path: format == null ? null : file.path,
      format: format ?? SaveFormat.png,
    );
    _fitAfterLoad();
  }

  /// Big images open whole; small ones at 100%.
  void _fitAfterLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fitting = _canvas.currentState?.fittingZoom ?? 1;
      _setZoom(math.min(1.0, fitting));
    });
  }

  Future<bool> _save() {
    final document = controller.document;
    final path = document.path;
    return path == null
        ? _saveAs(document.format)
        : _write(path, document.format);
  }

  Future<bool> _saveAs(SaveFormat format) async {
    final name = _name;
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final String? path;
    try {
      path = await widget.files.chooseSaveLocation(
        '$base.${format.extension}',
        format,
      );
    } catch (_) {
      if (mounted) _tell(context.l10n.saveFailed);
      return false;
    }
    if (path == null) return false;
    return _write(path, format);
  }

  Future<bool> _write(String path, SaveFormat format) async {
    controller.dropFloating();
    final l10n = context.l10n;
    try {
      final image = controller.document.image;
      var flattened = false;
      final Uint8List bytes;
      if (format.keepsTransparency) {
        bytes = await encodePng(image);
      } else {
        final pixels = await readPixels(image);
        (bytes, flattened) = await compute(_encodeOpaque, (pixels, format));
      }
      await widget.files.write(path, bytes);
      controller.document.markSaved(
        name: path.split(RegExp(r'[/\\]')).last,
        path: path,
        format: format,
      );
      if (flattened) _tell(l10n.flattenedWarning(format.label));
      return true;
    } catch (_) {
      _tell(l10n.saveFailed);
      return false;
    }
  }

  Future<void> _copy() async {
    final l10n = context.l10n;
    try {
      await widget.clipboard.write(await controller.copyPng());
    } catch (_) {
      _tell(l10n.copyFailed);
    }
  }

  Future<void> _cut() async {
    if (!controller.hasSelection) return;
    await _copy();
    controller.deleteSelection();
  }

  Future<void> _paste() async {
    final l10n = context.l10n;
    final bytes = await widget.clipboard.read().catchError((_) => null);
    ui.Image? image;
    if (bytes != null) {
      image = await decodeImageBytes(
        bytes,
      ).then<ui.Image?>((image) => image, onError: (_) => null);
    }
    if (image == null) return _tell(l10n.nothingToPaste);
    if (image.width > maxImageSide || image.height > maxImageSide) {
      image.dispose();
      return _tell(l10n.imageTooLarge(maxImageSide));
    }
    controller.paste(
      image,
      at: _canvas.currentState?.visibleOrigin ?? Offset.zero,
    );
  }

  Future<void> _resize() async {
    final document = controller.document;
    final size = await askResize(
      context,
      Size(document.width.toDouble(), document.height.toDouble()),
    );
    if (size != null) {
      controller.resize(size.width, size.height, stretch: size.stretch);
    }
  }

  Future<void> _editColor(bool second) async {
    final settings = controller.settings;
    final color = await askColor(
      context,
      second ? settings.color2 : settings.color1,
    );
    if (color == null) return;
    if (second) {
      settings.color2 = color;
    } else {
      settings.color1 = color;
    }
  }

  void _setZoom(double zoom) => setState(() => _zoom = clampZoom(zoom));

  void _stepZoom(int direction) {
    if (nextZoom(_zoom, direction) case final zoom?) _setZoom(zoom);
  }

  void _fit() {
    if (_canvas.currentState case final canvas?) _setZoom(canvas.fittingZoom);
  }

  void _showFilePanel() => showFilePanel(
    context,
    name: _name,
    language: widget.language,
    actions: FilePanelActions(
      newImage: _newImage,
      open: _open,
      save: _save,
      saveAs: _saveAs,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        shortcut(LogicalKeyboardKey.keyN): _newImage,
        shortcut(LogicalKeyboardKey.keyO): _open,
        shortcut(LogicalKeyboardKey.keyS): _save,
        shortcut(LogicalKeyboardKey.keyS, shift: true): () =>
            _saveAs(controller.document.format),
        shortcut(LogicalKeyboardKey.keyZ): controller.undo,
        shortcut(LogicalKeyboardKey.keyZ, shift: true): controller.redo,
        shortcut(LogicalKeyboardKey.keyY): controller.redo,
        shortcut(LogicalKeyboardKey.keyC): _copy,
        shortcut(LogicalKeyboardKey.keyX): _cut,
        shortcut(LogicalKeyboardKey.keyV): _paste,
        shortcut(LogicalKeyboardKey.keyA): controller.selectAll,
        shortcut(LogicalKeyboardKey.equal): () => _stepZoom(1),
        shortcut(LogicalKeyboardKey.minus): () => _stepZoom(-1),
        shortcut(LogicalKeyboardKey.digit0): () => _setZoom(1),
        const SingleActivator(LogicalKeyboardKey.delete):
            controller.deleteSelection,
        const SingleActivator(LogicalKeyboardKey.backspace):
            controller.deleteSelection,
        const SingleActivator(LogicalKeyboardKey.escape): controller.deselect,
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: _resizable(
          Scaffold(
            body: Column(
              children: [
                ColoredBox(
                  color: RibbonColors.background,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        ListenableBuilder(
                          listenable: controller,
                          builder: (context, _) => AppTitleBar(
                            name: _name,
                            dirty: controller.document.dirty,
                            onFile: _showFilePanel,
                            isMaximized: _maximized,
                            isFullScreen: _fullScreen,
                            windowButtons: widget.windowButtons,
                            actions: QuickActions(
                              undo: controller.canUndo ? controller.undo : null,
                              redo: controller.canRedo ? controller.redo : null,
                              copy: _copy,
                              cut: controller.hasSelection ? _cut : null,
                              paste: _paste,
                            ),
                          ),
                        ),
                        Ribbon(
                          controller: controller,
                          actions: RibbonActions(
                            copy: _copy,
                            cut: _cut,
                            paste: _paste,
                            resize: _resize,
                            editColor: _editColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _focus.requestFocus(),
                    child: CanvasView(
                      key: _canvas,
                      controller: controller,
                      zoom: _zoom,
                      onZoom: _setZoom,
                    ),
                  ),
                ),
                StatusBar(
                  controller: controller,
                  zoom: _zoom,
                  onZoom: _setZoom,
                  onFit: _fit,
                  trailing: switch (widget.updates) {
                    final updates? => UpdateStatusChip(
                      check: updates,
                      onUpdate: _startUpdate,
                    ),
                    null => null,
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Without the system title bar the window needs resize edges: on Windows
  /// only the top one is missing; on Linux, with no frame, all of them are.
  Widget _resizable(Widget child) {
    if (!isDesktopPlatform || defaultTargetPlatform == TargetPlatform.macOS) {
      return child;
    }
    return DragToResizeArea(
      enableResizeEdges: _maximized || _fullScreen
          ? const []
          : defaultTargetPlatform == TargetPlatform.windows
          ? const [ResizeEdge.topLeft, ResizeEdge.top, ResizeEdge.topRight]
          : null,
      child: child,
    );
  }
}

(Uint8List, bool) _encodeOpaque((RgbaImage, SaveFormat) request) {
  final (image, format) = request;
  return (encodeOpaque(image, format), image.hasTransparency);
}
