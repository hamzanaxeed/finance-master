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
import 'dart:io';

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


  // Certain prefs are stored as non-string types; handle them explicitly
  static bool _isBoolKey(String k) => k == 'biometric_enabled';
  static bool _isDoubleKey(String k) => k == 'portfolio_cash_balance';

  static Future<dynamic> _loadPrefValue(String k) async {
    if (_isBoolKey(k)) return await StorageUtils.safeLoadPrefsBool(k);
    if (_isDoubleKey(k)) return await StorageUtils.safeLoadPrefsDouble(k);
    final s = await StorageUtils.safeLoadPrefsString(k);
    if (s == null) return null;
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }

  static Future<bool> _savePrefValue(String k, dynamic v) async {
    if (v == null) return await StorageUtils.safeRemovePrefsKey(k);
    if (_isBoolKey(k)) {
      if (v is bool) return await StorageUtils.safeSavePrefsBool(k, v);
      // attempt to coerce
      if (v is String) return await StorageUtils.safeSavePrefsBool(k, v.toLowerCase() == 'true');
      return await StorageUtils.safeSavePrefsBool(k, v == true);
    }
    if (_isDoubleKey(k)) {
      if (v is num) return await StorageUtils.safeSavePrefsDouble(k, v.toDouble());
      if (v is String) return await StorageUtils.safeSavePrefsDouble(k, double.tryParse(v) ?? 0.0);
      return await StorageUtils.safeSavePrefsDouble(k, 0.0);
    }
    // default: store JSON string
    return await StorageUtils.safeSavePrefsString(k, jsonEncode(v));
  }

  static Future<bool> _saveSecureValue(String k, dynamic v) async {
    if (v == null) return await StorageUtils.safeRemoveSecureKey(k);
    return await StorageUtils.safeSaveSecureString(k, jsonEncode(v));
  }

  static Future<Map<String, dynamic>> _collectPayload() async {
    final Map<String, dynamic> payload = {};
    for (final k in _prefsKeys) {
      final v = await _loadPrefValue(k);
      payload[k] = v;
    }
    final Map<String, dynamic> securePayload = {};
    for (final k in _secureKeys) {
      final s = await StorageUtils.safeLoadSecureString(k);
      securePayload[k] = s == null ? null : jsonDecode(s);
    }
    return {'prefs': payload, 'secure': securePayload};
  }

  // Export all data into an encrypted file. Returns the saved file path or null on cancel/failure.
  static Future<String?> exportEncryptedBackup(String passphrase, {String? suggestedFileName}) async {
    if (passphrase.isEmpty) throw ArgumentError('Passphrase required');

    final collected = await _collectPayload();
    final full = {'prefs': collected['prefs'], 'secure': collected['secure'], 'meta': {'exportedAt': DateTime.now().toIso8601String()}};
    final plain = utf8.encode(jsonEncode(full));

    final salt = _randomBytes(16);
    final key = _deriveKey(passphrase, salt, iterations: 100000, keyLen: 32);
    final iv = _randomBytes(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(encrypt_pkg.Key(Uint8List.fromList(key)), mode: encrypt_pkg.AESMode.cbc));
    final enc = encrypter.encryptBytes(plain, iv: encrypt_pkg.IV(iv));
    final pkg = {'version': 1, 'salt': base64Encode(salt), 'iv': base64Encode(iv), 'cipher': base64Encode(enc.bytes)};
    final bytes = utf8.encode(jsonEncode(pkg));

    // Determine Downloads directory (only) and write file there
    final saveName = suggestedFileName ?? 'wealthtracker_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.wtb';
    Directory? downloadsDir;
    try {
      downloadsDir = await getDownloadsDirectory();
    } catch (_) {
      downloadsDir = null;
    }

    if (downloadsDir == null) {
      try {
        final ex = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (ex != null && ex.isNotEmpty) downloadsDir = ex.first;
      } catch (_) {
        downloadsDir = null;
      }
    }

    if (downloadsDir == null && Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    }

    if (downloadsDir == null) {
      throw UnsupportedError('Could not determine downloads directory on this platform');
    }

    // Best-effort: remove previous backups created by this app so only one backup file remains
    try {
      await for (final ent in downloadsDir.list(recursive: false, followLinks: false)) {
        if (ent is File) {
          final name = ent.uri.pathSegments.isNotEmpty ? ent.uri.pathSegments.last : '';
          if (name.startsWith('wealthtracker_backup_') && (name.endsWith('.wtb') || name.endsWith('.json'))) {
            try {
              await ent.delete();
            } catch (_) {
              // ignore individual delete failures
            }
          }
        }
      }
    } catch (_) {
      // ignore listing/deletion failures
    }

    final path = '${downloadsDir.path}/$saveName';
    final file = await _writeFileBytes(path, bytes);
    return file.path;
  }

  // Export to app documents directory using a generated filename (for automatic backups)
  static Future<String> exportToAppDirectory(String passphrase, {String? suggestedFileName}) async {
    if (passphrase.isEmpty) throw ArgumentError('Passphrase required');
    final saveName = suggestedFileName ?? 'wealthtracker_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.wtb';
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$saveName';

    final collected = await _collectPayload();
    final full = {'prefs': collected['prefs'], 'secure': collected['secure'], 'meta': {'exportedAt': DateTime.now().toIso8601String()}};
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

  // Export encrypted backup directly to the user's Downloads folder.
  // Attempts getDownloadsDirectory(), then external storage downloads on Android, then fallback path.
  static Future<String> exportToDownloads(String passphrase, {String? suggestedFileName}) async {
    if (passphrase.isEmpty) throw ArgumentError('Passphrase required');
    final saveName = suggestedFileName ?? 'wealthtracker_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.wtb';

    Directory? downloadsDir;
    try {
      downloadsDir = await getDownloadsDirectory(); // desktop
    } catch (_) {
      downloadsDir = null;
    }

    if (downloadsDir == null) {
      // try external storage downloads on Android
      try {
        final ex = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (ex != null && ex.isNotEmpty) {
          downloadsDir = ex.first;
        }
      } catch (_) {
        downloadsDir = null;
      }
    }

    // Android common fallback
    if (downloadsDir == null && Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    }

    if (downloadsDir == null) {
      throw UnsupportedError('Could not determine downloads directory on this platform');
    }

    final path = '${downloadsDir.path}/$saveName';

    final collected = await _collectPayload();
    final full = {'prefs': collected['prefs'], 'secure': collected['secure'], 'meta': {'exportedAt': DateTime.now().toIso8601String()}};
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
      await _savePrefValue(k, v);
    }

    for (final entry in secureMap.entries) {
      final k = entry.key;
      final v = entry.value;
      await _saveSecureValue(k, v);
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

  // Export encrypted backup as a JSON string (not bytes) suitable for copying to clipboard
  static Future<String> exportEncryptedBackupAsText(String passphrase) async {
    if (passphrase.isEmpty) throw ArgumentError('Passphrase required');

    final collected = await _collectPayload();
    final full = {'prefs': collected['prefs'], 'secure': collected['secure'], 'meta': {'exportedAt': DateTime.now().toIso8601String()}};
    final plain = utf8.encode(jsonEncode(full));

    final salt = _randomBytes(16);
    final key = _deriveKey(passphrase, salt, iterations: 100000, keyLen: 32);
    final iv = _randomBytes(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(encrypt_pkg.Key(Uint8List.fromList(key)), mode: encrypt_pkg.AESMode.cbc));
    final enc = encrypter.encryptBytes(plain, iv: encrypt_pkg.IV(iv));

    final pkg = {
      'version': 1,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'cipher': base64Encode(enc.bytes),
    };

    return jsonEncode(pkg);
  }

  // Import an encrypted backup from a JSON string (e.g. pasted from clipboard)
  static Future<Map<String, dynamic>> importEncryptedBackupFromText(String text, String passphrase) async {
    if (passphrase.isEmpty) throw ArgumentError('Passphrase required');
    try {
      if (kIsWeb) throw UnsupportedError('Import not supported on web');
      final pkg = jsonDecode(text) as Map<String, dynamic>;
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

  // Validate an exported/imported payload contains expected keys and report basic counts for lists
  static Map<String, dynamic> validateBackupPayload(Map<String, dynamic> payload) {
    final res = <String, dynamic>{};
    final prefs = payload['prefs'] as Map<String, dynamic>? ?? {};
    final secure = payload['secure'] as Map<String, dynamic>? ?? {};
    final missing = <String>[];
    for (final k in _prefsKeys) {
      if (!prefs.containsKey(k)) missing.add(k);
    }
    for (final k in _secureKeys) {
      if (!secure.containsKey(k)) missing.add(k);
    }
    res['missingKeys'] = missing;
    // counts
    final counts = <String, int>{};
    prefs.forEach((k, v) {
      if (v is List) counts[k] = v.length;
      else counts[k] = v == null ? 0 : 1;
    });
    res['counts'] = counts;
    return res;
  }
}

// File IO helpers using dart:io
Future<File> _writeFileBytes(String path, List<int> bytes) async {
  final f = File(path);
  await f.create(recursive: true);
  await f.writeAsBytes(bytes, flush: true);
  return f;
}

Future<List<int>> _readFileBytes(String path) async {
  final f = File(path);
  return await f.readAsBytes();
}
