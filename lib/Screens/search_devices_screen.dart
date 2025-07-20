import 'dart:io';

import 'package:flutter/material.dart';
import 'package:remote/utils/display_name.dart';
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
              Expanded(
                child: FutureBuilder(
                  future: service.discoverStbsByMdns(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<dynamic> snapshot,
                  ) {
                    if (snapshot.hasData) {
                      devices = snapshot.data;

                      if (devices.isNotEmpty) {
                        return ListView.builder(
                          // shrinkWrap: true,
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return GestureDetector(
                              onTap: () async {
                                Socket? socket = await service
                                    .sendPairingRequest(
                                      devices[index].ipAddress,
                                    );
                                if (socket != null) {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => PairingDialog(
                                          socket: socket,
                                          service: service,
                                          deviceModel: devices[index],
                                        ),
                                  );
                                }
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
                                    Icon(
                                      Icons.tv,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),

                                    Expanded(
                                      child: Text(
                                        getDisplayName(device.deviceName),
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
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Center(child: Text("No devices found"))],
                        );
                      }
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("An error occured! ${snapshot.error}"),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Center(child: CircularProgressIndicator())],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
