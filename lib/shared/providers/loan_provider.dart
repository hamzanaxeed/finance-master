import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';

class LoanNotifier extends StateNotifier<List<Loan>> {
  LoanNotifier() : super([]);

  void addLoan(Loan loan) {
    state = [...state, loan];
  }

  void updateLoan(String id, Loan loan) {
    state = [
      for (final l in state)
        if (l.id == id) loan else l,
    ];
  }

  void deleteLoan(String id) {
    state = state.where((l) => l.id != id).toList();
  }

  Loan? getLoanById(String id) {
    try {
      return state.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  void makePayment(String id, double amount) {
    final loan = getLoanById(id);
    if (loan != null) {
      updateLoan(
        id,
        loan.copyWith(
          remainingAmount: loan.remainingAmount - amount,
        ),
      );
    }
  }
}

final loanProvider = StateNotifierProvider<LoanNotifier, List<Loan>>((ref) {
  return LoanNotifier();
});

final totalDebtProvider = Provider<double>((ref) {
  final loans = ref.watch(loanProvider);
  return loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);
});
