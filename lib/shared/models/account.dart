import 'package:uuid/uuid.dart';
import 'dart:convert';

enum AccountType {
  bank,
  wallet,
  savings,
  investment,
  cash,
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final DateTime lastActivity;
  final DateTime createdAt;

  Account({
    String? id,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    required this.currentBalance,
    required this.lastActivity,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Account copyWith({
    String? name,
    AccountType? type,
    String? currency,
    double? initialBalance,
    double? currentBalance,
    DateTime? lastActivity,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      lastActivity: lastActivity ?? this.lastActivity,
      createdAt: createdAt,
    );
  }

  double get gain => currentBalance - initialBalance;
  double get gainPercent =>
      initialBalance > 0 ? (gain / initialBalance) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'currency': currency,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance,
      'lastActivity': lastActivity.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: AccountType.values
          .firstWhere((e) => e.name == (json['type'] as String)),
      currency: json['currency'] as String,
      initialBalance: (json['initialBalance'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
