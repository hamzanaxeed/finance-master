import 'package:uuid/uuid.dart';

class Budget {
  final String id;
  final String category;
  final double monthlyLimit;
  final double spent;
  final String period;
  final DateTime createdAt;

  Budget({
    String? id,
    required this.category,
    required this.monthlyLimit,
    required this.spent,
    required this.period,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Budget copyWith({
    String? category,
    double? monthlyLimit,
    double? spent,
    String? period,
  }) {
    return Budget(
      id: id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      createdAt: createdAt,
    );
  }

  double get remaining => monthlyLimit - spent;
  double get percentUsed => monthlyLimit > 0 ? (spent / monthlyLimit) * 100 : 0;
  bool get isOverBudget => spent > monthlyLimit;
}
