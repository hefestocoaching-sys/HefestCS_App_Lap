// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'muscle_progression.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MuscleProgression {

/// Identificación
 String get muscle; int get priority;// 5=P(primary), 3=S(secondary), 1=T(tertiary)
/// Volumen landmarks científicos
 VolumeLandmarks get landmarks;// MEV, VOP, MRV, MRV_target
/// Estado actual
 int get currentSets;// Sets/semana ACTUAL
 int get vopSets;// VOP específico para este músculo/usuario
 int get mrvSets;// MRV descubierto o estimado
 bool get hasDiscoveredMRV;// ¿Se encontró MRV empíricamente?
/// Progresión en ciclo
 String get currentPhase;// 'discovering'|'maintaining'|'overreaching'|'deloading'
 int get weeksInCurrentPhase; int get totalWeeksInTraining;/// Control de deload
 int get weeksSinceDeload;// Semanas desde último deload
 int get weeksUntilAutoDeload;// Estimado (4-5 para P, 5-6 para S)
 bool get isAutoDeloadScheduled;// ¿Deload automático programado?
/// Histórico resumido (últimas 4 semanas)
 List<int> get last4WeeksVolume;// [week-3, week-2, week-1, week0]
 List<double> get last4WeeksAdherence;// Adherencia % | last exercise efficiency
 List<String> get last4WeeksPhase;// Fases | progression_state
/// Metadata
 DateTime get createdAt; DateTime get lastUpdated; DateTime get lastDeloadDate;/// Notas
 String get notes;
/// Create a copy of MuscleProgression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MuscleProgressionCopyWith<MuscleProgression> get copyWith => _$MuscleProgressionCopyWithImpl<MuscleProgression>(this as MuscleProgression, _$identity);

  /// Serializes this MuscleProgression to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MuscleProgression&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.landmarks, landmarks) || other.landmarks == landmarks)&&(identical(other.currentSets, currentSets) || other.currentSets == currentSets)&&(identical(other.vopSets, vopSets) || other.vopSets == vopSets)&&(identical(other.mrvSets, mrvSets) || other.mrvSets == mrvSets)&&(identical(other.hasDiscoveredMRV, hasDiscoveredMRV) || other.hasDiscoveredMRV == hasDiscoveredMRV)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.weeksInCurrentPhase, weeksInCurrentPhase) || other.weeksInCurrentPhase == weeksInCurrentPhase)&&(identical(other.totalWeeksInTraining, totalWeeksInTraining) || other.totalWeeksInTraining == totalWeeksInTraining)&&(identical(other.weeksSinceDeload, weeksSinceDeload) || other.weeksSinceDeload == weeksSinceDeload)&&(identical(other.weeksUntilAutoDeload, weeksUntilAutoDeload) || other.weeksUntilAutoDeload == weeksUntilAutoDeload)&&(identical(other.isAutoDeloadScheduled, isAutoDeloadScheduled) || other.isAutoDeloadScheduled == isAutoDeloadScheduled)&&const DeepCollectionEquality().equals(other.last4WeeksVolume, last4WeeksVolume)&&const DeepCollectionEquality().equals(other.last4WeeksAdherence, last4WeeksAdherence)&&const DeepCollectionEquality().equals(other.last4WeeksPhase, last4WeeksPhase)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.lastDeloadDate, lastDeloadDate) || other.lastDeloadDate == lastDeloadDate)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,muscle,priority,landmarks,currentSets,vopSets,mrvSets,hasDiscoveredMRV,currentPhase,weeksInCurrentPhase,totalWeeksInTraining,weeksSinceDeload,weeksUntilAutoDeload,isAutoDeloadScheduled,const DeepCollectionEquality().hash(last4WeeksVolume),const DeepCollectionEquality().hash(last4WeeksAdherence),const DeepCollectionEquality().hash(last4WeeksPhase),createdAt,lastUpdated,lastDeloadDate,notes]);

