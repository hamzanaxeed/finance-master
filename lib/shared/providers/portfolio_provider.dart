import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/portfolio.dart';
import '../models/transaction.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';

class StockTransactionNotifier extends StateNotifier<List<StockTransaction>> {
  final Ref ref;

  StockTransactionNotifier(this.ref) : super([]) {
    _loadStockTransactions();
  }

  /// Adds a stock transaction. Returns true if successful. For BUY transactions
  /// the portfolio cash balance is checked and decreased by transaction.total.
  /// For SELL transactions the portfolio cash is increased by transaction.total.
  Future<bool> addTransaction(StockTransaction transaction) async {
    // Access portfolio cash
    final portfolioCashNotifier = ref.read(_portfolioCashProvider.notifier);
    final currentCash = ref.read(portfolioCashProvider);

    if (transaction.type == StockTransactionType.buy) {
      if (currentCash < transaction.total) {
        return false; // insufficient funds
      }
      // deduct from portfolio cash
      portfolioCashNotifier.withdraw(transaction.total);
    } else {
      // sell: add to portfolio cash
      portfolioCashNotifier.deposit(transaction.total);
    }

    state = [...state, transaction];
    await _saveStockTransactions();
    return true;
  }

  void deleteTransaction(String id) {
    state = state.where((txn) => txn.id != id).toList();
    _saveStockTransactions();
  }

  // Persistence
  static const String _stockKey = 'stock_transactions';

  Future<void> _saveStockTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((s) => s.toJson()).toList();
    await prefs.setString(_stockKey, jsonEncode(jsonList));
  }

  Future<void> _loadStockTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stockKey);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded
          .map((e) => StockTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  /// Delete all transactions for a given symbol (used when deleting a holding)
  void deleteTransactionsForSymbol(String symbol) {
    state = state.where((txn) => txn.symbol != symbol).toList();
    _saveStockTransactions();
  }
}


class DividendNotifier extends StateNotifier<List<Dividend>> {
  DividendNotifier() : super([]) {
    _loadDividends();
  }

  void addDividend(Dividend dividend) {
    state = [...state, dividend];
    _saveDividends();
  }

  void deleteDividend(String id) {
    state = state.where((div) => div.id != id).toList();
    _saveDividends();
  }

  // Persistence
  static const String _dividendKey = 'dividends';

  Future<void> _saveDividends() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((d) => d.toJson()).toList();
    await prefs.setString(_dividendKey, jsonEncode(jsonList));
  }

  Future<void> _loadDividends() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dividendKey);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => Dividend.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }
}

class CorporateActionNotifier extends StateNotifier<List<CorporateAction>> {
  CorporateActionNotifier() : super([]) {
    _loadActions();
  }

  void addAction(CorporateAction action) {
    state = [...state, action];
    _saveActions();
  }

  void deleteAction(String id) {
    state = state.where((action) => action.id == id).toList();
    _saveActions();
  }

  // Persistence
  static const String _actionsKey = 'corporate_actions';

  Future<void> _saveActions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((a) => a.toJson()).toList();
    await prefs.setString(_actionsKey, jsonEncode(jsonList));
  }

  Future<void> _loadActions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_actionsKey);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => CorporateAction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }
}

final stockTransactionProvider = StateNotifierProvider<StockTransactionNotifier, List<StockTransaction>>((ref) {
  return StockTransactionNotifier(ref);
});

final dividendProvider =
    StateNotifierProvider<DividendNotifier, List<Dividend>>((ref) {
  return DividendNotifier();
});

final corporateActionProvider =
    StateNotifierProvider<CorporateActionNotifier, List<CorporateAction>>(
        (ref) {
  return CorporateActionNotifier();
});

