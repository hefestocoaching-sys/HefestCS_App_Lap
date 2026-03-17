// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dietary_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DietaryState implements DiagnosticableTreeMixin {

 String get selectedTMBFormulaKey; Map<String, TMBFormulaInfo> get tmbCalculations; double get calculatedAverageTMB; Map<String, List<UserActivity>> get dailyActivities; Map<String, double> get dailyNafFactors; double get finalKcal; double get leanBodyMass; double get bodyFatPercentage; bool get isObese; bool get hasLBM;
/// Create a copy of DietaryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DietaryStateCopyWith<DietaryState> get copyWith => _$DietaryStateCopyWithImpl<DietaryState>(this as DietaryState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'DietaryState'))
    ..add(DiagnosticsProperty('selectedTMBFormulaKey', selectedTMBFormulaKey))..add(DiagnosticsProperty('tmbCalculations', tmbCalculations))..add(DiagnosticsProperty('calculatedAverageTMB', calculatedAverageTMB))..add(DiagnosticsProperty('dailyActivities', dailyActivities))..add(DiagnosticsProperty('dailyNafFactors', dailyNafFactors))..add(DiagnosticsProperty('finalKcal', finalKcal))..add(DiagnosticsProperty('leanBodyMass', leanBodyMass))..add(DiagnosticsProperty('bodyFatPercentage', bodyFatPercentage))..add(DiagnosticsProperty('isObese', isObese))..add(DiagnosticsProperty('hasLBM', hasLBM));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DietaryState&&(identical(other.selectedTMBFormulaKey, selectedTMBFormulaKey) || other.selectedTMBFormulaKey == selectedTMBFormulaKey)&&const DeepCollectionEquality().equals(other.tmbCalculations, tmbCalculations)&&(identical(other.calculatedAverageTMB, calculatedAverageTMB) || other.calculatedAverageTMB == calculatedAverageTMB)&&const DeepCollectionEquality().equals(other.dailyActivities, dailyActivities)&&const DeepCollectionEquality().equals(other.dailyNafFactors, dailyNafFactors)&&(identical(other.finalKcal, finalKcal) || other.finalKcal == finalKcal)&&(identical(other.leanBodyMass, leanBodyMass) || other.leanBodyMass == leanBodyMass)&&(identical(other.bodyFatPercentage, bodyFatPercentage) || other.bodyFatPercentage == bodyFatPercentage)&&(identical(other.isObese, isObese) || other.isObese == isObese)&&(identical(other.hasLBM, hasLBM) || other.hasLBM == hasLBM));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTMBFormulaKey,const DeepCollectionEquality().hash(tmbCalculations),calculatedAverageTMB,const DeepCollectionEquality().hash(dailyActivities),const DeepCollectionEquality().hash(dailyNafFactors),finalKcal,leanBodyMass,bodyFatPercentage,isObese,hasLBM);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'DietaryState(selectedTMBFormulaKey: $selectedTMBFormulaKey, tmbCalculations: $tmbCalculations, calculatedAverageTMB: $calculatedAverageTMB, dailyActivities: $dailyActivities, dailyNafFactors: $dailyNafFactors, finalKcal: $finalKcal, leanBodyMass: $leanBodyMass, bodyFatPercentage: $bodyFatPercentage, isObese: $isObese, hasLBM: $hasLBM)';
}


}

