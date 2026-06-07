import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/backup_service.dart';

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
            decoration: const InputDecoration(labelText: 'Passphrase'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Export a secure, encrypted backup of app data. Keep the passphrase safe.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Export Backup (save file)'),
              onPressed: () async {
                final pass = await _askPassphrase(context, title: 'Enter passphrase to encrypt backup');
                if (pass == null) return;
                try {
                  final path = await BackupService.exportEncryptedBackup(pass);
                  if (path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved: $path')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export cancelled')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.archive),
              label: const Text('Export Backup to App Folder'),
              onPressed: () async {
                final pass = await _askPassphrase(context, title: 'Enter passphrase to encrypt backup');
                if (pass == null) return;
                try {
                  final path = await BackupService.exportToAppDirectory(pass);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved: $path')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              },
            ),
            const SizedBox(height: 24),
            const Text('Import a previously exported backup file (will overwrite local data).'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Import Backup'),
              onPressed: () async {
                try {
                  final picked = await BackupService.pickBackupFile();
                  if (picked == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file selected')));
                    return;
                  }
                  final pass = await _askPassphrase(context, title: 'Enter passphrase to decrypt backup');
                  if (pass == null) return;
                  final parsed = await BackupService.importEncryptedBackupFromPath(picked, pass);
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
                    content: const Text('Backup exports all app preferences and secure entries into a single AES-encrypted file. Use the same passphrase to restore.'),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