@override
String toString() {
  return 'MuscleProgression(muscle: $muscle, priority: $priority, landmarks: $landmarks, currentSets: $currentSets, vopSets: $vopSets, mrvSets: $mrvSets, hasDiscoveredMRV: $hasDiscoveredMRV, currentPhase: $currentPhase, weeksInCurrentPhase: $weeksInCurrentPhase, totalWeeksInTraining: $totalWeeksInTraining, weeksSinceDeload: $weeksSinceDeload, weeksUntilAutoDeload: $weeksUntilAutoDeload, isAutoDeloadScheduled: $isAutoDeloadScheduled, last4WeeksVolume: $last4WeeksVolume, last4WeeksAdherence: $last4WeeksAdherence, last4WeeksPhase: $last4WeeksPhase, createdAt: $createdAt, lastUpdated: $lastUpdated, lastDeloadDate: $lastDeloadDate, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $MuscleProgressionCopyWith<$Res>  {
  factory $MuscleProgressionCopyWith(MuscleProgression value, $Res Function(MuscleProgression) _then) = _$MuscleProgressionCopyWithImpl;
@useResult
$Res call({
 String muscle, int priority, VolumeLandmarks landmarks, int currentSets, int vopSets, int mrvSets, bool hasDiscoveredMRV, String currentPhase, int weeksInCurrentPhase, int totalWeeksInTraining, int weeksSinceDeload, int weeksUntilAutoDeload, bool isAutoDeloadScheduled, List<int> last4WeeksVolume, List<double> last4WeeksAdherence, List<String> last4WeeksPhase, DateTime createdAt, DateTime lastUpdated, DateTime lastDeloadDate, String notes
});


$VolumeLandmarksCopyWith<$Res> get landmarks;

}
/// @nodoc
class _$MuscleProgressionCopyWithImpl<$Res>
    implements $MuscleProgressionCopyWith<$Res> {
  _$MuscleProgressionCopyWithImpl(this._self, this._then);

  final MuscleProgression _self;
  final $Res Function(MuscleProgression) _then;

/// Create a copy of MuscleProgression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? muscle = null,Object? priority = null,Object? landmarks = null,Object? currentSets = null,Object? vopSets = null,Object? mrvSets = null,Object? hasDiscoveredMRV = null,Object? currentPhase = null,Object? weeksInCurrentPhase = null,Object? totalWeeksInTraining = null,Object? weeksSinceDeload = null,Object? weeksUntilAutoDeload = null,Object? isAutoDeloadScheduled = null,Object? last4WeeksVolume = null,Object? last4WeeksAdherence = null,Object? last4WeeksPhase = null,Object? createdAt = null,Object? lastUpdated = null,Object? lastDeloadDate = null,Object? notes = null,}) {
  return _then(_self.copyWith(
muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,landmarks: null == landmarks ? _self.landmarks : landmarks // ignore: cast_nullable_to_non_nullable
as VolumeLandmarks,currentSets: null == currentSets ? _self.currentSets : currentSets // ignore: cast_nullable_to_non_nullable
as int,vopSets: null == vopSets ? _self.vopSets : vopSets // ignore: cast_nullable_to_non_nullable
as int,mrvSets: null == mrvSets ? _self.mrvSets : mrvSets // ignore: cast_nullable_to_non_nullable
as int,hasDiscoveredMRV: null == hasDiscoveredMRV ? _self.hasDiscoveredMRV : hasDiscoveredMRV // ignore: cast_nullable_to_non_nullable
as bool,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as String,weeksInCurrentPhase: null == weeksInCurrentPhase ? _self.weeksInCurrentPhase : weeksInCurrentPhase // ignore: cast_nullable_to_non_nullable
as int,totalWeeksInTraining: null == totalWeeksInTraining ? _self.totalWeeksInTraining : totalWeeksInTraining // ignore: cast_nullable_to_non_nullable
as int,weeksSinceDeload: null == weeksSinceDeload ? _self.weeksSinceDeload : weeksSinceDeload // ignore: cast_nullable_to_non_nullable
as int,weeksUntilAutoDeload: null == weeksUntilAutoDeload ? _self.weeksUntilAutoDeload : weeksUntilAutoDeload // ignore: cast_nullable_to_non_nullable
as int,isAutoDeloadScheduled: null == isAutoDeloadScheduled ? _self.isAutoDeloadScheduled : isAutoDeloadScheduled // ignore: cast_nullable_to_non_nullable
as bool,last4WeeksVolume: null == last4WeeksVolume ? _self.last4WeeksVolume : last4WeeksVolume // ignore: cast_nullable_to_non_nullable
as List<int>,last4WeeksAdherence: null == last4WeeksAdherence ? _self.last4WeeksAdherence : last4WeeksAdherence // ignore: cast_nullable_to_non_nullable
as List<double>,last4WeeksPhase: null == last4WeeksPhase ? _self.last4WeeksPhase : last4WeeksPhase // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,lastDeloadDate: null == lastDeloadDate ? _self.lastDeloadDate : lastDeloadDate // ignore: cast_nullable_to_non_nullable
as DateTime,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of MuscleProgression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VolumeLandmarksCopyWith<$Res> get landmarks {
  
  return $VolumeLandmarksCopyWith<$Res>(_self.landmarks, (value) {
    return _then(_self.copyWith(landmarks: value));
  });
}
}


/// Adds pattern-matching-related methods to [MuscleProgression].
extension MuscleProgressionPatterns on MuscleProgression {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MuscleProgression value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MuscleProgression() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MuscleProgression value)  $default,){
final _that = this;
switch (_that) {
case _MuscleProgression():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MuscleProgression value)?  $default,){
final _that = this;
switch (_that) {
case _MuscleProgression() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String muscle,  int priority,  VolumeLandmarks landmarks,  int currentSets,  int vopSets,  int mrvSets,  bool hasDiscoveredMRV,  String currentPhase,  int weeksInCurrentPhase,  int totalWeeksInTraining,  int weeksSinceDeload,  int weeksUntilAutoDeload,  bool isAutoDeloadScheduled,  List<int> last4WeeksVolume,  List<double> last4WeeksAdherence,  List<String> last4WeeksPhase,  DateTime createdAt,  DateTime lastUpdated,  DateTime lastDeloadDate,  String notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MuscleProgression() when $default != null:
return $default(_that.muscle,_that.priority,_that.landmarks,_that.currentSets,_that.vopSets,_that.mrvSets,_that.hasDiscoveredMRV,_that.currentPhase,_that.weeksInCurrentPhase,_that.totalWeeksInTraining,_that.weeksSinceDeload,_that.weeksUntilAutoDeload,_that.isAutoDeloadScheduled,_that.last4WeeksVolume,_that.last4WeeksAdherence,_that.last4WeeksPhase,_that.createdAt,_that.lastUpdated,_that.lastDeloadDate,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String muscle,  int priority,  VolumeLandmarks landmarks,  int currentSets,  int vopSets,  int mrvSets,  bool hasDiscoveredMRV,  String currentPhase,  int weeksInCurrentPhase,  int totalWeeksInTraining,  int weeksSinceDeload,  int weeksUntilAutoDeload,  bool isAutoDeloadScheduled,  List<int> last4WeeksVolume,  List<double> last4WeeksAdherence,  List<String> last4WeeksPhase,  DateTime createdAt,  DateTime lastUpdated,  DateTime lastDeloadDate,  String notes)  $default,) {final _that = this;
switch (_that) {
case _MuscleProgression():
return $default(_that.muscle,_that.priority,_that.landmarks,_that.currentSets,_that.vopSets,_that.mrvSets,_that.hasDiscoveredMRV,_that.currentPhase,_that.weeksInCurrentPhase,_that.totalWeeksInTraining,_that.weeksSinceDeload,_that.weeksUntilAutoDeload,_that.isAutoDeloadScheduled,_that.last4WeeksVolume,_that.last4WeeksAdherence,_that.last4WeeksPhase,_that.createdAt,_that.lastUpdated,_that.lastDeloadDate,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String muscle,  int priority,  VolumeLandmarks landmarks,  int currentSets,  int vopSets,  int mrvSets,  bool hasDiscoveredMRV,  String currentPhase,  int weeksInCurrentPhase,  int totalWeeksInTraining,  int weeksSinceDeload,  int weeksUntilAutoDeload,  bool isAutoDeloadScheduled,  List<int> last4WeeksVolume,  List<double> last4WeeksAdherence,  List<String> last4WeeksPhase,  DateTime createdAt,  DateTime lastUpdated,  DateTime lastDeloadDate,  String notes)?  $default,) {final _that = this;
switch (_that) {
case _MuscleProgression() when $default != null:
return $default(_that.muscle,_that.priority,_that.landmarks,_that.currentSets,_that.vopSets,_that.mrvSets,_that.hasDiscoveredMRV,_that.currentPhase,_that.weeksInCurrentPhase,_that.totalWeeksInTraining,_that.weeksSinceDeload,_that.weeksUntilAutoDeload,_that.isAutoDeloadScheduled,_that.last4WeeksVolume,_that.last4WeeksAdherence,_that.last4WeeksPhase,_that.createdAt,_that.lastUpdated,_that.lastDeloadDate,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MuscleProgression implements MuscleProgression {
  const _MuscleProgression({required this.muscle, required this.priority, required this.landmarks, required this.currentSets, required this.vopSets, required this.mrvSets, required this.hasDiscoveredMRV, required this.currentPhase, required this.weeksInCurrentPhase, required this.totalWeeksInTraining, required this.weeksSinceDeload, required this.weeksUntilAutoDeload, required this.isAutoDeloadScheduled, final  List<int> last4WeeksVolume = const [], final  List<double> last4WeeksAdherence = const [], final  List<String> last4WeeksPhase = const [], required this.createdAt, required this.lastUpdated, required this.lastDeloadDate, this.notes = ''}): _last4WeeksVolume = last4WeeksVolume,_last4WeeksAdherence = last4WeeksAdherence,_last4WeeksPhase = last4WeeksPhase;
  factory _MuscleProgression.fromJson(Map<String, dynamic> json) => _$MuscleProgressionFromJson(json);

/// Identificación
@override final  String muscle;
@override final  int priority;
// 5=P(primary), 3=S(secondary), 1=T(tertiary)
/// Volumen landmarks científicos
@override final  VolumeLandmarks landmarks;
// MEV, VOP, MRV, MRV_target
/// Estado actual
@override final  int currentSets;
// Sets/semana ACTUAL
@override final  int vopSets;
// VOP específico para este músculo/usuario
@override final  int mrvSets;
// MRV descubierto o estimado
@override final  bool hasDiscoveredMRV;
// ¿Se encontró MRV empíricamente?
/// Progresión en ciclo
@override final  String currentPhase;
// 'discovering'|'maintaining'|'overreaching'|'deloading'
@override final  int weeksInCurrentPhase;
@override final  int totalWeeksInTraining;
/// Control de deload
@override final  int weeksSinceDeload;
// Semanas desde último deload
@override final  int weeksUntilAutoDeload;
// Estimado (4-5 para P, 5-6 para S)
@override final  bool isAutoDeloadScheduled;
// ¿Deload automático programado?
/// Histórico resumido (últimas 4 semanas)
 final  List<int> _last4WeeksVolume;
// ¿Deload automático programado?
/// Histórico resumido (últimas 4 semanas)
@override@JsonKey() List<int> get last4WeeksVolume {
  if (_last4WeeksVolume is EqualUnmodifiableListView) return _last4WeeksVolume;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_last4WeeksVolume);
}

// [week-3, week-2, week-1, week0]
 final  List<double> _last4WeeksAdherence;
// [week-3, week-2, week-1, week0]
@override@JsonKey() List<double> get last4WeeksAdherence {
  if (_last4WeeksAdherence is EqualUnmodifiableListView) return _last4WeeksAdherence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_last4WeeksAdherence);
}

// Adherencia % | last exercise efficiency
 final  List<String> _last4WeeksPhase;
// Adherencia % | last exercise efficiency
@override@JsonKey() List<String> get last4WeeksPhase {
  if (_last4WeeksPhase is EqualUnmodifiableListView) return _last4WeeksPhase;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_last4WeeksPhase);
}

// Fases | progression_state
/// Metadata
@override final  DateTime createdAt;
@override final  DateTime lastUpdated;
@override final  DateTime lastDeloadDate;
/// Notas
@override@JsonKey() final  String notes;

/// Create a copy of MuscleProgression
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MuscleProgressionCopyWith<_MuscleProgression> get copyWith => __$MuscleProgressionCopyWithImpl<_MuscleProgression>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MuscleProgressionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MuscleProgression&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.landmarks, landmarks) || other.landmarks == landmarks)&&(identical(other.currentSets, currentSets) || other.currentSets == currentSets)&&(identical(other.vopSets, vopSets) || other.vopSets == vopSets)&&(identical(other.mrvSets, mrvSets) || other.mrvSets == mrvSets)&&(identical(other.hasDiscoveredMRV, hasDiscoveredMRV) || other.hasDiscoveredMRV == hasDiscoveredMRV)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.weeksInCurrentPhase, weeksInCurrentPhase) || other.weeksInCurrentPhase == weeksInCurrentPhase)&&(identical(other.totalWeeksInTraining, totalWeeksInTraining) || other.totalWeeksInTraining == totalWeeksInTraining)&&(identical(other.weeksSinceDeload, weeksSinceDeload) || other.weeksSinceDeload == weeksSinceDeload)&&(identical(other.weeksUntilAutoDeload, weeksUntilAutoDeload) || other.weeksUntilAutoDeload == weeksUntilAutoDeload)&&(identical(other.isAutoDeloadScheduled, isAutoDeloadScheduled) || other.isAutoDeloadScheduled == isAutoDeloadScheduled)&&const DeepCollectionEquality().equals(other._last4WeeksVolume, _last4WeeksVolume)&&const DeepCollectionEquality().equals(other._last4WeeksAdherence, _last4WeeksAdherence)&&const DeepCollectionEquality().equals(other._last4WeeksPhase, _last4WeeksPhase)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.lastDeloadDate, lastDeloadDate) || other.lastDeloadDate == lastDeloadDate)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,muscle,priority,landmarks,currentSets,vopSets,mrvSets,hasDiscoveredMRV,currentPhase,weeksInCurrentPhase,totalWeeksInTraining,weeksSinceDeload,weeksUntilAutoDeload,isAutoDeloadScheduled,const DeepCollectionEquality().hash(_last4WeeksVolume),const DeepCollectionEquality().hash(_last4WeeksAdherence),const DeepCollectionEquality().hash(_last4WeeksPhase),createdAt,lastUpdated,lastDeloadDate,notes]);

