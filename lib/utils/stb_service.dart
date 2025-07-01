import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';
import 'package:remote/models/device_model.dart';

class STBRemoteService {
  int port = 40611;
  String devId = "faeac9ec41c2f652";
  String devDescr = "Magic Remote";

  Socket? _socket;
  StreamQueue<List<int>>? _streamQueue;

  /// Convert array of integers to Uint8List, handling negative values
  static Uint8List toUint8(List<int> arr) {
    List<int> tmp = arr.map((x) => x >= 0 ? x : x + 256).toList();
    return Uint8List.fromList(tmp);
  }

  /// Get AES cipher with CFB mode (segment_size=128, which is 16 bytes - full block)
  static CFBBlockCipher getCipher(String pwd, {required bool forEncryption}) {
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

    // Create CFB cipher with 128-bit segments (16 bytes = full block)
    final cipher = CFBBlockCipher(blockCipher, 128); // 128 bits = 16 bytes

    final keyParam = KeyParameter(key);
    final params = ParametersWithIV(keyParam, iv);

    cipher.init(forEncryption, params);
    return cipher;
  }

  /// Manual CFB-128 encryption (matches Python's segment_size=128)
  static Uint8List encryptData(String pwd, Uint8List data) {
    // Get key and IV
    Uint8List pwdBytes = utf8.encode(pwd);
    List<int> suffix = [8, 56, -102, -124, 29, -75, -45, 74];
    Uint8List suffixBytes = toUint8(suffix);
    Uint8List toHash = Uint8List.fromList([...pwdBytes, ...suffixBytes]);
    crypto.Digest sha1Hash = crypto.sha1.convert(toHash);
    Uint8List key = Uint8List.fromList(sha1Hash.bytes.take(16).toList());

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
    blockCipher.init(true, keyParam);

    final output = Uint8List(data.length);
    final feedbackRegister = Uint8List.fromList(iv); // Start with IV
    final cipherInput = Uint8List(16);
    final cipherOutput = Uint8List(16);

    int offset = 0;
    while (offset < data.length) {
      // Encrypt the feedback register
      cipherInput.setAll(0, feedbackRegister);
      blockCipher.processBlock(cipherInput, 0, cipherOutput, 0);

      // Calculate how many bytes to process in this iteration
      int remainingBytes = data.length - offset;
      int segmentSize = remainingBytes >= 16 ? 16 : remainingBytes;

      // XOR with plaintext and update feedback register
      for (int i = 0; i < segmentSize; i++) {
        output[offset + i] = cipherOutput[i] ^ data[offset + i];
      }

      // Update feedback register: shift left by segmentSize bytes and add ciphertext
      if (segmentSize == 16) {
        // Full segment - feedback register becomes the ciphertext
        feedbackRegister.setAll(0, output.sublist(offset, offset + 16));
      } else {
        // Partial segment - shift left by segmentSize and add partial ciphertext
        for (int i = 0; i < 16 - segmentSize; i++) {
          feedbackRegister[i] = feedbackRegister[i + segmentSize];
        }
        for (int i = 0; i < segmentSize; i++) {
          feedbackRegister[16 - segmentSize + i] = output[offset + i];
        }
      }

      offset += segmentSize;
    }

    return output;
  }

