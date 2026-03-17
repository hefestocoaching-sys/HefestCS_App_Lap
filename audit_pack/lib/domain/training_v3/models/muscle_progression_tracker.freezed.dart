// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'muscle_progression_tracker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MuscleProgressionTracker {

 String get muscle; int get priority; VolumeLandmarks get landmarks; int get currentVolume; ProgressionPhase get currentPhase; int get weekInCurrentPhase; int get totalWeeksInCycle; int? get vmrDiscovered; List<WeeklyMuscleMetrics> get history; List<PhaseTransition> get phaseTimeline; DateTime get lastUpdated;
/// Create a copy of MuscleProgressionTracker
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MuscleProgressionTrackerCopyWith<MuscleProgressionTracker> get copyWith => _$MuscleProgressionTrackerCopyWithImpl<MuscleProgressionTracker>(this as MuscleProgressionTracker, _$identity);

  /// Serializes this MuscleProgressionTracker to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MuscleProgressionTracker&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.landmarks, landmarks) || other.landmarks == landmarks)&&(identical(other.currentVolume, currentVolume) || other.currentVolume == currentVolume)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.weekInCurrentPhase, weekInCurrentPhase) || other.weekInCurrentPhase == weekInCurrentPhase)&&(identical(other.totalWeeksInCycle, totalWeeksInCycle) || other.totalWeeksInCycle == totalWeeksInCycle)&&(identical(other.vmrDiscovered, vmrDiscovered) || other.vmrDiscovered == vmrDiscovered)&&const DeepCollectionEquality().equals(other.history, history)&&const DeepCollectionEquality().equals(other.phaseTimeline, phaseTimeline)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,muscle,priority,landmarks,currentVolume,currentPhase,weekInCurrentPhase,totalWeeksInCycle,vmrDiscovered,const DeepCollectionEquality().hash(history),const DeepCollectionEquality().hash(phaseTimeline),lastUpdated);

