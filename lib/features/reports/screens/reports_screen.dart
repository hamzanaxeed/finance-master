import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = [
      {'title': 'Monthly Finance Report', 'icon': Icons.receipt, 'color': Colors.blue},
      {'title': 'Investment Report', 'icon': Icons.trending_up, 'color': Colors.green},
      {'title': 'Dividend Income Report', 'icon': Icons.monetization_on, 'color': Colors.purple},
      {'title': 'Net Worth Report', 'icon': Icons.account_balance, 'color': Colors.orange},
      {'title': 'Budget Performance', 'icon': Icons.pie_chart, 'color': Colors.red},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (report['color'] as Color).withAlpha(51),
                child: Icon(report['icon'] as IconData, color: report['color'] as Color),
              ),
              title: Text(report['title'] as String),
              subtitle: const Text('Generate and export report'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.table_chart), onPressed: () {}),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
