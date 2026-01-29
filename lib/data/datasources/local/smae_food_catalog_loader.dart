import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hcs_app_lap/domain/entities/smae_food.dart';

class SmaeFoodCatalogLoader {
  List<SmaeFood>? _cache;
  bool _loading = false;

  Future<List<SmaeFood>> load() async {
    if (_cache != null) return _cache!;
    if (_loading) {
      while (_cache == null) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _cache!;
    }
    _loading = true;
    try {
      final raw = await rootBundle.loadString(
        'assets/data/smae_food_catalog.json',
      );
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cache = decoded
          .whereType<Map<String, dynamic>>()
          .map(SmaeFood.fromJson)
          .where((f) => f.id.isNotEmpty && f.nameEs.isNotEmpty)
          .toList();
      return _cache!;
    } finally {
      _loading = false;
    }
  }
}

final smaeFoodCatalogLoader = SmaeFoodCatalogLoader();
