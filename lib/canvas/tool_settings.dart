import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

enum PaintTool {
  select,
  pencil,
  brush,
  eraser,
  fill,
  picker,
  line,
  rectangle,
  ellipse;

  bool get isShape => this == line || this == rectangle || this == ellipse;

  bool get usesSize => !{select, fill, picker}.contains(this);
}

const brushSizes = [1, 2, 3, 5, 8, 12, 16, 24, 32, 48];

/// Two rows, dark on top and light below.
const paletteColors = [
  Color(0xFF000000),
  Color(0xFF7F7F7F),
  Color(0xFF880015),
  Color(0xFFED1C24),
  Color(0xFFFF7F27),
  Color(0xFFFFF200),
  Color(0xFF22B14C),
  Color(0xFF00A2E8),
  Color(0xFF3F48CC),
  Color(0xFFA349A4),
  Color(0xFFFFFFFF),
  Color(0xFFC3C3C3),
  Color(0xFFB97A57),
  Color(0xFFFFAEC9),
  Color(0xFFFFC90E),
  Color(0xFFEFE4B0),
  Color(0xFFB5E61D),
  Color(0xFF99D9EA),
  Color(0xFF7092BE),
  Color(0xFFC8BFE7),
];

/// The chosen tool, size and colors. Colors are always opaque: the fill
/// and the eraser rely on it.
class ToolSettings extends ChangeNotifier {
  PaintTool _tool = PaintTool.pencil;
  PaintTool _beforePicker = PaintTool.pencil;
  int _size = 3;
  Color _color1 = paletteColors.first;
  Color _color2 = const Color(0xFFFFFFFF);
  bool _filled = false;

  PaintTool get tool => _tool;
  int get size => _size;
  Color get color1 => _color1;
  Color get color2 => _color2;

  /// Shapes are filled with their color instead of only outlined.
  bool get filled => _filled;

  set tool(PaintTool value) {
    if (value == _tool) return;
    if (value == PaintTool.picker) _beforePicker = _tool;
    _tool = value;
    notifyListeners();
  }

  set size(int value) {
    if (value == _size) return;
    _size = value;
    notifyListeners();
  }

  set color1(Color value) {
    _color1 = value.withAlpha(255);
    notifyListeners();
  }

  set color2(Color value) {
    _color2 = value.withAlpha(255);
    notifyListeners();
  }

  set filled(bool value) {
    if (value == _filled) return;
    _filled = value;
    notifyListeners();
  }

  void swapColors() {
    final first = _color1;
    _color1 = _color2;
    _color2 = first;
    notifyListeners();
  }

  /// After picking a color the previous tool comes back, as in classic paint
  /// programs.
  void finishPicking() => tool = _beforePicker;
}
