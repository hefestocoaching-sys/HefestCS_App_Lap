// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_audit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrainingAuditLogEntry {

/// Identificadores
 String get userId; String get eventType;// Ver enum abajo
 String? get muscleAffected;// null si es a nivel usuario
 int get weekNumber;/// QUÉ pasó
 String get title;// Título breve del evento
 String get description;// Descripción detallada
 String get severity;// 'info', 'warning', 'error', 'critical'
/// DATOS de la decisión
 int? get volumeBefore;// Volumen anterior
 int? get volumeAfter;// Volumen nuevo
 String? get decisionReason;// Por qué se tomó
 String? get feedbackContext;// Contexto de feedback que llevó a esto
/// QUIÉN lo hizo
 String get actorType;// 'motor'|'user'|'system'|'coach'
 String get actorDetails;// ID del coach si aplica, versión del motor, etc.
/// Validación
 bool get isValid;// ¿Pasó validación?
 List<String> get validationErrors;// Errores de validación si aplica
/// Metadata
 DateTime get timestamp; Map<String, dynamic> get metadata;// Datos extras (lineage, calculations, etc.)
/// Linkage a otros registros
 String? get linkedToProgressRecordId;// ID de ProgressRecord si aplica
 String? get linkedToFeedbackEntryId;// ID de FeedbackEntry si aplica
 String? get linkedToPreviousLogId;
/// Create a copy of TrainingAuditLogEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingAuditLogEntryCopyWith<TrainingAuditLogEntry> get copyWith => _$TrainingAuditLogEntryCopyWithImpl<TrainingAuditLogEntry>(this as TrainingAuditLogEntry, _$identity);

  /// Serializes this TrainingAuditLogEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingAuditLogEntry&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.muscleAffected, muscleAffected) || other.muscleAffected == muscleAffected)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.volumeBefore, volumeBefore) || other.volumeBefore == volumeBefore)&&(identical(other.volumeAfter, volumeAfter) || other.volumeAfter == volumeAfter)&&(identical(other.decisionReason, decisionReason) || other.decisionReason == decisionReason)&&(identical(other.feedbackContext, feedbackContext) || other.feedbackContext == feedbackContext)&&(identical(other.actorType, actorType) || other.actorType == actorType)&&(identical(other.actorDetails, actorDetails) || other.actorDetails == actorDetails)&&(identical(other.isValid, isValid) || other.isValid == isValid)&&const DeepCollectionEquality().equals(other.validationErrors, validationErrors)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.linkedToProgressRecordId, linkedToProgressRecordId) || other.linkedToProgressRecordId == linkedToProgressRecordId)&&(identical(other.linkedToFeedbackEntryId, linkedToFeedbackEntryId) || other.linkedToFeedbackEntryId == linkedToFeedbackEntryId)&&(identical(other.linkedToPreviousLogId, linkedToPreviousLogId) || other.linkedToPreviousLogId == linkedToPreviousLogId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,eventType,muscleAffected,weekNumber,title,description,severity,volumeBefore,volumeAfter,decisionReason,feedbackContext,actorType,actorDetails,isValid,const DeepCollectionEquality().hash(validationErrors),timestamp,const DeepCollectionEquality().hash(metadata),linkedToProgressRecordId,linkedToFeedbackEntryId,linkedToPreviousLogId]);

@override
String toString() {
  return 'TrainingAuditLogEntry(userId: $userId, eventType: $eventType, muscleAffected: $muscleAffected, weekNumber: $weekNumber, title: $title, description: $description, severity: $severity, volumeBefore: $volumeBefore, volumeAfter: $volumeAfter, decisionReason: $decisionReason, feedbackContext: $feedbackContext, actorType: $actorType, actorDetails: $actorDetails, isValid: $isValid, validationErrors: $validationErrors, timestamp: $timestamp, metadata: $metadata, linkedToProgressRecordId: $linkedToProgressRecordId, linkedToFeedbackEntryId: $linkedToFeedbackEntryId, linkedToPreviousLogId: $linkedToPreviousLogId)';
}


}

