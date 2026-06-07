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
      debugPrint('StockRepository: loading cache from prefs ($_cacheKey)');
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        try {
          final sq = StockQuote.fromJson(v as Map<String, dynamic>);
          _cache[k] = sq;
        } catch (_) {}
      });
      debugPrint('StockRepository: loaded ${_cache.length} cached quotes');
    } catch (e) {
      debugPrint('StockRepository._loadCache failed: $e');
    }
  }

  Future<void> _saveCache() async {
    try {
      final map = _cache.map((k, v) => MapEntry(k, v.toJson()));
      await StorageUtils.safeSavePrefsString(_cacheKey, jsonEncode(map));
      debugPrint('StockRepository: saved ${_cache.length} quotes to cache');
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
      debugPrint('StockRepository.getQuote: cache hit for $s (age ${now.difference(cached.fetchedAt).inSeconds}s)');
      return cached;
    }
    if (cached != null) debugPrint('StockRepository.getQuote: cached but stale for $s (age ${now.difference(cached.fetchedAt).inSeconds}s)');
    debugPrint('StockRepository.getQuote: fetching $s from PSX');
    try {
      final sw = Stopwatch()..start();
      final fetched = await _service.fetchLatestPrice(s);
      sw.stop();
      debugPrint('StockRepository.getQuote: fetched $s price=${fetched.price} in ${sw.elapsedMilliseconds}ms');
      _cache[s] = fetched;
      // fire-and-forget cache save
      _saveCache();
      return fetched;
    } catch (e) {
      debugPrint('StockRepository.getQuote: fetch failed for $s: $e');
      if (cached != null) {
        debugPrint('StockRepository.getQuote: returning stale cached quote for $s');
        return cached; // fallback
      }
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
        debugPrint('StockRepository.fetchSymbols: success $s -> ${q.price}');
      } catch (e) {
        debugPrint('StockRepository.fetchSymbols: failed for $s: $e');
        if (e is InvalidSymbolException) {
          invalids.add(s);
        }
      }
    });
    await Future.wait(futures);
    debugPrint('StockRepository.fetchSymbols: completed ${results.length} successes, ${invalids.length} invalids');
    if (invalids.isNotEmpty) {
      throw InvalidSymbolsException(invalidSymbols: invalids, results: results);
    }
    return results;
  }

  /// Return in-memory snapshot of cache
  Map<String, StockQuote> snapshot() => Map<String, StockQuote>.from(_cache);

  void dispose() {
    try {
      debugPrint('StockRepository.dispose: disposing service');
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
