import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:wealthtracker/features/more/screens/add_password_screen.dart';
import '../../../shared/providers/passwords_provider.dart';
import '../../../shared/models/password_entry.dart';

class PasswordsScreen extends ConsumerStatefulWidget {
  const PasswordsScreen({super.key});

  @override
  ConsumerState<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends ConsumerState<PasswordsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _sortAz = true; // true: A-Z by appName, false: Z-A
  bool _showOnlyWithNote = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PasswordEntry> _applyFilters(List<PasswordEntry> src) {
    var list = src.where((e) {
      if (_showOnlyWithNote && (e.note == null || e.note!.trim().isEmpty)) return false;
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return e.appName.toLowerCase().contains(q) || e.username.toLowerCase().contains(q) || e.email.toLowerCase().contains(q) || (e.note ?? '').toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) => _sortAz ? a.appName.toLowerCase().compareTo(b.appName.toLowerCase()) : b.appName.toLowerCase().compareTo(a.appName.toLowerCase()));
    return list;
  }

  void _showDetailsSheet(PasswordEntry e) {
    bool obscure = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: MediaQuery.of(ctx).viewInsets.add(const EdgeInsets.all(16)),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              ListTile(
                title: Text(e.appName, style: Theme.of(context).textTheme.titleLarge),
                subtitle: Text(e.email.isNotEmpty ? e.email : e.username),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: e.email.isNotEmpty ? e.email : e.username));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [Text('Password:', style: Theme.of(context).textTheme.bodyLarge), const SizedBox(width: 8), Expanded(child: Text(obscure ? '••••••••' : e.password, style: const TextStyle(fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            setState(() => obscure = !obscure);
                          },
                          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                          label: Text(obscure ? 'Reveal' : 'Hide'),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: e.password));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied')));
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddPasswordScreen(entry: e)));
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool?>(context: context, builder: (dctx) => AlertDialog(title: const Text('Delete'), content: const Text('Delete this entry?'), actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Delete'))]));
                        if (confirmed == true) {
                          await ref.read(passwordsProvider.notifier).delete(e.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
                        }
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (e.note != null && e.note!.isNotEmpty) ...[
                Text('Note', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(e.note!),
                const SizedBox(height: 12),
              ],
            ]),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(passwordsProvider);
    final filtered = _applyFilters(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passwords'),
      ),
      body: Column(
        children: [
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('No passwords', style: Theme.of(context).textTheme.titleMedium))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      return Card(
                        child: ListTile(
                          title: Text(e.appName),
                          subtitle: Text(e.email.isNotEmpty ? e.email : e.username),
                          onTap: () => _showDetailsSheet(e),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPasswordScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
