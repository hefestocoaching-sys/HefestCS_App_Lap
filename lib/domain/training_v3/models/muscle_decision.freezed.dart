// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'muscle_decision.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MuscleDecision {

 String get muscle; VolumeAction get action; int get newVolume; ProgressionPhase get newPhase; String get reason; double get confidence; bool get requiresMicrodeload; int? get weeksToMicrodeload; int? get vmrDiscovered; bool get isNewCycle; List<ExerciseReplacement> get exercisesToReplace;
/// Create a copy of MuscleDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MuscleDecisionCopyWith<MuscleDecision> get copyWith => _$MuscleDecisionCopyWithImpl<MuscleDecision>(this as MuscleDecision, _$identity);

  /// Serializes this MuscleDecision to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MuscleDecision&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.action, action) || other.action == action)&&(identical(other.newVolume, newVolume) || other.newVolume == newVolume)&&(identical(other.newPhase, newPhase) || other.newPhase == newPhase)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.requiresMicrodeload, requiresMicrodeload) || other.requiresMicrodeload == requiresMicrodeload)&&(identical(other.weeksToMicrodeload, weeksToMicrodeload) || other.weeksToMicrodeload == weeksToMicrodeload)&&(identical(other.vmrDiscovered, vmrDiscovered) || other.vmrDiscovered == vmrDiscovered)&&(identical(other.isNewCycle, isNewCycle) || other.isNewCycle == isNewCycle)&&const DeepCollectionEquality().equals(other.exercisesToReplace, exercisesToReplace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,muscle,action,newVolume,newPhase,reason,confidence,requiresMicrodeload,weeksToMicrodeload,vmrDiscovered,isNewCycle,const DeepCollectionEquality().hash(exercisesToReplace));

@override
String toString() {
  return 'MuscleDecision(muscle: $muscle, action: $action, newVolume: $newVolume, newPhase: $newPhase, reason: $reason, confidence: $confidence, requiresMicrodeload: $requiresMicrodeload, weeksToMicrodeload: $weeksToMicrodeload, vmrDiscovered: $vmrDiscovered, isNewCycle: $isNewCycle, exercisesToReplace: $exercisesToReplace)';
}


}

/// @nodoc
abstract mixin class $MuscleDecisionCopyWith<$Res>  {
  factory $MuscleDecisionCopyWith(MuscleDecision value, $Res Function(MuscleDecision) _then) = _$MuscleDecisionCopyWithImpl;
@useResult
$Res call({
 String muscle, VolumeAction action, int newVolume, ProgressionPhase newPhase, String reason, double confidence, bool requiresMicrodeload, int? weeksToMicrodeload, int? vmrDiscovered, bool isNewCycle, List<ExerciseReplacement> exercisesToReplace
});




}
/// @nodoc
class _$MuscleDecisionCopyWithImpl<$Res>
    implements $MuscleDecisionCopyWith<$Res> {
  _$MuscleDecisionCopyWithImpl(this._self, this._then);

  final MuscleDecision _self;
  final $Res Function(MuscleDecision) _then;

/// Create a copy of MuscleDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? muscle = null,Object? action = null,Object? newVolume = null,Object? newPhase = null,Object? reason = null,Object? confidence = null,Object? requiresMicrodeload = null,Object? weeksToMicrodeload = freezed,Object? vmrDiscovered = freezed,Object? isNewCycle = null,Object? exercisesToReplace = null,}) {
  return _then(_self.copyWith(
muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as VolumeAction,newVolume: null == newVolume ? _self.newVolume : newVolume // ignore: cast_nullable_to_non_nullable
as int,newPhase: null == newPhase ? _self.newPhase : newPhase // ignore: cast_nullable_to_non_nullable
as ProgressionPhase,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,requiresMicrodeload: null == requiresMicrodeload ? _self.requiresMicrodeload : requiresMicrodeload // ignore: cast_nullable_to_non_nullable
as bool,weeksToMicrodeload: freezed == weeksToMicrodeload ? _self.weeksToMicrodeload : weeksToMicrodeload // ignore: cast_nullable_to_non_nullable
as int?,vmrDiscovered: freezed == vmrDiscovered ? _self.vmrDiscovered : vmrDiscovered // ignore: cast_nullable_to_non_nullable
as int?,isNewCycle: null == isNewCycle ? _self.isNewCycle : isNewCycle // ignore: cast_nullable_to_non_nullable
as bool,exercisesToReplace: null == exercisesToReplace ? _self.exercisesToReplace : exercisesToReplace // ignore: cast_nullable_to_non_nullable
as List<ExerciseReplacement>,
  ));
}

}