final holdingsProvider = Provider<List<StockHolding>>((ref) {
  final transactions = ref.watch(stockTransactionProvider);
  final priceHistoryMap = ref.watch(priceHistoryProvider);
  final holdingMeta = ref.watch(holdingMetaProvider);
  final Map<String, _HoldingData> holdings = {};

  for (final txn in transactions) {
    if (!holdings.containsKey(txn.symbol)) {
      holdings[txn.symbol] = _HoldingData(
        symbol: txn.symbol,
        companyName: holdingMeta[txn.symbol] ?? txn.symbol,
      );
    }

    final holding = holdings[txn.symbol]!;
    if (txn.type == StockTransactionType.buy) {
      holding.quantity += txn.quantity;
      holding.totalInvestment += txn.total;
      // initialize/update market price to the transaction price when buying
      holding.lastPrice = txn.price;
    } else {
      holding.quantity -= txn.quantity;
      holding.totalInvestment -= (txn.quantity * holding.averagePrice);
    }
  }

  // Consider any price history updates for symbols
  for (final entry in priceHistoryMap.entries) {
    final symbol = entry.key;
    final list = entry.value;
    if (list.isEmpty) continue;
    final last = list.last.price;
    if (!holdings.containsKey(symbol)) {
      holdings[symbol] = _HoldingData(symbol: symbol, companyName: holdingMeta[symbol] ?? symbol);
    }
    holdings[symbol]!.lastPrice = last;
  }

  return holdings.values
      .where((h) => h.quantity > 0)
      .map((h) => StockHolding(
            symbol: h.symbol,
            companyName: h.companyName,
            quantity: h.quantity,
            averagePrice: h.averagePrice,
            // currentPrice is independent from averagePrice; initialize from last buy price
            currentPrice: h.lastPrice > 0 ? h.lastPrice : h.averagePrice,
            totalInvestment: h.totalInvestment,
            // currentValue uses currentPrice (market price), initialized from last buy price
            currentValue: h.quantity * (h.lastPrice > 0 ? h.lastPrice : h.averagePrice),
          ))
      .toList();
});

class _HoldingData {
  final String symbol;
  final String companyName;
  double quantity = 0;
  double totalInvestment = 0;
  double lastPrice = 0; // market price independent of cost basis

  _HoldingData({
    required this.symbol,
    required this.companyName,
  });

  double get averagePrice =>
      quantity > 0 ? totalInvestment / quantity : 0;
}

// Price history notifier - stores list of PricePoint per symbol and persists
class PriceHistoryNotifier extends StateNotifier<Map<String, List<PricePoint>>> {
  PriceHistoryNotifier() : super({}) {
    _load();
  }

  static const String _key = 'price_history';

  void addPricePoint(String symbol, PricePoint p) {
    final newState = Map<String, List<PricePoint>>.from(state);
    final list = List<PricePoint>.from(newState[symbol] ?? []);
    list.add(p);
    newState[symbol] = list;
    state = newState;
    _save();
  }

  void setHistory(String symbol, List<PricePoint> list) {
    final newState = Map<String, List<PricePoint>>.from(state);
    newState[symbol] = list;
    state = newState;
    _save();
  }

  List<PricePoint> getHistory(String symbol) => state[symbol] ?? [];

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = state.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()));
    await prefs.setString(_key, jsonEncode(map));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, List<PricePoint>>{};
      decoded.forEach((k, v) {
        final List<dynamic> arr = v as List<dynamic>;
        result[k] = arr.map((e) => PricePoint.fromJson(e as Map<String, dynamic>)).toList();
      });
      state = result;
    } catch (_) {}
  }
}

final priceHistoryProvider = StateNotifierProvider<PriceHistoryNotifier, Map<String, List<PricePoint>>>((ref) {
  return PriceHistoryNotifier();
});

// Latest price for a given symbol (null if none)
final latestPriceProvider = Provider.family<double?, String>((ref, symbol) {
  final map = ref.watch(priceHistoryProvider);
  final list = map[symbol];
  if (list == null || list.isEmpty) return null;
  return list.last.price;
});

// Holding meta like editable company name
class HoldingMetaNotifier extends StateNotifier<Map<String, String>> {
  HoldingMetaNotifier() : super({}) {
    _load();
  }

  static const String _key = 'holding_meta';

  void updateCompanyName(String symbol, String name) {
    final newState = Map<String, String>.from(state);
    newState[symbol] = name;
    state = newState;
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {}
  }
}

final holdingMetaProvider = StateNotifierProvider<HoldingMetaNotifier, Map<String, String>>((ref) {
  return HoldingMetaNotifier();
});

// ---------------- Portfolio cash and transfers ----------------

// Internal provider token for notifier access
final _portfolioCashProvider = StateNotifierProvider<PortfolioCashNotifier, double>((ref) {
  return PortfolioCashNotifier();
});

// Public alias
final portfolioCashProvider = Provider<double>((ref) => ref.watch(_portfolioCashProvider));

class PortfolioCashNotifier extends StateNotifier<double> {
  PortfolioCashNotifier() : super(0) {
    _load();
  }

  static const String _key = 'portfolio_cash_balance';

  void deposit(double amount) {
    state = state + amount;
    _save();
  }

  void withdraw(double amount) {
    state = state - amount;
    if (state < 0) state = 0; // safety
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, state);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble(_key);
    if (v != null) state = v;
  }
}

