import 'dart:math';

import 'package:flutter/material.dart';
import 'package:remote/models/device_model.dart';
import 'package:remote/utils/pie_dpad_widget.dart';
import 'package:remote/utils/stb_service.dart';

class RemoteControlScreen extends StatefulWidget {
  final DeviceModel deviceModel;

  const RemoteControlScreen({super.key, required this.deviceModel});

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  final remote = STBRemoteService();

  Future<void> sendSTBKey(int code) async {
    await remote.sendKey(
      widget.deviceModel.ipAddress,
      widget.deviceModel.pairingCode!,
      code,
    );
  }

  Widget _buildButton(int number) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: () async {
          await sendSTBKey(128 + number);
        },
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black54,
            // fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildStyledDPad() {
    return Container(
      width: 250,
      height: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // UP
          // Positioned(
          //   top: 20,
          //   child: IconButton(
          //     icon: const Icon(
          //       Icons.arrow_drop_up,
          //       size: 24,
          //       color: Colors.black87,
          //     ),
          //     onPressed: () async => await sendSTBKey(189),
          //   ),
          // ),
          Positioned(
            top: 20,
            child: ElevatedButton(
              onPressed: () async => await sendSTBKey(189),
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16), // Increases touch area
                backgroundColor: Colors.white, // Match D-pad color
                elevation: 2,
                shadowColor: Colors.black26,
              ),
              child: const Icon(
                Icons.arrow_drop_up,
                size: 24,
                color: Colors.black87,
              ),
            ),
          ),
          // DOWN
          Positioned(
            bottom: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_drop_down,
                size: 24,
                color: Colors.black87,
              ),
              onPressed: () async => await sendSTBKey(190),
            ),
          ),

          // LEFT
          Positioned(
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_left,
                size: 24,
                color: Colors.black87,
              ),
              onPressed: () async => await sendSTBKey(191),
            ),
          ),

          // RIGHT
          Positioned(
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_right,
                size: 24,
                color: Colors.black87,
              ),
              onPressed: () async => await sendSTBKey(171),
            ),
          ),

          // Center OK with border
          GestureDetector(
            onTap: () async => await sendSTBKey(172),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pink.shade700, width: 3),
              ),
              alignment: Alignment.center,
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    remote.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: Text(
                        widget.deviceModel.deviceName,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    Positioned(
                      left: 0,
                      child: InkWell(
                        onTap: () async {
                          await sendSTBKey(140);
                        },

                        child: Icon(
                          size: 28,
                          Icons.power_settings_new,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(1),
                      _buildButton(2),
                      _buildButton(3),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(4),
                      _buildButton(5),
                      _buildButton(6),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(7),
                      _buildButton(8),
                      _buildButton(9),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 64 + 16),
                      _buildButton(0),
                      const SizedBox(width: 64 + 16),
                    ],
                  ),
                ],
              ),
              PieDPad(
                onClick: (code) async {
                  if (code == 189) {
                    print("up");
                  }
                  if (code == 191) {
                    print("left");
                  }
                  if (code == 171) {
                    print("right");
                  }
                  if (code == 190) {
                    print("down");
                  }
                  print(code);
                  // await remote.sendKey(
                  //   widget.deviceModel.ipAddress,
                  //   widget.deviceModel.pairingCode!,
                  //   code,
                  // );
                },
              ),

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [remoteButton("UP", 189)],
              // ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //   children: [
              //     remoteButton("LEFT", 191),
              //     remoteButton("OK", 172),
              //     remoteButton("RIGHT", 171),
              //   ],
              // ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [remoteButton("DOWN", 190)],
              // ),
              // SizedBox(height: 20),
              // Wrap(
              //   spacing: 8,
              //   runSpacing: 8,
              //   children: [
              //     remoteButton("HOME", 141),
              //     remoteButton("BACK", 143),
              //     remoteButton("VOL+", 146),
              //     remoteButton("VOL-", 147),
              //     remoteButton("CH+", 188),
              //     remoteButton("CH-", 145),
              //     remoteButton("MUTE", 176),
              //     remoteButton("POWER", 140),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
