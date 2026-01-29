import 'dart:math';

/// Genera un código de invitación único en formato HCS-XXXX-XXXX
/// Ejemplo: HCS-A7K9-2M4P
class InvitationCodeGenerator {
  static const String _prefix = 'HCS';
  static const String _chars =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sin 0,O,1,I para evitar confusión
  static final Random _random = Random();

  /// Genera un código de invitación único
  static String generate() {
    final part1 = _generateSegment(4);
    final part2 = _generateSegment(4);
    return '$_prefix-$part1-$part2';
  }

  static String _generateSegment(int length) {
    return List.generate(
      length,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }

  /// Valida que un código tenga el formato correcto
  static bool isValid(String code) {
    final pattern = RegExp(r'^HCS-[A-Z2-9]{4}-[A-Z2-9]{4}$');
    return pattern.hasMatch(code);
  }

  /// Limpia un código removiendo espacios y convirtiendo a mayúsculas
  static String normalize(String code) {
    return code.replaceAll(' ', '').toUpperCase();
  }
}
