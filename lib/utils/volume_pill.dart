import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VolumeControlPill extends StatelessWidget {
  final Future<void> Function(int) onClick;

  const VolumeControlPill({super.key, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Scale sizes relative to screen
    final pillWidth = screenWidth * 0.12;
    final pillHeight = screenHeight * 0.25;
    final borderRadius = pillWidth * 0.6;
    final iconSize = pillWidth * 0.4;
    final fontSize = pillWidth * 0.32;

    Timer? repeatTimer;

    return Container(
      width: pillWidth,
      height: pillHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top half (vol+)
          Expanded(
            child: GestureDetector(
              onTapDown: (_) {
                repeatTimer = Timer.periodic(
                  const Duration(milliseconds: 300),
                  (_) => onClick(146),
                  // (_) =>   print("click"),
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
                  await onClick(146);
                  // print("object");
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(borderRadius),
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: pillHeight * 0.07),
                      child: Icon(
                        CupertinoIcons.add,
                        color: Colors.black87,
                        size: iconSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Middle label (not clickable)
          Center(
            child: Text(
              "VOL",
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Bottom half (vol-)
          Expanded(
            child: GestureDetector(
              onTapDown: (_) {
                repeatTimer = Timer.periodic(
                  const Duration(milliseconds: 300),
                  (_) => onClick(147),
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
                  await onClick(147);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(borderRadius),
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: pillHeight * 0.07),
                      child: Icon(
                        CupertinoIcons.minus,
                        color: Colors.black87,
                        size: iconSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
