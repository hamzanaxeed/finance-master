import 'package:uuid/uuid.dart';

enum StockTransactionType {
  buy,
  sell,
}

class StockHolding {
  final String id;
  final String symbol;
  final String companyName;
  final double quantity;
  final double averagePrice;
  final double currentPrice;
  final double totalInvestment;
  final double currentValue;

  StockHolding({
    String? id,
    required this.symbol,
    required this.companyName,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.totalInvestment,
    required this.currentValue,
  }) : id = id ?? const Uuid().v4();

  double get profitLoss => currentValue - totalInvestment;
  double get profitLossPercent =>
      totalInvestment > 0 ? (profitLoss / totalInvestment) * 100 : 0;
}

class PricePoint {
  final DateTime time;
  final double price;

  PricePoint({required this.time, required this.price});

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'price': price,
      };

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      time: DateTime.parse(json['time'] as String),
      price: (json['price'] as num).toDouble(),
    );
  }
}

class StockTransaction {
  final String id;
  final String symbol;
  final StockTransactionType type;
  final double quantity;
  final double price;
  final double commission;
  final DateTime date;
  final String? notes;

  StockTransaction({
    String? id,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.price,
    this.commission = 0,
    required this.date,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  double get total => (quantity * price) + commission;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type.name,
      'quantity': quantity,
      'price': price,
      'commission': commission,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'] as String?,
      symbol: json['symbol'] as String,
      type: StockTransactionType.values.firstWhere((e) => e.name == (json['type'] as String)),
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      commission: (json['commission'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }
}

class Dividend {
  final String id;
  final String symbol;
  final String companyName;
  final double amountPerShare;
  final double totalReceived;
  final DateTime date;

  Dividend({
    String? id,
    required this.symbol,
    required this.companyName,
    required this.amountPerShare,
    required this.totalReceived,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'companyName': companyName,
      'amountPerShare': amountPerShare,
      'totalReceived': totalReceived,
      'date': date.toIso8601String(),
    };
  }

  factory Dividend.fromJson(Map<String, dynamic> json) {
    return Dividend(
      id: json['id'] as String?,
      symbol: json['symbol'] as String,
      companyName: (json['companyName'] as String?) ?? (json['symbol'] as String),
      amountPerShare: (json['amountPerShare'] as num).toDouble(),
      totalReceived: (json['totalReceived'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}

enum CorporateActionType {
  split,
  bonus,
  rights,
}

class CorporateAction {
  final String id;
  final String symbol;
  final String companyName;
  final CorporateActionType type;
  final String ratio;
  final double oldQuantity;
  final double newQuantity;
  final DateTime date;
  final String? notes;

  CorporateAction({
    String? id,
    required this.symbol,
    required this.companyName,
    required this.type,
    required this.ratio,
    required this.oldQuantity,
    required this.newQuantity,
    required this.date,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'companyName': companyName,
      'type': type.name,
      'ratio': ratio,
      'oldQuantity': oldQuantity,
      'newQuantity': newQuantity,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory CorporateAction.fromJson(Map<String, dynamic> json) {
    return CorporateAction(
      id: json['id'] as String?,
      symbol: json['symbol'] as String,
      companyName: json['companyName'] as String,
      type: CorporateActionType.values.firstWhere((e) => e.name == (json['type'] as String)),
      ratio: json['ratio'] as String,
      oldQuantity: (json['oldQuantity'] as num).toDouble(),
      newQuantity: (json['newQuantity'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }
}

class PortfolioTransfer {
  final String id;
  final String? fromAccountId; // null when transfer is external
  final String? toAccountId; // null when transfer is external
  final double amount;
  final DateTime date;
  final String? note;

  PortfolioTransfer({
    String? id,
    this.fromAccountId,
    this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory PortfolioTransfer.fromJson(Map<String, dynamic> json) => PortfolioTransfer(
        id: json['id'] as String?,
        fromAccountId: json['fromAccountId'] as String?,
        toAccountId: json['toAccountId'] as String?,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );
}
