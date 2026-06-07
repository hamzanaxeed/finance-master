// New file: lib/services/psx_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/stock_models.dart';

class PSXService {
  final http.Client _client;
  PSXService({http.Client? client}) : _client = client ?? http.Client();

  Future<StockQuote> fetchLatestPrice(String symbol, {Duration timeout = const Duration(seconds: 8)}) async {
    final s = symbol.toUpperCase();
    final url = Uri.parse('https://dps.psx.com.pk/timeseries/int/$s');
    try {
      final resp = await _client.get(url).timeout(timeout);
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final Map<String, dynamic> json = jsonDecode(resp.body) as Map<String, dynamic>;
      final status = json['status'];
      if (status == null || status.toString() != '1') {
        final msg = (json['message'] as String?) ?? 'Invalid symbol or empty data';
        throw InvalidSymbolException(symbol: s, message: msg);
      }
      final data = json['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) throw Exception('Empty data');
      final first = data.first as List<dynamic>;
      if (first.length < 2) throw Exception('Invalid data');
      final price = (first[1] as num).toDouble();
      return StockQuote(symbol: s, price: price, fetchedAt: DateTime.now());
    } catch (e) {
      debugPrint('PSXService.fetchLatestPrice($symbol) failed: $e');
      rethrow;
    }
  }

  void dispose() {
    try {
      _client.close();
    } catch (_) {}
  }
}

class InvalidSymbolException implements Exception {
  final String symbol;
  final String message;
  InvalidSymbolException({required this.symbol, required this.message});
  @override
  String toString() => 'InvalidSymbolException: $symbol -> $message';
}
