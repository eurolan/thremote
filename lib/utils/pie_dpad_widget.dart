import 'package:flutter/material.dart';
import 'dart:math';

class PieDPad extends StatelessWidget {
  final Future<void> Function(int) onClick;

  const PieDPad({super.key, required this.onClick});

  @override
  Widget build(BuildContext context) {
    double size = 230;

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
              color: Colors.white,
            ),
          ),

          // Diagonal dividers
          ClipOval(
            child: CustomPaint(
              size: Size(size, size),
              painter: DiagonalDividerPainter(),
            ),
          ),

          // Pie Slices (Triangle Taps)
          _buildTriangle(Direction.right, 171, size),
          _buildTriangle(Direction.left, 191, size),
          _buildTriangle(Direction.down, 190, size),
          _buildTriangle(Direction.up, 189, size),

          // Center OK Button
          GestureDetector(
            onTap: () async => await onClick(172),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color.fromRGBO(192, 24, 81, 1),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 20, color: Colors.black54),
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
          child: Icon(_iconData(direction), color: Colors.black, size: 20),
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
          ..color = Colors.black12
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

    // Fixed angle mappings to align with visual directions
    final angleOffset = {
      Direction.up: -3 * pi / 4, // Top segment
      Direction.right: -pi / 4, // Right segment
      Direction.down: pi / 4, // Bottom segment
      Direction.left: 3 * pi / 4, // Left segment
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
