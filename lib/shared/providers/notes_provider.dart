import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_utils.dart';
import 'dart:convert';
import '../models/note.dart';

class NotesNotifier extends StateNotifier<List<NoteItem>> {
  static const _key = 'app_notes';

  NotesNotifier() : super([]) {
    _load();
  }

  Future<void> addNote(NoteItem note) async {
    state = [...state, note];
    await _save();
  }

  Future<void> updateNote(String id, NoteItem note) async {
    state = [for (final n in state) if (n.id == id) note else n];
    await _save();
  }

  Future<void> deleteNote(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final jsonList = state.map((n) => n.toJson()).toList();
    await StorageUtils.safeSavePrefsString(_key, jsonEncode(jsonList));
  }

  Future<void> _load() async {
    final raw = await StorageUtils.safeLoadPrefsString(_key);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => NoteItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }

  // Export notes as JSON string
  Future<String> exportJson() async {
    final jsonList = state.map((n) => n.toJson()).toList();
    return jsonEncode(jsonList);
  }

  // Import notes from JSON string (replaces existing notes)
  Future<void> importJson(String jsonPayload) async {
    final List<dynamic> decoded = jsonDecode(jsonPayload) as List<dynamic>;
    state = decoded.map((e) => NoteItem.fromJson(e as Map<String, dynamic>)).toList();
    await _save();
  }

  // Export notes as CSV
  Future<String> exportCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('id,date,text');
    for (final n in state) {
      final date = n.date.toIso8601String();
      final text = n.text.replaceAll('"', '""');
      buffer.writeln('"${n.id}","$date","$text"');
    }
    return buffer.toString();
  }

  // Import from CSV — simple parsing expecting id,date,text per row. Replaces state.
  Future<void> importCsv(String csv) async {
    final lines = csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    // skip header if present
    if (lines.first.toLowerCase().contains('id') && lines.first.toLowerCase().contains('date')) {
      lines.removeAt(0);
    }
    final List<NoteItem> parsed = [];
    for (final line in lines) {
      // naive CSV split for three columns
      final parts = RegExp(r'"(.*?)",?"(.*?)",?"(.*?)"').firstMatch(line);
      if (parts != null) {
        final id = parts.group(1)!;
        final date = DateTime.parse(parts.group(2)!);
        final text = parts.group(3)!.replaceAll('""', '"');
        parsed.add(NoteItem(id: id, text: text, date: date));
      }
    }
    if (parsed.isNotEmpty) {
      state = parsed;
      await _save();
    }
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteItem>>((ref) => NotesNotifier());
