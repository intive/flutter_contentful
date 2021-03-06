import 'package:dartz/dartz.dart';
import 'package:contentful/lib/entry.dart' as E;

Map<String, dynamic> _ensureMap(dynamic input) =>
    Map<String, dynamic>.from(input);

bool _isListOfLinks(dynamic list) {
  if (list is! List) {
    return false;
  } else if (list.isEmpty) {
    return false;
  }

  if (!(list.first is Map)) {
    return false;
  }

  return E.isLink(list.first);
}

class Includes {
  factory Includes.fromJson(Map<String, List<dynamic>> json) =>
      Includes._(_IncludesMap.fromJson(json));

  Includes._(this.map);
  final _IncludesMap map;

  List<Map<String, dynamic>> resolveLinks(List<dynamic> items) =>
      items.map(_ensureMap).map(_walkMap).toList();

  Map<String, dynamic> _walkMap(Map<String, dynamic> entry) => E.isLink(entry)
      ? map.resolveLink(entry).fold(() => entry, _walkMap)
      : E.fields(entry).fold(
            () => entry,
            (fields) => {
              ...entry,
              'fields': fields.map(_resolveEntryFields),
            },
          );

  MapEntry<String, dynamic> _resolveEntryFields(String key, dynamic fields) =>
      _isListOfLinks(fields)
          ? MapEntry(key, resolveLinks(fields))
          : option(fields is Map, fields)
              .map(_ensureMap)
              .filter(E.isLink)
              .bind(map.resolveLink)
              .map(_walkMap)
              .fold(
                () => MapEntry(key, fields),
                (entry) => MapEntry(key, entry),
              );
}

class _IncludesMap {
  factory _IncludesMap.fromJson(Map<String, List<dynamic>> includes) =>
      _IncludesMap._(
        includes.values.fold(
          IHashMap.empty(),
          (map, entries) => entries.map(_ensureMap).fold(
                map,
                (map, entry) => E.id(entry).fold(
                      () => map,
                      (id) => map.put(id, entry),
                    ),
              ),
        ),
      );

  _IncludesMap._(this._map);

  final IHashMap<String, Map<String, dynamic>> _map;

  Option<Map<String, dynamic>> resolveLink(Map<String, dynamic> link) =>
      E.id(link).bind(_map.get);
}
