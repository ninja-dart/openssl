import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class Digest {
  final String name;

  const Digest(this.name);

  static const sha256 = Digest('sha256');
}

/// openssl dgst -sha256 -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:10 -sign myprivate.pem <(echo 'hello world!')
Future<List<int>> signRsaPss(String privateKey, String message,
    {Digest digest = Digest.sha256, int saltLength = 20}) async {
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
        'rsa_padding_mode:pss',
        '-sigopt',
        'rsa_pss_saltlen:${saltLength}',
        '-sign',
        '$privateKeyPath',
        '$messagePath'
      ],
      stdoutEncoding: null,
      includeParentEnvironment: true,
      runInShell: true);

  if (res.exitCode != 0) {
    print(res.stderr);
    await tempDir.delete(recursive: true);
    throw Exception(
        'openssl failed with exitCode: ${res.exitCode}'); // TODO better exception
  }

  await tempDir.delete(recursive: true);

  return res.stdout;
}

Future<String> signRsaPssBase64(String privateKey, String message,
    {Digest digest = Digest.sha256, int saltLength = 20}) async {
  return base64Encode(await signRsaPss(privateKey, message,
      digest: digest, saltLength: saltLength));
}

/// openssl dgst -sha256 -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:10 -sign myprivate.pem <(echo 'hello world!')
Future<bool> verifyRsaPss(String publicKey, signature, message,
    {Digest digest = Digest.sha256,
    int saltLength = 20,
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
        'rsa_padding_mode:pss',
        '-sigopt',
        'rsa_pss_saltlen:${saltLength}',
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

class OpensslException implements Exception {
  final int exitCode;

  final String stdout;

  final String stderr;

  OpensslException(this.exitCode, this.stdout, this.stderr);

  @override
  String toString() {
    final sb = StringBuffer();

    sb.writeln('Openssl failed with exitCode: $exitCode');
    sb.writeln('Stdout: $stdout');
    sb.writeln('Stderr: $stderr');

    return sb.toString();
  }
}
