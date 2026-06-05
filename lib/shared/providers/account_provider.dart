import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/account.dart';

class AccountNotifier extends StateNotifier<List<Account>> {
  AccountNotifier() : super([]) {
    _loadAccounts();
  }

  void addAccount(Account account) {
    state = [...state, account];
    _saveAccounts();
  }

  void updateAccount(String id, Account account) {
    state = [
      for (final acc in state)
        if (acc.id == id) account else acc,
    ];
    _saveAccounts();
  }

  void deleteAccount(String id) {
    state = state.where((acc) => acc.id != id).toList();
    _saveAccounts();
  }

  Account? getAccountById(String id) {
    try {
      return state.firstWhere((acc) => acc.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateBalance(String id, double amount) {
    final account = getAccountById(id);
    if (account != null) {
      updateAccount(
        id,
        account.copyWith(
          currentBalance: account.currentBalance + amount,
          lastActivity: DateTime.now(),
        ),
      );
    }
  }

  // Persistence
  static const String _prefsKey = 'accounts';

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((a) => a.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(jsonList));
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // ignore and keep empty state
    }
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, List<Account>>((ref) {
  return AccountNotifier();
});

final totalAssetsProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountProvider);
  return accounts.fold(0.0, (sum, account) => sum + account.currentBalance);
});
