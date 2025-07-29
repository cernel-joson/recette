import 'dart:convert';
import 'package:crypto/crypto.dart';

// This abstract class defines the "contract" for any object
// that wants to be able to generate a unique fingerprint.
abstract class Fingerprintable {
  /// A getter that must be implemented by any class that wants to be
  /// fingerprintable. It should return a consistent, unique string
  /// representation of the object's core content.
  String get fingerprintableString;
}

/// A centralized helper class for generating SHA-256 fingerprints.
class FingerprintHelper {
  /// Generates a SHA-256 hash for any object that implements Fingerprintable.
  ///
  /// This centralizes the hashing logic, so we don't repeat the
  /// crypto code in multiple places.
  static String generate(Fingerprintable item) {
    // 1. Get the unique string from the object.
    final uniqueString = item.fingerprintableString;

    // 2. Convert the string to a list of bytes using UTF-8 encoding.
    final bytes = utf8.encode(uniqueString);

    // 3. Use the SHA-256 algorithm to create a digest (a hash) of the bytes.
    final digest = sha256.convert(bytes);

    // 4. Return the hexadecimal string representation of the digest.
    return digest.toString();
  }
}