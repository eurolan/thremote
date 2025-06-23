import 'package:flutter/material.dart';
import 'package:remote/utils/pairing_dialog.dart';
import 'package:remote/models/device_model.dart';
import 'package:remote/utils/stb_service.dart';

class SearchDevicesScreen extends StatefulWidget {
  const SearchDevicesScreen({super.key});

  @override
  State<SearchDevicesScreen> createState() => _SearchDevicesScreenState();
}

class _SearchDevicesScreenState extends State<SearchDevicesScreen> {
  final service = STBRemoteService();
  List<DeviceModel> devices = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Color(0xFFFFFDF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "Search devices",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              SizedBox(height: 20),
              FutureBuilder(
                future: service.discoverStbsByMdns(),
                // future: Future.delayed(Duration(seconds: 3)),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<dynamic> snapshot,
                ) {
                  if (snapshot.hasData) {
                    devices = snapshot.data;
                    // if (!snapshot.hasData) {
                    // devices = [
                    //   DeviceModel(
                    //     deviceName: "TH300",
                    //     ipAddress: "192.168.25",
                    //     pairingCode: null,
                    //   ),
                    // ];

                    if (devices.isNotEmpty) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (_) => PairingDialog(
                                      deviceModel: devices[index],
                                    ),
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.tv, color: Colors.black, size: 24),
                                  SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      device.deviceName,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),

                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Center(child: Text("No devices found"))],
                        ),
                      );
                    }
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("An error occured!"));
                  }
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Center(child: CircularProgressIndicator())],
                    ),
                  );
                },
              ),
      
            ],
          ),
        ),
      ),
    );
  }
}
