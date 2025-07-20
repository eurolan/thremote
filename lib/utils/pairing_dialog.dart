import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote/screens/remote_controller_screen.dart';
import 'package:remote/models/device_model.dart';
import 'package:remote/pref/shared_pref.dart';
import 'package:remote/utils/display_name.dart';
import 'package:remote/utils/stb_service.dart';

class PairingDialog extends StatefulWidget {
  final Socket socket;
  final STBRemoteService service;
  final DeviceModel deviceModel;

  const PairingDialog({
    super.key,
    required this.socket,
    required this.deviceModel,
    required this.service,
  });

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  bool _isLoading = false;

  Future<void> pairAndNavigate() async {
    setState(() => _isLoading = true);
    try {
      bool pairCompleted = await widget.service.completePairing(
        widget.socket,
        _codeController.text.trim(),
      );

      if (pairCompleted) {
        // Add device to connected devices
        await SharedPrefrencesHelper().addConnectedDevice(
          DeviceModel(
            mdnsName: widget.deviceModel.mdnsName,
            deviceName: widget.deviceModel.deviceName,
            ipAddress: widget.deviceModel.ipAddress,
            pairingCode: _codeController.text.trim(),
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
                  deviceModel: DeviceModel(
                    mdnsName: widget.deviceModel.mdnsName,
                    deviceName: widget.deviceModel.deviceName,
                    ipAddress: widget.deviceModel.ipAddress,
                    pairingCode: _codeController.text.trim(),
                  ),
                ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pairing failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
              "Pair with ${getDisplayName(widget.deviceModel.deviceName)}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "IP Address: ${widget.deviceModel.ipAddress}",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: '6-digit Pairing Code',
                      counterText: '',
                    ),
                    validator: (code) {
                      if (code == null || code.isEmpty || code.length < 6) {
                        return 'Please enter 6 digits pairing code';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child:
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            await pairAndNavigate();
                          }
                        },
                        child: Text('Pair & Continue'),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
