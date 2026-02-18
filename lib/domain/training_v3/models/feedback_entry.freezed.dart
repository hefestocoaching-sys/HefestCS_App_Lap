// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeedbackEntry {

/// Identificadores
 String get userId; String get muscle; int get weekNumber; DateTime get weekStart; DateTime get weekEnd;/// Ratings subjetivos (escala 1-10 o 0-10)
 double get muscleActivation;// ¿Sentiste bien el músculo? (8=bien, 3=mal)
 double get pumpQuality;// Calidad del pump (8=excelente, 2=nada)
 double get fatigueLevel;// Fatiga acumulada (1=nada, 10=máxima)
 double get recoveryQuality;// Calidad de recuperación entre sesiones (1=pésima, 10=perfecta)
/// Flags
 bool get hadPain;// ¿Tuvo dolor o molestia?
 bool get deloadRequested;// ¿Solicita deload manual? (coach override)
 bool get isInjury;// ¿Hay lesión?
/// Notas libres
 String get userComments;// Cliente escribe qué pasó
/// Coach override (después de leer feedback)
 String get coachFeedback;// Coach agrega contexto/notas
/// Timestamps
 DateTime get submittedAt;// Cuándo se envió el feedback
 DateTime? get coachReviewedAt;// Cuándo lo revisó el coach
/// Metadata
 Map<String, dynamic> get metadata;
/// Create a copy of FeedbackEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackEntryCopyWith<FeedbackEntry> get copyWith => _$FeedbackEntryCopyWithImpl<FeedbackEntry>(this as FeedbackEntry, _$identity);

  /// Serializes this FeedbackEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackEntry&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.pumpQuality, pumpQuality) || other.pumpQuality == pumpQuality)&&(identical(other.fatigueLevel, fatigueLevel) || other.fatigueLevel == fatigueLevel)&&(identical(other.recoveryQuality, recoveryQuality) || other.recoveryQuality == recoveryQuality)&&(identical(other.hadPain, hadPain) || other.hadPain == hadPain)&&(identical(other.deloadRequested, deloadRequested) || other.deloadRequested == deloadRequested)&&(identical(other.isInjury, isInjury) || other.isInjury == isInjury)&&(identical(other.userComments, userComments) || other.userComments == userComments)&&(identical(other.coachFeedback, coachFeedback) || other.coachFeedback == coachFeedback)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.coachReviewedAt, coachReviewedAt) || other.coachReviewedAt == coachReviewedAt)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,muscle,weekNumber,weekStart,weekEnd,muscleActivation,pumpQuality,fatigueLevel,recoveryQuality,hadPain,deloadRequested,isInjury,userComments,coachFeedback,submittedAt,coachReviewedAt,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'FeedbackEntry(userId: $userId, muscle: $muscle, weekNumber: $weekNumber, weekStart: $weekStart, weekEnd: $weekEnd, muscleActivation: $muscleActivation, pumpQuality: $pumpQuality, fatigueLevel: $fatigueLevel, recoveryQuality: $recoveryQuality, hadPain: $hadPain, deloadRequested: $deloadRequested, isInjury: $isInjury, userComments: $userComments, coachFeedback: $coachFeedback, submittedAt: $submittedAt, coachReviewedAt: $coachReviewedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $FeedbackEntryCopyWith<$Res>  {
  factory $FeedbackEntryCopyWith(FeedbackEntry value, $Res Function(FeedbackEntry) _then) = _$FeedbackEntryCopyWithImpl;
