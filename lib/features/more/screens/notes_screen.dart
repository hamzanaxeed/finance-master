import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../shared/providers/notes_provider.dart';
import 'add_note_screen.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _sortNewestFirst = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List notesFiltered(List src) {
    var list = src.where((n) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return (n.text ?? '').toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) => _sortNewestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
    return list;
  }

  Future<void> _showExportDialog(String title, String content) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: SelectableText(content))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _importDialog(bool json) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Import ${json ? 'JSON' : 'CSV'}'),
        content: SizedBox(width: double.maxFinite, child: TextField(controller: ctrl, maxLines: 12, decoration: const InputDecoration(hintText: 'Paste content here'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      try {
        if (json) {
          await ref.read(notesProvider.notifier).importJson(ctrl.text.trim());
        } else {
          await ref.read(notesProvider.notifier).importCsv(ctrl.text.trim());
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imported successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final filtered = notesFiltered(notes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'export_json':
                  final s = await ref.read(notesProvider.notifier).exportJson();
                  await _showExportDialog('Export JSON', s);
                  break;
                case 'export_csv':
                  final s = await ref.read(notesProvider.notifier).exportCsv();
                  await _showExportDialog('Export CSV', s);
                  break;
                case 'import_json':
                  await _importDialog(true);
                  break;
                case 'import_csv':
                  await _importDialog(false);
                  break;
                case 'sort':
                  setState(() => _sortNewestFirst = !_sortNewestFirst);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'export_json', child: Text('Export JSON')),
              const PopupMenuItem(value: 'export_csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'import_json', child: Text('Import JSON')),
              const PopupMenuItem(value: 'import_csv', child: Text('Import CSV')),
              PopupMenuItem(value: 'sort', child: Text(_sortNewestFirst ? 'Sort Oldest First' : 'Sort Newest First')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search notes', border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('No notes', style: Theme.of(context).textTheme.titleMedium))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = filtered[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            n.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(DateFormat.yMMMd().format(n.date)),
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(note: n)));
                          },
                          onLongPress: () async {
                            final res = await showDialog<bool?>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete note'),
                                content: const Text('Are you sure you want to delete this note?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (res == true) {
                              await ref.read(notesProvider.notifier).deleteNote(n.id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted')));
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddNoteScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
