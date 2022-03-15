import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// echo -n 'Dart' | openssl enc -aes-128-ctr -e -K 000102030405060708090a0b0c0d0e0f -iv 3ffabe88d6a25a9f4ce3141a1e388ab6 -nopad -nosalt
Future<Uint8List> encryptAES128CTR(/* String | Uint8List */ key,
    /* String | Uint8List */ iv, /* String | Uint8List */ message) async {
  if (message is String) {
    message = utf8.encode(message);
  }
  if(key is Iterable<int>) {
    // TODO
  }

  final process = await Process.start(
      'openssl',
      [
        'enc',
        '-aes-128-ctr',
        '-e',
        '-nopad',
        '-nosalt',
        '-K',
        '000102030405060708090a0b0c0d0e0f', // TODO salt
        '-iv',
        '3ffabe88d6a25a9f4ce3141a1e388ab6'// TODO iv
      ],
      includeParentEnvironment: true,
      runInShell: true);
  process.stdin.add(message);
  await process.stdin.flush();
  await process.stdin.close();
  int exitCode = await process.exitCode;
  if (exitCode != 0) {
    // TODO include stderr
    throw Exception('openssl error!');
  }

  return Uint8List.fromList(await process.stdout.fold<List<int>>(<int>[],
      (List<int> previous, List<int> element) => previous..addAll(element)));
}
