// New file: lib/models/stock_models.dart

class PSXHolding {
  final String symbol;
  final double quantity;
  final double averageBuyPrice;

  PSXHolding({required this.symbol, required this.quantity, required this.averageBuyPrice});

  double investedValue() => quantity * averageBuyPrice;
}

class StockQuote {
  final String symbol;
  final double price;
  final DateTime fetchedAt;

  StockQuote({required this.symbol, required this.price, required this.fetchedAt});

  Map<String, dynamic> toJson() => {'symbol': symbol, 'price': price, 'fetchedAt': fetchedAt.toIso8601String()};

  factory StockQuote.fromJson(Map<String, dynamic> json) => StockQuote(
        symbol: json['symbol'] as String,
        price: (json['price'] as num).toDouble(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
}

class PortfolioSummary {
  final double totalInvested;
  final double totalMarketValue;
  final double totalPnL;

  PortfolioSummary({required this.totalInvested, required this.totalMarketValue}) : totalPnL = totalMarketValue - totalInvested;

  double get pnlPercent => totalInvested == 0 ? 0 : (totalPnL / totalInvested) * 100;
}
