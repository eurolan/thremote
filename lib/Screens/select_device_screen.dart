import 'package:flutter/material.dart';
import 'package:remote/screens/remote_controller_screen.dart';
import 'package:remote/screens/search_devices_screen.dart';
import 'package:remote/models/device_model.dart';
import 'package:remote/pref/shared_pref.dart';

class SelectDeviceScreen extends StatefulWidget {
  const SelectDeviceScreen({super.key});

  @override
  State<SelectDeviceScreen> createState() => _SelectDeviceScreenState();
}

class _SelectDeviceScreenState extends State<SelectDeviceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Select device",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: FutureBuilder(
                  future: SharedPrefrencesHelper().loadConnectedDevices(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<dynamic> snapshot,
                  ) {
                    if (snapshot.hasData) {
                      List<DeviceModel> connectedDevices = snapshot.data;

                      if (connectedDevices.isNotEmpty) {
                        return ListView.builder(
                          itemCount: connectedDevices.length,
                          itemBuilder: (context, index) {
                            final device = connectedDevices[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => RemoteControlScreen(
                                          deviceModel: connectedDevices[index],
                                        ),
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
                                    Icon(
                                      Icons.tv,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        device.deviceName,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    PopupMenuButton<MenuItem>(
                                      onSelected: (value) async {
                                        if (value == MenuItem.edit) {
                                          _renameDevice(
                                            context,
                                            connectedDevices[index],
                                          ).then((renamed) {
                                            if (renamed) setState(() {});
                                          });
                                        } else if (value == MenuItem.delete) {
                                          _deleteDevice(
                                            context,
                                            connectedDevices[index],
                                          ).then((deleted) {
                                            if (deleted) setState(() {});
                                          });
                                        }
                                      },
                                      child: const Icon(
                                        Icons.more_vert_rounded,
                                      ),
                                      itemBuilder:
                                          (context) => [
                                            const PopupMenuItem(
                                              value: MenuItem.edit,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    color: Colors.black54,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text("Rename"),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: MenuItem.delete,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text("Delete"),
                                                ],
                                              ),
                                            ),
                                          ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.35,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[300],
                                    ),
                                    child: Icon(
                                      Icons.tv_rounded,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "No Connected Devices",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  textAlign: TextAlign.center,
                                  "Your set-top box and mobile device should be connected to the same wifi network.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  textAlign: TextAlign.center,
                                  "On your set-top box must be turn on the remote control option or in portal selection screen.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                            
                                SizedBox(height: 16),
                                Text(
                                  textAlign: TextAlign.center,
                                  "(Settings > System settings > Remote control)",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  textAlign: TextAlign.center,
                                  "If we cannot find your set-top box, please ensure that your set-top box is running the lastest operating system update.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text("An error occured!"));
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width - 48,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF2A011),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SearchDevicesScreen()),
                    ).then((_) => setState(() {}));
                  },
                  child: Text(
                    "Search devices",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _deleteDevice(BuildContext context, DeviceModel device) async {
    bool deleted = false;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Device'),
            content: Text(
              'Are you sure you want to delete "${device.deviceName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Cancel
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await SharedPrefrencesHelper().deleteConnectedDevice(
                    device.ipAddress,
                  );
                  deleted = true;
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                },
                child: Text('Delete'),
              ),
            ],
          ),
    );

    return deleted;
  }

  Future<bool> _renameDevice(BuildContext context, DeviceModel device) async {
    final TextEditingController controller = TextEditingController(
      text: device.deviceName,
    );
    bool renamed = false;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Rename Device'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Enter new device name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty && newName != device.deviceName) {
                    await SharedPrefrencesHelper().renameConnectedDevice(
                      ipAddress: device.ipAddress,
                      newName: newName,
                    );
                    renamed = true;
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                },
                child: Text('Rename'),
              ),
            ],
          ),
    );

    return renamed;
  }
}

enum MenuItem { edit, delete }
