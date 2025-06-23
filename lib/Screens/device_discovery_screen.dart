// import 'package:flutter/material.dart';
// import 'package:remote/Screens/pairing_screen.dart';
// import 'package:remote/device_info.dart';
// import 'package:remote/stb_service.dart';

// class DeviceDiscoveryScreen extends StatefulWidget {
//   @override
//   _DeviceDiscoveryScreenState createState() => _DeviceDiscoveryScreenState();
// }

// class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
//   final service = STBRemoteService();
//   List<String> devices = [];
//   bool isLoading = false;

//   void _discover() async {
//     setState(() => isLoading = true);
//     // final localSubnet = await getLocalSubnetPrefix();
//     // print(localSubnet);
//     // if (localSubnet == null) {
//     //   ScaffoldMessenger.of(
//     //     context,
//     //   ).showSnackBar(SnackBar(content: Text('Could not detect local IP')));
//     //   return;
//     // }
//     devices = await service.discoverStbsByMdns();
//     // devices = await service.scanForSTBs(localSubnet);
//     setState(() => isLoading = false);
//   }

//   @override
//   void initState() {
//     super.initState();
//     _discover();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Discover STB Devices')),
//       body:
//           isLoading
//               ? Center(child: CircularProgressIndicator())
//               : ListView.builder(
//                 itemCount: devices.length,
//                 itemBuilder:
//                     (_, i) => ListTile(
//                       title: Text(devices[i]),
//                       onTap:
//                           () => Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => PairingScreen(ip: devices[i]),
//                             ),
//                           ),
//                     ),
//               ),
//     );
//   }
// }
