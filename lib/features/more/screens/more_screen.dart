import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    final features = [
      {'title': 'Transactions', 'icon': Icons.swap_horiz, 'route': '/transactions'},
      {'title': 'Notes', 'icon': Icons.note_alt_outlined, 'route': '/more/notes'},
      {'title': 'Passwords', 'icon': Icons.lock_outline, 'route': '/more/passwords'},
      {'title': 'Analytics Center', 'icon': Icons.analytics, 'route': '/analytics'},
      {'title': 'Activity Timeline', 'icon': Icons.timeline, 'route': '/activity'},
      {'title': 'Holdings', 'icon': Icons.show_chart, 'route': '/portfolio/holdings'},
      {'title': 'Dividends', 'icon': Icons.monetization_on, 'route': '/portfolio/dividends'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Features', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...features.map((feature) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(feature['icon'] as IconData),
                  title: Text(feature['title'] as String),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(feature['route'] as String),
                ),
              )),
          const SizedBox(height: 16),
          Text('Settings', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              value: isDarkMode,
              onChanged: (value) => ref.read(darkModeProvider.notifier).toggle(),
            ),
          ),
          Card(
            child: Consumer(
              builder: (ctx, ref, _) {
                final enabled = ref.watch(biometricProvider);
                return SwitchListTile(
                  title: const Text('Biometric lock'),
                  secondary: const Icon(Icons.fingerprint),
                  value: enabled,
                  onChanged: (val) async {
                    // perform toggle and show result in a SnackBar
                    final msg = await ref.read(biometricProvider.notifier).toggle();
                    if (msg == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Biometric enabled' : 'Biometric disabled')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $msg')));
                    }
                  },
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Manage Categories'),
              subtitle: const Text('Add or remove transaction categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/manage-categories'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup & Restore'),
              subtitle: const Text('Export or import encrypted backup'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/more/backup'),
            ),
          ),
        ],
      ),
    );
  }
}
