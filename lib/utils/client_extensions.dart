import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/constants/history_extra_keys.dart';

extension ClientX on Client {
  int? get age => profile.age;
  String? get gender => profile.gender?.name;
  String? get clientLevel => profile.level?.name;

  List<dynamic>? get personalPathologicalHistory =>
      (history.extra[HistoryExtraKeys.personalPathologicalHistory] is List)
      ? history.extra[HistoryExtraKeys.personalPathologicalHistory]
            as List<dynamic>
      : [];
}

extension AnthropometryRecordX on AnthropometryRecord {
  double? get safeWeight => weightKg;
  double get bodyFatPercentage => 0.0;

  double get leanBodyMassKg {
    return safeWeight! * (1 - (bodyFatPercentage / 100));
  }
}

extension TrainingProfileX on TrainingProfile {
  // CORREGIDO: Apunta al getter correcto
  String? get levelName => trainingLevel?.label;
}
