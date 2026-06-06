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
    final dividend = Dividend(symbol: symbol, companyName: company, amountPerShare: per, totalReceived: total, date: _date);

    // add dividend and deposit to portfolio cash
    ref.read(dividendProvider.notifier).addDividend(dividend);
    await ref.read(portfolioTransferProvider.notifier).depositToPortfolio(total, note: 'Dividend ${symbol} received');

    // Record an income transaction to the transactions provider so it shows in transaction history.
    // We use accountId 'portfolio' to indicate portfolio cash. Adjust if you prefer a real account id.
    final txn = Transaction(type: TransactionType.income, amount: total, category: 'Dividend', accountId: 'portfolio', date: _date, notes: 'Dividend from $company ($symbol)', hiddenFromGlobal: true);
    ref.read(transactionProvider.notifier).addTransaction(txn);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dividend recorded')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(holdingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Dividend')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(labelText: 'Company name', suffixIcon: PopupMenuButton<String>(
                  tooltip: 'Select from holdings',
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (v) {
                    final h = holdings.firstWhere((e) => e.symbol == v);
                    setState(() {
                      _companyController.text = h.companyName;
                      _symbolController.text = h.symbol;
                      _quantityController.text = h.quantity.toString();
                    });
                  },
                  itemBuilder: (ctx) => holdings.map((h) => PopupMenuItem(value: h.symbol, child: Text('${h.companyName} (${h.symbol})')) ).toList(),
                )),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter company name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(labelText: 'Symbol'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter symbol' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter quantity > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _perShareController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount per share (Rs)'),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter amount > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Date: ${DateFormat.yMMMd().format(_date)}'),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (d != null) setState(() => _date = d);
                  }, child: const Text('Change'))
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _submit();
                  },
                  child: const Text('Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
