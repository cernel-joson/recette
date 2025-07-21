import 'dart:convert'; // Required for utf8 encoding
import 'package:crypto/crypto.dart'; // Required for SHA256 hashing

/// Generates a SHA-256 hash "fingerprint" for a given string.
///
/// This is used to create a unique and consistent identifier for the user's
/// dietary profile. If the profile text changes in any way, the resulting
/// fingerprint will also change, allowing us to detect when cached health
/// ratings have become stale.
///
/// [profileText] The string content to be hashed, such as the user's health rules.
/// Returns a hexadecimal string representation of the SHA-256 hash.
String generateProfileFingerprint(String profileText) {
  // 1. Convert the input string into a list of bytes using UTF-8 encoding.
  //    This is a standard way to ensure consistency across all systems.
  var bytes = utf8.encode(profileText);

  // 2. Use the sha256 algorithm from the crypto package to create a digest
  //    (a fixed-size representation) of the bytes.
  var digest = sha256.convert(bytes);

  // 3. Convert the digest to a hexadecimal string, which is the common
  //    format for representing hashes.
  return digest.toString();
}