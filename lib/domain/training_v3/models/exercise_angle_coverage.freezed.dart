// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_angle_coverage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseAngleCoverage {

/// Identificación
 String get userId; String get muscle; int get weekNumber; String get cycleId;// ID del ciclo (macrocycle/mesocycle)
/// Ángulos/planos usados ESTA SEMANA
/// Map: angleKey (ej: 'horizontal', 'vertical', 'incline')
///      -> List de exercise IDs que cubren ese ángulo
 Map<String, List<String>> get angleExerciseMap;/// Cobertura general (qué porcentaje de ángulos se cubrieron)
/// 0.0 = ningún ángulo, 1.0 = todos los ángulos
 double get coverageRatio;/// Ángulos identificados para este músculo
 List<String> get knownAngles;// 'horizontal', 'vertical', 'incline', etc.
/// Ángulos cubiertos esta semana
 List<String> get coveredAngles;/// Ángulos NO cubiertos (auditoría)
 List<String> get missingAngles;/// Variedad: ¿Cambió con respecto a semana anterior?
 bool get changedFromLastWeek;// ¿Usamos ángulos diferentes?
/// Timestamp
 DateTime get recordedAt;/// Metadata
 Map<String, dynamic> get metadata;
/// Create a copy of ExerciseAngleCoverage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseAngleCoverageCopyWith<ExerciseAngleCoverage> get copyWith => _$ExerciseAngleCoverageCopyWithImpl<ExerciseAngleCoverage>(this as ExerciseAngleCoverage, _$identity);

  /// Serializes this ExerciseAngleCoverage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseAngleCoverage&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.cycleId, cycleId) || other.cycleId == cycleId)&&const DeepCollectionEquality().equals(other.angleExerciseMap, angleExerciseMap)&&(identical(other.coverageRatio, coverageRatio) || other.coverageRatio == coverageRatio)&&const DeepCollectionEquality().equals(other.knownAngles, knownAngles)&&const DeepCollectionEquality().equals(other.coveredAngles, coveredAngles)&&const DeepCollectionEquality().equals(other.missingAngles, missingAngles)&&(identical(other.changedFromLastWeek, changedFromLastWeek) || other.changedFromLastWeek == changedFromLastWeek)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,muscle,weekNumber,cycleId,const DeepCollectionEquality().hash(angleExerciseMap),coverageRatio,const DeepCollectionEquality().hash(knownAngles),const DeepCollectionEquality().hash(coveredAngles),const DeepCollectionEquality().hash(missingAngles),changedFromLastWeek,recordedAt,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ExerciseAngleCoverage(userId: $userId, muscle: $muscle, weekNumber: $weekNumber, cycleId: $cycleId, angleExerciseMap: $angleExerciseMap, coverageRatio: $coverageRatio, knownAngles: $knownAngles, coveredAngles: $coveredAngles, missingAngles: $missingAngles, changedFromLastWeek: $changedFromLastWeek, recordedAt: $recordedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ExerciseAngleCoverageCopyWith<$Res>  {
  factory $ExerciseAngleCoverageCopyWith(ExerciseAngleCoverage value, $Res Function(ExerciseAngleCoverage) _then) = _$ExerciseAngleCoverageCopyWithImpl;
