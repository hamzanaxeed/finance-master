import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/portfolio.dart';

class StockTransactionNotifier extends StateNotifier<List<StockTransaction>> {
  StockTransactionNotifier() : super([]) {
    _loadStockTransactions();
  }

  void addTransaction(StockTransaction transaction) {
    state = [...state, transaction];
    _saveStockTransactions();
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

final stockTransactionProvider =
    StateNotifierProvider<StockTransactionNotifier, List<StockTransaction>>(
        (ref) {
  return StockTransactionNotifier();
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