@useResult
$Res call({
 String userId, String muscle, int weekNumber, DateTime weekStart, DateTime weekEnd, double muscleActivation, double pumpQuality, double fatigueLevel, double recoveryQuality, bool hadPain, bool deloadRequested, bool isInjury, String userComments, String coachFeedback, DateTime submittedAt, DateTime? coachReviewedAt, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$FeedbackEntryCopyWithImpl<$Res>
    implements $FeedbackEntryCopyWith<$Res> {
  _$FeedbackEntryCopyWithImpl(this._self, this._then);

  final FeedbackEntry _self;
  final $Res Function(FeedbackEntry) _then;

/// Create a copy of FeedbackEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? muscle = null,Object? weekNumber = null,Object? weekStart = null,Object? weekEnd = null,Object? muscleActivation = null,Object? pumpQuality = null,Object? fatigueLevel = null,Object? recoveryQuality = null,Object? hadPain = null,Object? deloadRequested = null,Object? isInjury = null,Object? userComments = null,Object? coachFeedback = null,Object? submittedAt = null,Object? coachReviewedAt = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as DateTime,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,pumpQuality: null == pumpQuality ? _self.pumpQuality : pumpQuality // ignore: cast_nullable_to_non_nullable
as double,fatigueLevel: null == fatigueLevel ? _self.fatigueLevel : fatigueLevel // ignore: cast_nullable_to_non_nullable
as double,recoveryQuality: null == recoveryQuality ? _self.recoveryQuality : recoveryQuality // ignore: cast_nullable_to_non_nullable
as double,hadPain: null == hadPain ? _self.hadPain : hadPain // ignore: cast_nullable_to_non_nullable
as bool,deloadRequested: null == deloadRequested ? _self.deloadRequested : deloadRequested // ignore: cast_nullable_to_non_nullable
as bool,isInjury: null == isInjury ? _self.isInjury : isInjury // ignore: cast_nullable_to_non_nullable
as bool,userComments: null == userComments ? _self.userComments : userComments // ignore: cast_nullable_to_non_nullable
as String,coachFeedback: null == coachFeedback ? _self.coachFeedback : coachFeedback // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,coachReviewedAt: freezed == coachReviewedAt ? _self.coachReviewedAt : coachReviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedbackEntry].
extension FeedbackEntryPatterns on FeedbackEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackEntry value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String muscle,  int weekNumber,  DateTime weekStart,  DateTime weekEnd,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  bool deloadRequested,  bool isInjury,  String userComments,  String coachFeedback,  DateTime submittedAt,  DateTime? coachReviewedAt,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackEntry() when $default != null:
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.weekStart,_that.weekEnd,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.deloadRequested,_that.isInjury,_that.userComments,_that.coachFeedback,_that.submittedAt,_that.coachReviewedAt,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String muscle,  int weekNumber,  DateTime weekStart,  DateTime weekEnd,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  bool deloadRequested,  bool isInjury,  String userComments,  String coachFeedback,  DateTime submittedAt,  DateTime? coachReviewedAt,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _FeedbackEntry():
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.weekStart,_that.weekEnd,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.deloadRequested,_that.isInjury,_that.userComments,_that.coachFeedback,_that.submittedAt,_that.coachReviewedAt,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String muscle,  int weekNumber,  DateTime weekStart,  DateTime weekEnd,  double muscleActivation,  double pumpQuality,  double fatigueLevel,  double recoveryQuality,  bool hadPain,  bool deloadRequested,  bool isInjury,  String userComments,  String coachFeedback,  DateTime submittedAt,  DateTime? coachReviewedAt,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackEntry() when $default != null:
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.weekStart,_that.weekEnd,_that.muscleActivation,_that.pumpQuality,_that.fatigueLevel,_that.recoveryQuality,_that.hadPain,_that.deloadRequested,_that.isInjury,_that.userComments,_that.coachFeedback,_that.submittedAt,_that.coachReviewedAt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeedbackEntry implements FeedbackEntry {
  const _FeedbackEntry({required this.userId, required this.muscle, required this.weekNumber, required this.weekStart, required this.weekEnd, required this.muscleActivation, required this.pumpQuality, required this.fatigueLevel, required this.recoveryQuality, required this.hadPain, required this.deloadRequested, this.isInjury = false, required this.userComments, this.coachFeedback = '', required this.submittedAt, this.coachReviewedAt = null, final  Map<String, dynamic> metadata = const {}}): _metadata = metadata;
  factory _FeedbackEntry.fromJson(Map<String, dynamic> json) => _$FeedbackEntryFromJson(json);

/// Identificadores
@override final  String userId;
@override final  String muscle;
@override final  int weekNumber;
@override final  DateTime weekStart;
@override final  DateTime weekEnd;
/// Ratings subjetivos (escala 1-10 o 0-10)
@override final  double muscleActivation;
// ¿Sentiste bien el músculo? (8=bien, 3=mal)
@override final  double pumpQuality;
// Calidad del pump (8=excelente, 2=nada)
@override final  double fatigueLevel;
// Fatiga acumulada (1=nada, 10=máxima)
@override final  double recoveryQuality;
// Calidad de recuperación entre sesiones (1=pésima, 10=perfecta)
/// Flags
@override final  bool hadPain;
// ¿Tuvo dolor o molestia?
@override final  bool deloadRequested;
// ¿Solicita deload manual? (coach override)
@override@JsonKey() final  bool isInjury;
// ¿Hay lesión?
/// Notas libres
@override final  String userComments;
// Cliente escribe qué pasó
/// Coach override (después de leer feedback)
@override@JsonKey() final  String coachFeedback;
// Coach agrega contexto/notas
/// Timestamps
@override final  DateTime submittedAt;
// Cuándo se envió el feedback
@override@JsonKey() final  DateTime? coachReviewedAt;
// Cuándo lo revisó el coach
/// Metadata
 final  Map<String, dynamic> _metadata;
// Cuándo lo revisó el coach
/// Metadata
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of FeedbackEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackEntryCopyWith<_FeedbackEntry> get copyWith => __$FeedbackEntryCopyWithImpl<_FeedbackEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeedbackEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackEntry&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.muscleActivation, muscleActivation) || other.muscleActivation == muscleActivation)&&(identical(other.pumpQuality, pumpQuality) || other.pumpQuality == pumpQuality)&&(identical(other.fatigueLevel, fatigueLevel) || other.fatigueLevel == fatigueLevel)&&(identical(other.recoveryQuality, recoveryQuality) || other.recoveryQuality == recoveryQuality)&&(identical(other.hadPain, hadPain) || other.hadPain == hadPain)&&(identical(other.deloadRequested, deloadRequested) || other.deloadRequested == deloadRequested)&&(identical(other.isInjury, isInjury) || other.isInjury == isInjury)&&(identical(other.userComments, userComments) || other.userComments == userComments)&&(identical(other.coachFeedback, coachFeedback) || other.coachFeedback == coachFeedback)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.coachReviewedAt, coachReviewedAt) || other.coachReviewedAt == coachReviewedAt)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,muscle,weekNumber,weekStart,weekEnd,muscleActivation,pumpQuality,fatigueLevel,recoveryQuality,hadPain,deloadRequested,isInjury,userComments,coachFeedback,submittedAt,coachReviewedAt,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'FeedbackEntry(userId: $userId, muscle: $muscle, weekNumber: $weekNumber, weekStart: $weekStart, weekEnd: $weekEnd, muscleActivation: $muscleActivation, pumpQuality: $pumpQuality, fatigueLevel: $fatigueLevel, recoveryQuality: $recoveryQuality, hadPain: $hadPain, deloadRequested: $deloadRequested, isInjury: $isInjury, userComments: $userComments, coachFeedback: $coachFeedback, submittedAt: $submittedAt, coachReviewedAt: $coachReviewedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$FeedbackEntryCopyWith<$Res> implements $FeedbackEntryCopyWith<$Res> {
  factory _$FeedbackEntryCopyWith(_FeedbackEntry value, $Res Function(_FeedbackEntry) _then) = __$FeedbackEntryCopyWithImpl;
