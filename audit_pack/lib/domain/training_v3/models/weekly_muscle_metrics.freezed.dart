// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_muscle_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeeklyMuscleMetrics {

 int get weekNumber; int get volume; double get loadChange; double get rirDeviation; double get adherence; double get recoveryQuality; double get fatigueLevel; double get muscleActivation; bool get hadPain; double? get painSeverity;
/// Create a copy of WeeklyMuscleMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyMuscleMetricsCopyWith<WeeklyMuscleMetrics> get copyWith => _$WeeklyMuscleMetricsCopyWithImpl<WeeklyMuscleMetrics>(this as WeeklyMuscleMetrics, _$identity);

  /// Serializes this WeeklyMuscleMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyMuscleMetrics&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.loadChange, loadChange) || other.loadChange == loadChange)&&(identical(other.rirDeviation, rirDeviation) || other.rirDeviation == rirDeviation)&&(identical(other.adherence, adherence) || other.adherence == adherence)&&(identical(other.recoveryQuality, recoveryQuality) || other.recoveryQuality == recoveryQuality)&&(identical(other.fatigueLevel, fatigueLevel) || other.fatigueLevel == fatigueLevel)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.hadPain, hadPain) || other.hadPain == hadPain)&&(identical(other.painSeverity, painSeverity) || other.painSeverity == painSeverity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekNumber,volume,loadChange,rirDeviation,adherence,recoveryQuality,fatigueLevel,muscleActivation,hadPain,painSeverity);

@override
String toString() {
  return 'WeeklyMuscleMetrics(weekNumber: $weekNumber, volume: $volume, loadChange: $loadChange, rirDeviation: $rirDeviation, adherence: $adherence, recoveryQuality: $recoveryQuality, fatigueLevel: $fatigueLevel, muscleActivation: $muscleActivation, hadPain: $hadPain, painSeverity: $painSeverity)';
}


}

