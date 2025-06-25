import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:pointycastle/api.dart';
import 'package:remote/models/device_model.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';

// import 'package:pointycastle/digests/sha1.dart';

class STBRemoteService {
  int port = 40611;
  String devId = "faeac9ec41c2f652";
  String devDescr = "Magic Remote";
  Uint8List toUint8(List<int> list) {
    return Uint8List.fromList(list.map((e) => e < 0 ? 256 + e : e).toList());
  }

  Uint8List getIV() {
    return toUint8([
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
  }

  Uint8List sha1Digest(Uint8List data) {
    final d = sha1.convert(data);
    return Uint8List.fromList(d.bytes);
  }

  Uint8List getKeyFromPassword(String password) {
    final pwdBytes = utf8.encode(password);
    final suffix = toUint8([8, 56, -102, -124, 29, -75, -45, 74]);
    final combined = Uint8List.fromList([...pwdBytes, ...suffix]);
    final digest = sha1Digest(combined);
    return digest.sublist(0, 16); // AES-128
  }


  Uint8List encryptData(String password, Uint8List plainText) {
    final key = getKeyFromPassword(password);
    final iv = getIV();
    final blockCipher = AESFastEngine();
    final blockSize = blockCipher.blockSize;

    final output = Uint8List(plainText.length);
    final feedback = Uint8List.fromList(iv);

    blockCipher.init(true, KeyParameter(key));

    for (int i = 0; i < plainText.length; i++) {
      final encryptedBlock = Uint8List(blockSize);
      blockCipher.processBlock(feedback, 0, encryptedBlock, 0);

      final cipherByte = plainText[i] ^ encryptedBlock[0];
      output[i] = cipherByte;

      // Shift feedback by 1 and append the ciphertext byte
      for (int j = 0; j < blockSize - 1; j++) {
        feedback[j] = feedback[j + 1];
      }
      feedback[blockSize - 1] = cipherByte;
    }

    return output;
  }

  Uint8List decryptData(String password, Uint8List cipherText) {
    final key = getKeyFromPassword(password);
    final iv = getIV();
    final blockCipher = AESFastEngine();
    final blockSize = blockCipher.blockSize;

    final output = Uint8List(cipherText.length);
    final feedback = Uint8List.fromList(iv);

    blockCipher.init(true, KeyParameter(key));

    for (int i = 0; i < cipherText.length; i++) {
      final encryptedBlock = Uint8List(blockSize);
      blockCipher.processBlock(feedback, 0, encryptedBlock, 0);

      final plainByte = cipherText[i] ^ encryptedBlock[0];
      output[i] = plainByte;

      // Shift feedback by 1 and append the ciphertext byte
      for (int j = 0; j < blockSize - 1; j++) {
        feedback[j] = feedback[j + 1];
      }
      feedback[blockSize - 1] = cipherText[i];
    }

    return output;
  }

  Uint8List getMsg(String cmd, String body, String? code) {
    final prefix = Uint8List.fromList([0, 0, 0, 1, 0, 0]);
    Uint8List bodyBytes = Uint8List.fromList(utf8.encode(body));

    if (code != null) {
      bodyBytes = encryptData(code, bodyBytes);
    }

    final cmdBytes = utf8.encode(cmd);
    final full = Uint8List.fromList([...prefix, ...cmdBytes, ...bodyBytes]);

    full[4] = full.length;
    print("getMsgOutput :$full");
    return full;
  }

  void verifyEncryption() {
    final body = 'Magic Remote';
    final encrypted = encryptData(
      "123456",
      Uint8List.fromList(utf8.encode(body)),
    );
    final decrypted = decryptData("123456", encrypted);
    print('Decrypted: ${utf8.decode(decrypted)}');
  }

  Uint8List getReqPairMsg() {
    final body = jsonEncode({"dev_id": devId, "dev_descr": devDescr});
    return getMsg("pairing-reqpairing-reqpairing-re", body, null);
  }

  Uint8List getPairCompleteMsg(String code) {
    final body = jsonEncode({"dev_id": devId, "dev_descr": devDescr});
    return getMsg("pairing-complete-reqpairing-comp", body, code);
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

  Future<Socket?> sendPairingRequest(String ipAddress) async {
    try {
      final Socket socket = await Socket.connect(ipAddress, port);
      socket.add(getReqPairMsg());
      await socket.flush();
      print("sent pair request");
      return socket;
    } catch (e) {
      print("Failed to send pairing request: $e");
      return null;
    }
  }

  Future<bool> completePairing(Socket socket, String code) async {
    try {
      socket.add(getPairCompleteMsg(code));
      await socket.flush();

      final data = await socket
          .timeout(const Duration(seconds: 30))
          .firstWhere((d) => d.isNotEmpty);

      // final response = await socket.first;
      printReply(code, Uint8List.fromList(data));
      return true;
    } catch (e) {
      print("Error during pairing: $e");
    } finally {
      socket.destroy();
    }

    return false;
  }

  Uint8List getRcCodeMsg(String code, int rcCode) {
    const cmd = "rc-code-reqrc-code-reqrc-code-re";
    final body =
        '{"dev_id":"$devId","dev_descr":"$devDescr","rc_code":$rcCode}';
    return getMsg(cmd, body, code);
  }

  Uint8List getPingMsg(String code) {
    const cmd = "ping-reqping-reqping-reqping-req";
    final body = '{"dev_id":"$devId"}';
    return getMsg(cmd, body, code);
  }

  Uint8List getReqConnectMsg() {
    final body = '{"dev_id":"$devId","dev_descr":"$devDescr"}';
    return getMsg("connect-reqconnect-reqconnect-re", body, null);
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
