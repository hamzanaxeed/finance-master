import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/loan_provider.dart';

class LoanDetailsScreen extends ConsumerWidget {
  final String loanId;

  const LoanDetailsScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = ref.watch(loanProvider.notifier).getLoanById(loanId);

    if (loan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan Not Found')),
        body: const Center(child: Text('Loan not found')),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: Text(loan.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(currencyFormat.format(loan.remainingAmount), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const Text('Remaining Amount'),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: loan.progress / 100,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${loan.progress.toStringAsFixed(1)}% paid'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Total Amount', value: currencyFormat.format(loan.totalAmount)),
          _InfoRow(label: 'Paid Amount', value: currencyFormat.format(loan.paidAmount)),
          _InfoRow(label: 'Monthly Installment', value: currencyFormat.format(loan.monthlyInstallment)),
          _InfoRow(label: 'Interest Rate', value: '${loan.interestRate}%'),
          _InfoRow(label: 'Start Date', value: DateFormat.yMMMd().format(loan.startDate)),
          _InfoRow(label: 'Due Date', value: DateFormat.yMMMd().format(loan.dueDate)),
          _InfoRow(label: 'Type', value: loan.type.name.toUpperCase()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
