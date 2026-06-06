import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import 'dividend/add_dividend_screen.dart';
import 'dividend/dividend_detail_screen.dart';

class DividendsScreen extends ConsumerWidget {
  const DividendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dividends = ref.watch(dividendProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final totalDividends = dividends.fold(0.0, (sum, d) => sum + d.totalReceived);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Dividends', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const AddDividendScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Dividend'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Summary Dashboard Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Dividends',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(totalDividends),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dividends List / Empty View Block
          Expanded(
            child: dividends.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No dividends recorded yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
           : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 96),
              itemCount: dividends.length,
              itemBuilder: (context, index) {
                final dividend = dividends[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  child: InkWell( // Adds a premium ripple ink animation to the card
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => DividendDetailScreen(dividend: dividend)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Uniform structural internal padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Row: Info (Left) + Financials & Actions (Right)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon Indicator
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12), // Matching Material 3 soft squircle
                                ),
                                child: const Icon(Icons.add_chart_rounded, color: Colors.green, size: 22),
                              ),
                              const SizedBox(width: 14),

                              // Text Block: Company & Shares Rate
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${dividend.companyName} (${dividend.symbol})',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rs ${dividend.amountPerShare.toStringAsFixed(2)} / share',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Financial Total + Overflow Menu Action Block
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currencyFormat.format(dividend.totalReceived),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      PopupMenuButton<String>(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(), // Shrinks bounding box to stop trailing overflows
                                        onSelected: (action) => _handleDeleteAction(context, ref, dividend, action),
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 18),
                                                const SizedBox(width: 10),
                                                const Text('Delete Log'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Bottom Section: Divider line + Metadata Timestamp
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1, thickness: 0.5),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat.yMMMd().format(dividend.date),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),


                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          ),
        ],
      ),
    );
  }

  // Segmented Business Logic Handler (Keeps View Layer Lean)
  Future<void> _handleDeleteAction(BuildContext context, WidgetRef ref, dynamic dividend, String action) async {
    if (action != 'delete') return;

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(ctx).colorScheme.error),
              const SizedBox(width: 10),
              const Text('Delete Dividend'),
            ],
          ),
          content: const Text(
            'Choose how you want to handle removing this entry. You can delete just the log or reverse the added cash balance from your portfolio.',
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text('Cancel', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(ctx).colorScheme.error),
              ),
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: Text('Delete Record Only', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, 'reverse'),
              child: const Text('Delete & Reverse Cash'),
            ),
          ],
        );
      },
    );

    if (result == null || result == 'cancel') return;

    if (result == 'delete') {
      ref.read(dividendProvider.notifier).deleteDividend(dividend.id);
      _showFloatingSnackBar(context, '🗑️ Dividend record deleted');
      return;
    }

    // Process Complete Cash Reversal Logic Pathway
    final amount = dividend.totalReceived;
    final currentCashBalance = ref.read(portfolioCashProvider);

    if (currentCashBalance < amount) {
      _showFloatingSnackBar(context, '⚠️ Insufficient cash available to reverse payout');
      return;
    }

    await ref.read(portfolioTransferProvider.notifier).withdrawFromPortfolio(
      amount,
      note: 'Reversal for deleted dividend: ${dividend.companyName}',
    );

    if (dividend.transactionId != null) {
      ref.read(transactionProvider.notifier).deleteTransaction(dividend.transactionId!);
    }

    ref.read(dividendProvider.notifier).deleteDividend(dividend.id);
    _showFloatingSnackBar(context, '🔄 Payout deleted and balance reversed');
  }

  void _showFloatingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

