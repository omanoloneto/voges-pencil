import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../painting/flood_fill.dart';
import '../painting/image_formats.dart';
import '../painting/rgba_image.dart';
import 'image_ops.dart';
import 'marks.dart';
import 'paint_document.dart';
import 'tool_settings.dart';

/// A piece of image over the canvas, pasted or lifted from it to be moved.
/// It goes into the image only when it lands.
class FloatingImage {
  FloatingImage(this.image, this.topLeft, {this.hole});

  final ui.Image image;
  Offset topLeft;

  /// Where it was lifted from; it gets the second color when it lands.
  final Rect? hole;

  Rect get bounds =>
      topLeft & Size(image.width.toDouble(), image.height.toDouble());
}

/// What the tools do to the document, in image pixels. The canvas widget
/// only turns pointer events into these calls.
class PaintController extends ChangeNotifier {
  PaintController({required this.document, required this.settings})
    : _tool = settings.tool {
    document.addListener(_onDocument);
    settings.addListener(_onSettings);
  }

  final PaintDocument document;
  final ToolSettings settings;

  /// The pixel under the mouse, for the status bar.
  final cursor = ValueNotifier<(int, int)?>(null);

  PaintTool _tool;
  Mark? _mark;
  Rect? _selection;
  FloatingImage? _floating;
  Offset? _selectionStart;
  Offset? _grab;
  var _filling = false;
  Future<RgbaImage>? _pixels;
  var _pixelsRevision = -1;

  /// The drag being drawn, painted over the image until it is done.
  Mark? get mark => _mark;

  FloatingImage? get floating => _floating;

  Rect? get selection => _floating?.bounds ?? _selection;

  bool get hasSelection => selection != null;

  bool get canUndo => _floating != null || document.canUndo;

  bool get canRedo => _floating == null && document.canRedo;

  Rect get _imageRect =>
      Offset.zero & Size(document.width.toDouble(), document.height.toDouble());

  void pointerDown(Offset point, {bool secondary = false}) {
    final size = settings.size.toDouble();
    switch (settings.tool) {
      case PaintTool.select:
        _selectDown(point);
      case PaintTool.pencil:
        _mark = PenMark(PenKind.pencil, _color(secondary), size, _snap(point));
      case PaintTool.brush:
        _mark = PenMark(PenKind.brush, _color(secondary), size, point);
      case PaintTool.eraser:
        _mark = PenMark(PenKind.eraser, _color(!secondary), size, _snap(point));
      case PaintTool.line || PaintTool.rectangle || PaintTool.ellipse:
        _mark = ShapeMark(
          _shapeOf(settings.tool),
          _color(secondary),
          size,
          settings.filled,
          _snap(point),
        );
      case PaintTool.fill:
        fillAt(point, secondary: secondary).ignore();
      case PaintTool.picker:
        pickAt(point, secondary: secondary).ignore();
    }
    notifyListeners();
  }

  /// [straight] keeps lines at multiples of 45° and makes shapes square.
  void pointerMove(Offset point, {bool straight = false}) {
    hover(point);
    switch (_mark) {
      case final PenMark pen:
        pen.add(pen.kind == PenKind.brush ? point : _snap(point));
      case final ShapeMark shape:
        final end = _snap(point);
        shape.end = straight ? _constrain(shape.start, end, shape.kind) : end;
      case null:
        if (settings.tool == PaintTool.select) _selectMove(point);
    }
    notifyListeners();
  }

  void pointerUp() {
    final mark = _mark;
    _mark = null;
    if (mark is PenMark || (mark is ShapeMark && !mark.isEmpty)) {
      _commitOver((canvas) => mark!.paint(canvas));
    }
    _grab = null;
    if (_selectionStart != null) {
      _selectionStart = null;
      final area = _selection;
      if (area != null && (area.width < 1 || area.height < 1)) {
        _selection = null;
      }
    }
    notifyListeners();
  }

  void pointerCancel() {
    _mark = null;
    _grab = null;
    _selectionStart = null;
    notifyListeners();
  }

  void hover(Offset? point) {
    cursor.value = point == null || !_imageRect.contains(point)
        ? null
        : (point.dx.floor(), point.dy.floor());
  }

