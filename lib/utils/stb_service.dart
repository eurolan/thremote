import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:remote/models/device_model.dart';
import 'package:pointycastle/digests/sha1.dart';

class STBRemoteService {
  int port = 40611;
  String devId = "faeac9ec41c2f652";
  String devDescr = "Magic Remote";
  late Socket _socket;

  Uint8List toUint8(List<int> arr) {
    return Uint8List.fromList(arr.map((x) => x >= 0 ? x : x + 256).toList());
  }

  encrypt.Encrypter getCipher(String password) {
    final pwdBytes = utf8.encode(password);
    final suffix = [8, 56, -102, -124, 29, -75, -45, 74];
    final input = Uint8List.fromList(pwdBytes + toUint8(suffix));

    final sha1 = SHA1Digest();
    final key = sha1.process(input).sublist(0, 16);

    final ivBytes = toUint8([
      18,
      111,
      -15,
      33,
      102,
      71,
      -112,
      109,
      -64,
      -23,
      6,
      -103,
      -76,
      99,
      -34,
      101,
    ]);

    final iv = encrypt.IV(ivBytes);
    final aesKey = encrypt.Key(key);

    return encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cfb64));
  }

  Uint8List encryptData(String password, Uint8List data) {
    final cipher = getCipher(password);
    final ivBytes = toUint8([
      18,
      111,
      -15,
      33,
      102,
      71,
      -112,
      109,
      -64,
      -23,
      6,
      -103,
      -76,
      99,
      -34,
      101,
    ]);
    final iv = encrypt.IV(ivBytes);
    return cipher.encryptBytes(data, iv: iv).bytes;
  }

  Uint8List decryptData(String password, Uint8List data) {
    final cipher = getCipher(password);
    final ivBytes = toUint8([
      18,
      111,
      -15,
      33,
      102,
      71,
      -112,
      109,
      -64,
      -23,
      6,
      -103,
      -76,
      99,
      -34,
      101,
    ]);
    final iv = encrypt.IV(ivBytes);
    final decrypted = cipher.decryptBytes(encrypt.Encrypted(data), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  Uint8List getMessage(String cmd, String body, [String? code]) {
    final prefix = Uint8List.fromList([0, 0, 0, 1, 0, 0]);
    Uint8List bodyBytes = Uint8List.fromList(utf8.encode(body));

    if (code != null) {
      bodyBytes = encryptData(code, bodyBytes);
    }

    final cmdBytes = utf8.encode(cmd);
    final total = Uint8List.fromList([...prefix, ...cmdBytes, ...bodyBytes]);
    total[4] = total.length;

    return total;
  }

  Uint8List getReqPairMsg() {
    final body = jsonEncode({"dev_id": devId, "dev_descr": devDescr});
    return getMessage("pairing-reqpairing-reqpairing-re", body);
  }

  Uint8List getPairCompleteMsg(String code) {
    final body = jsonEncode({"dev_id": devId, "dev_descr": devDescr});
    return getMessage("pairing-complete-reqpairing-comp", body, code);
  }

  void printReply(String code, Uint8List data) {
    final cmd = utf8.decode(data.sublist(6, 38));
    final body = data.sublist(6 + cmd.length);

    try {
      final decrypted = utf8.decode(decryptData(code, body));

      print("<< $cmd $decrypted");
    } catch (e) {
      print("Decryption failed, wrong pairing code?");
    }
  }

  Future<void> sendPairingRequest(String ipAddress) async {
    try {
      _socket = await Socket.connect(ipAddress, port);
      _socket.add(getReqPairMsg());
      await _socket.flush();
    } catch (e) {
      print("Failed to send pairing request: $e");
    }
  }

  Future<bool> completePairing(String code) async {
    try {
      _socket.add(getPairCompleteMsg(code));
      await _socket.flush();

      final data = await _socket.timeout(Duration(seconds: 30)).first;
      if (data.isNotEmpty) {
        printReply(code, Uint8List.fromList(data));
        return true;
      }
    } catch (e) {
      print("Error during pairing: $e");
    } finally {
      _socket.destroy();
    }
    return false;
  }

  Uint8List getRcCodeMsg(String code, int rcCode) {
    const cmd = "rc-code-reqrc-code-reqrc-code-re";
    final body =
        '{"dev_id":"$devId","dev_descr":"$devDescr","rc_code":$rcCode}';
    return getMessage(cmd, body, code);
  }

  Uint8List getPingMsg(String code) {
    const cmd = "ping-reqping-reqping-reqping-req";
    final body = '{"dev_id":"$devId"}';
    return getMessage(cmd, body, code);
  }

  Uint8List getReqConnectMsg() {
    final body = '{"dev_id":"$devId","dev_descr":"$devDescr"}';
    return getMessage("connect-reqconnect-reqconnect-re", body);
  }

  Future<void> sendRcCode(Socket socket, String code, int rcCode) async {
    socket.add(getRcCodeMsg(code, rcCode));
    socket.add(getPingMsg(code));
    await socket.flush();

    final response = await socket.first;
    printReply(code, Uint8List.fromList(response));
  }

  Future<void> sendKey(String ipAddress, String code, int rcCode) async {
    try {
      final socket = await Socket.connect(ipAddress, port);

      // Step 1: Send connect request
      socket.add(getReqConnectMsg());
      await socket.flush();

      // Step 2: Read and print reply
      final response1 = await socket.first;
      printReply(code, Uint8List.fromList(response1));

      // Step 3: Send ping
      socket.add(getPingMsg(code));
      await socket.flush();

      final response2 = await socket.first;
      printReply(code, Uint8List.fromList(response2));

      // Step 4: Send RC code and ping
      await sendRcCode(socket, code, rcCode);

      socket.destroy();
    } catch (e) {
      print("sendKey error: $e");
    }
  }

  Future<List<DeviceModel>> discoverStbsByMdns() async {
    final List<DeviceModel> foundDevices = [];
    final MDnsClient client = MDnsClient();

    await client.start();

    await for (final ptr in client.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(
        '_infomir_mobile_rc_service._tcp.local',
      ),
    )) {
      await for (final srv in client.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      )) {
        final deviceName = srv.name;

        await for (final ip in client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(srv.target),
        )) {
          final ipAddress = ip.address.address;
          debugPrint('✅ Found STB: $deviceName at $ipAddress');

          foundDevices.add(
            DeviceModel(
              deviceName: deviceName,
              ipAddress: ipAddress,
              pairingCode: null,
            ),
          );
        }
      }
    }

    client.stop();
    return foundDevices;
  }
}
