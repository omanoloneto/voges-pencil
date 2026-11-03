import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voges_pencil/canvas/image_ops.dart';
import 'package:voges_pencil/canvas/paint_controller.dart';
import 'package:voges_pencil/canvas/paint_document.dart';
import 'package:voges_pencil/canvas/tool_settings.dart';

const _white = 0xFFFFFFFF;
const _black = 0xFF000000;
const _red = 0xFFED1C24;

PaintController _controller({int width = 20, int height = 20}) =>
    PaintController(
      document: PaintDocument(blankImage(width, height, const Color(_white))),
      settings: ToolSettings()..size = 1,
    );

Future<int> _at(PaintController controller, int x, int y) async =>
    (await readPixels(controller.document.image)).colorAt(x, y);

void _drag(PaintController controller, List<Offset> points) {
  controller.pointerDown(points.first);
  for (final point in points.skip(1)) {
    controller.pointerMove(point);
  }
  controller.pointerUp();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the pencil draws hard pixels with color 1', () async {
    final controller = _controller();
    _drag(controller, const [Offset(2.3, 4.6), Offset(9.8, 4.2)]);
    expect(await _at(controller, 2, 4), _black);
    expect(await _at(controller, 6, 4), _black);
    expect(await _at(controller, 9, 4), _black);
    expect(await _at(controller, 6, 5), _white);
    expect(controller.document.dirty, isTrue);
  });

  test(
    'the right button paints color 2, and the eraser uses color 2',
    () async {
      final controller = _controller();
      controller.settings.color2 = const Color(_red);
      controller.pointerDown(const Offset(1.5, 1.5), secondary: true);
      controller.pointerUp();
      expect(await _at(controller, 1, 1), _red);

      controller.settings
        ..color2 = const Color(_white)
        ..tool = PaintTool.eraser;
      _drag(controller, const [Offset(1.5, 1.5), Offset(1.6, 1.5)]);
      expect(await _at(controller, 1, 1), _white);
    },
  );

  test('a click without a drag draws no shape', () async {
    final controller = _controller();
    controller.settings.tool = PaintTool.rectangle;
    controller.pointerDown(const Offset(5, 5));
    controller.pointerUp();
    expect(controller.document.canUndo, isFalse);
  });

  test('the fill paints the closed area and undo takes it back', () async {
    final controller = _controller();
    controller.settings
      ..tool = PaintTool.rectangle
      ..size = 1;
    _drag(controller, const [Offset(4, 4), Offset(14, 14)]);
    controller.settings
      ..tool = PaintTool.fill
      ..color1 = const Color(_red);
    await controller.fillAt(const Offset(9, 9));
    expect(await _at(controller, 9, 9), _red);
    expect(await _at(controller, 1, 1), _white);
    controller.undo();
    expect(await _at(controller, 9, 9), _white);
  });

  test('filling with the same color does not add an undo step', () async {
    final controller = _controller();
    controller.settings.color1 = const Color(_white);
    await controller.fillAt(const Offset(3, 3));
    expect(controller.document.canUndo, isFalse);
  });

  test('the picker takes the color and goes back to the last tool', () async {
    final controller = _controller();
    controller.settings
      ..color1 = const Color(_red)
      ..tool = PaintTool.brush;
    controller.pointerDown(const Offset(5.5, 5.5));
    controller.pointerUp();
    controller.settings
      ..color1 = const Color(_black)
      ..tool = PaintTool.picker;
    await controller.pickAt(const Offset(5.5, 5.5));
    expect(controller.settings.color1.toARGB32(), _red);
    expect(controller.settings.tool, PaintTool.brush);
  });

  test('a moved selection leaves color 2 where it was', () async {
    final controller = _controller();
    controller.settings.tool = PaintTool.pencil;
    _drag(controller, const [Offset(2.5, 2.5), Offset(2.6, 2.5)]);
    controller.settings
      ..tool = PaintTool.select
      ..color2 = const Color(_white);
    _drag(controller, const [Offset(1, 1), Offset(4, 4)]);
    expect(controller.selection, const Rect.fromLTRB(1, 1, 4, 4));

    _drag(controller, const [Offset(2, 2), Offset(12, 12)]);
    expect(controller.floating, isNotNull);
    controller.deselect();
    expect(controller.floating, isNull);
    expect(await _at(controller, 2, 2), _white);
    expect(await _at(controller, 12, 12), _black);
  });

  test('undo while a selection floats only drops the floating piece', () async {
    final controller = _controller();
    controller.selectAll();
    _drag(controller, const [Offset(5, 5), Offset(8, 8)]);
    expect(controller.floating, isNotNull);
    controller.undo();
    expect(controller.floating, isNull);
    expect(controller.document.canUndo, isFalse);
  });

  test('deleting a selection paints it with color 2', () async {
    final controller = _controller();
    controller.settings.color2 = const Color(_red);
    controller.settings.tool = PaintTool.select;
    _drag(controller, const [Offset(2, 2), Offset(6, 6)]);
    controller.deleteSelection();
    expect(await _at(controller, 3, 3), _red);
    expect(await _at(controller, 7, 7), _white);
    expect(controller.hasSelection, isFalse);
  });

  test('pasting a bigger image grows the canvas, and it floats', () async {
    final controller = _controller(width: 10, height: 10);
    controller.paste(
      blankImage(16, 8, const Color(_red)),
      at: const Offset(5, 5),
    );
    expect(controller.document.width, 16);
    expect(controller.document.height, 10);
    expect(controller.floating!.topLeft, const Offset(0, 2));
    controller.deselect();
    expect(await _at(controller, 15, 2), _red);
  });

  test('crop keeps only the selection', () async {
    final controller = _controller();
    controller.settings.tool = PaintTool.select;
    _drag(controller, const [Offset(3, 3), Offset(9, 7)]);
    controller.crop();
    expect(controller.document.width, 6);
    expect(controller.document.height, 4);
  });

  test('turning right moves the top left pixel to the top right', () async {
    final controller = _controller(width: 4, height: 2);
    controller.pointerDown(const Offset(0.5, 0.5));
    controller.pointerUp();
    controller.turn(Turn.right);
    expect(controller.document.width, 2);
    expect(controller.document.height, 4);
    expect(await _at(controller, 1, 0), _black);
    expect(await _at(controller, 0, 0), _white);
  });

  test('a bigger canvas without stretching keeps the drawing size', () async {
    final controller = _controller(width: 4, height: 4);
    controller.settings.color2 = const Color(_red);
    controller.resize(8, 6, stretch: false);
    expect(await _at(controller, 6, 5), _red);
    expect(await _at(controller, 1, 1), _white);
  });
}
