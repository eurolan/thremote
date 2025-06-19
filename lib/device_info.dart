import 'package:network_info_plus/network_info_plus.dart';

Future<String?> getLocalSubnetPrefix() async {
  final info = NetworkInfo();
  final ip = await info.getWifiIP(); // e.g. 192.168.1.103
  if (ip == null || !ip.contains('.')) return null;
  final parts = ip.split('.');
  if (parts.length != 4) return null;
  return '${parts[0]}.${parts[1]}.${parts[2]}'; // e.g. 192.168.1
}
