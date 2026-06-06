import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/portfolio.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/providers/portfolio_provider.dart' as _pp show holdingMetaProvider;
import '../../../shared/providers/portfolio_provider.dart' as pp;

class AddStockTransactionScreen extends ConsumerStatefulWidget {
  final String? initialSymbol;
  final StockTransactionType? initialType;
  final double? initialPrice;
  final double? initialQuantity;

  const AddStockTransactionScreen({super.key, this.initialSymbol, this.initialType, this.initialPrice, this.initialQuantity});

  @override
  ConsumerState<AddStockTransactionScreen> createState() => _AddStockTransactionScreenState();
}

class _AddStockTransactionScreenState extends ConsumerState<AddStockTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _commissionController = TextEditingController(text: '0');
  final _companyNameController = TextEditingController();

  StockTransactionType _selectedType = StockTransactionType.buy;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _commissionController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prefill if initial values were provided
    final w = widget;
    if (w.initialSymbol != null) _symbolController.text = w.initialSymbol!.toUpperCase();
    if (w.initialPrice != null) _priceController.text = w.initialPrice!.toStringAsFixed(2);
    if (w.initialQuantity != null) _quantityController.text = w.initialQuantity!.toStringAsFixed(2);
    if (w.initialType != null) _selectedType = w.initialType!;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final transaction = StockTransaction(
        symbol: _symbolController.text.toUpperCase(),
        type: _selectedType,
        quantity: double.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        commission: double.parse(_commissionController.text),
        date: _selectedDate,
      );

      // Use notifier which now returns a Future<bool> indicating success (insufficient funds when buying)
      ref.read(stockTransactionProvider.notifier).addTransaction(transaction).then((success) {
        if (success) {
          // save company name to holding meta if provided
          final company = _companyNameController.text.trim();
          if (company.isNotEmpty) {
            ref.read(pp.holdingMetaProvider.notifier).updateCompanyName(transaction.symbol, company);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction added successfully')),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insufficient portfolio funds for this buy transaction')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Stock Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20), // Generous modern breathing room
          children: [
            // 1. Sleek Material 3 Segmented Toggle for Buy/Sell
            SegmentedButton<StockTransactionType>(
              segments: [
                ButtonSegment<StockTransactionType>(
                  value: StockTransactionType.buy,
                  label: const Text('BUY'),
                  icon: Icon(Icons.add_shopping_cart_rounded, size: 18, color: _selectedType == StockTransactionType.buy ? theme.colorScheme.primary : null),
                ),
                ButtonSegment<StockTransactionType>(
                  value: StockTransactionType.sell,
                  label: const Text('SELL'),
                  icon: Icon(Icons.sell_outlined, size: 18, color: _selectedType == StockTransactionType.sell ? theme.colorScheme.error : null),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (newSelection) {
                setState(() => _selectedType = newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                // Adaptive coloring depending on trade context
                selectedBackgroundColor: _selectedType == StockTransactionType.buy
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.errorContainer,
                selectedForegroundColor: _selectedType == StockTransactionType.buy
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),

            // 2. Asset Core Info (Ticker and Company Name)
            TextFormField(
              controller: _symbolController,
              decoration: const InputDecoration(
                labelText: 'Stock Symbol',
                hintText: 'e.g., AAPL, TSLA',
                prefixIcon: Icon(Icons.analytics_rounded, size: 20),
              ),
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontWeight: FontWeight.bold),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _companyNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Company Name (Optional)',
                prefixIcon: Icon(Icons.business_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            // Divider to visually structure transaction specifics
            Row(
              children: [
                Text('Transaction Details', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                const Expanded(child: Divider(indent: 12)),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Trade Specifics (Quantity & Price per Share)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.pin_rounded, size: 20),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price / Share',
                      prefixText: 'Rs ',
                      prefixStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Commission Fees
            TextFormField(
              controller: _commissionController,
              decoration: InputDecoration(
                labelText: 'Commission Fees',
                prefixText: 'Rs ',
                prefixStyle: TextStyle(color: theme.colorScheme.outline),
                prefixIcon: const Icon(Icons.receipt_long_rounded, size: 20),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // 5. Clean, Interactive Date Picker Form Trigger
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Transaction Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                ),
                child: Text(
                  DateFormat.yMMMd().format(_selectedDate), // Requires import 'package:intl/intl.dart';
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 6. Sticky Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton( // Using theme matching elevated buttons
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == StockTransactionType.buy
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      foregroundColor: _selectedType == StockTransactionType.buy
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onError,
                    ),
                    child: const Text('Save Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
