import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'link.dart';

part 'system_fields.g.dart';

@JsonSerializable()
class SystemFields extends Equatable {
  SystemFields({
    required this.id,
    required this.type,
    required this.space,
    required this.contentType,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.locale,
  });

  final String id;
  final String type;
  final Link space;
  final Link contentType;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String locale;

  @override
  List<Object> get props =>
      [id, type, space, contentType, revision, createdAt, updatedAt, locale];

  factory SystemFields.fromJson(Map<String, dynamic> json) =>
      _$SystemFieldsFromJson(json);

  Map<String, dynamic> toJson() => _$SystemFieldsToJson(this);
}
