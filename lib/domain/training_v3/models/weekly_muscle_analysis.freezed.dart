// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_muscle_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeeklyMuscleAnalysis {

 String get muscle; int get weekNumber; DateTime get weekStart; DateTime get weekEnd; int get prescribedSets; int get completedSets; double get volumeAdherence; double get averageLoad; double get previousLoad; double get loadChange; double get averageReps; double get previousReps; double get averageRir; int get prescribedRir; double get rirDeviation; double get averageRpe; double get muscleActivation; double get pumpQuality; double get fatigueLevel; double get recoveryQuality; bool get hadPain; double? get painSeverity; String? get painDescription; List<ExerciseFeedback> get exerciseFeedback;
/// Create a copy of WeeklyMuscleAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyMuscleAnalysisCopyWith<WeeklyMuscleAnalysis> get copyWith => _$WeeklyMuscleAnalysisCopyWithImpl<WeeklyMuscleAnalysis>(this as WeeklyMuscleAnalysis, _$identity);

  /// Serializes this WeeklyMuscleAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyMuscleAnalysis&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.prescribedSets, prescribedSets) || other.prescribedSets == prescribedSets)&&(identical(other.completedSets, completedSets) || other.completedSets == completedSets)&&(identical(other.volumeAdherence, volumeAdherence) || other.volumeAdherence == volumeAdherence)&&(identical(other.averageLoad, averageLoad) || other.averageLoad == averageLoad)&&(identical(other.previousLoad, previousLoad) || other.previousLoad == previousLoad)&&(identical(other.loadChange, loadChange) || other.loadChange == loadChange)&&(identical(other.averageReps, averageReps) || other.averageReps == averageReps)&&(identical(other.previousReps, previousReps) || other.previousReps == previousReps)&&(identical(other.averageRir, averageRir) || other.averageRir == averageRir)&&(identical(other.prescribedRir, prescribedRir) || other.prescribedRir == prescribedRir)&&(identical(other.rirDeviation, rirDeviation) || other.rirDeviation == rirDeviation)&&(identical(other.averageRpe, averageRpe) || other.averageRpe == averageRpe)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.pumpQuality, pumpQuality) || other.pumpQuality == pumpQuality)&&(identical(other.fatigueLevel, fatigueLevel) || other.fatigueLevel == fatigueLevel)&&(identical(other.recoveryQuality, recoveryQuality) || other.recoveryQuality == recoveryQuality)&&(identical(other.hadPain, hadPain) || other.hadPain == hadPain)&&(identical(other.painSeverity, painSeverity) || other.painSeverity == painSeverity)&&(identical(other.painDescription, painDescription) || other.painDescription == painDescription)&&const DeepCollectionEquality().equals(other.exerciseFeedback, exerciseFeedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,muscle,weekNumber,weekStart,weekEnd,prescribedSets,completedSets,volumeAdherence,averageLoad,previousLoad,loadChange,averageReps,previousReps,averageRir,prescribedRir,rirDeviation,averageRpe,muscleActivation,pumpQuality,fatigueLevel,recoveryQuality,hadPain,painSeverity,painDescription,const DeepCollectionEquality().hash(exerciseFeedback)]);

@override
String toString() {
  return 'WeeklyMuscleAnalysis(muscle: $muscle, weekNumber: $weekNumber, weekStart: $weekStart, weekEnd: $weekEnd, prescribedSets: $prescribedSets, completedSets: $completedSets, volumeAdherence: $volumeAdherence, averageLoad: $averageLoad, previousLoad: $previousLoad, loadChange: $loadChange, averageReps: $averageReps, previousReps: $previousReps, averageRir: $averageRir, prescribedRir: $prescribedRir, rirDeviation: $rirDeviation, averageRpe: $averageRpe, muscleActivation: $muscleActivation, pumpQuality: $pumpQuality, fatigueLevel: $fatigueLevel, recoveryQuality: $recoveryQuality, hadPain: $hadPain, painSeverity: $painSeverity, painDescription: $painDescription, exerciseFeedback: $exerciseFeedback)';
}


}

