import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/models/portfolio.dart';
import 'add_stock_transaction_screen.dart';
import 'package:flutter/services.dart';

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
    final sh = holding!;

    final transactions = ref.watch(stockTransactionProvider).where((t) => t.symbol == symbol).toList();
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
              if (value == 'share') {
                final txt = '${sh.companyName} (${sh.symbol}) - Current Rs ${latestPrice.toStringAsFixed(2)}';
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
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'share', child: Text('Share')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'buy', child: Text('Buy share')),
              const PopupMenuItem(value: 'sell', child: Text('Sell share')),
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
