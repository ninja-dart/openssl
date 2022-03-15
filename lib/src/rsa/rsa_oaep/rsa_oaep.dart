import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import 'package:ninja_openssl/ninja_openssl.dart';

/// openssl pkeyutl -decrypt -pkeyopt rsa_padding_mode:oaep -in hello.encrypted -inkey myprivate.pem
/// openssl rsautl -decrypt -oaep -in encrypted.dat -inkey privatekey.pem
Future<Uint8List> decryptRsaOaep(String privateKey, message,
    {HashName digest = HashName.sha256,
      bool cleanupTempDirectory = true}) async {
  if(message is String) {
    message = base64Decode(message);
  }

  final tempDir = await Directory.systemTemp.createTemp();
  final privateKeyPath = path.join(tempDir.path, 'privatekey.pem');
  await File(privateKeyPath).writeAsString(privateKey, encoding: utf8);
  final messagePath = path.join(tempDir.path, 'encrypted.dat');
  await File(messagePath).writeAsBytes(message);

  // TODO digest
  // TODO MGF digest
  final res = await Process.run(
      'openssl',
      [
        'pkeyutl',
        '-decrypt',
        '-pkeyopt',
        'rsa_padding_mode:oaep',
        '-in',
        messagePath,
        '-inkey',
        '$privateKeyPath',
      ],
      stdoutEncoding: null,
      includeParentEnvironment: true,
      runInShell: true);

  if (res.exitCode != 0) {
    if(cleanupTempDirectory) {
      await tempDir.delete(recursive: true);
    }
    throw OpensslException(
        res.exitCode, systemEncoding.decode(res.stdout), res.stderr);
  }

  if(cleanupTempDirectory) {
    await tempDir.delete(recursive: true);
  }

  return Uint8List.fromList(res.stdout);
}

/// openssl pkeyutl -encrypt -pkeyopt rsa_padding_mode:oaep -in hello.txt -pubin -inkey publickey.pem
/// openssl rsautl -encrypt -oaep -in message.txt -pubin -inkey publickey.pem
Future<Uint8List> encryptRsaOaep(String publicKey, message,
    {HashName digest = HashName.sha256,
    bool cleanupTempDirectory = true}) async {
  if (message is String) {
    message = utf8.encode(message);
  }

  final tempDir = await Directory.systemTemp.createTemp();
  final publicKeyPath = path.join(tempDir.path, 'publickey.pem');
  await File(publicKeyPath).writeAsString(publicKey, encoding: utf8);
  final messagePath = path.join(tempDir.path, 'message.txt');
  await File(messagePath).writeAsBytes(message);

  // TODO digest
  // TODO MGF digest
  final res = await Process.run(
      'openssl',
      [
        'pkeyutl',
        '-encrypt',
        '-pkeyopt',
        'rsa_padding_mode:oaep',
        '-in',
        messagePath,
        '-pubin',
        '-inkey',
        publicKeyPath,
      ],
      stdoutEncoding: null,
      includeParentEnvironment: true,
      runInShell: true);

  if (res.exitCode != 0) {
    if (cleanupTempDirectory) {
      await tempDir.delete(recursive: true);
    }
    throw OpensslException(res.exitCode, res.stdout, res.stderr);
  }

  if (cleanupTempDirectory) {
    await tempDir.delete(recursive: true);
  }

  return Uint8List.fromList(res.stdout);
}