@override @useResult
$Res call({
 String userId, String muscle, int weekNumber, DateTime weekStart, DateTime weekEnd, double muscleActivation, double pumpQuality, double fatigueLevel, double recoveryQuality, bool hadPain, bool deloadRequested, bool isInjury, String userComments, String coachFeedback, DateTime submittedAt, DateTime? coachReviewedAt, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$FeedbackEntryCopyWithImpl<$Res>
    implements _$FeedbackEntryCopyWith<$Res> {
  __$FeedbackEntryCopyWithImpl(this._self, this._then);

  final _FeedbackEntry _self;
  final $Res Function(_FeedbackEntry) _then;

/// Create a copy of FeedbackEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? muscle = null,Object? weekNumber = null,Object? weekStart = null,Object? weekEnd = null,Object? muscleActivation = null,Object? pumpQuality = null,Object? fatigueLevel = null,Object? recoveryQuality = null,Object? hadPain = null,Object? deloadRequested = null,Object? isInjury = null,Object? userComments = null,Object? coachFeedback = null,Object? submittedAt = null,Object? coachReviewedAt = freezed,Object? metadata = null,}) {
  return _then(_FeedbackEntry(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as DateTime,muscleActivation: null == muscleActivation ? _self.muscleActivation : muscleActivation // ignore: cast_nullable_to_non_nullable
as double,pumpQuality: null == pumpQuality ? _self.pumpQuality : pumpQuality // ignore: cast_nullable_to_non_nullable
as double,fatigueLevel: null == fatigueLevel ? _self.fatigueLevel : fatigueLevel // ignore: cast_nullable_to_non_nullable
as double,recoveryQuality: null == recoveryQuality ? _self.recoveryQuality : recoveryQuality // ignore: cast_nullable_to_non_nullable
as double,hadPain: null == hadPain ? _self.hadPain : hadPain // ignore: cast_nullable_to_non_nullable
as bool,deloadRequested: null == deloadRequested ? _self.deloadRequested : deloadRequested // ignore: cast_nullable_to_non_nullable
as bool,isInjury: null == isInjury ? _self.isInjury : isInjury // ignore: cast_nullable_to_non_nullable
as bool,userComments: null == userComments ? _self.userComments : userComments // ignore: cast_nullable_to_non_nullable
as String,coachFeedback: null == coachFeedback ? _self.coachFeedback : coachFeedback // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,coachReviewedAt: freezed == coachReviewedAt ? _self.coachReviewedAt : coachReviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
