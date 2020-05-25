# ninja openssl

Dart library to encrypt and sign using openssl.

# Usage

## RSA PSS signature and verification

```dart
  final message = 'hello world!\n';
  final signature = await signRsaPssBase64(privateKey, message);
  print(signature);
  await verifyRsaPss(publicKey, signature, 'hello world!\n');
```