@useResult
$Res call({
 String userId, String muscle, int weekNumber, String cycleId, Map<String, List<String>> angleExerciseMap, double coverageRatio, List<String> knownAngles, List<String> coveredAngles, List<String> missingAngles, bool changedFromLastWeek, DateTime recordedAt, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$ExerciseAngleCoverageCopyWithImpl<$Res>
    implements $ExerciseAngleCoverageCopyWith<$Res> {
  _$ExerciseAngleCoverageCopyWithImpl(this._self, this._then);

  final ExerciseAngleCoverage _self;
  final $Res Function(ExerciseAngleCoverage) _then;

/// Create a copy of ExerciseAngleCoverage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? muscle = null,Object? weekNumber = null,Object? cycleId = null,Object? angleExerciseMap = null,Object? coverageRatio = null,Object? knownAngles = null,Object? coveredAngles = null,Object? missingAngles = null,Object? changedFromLastWeek = null,Object? recordedAt = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,cycleId: null == cycleId ? _self.cycleId : cycleId // ignore: cast_nullable_to_non_nullable
as String,angleExerciseMap: null == angleExerciseMap ? _self.angleExerciseMap : angleExerciseMap // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,coverageRatio: null == coverageRatio ? _self.coverageRatio : coverageRatio // ignore: cast_nullable_to_non_nullable
as double,knownAngles: null == knownAngles ? _self.knownAngles : knownAngles // ignore: cast_nullable_to_non_nullable
as List<String>,coveredAngles: null == coveredAngles ? _self.coveredAngles : coveredAngles // ignore: cast_nullable_to_non_nullable
as List<String>,missingAngles: null == missingAngles ? _self.missingAngles : missingAngles // ignore: cast_nullable_to_non_nullable
as List<String>,changedFromLastWeek: null == changedFromLastWeek ? _self.changedFromLastWeek : changedFromLastWeek // ignore: cast_nullable_to_non_nullable
as bool,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseAngleCoverage].
extension ExerciseAngleCoveragePatterns on ExerciseAngleCoverage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseAngleCoverage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseAngleCoverage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseAngleCoverage value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseAngleCoverage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseAngleCoverage value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseAngleCoverage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String muscle,  int weekNumber,  String cycleId,  Map<String, List<String>> angleExerciseMap,  double coverageRatio,  List<String> knownAngles,  List<String> coveredAngles,  List<String> missingAngles,  bool changedFromLastWeek,  DateTime recordedAt,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseAngleCoverage() when $default != null:
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.cycleId,_that.angleExerciseMap,_that.coverageRatio,_that.knownAngles,_that.coveredAngles,_that.missingAngles,_that.changedFromLastWeek,_that.recordedAt,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String muscle,  int weekNumber,  String cycleId,  Map<String, List<String>> angleExerciseMap,  double coverageRatio,  List<String> knownAngles,  List<String> coveredAngles,  List<String> missingAngles,  bool changedFromLastWeek,  DateTime recordedAt,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _ExerciseAngleCoverage():
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.cycleId,_that.angleExerciseMap,_that.coverageRatio,_that.knownAngles,_that.coveredAngles,_that.missingAngles,_that.changedFromLastWeek,_that.recordedAt,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String muscle,  int weekNumber,  String cycleId,  Map<String, List<String>> angleExerciseMap,  double coverageRatio,  List<String> knownAngles,  List<String> coveredAngles,  List<String> missingAngles,  bool changedFromLastWeek,  DateTime recordedAt,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseAngleCoverage() when $default != null:
return $default(_that.userId,_that.muscle,_that.weekNumber,_that.cycleId,_that.angleExerciseMap,_that.coverageRatio,_that.knownAngles,_that.coveredAngles,_that.missingAngles,_that.changedFromLastWeek,_that.recordedAt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseAngleCoverage implements ExerciseAngleCoverage {
  const _ExerciseAngleCoverage({required this.userId, required this.muscle, required this.weekNumber, required this.cycleId, required final  Map<String, List<String>> angleExerciseMap, required this.coverageRatio, final  List<String> knownAngles = const [], final  List<String> coveredAngles = const [], final  List<String> missingAngles = const [], required this.changedFromLastWeek, required this.recordedAt, final  Map<String, dynamic> metadata = const {}}): _angleExerciseMap = angleExerciseMap,_knownAngles = knownAngles,_coveredAngles = coveredAngles,_missingAngles = missingAngles,_metadata = metadata;
  factory _ExerciseAngleCoverage.fromJson(Map<String, dynamic> json) => _$ExerciseAngleCoverageFromJson(json);

/// Identificación
@override final  String userId;
@override final  String muscle;
@override final  int weekNumber;
@override final  String cycleId;
// ID del ciclo (macrocycle/mesocycle)
/// Ángulos/planos usados ESTA SEMANA
/// Map: angleKey (ej: 'horizontal', 'vertical', 'incline')
///      -> List de exercise IDs que cubren ese ángulo
 final  Map<String, List<String>> _angleExerciseMap;
// ID del ciclo (macrocycle/mesocycle)
/// Ángulos/planos usados ESTA SEMANA
/// Map: angleKey (ej: 'horizontal', 'vertical', 'incline')
///      -> List de exercise IDs que cubren ese ángulo
@override Map<String, List<String>> get angleExerciseMap {
  if (_angleExerciseMap is EqualUnmodifiableMapView) return _angleExerciseMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_angleExerciseMap);
}

/// Cobertura general (qué porcentaje de ángulos se cubrieron)
/// 0.0 = ningún ángulo, 1.0 = todos los ángulos
@override final  double coverageRatio;
/// Ángulos identificados para este músculo
 final  List<String> _knownAngles;
/// Ángulos identificados para este músculo
@override@JsonKey() List<String> get knownAngles {
  if (_knownAngles is EqualUnmodifiableListView) return _knownAngles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownAngles);
}

// 'horizontal', 'vertical', 'incline', etc.
/// Ángulos cubiertos esta semana
 final  List<String> _coveredAngles;
// 'horizontal', 'vertical', 'incline', etc.
/// Ángulos cubiertos esta semana
@override@JsonKey() List<String> get coveredAngles {
  if (_coveredAngles is EqualUnmodifiableListView) return _coveredAngles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coveredAngles);
}

/// Ángulos NO cubiertos (auditoría)
 final  List<String> _missingAngles;
/// Ángulos NO cubiertos (auditoría)
@override@JsonKey() List<String> get missingAngles {
  if (_missingAngles is EqualUnmodifiableListView) return _missingAngles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missingAngles);
}

