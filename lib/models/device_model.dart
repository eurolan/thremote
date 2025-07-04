// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class DeviceModel {
  String mdnsName;
  String deviceName;
  String ipAddress;
  String? pairingCode;

  DeviceModel({
    required this.mdnsName,
    required this.deviceName,
    required this.ipAddress,
    required this.pairingCode,
  });

  DeviceModel copyWith({
    String? mdnsName,
    String? deviceName,
    String? ipAddress,
    String? pairingCode,
  }) {
    return DeviceModel(
      mdnsName: mdnsName ?? this.mdnsName,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
      pairingCode: pairingCode ?? this.pairingCode,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mdnsName': mdnsName,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'pairingCode': pairingCode,
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      mdnsName: map['mdnsName'] as String,
      deviceName: map['deviceName'] as String,
      ipAddress: map['ipAddress'] as String,
      pairingCode: map['pairingCode'] != null ? map['pairingCode'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceModel.fromJson(String source) =>
      DeviceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DeviceModel(mdnsName: $mdnsName, deviceName: $deviceName, ipAddress: $ipAddress, pairingCode: $pairingCode)';
  }

  @override
  bool operator ==(covariant DeviceModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.mdnsName == mdnsName &&
      other.deviceName == deviceName &&
      other.ipAddress == ipAddress &&
      other.pairingCode == pairingCode;
  }

  @override
  int get hashCode {
    return mdnsName.hashCode ^
      deviceName.hashCode ^
      ipAddress.hashCode ^
      pairingCode.hashCode;
  }
}