  /// Manual CFB-128 decryption (matches Python's segment_size=128)
  static Uint8List decryptData(String pwd, Uint8List data) {
    // Get key and IV
    Uint8List pwdBytes = utf8.encode(pwd);
    List<int> suffix = [8, 56, -102, -124, 29, -75, -45, 74];
    Uint8List suffixBytes = toUint8(suffix);
    Uint8List toHash = Uint8List.fromList([...pwdBytes, ...suffixBytes]);
    crypto.Digest sha1Hash = crypto.sha1.convert(toHash);
    Uint8List key = Uint8List.fromList(sha1Hash.bytes.take(16).toList());

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

    // Create AES block cipher (always encrypt mode for CFB)
    final blockCipher = AESEngine();
    final keyParam = KeyParameter(key);
    blockCipher.init(true, keyParam);

    final output = Uint8List(data.length);
    final feedbackRegister = Uint8List.fromList(iv); // Start with IV
    final cipherInput = Uint8List(16);
    final cipherOutput = Uint8List(16);

    int offset = 0;
    while (offset < data.length) {
      // Encrypt the feedback register
      cipherInput.setAll(0, feedbackRegister);
      blockCipher.processBlock(cipherInput, 0, cipherOutput, 0);

      // Calculate how many bytes to process in this iteration
      int remainingBytes = data.length - offset;
      int segmentSize = remainingBytes >= 16 ? 16 : remainingBytes;

      // XOR with ciphertext to get plaintext
      for (int i = 0; i < segmentSize; i++) {
        output[offset + i] = cipherOutput[i] ^ data[offset + i];
      }

      // Update feedback register: shift left by segmentSize bytes and add ciphertext (not plaintext!)
      if (segmentSize == 16) {
        // Full segment - feedback register becomes the ciphertext
        feedbackRegister.setAll(0, data.sublist(offset, offset + 16));
      } else {
        // Partial segment - shift left by segmentSize and add partial ciphertext
        for (int i = 0; i < 16 - segmentSize; i++) {
          feedbackRegister[i] = feedbackRegister[i + segmentSize];
        }
        for (int i = 0; i < segmentSize; i++) {
          feedbackRegister[16 - segmentSize + i] = data[offset + i];
        }
      }

      offset += segmentSize;
    }

    return output;
  }

  /// Create message with command, body, and optional encryption code
  static Uint8List getMsg(String cmd, String body, String? code) {
    List<int> prefix = [0x00, 0x00, 0x00, 0x01, 0x00, 0x00];

    Uint8List bodyBytes = utf8.encode(body);

    // Encrypt body if code is provided
    if (code != null) {
      bodyBytes = encryptData(code, bodyBytes);
    }

    // Convert command to bytes
    Uint8List cmdBytes = utf8.encode(cmd);

    // Combine all parts
    List<int> all = [...prefix, ...cmdBytes, ...bodyBytes];

    // Set length at position 4
    all[4] = all.length;

    return Uint8List.fromList(all);
  }

  // void verifyEncryption() {
  //   final body = 'Magic Remote';
  //   final encrypted = encryptData(
  //     "123456",
  //     Uint8List.fromList(utf8.encode(body)),
  //   );
  //   final decrypted = decryptData("123456", encrypted);
  //   print('Decrypted: ${utf8.decode(decrypted)}');
  // }

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
      print("sending pair code");
      socket.add(getPairCompleteMsg(code));
      await socket.flush();
      print("pair completed");

      print("getting data");
      final data = await socket
          .timeout(const Duration(seconds: 30))
          .firstWhere((d) => d.isNotEmpty);
      print("data fetched${data}");

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

  Future<void> connect(String ip) async {
    if (_socket == null) {
      print("connecting to socket");
      _socket = await Socket.connect(ip, port);
      _streamQueue = StreamQueue(_socket!);
      print("Persistent connection established.");
    }
  }

  Future<void> sendKey(String ipAddress, String code, int rcCode) async {
    try {
      await connect(ipAddress);

      // Send connect
      _socket!.add(getReqConnectMsg());
      await _socket!.flush();
      final response1 = await _streamQueue!.next;
      printReply(code, Uint8List.fromList(response1));

      // Send ping
      _socket!.add(getPingMsg(code));
      await _socket!.flush();
      final response2 = await _streamQueue!.next;
      printReply(code, Uint8List.fromList(response2));

      // Send RC + ping
      _socket!.add(getRcCodeMsg(code, rcCode));
      _socket!.add(getPingMsg(code));
      await _socket!.flush();
      final response3 = await _streamQueue!.next;
      printReply(code, Uint8List.fromList(response3));
    } catch (e) {
      print("sendKey error: $e");
      disconnect(); // Optional: force reconnect on next send
    }
  }

  void disconnect() {
    _streamQueue?.cancel();
    _socket?.destroy();
    _socket = null;
    _streamQueue = null;
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
