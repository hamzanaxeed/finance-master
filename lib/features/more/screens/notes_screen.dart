import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/notes_provider.dart';
import '../../../shared/providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final filtered = notesFiltered(notes);

    final biometricEnabled = ref.watch(biometricProvider);
    final sessionUnlocked = ref.watch(sessionUnlockedProvider);

    if (biometricEnabled && !sessionUnlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notes')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Authenticate to view notes.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await ref.read(biometricProvider.notifier).authenticate();
                if (ok) {
                  ref.read(sessionUnlockedProvider.notifier).state = true;
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed')));
                }
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
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
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
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
                          ),
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
