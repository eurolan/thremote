import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? repeatTimer;

  Future<void> sendSTBKey(int code) async {
    HapticFeedback.mediumImpact();
    await remote.sendKey(
      widget.deviceModel.ipAddress,
      widget.deviceModel.pairingCode!,
      code,
    );
  }

  Future<void> sendSTBText(String text) async {
    HapticFeedback.mediumImpact();
    await remote.sendText(
      widget.deviceModel.ipAddress,
      widget.deviceModel.pairingCode!,
      text,
    );
  }

  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardListenerFocus = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _isKeyboardVisible = false;

  Future<void> _sendCharacter(String value) async {
    if (value.isNotEmpty) {
      final char = value.substring(value.length - 1);
      debugPrint('Send to STB: $char');
      await sendSTBText(char);
    }
  }

  Widget _buildButton(int number, double size) {
    Timer? repeatTimer;

    void startSending() {
      repeatTimer = Timer.periodic(
        const Duration(milliseconds: 300),
        (_) => sendSTBKey(128 + number),
      );
    }

    void stopSending() {
      repeatTimer?.cancel();
      repeatTimer = null;
    }

    return Container(
      margin: EdgeInsets.all(size * 0.15),
      width: size,
      height: size,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: Colors.deepPurple.withOpacity(0.1),

          onTap: () async {
            await sendSTBKey(128 + number);
          },
          onTapDown: (_) {
            startSending();
          },
          onTapUp: (_) {
            stopSending();
          },
          onTapCancel: () {
            stopSending();
          },
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(fontSize: size * 0.4, color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  void clearKeyboardFocus(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void showFunctionButtonsSheet(BuildContext context, double fontSize) {
    clearKeyboardFocus(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _functionButton('F1', Colors.red, 178, fontSize),
                    _functionButton('F2', Colors.green, 177, fontSize),
                    _functionButton('F3', Colors.yellow[700]!, 185, fontSize),
                    _functionButton('F4', Colors.blue, 186, fontSize),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      FocusScope.of(context).unfocus();
    });
  }

  Widget _functionButton(
    String label,
    Color textColor,
    int rcCode,
    double fontSize,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton(
          onPressed: () async => await sendSTBKey(rcCode),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget abcButton(double size) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        if (_isKeyboardVisible) {
          _focusNode.unfocus();
        } else {
          FocusScope.of(context).requestFocus(_focusNode);
        }
        _isKeyboardVisible = !_isKeyboardVisible;
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(size, size),
      ),
      child: Text(
        "ABC",
        style: TextStyle(
          fontSize: size * 0.3,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget fourDotsButton(double size, double dotSize) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        showFunctionButtonsSheet(context, size * 0.3);
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(size, size),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(Colors.orange, dotSize),
              const SizedBox(width: 1),
              _buildDot(Colors.red, dotSize),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(Colors.green, dotSize),
              const SizedBox(width: 1),
              _buildDot(Colors.blue, dotSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      margin: const EdgeInsets.all(1),
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _iconCircleButton(IconData icon, int rcCode, double size) {
    return Container(
      margin: const EdgeInsets.all(4),
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () async => await sendSTBKey(rcCode),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, color: Colors.black87, size: size * 0.4),
      ),
    );
  }

  Widget _homeButton(IconData icon, int rcCode, double size) {
    return Container(
      margin: const EdgeInsets.all(4),
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () async => await sendSTBKey(rcCode),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, color: Colors.black87, size: size * 0.35),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonSize = screenWidth * 0.12; // number pad buttons
    final smallButtonSize = screenWidth * 0.14; // icon buttons
    final bigButtonSize = screenWidth * 0.2; // home button
    final dotSize = screenWidth * 0.02;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.015),

              /// Hidden TextField
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  height: 2,
                  child: KeyboardListener(
                    focusNode: _keyboardListenerFocus,
                    onKeyEvent: (KeyEvent event) async {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.backspace) {
                          await sendSTBKey(143);
                        }
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: false,
                      onChanged: (value) async {
                        await _sendCharacter(value);
                        _controller.clear();
                      },
                    ),
                  ),
                ),
              ),

              /// Title + Power button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: screenWidth * 0.7,
                        child: Text(
                          widget.deviceModel.deviceName,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
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
                            size: screenWidth * 0.07,
                            Icons.power_settings_new,
                            color: const Color.fromRGBO(192, 24, 81, 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              /// Number pad
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(1, buttonSize),
                      _buildButton(2, buttonSize),
                      _buildButton(3, buttonSize),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(4, buttonSize),
                      _buildButton(5, buttonSize),
                      _buildButton(6, buttonSize),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(7, buttonSize),
                      _buildButton(8, buttonSize),
                      _buildButton(9, buttonSize),
                    ],
                  ),
                  SizedBox(
                    width: screenWidth * 0.65,
                    height: buttonSize * 1.7,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(child: _buildButton(0, buttonSize)),
                        Positioned(
                          left: 0,
                          top: buttonSize * 0.4,
                          child: fourDotsButton(smallButtonSize, dotSize),
                        ),
                        Positioned(
                          right: 0,
                          top: buttonSize * 0.4,
                          child: abcButton(smallButtonSize),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),

              /// Volume - DPad - Channel
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VolumeControlPill(
                      onClick: (code) async => await sendSTBKey(code),
                    ),
                    PieDPad(onClick: (code) async => await sendSTBKey(code)),
                    ChannelControlPill(
                      onClick: (code) async => await sendSTBKey(code),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              /// Bottom section
              Column(
                children: [
                  // Home, Back, Info, Mute
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _iconCircleButton(Icons.volume_off, 176, smallButtonSize),
                      _iconCircleButton(Icons.arrow_back, 143, smallButtonSize),
                      _homeButton(Icons.home, 141, bigButtonSize),
                      _iconCircleButton(
                        Icons.info_outline,
                        157,
                        smallButtonSize,
                      ),
                      _iconCircleButton(
                        Icons.menu_rounded,
                        138,
                        smallButtonSize,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Rewind, Play/Pause, Fast Forward
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _iconCircleButton2(
                        Icons.fast_rewind,
                        150,
                        smallButtonSize,
                      ),
                      _iconCircleButton(
                        CupertinoIcons.playpause_fill,
                        139,
                        smallButtonSize,
                      ),
                      _iconCircleButton2(
                        Icons.fast_forward,
                        144,
                        smallButtonSize,
                      ),
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

  Widget _iconCircleButton2(IconData icon, int rcCode, double size) {
    return Container(
      margin: const EdgeInsets.all(4),
      width: size,
      height: size,
      child: GestureDetector(
        onTapDown: (_) {
          repeatTimer = Timer.periodic(
            const Duration(milliseconds: 300),
            (_) => sendSTBKey(rcCode),
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
            await sendSTBKey(rcCode);
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, color: Colors.black87, size: size * 0.4),
        ),
      ),
    );
  }
}
