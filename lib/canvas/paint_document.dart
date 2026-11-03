import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../painting/image_formats.dart';

/// The image being edited, where it came from, and its undo history.
class PaintDocument extends ChangeNotifier {
  PaintDocument(ui.Image image, {this.historyBytes = defaultHistoryBytes})
    : _image = image,
      _saved = image;

  /// Memory the undo steps may take; the oldest go first, but one is kept.
  static const defaultHistoryBytes = 768 << 20;

  final int historyBytes;

  ui.Image _image;
  ui.Image? _saved;
  final _undo = <ui.Image>[];
  final _redo = <ui.Image>[];

  /// File name, or null for a new image.
  String? name;

  /// Where Save writes; null until saved or for files that came as a copy.
  String? path;

  SaveFormat format = SaveFormat.png;

  /// Grows with every change to the pixels, so slow work started on an
  /// older image can tell it is stale.
  int revision = 0;

  ui.Image get image => _image;
  int get width => _image.width;
  int get height => _image.height;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Undoing back to the saved pixels makes the image clean again.
  bool get dirty => !identical(_image, _saved);

  void commit(ui.Image next) {
    _undo.add(_image);
    _image = next;
    _release(_redo);
    _trim();
    _changed();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_image);
    _image = _undo.removeLast();
    _changed();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_image);
    _image = _redo.removeLast();
    _changed();
  }

  /// A new or opened image: the history of the old one goes away.
  void replace(
    ui.Image image, {
    String? name,
    String? path,
    SaveFormat format = SaveFormat.png,
  }) {
    _release(_undo);
    _release(_redo);
    _image.dispose();
    _image = image;
    _saved = image;
    this.name = name;
    this.path = path;
    this.format = format;
    _changed();
  }

  void markSaved({required String name, String? path, SaveFormat? format}) {
    _saved = _image;
    this.name = name;
    this.path = path;
    if (format != null) this.format = format;
    notifyListeners();
  }

  @override
  void dispose() {
    _release(_undo);
    _release(_redo);
    _image.dispose();
    super.dispose();
  }

  void _changed() {
    revision++;
    notifyListeners();
  }

  void _trim() {
    int bytes() => _undo.fold(0, (sum, image) => sum + _bytesOf(image));
    while (_undo.length > 1 && bytes() > historyBytes) {
      _undo.removeAt(0).dispose();
    }
  }

  void _release(List<ui.Image> images) {
    for (final image in images) {
      if (!identical(image, _image)) image.dispose();
    }
    images.clear();
  }

  static int _bytesOf(ui.Image image) => image.width * image.height * 4;
}
