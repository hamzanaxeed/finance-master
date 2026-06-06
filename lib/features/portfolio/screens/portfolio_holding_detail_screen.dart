import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/models/portfolio.dart';
import 'add_stock_transaction_screen.dart';
import 'package:flutter/services.dart';
import 'dividend/add_dividend_screen.dart';

class HoldingDetailScreen extends ConsumerWidget {
  final String symbol;
  const HoldingDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    StockHolding? holding;
    try {
      holding = holdings.firstWhere((h) => h.symbol == symbol);
    } catch (_) {
      holding = null;
    }

    if (holding == null) {
      return Scaffold(
        appBar: AppBar(title: Text(symbol)),
        body: const Center(child: Text('Holding not found')),
      );
    }

    // Promote nullable holding to non-null local to satisfy analyzer
    final sh = holding;

    final transactions = ref.watch(stockTransactionProvider).where((t) => t.symbol == symbol).toList();
    final dividends = ref.watch(dividendProvider).where((d) => d.symbol == symbol).toList();
    // compute total dividends for this holding and group by year
    final totalDividendsForHolding = dividends.fold<double>(0.0, (sum, d) => sum + d.totalReceived);
    final Map<int, List<Dividend>> dividendsByYear = {};
    for (final d in dividends) {
      final y = d.date.year;
      dividendsByYear.putIfAbsent(y, () => []).add(d);
    }
    final priceHistory = ref.watch(priceHistoryProvider)[symbol] ?? [];