  Future<void> fillAt(Offset point, {bool secondary = false}) async {
    final x = point.dx.floor(), y = point.dy.floor();
    if (_filling || !_imageRect.contains(point)) return;
    _filling = true;
    try {
      final revision = document.revision;
      final base = document.image;
      final pixels = await _currentPixels();
      final color = _color(secondary).toARGB32();
      if (pixels.colorAt(x, y) == color) return;
      final layer = await compute(_fillLayer, (pixels, x, y, color));
      if (layer == null || revision != document.revision) return;
      final overlay = await imageFromOpaquePixels(
        layer,
        pixels.width,
        pixels.height,
      );
      if (revision == document.revision && identical(base, document.image)) {
        _commitOver(
          (canvas) => canvas.drawImage(overlay, Offset.zero, Paint()),
        );
      }
      overlay.dispose();
    } finally {
      _filling = false;
    }
  }

  Future<void> pickAt(Offset point, {bool secondary = false}) async {
    if (!_imageRect.contains(point)) return;
    final pixels = await _currentPixels();
    final argb = pixels.colorAt(point.dx.floor(), point.dy.floor());
    final color = argb >>> 24 == 0
        ? const Color(0xFFFFFFFF)
        : Color(argb | 0xFF000000);
    if (secondary) {
      settings.color2 = color;
    } else {
      settings.color1 = color;
    }
    settings.finishPicking();
  }

  void undo() {
    if (_floating case final floating?) {
      _floating = null;
      floating.image.dispose();
      notifyListeners();
      return;
    }
    _selection = null;
    document.undo();
  }

  void redo() {
    if (canRedo) document.redo();
  }

  void newImage(int width, int height) {
    _clearSelection();
    document.replace(blankImage(width, height, const Color(0xFFFFFFFF)));
  }

  void load(
    ui.Image image, {
    required String name,
    String? path,
    SaveFormat format = SaveFormat.png,
  }) {
    _clearSelection();
    document.replace(image, name: name, path: path, format: format);
  }

  void selectAll() {
    settings.tool = PaintTool.select;
    dropFloating();
    _selection = _imageRect;
    notifyListeners();
  }

  /// Lands the floating image and forgets the selection.
  void deselect() {
    dropFloating();
    _selection = null;
    notifyListeners();
  }

  void dropFloating() {
    final floating = _floating;
    if (floating == null) return;
    _floating = null;
    final hole = floating.hole;
    if (hole == null || floating.topLeft != hole.topLeft) {
      _commitOver((canvas) {
        if (hole != null) canvas.drawRect(hole, _background);
        canvas.drawImage(floating.image, floating.topLeft, Paint());
      });
    }
    floating.image.dispose();
    notifyListeners();
  }

  /// PNG of the floating image, the selection, or the whole image.
  Future<Uint8List> copyPng() async {
    if (_floating case final floating?) return encodePng(floating.image);
    final area = _selection?.intersect(_imageRect);
    if (area == null || area.isEmpty) return encodePng(document.image);
    final part = cropImage(document.image, area);
    try {
      return await encodePng(part);
    } finally {
      part.dispose();
    }
  }

  /// The selected area gets the second color.
  void deleteSelection() {
    if (_floating case final floating?) {
      _floating = null;
      floating.image.dispose();
      if (floating.hole case final hole?) {
        _commitOver((canvas) => canvas.drawRect(hole, _background));
      }
      notifyListeners();
      return;
    }
    final area = _selection;
    if (area == null) return;
    _selection = null;
    _commitOver((canvas) => canvas.drawRect(area, _background));
    notifyListeners();
  }

  /// [image] floats at [at], moved in so it fits; a bigger image first
  /// grows the canvas, with the second color in the new room.
  void paste(ui.Image image, {Offset at = Offset.zero}) {
    settings.tool = PaintTool.select;
    dropFloating();
    _selection = null;
    final base = document.image;
    if (image.width > base.width || image.height > base.height) {
      document.commit(
        resizeImage(
          base,
          math.max(base.width, image.width),
          math.max(base.height, image.height),
          stretch: false,
          background: settings.color2,
        ),
      );
    }
    double place(double start, int size, int room) =>
        math.max(0, math.min(start.roundToDouble(), (room - size).toDouble()));
    _floating = FloatingImage(
      image,
      Offset(
        place(at.dx, image.width, document.width),
        place(at.dy, image.height, document.height),
      ),
    );
    notifyListeners();
  }

  void crop() {
    final area = selection?.intersect(_imageRect);
    if (area == null || area.isEmpty) return;
    dropFloating();
    _selection = null;
    document.commit(cropImage(document.image, area));
  }

