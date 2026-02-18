// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProgressRecord {

/// Identificadores
 String get userId; String get muscle; int get weekNumber;/// Volumen (sets/semana)
 int get volumePrescribed; int get volumePerformed; double get volumeAdherence;// 0.0-1.0 (volumePerformed/volumePrescribed)
/// Rango de repeticiones
 int get ripRange;// RIR realizado (promedio)
 int get ripTarget;// RIR objetivo (de plan)
/// Feedback del usuario (subjetivo, 1-10)
 double get muscleActivation;// Qué tan bien sentiste el músculo
 double get pumpQuality;// Calidad del pump
 double get fatigueLevel;// Fatiga acumulada
 double get recoveryQuality;// Calidad de recuperación
 bool get hadPain;// ¿Tuvo dolor?
 String get userComments;// Notas del usuario
/// Progresión de volumen (objetivo)
 String get exerciseAngles;// Ángulos usados (ej: "plano,inclinado,declinado")
 int get exerciseVariations;// Número de ejercicios/ángulos diferentes
/// Decisión del motor
 String get volumeAction;// 'increase', 'maintain', 'decrease', 'deload', 'microdeload'
 int get newVolume;// Volumen prescrpto para la siguiente semana
 String get progressionPhase;// 'discovering', 'maintaining', 'overreaching', 'deloading', 'microdeload'
 String get decisionReason;// Razón de la decisión (ej: "VMR discovered at 20 sets")
/// Deload info
 bool get wasDeload;// ¿Fue una semana de deload?
 String get deloadReason;// Razón del deload (si procede)
/// Timestamps
 DateTime get recordedAt;// Cuándo se registró
 DateTime get updatedAt;// Última actualización
/// Coach notes (opcional)
 String get coachNotes;// Notas que el coach quiera agregar
/// Metadata para auditoría
 Map<String, dynamic> get auditMetadata;
/// Create a copy of ProgressRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressRecordCopyWith<ProgressRecord> get copyWith => _$ProgressRecordCopyWithImpl<ProgressRecord>(this as ProgressRecord, _$identity);

  /// Serializes this ProgressRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressRecord&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.volumePrescribed, volumePrescribed) || other.volumePrescribed == volumePrescribed)&&(identical(other.volumePerformed, volumePerformed) || other.volumePerformed == volumePerformed)&&(identical(other.volumeAdherence, volumeAdherence) || other.volumeAdherence == volumeAdherence)&&(identical(other.ripRange, ripRange) || other.ripRange == ripRange)&&(identical(other.ripTarget, ripTarget) || other.ripTarget == ripTarget)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.pumpQuality, pumpQuality) || other.pumpQuality == pumpQuality)&&(identical(other.fatigueLevel, fatigueLevel) || other.fatigueLevel == fatigueLevel)&&(identical(other.recoveryQuality, recoveryQuality) || other.recoveryQuality == recoveryQuality)&&(identical(other.hadPain, hadPain) || other.hadPain == hadPain)&&(identical(other.userComments, userComments) || other.userComments == userComments)&&(identical(other.exerciseAngles, exerciseAngles) || other.exerciseAngles == exerciseAngles)&&(identical(other.exerciseVariations, exerciseVariations) || other.exerciseVariations == exerciseVariations)&&(identical(other.volumeAction, volumeAction) || other.volumeAction == volumeAction)&&(identical(other.newVolume, newVolume) || other.newVolume == newVolume)&&(identical(other.progressionPhase, progressionPhase) || other.progressionPhase == progressionPhase)&&(identical(other.decisionReason, decisionReason) || other.decisionReason == decisionReason)&&(identical(other.wasDeload, wasDeload) || other.wasDeload == wasDeload)&&(identical(other.deloadReason, deloadReason) || other.deloadReason == deloadReason)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.coachNotes, coachNotes) || other.coachNotes == coachNotes)&&const DeepCollectionEquality().equals(other.auditMetadata, auditMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,muscle,weekNumber,volumePrescribed,volumePerformed,volumeAdherence,ripRange,ripTarget,muscleActivation,pumpQuality,fatigueLevel,recoveryQuality,hadPain,userComments,exerciseAngles,exerciseVariations,volumeAction,newVolume,progressionPhase,decisionReason,wasDeload,deloadReason,recordedAt,updatedAt,coachNotes,const DeepCollectionEquality().hash(auditMetadata)]);

