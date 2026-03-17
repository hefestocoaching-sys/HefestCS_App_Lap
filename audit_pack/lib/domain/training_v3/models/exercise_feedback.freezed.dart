// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_feedback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseFeedback {

 String get exerciseId; String get exerciseName; double get muscleActivation; double get formQuality; double get difficulty; bool get feltGood; bool get hadDiscomfort; String? get discomfortDescription; bool get wantsReplacement; String? get replacementReason;
/// Create a copy of ExerciseFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseFeedbackCopyWith<ExerciseFeedback> get copyWith => _$ExerciseFeedbackCopyWithImpl<ExerciseFeedback>(this as ExerciseFeedback, _$identity);

  /// Serializes this ExerciseFeedback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseFeedback&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.formQuality, formQuality) || other.formQuality == formQuality)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.feltGood, feltGood) || other.feltGood == feltGood)&&(identical(other.hadDiscomfort, hadDiscomfort) || other.hadDiscomfort == hadDiscomfort)&&(identical(other.discomfortDescription, discomfortDescription) || other.discomfortDescription == discomfortDescription)&&(identical(other.wantsReplacement, wantsReplacement) || other.wantsReplacement == wantsReplacement)&&(identical(other.replacementReason, replacementReason) || other.replacementReason == replacementReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,exerciseName,muscleActivation,formQuality,difficulty,feltGood,hadDiscomfort,discomfortDescription,wantsReplacement,replacementReason);

@override
String toString() {
  return 'ExerciseFeedback(exerciseId: $exerciseId, exerciseName: $exerciseName, muscleActivation: $muscleActivation, formQuality: $formQuality, difficulty: $difficulty, feltGood: $feltGood, hadDiscomfort: $hadDiscomfort, discomfortDescription: $discomfortDescription, wantsReplacement: $wantsReplacement, replacementReason: $replacementReason)';
}


}