  void turn(Turn turn) {
    _clearSelection();
    document.commit(turnImage(document.image, turn));
  }

  void resize(int width, int height, {required bool stretch}) {
    _clearSelection();
    document.commit(
      resizeImage(
        document.image,
        width,
        height,
        stretch: stretch,
        background: settings.color2,
      ),
    );
  }

  @override
  void dispose() {
    document.removeListener(_onDocument);
    settings.removeListener(_onSettings);
    _floating?.image.dispose();
    cursor.dispose();
    super.dispose();
  }

  Color _color(bool secondary) => secondary ? settings.color2 : settings.color1;

  Paint get _background => Paint()
    ..color = settings.color2
    ..blendMode = BlendMode.src;

  void _selectDown(Offset point) {
    final floating = _floating;
    if (floating != null && floating.bounds.contains(point)) {
      _grab = point - floating.topLeft;
      return;
    }
    final area = _selection;
    if (area != null && area.contains(point)) {
      _floating = FloatingImage(
        cropImage(document.image, area),
        area.topLeft,
        hole: area,
      );
      _selection = null;
      _grab = point - area.topLeft;
      return;
    }
    dropFloating();
    _selection = null;
    _selectionStart = _clamp(point);
  }

  void _selectMove(Offset point) {
    if (_grab case final grab?) {
      final topLeft = point - grab;
      _floating?.topLeft = Offset(
        topLeft.dx.roundToDouble(),
        topLeft.dy.roundToDouble(),
      );
      return;
    }
    final start = _selectionStart;
    if (start == null) return;
    final end = _clamp(point);
    _selection = Rect.fromLTRB(
      math.min(start.dx, end.dx).floorToDouble(),
      math.min(start.dy, end.dy).floorToDouble(),
      math.max(start.dx, end.dx).ceilToDouble(),
      math.max(start.dy, end.dy).ceilToDouble(),
    );
  }

  Offset _clamp(Offset point) => Offset(
    point.dx.clamp(0, document.width.toDouble()),
    point.dy.clamp(0, document.height.toDouble()),
  );

  /// Hard edges land on whole pixels: odd widths on pixel centers, even
  /// widths on pixel corners.
  Offset _snap(Offset point) {
    final odd = settings.size.isOdd;
    double snap(double value) =>
        odd ? value.floorToDouble() + 0.5 : value.roundToDouble();
    return Offset(snap(point.dx), snap(point.dy));
  }

  static ShapeKind _shapeOf(PaintTool tool) => switch (tool) {
    PaintTool.line => ShapeKind.line,
    PaintTool.rectangle => ShapeKind.rectangle,
    _ => ShapeKind.ellipse,
  };

  static Offset _constrain(Offset start, Offset end, ShapeKind kind) {
    final delta = end - start;
    if (kind == ShapeKind.line) {
      const step = math.pi / 4;
      final angle = (delta.direction / step).round() * step;
      return start + Offset.fromDirection(angle, delta.distance);
    }
    final side = math.max(delta.dx.abs(), delta.dy.abs());
    return start +
        Offset(delta.dx < 0 ? -side : side, delta.dy < 0 ? -side : side);
  }

  /// One undo step: the image with [draw] painted over it.
  void _commitOver(void Function(Canvas canvas) draw) {
    final base = document.image;
    document.commit(
      renderImage(base.width, base.height, (canvas) {
        canvas.drawImage(base, Offset.zero, Paint()..blendMode = BlendMode.src);
        draw(canvas);
      }),
    );
  }

  Future<RgbaImage> _currentPixels() {
    if (_pixels == null || _pixelsRevision != document.revision) {
      _pixelsRevision = document.revision;
      _pixels = readPixels(document.image);
    }
    return _pixels!;
  }

  void _clearSelection() {
    _floating?.image.dispose();
    _floating = null;
    _selection = null;
    _mark = null;
  }

  void _onDocument() {
    final area = _selection;
    if (area != null &&
        !_imageRect.contains(area.bottomRight - const Offset(1, 1))) {
      _selection = null;
    }
    notifyListeners();
  }

  void _onSettings() {
    if (settings.tool != _tool) {
      if (_tool == PaintTool.select) {
        dropFloating();
        _selection = null;
      }
      _tool = settings.tool;
      _mark = null;
    }
    notifyListeners();
  }
}

Uint8List? _fillLayer((RgbaImage, int, int, int) request) {
  final (image, x, y, color) = request;
  return fillLayer(image, x, y, color);
}
