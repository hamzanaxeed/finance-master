import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    final features = [
      {'title': 'Transactions', 'icon': Icons.swap_horiz, 'route': '/transactions'},
      {'title': 'Budgets', 'icon': Icons.pie_chart, 'route': '/budgets'},
      {'title': 'Loans & Liabilities', 'icon': Icons.credit_card, 'route': '/loans'},
      {'title': 'Analytics Center', 'icon': Icons.analytics, 'route': '/analytics'},
      {'title': 'Activity Timeline', 'icon': Icons.timeline, 'route': '/activity'},
      {'title': 'Holdings', 'icon': Icons.show_chart, 'route': '/portfolio/holdings'},
      {'title': 'Dividends', 'icon': Icons.monetization_on, 'route': '/portfolio/dividends'},
      {'title': 'Corporate Actions', 'icon': Icons.business, 'route': '/portfolio/corporate-actions'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('John Doe', style: Theme.of(context).textTheme.titleMedium),
                      Text('john.doe@example.com', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('WealthTracker v1.0.0'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}
