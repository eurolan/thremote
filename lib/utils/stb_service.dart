import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';

// import 'package:crypto/crypto.dart';
import 'package:remote/models/device_model.dart';
// import 'package:encrypt/encrypt.dart' as encrypt;

// import 'package:pointycastle/digests/sha1.dart';

class STBRemoteService {
  int port = 40611;
  String devId = "faeac9ec41c2f652";
  String devDescr = "Magic Remote";

  /// Convert array of integers to Uint8List, handling negative values
  static Uint8List toUint8(List<int> arr) {
    List<int> tmp = arr.map((x) => x >= 0 ? x : x + 256).toList();
    return Uint8List.fromList(tmp);
  }

  /// Encrypt data using password (using manual CFB-8 implementation)
  static Uint8List encryptData(String pwd, Uint8List data) {
    return encryptDataManual(pwd, data);
  }

  /// Decrypt data using password (using manual CFB-8 implementation)
  static Uint8List decryptData(String pwd, Uint8List data) {
    return decryptDataManual(pwd, data);
  }

  /// Alternative implementation using manual CFB processing if the above doesn't work
  static Uint8List encryptDataManual(String pwd, Uint8List data) {
    // Convert password to bytes
    Uint8List pwdBytes = utf8.encode(pwd);

    // Suffix array with negative values converted
    List<int> suffix = [8, 56, -102, -124, 29, -75, -45, 74];
    Uint8List suffixBytes = toUint8(suffix);

    // Concatenate password and suffix
    Uint8List toHash = Uint8List.fromList([...pwdBytes, ...suffixBytes]);

    // Calculate SHA1 hash and take first 16 bytes as key
    crypto.Digest sha1Hash = crypto.sha1.convert(toHash);
    Uint8List key = Uint8List.fromList(sha1Hash.bytes.take(16).toList());

    // IV array with negative values converted
    List<int> ivArray = [
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
    ];
    Uint8List iv = toUint8(ivArray);

    // Create AES block cipher
    final blockCipher = AESEngine();
    final keyParam = KeyParameter(key);
    blockCipher.init(true, keyParam); // Always true for CFB encryption

    final output = Uint8List(data.length);
    final feedbackRegister = Uint8List.fromList(
      iv,
    ); // Copy IV to feedback register
    final cipherInput = Uint8List(16); // AES block size
    final cipherOutput = Uint8List(16);

    for (int i = 0; i < data.length; i++) {
      // Copy feedback register to cipher input
      cipherInput.setAll(0, feedbackRegister);

      // Encrypt the feedback register
      blockCipher.processBlock(cipherInput, 0, cipherOutput, 0);

      // XOR the first byte of cipher output with plaintext
      output[i] = cipherOutput[0] ^ data[i];

      // Shift feedback register left by 1 byte and add the ciphertext
      for (int j = 0; j < 15; j++) {
        feedbackRegister[j] = feedbackRegister[j + 1];
      }
      feedbackRegister[15] = output[i]; // Add ciphertext to feedback register
    }

    return output;
  }

  /// Alternative manual decryption
  static Uint8List decryptDataManual(String pwd, Uint8List data) {
    // Convert password to bytes
    Uint8List pwdBytes = utf8.encode(pwd);

    // Suffix array with negative values converted
    List<int> suffix = [8, 56, -102, -124, 29, -75, -45, 74];
    Uint8List suffixBytes = toUint8(suffix);

    // Concatenate password and suffix
    Uint8List toHash = Uint8List.fromList([...pwdBytes, ...suffixBytes]);

    // Calculate SHA1 hash and take first 16 bytes as key
    crypto.Digest sha1Hash = crypto.sha1.convert(toHash);
    Uint8List key = Uint8List.fromList(sha1Hash.bytes.take(16).toList());

    // IV array with negative values converted
    List<int> ivArray = [
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
    ];
    Uint8List iv = toUint8(ivArray);

    // Create AES block cipher
    final blockCipher = AESEngine();
    final keyParam = KeyParameter(key);
    blockCipher.init(true, keyParam); // Always true for CFB (even decryption)

    final output = Uint8List(data.length);
    final feedbackRegister = Uint8List.fromList(
      iv,
    ); // Copy IV to feedback register
    final cipherInput = Uint8List(16); // AES block size
    final cipherOutput = Uint8List(16);

    for (int i = 0; i < data.length; i++) {
      // Copy feedback register to cipher input
      cipherInput.setAll(0, feedbackRegister);

      // Encrypt the feedback register
      blockCipher.processBlock(cipherInput, 0, cipherOutput, 0);

      // XOR the first byte of cipher output with ciphertext
      output[i] = cipherOutput[0] ^ data[i];

      // Shift feedback register left by 1 byte and add the ciphertext (not plaintext!)
      for (int j = 0; j < 15; j++) {
        feedbackRegister[j] = feedbackRegister[j + 1];
      }
      feedbackRegister[15] = data[i]; // Add ciphertext to feedback register
    }

    return output;
  }

  /// Create message with command, body, and optional encryption code
  static Uint8List getMsg(String cmd, String body, String? code) {
    // Create prefix - exactly matching Python: bytearray(b'\x00\x00\x00\x01\x00\x00')
    List<int> prefix = [0x00, 0x00, 0x00, 0x01, 0x00, 0x00];

    // Convert body to bytes
    Uint8List bodyBytes = utf8.encode(body);

    // Encrypt body if code is provided
    if (code != null) {
      bodyBytes = encryptData(code, bodyBytes);
    }

    // Convert command to bytes
    Uint8List cmdBytes = utf8.encode(cmd);

    // Combine all parts: prefix + cmd + body
    List<int> all = [...prefix, ...cmdBytes, ...bodyBytes];

    // Set length at position 4: all[4] = len(all)
    all[4] = all.length;

    // Print the bytes (matching Python's print(list(bytes(all))))
    print(all);

    return Uint8List.fromList(all);
  }

  // Uint8List getMsg(String cmd, String body, String? code) {
  //   final prefix = Uint8List.fromList([0, 0, 0, 1, 0, 0]);
  //   Uint8List bodyBytes = Uint8List.fromList(utf8.encode(body));

  //   if (code != null) {
  //     bodyBytes = encryptData(code, bodyBytes);
  //   }

  //   final cmdBytes = utf8.encode(cmd);
  //   final full = Uint8List.fromList([...prefix, ...cmdBytes, ...bodyBytes]);

  //   full[4] = full.length;
  //   print("getMsgOutput :$full");
  //   return full;
  // }

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
