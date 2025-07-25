import 'package:flutter/material.dart';
// import 'package:remote/models/device_model.dart';
// import 'package:remote/screens/remote_controller_screen.dart';
// import 'package:remote/screens/select_device_screen.dart';
import 'package:remote/pref/shared_pref.dart';
import 'package:remote/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefrencesHelper.init();
  await SharedPrefrencesHelper().updateStoredDevicesFromDiscovery();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Remote', home: SplashScreen());
  }
}
