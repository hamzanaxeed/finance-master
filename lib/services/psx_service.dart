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
      final sw = Stopwatch()..start();
      debugPrint('PSXService: fetching $s -> $url');
      final resp = await _client.get(url).timeout(timeout);
      sw.stop();
      debugPrint('PSXService: response ${resp.statusCode} for $s (took ${sw.elapsedMilliseconds} ms)');
      // Print body snippet for debugging (avoid huge logs)
      final bodySnippet = resp.body.length > 500 ? '${resp.body.substring(0, 500)}...<truncated>' : resp.body;
      debugPrint('PSXService: body for $s: $bodySnippet');
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final Map<String, dynamic> json = jsonDecode(resp.body) as Map<String, dynamic>;
      final status = json['status'];
      debugPrint('PSXService: parsed status=$status for $s');
      if (status == null || status.toString() != '1') {
        // message can be String or Map; normalize to string safely
        final dynamic msgVal = json['message'];
        String msg;
        if (msgVal == null) {
          msg = 'Invalid symbol or empty data';
        } else if (msgVal is String) {
          msg = msgVal;
        } else if (msgVal is Map && msgVal.values.isNotEmpty) {
          // try to extract a nested message string from common keys
          if (msgVal['message'] is String) msg = msgVal['message'] as String;
          else if (msgVal['msg'] is String) msg = msgVal['msg'] as String;
          else msg = msgVal.toString();
        } else {
          msg = msgVal.toString();
        }
        debugPrint('PSXService: invalid symbol or message for $s -> $msg');
        throw InvalidSymbolException(symbol: s, message: msg);
      }

      // Normalize data: API sometimes returns list or nested map containing the list
      final dynamic rawData = json['data'];
      List<dynamic>? data;
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map) {
        // attempt to find a list inside the map under common keys
        if (rawData['data'] is List) data = rawData['data'] as List<dynamic>;
        else if (rawData['series'] is List) data = rawData['series'] as List<dynamic>;
        else {
          // If the map itself represents a single datapoint, try to wrap it
          // but prefer to treat as invalid
          data = null;
        }
      } else {
        data = null;
      }

      debugPrint('PSXService: data length for $s = ${data?.length ?? 0}');
      if (data == null || data.isEmpty) throw Exception('Empty data');
      final first = data.first as List<dynamic>;
      debugPrint('PSXService: first data point for $s = $first');
      if (first.length < 2) throw Exception('Invalid data');
      final price = (first[1] as num).toDouble();
      debugPrint('PSXService: extracted price for $s = $price');
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
