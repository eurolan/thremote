import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';

class PieDPad extends StatefulWidget {
  final Future<void> Function(int) onClick;

  const PieDPad({super.key, required this.onClick});

  @override
  State<PieDPad> createState() => _PieDPadState();
}

class _PieDPadState extends State<PieDPad> {
  Timer? repeatTimer;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    final dpadSize = screenWidth * 0.55;
    final okButtonSize = dpadSize * 0.35;
    final iconSize = dpadSize * 0.09;

    return SizedBox(
      width: dpadSize,
      height: dpadSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: dpadSize,
            height: dpadSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),

          // Diagonal dividers
          ClipOval(
            child: CustomPaint(
              size: Size(dpadSize, dpadSize),
              painter: DiagonalDividerPainter(),
            ),
          ),

          // Pie slices
          _buildTriangle(Direction.right, 171, dpadSize, iconSize),
          _buildTriangle(Direction.left, 191, dpadSize, iconSize),
          _buildTriangle(Direction.down, 190, dpadSize, iconSize),
          _buildTriangle(Direction.up, 189, dpadSize, iconSize),

          // Center OK button
          GestureDetector(
            onTapDown: (_) {
              repeatTimer = Timer.periodic(
                const Duration(milliseconds: 300),
                (_) => widget.onClick(172),
              );
            },
            onTapUp: (_) {
              repeatTimer?.cancel();
              repeatTimer = null;
            },
            onTapCancel: () {
              repeatTimer?.cancel();
              repeatTimer = null;
            },
            child: ElevatedButton(
              onPressed: () async {
                await widget.onClick(172);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: const CircleBorder(),
                side: const BorderSide(
                  color: Color.fromRGBO(192, 24, 81, 1),
                  width: 3,
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
                fixedSize: Size(okButtonSize, okButtonSize),
              ),
              child: Text(
                "OK",
                style: TextStyle(
                  fontSize: okButtonSize * 0.25,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriangle(
    Direction direction,
    int code,
    double size,
    double iconSize,
  ) {
    return ClipPath(
      clipper: PieSegmentClipper(direction),
      child: SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
          onTapDown: (_) {
            repeatTimer = Timer.periodic(
              const Duration(milliseconds: 300),
              (_) => widget.onClick(code),
            );
          },
          onTapUp: (_) {
            repeatTimer?.cancel();
            repeatTimer = null;
          },
          onTapCancel: () {
            repeatTimer?.cancel();
            repeatTimer = null;
          },
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              alignment: _alignment(direction),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () async {
              await widget.onClick(code);
            },
            child: Icon(
              _iconData(direction),
              color: Colors.black,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
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