/// @nodoc
abstract mixin class $ExerciseFeedbackCopyWith<$Res>  {
  factory $ExerciseFeedbackCopyWith(ExerciseFeedback value, $Res Function(ExerciseFeedback) _then) = _$ExerciseFeedbackCopyWithImpl;
@useResult
$Res call({
 String exerciseId, String exerciseName, double muscleActivation, double formQuality, double difficulty, bool feltGood, bool hadDiscomfort, String? discomfortDescription, bool wantsReplacement, String? replacementReason
});




}
/// @nodoc
class _$ExerciseFeedbackCopyWithImpl<$Res>
    implements $ExerciseFeedbackCopyWith<$Res> {
  _$ExerciseFeedbackCopyWithImpl(this._self, this._then);

  final ExerciseFeedback _self;
  final $Res Function(ExerciseFeedback) _then;

/// Create a copy of ExerciseFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exerciseId = null,Object? exerciseName = null,Object? muscleActivation = null,Object? formQuality = null,Object? difficulty = null,Object? feltGood = null,Object? hadDiscomfort = null,Object? discomfortDescription = freezed,Object? wantsReplacement = null,Object? replacementReason = freezed,}) {
  return _then(_self.copyWith(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,formQuality: null == formQuality ? _self.formQuality : formQuality // ignore: cast_nullable_to_non_nullable
as double,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as double,feltGood: null == feltGood ? _self.feltGood : feltGood // ignore: cast_nullable_to_non_nullable
as bool,hadDiscomfort: null == hadDiscomfort ? _self.hadDiscomfort : hadDiscomfort // ignore: cast_nullable_to_non_nullable
as bool,discomfortDescription: freezed == discomfortDescription ? _self.discomfortDescription : discomfortDescription // ignore: cast_nullable_to_non_nullable
as String?,wantsReplacement: null == wantsReplacement ? _self.wantsReplacement : wantsReplacement // ignore: cast_nullable_to_non_nullable
as bool,replacementReason: freezed == replacementReason ? _self.replacementReason : replacementReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseFeedback].
extension ExerciseFeedbackPatterns on ExerciseFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseFeedback value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String exerciseId,  String exerciseName,  double muscleActivation,  double formQuality,  double difficulty,  bool feltGood,  bool hadDiscomfort,  String? discomfortDescription,  bool wantsReplacement,  String? replacementReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseFeedback() when $default != null:
return $default(_that.exerciseId,_that.exerciseName,_that.muscleActivation,_that.formQuality,_that.difficulty,_that.feltGood,_that.hadDiscomfort,_that.discomfortDescription,_that.wantsReplacement,_that.replacementReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String exerciseId,  String exerciseName,  double muscleActivation,  double formQuality,  double difficulty,  bool feltGood,  bool hadDiscomfort,  String? discomfortDescription,  bool wantsReplacement,  String? replacementReason)  $default,) {final _that = this;
switch (_that) {
case _ExerciseFeedback():
return $default(_that.exerciseId,_that.exerciseName,_that.muscleActivation,_that.formQuality,_that.difficulty,_that.feltGood,_that.hadDiscomfort,_that.discomfortDescription,_that.wantsReplacement,_that.replacementReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String exerciseId,  String exerciseName,  double muscleActivation,  double formQuality,  double difficulty,  bool feltGood,  bool hadDiscomfort,  String? discomfortDescription,  bool wantsReplacement,  String? replacementReason)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseFeedback() when $default != null:
return $default(_that.exerciseId,_that.exerciseName,_that.muscleActivation,_that.formQuality,_that.difficulty,_that.feltGood,_that.hadDiscomfort,_that.discomfortDescription,_that.wantsReplacement,_that.replacementReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseFeedback implements ExerciseFeedback {
  const _ExerciseFeedback({required this.exerciseId, required this.exerciseName, required this.muscleActivation, required this.formQuality, required this.difficulty, this.feltGood = true, this.hadDiscomfort = false, this.discomfortDescription, this.wantsReplacement = false, this.replacementReason});
  factory _ExerciseFeedback.fromJson(Map<String, dynamic> json) => _$ExerciseFeedbackFromJson(json);

@override final  String exerciseId;
@override final  String exerciseName;
@override final  double muscleActivation;
@override final  double formQuality;
@override final  double difficulty;
@override@JsonKey() final  bool feltGood;
@override@JsonKey() final  bool hadDiscomfort;
@override final  String? discomfortDescription;
@override@JsonKey() final  bool wantsReplacement;
@override final  String? replacementReason;

/// Create a copy of ExerciseFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseFeedbackCopyWith<_ExerciseFeedback> get copyWith => __$ExerciseFeedbackCopyWithImpl<_ExerciseFeedback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseFeedbackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseFeedback&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.formQuality, formQuality) || other.formQuality == formQuality)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.feltGood, feltGood) || other.feltGood == feltGood)&&(identical(other.hadDiscomfort, hadDiscomfort) || other.hadDiscomfort == hadDiscomfort)&&(identical(other.discomfortDescription, discomfortDescription) || other.discomfortDescription == discomfortDescription)&&(identical(other.wantsReplacement, wantsReplacement) || other.wantsReplacement == wantsReplacement)&&(identical(other.replacementReason, replacementReason) || other.replacementReason == replacementReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,exerciseName,muscleActivation,formQuality,difficulty,feltGood,hadDiscomfort,discomfortDescription,wantsReplacement,replacementReason);

@override
String toString() {
  return 'ExerciseFeedback(exerciseId: $exerciseId, exerciseName: $exerciseName, muscleActivation: $muscleActivation, formQuality: $formQuality, difficulty: $difficulty, feltGood: $feltGood, hadDiscomfort: $hadDiscomfort, discomfortDescription: $discomfortDescription, wantsReplacement: $wantsReplacement, replacementReason: $replacementReason)';
}


}

/// @nodoc
abstract mixin class _$ExerciseFeedbackCopyWith<$Res> implements $ExerciseFeedbackCopyWith<$Res> {
  factory _$ExerciseFeedbackCopyWith(_ExerciseFeedback value, $Res Function(_ExerciseFeedback) _then) = __$ExerciseFeedbackCopyWithImpl;
@override @useResult
$Res call({
 String exerciseId, String exerciseName, double muscleActivation, double formQuality, double difficulty, bool feltGood, bool hadDiscomfort, String? discomfortDescription, bool wantsReplacement, String? replacementReason
});




}
/// @nodoc
class __$ExerciseFeedbackCopyWithImpl<$Res>
    implements _$ExerciseFeedbackCopyWith<$Res> {
  __$ExerciseFeedbackCopyWithImpl(this._self, this._then);

  final _ExerciseFeedback _self;
  final $Res Function(_ExerciseFeedback) _then;

/// Create a copy of ExerciseFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exerciseId = null,Object? exerciseName = null,Object? muscleActivation = null,Object? formQuality = null,Object? difficulty = null,Object? feltGood = null,Object? hadDiscomfort = null,Object? discomfortDescription = freezed,Object? wantsReplacement = null,Object? replacementReason = freezed,}) {
  return _then(_ExerciseFeedback(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,formQuality: null == formQuality ? _self.formQuality : formQuality // ignore: cast_nullable_to_non_nullable
as double,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as double,feltGood: null == feltGood ? _self.feltGood : feltGood // ignore: cast_nullable_to_non_nullable
as bool,hadDiscomfort: null == hadDiscomfort ? _self.hadDiscomfort : hadDiscomfort // ignore: cast_nullable_to_non_nullable
as bool,discomfortDescription: freezed == discomfortDescription ? _self.discomfortDescription : discomfortDescription // ignore: cast_nullable_to_non_nullable
as String?,wantsReplacement: null == wantsReplacement ? _self.wantsReplacement : wantsReplacement // ignore: cast_nullable_to_non_nullable
as bool,replacementReason: freezed == replacementReason ? _self.replacementReason : replacementReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
