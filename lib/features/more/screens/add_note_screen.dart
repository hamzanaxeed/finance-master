import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/note.dart';
import '../../../shared/providers/notes_provider.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  final NoteItem? note;
  const AddNoteScreen({super.key, this.note});

  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}


class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textCtrl;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.note?.text ?? '');
    _date = widget.note?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final text = _textCtrl.text.trim();
    if (widget.note != null) {
      final updated = NoteItem(id: widget.note!.id, text: text, date: _date);
      await ref.read(notesProvider.notifier).updateNote(widget.note!.id, updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note updated')));
    } else {
      final note = NoteItem(text: text, date: _date);
      await ref.read(notesProvider.notifier).addNote(note);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note added')));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.note != null ? 'Edit Note' : 'Add Note')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _textCtrl,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter note' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_date)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(widget.note != null ? 'Save' : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

