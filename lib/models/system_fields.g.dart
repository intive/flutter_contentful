// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_fields.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemFields _$SystemFieldsFromJson(Map<String, dynamic> json) {
  return SystemFields(
    id: json['id'] as String,
    type: json['type'] as String,
    space: Link.fromJson(json['space'] as Map<String, dynamic>),
    contentType: Link.fromJson(json['contentType'] as Map<String, dynamic>),
    revision: json['revision'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    locale: json['locale'] as String,
  );
}

Map<String, dynamic> _$SystemFieldsToJson(SystemFields instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'space': instance.space,
      'contentType': instance.contentType,
      'revision': instance.revision,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'locale': instance.locale,
    };
