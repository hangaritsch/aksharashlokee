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

  /// Search shlokas by query (searches content, reference, akshara, & Devanagari transliteration)
  static Future<List<Shloka>> searchShlokas(String query, {String? devanagariQuery}) async {
    if (query.isEmpty) {
      return [];
    }

    final shlokas = await getAllShlokas();
    final lowerQuery = query.toLowerCase();
    final lowerDevanagari = devanagariQuery?.toLowerCase() ?? '';

    return shlokas.where((s) {
      final content = s.content.toLowerCase();
      final reference = s.reference.toLowerCase();
      final akshara = s.akshara.toLowerCase();

      final matchesDirect = content.contains(lowerQuery) ||
          reference.contains(lowerQuery) ||
          akshara.contains(lowerQuery);

      if (matchesDirect) return true;

      if (lowerDevanagari.isNotEmpty) {
        return content.contains(lowerDevanagari) ||
            reference.contains(lowerDevanagari) ||
            akshara.contains(lowerDevanagari);
      }

      return false;
    }).toList();
  }

  /// Clear cache (useful if file might have been updated)
  static void clearCache() {
    _cachedShlokas = null;
  }
}