@override
String toString() {
  return 'ProgressRecord(userId: $userId, muscle: $muscle, weekNumber: $weekNumber, volumePrescribed: $volumePrescribed, volumePerformed: $volumePerformed, volumeAdherence: $volumeAdherence, ripRange: $ripRange, ripTarget: $ripTarget, muscleActivation: $muscleActivation, pumpQuality: $pumpQuality, fatigueLevel: $fatigueLevel, recoveryQuality: $recoveryQuality, hadPain: $hadPain, userComments: $userComments, exerciseAngles: $exerciseAngles, exerciseVariations: $exerciseVariations, volumeAction: $volumeAction, newVolume: $newVolume, progressionPhase: $progressionPhase, decisionReason: $decisionReason, wasDeload: $wasDeload, deloadReason: $deloadReason, recordedAt: $recordedAt, updatedAt: $updatedAt, coachNotes: $coachNotes, auditMetadata: $auditMetadata)';
}


}

/// @nodoc
abstract mixin class $ProgressRecordCopyWith<$Res>  {
  factory $ProgressRecordCopyWith(ProgressRecord value, $Res Function(ProgressRecord) _then) = _$ProgressRecordCopyWithImpl;
@useResult
$Res call({
 String userId, String muscle, int weekNumber, int volumePrescribed, int volumePerformed, double volumeAdherence, int ripRange, int ripTarget, double muscleActivation, double pumpQuality, double fatigueLevel, double recoveryQuality, bool hadPain, String userComments, String exerciseAngles, int exerciseVariations, String volumeAction, int newVolume, String progressionPhase, String decisionReason, bool wasDeload, String deloadReason, DateTime recordedAt, DateTime updatedAt, String coachNotes, Map<String, dynamic> auditMetadata
});




}
/// @nodoc
class _$ProgressRecordCopyWithImpl<$Res>
    implements $ProgressRecordCopyWith<$Res> {
  _$ProgressRecordCopyWithImpl(this._self, this._then);

  final ProgressRecord _self;
  final $Res Function(ProgressRecord) _then;

/// Create a copy of ProgressRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? muscle = null,Object? weekNumber = null,Object? volumePrescribed = null,Object? volumePerformed = null,Object? volumeAdherence = null,Object? ripRange = null,Object? ripTarget = null,Object? muscleActivation = null,Object? pumpQuality = null,Object? fatigueLevel = null,Object? recoveryQuality = null,Object? hadPain = null,Object? userComments = null,Object? exerciseAngles = null,Object? exerciseVariations = null,Object? volumeAction = null,Object? newVolume = null,Object? progressionPhase = null,Object? decisionReason = null,Object? wasDeload = null,Object? deloadReason = null,Object? recordedAt = null,Object? updatedAt = null,Object? coachNotes = null,Object? auditMetadata = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,volumePrescribed: null == volumePrescribed ? _self.volumePrescribed : volumePrescribed // ignore: cast_nullable_to_non_nullable
as int,volumePerformed: null == volumePerformed ? _self.volumePerformed : volumePerformed // ignore: cast_nullable_to_non_nullable
as int,volumeAdherence: null == volumeAdherence ? _self.volumeAdherence : volumeAdherence // ignore: cast_nullable_to_non_nullable
as double,ripRange: null == ripRange ? _self.ripRange : ripRange // ignore: cast_nullable_to_non_nullable
as int,ripTarget: null == ripTarget ? _self.ripTarget : ripTarget // ignore: cast_nullable_to_non_nullable
as int,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,pumpQuality: null == pumpQuality ? _self.pumpQuality : pumpQuality // ignore: cast_nullable_to_non_nullable
as double,fatigueLevel: null == fatigueLevel ? _self.fatigueLevel : fatigueLevel // ignore: cast_nullable_to_non_nullable
as double,recoveryQuality: null == recoveryQuality ? _self.recoveryQuality : recoveryQuality // ignore: cast_nullable_to_non_nullable
as double,hadPain: null == hadPain ? _self.hadPain : hadPain // ignore: cast_nullable_to_non_nullable
as bool,userComments: null == userComments ? _self.userComments : userComments // ignore: cast_nullable_to_non_nullable
as String,exerciseAngles: null == exerciseAngles ? _self.exerciseAngles : exerciseAngles // ignore: cast_nullable_to_non_nullable
as String,exerciseVariations: null == exerciseVariations ? _self.exerciseVariations : exerciseVariations // ignore: cast_nullable_to_non_nullable
as int,volumeAction: null == volumeAction ? _self.volumeAction : volumeAction // ignore: cast_nullable_to_non_nullable
as String,newVolume: null == newVolume ? _self.newVolume : newVolume // ignore: cast_nullable_to_non_nullable
as int,progressionPhase: null == progressionPhase ? _self.progressionPhase : progressionPhase // ignore: cast_nullable_to_non_nullable
as String,decisionReason: null == decisionReason ? _self.decisionReason : decisionReason // ignore: cast_nullable_to_non_nullable
as String,wasDeload: null == wasDeload ? _self.wasDeload : wasDeload // ignore: cast_nullable_to_non_nullable
as bool,deloadReason: null == deloadReason ? _self.deloadReason : deloadReason // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,coachNotes: null == coachNotes ? _self.coachNotes : coachNotes // ignore: cast_nullable_to_non_nullable
as String,auditMetadata: null == auditMetadata ? _self.auditMetadata : auditMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressRecord].
extension ProgressRecordPatterns on ProgressRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressRecord value)  $default,){
final _that = this;
switch (_that) {
case _ProgressRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String muscle,  int weekNumber,  int volumePrescribed,  int volumePerformed,  double volumeAdherence,  int ripRange,  int ripTarget,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  String userComments,  String exerciseAngles,  int exerciseVariations,  String volumeAction,  int newVolume,  String progressionPhase,  String decisionReason,  bool wasDeload,  String deloadReason,  DateTime recordedAt,  DateTime updatedAt,  String coachNotes,  Map<String, dynamic> auditMetadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressRecord() when $default != null:
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.volumePrescribed,_that.volumePerformed,_that.volumeAdherence,_that.ripRange,_that.ripTarget,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.userComments,_that.exerciseAngles,_that.exerciseVariations,_that.volumeAction,_that.newVolume,_that.progressionPhase,_that.decisionReason,_that.wasDeload,_that.deloadReason,_that.recordedAt,_that.updatedAt,_that.coachNotes,_that.auditMetadata);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String muscle,  int weekNumber,  int volumePrescribed,  int volumePerformed,  double volumeAdherence,  int ripRange,  int ripTarget,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  String userComments,  String exerciseAngles,  int exerciseVariations,  String volumeAction,  int newVolume,  String progressionPhase,  String decisionReason,  bool wasDeload,  String deloadReason,  DateTime recordedAt,  DateTime updatedAt,  String coachNotes,  Map<String, dynamic> auditMetadata)  $default,) {final _that = this;
switch (_that) {
case _ProgressRecord():
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.volumePrescribed,_that.volumePerformed,_that.volumeAdherence,_that.ripRange,_that.ripTarget,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.userComments,_that.exerciseAngles,_that.exerciseVariations,_that.volumeAction,_that.newVolume,_that.progressionPhase,_that.decisionReason,_that.wasDeload,_that.deloadReason,_that.recordedAt,_that.updatedAt,_that.coachNotes,_that.auditMetadata);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String muscle,  int weekNumber,  int volumePrescribed,  int volumePerformed,  double volumeAdherence,  int ripRange,  int ripTarget,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  String userComments,  String exerciseAngles,  int exerciseVariations,  String volumeAction,  int newVolume,  String progressionPhase,  String decisionReason,  bool wasDeload,  String deloadReason,  DateTime recordedAt,  DateTime updatedAt,  String coachNotes,  Map<String, dynamic> auditMetadata)?  $default,) {final _that = this;
switch (_that) {
case _ProgressRecord() when $default != null:
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.volumePrescribed,_that.volumePerformed,_that.volumeAdherence,_that.ripRange,_that.ripTarget,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.userComments,_that.exerciseAngles,_that.exerciseVariations,_that.volumeAction,_that.newVolume,_that.progressionPhase,_that.decisionReason,_that.wasDeload,_that.deloadReason,_that.recordedAt,_that.updatedAt,_that.coachNotes,_that.auditMetadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgressRecord implements ProgressRecord {
  const _ProgressRecord({required this.userId, required this.muscle, required this.weekNumber, required this.volumePrescribed, required this.volumePerformed, required this.volumeAdherence, required this.ripRange, required this.ripTarget, required this.muscleActivation, required this.pumpQuality, required this.fatigueLevel, required this.recoveryQuality, required this.hadPain, required this.userComments, required this.exerciseAngles, required this.exerciseVariations, required this.volumeAction, required this.newVolume, required this.progressionPhase, required this.decisionReason, required this.wasDeload, required this.deloadReason, required this.recordedAt, required this.updatedAt, this.coachNotes = '', final  Map<String, dynamic> auditMetadata = const {}}): _auditMetadata = auditMetadata;
  factory _ProgressRecord.fromJson(Map<String, dynamic> json) => _$ProgressRecordFromJson(json);

/// Identificadores
@override final  String userId;
@override final  String muscle;
@override final  int weekNumber;
/// Volumen (sets/semana)
@override final  int volumePrescribed;
@override final  int volumePerformed;
@override final  double volumeAdherence;
// 0.0-1.0 (volumePerformed/volumePrescribed)
/// Rango de repeticiones
@override final  int ripRange;
// RIR realizado (promedio)
@override final  int ripTarget;
// RIR objetivo (de plan)
/// Feedback del usuario (subjetivo, 1-10)
@override final  double muscleActivation;
// Qué tan bien sentiste el músculo
@override final  double pumpQuality;
// Calidad del pump
@override final  double fatigueLevel;
// Fatiga acumulada
@override final  double recoveryQuality;
// Calidad de recuperación
@override final  bool hadPain;
// ¿Tuvo dolor?
@override final  String userComments;
// Notas del usuario
/// Progresión de volumen (objetivo)
@override final  String exerciseAngles;
// Ángulos usados (ej: "plano,inclinado,declinado")
@override final  int exerciseVariations;
// Número de ejercicios/ángulos diferentes
/// Decisión del motor
@override final  String volumeAction;
// 'increase', 'maintain', 'decrease', 'deload', 'microdeload'
@override final  int newVolume;
// Volumen prescrpto para la siguiente semana
@override final  String progressionPhase;
// 'discovering', 'maintaining', 'overreaching', 'deloading', 'microdeload'
@override final  String decisionReason;
// Razón de la decisión (ej: "VMR discovered at 20 sets")
/// Deload info
@override final  bool wasDeload;
// ¿Fue una semana de deload?
@override final  String deloadReason;
// Razón del deload (si procede)
/// Timestamps
@override final  DateTime recordedAt;
// Cuándo se registró
@override final  DateTime updatedAt;
// Última actualización
/// Coach notes (opcional)
@override@JsonKey() final  String coachNotes;
// Notas que el coach quiera agregar
/// Metadata para auditoría
 final  Map<String, dynamic> _auditMetadata;
// Notas que el coach quiera agregar
/// Metadata para auditoría
@override@JsonKey() Map<String, dynamic> get auditMetadata {
  if (_auditMetadata is EqualUnmodifiableMapView) return _auditMetadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_auditMetadata);
}


/// Create a copy of ProgressRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressRecordCopyWith<_ProgressRecord> get copyWith => __$ProgressRecordCopyWithImpl<_ProgressRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressRecord&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.volumePrescribed, volumePrescribed) || other.volumePrescribed == volumePrescribed)&&(identical(other.volumePerformed, volumePerformed) || other.volumePerformed == volumePerformed)&&(identical(other.volumeAdherence, volumeAdherence) || other.volumeAdherence == volumeAdherence)&&(identical(other.ripRange, ripRange) || other.ripRange == ripRange)&&(identical(other.ripTarget, ripTarget) || other.ripTarget == ripTarget)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.pumpQuality, pumpQuality) || other.pumpQuality == pumpQuality)&&(identical(other.fatigueLevel, fatigueLevel) || other.fatigueLevel == fatigueLevel)&&(identical(other.recoveryQuality, recoveryQuality) || other.recoveryQuality == recoveryQuality)&&(identical(other.hadPain, hadPain) || other.hadPain == hadPain)&&(identical(other.userComments, userComments) || other.userComments == userComments)&&(identical(other.exerciseAngles, exerciseAngles) || other.exerciseAngles == exerciseAngles)&&(identical(other.exerciseVariations, exerciseVariations) || other.exerciseVariations == exerciseVariations)&&(identical(other.volumeAction, volumeAction) || other.volumeAction == volumeAction)&&(identical(other.newVolume, newVolume) || other.newVolume == newVolume)&&(identical(other.progressionPhase, progressionPhase) || other.progressionPhase == progressionPhase)&&(identical(other.decisionReason, decisionReason) || other.decisionReason == decisionReason)&&(identical(other.wasDeload, wasDeload) || other.wasDeload == wasDeload)&&(identical(other.deloadReason, deloadReason) || other.deloadReason == deloadReason)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.coachNotes, coachNotes) || other.coachNotes == coachNotes)&&const DeepCollectionEquality().equals(other._auditMetadata, _auditMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,muscle,weekNumber,volumePrescribed,volumePerformed,volumeAdherence,ripRange,ripTarget,muscleActivation,pumpQuality,fatigueLevel,recoveryQuality,hadPain,userComments,exerciseAngles,exerciseVariations,volumeAction,newVolume,progressionPhase,decisionReason,wasDeload,deloadReason,recordedAt,updatedAt,coachNotes,const DeepCollectionEquality().hash(_auditMetadata)]);

@override
String toString() {
  return 'ProgressRecord(userId: $userId, muscle: $muscle, weekNumber: $weekNumber, volumePrescribed: $volumePrescribed, volumePerformed: $volumePerformed, volumeAdherence: $volumeAdherence, ripRange: $ripRange, ripTarget: $ripTarget, muscleActivation: $muscleActivation, pumpQuality: $pumpQuality, fatigueLevel: $fatigueLevel, recoveryQuality: $recoveryQuality, hadPain: $hadPain, userComments: $userComments, exerciseAngles: $exerciseAngles, exerciseVariations: $exerciseVariations, volumeAction: $volumeAction, newVolume: $newVolume, progressionPhase: $progressionPhase, decisionReason: $decisionReason, wasDeload: $wasDeload, deloadReason: $deloadReason, recordedAt: $recordedAt, updatedAt: $updatedAt, coachNotes: $coachNotes, auditMetadata: $auditMetadata)';
}


}

/// @nodoc
abstract mixin class _$ProgressRecordCopyWith<$Res> implements $ProgressRecordCopyWith<$Res> {
  factory _$ProgressRecordCopyWith(_ProgressRecord value, $Res Function(_ProgressRecord) _then) = __$ProgressRecordCopyWithImpl;
@override @useResult
$Res call({
 String userId, String muscle, int weekNumber, int volumePrescribed, int volumePerformed, double volumeAdherence, int ripRange, int ripTarget, double muscleActivation, double pumpQuality, double fatigueLevel, double recoveryQuality, bool hadPain, String userComments, String exerciseAngles, int exerciseVariations, String volumeAction, int newVolume, String progressionPhase, String decisionReason, bool wasDeload, String deloadReason, DateTime recordedAt, DateTime updatedAt, String coachNotes, Map<String, dynamic> auditMetadata
});




}
/// @nodoc
class __$ProgressRecordCopyWithImpl<$Res>
    implements _$ProgressRecordCopyWith<$Res> {
  __$ProgressRecordCopyWithImpl(this._self, this._then);

  final _ProgressRecord _self;
  final $Res Function(_ProgressRecord) _then;

/// Create a copy of ProgressRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? muscle = null,Object? weekNumber = null,Object? volumePrescribed = null,Object? volumePerformed = null,Object? volumeAdherence = null,Object? ripRange = null,Object? ripTarget = null,Object? muscleActivation = null,Object? pumpQuality = null,Object? fatigueLevel = null,Object? recoveryQuality = null,Object? hadPain = null,Object? userComments = null,Object? exerciseAngles = null,Object? exerciseVariations = null,Object? volumeAction = null,Object? newVolume = null,Object? progressionPhase = null,Object? decisionReason = null,Object? wasDeload = null,Object? deloadReason = null,Object? recordedAt = null,Object? updatedAt = null,Object? coachNotes = null,Object? auditMetadata = null,}) {
  return _then(_ProgressRecord(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,volumePrescribed: null == volumePrescribed ? _self.volumePrescribed : volumePrescribed // ignore: cast_nullable_to_non_nullable
as int,volumePerformed: null == volumePerformed ? _self.volumePerformed : volumePerformed // ignore: cast_nullable_to_non_nullable
as int,volumeAdherence: null == volumeAdherence ? _self.volumeAdherence : volumeAdherence // ignore: cast_nullable_to_non_nullable
as double,ripRange: null == ripRange ? _self.ripRange : ripRange // ignore: cast_nullable_to_non_nullable
as int,ripTarget: null == ripTarget ? _self.ripTarget : ripTarget // ignore: cast_nullable_to_non_nullable
as int,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,pumpQuality: null == pumpQuality ? _self.pumpQuality : pumpQuality // ignore: cast_nullable_to_non_nullable
as double,fatigueLevel: null == fatigueLevel ? _self.fatigueLevel : fatigueLevel // ignore: cast_nullable_to_non_nullable
as double,recoveryQuality: null == recoveryQuality ? _self.recoveryQuality : recoveryQuality // ignore: cast_nullable_to_non_nullable
as double,hadPain: null == hadPain ? _self.hadPain : hadPain // ignore: cast_nullable_to_non_nullable
as bool,userComments: null == userComments ? _self.userComments : userComments // ignore: cast_nullable_to_non_nullable
as String,exerciseAngles: null == exerciseAngles ? _self.exerciseAngles : exerciseAngles // ignore: cast_nullable_to_non_nullable
as String,exerciseVariations: null == exerciseVariations ? _self.exerciseVariations : exerciseVariations // ignore: cast_nullable_to_non_nullable
as int,volumeAction: null == volumeAction ? _self.volumeAction : volumeAction // ignore: cast_nullable_to_non_nullable
as String,newVolume: null == newVolume ? _self.newVolume : newVolume // ignore: cast_nullable_to_non_nullable
as int,progressionPhase: null == progressionPhase ? _self.progressionPhase : progressionPhase // ignore: cast_nullable_to_non_nullable
as String,decisionReason: null == decisionReason ? _self.decisionReason : decisionReason // ignore: cast_nullable_to_non_nullable
as String,wasDeload: null == wasDeload ? _self.wasDeload : wasDeload // ignore: cast_nullable_to_non_nullable
as bool,deloadReason: null == deloadReason ? _self.deloadReason : deloadReason // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,coachNotes: null == coachNotes ? _self.coachNotes : coachNotes // ignore: cast_nullable_to_non_nullable
as String,auditMetadata: null == auditMetadata ? _self._auditMetadata : auditMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
