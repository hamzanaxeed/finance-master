import 'package:uuid/uuid.dart';

enum LoanType {
  personal,
  home,
  auto,
  education,
  business,
}

class Loan {
  final String id;
  final String name;
  final LoanType type;
  final double totalAmount;
  final double remainingAmount;
  final double monthlyInstallment;
  final double interestRate;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime createdAt;

  Loan({
    String? id,
    required this.name,
    required this.type,
    required this.totalAmount,
    required this.remainingAmount,
    required this.monthlyInstallment,
    required this.interestRate,
    required this.startDate,
    required this.dueDate,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Loan copyWith({
    String? name,
    LoanType? type,
    double? totalAmount,
    double? remainingAmount,
    double? monthlyInstallment,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
  }) {
    return Loan(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      monthlyInstallment: monthlyInstallment ?? this.monthlyInstallment,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
    );
  }

  double get paidAmount => totalAmount - remainingAmount;
  double get progress => totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
}