/// @nodoc
abstract mixin class $WeeklyMuscleMetricsCopyWith<$Res>  {
  factory $WeeklyMuscleMetricsCopyWith(WeeklyMuscleMetrics value, $Res Function(WeeklyMuscleMetrics) _then) = _$WeeklyMuscleMetricsCopyWithImpl;
@useResult
$Res call({
 int weekNumber, int volume, double loadChange, double rirDeviation, double adherence, double recoveryQuality, double fatigueLevel, double muscleActivation, bool hadPain, double? painSeverity
});




}
/// @nodoc
class _$WeeklyMuscleMetricsCopyWithImpl<$Res>
    implements $WeeklyMuscleMetricsCopyWith<$Res> {
  _$WeeklyMuscleMetricsCopyWithImpl(this._self, this._then);

  final WeeklyMuscleMetrics _self;
  final $Res Function(WeeklyMuscleMetrics) _then;

/// Create a copy of WeeklyMuscleMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekNumber = null,Object? volume = null,Object? loadChange = null,Object? rirDeviation = null,Object? adherence = null,Object? recoveryQuality = null,Object? fatigueLevel = null,Object? muscleActivation = null,Object? hadPain = null,Object? painSeverity = freezed,}) {
  return _then(_self.copyWith(
weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,loadChange: null == loadChange ? _self.loadChange : loadChange // ignore: cast_nullable_to_non_nullable
as double,rirDeviation: null == rirDeviation ? _self.rirDeviation : rirDeviation // ignore: cast_nullable_to_non_nullable
as double,adherence: null == adherence ? _self.adherence : adherence // ignore: cast_nullable_to_non_nullable
as double,recoveryQuality: null == recoveryQuality ? _self.recoveryQuality : recoveryQuality // ignore: cast_nullable_to_non_nullable
as double,fatigueLevel: null == fatigueLevel ? _self.fatigueLevel : fatigueLevel // ignore: cast_nullable_to_non_nullable
as double,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,hadPain: null == hadPain ? _self.hadPain : hadPain // ignore: cast_nullable_to_non_nullable
as bool,painSeverity: freezed == painSeverity ? _self.painSeverity : painSeverity // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyMuscleMetrics].
extension WeeklyMuscleMetricsPatterns on WeeklyMuscleMetrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyMuscleMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyMuscleMetrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyMuscleMetrics value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyMuscleMetrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyMuscleMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyMuscleMetrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int weekNumber,  int volume,  double loadChange,  double rirDeviation,  double adherence,  double recoveryQuality,  double fatigueLevel,  double muscleActivation,  bool hadPain,  double? painSeverity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyMuscleMetrics() when $default != null:
return $default(_that.weekNumber,_that.volume,_that.loadChange,_that.rirDeviation,_that.adherence,_that.recoveryQuality,_that.fatigueLevel,_that.muscleActivation,_that.hadPain,_that.painSeverity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int weekNumber,  int volume,  double loadChange,  double rirDeviation,  double adherence,  double recoveryQuality,  double fatigueLevel,  double muscleActivation,  bool hadPain,  double? painSeverity)  $default,) {final _that = this;
switch (_that) {
case _WeeklyMuscleMetrics():
return $default(_that.weekNumber,_that.volume,_that.loadChange,_that.rirDeviation,_that.adherence,_that.recoveryQuality,_that.fatigueLevel,_that.muscleActivation,_that.hadPain,_that.painSeverity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int weekNumber,  int volume,  double loadChange,  double rirDeviation,  double adherence,  double recoveryQuality,  double fatigueLevel,  double muscleActivation,  bool hadPain,  double? painSeverity)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyMuscleMetrics() when $default != null:
return $default(_that.weekNumber,_that.volume,_that.loadChange,_that.rirDeviation,_that.adherence,_that.recoveryQuality,_that.fatigueLevel,_that.muscleActivation,_that.hadPain,_that.painSeverity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyMuscleMetrics implements WeeklyMuscleMetrics {
  const _WeeklyMuscleMetrics({required this.weekNumber, required this.volume, required this.loadChange, required this.rirDeviation, required this.adherence, required this.recoveryQuality, required this.fatigueLevel, required this.muscleActivation, this.hadPain = false, this.painSeverity});
  factory _WeeklyMuscleMetrics.fromJson(Map<String, dynamic> json) => _$WeeklyMuscleMetricsFromJson(json);

@override final  int weekNumber;
@override final  int volume;
@override final  double loadChange;
@override final  double rirDeviation;
@override final  double adherence;
@override final  double recoveryQuality;
@override final  double fatigueLevel;
@override final  double muscleActivation;
@override@JsonKey() final  bool hadPain;
@override final  double? painSeverity;

/// Create a copy of WeeklyMuscleMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyMuscleMetricsCopyWith<_WeeklyMuscleMetrics> get copyWith => __$WeeklyMuscleMetricsCopyWithImpl<_WeeklyMuscleMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyMuscleMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyMuscleMetrics&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.loadChange, loadChange) || other.loadChange == loadChange)&&(identical(other.rirDeviation, rirDeviation) || other.rirDeviation == rirDeviation)&&(identical(other.adherence, adherence) || other.adherence == adherence)&&(identical(other.recoveryQuality, recoveryQuality) || other.recoveryQuality == recoveryQuality)&&(identical(other.fatigueLevel, fatigueLevel) || other.fatigueLevel == fatigueLevel)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.hadPain, hadPain) || other.hadPain == hadPain)&&(identical(other.painSeverity, painSeverity) || other.painSeverity == painSeverity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekNumber,volume,loadChange,rirDeviation,adherence,recoveryQuality,fatigueLevel,muscleActivation,hadPain,painSeverity);

@override
String toString() {
  return 'WeeklyMuscleMetrics(weekNumber: $weekNumber, volume: $volume, loadChange: $loadChange, rirDeviation: $rirDeviation, adherence: $adherence, recoveryQuality: $recoveryQuality, fatigueLevel: $fatigueLevel, muscleActivation: $muscleActivation, hadPain: $hadPain, painSeverity: $painSeverity)';
}


}

/// @nodoc
abstract mixin class _$WeeklyMuscleMetricsCopyWith<$Res> implements $WeeklyMuscleMetricsCopyWith<$Res> {
  factory _$WeeklyMuscleMetricsCopyWith(_WeeklyMuscleMetrics value, $Res Function(_WeeklyMuscleMetrics) _then) = __$WeeklyMuscleMetricsCopyWithImpl;
@override @useResult
$Res call({
 int weekNumber, int volume, double loadChange, double rirDeviation, double adherence, double recoveryQuality, double fatigueLevel, double muscleActivation, bool hadPain, double? painSeverity
});




}
/// @nodoc
class __$WeeklyMuscleMetricsCopyWithImpl<$Res>
    implements _$WeeklyMuscleMetricsCopyWith<$Res> {
  __$WeeklyMuscleMetricsCopyWithImpl(this._self, this._then);

  final _WeeklyMuscleMetrics _self;
  final $Res Function(_WeeklyMuscleMetrics) _then;

/// Create a copy of WeeklyMuscleMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekNumber = null,Object? volume = null,Object? loadChange = null,Object? rirDeviation = null,Object? adherence = null,Object? recoveryQuality = null,Object? fatigueLevel = null,Object? muscleActivation = null,Object? hadPain = null,Object? painSeverity = freezed,}) {
  return _then(_WeeklyMuscleMetrics(
weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,loadChange: null == loadChange ? _self.loadChange : loadChange // ignore: cast_nullable_to_non_nullable
as double,rirDeviation: null == rirDeviation ? _self.rirDeviation : rirDeviation // ignore: cast_nullable_to_non_nullable
as double,adherence: null == adherence ? _self.adherence : adherence // ignore: cast_nullable_to_non_nullable
as double,recoveryQuality: null == recoveryQuality ? _self.recoveryQuality : recoveryQuality // ignore: cast_nullable_to_non_nullable
as double,fatigueLevel: null == fatigueLevel ? _self.fatigueLevel : fatigueLevel // ignore: cast_nullable_to_non_nullable
as double,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,hadPain: null == hadPain ? _self.hadPain : hadPain // ignore: cast_nullable_to_non_nullable
as bool,painSeverity: freezed == painSeverity ? _self.painSeverity : painSeverity // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
