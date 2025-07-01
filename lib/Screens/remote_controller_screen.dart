import 'package:flutter/material.dart';
import 'package:remote/models/device_model.dart';
import 'package:remote/utils/channel_pill.dart';
import 'package:remote/utils/pie_dpad_widget.dart';
import 'package:remote/utils/stb_service.dart';
import 'package:remote/utils/volume_pill.dart';

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

  Widget _iconCircleButton(IconData icon, int rcCode) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: () async => await sendSTBKey(rcCode),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, color: Colors.black54, size: 20),
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
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  VolumeControlPill(
                    onClick: (code) async {
                      await sendSTBKey(code);
                    },
                  ),
                  PieDPad(
                    onClick: (code) async {
                      await sendSTBKey(code);
                    },
                  ),
                  ChannelControlPill(
                    onClick: (code) async {
                      await sendSTBKey(code);
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
              Column(
                children: [
                  // Home, Back, Info, Mute
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _iconCircleButton(Icons.arrow_back, 143),
                      _iconCircleButton(Icons.home, 141),
                      _iconCircleButton(Icons.info_outline, 157),
                      _iconCircleButton(Icons.volume_off, 176),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Rewind, Play/Pause, Fast Forward
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _iconCircleButton(Icons.fast_rewind, 150),
                      _iconCircleButton(Icons.play_arrow, 139),
                      _iconCircleButton(Icons.fast_forward, 144),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