@override
String toString() {
  return 'MuscleProgressionTracker(muscle: $muscle, priority: $priority, landmarks: $landmarks, currentVolume: $currentVolume, currentPhase: $currentPhase, weekInCurrentPhase: $weekInCurrentPhase, totalWeeksInCycle: $totalWeeksInCycle, vmrDiscovered: $vmrDiscovered, history: $history, phaseTimeline: $phaseTimeline, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $MuscleProgressionTrackerCopyWith<$Res>  {
  factory $MuscleProgressionTrackerCopyWith(MuscleProgressionTracker value, $Res Function(MuscleProgressionTracker) _then) = _$MuscleProgressionTrackerCopyWithImpl;
@useResult
$Res call({
 String muscle, int priority, VolumeLandmarks landmarks, int currentVolume, ProgressionPhase currentPhase, int weekInCurrentPhase, int totalWeeksInCycle, int? vmrDiscovered, List<WeeklyMuscleMetrics> history, List<PhaseTransition> phaseTimeline, DateTime lastUpdated
});


$VolumeLandmarksCopyWith<$Res> get landmarks;

}
/// @nodoc
class _$MuscleProgressionTrackerCopyWithImpl<$Res>
    implements $MuscleProgressionTrackerCopyWith<$Res> {
  _$MuscleProgressionTrackerCopyWithImpl(this._self, this._then);

  final MuscleProgressionTracker _self;
  final $Res Function(MuscleProgressionTracker) _then;

/// Create a copy of MuscleProgressionTracker
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? muscle = null,Object? priority = null,Object? landmarks = null,Object? currentVolume = null,Object? currentPhase = null,Object? weekInCurrentPhase = null,Object? totalWeeksInCycle = null,Object? vmrDiscovered = freezed,Object? history = null,Object? phaseTimeline = null,Object? lastUpdated = null,}) {
  return _then(_self.copyWith(
muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,landmarks: null == landmarks ? _self.landmarks : landmarks // ignore: cast_nullable_to_non_nullable
as VolumeLandmarks,currentVolume: null == currentVolume ? _self.currentVolume : currentVolume // ignore: cast_nullable_to_non_nullable
as int,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as ProgressionPhase,weekInCurrentPhase: null == weekInCurrentPhase ? _self.weekInCurrentPhase : weekInCurrentPhase // ignore: cast_nullable_to_non_nullable
as int,totalWeeksInCycle: null == totalWeeksInCycle ? _self.totalWeeksInCycle : totalWeeksInCycle // ignore: cast_nullable_to_non_nullable
as int,vmrDiscovered: freezed == vmrDiscovered ? _self.vmrDiscovered : vmrDiscovered // ignore: cast_nullable_to_non_nullable
as int?,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<WeeklyMuscleMetrics>,phaseTimeline: null == phaseTimeline ? _self.phaseTimeline : phaseTimeline // ignore: cast_nullable_to_non_nullable
as List<PhaseTransition>,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of MuscleProgressionTracker
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VolumeLandmarksCopyWith<$Res> get landmarks {
  
  return $VolumeLandmarksCopyWith<$Res>(_self.landmarks, (value) {
    return _then(_self.copyWith(landmarks: value));
  });
}
}


/// Adds pattern-matching-related methods to [MuscleProgressionTracker].
extension MuscleProgressionTrackerPatterns on MuscleProgressionTracker {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MuscleProgressionTracker value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MuscleProgressionTracker() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MuscleProgressionTracker value)  $default,){
final _that = this;
switch (_that) {
case _MuscleProgressionTracker():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MuscleProgressionTracker value)?  $default,){
final _that = this;
switch (_that) {
case _MuscleProgressionTracker() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String muscle,  int priority,  VolumeLandmarks landmarks,  int currentVolume,  ProgressionPhase currentPhase,  int weekInCurrentPhase,  int totalWeeksInCycle,  int? vmrDiscovered,  List<WeeklyMuscleMetrics> history,  List<PhaseTransition> phaseTimeline,  DateTime lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MuscleProgressionTracker() when $default != null:
return $default(_that.muscle,_that.priority,_that.landmarks,_that.currentVolume,_that.currentPhase,_that.weekInCurrentPhase,_that.totalWeeksInCycle,_that.vmrDiscovered,_that.history,_that.phaseTimeline,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String muscle,  int priority,  VolumeLandmarks landmarks,  int currentVolume,  ProgressionPhase currentPhase,  int weekInCurrentPhase,  int totalWeeksInCycle,  int? vmrDiscovered,  List<WeeklyMuscleMetrics> history,  List<PhaseTransition> phaseTimeline,  DateTime lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _MuscleProgressionTracker():
return $default(_that.muscle,_that.priority,_that.landmarks,_that.currentVolume,_that.currentPhase,_that.weekInCurrentPhase,_that.totalWeeksInCycle,_that.vmrDiscovered,_that.history,_that.phaseTimeline,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String muscle,  int priority,  VolumeLandmarks landmarks,  int currentVolume,  ProgressionPhase currentPhase,  int weekInCurrentPhase,  int totalWeeksInCycle,  int? vmrDiscovered,  List<WeeklyMuscleMetrics> history,  List<PhaseTransition> phaseTimeline,  DateTime lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _MuscleProgressionTracker() when $default != null:
return $default(_that.muscle,_that.priority,_that.landmarks,_that.currentVolume,_that.currentPhase,_that.weekInCurrentPhase,_that.totalWeeksInCycle,_that.vmrDiscovered,_that.history,_that.phaseTimeline,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MuscleProgressionTracker implements MuscleProgressionTracker {
  const _MuscleProgressionTracker({required this.muscle, required this.priority, required this.landmarks, required this.currentVolume, required this.currentPhase, required this.weekInCurrentPhase, required this.totalWeeksInCycle, this.vmrDiscovered, final  List<WeeklyMuscleMetrics> history = const [], final  List<PhaseTransition> phaseTimeline = const [], required this.lastUpdated}): _history = history,_phaseTimeline = phaseTimeline;
  factory _MuscleProgressionTracker.fromJson(Map<String, dynamic> json) => _$MuscleProgressionTrackerFromJson(json);

@override final  String muscle;
@override final  int priority;
@override final  VolumeLandmarks landmarks;
@override final  int currentVolume;
@override final  ProgressionPhase currentPhase;
@override final  int weekInCurrentPhase;
@override final  int totalWeeksInCycle;
@override final  int? vmrDiscovered;
 final  List<WeeklyMuscleMetrics> _history;
@override@JsonKey() List<WeeklyMuscleMetrics> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

 final  List<PhaseTransition> _phaseTimeline;
@override@JsonKey() List<PhaseTransition> get phaseTimeline {
  if (_phaseTimeline is EqualUnmodifiableListView) return _phaseTimeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_phaseTimeline);
}

@override final  DateTime lastUpdated;

/// Create a copy of MuscleProgressionTracker
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MuscleProgressionTrackerCopyWith<_MuscleProgressionTracker> get copyWith => __$MuscleProgressionTrackerCopyWithImpl<_MuscleProgressionTracker>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MuscleProgressionTrackerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MuscleProgressionTracker&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.landmarks, landmarks) || other.landmarks == landmarks)&&(identical(other.currentVolume, currentVolume) || other.currentVolume == currentVolume)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.weekInCurrentPhase, weekInCurrentPhase) || other.weekInCurrentPhase == weekInCurrentPhase)&&(identical(other.totalWeeksInCycle, totalWeeksInCycle) || other.totalWeeksInCycle == totalWeeksInCycle)&&(identical(other.vmrDiscovered, vmrDiscovered) || other.vmrDiscovered == vmrDiscovered)&&const DeepCollectionEquality().equals(other._history, _history)&&const DeepCollectionEquality().equals(other._phaseTimeline, _phaseTimeline)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,muscle,priority,landmarks,currentVolume,currentPhase,weekInCurrentPhase,totalWeeksInCycle,vmrDiscovered,const DeepCollectionEquality().hash(_history),const DeepCollectionEquality().hash(_phaseTimeline),lastUpdated);

@override
String toString() {
  return 'MuscleProgressionTracker(muscle: $muscle, priority: $priority, landmarks: $landmarks, currentVolume: $currentVolume, currentPhase: $currentPhase, weekInCurrentPhase: $weekInCurrentPhase, totalWeeksInCycle: $totalWeeksInCycle, vmrDiscovered: $vmrDiscovered, history: $history, phaseTimeline: $phaseTimeline, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$MuscleProgressionTrackerCopyWith<$Res> implements $MuscleProgressionTrackerCopyWith<$Res> {
  factory _$MuscleProgressionTrackerCopyWith(_MuscleProgressionTracker value, $Res Function(_MuscleProgressionTracker) _then) = __$MuscleProgressionTrackerCopyWithImpl;
@override @useResult
$Res call({
 String muscle, int priority, VolumeLandmarks landmarks, int currentVolume, ProgressionPhase currentPhase, int weekInCurrentPhase, int totalWeeksInCycle, int? vmrDiscovered, List<WeeklyMuscleMetrics> history, List<PhaseTransition> phaseTimeline, DateTime lastUpdated
});


@override $VolumeLandmarksCopyWith<$Res> get landmarks;

}
/// @nodoc
class __$MuscleProgressionTrackerCopyWithImpl<$Res>
    implements _$MuscleProgressionTrackerCopyWith<$Res> {
  __$MuscleProgressionTrackerCopyWithImpl(this._self, this._then);

  final _MuscleProgressionTracker _self;
  final $Res Function(_MuscleProgressionTracker) _then;

/// Create a copy of MuscleProgressionTracker
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? muscle = null,Object? priority = null,Object? landmarks = null,Object? currentVolume = null,Object? currentPhase = null,Object? weekInCurrentPhase = null,Object? totalWeeksInCycle = null,Object? vmrDiscovered = freezed,Object? history = null,Object? phaseTimeline = null,Object? lastUpdated = null,}) {
  return _then(_MuscleProgressionTracker(
muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,landmarks: null == landmarks ? _self.landmarks : landmarks // ignore: cast_nullable_to_non_nullable
as VolumeLandmarks,currentVolume: null == currentVolume ? _self.currentVolume : currentVolume // ignore: cast_nullable_to_non_nullable
as int,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as ProgressionPhase,weekInCurrentPhase: null == weekInCurrentPhase ? _self.weekInCurrentPhase : weekInCurrentPhase // ignore: cast_nullable_to_non_nullable
as int,totalWeeksInCycle: null == totalWeeksInCycle ? _self.totalWeeksInCycle : totalWeeksInCycle // ignore: cast_nullable_to_non_nullable
as int,vmrDiscovered: freezed == vmrDiscovered ? _self.vmrDiscovered : vmrDiscovered // ignore: cast_nullable_to_non_nullable
as int?,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<WeeklyMuscleMetrics>,phaseTimeline: null == phaseTimeline ? _self._phaseTimeline : phaseTimeline // ignore: cast_nullable_to_non_nullable
as List<PhaseTransition>,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of MuscleProgressionTracker
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VolumeLandmarksCopyWith<$Res> get landmarks {
  
  return $VolumeLandmarksCopyWith<$Res>(_self.landmarks, (value) {
    return _then(_self.copyWith(landmarks: value));
  });
}
}


/// @nodoc
mixin _$PhaseTransition {

 int get weekNumber; ProgressionPhase get fromPhase; ProgressionPhase get toPhase; int get volume; String get reason; DateTime get timestamp;
/// Create a copy of PhaseTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhaseTransitionCopyWith<PhaseTransition> get copyWith => _$PhaseTransitionCopyWithImpl<PhaseTransition>(this as PhaseTransition, _$identity);

  /// Serializes this PhaseTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhaseTransition&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.fromPhase, fromPhase) || other.fromPhase == fromPhase)&&(identical(other.toPhase, toPhase) || other.toPhase == toPhase)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekNumber,fromPhase,toPhase,volume,reason,timestamp);

@override
String toString() {
  return 'PhaseTransition(weekNumber: $weekNumber, fromPhase: $fromPhase, toPhase: $toPhase, volume: $volume, reason: $reason, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $PhaseTransitionCopyWith<$Res>  {
  factory $PhaseTransitionCopyWith(PhaseTransition value, $Res Function(PhaseTransition) _then) = _$PhaseTransitionCopyWithImpl;
@useResult
$Res call({
 int weekNumber, ProgressionPhase fromPhase, ProgressionPhase toPhase, int volume, String reason, DateTime timestamp
});




}
/// @nodoc
class _$PhaseTransitionCopyWithImpl<$Res>
    implements $PhaseTransitionCopyWith<$Res> {
  _$PhaseTransitionCopyWithImpl(this._self, this._then);

  final PhaseTransition _self;
  final $Res Function(PhaseTransition) _then;

/// Create a copy of PhaseTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekNumber = null,Object? fromPhase = null,Object? toPhase = null,Object? volume = null,Object? reason = null,Object? timestamp = null,}) {
  return _then(_self.copyWith(
weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,fromPhase: null == fromPhase ? _self.fromPhase : fromPhase // ignore: cast_nullable_to_non_nullable
as ProgressionPhase,toPhase: null == toPhase ? _self.toPhase : toPhase // ignore: cast_nullable_to_non_nullable
as ProgressionPhase,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PhaseTransition].
extension PhaseTransitionPatterns on PhaseTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhaseTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhaseTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhaseTransition value)  $default,){
final _that = this;
switch (_that) {
case _PhaseTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhaseTransition value)?  $default,){
final _that = this;
switch (_that) {
case _PhaseTransition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int weekNumber,  ProgressionPhase fromPhase,  ProgressionPhase toPhase,  int volume,  String reason,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhaseTransition() when $default != null:
return $default(_that.weekNumber,_that.fromPhase,_that.toPhase,_that.volume,_that.reason,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int weekNumber,  ProgressionPhase fromPhase,  ProgressionPhase toPhase,  int volume,  String reason,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _PhaseTransition():
return $default(_that.weekNumber,_that.fromPhase,_that.toPhase,_that.volume,_that.reason,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int weekNumber,  ProgressionPhase fromPhase,  ProgressionPhase toPhase,  int volume,  String reason,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _PhaseTransition() when $default != null:
return $default(_that.weekNumber,_that.fromPhase,_that.toPhase,_that.volume,_that.reason,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhaseTransition implements PhaseTransition {
  const _PhaseTransition({required this.weekNumber, required this.fromPhase, required this.toPhase, required this.volume, required this.reason, required this.timestamp});
  factory _PhaseTransition.fromJson(Map<String, dynamic> json) => _$PhaseTransitionFromJson(json);

@override final  int weekNumber;
@override final  ProgressionPhase fromPhase;
@override final  ProgressionPhase toPhase;
@override final  int volume;
@override final  String reason;
@override final  DateTime timestamp;

/// Create a copy of PhaseTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhaseTransitionCopyWith<_PhaseTransition> get copyWith => __$PhaseTransitionCopyWithImpl<_PhaseTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhaseTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhaseTransition&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.fromPhase, fromPhase) || other.fromPhase == fromPhase)&&(identical(other.toPhase, toPhase) || other.toPhase == toPhase)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekNumber,fromPhase,toPhase,volume,reason,timestamp);

@override
String toString() {
  return 'PhaseTransition(weekNumber: $weekNumber, fromPhase: $fromPhase, toPhase: $toPhase, volume: $volume, reason: $reason, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$PhaseTransitionCopyWith<$Res> implements $PhaseTransitionCopyWith<$Res> {
  factory _$PhaseTransitionCopyWith(_PhaseTransition value, $Res Function(_PhaseTransition) _then) = __$PhaseTransitionCopyWithImpl;
@override @useResult
$Res call({
 int weekNumber, ProgressionPhase fromPhase, ProgressionPhase toPhase, int volume, String reason, DateTime timestamp
});




}
/// @nodoc
class __$PhaseTransitionCopyWithImpl<$Res>
    implements _$PhaseTransitionCopyWith<$Res> {
  __$PhaseTransitionCopyWithImpl(this._self, this._then);

  final _PhaseTransition _self;
  final $Res Function(_PhaseTransition) _then;

/// Create a copy of PhaseTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekNumber = null,Object? fromPhase = null,Object? toPhase = null,Object? volume = null,Object? reason = null,Object? timestamp = null,}) {
  return _then(_PhaseTransition(
weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,fromPhase: null == fromPhase ? _self.fromPhase : fromPhase // ignore: cast_nullable_to_non_nullable
as ProgressionPhase,toPhase: null == toPhase ? _self.toPhase : toPhase // ignore: cast_nullable_to_non_nullable
as ProgressionPhase,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
