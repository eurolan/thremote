import 'package:flutter/material.dart';
import 'dart:math';

class PieDPad extends StatelessWidget {
  final Future<void> Function(int) onClick;

  const PieDPad({super.key, required this.onClick});

  @override
  Widget build(BuildContext context) {
    double size = 250;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87,
            ),
          ),

          // Diagonal dividers
          CustomPaint(
            size: Size(size, size),
            painter: DiagonalDividerPainter(),
          ),

          // Pie Slices (Triangle Taps)
          _buildTriangle(Direction.up, 189, size),
          _buildTriangle(Direction.down, 190, size),
          _buildTriangle(Direction.right, 171, size),
          _buildTriangle(Direction.left, 191, size),

          // Center OK Button
          GestureDetector(
            onTap: () async => await onClick(172),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade700,
                border: Border.all(color: Colors.grey.shade600, width: 2),
              ),
              alignment: Alignment.center,
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriangle(Direction direction, int code, double size) {
    return ClipPath(
      clipper: PieSegmentClipper(direction),
      child: GestureDetector(
        onTap: () async => await onClick(code),
        child: Container(
          width: size,
          height: size,
          color: Colors.transparent,
          alignment: _alignment(direction),
          child: Icon(_iconData(direction), color: Colors.white70, size: 20),
        ),
      ),
    );
  }

  Alignment _alignment(Direction direction) {
    switch (direction) {
      case Direction.up:
        return const Alignment(0, -0.8);
      case Direction.down:
        return const Alignment(0, 0.8);
      case Direction.left:
        return const Alignment(-0.8, 0);
      case Direction.right:
        return const Alignment(0.8, 0);
    }
  }

  IconData _iconData(Direction direction) {
    switch (direction) {
      case Direction.up:
        return Icons.arrow_drop_up;
      case Direction.down:
        return Icons.arrow_drop_down;
      case Direction.left:
        return Icons.arrow_left;
      case Direction.right:
        return Icons.arrow_right;
    }
  }
}

enum Direction { up, down, left, right }

/// This painter draws the two diagonal lines
class DiagonalDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade800
          ..strokeWidth = 2;

    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Clips triangle pie segments based on direction
class PieSegmentClipper extends CustomClipper<Path> {
  final Direction direction;

  PieSegmentClipper(this.direction);

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final angleOffset = {
      Direction.up: -pi / 4,
      Direction.right: pi / 4,
      Direction.down: 3 * pi / 4,
      Direction.left: 5 * pi / 4,
    };

    final startAngle = angleOffset[direction]!;
    final sweep = pi / 2;

    path.moveTo(center.dx, center.dy);
    for (
      double angle = startAngle;
      angle <= startAngle + sweep;
      angle += 0.01
    ) {
      path.lineTo(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
