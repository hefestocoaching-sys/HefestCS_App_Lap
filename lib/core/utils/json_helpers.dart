import 'dart:convert';
import 'package:flutter/foundation.dart';

class SafeJson {
  static Map<String, dynamic>? decode(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      debugPrint('JSON decode returned non-map: ${decoded.runtimeType}');
      return null;
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return null;
    }
  }

  static String encode(dynamic object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      debugPrint('JSON encode error: $e');
      return '{}';
    }
  }
}
