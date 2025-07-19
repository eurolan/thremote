import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChannelControlPill extends StatelessWidget {
  final Future<void> Function(int) onClick;

  const ChannelControlPill({super.key, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          // Top half (CH+)
          Expanded(
            child: ElevatedButton(
              onPressed: () async => await onClick(188),
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: const Column(
                children: [
                  SizedBox(height: 16),
                  Icon(
                    CupertinoIcons.chevron_up,
                    color: Colors.black87,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Middle label (not clickable)
          Center(
            child: Text(
              "CH",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Bottom half (CH-)
          Expanded(
            child: ElevatedButton(
              onPressed: () async => await onClick(145),
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    CupertinoIcons.chevron_down,
                    color: Colors.black87,
                    size: 20,
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
