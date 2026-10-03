import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/password_entry.dart';
import '../../core/storage/storage_utils.dart';

class PasswordsNotifier extends StateNotifier<List<PasswordEntry>> {
  static const _key = 'password_entries';
  // secure storage for sensitive password data
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  PasswordsNotifier() : super([]) {
    _load();
  }

  Future<void> add(PasswordEntry entry) async {
    state = [...state, entry];
    await _save();
  }

  Future<void> update(String id, PasswordEntry entry) async {
    state = [for (final e in state) if (e.id == id) entry else e];
    await _save();
  }

  Future<void> delete(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final jsonList = state.map((e) => e.toJson()).toList();
    await StorageUtils.safeSaveSecureString(_key, jsonEncode(jsonList));
  }

  Future<void> _load() async {
    final raw = await StorageUtils.safeLoadSecureString(_key);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }

  // Public reload helper used after importing backups
  Future<void> reload() async => _load();

  // Export stored password entries as JSON string (encrypted storage still used for persistence)
  Future<String> exportJson() async {
    final jsonList = state.map((e) => e.toJson()).toList();
    return jsonEncode(jsonList);
  }

  // Import entries from a JSON payload. This will replace existing entries.
  Future<void> importJson(String jsonPayload) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonPayload) as List<dynamic>;
      state = decoded.map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>)).toList();
      await _save();
    } catch (e) {
      rethrow;
    }
  }

  // Export as CSV
  Future<String> exportCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('id,appName,username,email,password,note,createdAt');
    for (final e in state) {
      final app = e.appName.replaceAll('"', '""');
      final user = e.username.replaceAll('"', '""');
      final email = e.email.replaceAll('"', '""');
      final pass = e.password.replaceAll('"', '""');
      final note = (e.note ?? '').replaceAll('"', '""');
      buffer.writeln('"${e.id}","$app","$user","$email","$pass","$note","${e.createdAt.toIso8601String()}"');
    }
    return buffer.toString();
  }

  // Import CSV (naive parser expecting quoted CSV rows matching export format)
  Future<void> importCsv(String csv) async {
    final lines = csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    if (lines.first.toLowerCase().contains('id') && lines.first.toLowerCase().contains('appname')) {
      lines.removeAt(0);
    }
    final List<PasswordEntry> parsed = [];
    final regex = RegExp(r'"(.*?)",?"(.*?)",?"(.*?)",?"(.*?)",?"(.*?)",?"(.*?)",?"(.*?)"');
    for (final line in lines) {
      final m = regex.firstMatch(line);
      if (m != null) {
        final id = m.group(1)!;
        final app = m.group(2)!.replaceAll('""', '"');
        final user = m.group(3)!.replaceAll('""', '"');
        final email = m.group(4)!.replaceAll('""', '"');
        final pass = m.group(5)!.replaceAll('""', '"');
        final note = m.group(6)!.replaceAll('""', '"');
        final created = DateTime.parse(m.group(7)!);
        parsed.add(PasswordEntry(id: id, appName: app, username: user, email: email, password: pass, note: note.isEmpty ? null : note, createdAt: created));
      }
    }
    if (parsed.isNotEmpty) {
      state = parsed;
      await _save();
    }
  }
}

final passwordsProvider = StateNotifierProvider<PasswordsNotifier, List<PasswordEntry>>((ref) => PasswordsNotifier());
