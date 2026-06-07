import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/transaction.dart';
import '../../core/storage/storage_utils.dart';

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier() : super([]) {
    _loadTransactions();
  }

  void addTransaction(Transaction transaction) {
    // insert newest transactions at the beginning so consumers see newest-first by default
    state = [transaction, ...state];
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

  // Persistence helpers moved into the class to allow access to 'state'
  static const String _prefsKey = 'transactions';

  Future<void> _saveTransactions() async {
    final jsonList = state.map((t) => t.toJson()).toList();
    await StorageUtils.safeSavePrefsString(_prefsKey, jsonEncode(jsonList));
  }

  Future<void> _loadTransactions() async {
    final raw = await StorageUtils.safeLoadPrefsString(_prefsKey);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
      // ensure newest-first ordering
      state.sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      // ignore and keep empty state
    }
  }

  // Public reload helper used after importing backups
  Future<void> reload() async => _loadTransactions();
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier();
});

// Category management: dynamic categories persisted in SharedPreferences
class CategoryState {
  final List<String> income;
  final List<String> expense;

  CategoryState({required this.income, required this.expense});

  Map<String, dynamic> toJson() => {
        'income': income,
        'expense': expense,
      };

  factory CategoryState.fromJson(Map<String, dynamic> json) => CategoryState(
        income: (json['income'] as List<dynamic>).map((e) => e as String).toList(),
        expense: (json['expense'] as List<dynamic>).map((e) => e as String).toList(),
      );
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  static const _prefsKey = 'transaction_categories_v2';

  CategoryNotifier()
      : super(CategoryState(income: TransactionCategories.incomeCategories.toList(), expense: TransactionCategories.expenseCategories.toList())) {
    _load();
  }

  Future<void> addCategory(TransactionType type, String name) async {
    final lower = name.trim();
    if (lower.isEmpty) return;
    if (type == TransactionType.income) {
      if (!state.income.contains(lower)) {
        state = CategoryState(income: [...state.income, lower], expense: state.expense);
        await _save();
      }
    } else if (type == TransactionType.expense) {
      if (!state.expense.contains(lower)) {
        state = CategoryState(income: state.income, expense: [...state.expense, lower]);
        await _save();
      }
    }
  }

  Future<void> deleteCategory(TransactionType type, String name) async {
    if (type == TransactionType.income) {
      state = CategoryState(income: state.income.where((c) => c != name).toList(), expense: state.expense);
      await _save();
    } else if (type == TransactionType.expense) {
      state = CategoryState(income: state.income, expense: state.expense.where((c) => c != name).toList());
      await _save();
    }
  }

  Future<void> _save() async {
    await StorageUtils.safeSavePrefsString(_prefsKey, jsonEncode(state.toJson()));
  }

  Future<void> _load() async {
    final raw = await StorageUtils.safeLoadPrefsString(_prefsKey);
    if (raw == null) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = CategoryState.fromJson(decoded);
    } catch (_) {}
  }

  // Public reload helper used after importing backups
  Future<void> reload() async => _load();
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier();
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  final now = DateTime.now();
  return transactions
      .where((txn) {
        // skip hidden transactions (e.g., dividends recorded as hidden income)
        try {
          final v = (txn as dynamic).hiddenFromGlobal;
          if (v is bool && v) return false;
        } catch (_) {}
        return txn.type == TransactionType.income && txn.date.month == now.month && txn.date.year == now.year;
      })
      .fold(0.0, (sum, txn) => sum + txn.amount);
});

final monthlyExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  final now = DateTime.now();
  return transactions
      .where((txn) {
        try {
          final v = (txn as dynamic).hiddenFromGlobal;
          if (v is bool && v) return false;
        } catch (_) {}
        return txn.type == TransactionType.expense && txn.date.month == now.month && txn.date.year == now.year;
      })
      .fold(0.0, (sum, txn) => sum + txn.amount);
});
