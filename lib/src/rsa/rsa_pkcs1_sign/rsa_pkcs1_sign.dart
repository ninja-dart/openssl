import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:ninja_openssl/ninja_openssl.dart';

Future<List<int>> signRsaPkcs1(String privateKey, String message,
    {HashName digest = HashName.sha256}) async {
  final tempDir = await Directory.systemTemp.createTemp();
  final privateKeyPath = path.join(tempDir.path, 'privatekey.pem');
  final f =
      await File(privateKeyPath).writeAsString(privateKey, encoding: utf8);
  final messagePath = path.join(tempDir.path, 'message.txt');
  await File(messagePath).writeAsString(message, encoding: utf8);

  final res = await Process.run(
      'openssl',
      [
        'dgst',
        '-${digest.name}',
        '-sigopt',
        'rsa_padding_mode:pkcs1',
        '-sign',
        '$privateKeyPath',
        '$messagePath'
      ],
      stdoutEncoding: null,
      includeParentEnvironment: true,
      runInShell: true);

  if (res.exitCode != 0) {
    await tempDir.delete(recursive: true);
    throw OpensslException(
        res.exitCode, systemEncoding.decode(res.stdout), res.stderr);
  }

  await tempDir.delete(recursive: true);

  return res.stdout;
}

Future<bool> verifyRsaPkcs1(String publicKey, signature, message,
    {HashName digest = HashName.sha256,
    bool cleanupTempDirectory = true}) async {
  if (signature is String) {
    signature = base64Decode(signature);
  }
  if (message is String) {
    message = utf8.encode(message);
  }

  final tempDir = await Directory.systemTemp.createTemp();
  final publicKeyPath = path.join(tempDir.path, 'publickey.pem');
  await File(publicKeyPath).writeAsString(publicKey, encoding: utf8);
  final signaturePath = path.join(tempDir.path, 'signature.txt');
  await File(signaturePath).writeAsBytes(signature);
  final messagePath = path.join(tempDir.path, 'message.txt');
  await File(messagePath).writeAsBytes(message);

  final res = await Process.run(
      'openssl',
      [
        'dgst',
        '-${digest.name}',
        '-sigopt',
        'rsa_padding_mode:pkcs1',
        '-verify',
        publicKeyPath,
        '-signature',
        signaturePath,
        messagePath
      ],
      includeParentEnvironment: true,
      runInShell: true);

  if (res.exitCode != 0) {
    if (res.stdout == 'Verification Failure\n') {
      return false;
    }
    await tempDir.delete(recursive: true);
    throw OpensslException(res.exitCode, res.stdout, res.stderr);
  }

  if (cleanupTempDirectory) {
    await tempDir.delete(recursive: true);
  }

  return res.stdout == 'Verified OK\n';
}
