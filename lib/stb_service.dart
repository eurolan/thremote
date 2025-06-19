// Flutter STB Remote Core Implementation with UI and Pairing Screen

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class STBRemoteService {
  static const String devId = "faeac9ec41c2f652";
  static const String devDescr = "Magic Remote";
  static const int port = 40611;

  Uint8List toUint8(List<int> arr) {
    return Uint8List.fromList(arr.map((e) => e < 0 ? e + 256 : e).toList());
  }

  Uint8List generateKey(String pwd) {
    final pwdBytes = utf8.encode(pwd);
    final suffix = toUint8([8, 56, -102, -124, 29, -75, -45, 74]);
    final toHash = Uint8List.fromList([...pwdBytes, ...suffix]);
    final digest = sha1.convert(toHash);
    return Uint8List.fromList(digest.bytes.sublist(0, 16));
  }

  encrypt.Encrypter getEncrypter(String pwd) {
    final key = encrypt.Key(generateKey(pwd));
    final iv = encrypt.IV(
      toUint8([
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
      ]),
    );
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cfb64));
  }

  Uint8List encryptBody(String pwd, String data) {
    final encrypter = getEncrypter(pwd);
    return Uint8List.fromList(
      encrypter
          .encrypt(
            data,
            iv: encrypt.IV(
              toUint8([
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
              ]),
            ),
          )
          .bytes,
    );
  }

  Uint8List buildMessage(String cmd, String body, String? code) {
    final prefix = [0x00, 0x00, 0x00, 0x01, 0x00, 0x00];
    final cmdBytes = utf8.encode(cmd);
    Uint8List bodyBytes = utf8.encode(body) as Uint8List;
    if (code != null) {
      bodyBytes = encryptBody(code, body);
    }
    final total = Uint8List.fromList([...prefix, ...cmdBytes, ...bodyBytes]);
    total[4] = total.length;
    return total;
  }

  Uint8List buildRcCodeMessage(String code, int rcCode) {
    const cmd = 'rc-code-reqrc-code-reqrc-code-re';
    final body =
        '{"dev_id":"$devId","dev_descr":"$devDescr","rc_code":$rcCode}';
    return buildMessage(cmd, body, code);
  }

  Uint8List buildConnectMessage() {
    const cmd = 'connect-reqconnect-reqconnect-re';
    final body = '{"dev_id":"$devId","dev_descr":"$devDescr"}';
    return buildMessage(cmd, body, null);
  }

  Uint8List buildPingMessage(String code) {
    const cmd = 'ping-reqping-reqping-reqping-req';
    final body = '{"dev_id":"$devId"}';
    return buildMessage(cmd, body, code);
  }

  Uint8List buildPairRequestMessage() {
    const cmd = 'pairing-reqpairing-reqpairing-re';
    final body = '{"dev_id":"$devId","dev_descr":"$devDescr"}';
    return buildMessage(cmd, body, null);
  }

  Uint8List buildPairCompleteMessage(String code) {
    const cmd = 'pairing-complete-reqpairing-comp';
    final body = '{"dev_id":"$devId","dev_descr":"$devDescr"}';
    return buildMessage(cmd, body, code);
  }

  Future<void> pairDevice(String ip, String code) async {
    final socket = await Socket.connect(ip, port);
    socket.add(buildPairRequestMessage());
    await socket.flush();
    await Future.delayed(Duration(seconds: 1));
    socket.add(buildPairCompleteMessage(code));
    await socket.flush();
    await socket.first;
    await socket.close();
  }

  Future<void> sendRcCode({
    required String ip,
    required String code,
    required int rcCode,
  }) async {
    final socket = await Socket.connect(ip, port);

    // Buffer to collect response
    final responses = <List<int>>[];

    socket.listen(
      (data) {
        responses.add(data);
        print("[RESPONSE] ${utf8.decode(data, allowMalformed: true)}");
      },
      onDone: () => socket.destroy(),
      onError: (e) => print("Socket error: $e"),
      cancelOnError: true,
    );

    socket.add(buildConnectMessage());
    await Future.delayed(
      Duration(milliseconds: 200),
    ); // Give it time to respond

    socket.add(buildPingMessage(code));
    await Future.delayed(Duration(milliseconds: 200));

    socket.add(buildRcCodeMessage(code, rcCode));
    socket.add(buildPingMessage(code));
    await Future.delayed(Duration(milliseconds: 300));

    await socket.close();
  }

  Future<List<String>> scanForSTBs(String subnet) async {
    final List<Future<String?>> futures = [];

    for (int i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      futures.add(_tryConnect(ip));
    }

    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }

  Future<String?> _tryConnect(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        40611,
        timeout: Duration(milliseconds: 300),
      );
      await socket.close();
      return ip;
    } catch (_) {
      return null;
    }
  }
}