/// @nodoc
abstract mixin class $DietaryStateCopyWith<$Res>  {
  factory $DietaryStateCopyWith(DietaryState value, $Res Function(DietaryState) _then) = _$DietaryStateCopyWithImpl;
@useResult
$Res call({
 String selectedTMBFormulaKey, Map<String, TMBFormulaInfo> tmbCalculations, double calculatedAverageTMB, Map<String, List<UserActivity>> dailyActivities, Map<String, double> dailyNafFactors, double finalKcal, double leanBodyMass, double bodyFatPercentage, bool isObese, bool hasLBM
});




}
/// @nodoc
class _$DietaryStateCopyWithImpl<$Res>
    implements $DietaryStateCopyWith<$Res> {
  _$DietaryStateCopyWithImpl(this._self, this._then);

  final DietaryState _self;
  final $Res Function(DietaryState) _then;

/// Create a copy of DietaryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedTMBFormulaKey = null,Object? tmbCalculations = null,Object? calculatedAverageTMB = null,Object? dailyActivities = null,Object? dailyNafFactors = null,Object? finalKcal = null,Object? leanBodyMass = null,Object? bodyFatPercentage = null,Object? isObese = null,Object? hasLBM = null,}) {
  return _then(_self.copyWith(
selectedTMBFormulaKey: null == selectedTMBFormulaKey ? _self.selectedTMBFormulaKey : selectedTMBFormulaKey // ignore: cast_nullable_to_non_nullable
as String,tmbCalculations: null == tmbCalculations ? _self.tmbCalculations : tmbCalculations // ignore: cast_nullable_to_non_nullable
as Map<String, TMBFormulaInfo>,calculatedAverageTMB: null == calculatedAverageTMB ? _self.calculatedAverageTMB : calculatedAverageTMB // ignore: cast_nullable_to_non_nullable
as double,dailyActivities: null == dailyActivities ? _self.dailyActivities : dailyActivities // ignore: cast_nullable_to_non_nullable
as Map<String, List<UserActivity>>,dailyNafFactors: null == dailyNafFactors ? _self.dailyNafFactors : dailyNafFactors // ignore: cast_nullable_to_non_nullable
as Map<String, double>,finalKcal: null == finalKcal ? _self.finalKcal : finalKcal // ignore: cast_nullable_to_non_nullable
as double,leanBodyMass: null == leanBodyMass ? _self.leanBodyMass : leanBodyMass // ignore: cast_nullable_to_non_nullable
as double,bodyFatPercentage: null == bodyFatPercentage ? _self.bodyFatPercentage : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
as double,isObese: null == isObese ? _self.isObese : isObese // ignore: cast_nullable_to_non_nullable
as bool,hasLBM: null == hasLBM ? _self.hasLBM : hasLBM // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DietaryState].
extension DietaryStatePatterns on DietaryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DietaryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DietaryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DietaryState value)  $default,){
final _that = this;
switch (_that) {
case _DietaryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DietaryState value)?  $default,){
final _that = this;
switch (_that) {
case _DietaryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String selectedTMBFormulaKey,  Map<String, TMBFormulaInfo> tmbCalculations,  double calculatedAverageTMB,  Map<String, List<UserActivity>> dailyActivities,  Map<String, double> dailyNafFactors,  double finalKcal,  double leanBodyMass,  double bodyFatPercentage,  bool isObese,  bool hasLBM)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DietaryState() when $default != null:
return $default(_that.selectedTMBFormulaKey,_that.tmbCalculations,_that.calculatedAverageTMB,_that.dailyActivities,_that.dailyNafFactors,_that.finalKcal,_that.leanBodyMass,_that.bodyFatPercentage,_that.isObese,_that.hasLBM);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String selectedTMBFormulaKey,  Map<String, TMBFormulaInfo> tmbCalculations,  double calculatedAverageTMB,  Map<String, List<UserActivity>> dailyActivities,  Map<String, double> dailyNafFactors,  double finalKcal,  double leanBodyMass,  double bodyFatPercentage,  bool isObese,  bool hasLBM)  $default,) {final _that = this;
switch (_that) {
case _DietaryState():
return $default(_that.selectedTMBFormulaKey,_that.tmbCalculations,_that.calculatedAverageTMB,_that.dailyActivities,_that.dailyNafFactors,_that.finalKcal,_that.leanBodyMass,_that.bodyFatPercentage,_that.isObese,_that.hasLBM);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String selectedTMBFormulaKey,  Map<String, TMBFormulaInfo> tmbCalculations,  double calculatedAverageTMB,  Map<String, List<UserActivity>> dailyActivities,  Map<String, double> dailyNafFactors,  double finalKcal,  double leanBodyMass,  double bodyFatPercentage,  bool isObese,  bool hasLBM)?  $default,) {final _that = this;
switch (_that) {
case _DietaryState() when $default != null:
return $default(_that.selectedTMBFormulaKey,_that.tmbCalculations,_that.calculatedAverageTMB,_that.dailyActivities,_that.dailyNafFactors,_that.finalKcal,_that.leanBodyMass,_that.bodyFatPercentage,_that.isObese,_that.hasLBM);case _:
  return null;

}
}

}

