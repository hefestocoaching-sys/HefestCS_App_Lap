enum ClientLevel { beginner, intermediate, advanced }

extension ClientLevelX on ClientLevel {
  String get label => switch (this) {
    ClientLevel.beginner => 'Recreativo/Principiante',
    ClientLevel.intermediate => 'Intermedio/Amateur',
    ClientLevel.advanced => 'Avanzado/Competidor',
  };
}
