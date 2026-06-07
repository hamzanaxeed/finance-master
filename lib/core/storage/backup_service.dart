// New file: lib/core/storage/backup_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart' as crypto;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'storage_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

class BackupService {
  // Keys used in app storage
  static const _prefsKeys = <String>[
    'accounts',
    'transactions',
    'transaction_categories_v2',
    'stock_transactions',
    'dividends',
    'corporate_actions',
    'price_history',
    'holding_meta',
    'portfolio_cash_balance',
    'portfolio_transfers',
    'app_notes',
    'biometric_enabled',
  ];

  static const _secureKeys = <String>[
    'password_entries',
  ];

  // Export all data into an encrypted file. Returns the saved file path or null on cancel/failure.
  static Future<String?> exportEncryptedBackup(String passphrase, {String? suggestedFileName}) async {
    if (passphrase.isEmpty) throw ArgumentError('Passphrase required');

    // Collect all data
    final Map<String, dynamic> payload = {};

    for (final k in _prefsKeys) {
      final v = await StorageUtils.safeLoadPrefsString(k);
      payload[k] = v == null ? null : jsonDecode(v);
    }

    final Map<String, dynamic> securePayload = {};
    for (final k in _secureKeys) {
      final v = await StorageUtils.safeLoadSecureString(k);
      securePayload[k] = v == null ? null : jsonDecode(v);
    }

    final full = {'prefs': payload, 'secure': securePayload, 'meta': {'exportedAt': DateTime.now().toIso8601String()}};
    final plain = utf8.encode(jsonEncode(full));

    // Derive key from passphrase using PBKDF2
    final salt = _randomBytes(16);
    final key = _deriveKey(passphrase, salt, iterations: 100000, keyLen: 32);

    // Encrypt using AES CBC with random IV
    final iv = _randomBytes(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(encrypt_pkg.Key(Uint8List.fromList(key)), mode: encrypt_pkg.AESMode.cbc));
    final enc = encrypter.encryptBytes(plain, iv: encrypt_pkg.IV(iv));

    // Build export package
    final pkg = {
      'version': 1,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'cipher': base64Encode(enc.bytes),
    };

    final bytes = utf8.encode(jsonEncode(pkg));

    // Ask user for save location
    try {
      final saveName = suggestedFileName ?? 'wealthtracker_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.wtb';
      final filePath = await FilePicker.platform.saveFile(dialogTitle: 'Save backup file', fileName: saveName, type: FileType.custom, allowedExtensions: ['wtb', 'json']);
      if (filePath == null) return null; // user cancelled

      // write bytes to file
      if (!kIsWeb) {
        final ioFile = await _writeFileBytes(filePath, bytes);
        return ioFile.path;
      } else {
        throw UnsupportedError('Export not supported on web');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Export to app documents directory using a generated filename (for automatic backups)
  static Future<String> exportToAppDirectory(String passphrase, {String? suggestedFileName}) async {
    if (passphrase.isEmpty) throw ArgumentError('Passphrase required');
    final saveName = suggestedFileName ?? 'wealthtracker_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.wtb';
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$saveName';

    // reuse export logic but write to path
    // Collect data
    final Map<String, dynamic> payload = {};
    for (final k in _prefsKeys) {
      final v = await StorageUtils.safeLoadPrefsString(k);
      payload[k] = v == null ? null : jsonDecode(v);
    }
    final Map<String, dynamic> securePayload = {};
    for (final k in _secureKeys) {
      final v = await StorageUtils.safeLoadSecureString(k);
      securePayload[k] = v == null ? null : jsonDecode(v);
    }
    final full = {'prefs': payload, 'secure': securePayload, 'meta': {'exportedAt': DateTime.now().toIso8601String()}};
    final plain = utf8.encode(jsonEncode(full));

    final salt = _randomBytes(16);
    final key = _deriveKey(passphrase, salt, iterations: 100000, keyLen: 32);
    final iv = _randomBytes(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(encrypt_pkg.Key(Uint8List.fromList(key)), mode: encrypt_pkg.AESMode.cbc));
    final enc = encrypter.encryptBytes(plain, iv: encrypt_pkg.IV(iv));
    final pkg = {'version': 1, 'salt': base64Encode(salt), 'iv': base64Encode(iv), 'cipher': base64Encode(enc.bytes)};
    final bytes = utf8.encode(jsonEncode(pkg));

    final ioFile = await _writeFileBytes(path, bytes);
    return ioFile.path;
  }

  // Import encrypted backup: returns parsed payload map on success
  static Future<Map<String, dynamic>> importEncryptedBackupFromPath(String filePath, String passphrase) async {
    if (passphrase.isEmpty) throw ArgumentError('Passphrase required');
    try {
      if (kIsWeb) throw UnsupportedError('Import not supported on web');
      final bytes = await _readFileBytes(filePath);
      final pkg = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final salt = base64Decode(pkg['salt'] as String);
      final iv = base64Decode(pkg['iv'] as String);
      final cipher = base64Decode(pkg['cipher'] as String);

      final key = _deriveKey(passphrase, salt, iterations: 100000, keyLen: 32);
      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(encrypt_pkg.Key(Uint8List.fromList(key)), mode: encrypt_pkg.AESMode.cbc));
      final decrypted = encrypter.decryptBytes(encrypt_pkg.Encrypted(Uint8List.fromList(cipher)), iv: encrypt_pkg.IV(iv));

      final decoded = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      rethrow;
    }
  }

  // Apply the imported data to local storage. Overwrites existing keys.
  static Future<void> applyImportedBackup(Map<String, dynamic> imported) async {
    final prefsMap = imported['prefs'] as Map<String, dynamic>;
    final secureMap = imported['secure'] as Map<String, dynamic>;

    for (final entry in prefsMap.entries) {
      final k = entry.key;
      final v = entry.value;
      if (v == null) {
        // remove key if exists by setting empty
        await StorageUtils.safeSavePrefsString(k, jsonEncode(null));
      } else {
        await StorageUtils.safeSavePrefsString(k, jsonEncode(v));
      }
    }

    for (final entry in secureMap.entries) {
      final k = entry.key;
      final v = entry.value;
      if (v == null) {
        await StorageUtils.safeSaveSecureString(k, jsonEncode(null));
      } else {
        await StorageUtils.safeSaveSecureString(k, jsonEncode(v));
      }
    }
  }

  // Helpers
  static Uint8List _randomBytes(int len) {
    final rnd = Random.secure();
    final list = List<int>.generate(len, (_) => rnd.nextInt(256));
    return Uint8List.fromList(list);
  }

  static List<int> _deriveKey(String passphrase, Uint8List salt, {int iterations = 100000, int keyLen = 32}) {
    // PBKDF2-HMAC-SHA256 implementation
    final passBytes = utf8.encode(passphrase);
    final hmac = (List<int> data) => crypto.Hmac(crypto.sha256, passBytes).convert(data).bytes;
    final hashLen = 32; // SHA256 output
    final blocks = (keyLen + hashLen - 1) ~/ hashLen;
    final out = <int>[];

    for (var i = 1; i <= blocks; i++) {
      // salt || INT(i)
      final block = <int>[];
      block.addAll(salt);
      block.addAll(_int32BE(i));

      var u = hmac(block);
      final t = u.toList();
      for (var j = 1; j < iterations; j++) {
        u = hmac(u);
        for (var k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }
      out.addAll(t);
    }

    return out.sublist(0, keyLen);
  }

  static List<int> _int32BE(int i) {
    return [(i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff];
  }

  // Let user pick a backup file (path) for import
  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['wtb', 'json']);
    if (result == null || result.files.isEmpty) return null;
    return result.files.first.path;
  }
}

// File IO helpers using dart:io
Future<io.File> _writeFileBytes(String path, List<int> bytes) async {
  final f = io.File(path);
  await f.create(recursive: true);
  await f.writeAsBytes(bytes, flush: true);
  return f;
}

Future<List<int>> _readFileBytes(String path) async {
  final f = io.File(path);
  return await f.readAsBytes();
}
