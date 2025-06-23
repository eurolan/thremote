import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:remote/models/device_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefrencesHelper {
  static SharedPreferences? preferences;

  static Future<void> init() async {
    preferences = await SharedPreferences.getInstance();
  }

  Future<List<DeviceModel>> loadConnectedDevices() async {
    final List<String>? jsonStringList = preferences?.getStringList(
      'connectedDevices',
    );

    if (jsonStringList == null) return [];

    return jsonStringList
        .map((jsonStr) => DeviceModel.fromJson(json.decode(jsonStr)))
        .toList();
  }

  // Add new device
  Future<void> addConnectedDevice(DeviceModel newDevice) async {
    // Load existing list
    final List<String>? jsonStringList = preferences?.getStringList(
      'connectedDevices',
    );
    List<DeviceModel> connectedDevices =
        jsonStringList != null
            ? jsonStringList
                .map((jsonStr) => DeviceModel.fromJson(json.decode(jsonStr)))
                .toList()
            : [];

    // Check if model already exists
    final exists = connectedDevices.any(
      (model) => model.ipAddress == newDevice.ipAddress,
    );

    if (!exists) {
      connectedDevices.add(newDevice);

      // Save back to SharedPreferences
      final updatedJsonList =
          connectedDevices.map((model) => json.encode(model.toJson())).toList();
      await preferences?.setStringList('connectedDevices', updatedJsonList);
    } else {
      debugPrint('Model with name "${newDevice.deviceName}" already exists.');
    }
  }

  // Rename a device by IP address
  Future<void> renameConnectedDevice({
    required String ipAddress,
    required String newName,
  }) async {
    final List<String>? jsonStringList = preferences?.getStringList(
      'connectedDevices',
    );
    if (jsonStringList == null) return;

    List<DeviceModel> connectedDevices =
        jsonStringList
            .map((jsonStr) => DeviceModel.fromJson(json.decode(jsonStr)))
            .toList();

    // Find the device and update its name
    for (int i = 0; i < connectedDevices.length; i++) {
      if (connectedDevices[i].ipAddress == ipAddress) {
        connectedDevices[i] = connectedDevices[i].copyWith(deviceName: newName);
        break;
      }
    }

    final updatedJsonList =
        connectedDevices.map((d) => json.encode(d.toJson())).toList();
    await preferences?.setStringList('connectedDevices', updatedJsonList);
  }

  // Delete a device by IP address
  Future<void> deleteConnectedDevice(String ipAddress) async {
    final List<String>? jsonStringList = preferences?.getStringList(
      'connectedDevices',
    );
    if (jsonStringList == null) return;

    List<DeviceModel> connectedDevices =
        jsonStringList
            .map((jsonStr) => DeviceModel.fromJson(json.decode(jsonStr)))
            .toList();

    connectedDevices.removeWhere((device) => device.ipAddress == ipAddress);

    final updatedJsonList =
        connectedDevices.map((d) => json.encode(d.toJson())).toList();
    await preferences?.setStringList('connectedDevices', updatedJsonList);
  }
}
