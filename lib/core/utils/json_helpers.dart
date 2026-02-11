import 'dart:convert';
import 'package:hcs_app_lap/core/utils/app_logger.dart';

class SafeJson {
  static Map<String, dynamic>? decode(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      logger.debug('JSON decode returned non-map', {
        'type': decoded.runtimeType.toString(),
      });
      return null;
    } catch (e) {
      logger.error('JSON decode error', e);
      return null;
    }
  }

  static String encode(dynamic object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      logger.error('JSON encode error', e);
      return '{}';
    }
  }
}
