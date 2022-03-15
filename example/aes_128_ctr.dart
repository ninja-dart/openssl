import 'dart:convert';

import 'package:ninja_openssl/ninja_openssl.dart';

Future<void> main() async {
  final encodedBytes = await encryptAES128CTR('000102030405060708090a0b0c0d0e0f',
      '3ffabe88d6a25a9f4ce3141a1e388ab6', 'Dart');
  print(base64Encode(encodedBytes));
}
