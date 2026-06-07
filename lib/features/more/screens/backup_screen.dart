import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/backup_service.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/providers/passwords_provider.dart';
import '../../../shared/providers/notes_provider.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/providers/auth_provider.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  Future<String?> _askPassphrase(BuildContext context, {required String title}) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Pass Key'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(ctx).pop(controller.text.trim());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Export a secure, encrypted backup of app data. Keep the Pass Key safe.'),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy_all),
                label: const Text('Copy Backup to Clipboard'),
                onPressed: () async {
                  final pass = await _askPassphrase(context, title: 'Enter Pass Key to encrypt backup');
                  if (pass == null) return;
                  try {
                    final txt = await BackupService.exportEncryptedBackupAsText(pass);
                    await Clipboard.setData(ClipboardData(text: txt));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup copied to clipboard')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copy failed: $e')));
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Import a previously exported backup file (will overwrite local data).'),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.paste),
                label: const Text('Paste Backup from Clipboard'),
                onPressed: () async {
                  try {
                    final clip = await Clipboard.getData('text/plain');
                    final initial = clip?.text ?? '';

                    // Let user edit/paste the backup text if clipboard was empty
                    final controller = TextEditingController(text: initial);
                    final formKey = GlobalKey<FormState>();
                    final pasted = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Paste backup JSON'),
                        content: Form(
                          key: formKey,
                          child: TextFormField(
                            controller: controller,
                            maxLines: 8,
                            decoration: const InputDecoration(hintText: 'Paste backup JSON here'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) Navigator.of(ctx).pop(controller.text.trim());
                            },
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    );
                    if (pasted == null) return;

                    final pass = await _askPassphrase(context, title: 'Enter Pass Key to decrypt pasted backup');
                    if (pass == null) return;

                    final parsed = await BackupService.importEncryptedBackupFromText(pasted, pass);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Import'),
                        content: const Text('Importing will overwrite local data. Continue?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Import')),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await BackupService.applyImportedBackup(parsed);
                    try {
                      await Future.wait<void>([
                        ref.read(accountProvider.notifier).reload(),
                        ref.read(transactionProvider.notifier).reload(),
                        ref.read(categoryProvider.notifier).reload(),
                        ref.read(passwordsProvider.notifier).reload(),
                        ref.read(notesProvider.notifier).reload(),
                        ref.read(biometricProvider.notifier).reload(),
                        reloadPortfolioData(ref),
                      ]);
                      try {
                        final bioEnabled = ref.read(biometricProvider);
                        if (!bioEnabled) ref.read(sessionUnlockedProvider.notifier).state = true;
                      } catch (_) {}
                    } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.help_outline),
                label: const Text('How it works'),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Backup details'),
                      content: const Text('Backup exports all app preferences and secure entries into a single AES-encrypted file. Use the same Pass Key to restore.'),
                      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
