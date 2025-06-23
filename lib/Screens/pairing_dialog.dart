import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote/Screens/remote_controller_screen.dart';
import 'package:remote/models/device_model.dart';
import 'package:remote/pref/shared_pref.dart';
import 'package:remote/stb_service.dart';

class PairingDialog extends StatefulWidget {
  final DeviceModel deviceModel;

  const PairingDialog({super.key, required this.deviceModel});

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  final _codeController = TextEditingController();
  final _service = STBRemoteService();
  bool _isLoading = false;

  void _pairAndNavigate() async {
    setState(() => _isLoading = true);
    try {
      // await _service.pairDevice(
      //   widget.deviceModel.ipAddress,
      //   _codeController.text,
      // );

      // Add device to connected devices
      await SharedPrefrencesHelper().addConnectedDevice(
        DeviceModel(
          deviceName: widget.deviceModel.deviceName,
          ipAddress: widget.deviceModel.ipAddress,
          pairingCode: _codeController.text,
        ),
      );

      // Close dialog first
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      // Navigate to RemoteControlScreen after dialog closes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => RemoteControlScreen(
                ip: widget.deviceModel.ipAddress,
                pairingCode: _codeController.text,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pairing failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pair with ${widget.deviceModel.deviceName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "IP Address: ${widget.deviceModel.ipAddress}",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: '6-digit Pairing Code',
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child:
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: _pairAndNavigate,
                        child: Text('Pair & Continue'),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
