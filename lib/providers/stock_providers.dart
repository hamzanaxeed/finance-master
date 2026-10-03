import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/stock_repository.dart';
import '../models/stock_models.dart';
import '../shared/providers/portfolio_provider.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final repo = StockRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// User-configurable watchlist
final watchlistProvider = StateProvider<List<String>>((ref) => ['HUBC', 'ENGRO', 'MARI', 'OGDC', 'FFC']);

// Lifecycle-aware refresher: pauses when app is backgrounded
class _AutoRefresher with WidgetsBindingObserver {
  final Ref ref;
  final StockRepository repo;
  Timer? _timer;
  bool _running = false;

  _AutoRefresher(this.ref, this.repo) {
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    if (_running) return;
    _running = true;
    // initial tick
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  Future<void> _tick() async {
    try {
      final list = ref.read(watchlistProvider);
      if (list.isNotEmpty) await repo.fetchSymbols(list);
    } catch (e) {
      // swallow errors; repository will fallback to cache
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stop();
    } else if (state == AppLifecycleState.resumed) {
      _start();
    }
  }

  void dispose() {
    _stop();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }
}

final psxAutoRefreshProvider = Provider<void>((ref) {
  final repo = ref.read(stockRepositoryProvider);
  final refresher = _AutoRefresher(ref, repo);
  ref.onDispose(() => refresher.dispose());
  return null;
});

// Single symbol quote provider (uses repository caching)
final stockPriceProvider = FutureProvider.family<StockQuote, String>((ref, symbol) async {
  final repo = ref.read(stockRepositoryProvider);
  final q = await repo.getQuote(symbol);
  return q;
});

// Portfolio summary computed from existing holdings provider (from portfolio_provider.dart)
final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) async {
  // ensure auto refresh runs
  ref.read(psxAutoRefreshProvider);
  final repo = ref.read(stockRepositoryProvider);
  // holdingsProvider is defined elsewhere; use it
  final holdings = ref.read(holdingsProvider);
  if (holdings.isEmpty) return PortfolioSummary(totalInvested: 0, totalMarketValue: 0);
  final symbols = holdings.map((h) => h.symbol).toSet().toList();
  final quotes = await repo.fetchSymbols(symbols);
  double totalInvested = 0;
  double totalMarket = 0;
  for (final h in holdings) {
    final invested = h.totalInvestment; // existing StockHolding model has totalInvestment
    totalInvested += invested;
    final quote = quotes[h.symbol];
    final price = quote?.price ?? repo.snapshot()[h.symbol]?.price ?? 0.0;
    totalMarket += h.quantity * price;
  }
  return PortfolioSummary(totalInvested: totalInvested, totalMarketValue: totalMarket);
});