/// Variedad: ¿Cambió con respecto a semana anterior?
@override final  bool changedFromLastWeek;
// ¿Usamos ángulos diferentes?
/// Timestamp
@override final  DateTime recordedAt;
/// Metadata
 final  Map<String, dynamic> _metadata;
/// Metadata
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ExerciseAngleCoverage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseAngleCoverageCopyWith<_ExerciseAngleCoverage> get copyWith => __$ExerciseAngleCoverageCopyWithImpl<_ExerciseAngleCoverage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseAngleCoverageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseAngleCoverage&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.muscle, muscle) || other.muscle == muscle)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.cycleId, cycleId) || other.cycleId == cycleId)&&const DeepCollectionEquality().equals(other._angleExerciseMap, _angleExerciseMap)&&(identical(other.coverageRatio, coverageRatio) || other.coverageRatio == coverageRatio)&&const DeepCollectionEquality().equals(other._knownAngles, _knownAngles)&&const DeepCollectionEquality().equals(other._coveredAngles, _coveredAngles)&&const DeepCollectionEquality().equals(other._missingAngles, _missingAngles)&&(identical(other.changedFromLastWeek, changedFromLastWeek) || other.changedFromLastWeek == changedFromLastWeek)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,muscle,weekNumber,cycleId,const DeepCollectionEquality().hash(_angleExerciseMap),coverageRatio,const DeepCollectionEquality().hash(_knownAngles),const DeepCollectionEquality().hash(_coveredAngles),const DeepCollectionEquality().hash(_missingAngles),changedFromLastWeek,recordedAt,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ExerciseAngleCoverage(userId: $userId, muscle: $muscle, weekNumber: $weekNumber, cycleId: $cycleId, angleExerciseMap: $angleExerciseMap, coverageRatio: $coverageRatio, knownAngles: $knownAngles, coveredAngles: $coveredAngles, missingAngles: $missingAngles, changedFromLastWeek: $changedFromLastWeek, recordedAt: $recordedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ExerciseAngleCoverageCopyWith<$Res> implements $ExerciseAngleCoverageCopyWith<$Res> {
  factory _$ExerciseAngleCoverageCopyWith(_ExerciseAngleCoverage value, $Res Function(_ExerciseAngleCoverage) _then) = __$ExerciseAngleCoverageCopyWithImpl;
@override @useResult
$Res call({
 String userId, String muscle, int weekNumber, String cycleId, Map<String, List<String>> angleExerciseMap, double coverageRatio, List<String> knownAngles, List<String> coveredAngles, List<String> missingAngles, bool changedFromLastWeek, DateTime recordedAt, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$ExerciseAngleCoverageCopyWithImpl<$Res>
    implements _$ExerciseAngleCoverageCopyWith<$Res> {
  __$ExerciseAngleCoverageCopyWithImpl(this._self, this._then);

  final _ExerciseAngleCoverage _self;
  final $Res Function(_ExerciseAngleCoverage) _then;

/// Create a copy of ExerciseAngleCoverage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? muscle = null,Object? weekNumber = null,Object? cycleId = null,Object? angleExerciseMap = null,Object? coverageRatio = null,Object? knownAngles = null,Object? coveredAngles = null,Object? missingAngles = null,Object? changedFromLastWeek = null,Object? recordedAt = null,Object? metadata = null,}) {
  return _then(_ExerciseAngleCoverage(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,muscle: null == muscle ? _self.muscle : muscle // ignore: cast_nullable_to_non_nullable
as String,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,cycleId: null == cycleId ? _self.cycleId : cycleId // ignore: cast_nullable_to_non_nullable
as String,angleExerciseMap: null == angleExerciseMap ? _self._angleExerciseMap : angleExerciseMap // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,coverageRatio: null == coverageRatio ? _self.coverageRatio : coverageRatio // ignore: cast_nullable_to_non_nullable
as double,knownAngles: null == knownAngles ? _self._knownAngles : knownAngles // ignore: cast_nullable_to_non_nullable
as List<String>,coveredAngles: null == coveredAngles ? _self._coveredAngles : coveredAngles // ignore: cast_nullable_to_non_nullable
as List<String>,missingAngles: null == missingAngles ? _self._missingAngles : missingAngles // ignore: cast_nullable_to_non_nullable
as List<String>,changedFromLastWeek: null == changedFromLastWeek ? _self.changedFromLastWeek : changedFromLastWeek // ignore: cast_nullable_to_non_nullable
as bool,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
