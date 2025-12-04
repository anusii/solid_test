/// DPoP (Demonstrating Proof of Possession) utilities.
///
/// Generates RSA keypairs for DPoP token signing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

/// Generates an RSA keypair for DPoP token generation.
///
/// Returns a map containing:
/// - 'rsa': AsymmetricKeyPair object (from pointycastle)
/// - 'pubKeyJwk': Public key in JWK format
/// - 'prvKeyJwk': Private key in JWK format
Future<Map<String, dynamic>> generateRsaKeyPair() async {
  // Generate 2048-bit RSA keypair using pointycastle.
  final keyGen = RSAKeyGenerator()
    ..init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        FortunaRandom()..seed(KeyParameter(_generateRandomBytes(32))),
      ),
    );

  final keyPair = keyGen.generateKeyPair();
  final publicKey = keyPair.publicKey;
  final privateKey = keyPair.privateKey;

  // Convert to JWK format.
  final publicKeyJwk = _rsaPublicKeyToJwk(publicKey);
  final privateKeyJwk = _rsaPrivateKeyToJwk(privateKey);

  // Add algorithm.
  publicKeyJwk['alg'] = 'RS256';
  privateKeyJwk['alg'] = 'RS256';

  return {
    'rsa': keyPair,
    'pubKeyJwk': publicKeyJwk,
    'prvKeyJwk': privateKeyJwk,
  };
}

/// Generates random bytes for seeding the random number generator.
Uint8List _generateRandomBytes(int length) {
  final random = Random.secure();
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

/// Converts an RSA public key to JWK format.
Map<String, dynamic> _rsaPublicKeyToJwk(RSAPublicKey publicKey) {
  return {
    'kty': 'RSA',
    'n': _base64UrlEncode(publicKey.modulus!),
    'e': _base64UrlEncode(publicKey.exponent!),
  };
}

/// Converts an RSA private key to JWK format.
Map<String, dynamic> _rsaPrivateKeyToJwk(RSAPrivateKey privateKey) {
  return {
    'kty': 'RSA',
    'n': _base64UrlEncode(privateKey.modulus!),
    'e': _base64UrlEncode(privateKey.exponent!),
    'd': _base64UrlEncode(privateKey.privateExponent!),
    'p': _base64UrlEncode(privateKey.p!),
    'q': _base64UrlEncode(privateKey.q!),
  };
}

/// Encodes a BigInt to base64url format for JWK.
String _base64UrlEncode(BigInt value) {
  final bytes = _bigIntToBytes(value);
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Converts a BigInt to bytes.
Uint8List _bigIntToBytes(BigInt value) {
  final hex = value.toRadixString(16);
  final paddedHex = hex.length.isOdd ? '0$hex' : hex;
  final bytes = Uint8List(paddedHex.length ~/ 2);
  for (var i = 0; i < paddedHex.length; i += 2) {
    bytes[i ~/ 2] = int.parse(paddedHex.substring(i, i + 2), radix: 16);
  }
  return bytes;
}

/// Serializes an RSA public key to PEM format.
String serializePublicKey(RSAPublicKey publicKey) {
  final algorithmSeq = ASN1Sequence();
  // OID for rsaEncryption: 1.2.840.113549.1.1.1
  algorithmSeq.add(ASN1ObjectIdentifier([1, 2, 840, 113549, 1, 1, 1]));
  algorithmSeq.add(ASN1Null());

  final publicKeySeq = ASN1Sequence();
  publicKeySeq.add(ASN1Integer(publicKey.modulus!));
  publicKeySeq.add(ASN1Integer(publicKey.exponent!));

  final publicKeyBitString = ASN1BitString(publicKeySeq.encodedBytes);

  final topLevelSeq = ASN1Sequence();
  topLevelSeq.add(algorithmSeq);
  topLevelSeq.add(publicKeyBitString);

  final dataBase64 = base64.encode(topLevelSeq.encodedBytes);
  final chunks = <String>[];
  for (var i = 0; i < dataBase64.length; i += 64) {
    final end = (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length;
    chunks.add(dataBase64.substring(i, end));
  }

  return '-----BEGIN PUBLIC KEY-----\n${chunks.join('\n')}\n-----END PUBLIC KEY-----';
}

/// Serializes an RSA private key to PEM format.
String serializePrivateKey(RSAPrivateKey privateKey) {
  final version = ASN1Integer(BigInt.zero);
  final modulus = ASN1Integer(privateKey.modulus!);
  final publicExponent = ASN1Integer(privateKey.exponent!);
  final privateExponent = ASN1Integer(privateKey.privateExponent!);
  final p = ASN1Integer(privateKey.p!);
  final q = ASN1Integer(privateKey.q!);

  final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
  final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
  final iQ = privateKey.q!.modInverse(privateKey.p!);

  final seq = ASN1Sequence();
  seq.add(version);
  seq.add(modulus);
  seq.add(publicExponent);
  seq.add(privateExponent);
  seq.add(p);
  seq.add(q);
  seq.add(ASN1Integer(dP));
  seq.add(ASN1Integer(dQ));
  seq.add(ASN1Integer(iQ));

  final dataBase64 = base64.encode(seq.encodedBytes);
  final chunks = <String>[];
  for (var i = 0; i < dataBase64.length; i += 64) {
    final end = (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length;
    chunks.add(dataBase64.substring(i, end));
  }

  return '-----BEGIN PRIVATE KEY-----\n${chunks.join('\n')}\n-----END PRIVATE KEY-----';
}
