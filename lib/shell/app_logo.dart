import 'package:flutter/material.dart';

/// The icon's colors, from light amber to dark.
const logoShades = [
  Color(0xFFF9CC6A),
  Color(0xFFF0A93D),
  Color(0xFFE28F26),
  Color(0xFFCC7718),
  Color(0xFFA85A0F),
];

/// Radius of each paint arc around the bottom right corner, as a fraction of
/// the icon's side; the same as in `assets/icon`.
const _arcRadii = [1.5, 1.12, 0.84, 0.56, 0.28];

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 24, this.outlined = false, super.key});

  final double size;

  /// Light outline so the icon does not vanish against the ribbon.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: const _ArcsPainter(),
          child: Center(
            child: Text(
              'P',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.64,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: 'Voges Pencil',
      child: outlined
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.24),
                border: Border.all(color: const Color(0xB3FFFFFF)),
              ),
              child: logo,
            )
          : logo,
    );
  }
}

class _ArcsPainter extends CustomPainter {
  const _ArcsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final corner = Offset(size.width, size.height);
    for (var i = 0; i < _arcRadii.length; i++) {
      canvas.drawCircle(
        corner,
        size.width * _arcRadii[i],
        Paint()..color = logoShades[i],
      );
    }
  }

  @override
  bool shouldRepaint(_ArcsPainter oldDelegate) => false;
}
