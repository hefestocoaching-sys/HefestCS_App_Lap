import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:flutter/services.dart' show rootBundle;

List<FoodItem> _parseAndDecode(String responseBody) {
  final data = jsonDecode(responseBody);

  // Maneja ambos formatos:
  // 1. { "foods": [...] } (smae_database.json)
  // 2. [...] (smae_food_catalog.json - array directo)
  List foodList;
  if (data is Map && data.containsKey("foods")) {
    foodList = data["foods"] as List;
  } else if (data is List) {
    foodList = data;
  } else {
    return [];
  }

  return foodList
      .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
      .toList();
}

class FoodItem {
  final String id;
  final String group;
  final Map<String, double> nutrients;
  final String? name; // por si la columna "nombre" existe

  FoodItem({
    required this.id,
    required this.group,
    required this.nutrients,
    this.name,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Extraemos solo valores numéricos
    final nutrientMap = <String, double>{};
    json.forEach((key, value) {
      if (value is num) {
        nutrientMap[key] = value.toDouble();
      }
    });

    // Maneja ambos formatos de JSON:
    // smae_database.json: group, alimento
    // smae_food_catalog.json: smaeGroup, nameEs
    final group = json["group"] ?? json["smaeGroup"] ?? "Otros";
    final name = json["alimento"] ?? json["nameEs"] ?? json["name"];

    return FoodItem(
      id: json["id"] ?? "",
      group: group.toString(),
      name: name?.toString(),
      nutrients: nutrientMap,
    );
  }
}

class FoodDatabaseService {
  List<FoodItem> _foods = [];

  Future<void> loadDatabase() async {
    try {
      String raw;
      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;

      if (isDesktop) {
        // En desktop: intentar filesystem directamente (rootBundle no funciona en desktop)
        final currentDir = Directory.current;
        final assetPath =
            '${currentDir.path}/assets/data/smae_food_catalog.json';
        final file = File(assetPath);

        if (await file.exists()) {
          raw = await file.readAsString();
          logger.info('SMAE loaded from desktop path', {
            'path': assetPath,
          });
        } else {
          // Intento alternativo
          final altPath = 'assets/data/smae_food_catalog.json';
          final altFile = File(altPath);
          if (await altFile.exists()) {
            raw = await altFile.readAsString();
            logger.info('SMAE loaded from alternate path', {
              'path': altPath,
            });
          } else {
            throw FileSystemException(
              'Asset no encontrado. Intentadas rutas:\n- $assetPath\n- $altPath',
            );
          }
        }
      } else {
        // En mobile/web: usar rootBundle
        raw = await rootBundle.loadString('assets/data/smae_food_catalog.json');
        logger.info('SMAE loaded from rootBundle');
      }

      _foods = await compute(_parseAndDecode, raw);
      logger.info('SMAE catalog parsed', {
        'count': _foods.length,
      });
    } on FlutterError catch (e) {
      logger.error('Flutter error loading SMAE', e, e.stackTrace);
      _foods = [];
    } catch (e, st) {
      logger.error('Failed to load SMAE catalog', e, st);
      if (!kReleaseMode) {
        logger.debug('SMAE load stack trace', {'stackTrace': st.toString()});
      }
      _foods = [];
    }
  }

  List<FoodItem> search(String query) {
    query = query.toLowerCase();
    return _foods.where((f) {
      final foodName = f.name ?? '';
      return foodName.toLowerCase().contains(query);
    }).toList();
  }

  List<FoodItem> group(String groupName) {
    return _foods.where((f) => f.group == groupName).toList();
  }

  FoodItem? getById(String id) {
    for (final f in _foods) {
      if (f.id == id) return f;
    }
    return null;
  }
}

final foodDB = FoodDatabaseService();
