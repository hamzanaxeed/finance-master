import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';

class BudgetNotifier extends StateNotifier<List<Budget>> {
  BudgetNotifier() : super([]);

  void addBudget(Budget budget) {
    state = [...state, budget];
  }

  void updateBudget(String id, Budget budget) {
    state = [
      for (final b in state)
        if (b.id == id) budget else b,
    ];
  }

  void deleteBudget(String id) {
    state = state.where((b) => b.id != id).toList();
  }

  Budget? getBudgetById(String id) {
    try {
      return state.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }
}

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  return BudgetNotifier();
});