@override
String toString() {
  return 'MuscleProgression(muscle: $muscle, priority: $priority, landmarks: $landmarks, currentSets: $currentSets, vopSets: $vopSets, mrvSets: $mrvSets, hasDiscoveredMRV: $hasDiscoveredMRV, currentPhase: $currentPhase, weeksInCurrentPhase: $weeksInCurrentPhase, totalWeeksInTraining: $totalWeeksInTraining, weeksSinceDeload: $weeksSinceDeload, weeksUntilAutoDeload: $weeksUntilAutoDeload, isAutoDeloadScheduled: $isAutoDeloadScheduled, last4WeeksVolume: $last4WeeksVolume, last4WeeksAdherence: $last4WeeksAdherence, last4WeeksPhase: $last4WeeksPhase, createdAt: $createdAt, lastUpdated: $lastUpdated, lastDeloadDate: $lastDeloadDate, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$MuscleProgressionCopyWith<$Res> implements $MuscleProgressionCopyWith<$Res> {
  factory _$MuscleProgressionCopyWith(_MuscleProgression value, $Res Function(_MuscleProgression) _then) = __$MuscleProgressionCopyWithImpl;
@override @useResult
$Res call({
 String muscle, int priority, VolumeLandmarks landmarks, int currentSets, int vopSets, int mrvSets, bool hasDiscoveredMRV, String currentPhase, int weeksInCurrentPhase, int totalWeeksInTraining, int weeksSinceDeload, int weeksUntilAutoDeload, bool isAutoDeloadScheduled, List<int> last4WeeksVolume, List<double> last4WeeksAdherence, List<String> last4WeeksPhase, DateTime createdAt, DateTime lastUpdated, DateTime lastDeloadDate, String notes
});


@override $VolumeLandmarksCopyWith<$Res> get landmarks;

}
/// @nodoc
class __$MuscleProgressionCopyWithImpl<$Res>
    implements _$MuscleProgressionCopyWith<$Res> {
  __$MuscleProgressionCopyWithImpl(this._self, this._then);

  final _MuscleProgression _self;
  final $Res Function(_MuscleProgression) _then;

/// Create a copy of MuscleProgression
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? muscle = null,Object? priority = null,Object? landmarks = null,Object? currentSets = null,Object? vopSets = null,Object? mrvSets = null,Object? hasDiscoveredMRV = null,Object? currentPhase = null,Object? weeksInCurrentPhase = null,Object? totalWeeksInTraining = null,Object? weeksSinceDeload = null,Object? weeksUntilAutoDeload = null,Object? isAutoDeloadScheduled = null,Object? last4WeeksVolume = null,Object? last4WeeksAdherence = null,Object? last4WeeksPhase = null,Object? createdAt = null,Object? lastUpdated = null,Object? lastDeloadDate = null,Object? notes = null,}) {
  return _then(_MuscleProgression(
muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,landmarks: null == landmarks ? _self.landmarks : landmarks // ignore: cast_nullable_to_non_nullable
as VolumeLandmarks,currentSets: null == currentSets ? _self.currentSets : currentSets // ignore: cast_nullable_to_non_nullable
as int,vopSets: null == vopSets ? _self.vopSets : vopSets // ignore: cast_nullable_to_non_nullable
as int,mrvSets: null == mrvSets ? _self.mrvSets : mrvSets // ignore: cast_nullable_to_non_nullable
as int,hasDiscoveredMRV: null == hasDiscoveredMRV ? _self.hasDiscoveredMRV : hasDiscoveredMRV // ignore: cast_nullable_to_non_nullable
as bool,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as String,weeksInCurrentPhase: null == weeksInCurrentPhase ? _self.weeksInCurrentPhase : weeksInCurrentPhase // ignore: cast_nullable_to_non_nullable
as int,totalWeeksInTraining: null == totalWeeksInTraining ? _self.totalWeeksInTraining : totalWeeksInTraining // ignore: cast_nullable_to_non_nullable
as int,weeksSinceDeload: null == weeksSinceDeload ? _self.weeksSinceDeload : weeksSinceDeload // ignore: cast_nullable_to_non_nullable
as int,weeksUntilAutoDeload: null == weeksUntilAutoDeload ? _self.weeksUntilAutoDeload : weeksUntilAutoDeload // ignore: cast_nullable_to_non_nullable
as int,isAutoDeloadScheduled: null == isAutoDeloadScheduled ? _self.isAutoDeloadScheduled : isAutoDeloadScheduled // ignore: cast_nullable_to_non_nullable
as bool,last4WeeksVolume: null == last4WeeksVolume ? _self._last4WeeksVolume : last4WeeksVolume // ignore: cast_nullable_to_non_nullable
as List<int>,last4WeeksAdherence: null == last4WeeksAdherence ? _self._last4WeeksAdherence : last4WeeksAdherence // ignore: cast_nullable_to_non_nullable
as List<double>,last4WeeksPhase: null == last4WeeksPhase ? _self._last4WeeksPhase : last4WeeksPhase // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,lastDeloadDate: null == lastDeloadDate ? _self.lastDeloadDate : lastDeloadDate // ignore: cast_nullable_to_non_nullable
as DateTime,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of MuscleProgression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VolumeLandmarksCopyWith<$Res> get landmarks {
  
  return $VolumeLandmarksCopyWith<$Res>(_self.landmarks, (value) {
    return _then(_self.copyWith(landmarks: value));
  });
}
}

// dart format on
