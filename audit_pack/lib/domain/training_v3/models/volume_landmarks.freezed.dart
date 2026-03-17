// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'volume_landmarks.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VolumeLandmarks {

 int get vme; int get vop; int get vmr; int get vmrTarget;
/// Create a copy of VolumeLandmarks
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VolumeLandmarksCopyWith<VolumeLandmarks> get copyWith => _$VolumeLandmarksCopyWithImpl<VolumeLandmarks>(this as VolumeLandmarks, _$identity);

  /// Serializes this VolumeLandmarks to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VolumeLandmarks&&(identical(other.vme, vme) || other.vme == vme)&&(identical(other.vop, vop) || other.vop == vop)&&(identical(other.vmr, vmr) || other.vmr == vmr)&&(identical(other.vmrTarget, vmrTarget) || other.vmrTarget == vmrTarget));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vme,vop,vmr,vmrTarget);

@override
String toString() {
  return 'VolumeLandmarks(vme: $vme, vop: $vop, vmr: $vmr, vmrTarget: $vmrTarget)';
}


}

/// @nodoc
abstract mixin class $VolumeLandmarksCopyWith<$Res>  {
  factory $VolumeLandmarksCopyWith(VolumeLandmarks value, $Res Function(VolumeLandmarks) _then) = _$VolumeLandmarksCopyWithImpl;
@useResult
$Res call({
 int vme, int vop, int vmr, int vmrTarget
});




}
/// @nodoc
class _$VolumeLandmarksCopyWithImpl<$Res>
    implements $VolumeLandmarksCopyWith<$Res> {
  _$VolumeLandmarksCopyWithImpl(this._self, this._then);

  final VolumeLandmarks _self;
  final $Res Function(VolumeLandmarks) _then;

/// Create a copy of VolumeLandmarks
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vme = null,Object? vop = null,Object? vmr = null,Object? vmrTarget = null,}) {
  return _then(_self.copyWith(
vme: null == vme ? _self.vme : vme // ignore: cast_nullable_to_non_nullable
as int,vop: null == vop ? _self.vop : vop // ignore: cast_nullable_to_non_nullable
as int,vmr: null == vmr ? _self.vmr : vmr // ignore: cast_nullable_to_non_nullable
as int,vmrTarget: null == vmrTarget ? _self.vmrTarget : vmrTarget // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VolumeLandmarks].
extension VolumeLandmarksPatterns on VolumeLandmarks {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VolumeLandmarks value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VolumeLandmarks() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VolumeLandmarks value)  $default,){
final _that = this;
switch (_that) {
case _VolumeLandmarks():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VolumeLandmarks value)?  $default,){
final _that = this;
switch (_that) {
case _VolumeLandmarks() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int vme,  int vop,  int vmr,  int vmrTarget)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VolumeLandmarks() when $default != null:
return $default(_that.vme,_that.vop,_that.vmr,_that.vmrTarget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int vme,  int vop,  int vmr,  int vmrTarget)  $default,) {final _that = this;
switch (_that) {
case _VolumeLandmarks():
return $default(_that.vme,_that.vop,_that.vmr,_that.vmrTarget);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int vme,  int vop,  int vmr,  int vmrTarget)?  $default,) {final _that = this;
switch (_that) {
case _VolumeLandmarks() when $default != null:
return $default(_that.vme,_that.vop,_that.vmr,_that.vmrTarget);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VolumeLandmarks implements VolumeLandmarks {
  const _VolumeLandmarks({required this.vme, required this.vop, required this.vmr, required this.vmrTarget});
  factory _VolumeLandmarks.fromJson(Map<String, dynamic> json) => _$VolumeLandmarksFromJson(json);

@override final  int vme;
@override final  int vop;
@override final  int vmr;
@override final  int vmrTarget;

/// Create a copy of VolumeLandmarks
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VolumeLandmarksCopyWith<_VolumeLandmarks> get copyWith => __$VolumeLandmarksCopyWithImpl<_VolumeLandmarks>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VolumeLandmarksToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VolumeLandmarks&&(identical(other.vme, vme) || other.vme == vme)&&(identical(other.vop, vop) || other.vop == vop)&&(identical(other.vmr, vmr) || other.vmr == vmr)&&(identical(other.vmrTarget, vmrTarget) || other.vmrTarget == vmrTarget));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vme,vop,vmr,vmrTarget);

@override
String toString() {
  return 'VolumeLandmarks(vme: $vme, vop: $vop, vmr: $vmr, vmrTarget: $vmrTarget)';
}


}

/// @nodoc
abstract mixin class _$VolumeLandmarksCopyWith<$Res> implements $VolumeLandmarksCopyWith<$Res> {
  factory _$VolumeLandmarksCopyWith(_VolumeLandmarks value, $Res Function(_VolumeLandmarks) _then) = __$VolumeLandmarksCopyWithImpl;
@override @useResult
$Res call({
 int vme, int vop, int vmr, int vmrTarget
});




}
/// @nodoc
class __$VolumeLandmarksCopyWithImpl<$Res>
    implements _$VolumeLandmarksCopyWith<$Res> {
  __$VolumeLandmarksCopyWithImpl(this._self, this._then);

  final _VolumeLandmarks _self;
  final $Res Function(_VolumeLandmarks) _then;

/// Create a copy of VolumeLandmarks
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vme = null,Object? vop = null,Object? vmr = null,Object? vmrTarget = null,}) {
  return _then(_VolumeLandmarks(
vme: null == vme ? _self.vme : vme // ignore: cast_nullable_to_non_nullable
as int,vop: null == vop ? _self.vop : vop // ignore: cast_nullable_to_non_nullable
as int,vmr: null == vmr ? _self.vmr : vmr // ignore: cast_nullable_to_non_nullable
as int,vmrTarget: null == vmrTarget ? _self.vmrTarget : vmrTarget // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
