import 'dart:convert';

import 'package:ninja_openssl/ninja_openssl.dart';

Future<void> main() async {
  final key = '000102030405060708090a0b0c0d0e0f';
  final iv = '3ffabe88d6a25a9f4ce3141a1e388ab6';
  final encodedBytes = await encryptAES128CTR(key, iv, 'Dart');
  print(base64Encode(encodedBytes));
  final decodedBytes = await decryptAES128CTR(key, iv, encodedBytes);
  print(utf8.decode(decodedBytes));
}
