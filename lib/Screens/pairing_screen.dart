import 'package:flutter/material.dart';
import 'package:remote/Screens/remote_controller_screen.dart';
import 'package:remote/stb_service.dart';

class PairingScreen extends StatefulWidget {
  final String ip;
  const PairingScreen({super.key, required this.ip});

  @override
  // ignore: library_private_types_in_public_api
  _PairingScreenState createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeController = TextEditingController();
  final _service = STBRemoteService();
  bool _isLoading = false;

  void _pairAndNavigate() async {
    setState(() => _isLoading = true);
    try {
      await _service.pairDevice(widget.ip, _codeController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => RemoteControlScreen(
                ip: widget.ip,
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
    return Scaffold(
      appBar: AppBar(title: Text('Pair with STB')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Selected IP: ${widget.ip}"),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: '6-digit Pairing Code'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _pairAndNavigate,
                  child: Text('Pair & Continue'),
                ),
          ],
        ),
      ),
    );
  }
}
