import 'package:uuid/uuid.dart';
import 'dart:convert';

enum TransactionType {
  income,
  expense,
  transfer,
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final String accountId;
  final String? toAccountId;
  final DateTime date;
  final String? notes;
  final bool hiddenFromGlobal; // when true transaction is not shown in global transactions list
  final DateTime createdAt;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    required this.category,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.notes,
    this.hiddenFromGlobal = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Transaction copyWith({
    TransactionType? type,
    double? amount,
    String? category,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    String? notes,
    bool? hiddenFromGlobal,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      hiddenFromGlobal: hiddenFromGlobal ?? this.hiddenFromGlobal,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'category': category,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'date': date.toIso8601String(),
      'notes': notes,
      'hiddenFromGlobal': hiddenFromGlobal,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String?,
      type: TransactionType.values.firstWhere((e) => e.name == (json['type'] as String)),
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      accountId: json['accountId'] as String,
      toAccountId: json['toAccountId'] as String?,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      hiddenFromGlobal: (json['hiddenFromGlobal'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TransactionCategories {
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
    'Gift',
    'Other Income',
  ];

  static const List<String> expenseCategories = [
    'Food & Dining',
    'Shopping',
    'Transportation',
    'Bills & Utilities',
    'Entertainment',
    'Healthcare',
    'Education',
    'Travel',
    'Other Expense',
  ];
}
