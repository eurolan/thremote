import 'package:flutter/material.dart';
import 'package:remote/Screens/device_discovery_screen.dart';
import 'package:remote/Screens/pairing_dialog.dart';
import 'package:remote/Screens/select_device_screen.dart';
import 'package:remote/pref/shared_pref.dart';
// import 'package:remote/Screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefrencesHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Remote', home: SelectDeviceScreen());
  }
}