/// Adds pattern-matching-related methods to [MuscleDecision].
extension MuscleDecisionPatterns on MuscleDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MuscleDecision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MuscleDecision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MuscleDecision value)  $default,){
final _that = this;
switch (_that) {
case _MuscleDecision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MuscleDecision value)?  $default,){
final _that = this;
switch (_that) {
case _MuscleDecision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String muscle,  VolumeAction action,  int newVolume,  ProgressionPhase newPhase,  String reason,  double confidence,  bool requiresMicrodeload,  int? weeksToMicrodeload,  int? vmrDiscovered,  bool isNewCycle,  List<ExerciseReplacement> exercisesToReplace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MuscleDecision() when $default != null:
return $default(_that.muscle,_that.action,_that.newVolume,_that.newPhase,_that.reason,_that.confidence,_that.requiresMicrodeload,_that.weeksToMicrodeload,_that.vmrDiscovered,_that.isNewCycle,_that.exercisesToReplace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String muscle,  VolumeAction action,  int newVolume,  ProgressionPhase newPhase,  String reason,  double confidence,  bool requiresMicrodeload,  int? weeksToMicrodeload,  int? vmrDiscovered,  bool isNewCycle,  List<ExerciseReplacement> exercisesToReplace)  $default,) {final _that = this;
switch (_that) {
case _MuscleDecision():
return $default(_that.muscle,_that.action,_that.newVolume,_that.newPhase,_that.reason,_that.confidence,_that.requiresMicrodeload,_that.weeksToMicrodeload,_that.vmrDiscovered,_that.isNewCycle,_that.exercisesToReplace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String muscle,  VolumeAction action,  int newVolume,  ProgressionPhase newPhase,  String reason,  double confidence,  bool requiresMicrodeload,  int? weeksToMicrodeload,  int? vmrDiscovered,  bool isNewCycle,  List<ExerciseReplacement> exercisesToReplace)?  $default,) {final _that = this;
switch (_that) {
case _MuscleDecision() when $default != null:
return $default(_that.muscle,_that.action,_that.newVolume,_that.newPhase,_that.reason,_that.confidence,_that.requiresMicrodeload,_that.weeksToMicrodeload,_that.vmrDiscovered,_that.isNewCycle,_that.exercisesToReplace);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MuscleDecision implements MuscleDecision {
  const _MuscleDecision({required this.muscle, required this.action, required this.newVolume, required this.newPhase, required this.reason, required this.confidence, this.requiresMicrodeload = false, this.weeksToMicrodeload, this.vmrDiscovered, this.isNewCycle = false, final  List<ExerciseReplacement> exercisesToReplace = const []}): _exercisesToReplace = exercisesToReplace;
  factory _MuscleDecision.fromJson(Map<String, dynamic> json) => _$MuscleDecisionFromJson(json);

@override final  String muscle;
@override final  VolumeAction action;
@override final  int newVolume;
@override final  ProgressionPhase newPhase;
@override final  String reason;
@override final  double confidence;
@override@JsonKey() final  bool requiresMicrodeload;
@override final  int? weeksToMicrodeload;
@override final  int? vmrDiscovered;
@override@JsonKey() final  bool isNewCycle;
 final  List<ExerciseReplacement> _exercisesToReplace;
@override@JsonKey() List<ExerciseReplacement> get exercisesToReplace {
  if (_exercisesToReplace is EqualUnmodifiableListView) return _exercisesToReplace;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercisesToReplace);
}


/// Create a copy of MuscleDecision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MuscleDecisionCopyWith<_MuscleDecision> get copyWith => __$MuscleDecisionCopyWithImpl<_MuscleDecision>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MuscleDecisionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MuscleDecision&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.action, action) || other.action == action)&&(identical(other.newVolume, newVolume) || other.newVolume == newVolume)&&(identical(other.newPhase, newPhase) || other.newPhase == newPhase)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.requiresMicrodeload, requiresMicrodeload) || other.requiresMicrodeload == requiresMicrodeload)&&(identical(other.weeksToMicrodeload, weeksToMicrodeload) || other.weeksToMicrodeload == weeksToMicrodeload)&&(identical(other.vmrDiscovered, vmrDiscovered) || other.vmrDiscovered == vmrDiscovered)&&(identical(other.isNewCycle, isNewCycle) || other.isNewCycle == isNewCycle)&&const DeepCollectionEquality().equals(other._exercisesToReplace, _exercisesToReplace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,muscle,action,newVolume,newPhase,reason,confidence,requiresMicrodeload,weeksToMicrodeload,vmrDiscovered,isNewCycle,const DeepCollectionEquality().hash(_exercisesToReplace));

@override
String toString() {
  return 'MuscleDecision(muscle: $muscle, action: $action, newVolume: $newVolume, newPhase: $newPhase, reason: $reason, confidence: $confidence, requiresMicrodeload: $requiresMicrodeload, weeksToMicrodeload: $weeksToMicrodeload, vmrDiscovered: $vmrDiscovered, isNewCycle: $isNewCycle, exercisesToReplace: $exercisesToReplace)';
}


}

/// @nodoc
abstract mixin class _$MuscleDecisionCopyWith<$Res> implements $MuscleDecisionCopyWith<$Res> {
  factory _$MuscleDecisionCopyWith(_MuscleDecision value, $Res Function(_MuscleDecision) _then) = __$MuscleDecisionCopyWithImpl;
@override @useResult
$Res call({
 String muscle, VolumeAction action, int newVolume, ProgressionPhase newPhase, String reason, double confidence, bool requiresMicrodeload, int? weeksToMicrodeload, int? vmrDiscovered, bool isNewCycle, List<ExerciseReplacement> exercisesToReplace
});




}
/// @nodoc
class __$MuscleDecisionCopyWithImpl<$Res>
    implements _$MuscleDecisionCopyWith<$Res> {
  __$MuscleDecisionCopyWithImpl(this._self, this._then);

  final _MuscleDecision _self;
  final $Res Function(_MuscleDecision) _then;

/// Create a copy of MuscleDecision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? muscle = null,Object? action = null,Object? newVolume = null,Object? newPhase = null,Object? reason = null,Object? confidence = null,Object? requiresMicrodeload = null,Object? weeksToMicrodeload = freezed,Object? vmrDiscovered = freezed,Object? isNewCycle = null,Object? exercisesToReplace = null,}) {
  return _then(_MuscleDecision(
muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as VolumeAction,newVolume: null == newVolume ? _self.newVolume : newVolume // ignore: cast_nullable_to_non_nullable
as int,newPhase: null == newPhase ? _self.newPhase : newPhase // ignore: cast_nullable_to_non_nullable
as ProgressionPhase,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,requiresMicrodeload: null == requiresMicrodeload ? _self.requiresMicrodeload : requiresMicrodeload // ignore: cast_nullable_to_non_nullable
as bool,weeksToMicrodeload: freezed == weeksToMicrodeload ? _self.weeksToMicrodeload : weeksToMicrodeload // ignore: cast_nullable_to_non_nullable
as int?,vmrDiscovered: freezed == vmrDiscovered ? _self.vmrDiscovered : vmrDiscovered // ignore: cast_nullable_to_non_nullable
as int?,isNewCycle: null == isNewCycle ? _self.isNewCycle : isNewCycle // ignore: cast_nullable_to_non_nullable
as bool,exercisesToReplace: null == exercisesToReplace ? _self._exercisesToReplace : exercisesToReplace // ignore: cast_nullable_to_non_nullable
as List<ExerciseReplacement>,
  ));
}


}


/// @nodoc
mixin _$ExerciseReplacement {

 String get exerciseId; String get exerciseName; String get reason; double get muscleActivation; bool get hadDiscomfort;
/// Create a copy of ExerciseReplacement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseReplacementCopyWith<ExerciseReplacement> get copyWith => _$ExerciseReplacementCopyWithImpl<ExerciseReplacement>(this as ExerciseReplacement, _$identity);

  /// Serializes this ExerciseReplacement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseReplacement&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.hadDiscomfort, hadDiscomfort) || other.hadDiscomfort == hadDiscomfort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,exerciseName,reason,muscleActivation,hadDiscomfort);

@override
String toString() {
  return 'ExerciseReplacement(exerciseId: $exerciseId, exerciseName: $exerciseName, reason: $reason, muscleActivation: $muscleActivation, hadDiscomfort: $hadDiscomfort)';
}


}

/// @nodoc
abstract mixin class $ExerciseReplacementCopyWith<$Res>  {
  factory $ExerciseReplacementCopyWith(ExerciseReplacement value, $Res Function(ExerciseReplacement) _then) = _$ExerciseReplacementCopyWithImpl;
@useResult
$Res call({
 String exerciseId, String exerciseName, String reason, double muscleActivation, bool hadDiscomfort
});




}
/// @nodoc
class _$ExerciseReplacementCopyWithImpl<$Res>
    implements $ExerciseReplacementCopyWith<$Res> {
  _$ExerciseReplacementCopyWithImpl(this._self, this._then);

  final ExerciseReplacement _self;
  final $Res Function(ExerciseReplacement) _then;

/// Create a copy of ExerciseReplacement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exerciseId = null,Object? exerciseName = null,Object? reason = null,Object? muscleActivation = null,Object? hadDiscomfort = null,}) {
  return _then(_self.copyWith(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,hadDiscomfort: null == hadDiscomfort ? _self.hadDiscomfort : hadDiscomfort // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseReplacement].
extension ExerciseReplacementPatterns on ExerciseReplacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseReplacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseReplacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseReplacement value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseReplacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseReplacement value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseReplacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String exerciseId,  String exerciseName,  String reason,  double muscleActivation,  bool hadDiscomfort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseReplacement() when $default != null:
return $default(_that.exerciseId,_that.exerciseName,_that.reason,_that.muscleActivation,_that.hadDiscomfort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String exerciseId,  String exerciseName,  String reason,  double muscleActivation,  bool hadDiscomfort)  $default,) {final _that = this;
switch (_that) {
case _ExerciseReplacement():
return $default(_that.exerciseId,_that.exerciseName,_that.reason,_that.muscleActivation,_that.hadDiscomfort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String exerciseId,  String exerciseName,  String reason,  double muscleActivation,  bool hadDiscomfort)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseReplacement() when $default != null:
return $default(_that.exerciseId,_that.exerciseName,_that.reason,_that.muscleActivation,_that.hadDiscomfort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseReplacement implements ExerciseReplacement {
  const _ExerciseReplacement({required this.exerciseId, required this.exerciseName, required this.reason, required this.muscleActivation, this.hadDiscomfort = false});
  factory _ExerciseReplacement.fromJson(Map<String, dynamic> json) => _$ExerciseReplacementFromJson(json);

@override final  String exerciseId;
@override final  String exerciseName;
@override final  String reason;
@override final  double muscleActivation;
@override@JsonKey() final  bool hadDiscomfort;

/// Create a copy of ExerciseReplacement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseReplacementCopyWith<_ExerciseReplacement> get copyWith => __$ExerciseReplacementCopyWithImpl<_ExerciseReplacement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseReplacementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseReplacement&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.hadDiscomfort, hadDiscomfort) || other.hadDiscomfort == hadDiscomfort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,exerciseName,reason,muscleActivation,hadDiscomfort);

@override
String toString() {
  return 'ExerciseReplacement(exerciseId: $exerciseId, exerciseName: $exerciseName, reason: $reason, muscleActivation: $muscleActivation, hadDiscomfort: $hadDiscomfort)';
}


}

/// @nodoc
abstract mixin class _$ExerciseReplacementCopyWith<$Res> implements $ExerciseReplacementCopyWith<$Res> {
  factory _$ExerciseReplacementCopyWith(_ExerciseReplacement value, $Res Function(_ExerciseReplacement) _then) = __$ExerciseReplacementCopyWithImpl;
@override @useResult
$Res call({
 String exerciseId, String exerciseName, String reason, double muscleActivation, bool hadDiscomfort
});




}
/// @nodoc
class __$ExerciseReplacementCopyWithImpl<$Res>
    implements _$ExerciseReplacementCopyWith<$Res> {
  __$ExerciseReplacementCopyWithImpl(this._self, this._then);

  final _ExerciseReplacement _self;
  final $Res Function(_ExerciseReplacement) _then;

/// Create a copy of ExerciseReplacement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exerciseId = null,Object? exerciseName = null,Object? reason = null,Object? muscleActivation = null,Object? hadDiscomfort = null,}) {
  return _then(_ExerciseReplacement(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,hadDiscomfort: null == hadDiscomfort ? _self.hadDiscomfort : hadDiscomfort // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
