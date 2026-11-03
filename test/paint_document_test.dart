import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voges_pencil/canvas/image_ops.dart';
import 'package:voges_pencil/canvas/paint_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('undo goes back to the saved image, which is clean again', () {
    final document = PaintDocument(blankImage(4, 4, const Color(0xFFFFFFFF)));
    expect(document.dirty, isFalse);
    document.commit(blankImage(4, 4, const Color(0xFF000000)));
    expect(document.dirty, isTrue);
    expect(document.canUndo, isTrue);
    document.undo();
    expect(document.dirty, isFalse);
    expect(document.canRedo, isTrue);
    document.redo();
    expect(document.dirty, isTrue);
  });

  test('a new change drops what could be redone', () {
    final document = PaintDocument(blankImage(4, 4, const Color(0xFFFFFFFF)));
    document
      ..commit(blankImage(4, 4, const Color(0xFF000000)))
      ..undo()
      ..commit(blankImage(4, 4, const Color(0xFFFF0000)));
    expect(document.canRedo, isFalse);
  });

  test('old steps go once the history is over its memory, but one stays', () {
    // each 4×4 step takes 64 bytes
    final document = PaintDocument(
      blankImage(4, 4, const Color(0xFFFFFFFF)),
      historyBytes: 130,
    );
    for (var i = 0; i < 5; i++) {
      document.commit(blankImage(4, 4, const Color(0xFF000000)));
    }
    var steps = 0;
    while (document.canUndo) {
      document.undo();
      steps++;
    }
    expect(steps, 2);

    final tight = PaintDocument(
      blankImage(4, 4, const Color(0xFFFFFFFF)),
      historyBytes: 0,
    )..commit(blankImage(4, 4, const Color(0xFF000000)));
    expect(tight.canUndo, isTrue);
  });

  test('saving marks the current image as clean', () {
    final document = PaintDocument(blankImage(4, 4, const Color(0xFFFFFFFF)))
      ..commit(blankImage(4, 4, const Color(0xFF000000)))
      ..markSaved(name: 'a.png', path: '/tmp/a.png');
    expect(document.dirty, isFalse);
    expect(document.name, 'a.png');
    document.undo();
    expect(document.dirty, isTrue);
  });
}