/// @nodoc


class _DietaryState with DiagnosticableTreeMixin implements DietaryState {
  const _DietaryState({this.selectedTMBFormulaKey = 'Mifflin-St. Jeor', final  Map<String, TMBFormulaInfo> tmbCalculations = const {}, this.calculatedAverageTMB = 0.0, final  Map<String, List<UserActivity>> dailyActivities = const {}, final  Map<String, double> dailyNafFactors = const {}, this.finalKcal = 0.0, this.leanBodyMass = 0.0, this.bodyFatPercentage = 0.0, this.isObese = false, this.hasLBM = false}): _tmbCalculations = tmbCalculations,_dailyActivities = dailyActivities,_dailyNafFactors = dailyNafFactors;
  

@override@JsonKey() final  String selectedTMBFormulaKey;
 final  Map<String, TMBFormulaInfo> _tmbCalculations;
@override@JsonKey() Map<String, TMBFormulaInfo> get tmbCalculations {
  if (_tmbCalculations is EqualUnmodifiableMapView) return _tmbCalculations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tmbCalculations);
}

@override@JsonKey() final  double calculatedAverageTMB;
 final  Map<String, List<UserActivity>> _dailyActivities;
@override@JsonKey() Map<String, List<UserActivity>> get dailyActivities {
  if (_dailyActivities is EqualUnmodifiableMapView) return _dailyActivities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dailyActivities);
}

 final  Map<String, double> _dailyNafFactors;
@override@JsonKey() Map<String, double> get dailyNafFactors {
  if (_dailyNafFactors is EqualUnmodifiableMapView) return _dailyNafFactors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dailyNafFactors);
}

@override@JsonKey() final  double finalKcal;
@override@JsonKey() final  double leanBodyMass;
@override@JsonKey() final  double bodyFatPercentage;
@override@JsonKey() final  bool isObese;
@override@JsonKey() final  bool hasLBM;

/// Create a copy of DietaryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DietaryStateCopyWith<_DietaryState> get copyWith => __$DietaryStateCopyWithImpl<_DietaryState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'DietaryState'))
    ..add(DiagnosticsProperty('selectedTMBFormulaKey', selectedTMBFormulaKey))..add(DiagnosticsProperty('tmbCalculations', tmbCalculations))..add(DiagnosticsProperty('calculatedAverageTMB', calculatedAverageTMB))..add(DiagnosticsProperty('dailyActivities', dailyActivities))..add(DiagnosticsProperty('dailyNafFactors', dailyNafFactors))..add(DiagnosticsProperty('finalKcal', finalKcal))..add(DiagnosticsProperty('leanBodyMass', leanBodyMass))..add(DiagnosticsProperty('bodyFatPercentage', bodyFatPercentage))..add(DiagnosticsProperty('isObese', isObese))..add(DiagnosticsProperty('hasLBM', hasLBM));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DietaryState&&(identical(other.selectedTMBFormulaKey, selectedTMBFormulaKey) || other.selectedTMBFormulaKey == selectedTMBFormulaKey)&&const DeepCollectionEquality().equals(other._tmbCalculations, _tmbCalculations)&&(identical(other.calculatedAverageTMB, calculatedAverageTMB) || other.calculatedAverageTMB == calculatedAverageTMB)&&const DeepCollectionEquality().equals(other._dailyActivities, _dailyActivities)&&const DeepCollectionEquality().equals(other._dailyNafFactors, _dailyNafFactors)&&(identical(other.finalKcal, finalKcal) || other.finalKcal == finalKcal)&&(identical(other.leanBodyMass, leanBodyMass) || other.leanBodyMass == leanBodyMass)&&(identical(other.bodyFatPercentage, bodyFatPercentage) || other.bodyFatPercentage == bodyFatPercentage)&&(identical(other.isObese, isObese) || other.isObese == isObese)&&(identical(other.hasLBM, hasLBM) || other.hasLBM == hasLBM));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTMBFormulaKey,const DeepCollectionEquality().hash(_tmbCalculations),calculatedAverageTMB,const DeepCollectionEquality().hash(_dailyActivities),const DeepCollectionEquality().hash(_dailyNafFactors),finalKcal,leanBodyMass,bodyFatPercentage,isObese,hasLBM);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'DietaryState(selectedTMBFormulaKey: $selectedTMBFormulaKey, tmbCalculations: $tmbCalculations, calculatedAverageTMB: $calculatedAverageTMB, dailyActivities: $dailyActivities, dailyNafFactors: $dailyNafFactors, finalKcal: $finalKcal, leanBodyMass: $leanBodyMass, bodyFatPercentage: $bodyFatPercentage, isObese: $isObese, hasLBM: $hasLBM)';
}


}

