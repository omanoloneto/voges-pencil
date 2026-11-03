import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'image_ops.dart';
import 'paint_controller.dart';
import 'tool_settings.dart';
import 'zoom.dart';

/// The image on a gray desk, scrollable, with the tools working on it.
class CanvasView extends StatefulWidget {
  const CanvasView({
    required this.controller,
    required this.zoom,
    required this.onZoom,
    super.key,
  });

  static const margin = 24.0;

  final PaintController controller;
  final double zoom;
  final ValueChanged<double> onZoom;

  @override
  State<CanvasView> createState() => CanvasViewState();
}

class CanvasViewState extends State<CanvasView> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  late final ui.Image _checker = renderImage(16, 16, (canvas) {
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final gray = Paint()..color = const Color(0xFFDDDDDD);
    canvas
      ..drawRect(const Rect.fromLTWH(0, 0, 8, 8), gray)
      ..drawRect(const Rect.fromLTWH(8, 8, 8, 8), gray);
  });
  Size _viewport = Size.zero;
  int? _pointer;
  double _pinchStart = 1;

  PaintController get controller => widget.controller;

  /// Top left of the visible part of the image, in image pixels.
  Offset get visibleOrigin {
    double origin(ScrollController scroll) => math.max(
      0,
      ((scroll.hasClients ? scroll.offset : 0) - CanvasView.margin) /
          widget.zoom,
    );
    return Offset(origin(_horizontal), origin(_vertical));
  }

  double get fittingZoom => fitZoom(
    _viewport,
    controller.document.width,
    controller.document.height,
    CanvasView.margin,
  );

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    _checker.dispose();
    super.dispose();
  }

  Offset _toImage(Offset local) => local / widget.zoom;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    final secondary = event.buttons & kSecondaryMouseButton != 0;
    if (!secondary && event.buttons & kPrimaryButton == 0) return;
    _pointer = event.pointer;
    controller.pointerDown(_toImage(event.localPosition), secondary: secondary);
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    controller.pointerMove(
      _toImage(event.localPosition),
      straight: HardwareKeyboard.instance.isShiftPressed,
    );
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    controller.pointerUp();
  }

  void _cancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    controller.pointerCancel();
  }

  void _signal(PointerSignalEvent event) {
    final keys = HardwareKeyboard.instance;
    if (event is! PointerScrollEvent ||
        !(keys.isControlPressed || keys.isMetaPressed)) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      final delta = (event as PointerScrollEvent).scrollDelta.dy;
      widget.onZoom(clampZoom(widget.zoom * math.pow(1.002, -delta)));
    });
  }

  MouseCursor get _cursor => switch (controller.settings.tool) {
    PaintTool.select => SystemMouseCursors.basic,
    PaintTool.fill || PaintTool.picker => SystemMouseCursors.click,
    _ => SystemMouseCursors.precise,
  };

  @override
  Widget build(BuildContext context) {
    final desk = Theme.of(context).colorScheme.surfaceContainerHigh;
    return ColoredBox(
      color: desk,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewport = constraints.biggest;
          return Scrollbar(
            controller: _vertical,
            child: Scrollbar(
              controller: _horizontal,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _vertical,
                child: SingleChildScrollView(
                  controller: _horizontal,
                  scrollDirection: Axis.horizontal,
                  child: Listener(
                    onPointerSignal: _signal,
                    onPointerPanZoomStart: (_) => _pinchStart = widget.zoom,
                    onPointerPanZoomUpdate: (event) {
                      if (event.scale != 1) {
                        widget.onZoom(clampZoom(_pinchStart * event.scale));
                      }
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(CanvasView.margin),
                          child: _surface(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _surface() {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final document = controller.document;
        return DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 8)],
          ),
          child: MouseRegion(
            cursor: _cursor,
            onHover: (event) => controller.hover(_toImage(event.localPosition)),
            onExit: (_) => controller.hover(null),
            child: Listener(
              onPointerDown: _down,
              onPointerMove: _move,
              onPointerUp: _up,
              onPointerCancel: _cancel,
              child: CustomPaint(
                size: Size(
                  document.width * widget.zoom,
                  document.height * widget.zoom,
                ),
                painter: _CanvasPainter(controller, widget.zoom, _checker),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter(this.controller, this.zoom, this.checker)
    : super(repaint: controller);

  final PaintController controller;
  final double zoom;
  final ui.Image checker;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ImageShader(
          checker,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.identity().storage,
        ),
    );
    // pixels stay sharp from 100% up, as in every paint program
    final quality = zoom < 1 ? FilterQuality.medium : FilterQuality.none;
    canvas
      ..save()
      ..clipRect(bounds)
      ..scale(zoom)
      ..drawImage(
        controller.document.image,
        Offset.zero,
        Paint()..filterQuality = quality,
      );
    if (controller.floating case final floating?) {
      if (floating.hole case final hole?) {
        canvas.drawRect(hole, Paint()..color = controller.settings.color2);
      }
      canvas.drawImage(
        floating.image,
        floating.topLeft,
        Paint()..filterQuality = quality,
      );
    }
    controller.mark?.paint(canvas);
    canvas.restore();
    if (controller.selection case final selection?) {
      _marquee(
        canvas,
        Rect.fromLTRB(
          selection.left * zoom,
          selection.top * zoom,
          selection.right * zoom,
          selection.bottom * zoom,
        ).deflate(0.5),
      );
    }
  }

  void _marquee(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFFFFFFF),
    );
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1F1F1F);
    const length = 4.0;
    void edge(Offset from, Offset to) {
      final total = (to - from).distance;
      if (total <= 0) return;
      final step = (to - from) / total;
      for (var at = 0.0; at < total; at += length * 2) {
        canvas.drawLine(
          from + step * at,
          from + step * math.min(at + length, total),
          dash,
        );
      }
    }

    edge(rect.topLeft, rect.topRight);
    edge(rect.topRight, rect.bottomRight);
    edge(rect.bottomRight, rect.bottomLeft);
    edge(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) =>
      oldDelegate.zoom != zoom || oldDelegate.checker != checker;
}
