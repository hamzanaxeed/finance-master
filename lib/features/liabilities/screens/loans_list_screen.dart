import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/loan_provider.dart';
import '../../../shared/models/loan.dart';

class LoansListScreen extends ConsumerWidget {
  const LoansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loanProvider);
    final totalDebt = ref.watch(totalDebtProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    final totalMonthlyPayment = loans.fold(0.0, (sum, loan) => sum + loan.monthlyInstallment);

    return Scaffold(
      appBar: AppBar(title: const Text('Loans & Liabilities')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Debt', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                const SizedBox(height: 8),
                Text(currencyFormat.format(totalDebt), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Monthly Payment: ${currencyFormat.format(totalMonthlyPayment)}', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          Expanded(
            child: loans.isEmpty
                ? const Center(child: Text('No loans'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: loans.length,
                    itemBuilder: (context, index) {
                      final loan = loans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => context.push('/loans/${loan.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(loan.name, style: Theme.of(context).textTheme.titleMedium),
                                    Text(currencyFormat.format(loan.remainingAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${loan.type.name.toUpperCase()} • ${loan.interestRate}% APR', style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: loan.progress / 100,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('${loan.progress.toStringAsFixed(0)}% paid', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
