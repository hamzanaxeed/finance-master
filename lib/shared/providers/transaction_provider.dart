import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction.dart';

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier() : super([]) {
    _loadTransactions();
  }

  void addTransaction(Transaction transaction) {
    state = [...state, transaction];
    _saveTransactions();
  }

  void updateTransaction(String id, Transaction transaction) {
    state = [
      for (final txn in state)
        if (txn.id == id) transaction else txn,
    ];
    _saveTransactions();
  }

  void deleteTransaction(String id) {
    state = state.where((txn) => txn.id != id).toList();
    _saveTransactions();
  }

  Transaction? getTransactionById(String id) {
    try {
      return state.firstWhere((txn) => txn.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Transaction> getTransactionsByAccount(String accountId) {
    return state.where((txn) => txn.accountId == accountId).toList();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier();
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  final now = DateTime.now();
  return transactions
      .where((txn) =>
          txn.type == TransactionType.income &&
          txn.date.month == now.month &&
          txn.date.year == now.year)
      .fold(0.0, (sum, txn) => sum + txn.amount);
});

final monthlyExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  final now = DateTime.now();
  return transactions
      .where((txn) =>
          txn.type == TransactionType.expense &&
          txn.date.month == now.month &&
          txn.date.year == now.year)
      .fold(0.0, (sum, txn) => sum + txn.amount);
});

// Persistence helpers
extension on TransactionNotifier {
  static const String _prefsKey = 'transactions';

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((t) => t.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(jsonList));
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // ignore and keep empty state
    }
  }
}
