import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/shloka.dart';

class LocalShlokaService {
  static const String _assetPath = 'assets/shlokas.json';
  static List<Shloka>? _cachedShlokas;

  /// Load all shlokas from local JSON file
  static Future<List<Shloka>> getAllShlokas() async {
    if (_cachedShlokas != null) {
      return _cachedShlokas!;
    }

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final jsonData = json.decode(jsonString);

      List<dynamic> shlokaList = jsonData['aksharas'] ?? [];
      _cachedShlokas = shlokaList
          .map((s) => Shloka.fromJson(s as Map<String, dynamic>))
          .toList();

      return _cachedShlokas!;
    } catch (e) {
      throw Exception('Failed to load shlokas: $e');
    }
  }

  /// Get unique aksharas from all shlokas
  static Future<List<String>> getAksharas() async {
    final shlokas = await getAllShlokas();
    final aksharas = shlokas.map((s) => s.akshara).toSet().toList();
    aksharas.sort();
    return aksharas;
  }

  /// Get shlokas for a specific akshara
  static Future<List<Shloka>> getShlokasByAkshara(String akshara) async {
    final shlokas = await getAllShlokas();
    return shlokas.where((s) => s.akshara == akshara).toList();
  }

  /// Get unique main grantha names from all shlokas
  static Future<List<String>> getGranthas() async {
    final shlokas = await getAllShlokas();
    final granthas = shlokas
        .map((s) => s.mainGrantha)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    granthas.sort();
    return granthas;
  }

  /// Get shlokas for a specific grantha
  static Future<List<Shloka>> getShlokasByGrantha(String grantha) async {
    final shlokas = await getAllShlokas();
    return shlokas.where((s) => s.mainGrantha == grantha).toList();
  }

  /// Filter shlokas by combining Akshara, Grantha, and text Search query
  static Future<List<Shloka>> getFilteredShlokas({
    String? akshara,
    String? grantha,
    String? query,
    String? devanagariQuery,
  }) async {
    final shlokas = await getAllShlokas();

    final lowerQuery = (query != null && query.trim().isNotEmpty)
        ? query.trim().toLowerCase()
        : null;
    final lowerDevanagari = (devanagariQuery != null && devanagariQuery.trim().isNotEmpty)
        ? devanagariQuery.trim().toLowerCase()
        : null;

    return shlokas.where((s) {
      // 1. Akshara Filter
      if (akshara != null && akshara.isNotEmpty && s.akshara != akshara) {
        return false;
      }

      // 2. Grantha Filter
      if (grantha != null && grantha.isNotEmpty && s.mainGrantha != grantha) {
        return false;
      }

      // 3. Search Query Filter
      if (lowerQuery != null) {
        final content = s.content.toLowerCase();
        final reference = s.reference.toLowerCase();
        final sAkshara = s.akshara.toLowerCase();

        final matchesDirect = content.contains(lowerQuery) ||
            reference.contains(lowerQuery) ||
            sAkshara.contains(lowerQuery);

        if (matchesDirect) return true;

        if (lowerDevanagari != null && lowerDevanagari.isNotEmpty) {
          return content.contains(lowerDevanagari) ||
              reference.contains(lowerDevanagari) ||
              sAkshara.contains(lowerDevanagari);
        }

        return false;
      }

      return true;
    }).toList();
  }

  /// Extracts Sanskrit word suggestions matching the input Devanagari query prefix/substring
  static Future<List<String>> getSanskritWordSuggestions(String devanagariQuery) async {
    if (devanagariQuery.trim().isEmpty) return [];

    final shlokas = await getAllShlokas();
    final term = devanagariQuery.trim();
    final suggestions = <String>{};

    for (var s in shlokas) {
      // Extract words from shloka content using Devanagari regex
      final words = s.content.split(RegExp(r'[\s।,॥\d\-\\\/]+'));
      for (var word in words) {
        final cleanWord = word.trim();
        if (cleanWord.length >= 2 && cleanWord.contains(term)) {
          suggestions.add(cleanWord);
          if (suggestions.length >= 8) break;
        }
      }
      if (suggestions.length >= 8) break;
    }

    return suggestions.toList();
  }

  /// Clear cache (useful if file might have been updated)
  static void clearCache() {
    _cachedShlokas = null;
  }
}