/// @nodoc
abstract mixin class $TrainingAuditLogEntryCopyWith<$Res>  {
  factory $TrainingAuditLogEntryCopyWith(TrainingAuditLogEntry value, $Res Function(TrainingAuditLogEntry) _then) = _$TrainingAuditLogEntryCopyWithImpl;
@useResult
$Res call({
 String userId, String eventType, String? muscleAffected, int weekNumber, String title, String description, String severity, int? volumeBefore, int? volumeAfter, String? decisionReason, String? feedbackContext, String actorType, String actorDetails, bool isValid, List<String> validationErrors, DateTime timestamp, Map<String, dynamic> metadata, String? linkedToProgressRecordId, String? linkedToFeedbackEntryId, String? linkedToPreviousLogId
});




}
/// @nodoc
class _$TrainingAuditLogEntryCopyWithImpl<$Res>
    implements $TrainingAuditLogEntryCopyWith<$Res> {
  _$TrainingAuditLogEntryCopyWithImpl(this._self, this._then);

  final TrainingAuditLogEntry _self;
  final $Res Function(TrainingAuditLogEntry) _then;

/// Create a copy of TrainingAuditLogEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? eventType = null,Object? muscleAffected = freezed,Object? weekNumber = null,Object? title = null,Object? description = null,Object? severity = null,Object? volumeBefore = freezed,Object? volumeAfter = freezed,Object? decisionReason = freezed,Object? feedbackContext = freezed,Object? actorType = null,Object? actorDetails = null,Object? isValid = null,Object? validationErrors = null,Object? timestamp = null,Object? metadata = null,Object? linkedToProgressRecordId = freezed,Object? linkedToFeedbackEntryId = freezed,Object? linkedToPreviousLogId = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,muscleAffected: freezed == muscleAffected ? _self.muscleAffected : muscleAffected // ignore: cast_nullable_to_non_nullable
as String?,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,volumeBefore: freezed == volumeBefore ? _self.volumeBefore : volumeBefore // ignore: cast_nullable_to_non_nullable
as int?,volumeAfter: freezed == volumeAfter ? _self.volumeAfter : volumeAfter // ignore: cast_nullable_to_non_nullable
as int?,decisionReason: freezed == decisionReason ? _self.decisionReason : decisionReason // ignore: cast_nullable_to_non_nullable
as String?,feedbackContext: freezed == feedbackContext ? _self.feedbackContext : feedbackContext // ignore: cast_nullable_to_non_nullable
as String?,actorType: null == actorType ? _self.actorType : actorType // ignore: cast_nullable_to_non_nullable
as String,actorDetails: null == actorDetails ? _self.actorDetails : actorDetails // ignore: cast_nullable_to_non_nullable
as String,isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,validationErrors: null == validationErrors ? _self.validationErrors : validationErrors // ignore: cast_nullable_to_non_nullable
as List<String>,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,linkedToProgressRecordId: freezed == linkedToProgressRecordId ? _self.linkedToProgressRecordId : linkedToProgressRecordId // ignore: cast_nullable_to_non_nullable
as String?,linkedToFeedbackEntryId: freezed == linkedToFeedbackEntryId ? _self.linkedToFeedbackEntryId : linkedToFeedbackEntryId // ignore: cast_nullable_to_non_nullable
as String?,linkedToPreviousLogId: freezed == linkedToPreviousLogId ? _self.linkedToPreviousLogId : linkedToPreviousLogId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainingAuditLogEntry].
extension TrainingAuditLogEntryPatterns on TrainingAuditLogEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingAuditLogEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingAuditLogEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingAuditLogEntry value)  $default,){
final _that = this;
switch (_that) {
case _TrainingAuditLogEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingAuditLogEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingAuditLogEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String eventType,  String? muscleAffected,  int weekNumber,  String title,  String description,  String severity,  int? volumeBefore,  int? volumeAfter,  String? decisionReason,  String? feedbackContext,  String actorType,  String actorDetails,  bool isValid,  List<String> validationErrors,  DateTime timestamp,  Map<String, dynamic> metadata,  String? linkedToProgressRecordId,  String? linkedToFeedbackEntryId,  String? linkedToPreviousLogId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingAuditLogEntry() when $default != null:
return $default(_that.userId,_that.eventType,_that.muscleAffected,_that.weekNumber,_that.title,_that.description,_that.severity,_that.volumeBefore,_that.volumeAfter,_that.decisionReason,_that.feedbackContext,_that.actorType,_that.actorDetails,_that.isValid,_that.validationErrors,_that.timestamp,_that.metadata,_that.linkedToProgressRecordId,_that.linkedToFeedbackEntryId,_that.linkedToPreviousLogId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String eventType,  String? muscleAffected,  int weekNumber,  String title,  String description,  String severity,  int? volumeBefore,  int? volumeAfter,  String? decisionReason,  String? feedbackContext,  String actorType,  String actorDetails,  bool isValid,  List<String> validationErrors,  DateTime timestamp,  Map<String, dynamic> metadata,  String? linkedToProgressRecordId,  String? linkedToFeedbackEntryId,  String? linkedToPreviousLogId)  $default,) {final _that = this;
switch (_that) {
case _TrainingAuditLogEntry():
return $default(_that.userId,_that.eventType,_that.muscleAffected,_that.weekNumber,_that.title,_that.description,_that.severity,_that.volumeBefore,_that.volumeAfter,_that.decisionReason,_that.feedbackContext,_that.actorType,_that.actorDetails,_that.isValid,_that.validationErrors,_that.timestamp,_that.metadata,_that.linkedToProgressRecordId,_that.linkedToFeedbackEntryId,_that.linkedToPreviousLogId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String eventType,  String? muscleAffected,  int weekNumber,  String title,  String description,  String severity,  int? volumeBefore,  int? volumeAfter,  String? decisionReason,  String? feedbackContext,  String actorType,  String actorDetails,  bool isValid,  List<String> validationErrors,  DateTime timestamp,  Map<String, dynamic> metadata,  String? linkedToProgressRecordId,  String? linkedToFeedbackEntryId,  String? linkedToPreviousLogId)?  $default,) {final _that = this;
switch (_that) {
case _TrainingAuditLogEntry() when $default != null:
return $default(_that.userId,_that.eventType,_that.muscleAffected,_that.weekNumber,_that.title,_that.description,_that.severity,_that.volumeBefore,_that.volumeAfter,_that.decisionReason,_that.feedbackContext,_that.actorType,_that.actorDetails,_that.isValid,_that.validationErrors,_that.timestamp,_that.metadata,_that.linkedToProgressRecordId,_that.linkedToFeedbackEntryId,_that.linkedToPreviousLogId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingAuditLogEntry implements TrainingAuditLogEntry {
  const _TrainingAuditLogEntry({required this.userId, required this.eventType, this.muscleAffected = null, required this.weekNumber, required this.title, required this.description, required this.severity, this.volumeBefore = null, this.volumeAfter = null, this.decisionReason = null, this.feedbackContext = null, required this.actorType, this.actorDetails = '', required this.isValid, final  List<String> validationErrors = const [], required this.timestamp, final  Map<String, dynamic> metadata = const {}, this.linkedToProgressRecordId = null, this.linkedToFeedbackEntryId = null, this.linkedToPreviousLogId = null}): _validationErrors = validationErrors,_metadata = metadata;
  factory _TrainingAuditLogEntry.fromJson(Map<String, dynamic> json) => _$TrainingAuditLogEntryFromJson(json);

/// Identificadores
@override final  String userId;
@override final  String eventType;
// Ver enum abajo
@override@JsonKey() final  String? muscleAffected;
// null si es a nivel usuario
@override final  int weekNumber;
/// QUÉ pasó
@override final  String title;
// Título breve del evento
@override final  String description;
// Descripción detallada
@override final  String severity;
// 'info', 'warning', 'error', 'critical'
/// DATOS de la decisión
@override@JsonKey() final  int? volumeBefore;
// Volumen anterior
@override@JsonKey() final  int? volumeAfter;
// Volumen nuevo
@override@JsonKey() final  String? decisionReason;
// Por qué se tomó
@override@JsonKey() final  String? feedbackContext;
// Contexto de feedback que llevó a esto
/// QUIÉN lo hizo
@override final  String actorType;
// 'motor'|'user'|'system'|'coach'
@override@JsonKey() final  String actorDetails;
// ID del coach si aplica, versión del motor, etc.
/// Validación
@override final  bool isValid;
// ¿Pasó validación?
 final  List<String> _validationErrors;
// ¿Pasó validación?
@override@JsonKey() List<String> get validationErrors {
  if (_validationErrors is EqualUnmodifiableListView) return _validationErrors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_validationErrors);
}

// Errores de validación si aplica
/// Metadata
@override final  DateTime timestamp;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

// Datos extras (lineage, calculations, etc.)
/// Linkage a otros registros
@override@JsonKey() final  String? linkedToProgressRecordId;
// ID de ProgressRecord si aplica
@override@JsonKey() final  String? linkedToFeedbackEntryId;
// ID de FeedbackEntry si aplica
@override@JsonKey() final  String? linkedToPreviousLogId;

/// Create a copy of TrainingAuditLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingAuditLogEntryCopyWith<_TrainingAuditLogEntry> get copyWith => __$TrainingAuditLogEntryCopyWithImpl<_TrainingAuditLogEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingAuditLogEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingAuditLogEntry&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.muscleAffected, muscleAffected) || other.muscleAffected == muscleAffected)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.volumeBefore, volumeBefore) || other.volumeBefore == volumeBefore)&&(identical(other.volumeAfter, volumeAfter) || other.volumeAfter == volumeAfter)&&(identical(other.decisionReason, decisionReason) || other.decisionReason == decisionReason)&&(identical(other.feedbackContext, feedbackContext) || other.feedbackContext == feedbackContext)&&(identical(other.actorType, actorType) || other.actorType == actorType)&&(identical(other.actorDetails, actorDetails) || other.actorDetails == actorDetails)&&(identical(other.isValid, isValid) || other.isValid == isValid)&&const DeepCollectionEquality().equals(other._validationErrors, _validationErrors)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.linkedToProgressRecordId, linkedToProgressRecordId) || other.linkedToProgressRecordId == linkedToProgressRecordId)&&(identical(other.linkedToFeedbackEntryId, linkedToFeedbackEntryId) || other.linkedToFeedbackEntryId == linkedToFeedbackEntryId)&&(identical(other.linkedToPreviousLogId, linkedToPreviousLogId) || other.linkedToPreviousLogId == linkedToPreviousLogId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,eventType,muscleAffected,weekNumber,title,description,severity,volumeBefore,volumeAfter,decisionReason,feedbackContext,actorType,actorDetails,isValid,const DeepCollectionEquality().hash(_validationErrors),timestamp,const DeepCollectionEquality().hash(_metadata),linkedToProgressRecordId,linkedToFeedbackEntryId,linkedToPreviousLogId]);

@override
String toString() {
  return 'TrainingAuditLogEntry(userId: $userId, eventType: $eventType, muscleAffected: $muscleAffected, weekNumber: $weekNumber, title: $title, description: $description, severity: $severity, volumeBefore: $volumeBefore, volumeAfter: $volumeAfter, decisionReason: $decisionReason, feedbackContext: $feedbackContext, actorType: $actorType, actorDetails: $actorDetails, isValid: $isValid, validationErrors: $validationErrors, timestamp: $timestamp, metadata: $metadata, linkedToProgressRecordId: $linkedToProgressRecordId, linkedToFeedbackEntryId: $linkedToFeedbackEntryId, linkedToPreviousLogId: $linkedToPreviousLogId)';
}


}

/// @nodoc
abstract mixin class _$TrainingAuditLogEntryCopyWith<$Res> implements $TrainingAuditLogEntryCopyWith<$Res> {
  factory _$TrainingAuditLogEntryCopyWith(_TrainingAuditLogEntry value, $Res Function(_TrainingAuditLogEntry) _then) = __$TrainingAuditLogEntryCopyWithImpl;
@override @useResult
$Res call({
 String userId, String eventType, String? muscleAffected, int weekNumber, String title, String description, String severity, int? volumeBefore, int? volumeAfter, String? decisionReason, String? feedbackContext, String actorType, String actorDetails, bool isValid, List<String> validationErrors, DateTime timestamp, Map<String, dynamic> metadata, String? linkedToProgressRecordId, String? linkedToFeedbackEntryId, String? linkedToPreviousLogId
});




}
/// @nodoc
class __$TrainingAuditLogEntryCopyWithImpl<$Res>
    implements _$TrainingAuditLogEntryCopyWith<$Res> {
  __$TrainingAuditLogEntryCopyWithImpl(this._self, this._then);

  final _TrainingAuditLogEntry _self;
  final $Res Function(_TrainingAuditLogEntry) _then;

/// Create a copy of TrainingAuditLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? eventType = null,Object? muscleAffected = freezed,Object? weekNumber = null,Object? title = null,Object? description = null,Object? severity = null,Object? volumeBefore = freezed,Object? volumeAfter = freezed,Object? decisionReason = freezed,Object? feedbackContext = freezed,Object? actorType = null,Object? actorDetails = null,Object? isValid = null,Object? validationErrors = null,Object? timestamp = null,Object? metadata = null,Object? linkedToProgressRecordId = freezed,Object? linkedToFeedbackEntryId = freezed,Object? linkedToPreviousLogId = freezed,}) {
  return _then(_TrainingAuditLogEntry(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,muscleAffected: freezed == muscleAffected ? _self.muscleAffected : muscleAffected // ignore: cast_nullable_to_non_nullable
as String?,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,volumeBefore: freezed == volumeBefore ? _self.volumeBefore : volumeBefore // ignore: cast_nullable_to_non_nullable
as int?,volumeAfter: freezed == volumeAfter ? _self.volumeAfter : volumeAfter // ignore: cast_nullable_to_non_nullable
as int?,decisionReason: freezed == decisionReason ? _self.decisionReason : decisionReason // ignore: cast_nullable_to_non_nullable
as String?,feedbackContext: freezed == feedbackContext ? _self.feedbackContext : feedbackContext // ignore: cast_nullable_to_non_nullable
as String?,actorType: null == actorType ? _self.actorType : actorType // ignore: cast_nullable_to_non_nullable
as String,actorDetails: null == actorDetails ? _self.actorDetails : actorDetails // ignore: cast_nullable_to_non_nullable
as String,isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,validationErrors: null == validationErrors ? _self._validationErrors : validationErrors // ignore: cast_nullable_to_non_nullable
as List<String>,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,linkedToProgressRecordId: freezed == linkedToProgressRecordId ? _self.linkedToProgressRecordId : linkedToProgressRecordId // ignore: cast_nullable_to_non_nullable
as String?,linkedToFeedbackEntryId: freezed == linkedToFeedbackEntryId ? _self.linkedToFeedbackEntryId : linkedToFeedbackEntryId // ignore: cast_nullable_to_non_nullable
as String?,linkedToPreviousLogId: freezed == linkedToPreviousLogId ? _self.linkedToPreviousLogId : linkedToPreviousLogId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
