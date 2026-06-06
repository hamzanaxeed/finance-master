import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/password_entry.dart';
import '../../../shared/providers/passwords_provider.dart';

class AddPasswordScreen extends ConsumerStatefulWidget {
  final PasswordEntry? entry;
  const AddPasswordScreen({super.key, this.entry});

  @override
  ConsumerState<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends ConsumerState<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _appCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _noteCtrl;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _appCtrl = TextEditingController(text: widget.entry?.appName ?? '');
    _usernameCtrl = TextEditingController(text: widget.entry?.username ?? '');
    _emailCtrl = TextEditingController(text: widget.entry?.email ?? '');
    _passwordCtrl = TextEditingController(text: widget.entry?.password ?? '');
    _noteCtrl = TextEditingController(text: widget.entry?.note ?? '');
  }

  @override
  void dispose() {
    _appCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entry = PasswordEntry(
      id: widget.entry?.id,
      appName: _appCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: widget.entry?.createdAt,
    );

    if (widget.entry != null) {
      await ref.read(passwordsProvider.notifier).update(widget.entry!.id, entry);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } else {
      await ref.read(passwordsProvider.notifier).add(entry);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password added')));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.entry != null ? 'Edit Password' : 'Add Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _appCtrl,
                decoration: const InputDecoration(labelText: 'App / Service Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(widget.entry != null ? 'Save' : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
