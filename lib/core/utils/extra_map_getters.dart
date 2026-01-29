// Helper para lectura segura de training.extra usando constantes
// Evita typos silenciosos y centraliza validación de tipos

class ExtraMapGetters {
  /// Lee un valor genérico con fallback tipado
  static T? read<T>(
    Map<String, dynamic>? extra,
    String key, [
    T? defaultValue,
  ]) {
    if (extra == null) return defaultValue;
    final value = extra[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Lee un int con validación y conversión
  static int? readInt(
    Map<String, dynamic>? extra,
    String key, [
    int? defaultValue,
  ]) {
    if (extra == null) return defaultValue;
    final value = extra[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return defaultValue;
  }

  /// Lee un double con validación y conversión
  static double? readDouble(
    Map<String, dynamic>? extra,
    String key, [
    double? defaultValue,
  ]) {
    if (extra == null) return defaultValue;
    final value = extra[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return defaultValue;
  }

  /// Lee un string con trim
  static String? readString(
    Map<String, dynamic>? extra,
    String key, [
    String? defaultValue,
  ]) {
    if (extra == null) return defaultValue;
    final value = extra[key];
    if (value is String) return value.trim();
    if (value != null) return value.toString().trim();
    return defaultValue;
  }

  /// Lee un List de String
  static List<String> readStringList(
    Map<String, dynamic>? extra,
    String key, [
    List<String>? defaultValue,
  ]) {
    if (extra == null) return defaultValue ?? const [];
    final value = extra[key];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return defaultValue ?? const [];
  }

  /// Lee un List dinámico
  static List<dynamic> readList(
    Map<String, dynamic>? extra,
    String key, [
    List<dynamic>? defaultValue,
  ]) {
    if (extra == null) return defaultValue ?? const [];
    final value = extra[key];
    if (value is List) return value;
    return defaultValue ?? const [];
  }

  /// Lee un mapa de String a dynamic
  static Map<String, dynamic>? readMap(
    Map<String, dynamic>? extra,
    String key, [
    Map<String, dynamic>? defaultValue,
  ]) {
    if (extra == null) return defaultValue;
    final value = extra[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return defaultValue;
  }

  /// Lee un bool con conversión desde string
  static bool readBool(
    Map<String, dynamic>? extra,
    String key, [
    bool defaultValue = false,
  ]) {
    if (extra == null) return defaultValue;
    final value = extra[key];
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' ||
          value.toLowerCase() == '1' ||
          value.toLowerCase() == 'yes';
    }
    return defaultValue;
  }

  /// Escribe un valor con validación de tipo
  static void write<T>(Map<String, dynamic> extra, String key, T? value) {
    if (value == null) {
      extra.remove(key);
    } else {
      extra[key] = value;
    }
  }

  /// Merge seguro: no sobrescribe valores existentes por defecto
  /// `force=true` para sobrescribir
  static void writeMap(
    Map<String, dynamic> extra,
    String key,
    Map<String, dynamic>? value, {
    bool force = true,
  }) {
    if (value == null) {
      extra.remove(key);
      return;
    }

    if (!force && extra.containsKey(key)) {
      // Merge con existente
      final existing = readMap(extra, key) ?? {};
      existing.addAll(value);
      extra[key] = existing;
    } else {
      extra[key] = value;
    }
  }
}

/// Extension para acceso directo desde un mapa de String a dynamic
extension ExtraMapExtension on Map<String, dynamic> {
  int? getInt(String key, [int? defaultValue]) =>
      ExtraMapGetters.readInt(this, key, defaultValue);

  double? getDouble(String key, [double? defaultValue]) =>
      ExtraMapGetters.readDouble(this, key, defaultValue);

  String? getString(String key, [String? defaultValue]) =>
      ExtraMapGetters.readString(this, key, defaultValue);

  List<String> getStringList(String key, [List<String>? defaultValue]) =>
      ExtraMapGetters.readStringList(this, key, defaultValue);

  List<dynamic> getList(String key, [List<dynamic>? defaultValue]) =>
      ExtraMapGetters.readList(this, key, defaultValue);

  Map<String, dynamic>? getMap(
    String key, [
    Map<String, dynamic>? defaultValue,
  ]) => ExtraMapGetters.readMap(this, key, defaultValue);

  bool getBool(String key, [bool defaultValue = false]) =>
      ExtraMapGetters.readBool(this, key, defaultValue);

  void setInt(String key, int? value) =>
      ExtraMapGetters.write(this, key, value);

  void setString(String key, String? value) =>
      ExtraMapGetters.write(this, key, value);

  void setDouble(String key, double? value) =>
      ExtraMapGetters.write(this, key, value);

  void setBool(String key, bool? value) =>
      ExtraMapGetters.write(this, key, value);

  void mergeMap(String key, Map<String, dynamic>? value, {bool force = true}) =>
      ExtraMapGetters.writeMap(this, key, value, force: force);
}
