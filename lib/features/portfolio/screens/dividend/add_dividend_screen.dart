import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/portfolio.dart';
import '../../../../shared/providers/portfolio_provider.dart';
import '../../../../shared/models/transaction.dart';
import '../../../../shared/providers/transaction_provider.dart';

class AddDividendScreen extends ConsumerStatefulWidget {
  final String? initialSymbol;
  final String? initialCompanyName;
  final double? initialQuantity;

  const AddDividendScreen({super.key, this.initialSymbol, this.initialCompanyName, this.initialQuantity});

  @override
  ConsumerState<AddDividendScreen> createState() => _AddDividendScreenState();

}

class _AddDividendScreenState extends ConsumerState<AddDividendScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _symbolController;
  late TextEditingController _quantityController;
  late TextEditingController _perShareController;
  DateTime _date = DateTime.now();
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.initialCompanyName ?? '');
    _symbolController = TextEditingController(text: widget.initialSymbol ?? '');
    _quantityController = TextEditingController(text: widget.initialQuantity != null ? widget.initialQuantity!.toString() : '');
    _perShareController = TextEditingController();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _perShareController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _autoValidate = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final company = _companyController.text.trim();
    final symbol = _symbolController.text.trim();
    final q = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final per = double.tryParse(_perShareController.text.trim()) ?? 0.0;

    final total = q * per;

    // Deposit to portfolio cash (records a PortfolioTransfer)
    await ref.read(portfolioTransferProvider.notifier).depositToPortfolio(total, note: 'Dividend ${symbol} received');

    // Create a hidden transaction and add it so it can be linked to the dividend for reversible delete
    final txn = Transaction(type: TransactionType.income, amount: total, category: 'Dividend', accountId: 'portfolio', date: _date, notes: 'Dividend from $company ($symbol)', hiddenFromGlobal: true);
    ref.read(transactionProvider.notifier).addTransaction(txn);

    // Now create dividend with link to transaction id
    final dividend = Dividend(symbol: symbol, companyName: company, transactionId: txn.id, amountPerShare: per, totalReceived: total, date: _date);
    ref.read(dividendProvider.notifier).addDividend(dividend);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dividend recorded')));
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(holdingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Add Dividend', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Text(
                'Asset Information',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Company Input Field with integrated modern selector
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: const Icon(Icons.business_outlined),
                  suffixIcon: Theme(
                    // Style the popup button context menu beautifully
                    data: Theme.of(context).copyWith(
                      cardColor: Theme.of(context).colorScheme.surface,
                    ),
                    child: PopupMenuButton<String>(
                      tooltip: 'Select from holdings',
                      icon: Icon(Icons.manage_search, color: Theme.of(context).colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (v) {
                        final h = holdings.firstWhere((e) => e.symbol == v);
                        setState(() {
                          _companyController.text = h.companyName;
                          _symbolController.text = h.symbol;
                          _quantityController.text = h.quantity.toString();
                        });
                      },
                      itemBuilder: (ctx) => holdings
                          .map((h) => PopupMenuItem(
                        value: h.symbol,
                        child: Text('${h.companyName} (${h.symbol})'),
                      ))
                          .toList(),
                    ),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter company name' : null,
              ),
              const SizedBox(height: 16),

              // Symbol & Quantity row for a more compact, screen-efficient layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _symbolController,
                      decoration: InputDecoration(
                        labelText: 'Symbol',
                        prefixIcon: const Icon(Icons.label_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dividend Yield Details
              TextFormField(
                controller: _perShareController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount Per Share',
                  prefixText: 'Rs. ',
                  prefixIcon: const Icon(Icons.paid_outlined),
                  prefixStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter amount > 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section Header: Transaction Timing
              Text(
                'Payment Timeline',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Clean, interactive Card layout for Date Picking
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Theme.of(context).colorScheme.surface,
                child: ListTile(
                  leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Dividend Date', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    DateFormat.yMMMd().format(_date),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (!(_formKey.currentState?.validate() ?? false)) {
                      setState(() => _autoValidate = true);
                      return;
                    }
                    await _submit();
                  },
                  child: const Text(
                    'Save Dividend',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
