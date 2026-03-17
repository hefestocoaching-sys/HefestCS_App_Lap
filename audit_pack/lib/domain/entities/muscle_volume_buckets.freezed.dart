// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'muscle_volume_buckets.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MuscleVolumeBuckets {

 double get heavySets; double get mediumSets; double get lightSets;
/// Create a copy of MuscleVolumeBuckets
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MuscleVolumeBucketsCopyWith<MuscleVolumeBuckets> get copyWith => _$MuscleVolumeBucketsCopyWithImpl<MuscleVolumeBuckets>(this as MuscleVolumeBuckets, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MuscleVolumeBuckets&&(identical(other.heavySets, heavySets) || other.heavySets == heavySets)&&(identical(other.mediumSets, mediumSets) || other.mediumSets == mediumSets)&&(identical(other.lightSets, lightSets) || other.lightSets == lightSets));
}


@override
int get hashCode => Object.hash(runtimeType,heavySets,mediumSets,lightSets);

@override
String toString() {
  return 'MuscleVolumeBuckets(heavySets: $heavySets, mediumSets: $mediumSets, lightSets: $lightSets)';
}


}

/// @nodoc
abstract mixin class $MuscleVolumeBucketsCopyWith<$Res>  {
  factory $MuscleVolumeBucketsCopyWith(MuscleVolumeBuckets value, $Res Function(MuscleVolumeBuckets) _then) = _$MuscleVolumeBucketsCopyWithImpl;
@useResult
$Res call({
 double heavySets, double mediumSets, double lightSets
});




}
/// @nodoc
class _$MuscleVolumeBucketsCopyWithImpl<$Res>
    implements $MuscleVolumeBucketsCopyWith<$Res> {
  _$MuscleVolumeBucketsCopyWithImpl(this._self, this._then);

  final MuscleVolumeBuckets _self;
  final $Res Function(MuscleVolumeBuckets) _then;

/// Create a copy of MuscleVolumeBuckets
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? heavySets = null,Object? mediumSets = null,Object? lightSets = null,}) {
  return _then(_self.copyWith(
heavySets: null == heavySets ? _self.heavySets : heavySets // ignore: cast_nullable_to_non_nullable
as double,mediumSets: null == mediumSets ? _self.mediumSets : mediumSets // ignore: cast_nullable_to_non_nullable
as double,lightSets: null == lightSets ? _self.lightSets : lightSets // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MuscleVolumeBuckets].
extension MuscleVolumeBucketsPatterns on MuscleVolumeBuckets {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MuscleVolumeBuckets value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MuscleVolumeBuckets() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MuscleVolumeBuckets value)  $default,){
final _that = this;
switch (_that) {
case _MuscleVolumeBuckets():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MuscleVolumeBuckets value)?  $default,){
final _that = this;
switch (_that) {
case _MuscleVolumeBuckets() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double heavySets,  double mediumSets,  double lightSets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MuscleVolumeBuckets() when $default != null:
return $default(_that.heavySets,_that.mediumSets,_that.lightSets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double heavySets,  double mediumSets,  double lightSets)  $default,) {final _that = this;
switch (_that) {
case _MuscleVolumeBuckets():
return $default(_that.heavySets,_that.mediumSets,_that.lightSets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double heavySets,  double mediumSets,  double lightSets)?  $default,) {final _that = this;
switch (_that) {
case _MuscleVolumeBuckets() when $default != null:
return $default(_that.heavySets,_that.mediumSets,_that.lightSets);case _:
  return null;

}
}

}

/// @nodoc


class _MuscleVolumeBuckets implements MuscleVolumeBuckets {
  const _MuscleVolumeBuckets({required this.heavySets, required this.mediumSets, required this.lightSets});
  

@override final  double heavySets;
@override final  double mediumSets;
@override final  double lightSets;

/// Create a copy of MuscleVolumeBuckets
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MuscleVolumeBucketsCopyWith<_MuscleVolumeBuckets> get copyWith => __$MuscleVolumeBucketsCopyWithImpl<_MuscleVolumeBuckets>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MuscleVolumeBuckets&&(identical(other.heavySets, heavySets) || other.heavySets == heavySets)&&(identical(other.mediumSets, mediumSets) || other.mediumSets == mediumSets)&&(identical(other.lightSets, lightSets) || other.lightSets == lightSets));
}


@override
int get hashCode => Object.hash(runtimeType,heavySets,mediumSets,lightSets);

@override
String toString() {
  return 'MuscleVolumeBuckets(heavySets: $heavySets, mediumSets: $mediumSets, lightSets: $lightSets)';
}


}

/// @nodoc
abstract mixin class _$MuscleVolumeBucketsCopyWith<$Res> implements $MuscleVolumeBucketsCopyWith<$Res> {
  factory _$MuscleVolumeBucketsCopyWith(_MuscleVolumeBuckets value, $Res Function(_MuscleVolumeBuckets) _then) = __$MuscleVolumeBucketsCopyWithImpl;
@override @useResult
$Res call({
 double heavySets, double mediumSets, double lightSets
});




}
/// @nodoc
class __$MuscleVolumeBucketsCopyWithImpl<$Res>
    implements _$MuscleVolumeBucketsCopyWith<$Res> {
  __$MuscleVolumeBucketsCopyWithImpl(this._self, this._then);

  final _MuscleVolumeBuckets _self;
  final $Res Function(_MuscleVolumeBuckets) _then;

/// Create a copy of MuscleVolumeBuckets
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? heavySets = null,Object? mediumSets = null,Object? lightSets = null,}) {
  return _then(_MuscleVolumeBuckets(
heavySets: null == heavySets ? _self.heavySets : heavySets // ignore: cast_nullable_to_non_nullable
as double,mediumSets: null == mediumSets ? _self.mediumSets : mediumSets // ignore: cast_nullable_to_non_nullable
as double,lightSets: null == lightSets ? _self.lightSets : lightSets // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
