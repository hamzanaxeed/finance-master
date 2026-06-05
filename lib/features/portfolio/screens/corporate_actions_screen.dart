import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/models/portfolio.dart';

class CorporateActionsScreen extends ConsumerWidget {
  const CorporateActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(corporateActionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Corporate Actions')),
      body: actions.isEmpty
          ? const Center(child: Text('No corporate actions'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(action.symbol, style: Theme.of(context).textTheme.titleMedium),
                            Chip(
                              label: Text(action.type.name.toUpperCase()),
                              backgroundColor: _getActionColor(action.type),
                              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(action.companyName, style: Theme.of(context).textTheme.bodySmall),
                        const Divider(height: 16),
                        _InfoRow('Ratio', action.ratio),
                        _InfoRow('Old Quantity', '${action.oldQuantity} shares'),
                        _InfoRow('New Quantity', '${action.newQuantity} shares'),
                        _InfoRow('Date', DateFormat.yMMMd().format(action.date)),
                        if (action.notes != null) ...[
                          const SizedBox(height: 8),
                          Text(action.notes!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getActionColor(CorporateActionType type) {
    switch (type) {
      case CorporateActionType.split:
        return Colors.blue;
      case CorporateActionType.bonus:
        return Colors.green;
      case CorporateActionType.rights:
        return Colors.purple;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
