import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Contiene los volúmenes de entrenamiento (en series semanales) para un grupo muscular.
class MuscleVolume extends Equatable {
  /// Volumen Mínimo Efectivo: La cantidad mínima de trabajo para mantener o ganar músculo.
  final int vme;

  /// Volumen Máximo Adaptativo: El rango ideal de volumen para maximizar las ganancias.
  final int vma;

  /// Volumen Máximo Recuperable: El máximo volumen del que un atleta puede recuperarse.
  final int vmr;

  const MuscleVolume({required this.vme, required this.vma, required this.vmr});

  @override
  List<Object?> get props => [vme, vma, vmr];

  Map<String, dynamic> toMap() {
    return {'vme': vme, 'vma': vma, 'vmr': vmr};
  }

  factory MuscleVolume.fromMap(Map<String, dynamic> map) {
    return MuscleVolume(
      vme: map['vme']?.toInt() ?? 0,
      vma: map['vma']?.toInt() ?? 0,
      vmr: map['vmr']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory MuscleVolume.fromJson(String source) =>
      MuscleVolume.fromMap(json.decode(source));
}

/// Representa el perfil de volumen de entrenamiento completo para un cliente.
class VolumeProfile extends Equatable {
  final Map<String, MuscleVolume> volumesByMuscle;

  const VolumeProfile({required this.volumesByMuscle});

  @override
  List<Object?> get props => [volumesByMuscle];

  Map<String, dynamic> toMap() {
    return {
      'volumesByMuscle': volumesByMuscle.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  factory VolumeProfile.fromMap(Map<String, dynamic> map) {
    return VolumeProfile(
      volumesByMuscle:
          (map['volumesByMuscle'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              MuscleVolume.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
    );
  }

  String toJson() => json.encode(toMap());

  factory VolumeProfile.fromJson(String source) =>
      VolumeProfile.fromMap(json.decode(source));
}