/// @nodoc
abstract mixin class $WeeklyMuscleAnalysisCopyWith<$Res>  {
  factory $WeeklyMuscleAnalysisCopyWith(WeeklyMuscleAnalysis value, $Res Function(WeeklyMuscleAnalysis) _then) = _$WeeklyMuscleAnalysisCopyWithImpl;
@useResult
$Res call({
 String muscle, int weekNumber, DateTime weekStart, DateTime weekEnd, int prescribedSets, int completedSets, double volumeAdherence, double averageLoad, double previousLoad, double loadChange, double averageReps, double previousReps, double averageRir, int prescribedRir, double rirDeviation, double averageRpe, double muscleActivation, double pumpQuality, double fatigueLevel, double recoveryQuality, bool hadPain, double? painSeverity, String? painDescription, List<ExerciseFeedback> exerciseFeedback
});




}
/// @nodoc
class _$WeeklyMuscleAnalysisCopyWithImpl<$Res>
    implements $WeeklyMuscleAnalysisCopyWith<$Res> {
  _$WeeklyMuscleAnalysisCopyWithImpl(this._self, this._then);

  final WeeklyMuscleAnalysis _self;
  final $Res Function(WeeklyMuscleAnalysis) _then;

/// Create a copy of WeeklyMuscleAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? muscle = null,Object? weekNumber = null,Object? weekStart = null,Object? weekEnd = null,Object? prescribedSets = null,Object? completedSets = null,Object? volumeAdherence = null,Object? averageLoad = null,Object? previousLoad = null,Object? loadChange = null,Object? averageReps = null,Object? previousReps = null,Object? averageRir = null,Object? prescribedRir = null,Object? rirDeviation = null,Object? averageRpe = null,Object? muscleActivation = null,Object? pumpQuality = null,Object? fatigueLevel = null,Object? recoveryQuality = null,Object? hadPain = null,Object? painSeverity = freezed,Object? painDescription = freezed,Object? exerciseFeedback = null,}) {
  return _then(_self.copyWith(
muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as DateTime,prescribedSets: null == prescribedSets ? _self.prescribedSets : prescribedSets // ignore: cast_nullable_to_non_nullable
as int,completedSets: null == completedSets ? _self.completedSets : completedSets // ignore: cast_nullable_to_non_nullable
as int,volumeAdherence: null == volumeAdherence ? _self.volumeAdherence : volumeAdherence // ignore: cast_nullable_to_non_nullable
as double,averageLoad: null == averageLoad ? _self.averageLoad : averageLoad // ignore: cast_nullable_to_non_nullable
as double,previousLoad: null == previousLoad ? _self.previousLoad : previousLoad // ignore: cast_nullable_to_non_nullable
as double,loadChange: null == loadChange ? _self.loadChange : loadChange // ignore: cast_nullable_to_non_nullable
as double,averageReps: null == averageReps ? _self.averageReps : averageReps // ignore: cast_nullable_to_non_nullable
as double,previousReps: null == previousReps ? _self.previousReps : previousReps // ignore: cast_nullable_to_non_nullable
as double,averageRir: null == averageRir ? _self.averageRir : averageRir // ignore: cast_nullable_to_non_nullable
as double,prescribedRir: null == prescribedRir ? _self.prescribedRir : prescribedRir // ignore: cast_nullable_to_non_nullable
as int,rirDeviation: null == rirDeviation ? _self.rirDeviation : rirDeviation // ignore: cast_nullable_to_non_nullable
as double,averageRpe: null == averageRpe ? _self.averageRpe : averageRpe // ignore: cast_nullable_to_non_nullable
as double,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,pumpQuality: null == pumpQuality ? _self.pumpQuality : pumpQuality // ignore: cast_nullable_to_non_nullable
as double,fatigueLevel: null == fatigueLevel ? _self.fatigueLevel : fatigueLevel // ignore: cast_nullable_to_non_nullable
as double,recoveryQuality: null == recoveryQuality ? _self.recoveryQuality : recoveryQuality // ignore: cast_nullable_to_non_nullable
as double,hadPain: null == hadPain ? _self.hadPain : hadPain // ignore: cast_nullable_to_non_nullable
as bool,painSeverity: freezed == painSeverity ? _self.painSeverity : painSeverity // ignore: cast_nullable_to_non_nullable
as double?,painDescription: freezed == painDescription ? _self.painDescription : painDescription // ignore: cast_nullable_to_non_nullable
as String?,exerciseFeedback: null == exerciseFeedback ? _self.exerciseFeedback : exerciseFeedback // ignore: cast_nullable_to_non_nullable
as List<ExerciseFeedback>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyMuscleAnalysis].
extension WeeklyMuscleAnalysisPatterns on WeeklyMuscleAnalysis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyMuscleAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyMuscleAnalysis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyMuscleAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyMuscleAnalysis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyMuscleAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyMuscleAnalysis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String muscle,  int weekNumber,  DateTime weekStart,  DateTime weekEnd,  int prescribedSets,  int completedSets,  double volumeAdherence,  double averageLoad,  double previousLoad,  double loadChange,  double averageReps,  double previousReps,  double averageRir,  int prescribedRir,  double rirDeviation,  double averageRpe,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  double? painSeverity,  String? painDescription,  List<ExerciseFeedback> exerciseFeedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyMuscleAnalysis() when $default != null:
return $default(_that.muscle,_that.weekNumber,_that.weekStart,_that.weekEnd,_that.prescribedSets,_that.completedSets,_that.volumeAdherence,_that.averageLoad,_that.previousLoad,_that.loadChange,_that.averageReps,_that.previousReps,_that.averageRir,_that.prescribedRir,_that.rirDeviation,_that.averageRpe,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.painSeverity,_that.painDescription,_that.exerciseFeedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String muscle,  int weekNumber,  DateTime weekStart,  DateTime weekEnd,  int prescribedSets,  int completedSets,  double volumeAdherence,  double averageLoad,  double previousLoad,  double loadChange,  double averageReps,  double previousReps,  double averageRir,  int prescribedRir,  double rirDeviation,  double averageRpe,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  double? painSeverity,  String? painDescription,  List<ExerciseFeedback> exerciseFeedback)  $default,) {final _that = this;
switch (_that) {
case _WeeklyMuscleAnalysis():
return $default(_that.muscle,_that.weekNumber,_that.weekStart,_that.weekEnd,_that.prescribedSets,_that.completedSets,_that.volumeAdherence,_that.averageLoad,_that.previousLoad,_that.loadChange,_that.averageReps,_that.previousReps,_that.averageRir,_that.prescribedRir,_that.rirDeviation,_that.averageRpe,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.painSeverity,_that.painDescription,_that.exerciseFeedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String muscle,  int weekNumber,  DateTime weekStart,  DateTime weekEnd,  int prescribedSets,  int completedSets,  double volumeAdherence,  double averageLoad,  double previousLoad,  double loadChange,  double averageReps,  double previousReps,  double averageRir,  int prescribedRir,  double rirDeviation,  double averageRpe,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  double? painSeverity,  String? painDescription,  List<ExerciseFeedback> exerciseFeedback)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyMuscleAnalysis() when $default != null:
return $default(_that.muscle,_that.weekNumber,_that.weekStart,_that.weekEnd,_that.prescribedSets,_that.completedSets,_that.volumeAdherence,_that.averageLoad,_that.previousLoad,_that.loadChange,_that.averageReps,_that.previousReps,_that.averageRir,_that.prescribedRir,_that.rirDeviation,_that.averageRpe,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.painSeverity,_that.painDescription,_that.exerciseFeedback);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyMuscleAnalysis implements WeeklyMuscleAnalysis {
  const _WeeklyMuscleAnalysis({required this.muscle, required this.weekNumber, required this.weekStart, required this.weekEnd, required this.prescribedSets, required this.completedSets, required this.volumeAdherence, required this.averageLoad, required this.previousLoad, required this.loadChange, required this.averageReps, required this.previousReps, required this.averageRir, required this.prescribedRir, required this.rirDeviation, required this.averageRpe, required this.muscleActivation, required this.pumpQuality, required this.fatigueLevel, required this.recoveryQuality, this.hadPain = false, this.painSeverity, this.painDescription, final  List<ExerciseFeedback> exerciseFeedback = const []}): _exerciseFeedback = exerciseFeedback;
  factory _WeeklyMuscleAnalysis.fromJson(Map<String, dynamic> json) => _$WeeklyMuscleAnalysisFromJson(json);

@override final  String muscle;
@override final  int weekNumber;
@override final  DateTime weekStart;
@override final  DateTime weekEnd;
@override final  int prescribedSets;
@override final  int completedSets;
@override final  double volumeAdherence;
@override final  double averageLoad;
@override final  double previousLoad;
@override final  double loadChange;
@override final  double averageReps;
@override final  double previousReps;
@override final  double averageRir;
@override final  int prescribedRir;
@override final  double rirDeviation;
@override final  double averageRpe;
@override final  double muscleActivation;
@override final  double pumpQuality;
@override final  double fatigueLevel;
@override final  double recoveryQuality;
@override@JsonKey() final  bool hadPain;
@override final  double? painSeverity;
@override final  String? painDescription;
 final  List<ExerciseFeedback> _exerciseFeedback;
@override@JsonKey() List<ExerciseFeedback> get exerciseFeedback {
  if (_exerciseFeedback is EqualUnmodifiableListView) return _exerciseFeedback;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exerciseFeedback);
}


/// Create a copy of WeeklyMuscleAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyMuscleAnalysisCopyWith<_WeeklyMuscleAnalysis> get copyWith => __$WeeklyMuscleAnalysisCopyWithImpl<_WeeklyMuscleAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyMuscleAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyMuscleAnalysis&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.prescribedSets, prescribedSets) || other.prescribedSets == prescribedSets)&&(identical(other.completedSets, completedSets) || other.completedSets == completedSets)&&(identical(other.volumeAdherence, volumeAdherence) || other.volumeAdherence == volumeAdherence)&&(identical(other.averageLoad, averageLoad) || other.averageLoad == averageLoad)&&(identical(other.previousLoad, previousLoad) || other.previousLoad == previousLoad)&&(identical(other.loadChange, loadChange) || other.loadChange == loadChange)&&(identical(other.averageReps, averageReps) || other.averageReps == averageReps)&&(identical(other.previousReps, previousReps) || other.previousReps == previousReps)&&(identical(other.averageRir, averageRir) || other.averageRir == averageRir)&&(identical(other.prescribedRir, prescribedRir) || other.prescribedRir == prescribedRir)&&(identical(other.rirDeviation, rirDeviation) || other.rirDeviation == rirDeviation)&&(identical(other.averageRpe, averageRpe) || other.averageRpe == averageRpe)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.pumpQuality, pumpQuality) || other.pumpQuality == pumpQuality)&&(identical(other.fatigueLevel, fatigueLevel) || other.fatigueLevel == fatigueLevel)&&(identical(other.recoveryQuality, recoveryQuality) || other.recoveryQuality == recoveryQuality)&&(identical(other.hadPain, hadPain) || other.hadPain == hadPain)&&(identical(other.painSeverity, painSeverity) || other.painSeverity == painSeverity)&&(identical(other.painDescription, painDescription) || other.painDescription == painDescription)&&const DeepCollectionEquality().equals(other._exerciseFeedback, _exerciseFeedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,muscle,weekNumber,weekStart,weekEnd,prescribedSets,completedSets,volumeAdherence,averageLoad,previousLoad,loadChange,averageReps,previousReps,averageRir,prescribedRir,rirDeviation,averageRpe,muscleActivation,pumpQuality,fatigueLevel,recoveryQuality,hadPain,painSeverity,painDescription,const DeepCollectionEquality().hash(_exerciseFeedback)]);

@override
String toString() {
  return 'WeeklyMuscleAnalysis(muscle: $muscle, weekNumber: $weekNumber, weekStart: $weekStart, weekEnd: $weekEnd, prescribedSets: $prescribedSets, completedSets: $completedSets, volumeAdherence: $volumeAdherence, averageLoad: $averageLoad, previousLoad: $previousLoad, loadChange: $loadChange, averageReps: $averageReps, previousReps: $previousReps, averageRir: $averageRir, prescribedRir: $prescribedRir, rirDeviation: $rirDeviation, averageRpe: $averageRpe, muscleActivation: $muscleActivation, pumpQuality: $pumpQuality, fatigueLevel: $fatigueLevel, recoveryQuality: $recoveryQuality, hadPain: $hadPain, painSeverity: $painSeverity, painDescription: $painDescription, exerciseFeedback: $exerciseFeedback)';
}


}

/// @nodoc
abstract mixin class _$WeeklyMuscleAnalysisCopyWith<$Res> implements $WeeklyMuscleAnalysisCopyWith<$Res> {
  factory _$WeeklyMuscleAnalysisCopyWith(_WeeklyMuscleAnalysis value, $Res Function(_WeeklyMuscleAnalysis) _then) = __$WeeklyMuscleAnalysisCopyWithImpl;
@override @useResult
$Res call({
 String muscle, int weekNumber, DateTime weekStart, DateTime weekEnd, int prescribedSets, int completedSets, double volumeAdherence, double averageLoad, double previousLoad, double loadChange, double averageReps, double previousReps, double averageRir, int prescribedRir, double rirDeviation, double averageRpe, double muscleActivation, double pumpQuality, double fatigueLevel, double recoveryQuality, bool hadPain, double? painSeverity, String? painDescription, List<ExerciseFeedback> exerciseFeedback
});




}
/// @nodoc
class __$WeeklyMuscleAnalysisCopyWithImpl<$Res>
    implements _$WeeklyMuscleAnalysisCopyWith<$Res> {
  __$WeeklyMuscleAnalysisCopyWithImpl(this._self, this._then);

  final _WeeklyMuscleAnalysis _self;
  final $Res Function(_WeeklyMuscleAnalysis) _then;

/// Create a copy of WeeklyMuscleAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? muscle = null,Object? weekNumber = null,Object? weekStart = null,Object? weekEnd = null,Object? prescribedSets = null,Object? completedSets = null,Object? volumeAdherence = null,Object? averageLoad = null,Object? previousLoad = null,Object? loadChange = null,Object? averageReps = null,Object? previousReps = null,Object? averageRir = null,Object? prescribedRir = null,Object? rirDeviation = null,Object? averageRpe = null,Object? muscleActivation = null,Object? pumpQuality = null,Object? fatigueLevel = null,Object? recoveryQuality = null,Object? hadPain = null,Object? painSeverity = freezed,Object? painDescription = freezed,Object? exerciseFeedback = null,}) {
  return _then(_WeeklyMuscleAnalysis(
muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as DateTime,prescribedSets: null == prescribedSets ? _self.prescribedSets : prescribedSets // ignore: cast_nullable_to_non_nullable
as int,completedSets: null == completedSets ? _self.completedSets : completedSets // ignore: cast_nullable_to_non_nullable
as int,volumeAdherence: null == volumeAdherence ? _self.volumeAdherence : volumeAdherence // ignore: cast_nullable_to_non_nullable
as double,averageLoad: null == averageLoad ? _self.averageLoad : averageLoad // ignore: cast_nullable_to_non_nullable
as double,previousLoad: null == previousLoad ? _self.previousLoad : previousLoad // ignore: cast_nullable_to_non_nullable
as double,loadChange: null == loadChange ? _self.loadChange : loadChange // ignore: cast_nullable_to_non_nullable
as double,averageReps: null == averageReps ? _self.averageReps : averageReps // ignore: cast_nullable_to_non_nullable
as double,previousReps: null == previousReps ? _self.previousReps : previousReps // ignore: cast_nullable_to_non_nullable
as double,averageRir: null == averageRir ? _self.averageRir : averageRir // ignore: cast_nullable_to_non_nullable
as double,prescribedRir: null == prescribedRir ? _self.prescribedRir : prescribedRir // ignore: cast_nullable_to_non_nullable
as int,rirDeviation: null == rirDeviation ? _self.rirDeviation : rirDeviation // ignore: cast_nullable_to_non_nullable
as double,averageRpe: null == averageRpe ? _self.averageRpe : averageRpe // ignore: cast_nullable_to_non_nullable
as double,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,pumpQuality: null == pumpQuality ? _self.pumpQuality : pumpQuality // ignore: cast_nullable_to_non_nullable
as double,fatigueLevel: null == fatigueLevel ? _self.fatigueLevel : fatigueLevel // ignore: cast_nullable_to_non_nullable
as double,recoveryQuality: null == recoveryQuality ? _self.recoveryQuality : recoveryQuality // ignore: cast_nullable_to_non_nullable
as double,hadPain: null == hadPain ? _self.hadPain : hadPain // ignore: cast_nullable_to_non_nullable
as bool,painSeverity: freezed == painSeverity ? _self.painSeverity : painSeverity // ignore: cast_nullable_to_non_nullable
as double?,painDescription: freezed == painDescription ? _self.painDescription : painDescription // ignore: cast_nullable_to_non_nullable
as String?,exerciseFeedback: null == exerciseFeedback ? _self._exerciseFeedback : exerciseFeedback // ignore: cast_nullable_to_non_nullable
as List<ExerciseFeedback>,
  ));
}


}

// dart format on