/// @nodoc
abstract mixin class _$DietaryStateCopyWith<$Res> implements $DietaryStateCopyWith<$Res> {
  factory _$DietaryStateCopyWith(_DietaryState value, $Res Function(_DietaryState) _then) = __$DietaryStateCopyWithImpl;
@override @useResult
$Res call({
 String selectedTMBFormulaKey, Map<String, TMBFormulaInfo> tmbCalculations, double calculatedAverageTMB, Map<String, List<UserActivity>> dailyActivities, Map<String, double> dailyNafFactors, double finalKcal, double leanBodyMass, double bodyFatPercentage, bool isObese, bool hasLBM
});




}
/// @nodoc
class __$DietaryStateCopyWithImpl<$Res>
    implements _$DietaryStateCopyWith<$Res> {
  __$DietaryStateCopyWithImpl(this._self, this._then);

  final _DietaryState _self;
  final $Res Function(_DietaryState) _then;

/// Create a copy of DietaryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedTMBFormulaKey = null,Object? tmbCalculations = null,Object? calculatedAverageTMB = null,Object? dailyActivities = null,Object? dailyNafFactors = null,Object? finalKcal = null,Object? leanBodyMass = null,Object? bodyFatPercentage = null,Object? isObese = null,Object? hasLBM = null,}) {
  return _then(_DietaryState(
selectedTMBFormulaKey: null == selectedTMBFormulaKey ? _self.selectedTMBFormulaKey : selectedTMBFormulaKey // ignore: cast_nullable_to_non_nullable
as String,tmbCalculations: null == tmbCalculations ? _self._tmbCalculations : tmbCalculations // ignore: cast_nullable_to_non_nullable
as Map<String, TMBFormulaInfo>,calculatedAverageTMB: null == calculatedAverageTMB ? _self.calculatedAverageTMB : calculatedAverageTMB // ignore: cast_nullable_to_non_nullable
as double,dailyActivities: null == dailyActivities ? _self._dailyActivities : dailyActivities // ignore: cast_nullable_to_non_nullable
as Map<String, List<UserActivity>>,dailyNafFactors: null == dailyNafFactors ? _self._dailyNafFactors : dailyNafFactors // ignore: cast_nullable_to_non_nullable
as Map<String, double>,finalKcal: null == finalKcal ? _self.finalKcal : finalKcal // ignore: cast_nullable_to_non_nullable
as double,leanBodyMass: null == leanBodyMass ? _self.leanBodyMass : leanBodyMass // ignore: cast_nullable_to_non_nullable
as double,bodyFatPercentage: null == bodyFatPercentage ? _self.bodyFatPercentage : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
as double,isObese: null == isObese ? _self.isObese : isObese // ignore: cast_nullable_to_non_nullable
as bool,hasLBM: null == hasLBM ? _self.hasLBM : hasLBM // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