    // firstTxnDate not used currently
    // DateTime? firstTxnDate;
    if (transactions.isNotEmpty) {
      // keep logic available for future use
      // final _firstTxnDate = transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final latestPrice = priceHistory.isNotEmpty ? priceHistory.last.price : sh.currentPrice;
    final displayCurrentValue = sh.quantity * latestPrice;
    final displayProfitLoss = displayCurrentValue - sh.totalInvestment;
    final displayProfitLossPercent = sh.totalInvestment > 0 ? (displayProfitLoss / sh.totalInvestment) * 100 : 0;
    final isPositive = displayProfitLoss >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(sh.symbol),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) async {
              if (value == 'add_dividend') {
                // Open add dividend screen with prefilled company/symbol
                await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AddDividendScreen(
                      initialSymbol: sh.symbol,
                      initialCompanyName: sh.companyName,
                      initialQuantity: sh.quantity,
                    )));
                return;
              }
              if (value == 'copy data') {
                final txt = '${sh.companyName} (${sh.symbol}) - ${sh.quantity} @ Rs ${sh.averagePrice.toStringAsFixed(2)}, current price Rs ${latestPrice.toStringAsFixed(2)}, Total P/L ${displayProfitLossPercent >= 0 ? '+' : ''}${displayProfitLossPercent.toStringAsFixed(2)}%';
                await Clipboard.setData(ClipboardData(text: txt));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share text copied to clipboard')));
              } else if (value == 'edit') {
                final controller = TextEditingController(text: sh.companyName);
                final res = await showDialog<String?>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Edit Share'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(labelText: 'Company name'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
                      ],
                    );
                  },
                );
                if (res != null && res.isNotEmpty) {
                  ref.read(holdingMetaProvider.notifier).updateCompanyName(symbol, res);
                }
              } else if (value == 'buy' || value == 'sell') {
                final type = value == 'buy' ? StockTransactionType.buy : StockTransactionType.sell;
                Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AddStockTransactionScreen(
                      initialSymbol: sh.symbol,
                      initialType: type,
                      initialPrice: latestPrice,
                      initialQuantity: 1,
                    )));
              } else if (value == 'delete') {
                // Show confirmation with three choices
                final res = await showDialog<String?>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: const Text('Delete holding and transactions'),
                      content: const Text('Deleting this holding will remove all related transactions. What would you like to do with the cash effects?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, 'nochange'), child: const Text("Don't change portfolio cash")),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, 'reverse'), child: const Text('Reverse cash to portfolio')),
                      ],
                    );
                  },
                );

                if (res == null || res == 'cancel') return;

                // Perform actions depending on choice
                if (res == 'reverse') {
                  // Calculate the net original cash effect of all transactions (buys are negative, sells are positive)
                  double originalNet = 0.0;
                  for (final t in transactions) {
                    if (t.type == StockTransactionType.buy) {
                      originalNet -= t.total;
                    } else if (t.type == StockTransactionType.sell) {
                      originalNet += t.total;
                    }
                  }


                  // Desired cash effect when deleting the holding should be as if the remaining shares
                  // were sold at the current/latest price.
                  final double desiredCashEffect = sh.quantity * latestPrice;

                  // Compute the delta to apply to portfolio so the final cash effect equals desiredCashEffect
                  final double delta = desiredCashEffect - originalNet;
                  if (delta > 0) {
                    await ref.read(portfolioTransferProvider.notifier).depositToPortfolio(delta, note: 'Reversal for deleted holding ${sh.symbol} at current price Rs ${latestPrice.toStringAsFixed(2)}');
                  } else if (delta < 0) {
                    await ref.read(portfolioTransferProvider.notifier).withdrawFromPortfolio(-delta, note: 'Reversal for deleted holding ${sh.symbol} at current price Rs ${latestPrice.toStringAsFixed(2)}');
                  }
                }

                // Delete transactions for this symbol
                ref.read(stockTransactionProvider.notifier).deleteTransactionsForSymbol(sh.symbol);

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Holding transactions deleted')));
                // Close detail screen
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'add_dividend', child: Text('Add dividend')),
              const PopupMenuItem(value: 'copy data', child: Text('copy data')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'buy', child: Text('Buy share')),
              const PopupMenuItem(value: 'sell', child: Text('Sell share')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sh.companyName, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${sh.quantity} shares', style: Theme.of(context).textTheme.bodyMedium),
                        Text(currencyFormat.format(displayCurrentValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow('Avg Price', currencyFormat.format(sh.averagePrice)),
                    _InfoRow('Current Price', currencyFormat.format(latestPrice)),
                    _InfoRow('Total Investment', currencyFormat.format(sh.totalInvestment)),
                    _InfoRow('Current Value', currencyFormat.format(displayCurrentValue)),
                    _InfoRow('Profit/Loss', '${displayProfitLoss >= 0 ? '+' : ''}${currencyFormat.format(displayProfitLoss)}', valueColor: isPositive ? Colors.green : Colors.red),
                    _InfoRow('Profit/Loss %', '${displayProfitLossPercent >= 0 ? '+' : ''}${displayProfitLossPercent.toStringAsFixed(2)}%', valueColor: isPositive ? Colors.green : Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Price charts
            Text('Price history', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            priceHistory.isEmpty
                ? const Text('No price history available')
                : SizedBox(
                    height: 200,
                    child: _buildChart(context, priceHistory),
                  ),
            const SizedBox(height: 8),
            // Moved update current price button here (previously in AppBar)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.currency_rupee),
                label: const Text('Update current price'),
                onPressed: () async {
                  final controller = TextEditingController();
                  final res = await showDialog<double?>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Update Current Price'),
                        content: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Price'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              final v = double.tryParse(controller.text.trim());
                              Navigator.pop(context, v);
                            },
                            child: const Text('Update'),
                          ),
                        ],
                      );
                    },
                  );
                  if (res != null) {
                    final pp = PricePoint(time: DateTime.now(), price: res);
                    ref.read(priceHistoryProvider.notifier).addPricePoint(symbol, pp);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            transactions.isEmpty
                ? const Text('No transactions for this holding')
                : Column(
                    children: transactions.reversed.map((t) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${t.type.name.toUpperCase()} ${t.quantity} @ Rs ${t.price.toStringAsFixed(2)}'),
                          subtitle: Text(DateFormat.yMMMd().format(t.date)),
                          trailing: Text('Rs ${t.total.toStringAsFixed(2)}'),
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dividends', style: Theme.of(context).textTheme.titleMedium),
                Text('Total: Rs ${totalDividendsForHolding.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            dividends.isEmpty
                ? const Text('No dividends for this holding')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dividendsByYear.keys.toList().reversed.map((year) {
                      final list = dividendsByYear[year]!..sort((a, b) => b.date.compareTo(a.date));
                      final yearTotal = list.fold<double>(0.0, (s, d) => s + d.totalReceived);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(year.toString(), style: Theme.of(context).textTheme.bodyLarge),
                                Text('Year total: Rs ${yearTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          ...list.map((d) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.monetization_on, color: Colors.white),
                                ),
                                title: Text('${d.companyName} (${d.symbol})'),
                                subtitle: Text('Rs ${d.amountPerShare.toStringAsFixed(2)} per share\n${DateFormat.yMMMd().format(d.date)}'),
                                trailing: Text('${d.totalReceived.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                isThreeLine: true,
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<PricePoint> points) {
    // Using Syncfusion SfCartesianChart with SplineAreaSeries for a modern share chart
    return ScrollableLineChart(points: points, height: 200);
  }
}

class ScrollableLineChart extends StatelessWidget {
  final List<PricePoint> points;
  final double height;
  final int visibleWindow; // number of latest points visible by default
  const ScrollableLineChart({super.key, required this.points, this.height = 240, this.visibleWindow = 60});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final sorted = List<PricePoint>.from(points)..sort((a, b) => a.time.compareTo(b.time));

    // Downsample for performance only if extremely large
    final int maxPoints = 2000;
    List<PricePoint> data = sorted;
    if (sorted.length > maxPoints) {
      final step = (sorted.length / maxPoints).ceil();
      data = [for (var i = 0; i < sorted.length; i += step) sorted[i]];
      if (data.last != sorted.last) data.add(sorted.last);
    }

    // Default visible window (right-aligned)
    final int n = data.length;
    final DateTime visibleMin = n > visibleWindow ? data[n - visibleWindow].time : data.first.time;
    final DateTime visibleMax = data.last.time;

    final zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      enableDoubleTapZooming: true,
      zoomMode: ZoomMode.x,
    );

    final trackballBehavior = TrackballBehavior(enable: true, activationMode: ActivationMode.singleTap, tooltipSettings: const InteractiveTooltip(enable: true));

    // Compute a sensible interval for date labels to avoid overlap while showing dates
    final int daysSpan = visibleMax.difference(visibleMin).inDays.clamp(1, 365);
    final int labelCount = 6; // aim for ~6 labels
    final double rawInterval = daysSpan / labelCount;
    final int intervalDays = rawInterval < 1 ? 1 : rawInterval.ceil();

    return SizedBox(
      height: height,
      child: SfCartesianChart(
        zoomPanBehavior: zoomPanBehavior,
        trackballBehavior: trackballBehavior,
        primaryXAxis: DateTimeAxis(
          minimum: visibleMin,
          maximum: visibleMax,
          dateFormat: DateFormat.Md(),
          intervalType: DateTimeIntervalType.days,
          interval: intervalDays.toDouble(),
          majorGridLines: const MajorGridLines(width: 0.5),
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          labelIntersectAction: AxisLabelIntersectAction.hide,
          labelRotation: 45,
        ),
        primaryYAxis: NumericAxis(majorGridLines: const MajorGridLines(width: 0.5)),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries>[
          LineSeries<PricePoint, DateTime>(
            dataSource: data,
            xValueMapper: (p, _) => p.time,
            yValueMapper: (p, _) => p.price,
            color: Theme.of(context).primaryColor,
            width: 2,
            markerSettings: MarkerSettings(isVisible: true, height: 4, width: 4),
            name: 'Price',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }
}
