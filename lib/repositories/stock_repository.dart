import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/psx_service.dart';
import '../models/stock_models.dart';
import '../core/storage/storage_utils.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class StockRepository {
  final PSXService _service;
  final Map<String, StockQuote> _cache = {}; // in-memory cache
  static const _cacheKey = 'psx_quote_cache_v1';

  StockRepository({PSXService? service}) : _service = service ?? PSXService() {
    _loadCache();
  }

  Future<void> _loadCache() async {
    try {
      final raw = await StorageUtils.safeLoadPrefsString(_cacheKey);
      if (raw == null) return;
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        try {
          final sq = StockQuote.fromJson(v as Map<String, dynamic>);
          _cache[k] = sq;
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('StockRepository._loadCache failed: $e');
    }
  }

  Future<void> _saveCache() async {
    try {
      final map = _cache.map((k, v) => MapEntry(k, v.toJson()));
      await StorageUtils.safeSavePrefsString(_cacheKey, jsonEncode(map));
    } catch (e) {
      debugPrint('StockRepository._saveCache failed: $e');
    }
  }

  /// Get quote from cache if fresh (<=30s) or fetch new
  Future<StockQuote> getQuote(String symbol, {Duration maxAge = const Duration(seconds: 30)}) async {
    final s = symbol.toUpperCase();
    final cached = _cache[s];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.fetchedAt) <= maxAge) {
      return cached;
    }
    try {
      final fetched = await _service.fetchLatestPrice(s);
      _cache[s] = fetched;
      // fire-and-forget cache save
      _saveCache();
      return fetched;
    } catch (e) {
      if (cached != null) return cached; // fallback
      rethrow;
    }
  }

  /// Fetch multiple symbols in parallel and update cache. Returns map of symbol->quote for successes.
  Future<Map<String, StockQuote>> fetchSymbols(List<String> symbols) async {
    final results = <String, StockQuote>{};
    final unique = symbols.map((s) => s.toUpperCase()).toSet().toList();
    final invalids = <String>[];
    final futures = unique.map((s) async {
      try {
        final q = await getQuote(s);
        results[s] = q;
      } catch (e) {
        debugPrint('fetchSymbols failed for $s: $e');
        if (e is InvalidSymbolException) {
          invalids.add(s);
        }
      }
    });
    await Future.wait(futures);
    if (invalids.isNotEmpty) {
      throw InvalidSymbolsException(invalidSymbols: invalids, results: results);
    }
    return results;
  }

  /// Return in-memory snapshot of cache
  Map<String, StockQuote> snapshot() => Map<String, StockQuote>.from(_cache);

  void dispose() {
    try {
      _service.dispose();
    } catch (_) {}
  }
}

class InvalidSymbolsException implements Exception {
  final List<String> invalidSymbols;
  final Map<String, StockQuote> results;
  InvalidSymbolsException({required this.invalidSymbols, required this.results});
  @override
  String toString() => 'InvalidSymbolsException: ${invalidSymbols.join(",")}';
}
