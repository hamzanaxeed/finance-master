// New file: lib/core/storage/storage_utils.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageUtils {
  // SharedPreferences helpers
  static Future<bool> safeSavePrefsString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tmpKey = '${key}_tmp'; // use non-printable prefix to reduce collision chance
      final bakKey = '${key}_bak';
      await prefs.setString(tmpKey, value);
      await prefs.setString(key, value);
      await prefs.setString(bakKey, value);
      await prefs.remove(tmpKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> safeLoadPrefsString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(key);
      if (val != null) return val;
      final bak = prefs.getString('${key}_bak');
      if (bak != null) {
        // restore from backup
        await prefs.setString(key, bak);
        return bak;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> safeSavePrefsDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tmpKey = '\u007f${key}_tmp';
      final bakKey = '${key}_bak';
      await prefs.setDouble(tmpKey, value);
      await prefs.setDouble(key, value);
      // store backup as string to avoid type issues
      await prefs.setString(bakKey, value.toString());
      await prefs.remove(tmpKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<double?> safeLoadPrefsDouble(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getDouble(key);
      if (val != null) return val;
      final bak = prefs.getString('${key}_bak');
      if (bak != null) {
        final parsed = double.tryParse(bak);
        if (parsed != null) {
          await prefs.setDouble(key, parsed);
          return parsed;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> safeSavePrefsBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tmpKey = '\u007f${key}_tmp';
      final bakKey = '${key}_bak';
      await prefs.setBool(tmpKey, value);
      await prefs.setBool(key, value);
      await prefs.setString(bakKey, value ? 'true' : 'false');
      await prefs.remove(tmpKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool?> safeLoadPrefsBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(key);
      if (val != null) return val;
      final bak = prefs.getString('${key}_bak');
      if (bak != null) {
        final restored = bak.toLowerCase() == 'true';
        await prefs.setBool(key, restored);
        return restored;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Secure storage helpers
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<bool> safeSaveSecureString(String key, String value) async {
    try {
      final tmpKey = '\u007f${key}_tmp';
      final bakKey = '${key}_bak';
      await _secure.write(key: tmpKey, value: value);
      await _secure.write(key: key, value: value);
      await _secure.write(key: bakKey, value: value);
      await _secure.delete(key: tmpKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> safeLoadSecureString(String key) async {
    try {
      final val = await _secure.read(key: key);
      if (val != null) return val;
      final bak = await _secure.read(key: '${key}_bak');
      if (bak != null) {
        await _secure.write(key: key, value: bak);
        return bak;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Remove a prefs key and its backup
  static Future<bool> safeRemovePrefsKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('${key}_bak');
      return true;
    } catch (_) {
      return false;
    }
  }

  // Remove a secure storage key and its backup
  static Future<bool> safeRemoveSecureKey(String key) async {
    try {
      await _secure.delete(key: key);
      await _secure.delete(key: '${key}_bak');
      return true;
    } catch (_) {
      return false;
    }
  }
}
