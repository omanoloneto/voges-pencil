import 'package:flutter/painting.dart';

enum PenKind { pencil, brush, eraser }

enum ShapeKind { line, rectangle, ellipse }

/// Something drawn with one drag, painted the same way while it is drawn
/// and when it goes into the image.
sealed class Mark {
  void paint(Canvas canvas);
}

/// Pencil: hard edges. Brush: soft round edges. Eraser: a hard square that
/// paints the second color.
final class PenMark extends Mark {
  PenMark(this.kind, this.color, this.width, Offset start) : points = [start];

  final PenKind kind;
  final Color color;
  final double width;
  final List<Offset> points;

  void add(Offset point) {
    if (point != points.last) points.add(point);
  }

  @override
  void paint(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = kind == PenKind.brush;
    if (points.length == 1) {
      final dot = Rect.fromCenter(
        center: points.single,
        width: width,
        height: width,
      );
      if (kind == PenKind.eraser || width <= 1) {
        canvas.drawRect(dot, paint);
      } else {
        canvas.drawOval(dot, paint);
      }
      return;
    }
    final square = kind == PenKind.eraser;
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = square ? StrokeCap.square : StrokeCap.round
      ..strokeJoin = square ? StrokeJoin.bevel : StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }
}

final class ShapeMark extends Mark {
  ShapeMark(this.kind, this.color, this.width, this.filled, this.start)
    : end = start;

  final ShapeKind kind;
  final Color color;
  final double width;
  final bool filled;
  final Offset start;
  Offset end;

  bool get isEmpty => start == end;

  @override
  void paint(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = filled && kind != ShapeKind.line
          ? PaintingStyle.fill
          : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;
    final box = Rect.fromPoints(start, end);
    switch (kind) {
      case ShapeKind.line:
        canvas.drawLine(start, end, paint);
      case ShapeKind.rectangle:
        canvas.drawRect(box, paint);
      case ShapeKind.ellipse:
        canvas.drawOval(box, paint);
    }
  }
}
