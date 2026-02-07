import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> sanitizeForFirestore(Map<String, dynamic> data) {
  final result = <String, dynamic>{};

  dynamic sanitizeValue(dynamic value) {
    if (value == null) return null;
    if (value is String || value is bool) return value;
    if (value is num) {
      if (value is double && !value.isFinite) return null;
      return value;
    }
    if (value is Timestamp) return value;
    if (value is FieldValue) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is GeoPoint) return value;
    if (value is Enum) return value.name;
    if (value is Iterable) {
      return value.map(sanitizeValue).where((item) => item != null).toList();
    }
    if (value is Map) {
      final map = <String, dynamic>{};
      value.forEach((key, nestedValue) {
        final sanitized = sanitizeValue(nestedValue);
        if (nestedValue == null) {
          map[key.toString()] = null;
        } else if (sanitized != null) {
          map[key.toString()] = sanitized;
        }
      });
      return map;
    }

    return null;
  }

  data.forEach((key, value) {
    final sanitized = sanitizeValue(value);
    if (value == null) {
      result[key] = null;
    } else if (sanitized != null) {
      result[key] = sanitized;
    }
  });

  return result;
}

String? findInvalidFirestorePath(Map<String, dynamic> data) {
  String? scan(dynamic value, String path) {
    if (value == null) return null;
    if (value is String || value is bool) return null;
    if (value is num) {
      if (value is double && !value.isFinite) {
        return '$path (${value.runtimeType}: $value)';
      }
      return null;
    }
    if (value is Timestamp || value is FieldValue || value is GeoPoint) {
      return null;
    }
    if (value is DateTime) return null;
    if (value is Enum) return null;
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        final nested = scan(value[i], '$path[$i]');
        if (nested != null) return nested;
      }
      return null;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          return '$path.${key.toString()} (non-string key: ${key.runtimeType})';
        }
        final nested = scan(entry.value, '$path.$key');
        if (nested != null) return nested;
      }
      return null;
    }
    return '$path (${value.runtimeType})';
  }

  return scan(data, 'payloadRoot');
}
