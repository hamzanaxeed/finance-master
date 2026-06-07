import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/stock_providers.dart';
import '../../../repositories/stock_repository.dart';
import '../../../shared/models/portfolio.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    // Cash currently available in portfolio
    final cashAvailable = ref.watch(portfolioCashProvider);
    // Current market value of holdings
    final holdingsValue = ref.watch(portfolioHoldingsValueProvider);
    // Total portfolio value = cash + holdings current value
    final totalValue = ref.watch(portfolioTotalValueProvider);

    // nl = net external transfers into portfolio (transfers in - transfers out)
    final invested = ref.watch(portfolioTotalInvestedProvider);
    // Current holdings cost basis (sum of avg * qty)
    final holdingsInvestment = ref.watch(portfolioHoldingsInvestmentProvider);
    final holdingsProfitLoss = ref.watch(portfolioHoldingsProfitLossProvider);
    final holdingsProfitLossPercent = holdingsInvestment > 0 ? (holdingsProfitLoss / holdingsInvestment) * 100 : 0.0;
    // Total portfolio profit/loss relative to total invested (transfers)
    final totalProfitLoss = totalValue - invested;
    final profitLossPercent = invested > 0 ? (totalProfitLoss / invested) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'transactions') {
                context.push('/portfolio/transactions');
              } else if (value == 'transfer') {
                _showTransferDialog(context, ref);
              } else if (value == 'manage_cash') {
                _showManageCashDialog(context, ref);
              } else if (value == 'refresh_prices') {
                _refreshAllPrices(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'transactions', child: Text('Transactions')),
              PopupMenuItem(value: 'transfer', child: Text('Transfer')),
              PopupMenuItem(value: 'manage_cash', child: Text('Manage cash')),
              PopupMenuItem(value: 'refresh_prices', child: Text('Refresh Prices')),
            ],
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is OverscrollNotification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent && notification.overscroll > 0 && !_isRefreshing) {
              _triggerRefresh();
            }
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () => _refreshAllPrices(context, ref),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Portfolio Value', style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.9), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(currencyFormat.format(totalValue), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(totalProfitLoss >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${totalProfitLoss >= 0 ? '+' : ''}${currencyFormat.format(totalProfitLoss)} (${totalProfitLoss >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          context,
                          title: 'Cash',
                          value: currencyFormat.format(cashAvailable),
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _summaryCard(
                          context,
                          title: 'Current cost',
                          value: currencyFormat.format(holdingsInvestment),
                          icon: Icons.trending_up_rounded,
                          iconColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _summaryCard(
                          context,
                          title: 'Holdings',
                          value: currencyFormat.format(holdingsValue),
                          icon: Icons.pie_chart_rounded,
                          iconColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: 16),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(holdingsProfitLoss >= 0 ? Icons.trending_up : Icons.trending_down, color: holdingsProfitLoss >= 0 ? Colors.green : Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Holdings P/L: ${holdingsProfitLoss >= 0 ? '+' : ''}${currencyFormat.format(holdingsProfitLoss)} (${holdingsProfitLossPercent.toStringAsFixed(2)}%)',
                            style: TextStyle(color: holdingsProfitLoss >= 0 ? Colors.green : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              // Holdings list
              holdings.isEmpty
                  ? SliverFillRemaining(hasScrollBody: false, child: const Center(child: Text('No holdings')))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final holding = holdings[index];
                        final isPositive = holding.profitLoss >= 0;
                        return InkWell(
                          onTap: () => context.push('/portfolio/holdings/${holding.symbol}'),
                          child: Card(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(holding.symbol, style: Theme.of(context).textTheme.titleMedium),
                                      Text(currencyFormat.format(holding.currentValue), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${holding.quantity} shares @ Rs ${holding.averagePrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                                      Text(
                                        '${isPositive ? '+' : ''}${holding.profitLossPercent.toStringAsFixed(2)}%',
                                        style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: holdings.length),
                    ),
              // bottom padding to account for FAB
              SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/portfolio/add-transaction'),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showTransferDialog(BuildContext context, WidgetRef ref) {
    final accounts = ref.read(accountProvider);
    showDialog(
      context: context,
      builder: (context) {
        String? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
        bool toPortfolio = true; // true: account -> portfolio, false: portfolio -> account
        final _formKey = GlobalKey<FormState>();
        final _amountCtrl = TextEditingController();
        final _noteCtrl = TextEditingController();

        return AlertDialog(
          title: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.swap_horiz_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
            title: Text(
              'Transfer Funds',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            dense: true,
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0), // Optimal spacing for modern dialogs
          content: StatefulBuilder(
            builder: (context, setState) {
              final portfolioCash = ref.watch(portfolioCashProvider);

              // Look up selected account safely to check its dynamic balance
              final selectedAccount = selectedAccountId != null
                  ? ref.read(accountProvider.notifier).getAccountById(selectedAccountId!)
                  : null;

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Modern Material 3 Toggle Segment
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('To Portfolio'),
                            icon: Icon(Icons.arrow_downward_rounded, size: 18),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('To Account'),
                            icon: Icon(Icons.arrow_upward_rounded, size: 18),
                          ),
                        ],
                        selected: {toPortfolio},
                        onSelectionChanged: (newSelection) {
                          setState(() => toPortfolio = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Account Selector Dropdown
                      if (accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No accounts available. Create an account first.',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedAccountId,
                          items: accounts.map((a) {
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.name} (Rs ${a.currentBalance.toStringAsFixed(0)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => selectedAccountId = v),
                          decoration: const InputDecoration(
                            labelText: 'Select Account',
                            prefixIcon: Icon(Icons.account_balance_rounded, size: 20),
                          ),
                          validator: (v) => v == null ? 'Please select an account' : null,
                        ),
                      const SizedBox(height: 16),

                      // Amount Input Field with Smart, Real-Time In-line Validation
                      TextFormField(
                        controller: _amountCtrl,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: 'Rs ',
                          prefixStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final amount = double.tryParse(v);
                          if (amount == null || amount <= 0) return 'Enter valid amount';

                          if (toPortfolio) {
                            if (selectedAccount == null) return 'Select an account first';
                            if (selectedAccount.currentBalance < amount) {
                              return 'Insufficient balance (Available: Rs ${selectedAccount.currentBalance.toStringAsFixed(0)})';
                            }
                          } else {
                            if (portfolioCash < amount) {
                              return 'Insufficient cash (Available: Rs ${portfolioCash.toStringAsFixed(0)})';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Optional Transaction Note Field
                      TextFormField(
                        controller: _noteCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Note (Optional)',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Form states handle all balance validations cleanly right here
                if (!_formKey.currentState!.validate() || selectedAccountId == null) return;

                final amount = double.parse(_amountCtrl.text);
                final memo = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

                // Close form dialog upfront to make the app feel quick and responsive
                Navigator.pop(context);

                try {
                  if (toPortfolio) {
                    await ref.read(portfolioTransferProvider.notifier).transferFromAccountToPortfolio(selectedAccountId!, amount, note: memo);
                  } else {
                    await ref.read(portfolioTransferProvider.notifier).transferFromPortfolioToAccount(selectedAccountId!, amount, note: memo);
                  }

                  // Use your custom success snackbar token from your theme config file
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.successSnackBar(context, 'Transfer completed successfully!'),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.errorSnackBar(context, 'Transfer failed. Please try again.'),
                  );
                }
              },
              child: const Text('Confirm Transfer'),
            ),
          ],
        );
      },
    );
  }

  void _showManageCashDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        bool add = true; // true = add cash, false = remove
        final _formKey = GlobalKey<FormState>();
        final _amountCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manage Portfolio Cash',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                // Keeps the dialog tight but allows room for error text validation animations
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Premium Material 3 Toggle
                      SegmentedButton<bool>(
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Add Cash'),
                            icon: Icon(Icons.add_circle_outline, size: 18),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Remove Cash'),
                            icon: Icon(Icons.remove_circle_outline, size: 18),
                          ),
                        ],
                        selected: {add},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() => add = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Cleaned up Input Box
                      TextFormField(
                        controller: _amountCtrl,
                        autofocus: true, // Instantly opens keyboard for seamless user flow
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: 'Rs. ',
                          prefixStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          // Use Material 3 recommended surface color
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter an amount';
                          final a = double.tryParse(v);
                          if (a == null || a <= 0) return 'Enter a valid positive amount';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (!(_formKey.currentState?.validate() ?? false)) return;

                    final amount = double.parse(_amountCtrl.text);
                    final actions = ref.read(portfolioCashActionsProvider);

                    // Capture the state variable locally before closing the context safely
                    final isDepositing = add;

                    if (isDepositing) {
                      actions.deposit(amount);
                    } else {
                      actions.withdraw(amount);
                    }

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(isDepositing ? '💸 Cash added successfully' : '💰 Cash removed successfully'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _refreshAllPrices(BuildContext context, WidgetRef ref) async {
    final holdings = ref.read(holdingsProvider);
    if (holdings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No holdings to refresh')));
      return;
    }
    final symbols = holdings.map((h) => h.symbol).toSet().toList();
    final repo = ref.read(stockRepositoryProvider);
    try {
      final results = await repo.fetchSymbols(symbols);
      // update price history for each symbol with a new PricePoint
      for (final entry in results.entries) {
        final sym = entry.key;
        final quote = entry.value;
        try {
          ref.read(priceHistoryProvider.notifier).addPricePoint(sym, PricePoint(time: quote.fetchedAt, price: quote.price));
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All shares current price updated')));
    } catch (e) {
      if (e is InvalidSymbolsException) {
        // still apply successful results
        for (final entry in e.results.entries) {
          final sym = entry.key;
          final quote = entry.value;
          try {
            ref.read(priceHistoryProvider.notifier).addPricePoint(sym, PricePoint(time: quote.fetchedAt, price: quote.price));
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid symbols; invalid: ${e.invalidSymbols.join(",")}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to refresh prices: $e')));
      }
    }
  }

  Future<void> _triggerRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      await _refreshAllPrices(context, ref);
    } finally {
      // small delay so UI has a moment to reflect the action and avoid rapid repeats
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _isRefreshing = false);
    }
  }
}

Widget _summaryCard(
    BuildContext context, {
      required String title,
      required String value,
      required IconData icon,
      required Color iconColor,
    }) {
  return Container(
    height: 130,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withAlpha(80),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      // prevent the Column from expanding beyond the card's space
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 4),

        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
