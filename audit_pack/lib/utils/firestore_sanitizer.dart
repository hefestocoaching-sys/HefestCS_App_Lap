import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

const _invalidFirestoreKeyChars = ['.', '~', '*', '/', '[', ']'];

bool _isValidFirestoreKey(String key) {
  if (key.isEmpty) return false;
  if (key.startsWith('__')) return false;
  for (final ch in _invalidFirestoreKeyChars) {
    if (key.contains(ch)) return false;
  }
  return true;
}

Map<String, dynamic> sanitizeForFirestore(Map<String, dynamic> data) {
  final result = <String, dynamic>{};

  dynamic sanitizeValue(dynamic value, {required bool inArray}) {
    if (value == null) return null;
    if (value is String || value is bool) return value;
    if (value is num) {
      if (value is double && !value.isFinite) return null;
      return value;
    }
    if (value is Timestamp) return value;
    if (value is FieldValue) {
      return inArray ? null : value;
    }
    if (value is Blob) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is GeoPoint) return value;
    if (value is Enum) return value.name;
    if (value is Uint8List) return Blob(value);
    if (value is Iterable) {
      return value
          .map((item) => sanitizeValue(item, inArray: true))
          .where((item) => item != null)
          .toList();
    }
    if (value is Map) {
      final map = <String, dynamic>{};
      value.forEach((key, nestedValue) {
        final keyString = key.toString();
        if (!_isValidFirestoreKey(keyString)) {
          return;
        }
        final sanitized = sanitizeValue(nestedValue, inArray: inArray);
        if (nestedValue == null) {
          map[keyString] = null;
        } else if (sanitized != null) {
          map[keyString] = sanitized;
        }
      });
      return map;
    }

    return null;
  }

  data.forEach((key, value) {
    final keyString = key.toString();
    if (!_isValidFirestoreKey(keyString)) {
      return;
    }
    final sanitized = sanitizeValue(value, inArray: false);
    if (value == null) {
      result[keyString] = null;
    } else if (sanitized != null) {
      result[keyString] = sanitized;
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
    if (value is Blob) return null;
    if (value is Uint8List) return null;
    if (value is DateTime) {
      return '$path (${value.runtimeType})';
    }
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
        if (!_isValidFirestoreKey(key)) {
          return '$path.$key (invalid firestore key)';
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

List<String> listInvalidFirestorePaths(
  Map<String, dynamic> data, {
  int limit = 20,
}) {
  final results = <String>[];

  void scan(dynamic value, String path) {
    if (results.length >= limit) return;
    if (value == null) return;
    if (value is String || value is bool) return;
    if (value is num) {
      if (value is double && !value.isFinite) {
        results.add('$path (${value.runtimeType}: $value)');
      }
      return;
    }
    if (value is Timestamp ||
        value is FieldValue ||
        value is GeoPoint ||
        value is Blob) {
      return;
    }
    if (value is Uint8List) return;
    if (value is DateTime) {
      results.add('$path (${value.runtimeType})');
      return;
    }
    if (value is Enum) return;
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        scan(value[i], '$path[$i]');
        if (results.length >= limit) return;
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          results.add('$path.${key.toString()} (non-string key: ${key.runtimeType})');
          if (results.length >= limit) return;
        } else if (!_isValidFirestoreKey(key)) {
          results.add('$path.$key (invalid firestore key)');
          if (results.length >= limit) return;
        }
        scan(entry.value, '$path.$key');
        if (results.length >= limit) return;
      }
      return;
    }
    results.add('$path (${value.runtimeType})');
  }

  scan(data, 'payloadRoot');
  return results;
}

List<String> listFirestoreAuditFindings(
  Map<String, dynamic> data, {
  int limit = 20,
}) {
  final results = <String>[];

  void scan(dynamic value, String path, {required bool inArray}) {
    if (results.length >= limit) return;
    if (value == null) return;
    if (value is String || value is bool) return;
    if (value is num) {
      if (value is double && !value.isFinite) {
        results.add('$path (non-finite double: $value)');
      }
      return;
    }
    if (value is Timestamp || value is GeoPoint || value is Blob) {
      return;
    }
    if (value is FieldValue) {
      if (inArray) {
        results.add('$path (FieldValue inside array)');
      }
      return;
    }
    if (value is DateTime) {
      results.add('$path (DateTime)');
      return;
    }
    if (value is Uint8List) {
      results.add('$path (Uint8List)');
      return;
    }
    if (value is Enum) {
      results.add('$path (Enum)');
      return;
    }
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        scan(value[i], '$path[$i]', inArray: true);
        if (results.length >= limit) return;
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          results.add('$path.${key.toString()} (non-string key: ${key.runtimeType})');
          if (results.length >= limit) return;
        } else {
          if (!_isValidFirestoreKey(key)) {
            results.add('$path.$key (invalid firestore key)');
            if (results.length >= limit) return;
          }
        }
        scan(entry.value, '$path.$key', inArray: inArray);
        if (results.length >= limit) return;
      }
      return;
    }
    results.add('$path (${value.runtimeType})');
  }

  scan(data, 'payloadRoot', inArray: false);
  return results;
}
