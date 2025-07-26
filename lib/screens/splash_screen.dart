import 'package:flutter/material.dart';
import 'dart:async';

import 'package:remote/pref/shared_pref.dart';
import 'package:remote/screens/select_device_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Show logo immediately, then do background initialization
    
    // Start device discovery in background
    final Future<void> deviceDiscovery = SharedPrefrencesHelper().updateStoredDevicesFromDiscovery();
    
    // Ensure minimum display time of 1.5 seconds for branding
    final Future<void> minimumDelay = Future.delayed(const Duration(milliseconds: 1500));
    
    // Wait for both to complete
    await Future.wait([deviceDiscovery, minimumDelay]);
    
    // Navigate to next screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SelectDeviceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Image(
            image: AssetImage('assets/images/th300.jpg'),
            height: 350,
          ),
        ),
      ),
    );
  }
}
