import 'package:dartz/dartz.dart';
import 'package:contentful/lib/conversion.dart' as convert;
import 'package:contentful/lib/entry.dart' as entry_utils;

bool _isListOfLinks(dynamic list) {
  if (list is! List) {
    return false;
  } else if (list.isEmpty) {
    return false;
  }

  if (!(list.first is Map)) {
    return false;
  }

  return entry_utils.isLink(list.first);
}

class Includes {
  static Includes fromJson(Map<String, dynamic> json) =>
      Includes._(_IncludesMap.fromJson(json));

  Includes._(this.map);
  final _IncludesMap map;

  List<Map<String, dynamic>> resolveLinks(List<dynamic> items) =>
      items.map(convert.map).map(_walkMap).toList();

  Map<String, dynamic> _walkMap(Map<String, dynamic> entry) =>
      entry_utils.isLink(entry)
          ? map.resolveLink(entry).fold(() => entry, _walkMap)
          : entry_utils.fields(entry).fold(
                () => entry,
                (fields) => {
                  ...entry,
                  'fields': fields.map(_resolveEntryFields),
                },
              );

  MapEntry<String, dynamic> _resolveEntryFields(String key, dynamic object) =>
      _isListOfLinks(object)
          ? MapEntry(key, resolveLinks(object))
          : option(object is Map, object)
              .map(convert.map)
              .filter(entry_utils.isLink)
              .bind(map.resolveLink)
              .map(_walkMap)
              .fold(
                () => MapEntry(key, object),
                (entry) => MapEntry(key, entry),
              );
}

class _IncludesMap {
  factory _IncludesMap.fromJson(Map<String, dynamic> includes) =>
      _IncludesMap._(
        includes.values.map(convert.listOfMaps).fold(
          {},
          (map, entries) => entries.fold(
            map,
            (map, entry) => entry_utils.id(entry).fold(
              () => map,
              (id) {
                map[id] = entry;
                return map;
              },
            ),
          ),
        ),
      );

  _IncludesMap._(this._map);

  final Map<String, Map<String, dynamic>> _map;

  Option<Map<String, dynamic>> resolveLink(Map<String, dynamic> link) =>
      entry_utils.id(link).bind((id) => optionOf(_map[id]));
}
