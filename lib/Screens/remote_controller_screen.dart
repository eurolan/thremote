import 'package:flutter/material.dart';
import 'package:remote/models/device_model.dart';
import 'package:remote/utils/stb_service.dart';

class RemoteControlScreen extends StatelessWidget {
  final DeviceModel deviceModel;

  RemoteControlScreen({super.key, required this.deviceModel});

  final remote = STBRemoteService();

  void send(int code) async {
    await remote.sendKey(deviceModel.ipAddress, deviceModel.pairingCode!, code);
  }

  Widget remoteButton(String label, int code) {
    return ElevatedButton(onPressed: () => send(code), child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(deviceModel.deviceName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [remoteButton("UP", 189)],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                remoteButton("LEFT", 191),
                remoteButton("OK", 172),
                remoteButton("RIGHT", 171),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [remoteButton("DOWN", 190)],
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                remoteButton("HOME", 141),
                remoteButton("BACK", 143),
                remoteButton("VOL+", 146),
                remoteButton("VOL-", 147),
                remoteButton("CH+", 188),
                remoteButton("CH-", 145),
                remoteButton("MUTE", 176),
                remoteButton("POWER", 140),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