// Transfers between accounts and portfolio are recorded here
class PortfolioTransferNotifier extends StateNotifier<List<PortfolioTransfer>> {
  final Ref ref;

  PortfolioTransferNotifier(this.ref) : super([]) {
    _load();
  }

  static const String _key = 'portfolio_transfers';

  Future<void> transferFromAccountToPortfolio(String accountId, double amount, {String? note}) async {
    // withdraw from account
    ref.read(accountProvider.notifier).updateBalance(accountId, -amount);
    // deposit to portfolio
    ref.read(_portfolioCashProvider.notifier).deposit(amount);
    final t = PortfolioTransfer(fromAccountId: accountId, toAccountId: null, amount: amount, date: DateTime.now(), note: note);
    state = [...state, t];
    await _save();

    // record as general transaction
    final txn = Transaction(type: TransactionType.transfer, amount: amount, category: 'Portfolio transfer in', accountId: accountId, toAccountId: null, date: DateTime.now());
    ref.read(transactionProvider.notifier).addTransaction(txn);
  }

  Future<void> transferFromPortfolioToAccount(String accountId, double amount, {String? note}) async {
    // withdraw from portfolio
    ref.read(_portfolioCashProvider.notifier).withdraw(amount);
    // deposit to account
    ref.read(accountProvider.notifier).updateBalance(accountId, amount);
    final t = PortfolioTransfer(fromAccountId: null, toAccountId: accountId, amount: amount, date: DateTime.now(), note: note);
    state = [...state, t];
    await _save();

    final txn = Transaction(type: TransactionType.transfer, amount: amount, category: 'Portfolio transfer out', accountId: accountId, toAccountId: null, date: DateTime.now());
    ref.read(transactionProvider.notifier).addTransaction(txn);
  }

  /// Directly deposit to portfolio cash without an account transfer. Records a PortfolioTransfer with null accounts.
  Future<void> depositToPortfolio(double amount, {String? note}) async {
    ref.read(_portfolioCashProvider.notifier).deposit(amount);
    final t = PortfolioTransfer(fromAccountId: null, toAccountId: null, amount: amount, date: DateTime.now(), note: note ?? 'Deposit to portfolio');
    state = [...state, t];
    await _save();
  }

  /// Directly withdraw from portfolio cash without an account transfer. Records a PortfolioTransfer with null accounts.
  Future<void> withdrawFromPortfolio(double amount, {String? note}) async {
    ref.read(_portfolioCashProvider.notifier).withdraw(amount);
    final t = PortfolioTransfer(fromAccountId: null, toAccountId: null, amount: -amount, date: DateTime.now(), note: note ?? 'Withdraw from portfolio');
    state = [...state, t];
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = state.map((t) => t.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => PortfolioTransfer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }
}

final portfolioTransferProvider = StateNotifierProvider<PortfolioTransferNotifier, List<PortfolioTransfer>>((ref) {
  return PortfolioTransferNotifier(ref);
});

// Total invested into portfolio = sum of transfers into portfolio - sum out
final portfolioTotalInvestedProvider = Provider<double>((ref) {
  final transfers = ref.watch(portfolioTransferProvider);
  double invested = 0.0;

  for (var t in transfers) {
    // account -> portfolio (inflow)
    if (t.fromAccountId != null && t.toAccountId == null) {
      invested += t.amount.abs();
      continue;
    }

    // portfolio -> account (outflow)
    if (t.fromAccountId == null && t.toAccountId != null) {
      invested -= t.amount.abs();
      continue;
    }

    // both null: external deposit/withdrawal recorded directly; respect sign but use abs for clarity
    if (t.fromAccountId == null && t.toAccountId == null) {
      if (t.amount >= 0) invested += t.amount.abs();
      else invested -= t.amount.abs(); // external withdrawal recorded as negative amount
      continue;
    }

    // Fallback: if data shape unexpected, treat positive amount as inflow
    invested += t.amount;
  }

  return invested;
});

// Portfolio holdings value = sum of holdings currentValue
final portfolioHoldingsValueProvider = Provider<double>((ref) {
  final holdings = ref.watch(holdingsProvider);
  return holdings.fold(0.0, (sum, h) => sum + h.currentValue);
});

// Portfolio total value = cash + holdings value
final portfolioTotalValueProvider = Provider<double>((ref) {
  final cash = ref.watch(portfolioCashProvider);
  final holdings = ref.watch(portfolioHoldingsValueProvider);
  return cash + holdings;
});
