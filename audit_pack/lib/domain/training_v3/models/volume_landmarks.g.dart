// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume_landmarks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VolumeLandmarks _$VolumeLandmarksFromJson(Map<String, dynamic> json) =>
    _VolumeLandmarks(
      vme: (json['vme'] as num).toInt(),
      vop: (json['vop'] as num).toInt(),
      vmr: (json['vmr'] as num).toInt(),
      vmrTarget: (json['vmrTarget'] as num).toInt(),
    );

Map<String, dynamic> _$VolumeLandmarksToJson(_VolumeLandmarks instance) =>
    <String, dynamic>{
      'vme': instance.vme,
      'vop': instance.vop,
      'vmr': instance.vmr,
      'vmrTarget': instance.vmrTarget,
    };
