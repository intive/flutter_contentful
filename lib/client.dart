import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:contentful/lib/entry.dart' as E;
import 'package:contentful/models/entry.dart';

class HttpClient extends http.BaseClient {
  factory HttpClient(String accessToken) {
    final client = http.Client();
    return HttpClient._internal(client, accessToken);
  }
  HttpClient._internal(this._inner, this.accessToken);

  final http.Client _inner;
  final String accessToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $accessToken';
    return _inner.send(request);
  }
}

class Client {
  factory Client(
    String spaceId,
    String accessToken, {
    String host = 'cdn.contentful.com',
  }) {
    final client = HttpClient(accessToken);
    return Client._(client, spaceId, host: host);
  }
  Client._(
    this._client,
    this.spaceId, {
    required this.host,
  });

  final HttpClient _client;
  final String spaceId;
  final String host;

  Uri _uri(String path, {Map<String, dynamic>? params}) => Uri(
        scheme: 'https',
        host: host,
        path: '/spaces/$spaceId/environments/master$path',
        queryParameters: params,
      );

  void close() {
    this._client.close();
  }

  Future<T> getEntry<T extends Entry>(
    String id,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? params,
  }) async {
    final response = await _client.get(_uri('/entries/$id', params: params));
    if (response.statusCode != 200) {
      throw Exception('getEntry failed');
    }
    return fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<EntryCollection<T>> getEntries<T extends Entry>(
    Map<String, dynamic> query,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _client.get(_uri('/entries', params: query));
    if (response.statusCode != 200) {
      throw Exception('getEntries failed');
    }

    dynamic jsonr = json.decode(utf8.decode(response.bodyBytes));
    if (jsonr['includes'] != null) {
      final includes = Includes.fromJson(jsonr['includes']);
      jsonr['items'] = includes.resolveLinks(jsonr['items']);
    }

    return EntryCollection.fromJson(jsonr, fromJson);
  }
}

bool _isListOfLinks(List<dynamic> list) {
  if (list.isEmpty) {
    return false;
  }

  if (!(list.first is Map)) {
    return false;
  }

  return E.isLink(list.first);
}

class Includes {
  factory Includes.fromJson(Map<String, dynamic> json) =>
      Includes(IncludesMap.fromJson(json));

  Includes(this.map);
  final IncludesMap map;

  MapEntry<String, dynamic> _resolveFieldEntry(String key, dynamic fieldJson) =>
      some(fieldJson)
          .filter((fieldJson) => fieldJson is List && _isListOfLinks(fieldJson))
          .map((fieldJson) => MapEntry<String, dynamic>(
                key,
                resolveLinks(fieldJson),
              ))
          .orElse(() => some(fieldJson)
              .filter((field) => field is Map)
              .map((field) => Map<String, dynamic>.from(field))
              .map((field) => map.resolveLink(field) | field)
              .map(_walkMap)
              .map((field) => MapEntry(key, field)))
          .getOrElse(() => MapEntry(key, fieldJson));

  Map<String, dynamic> _walkMap(Map<String, dynamic> entry) {
    if (E.isLink(entry)) {
      return map.resolveLink(entry).map(_walkMap) | entry;
    }

    return E.fields(entry).fold(() => entry, (fields) {
      entry['fields'] = fields.map(_resolveFieldEntry);
      return entry;
    });
  }

  Iterable<Map<String, dynamic>> resolveLinks(List<dynamic> items) => items
      .map((item) => Map<String, dynamic>.from(item))
      .map((item) => _walkMap(item));
}

Iterable<MapEntry<String, Map<String, dynamic>>> _mapEntriesFromList(
  Iterable<dynamic> list,
) =>
    list
        .map((json) => Map<String, dynamic>.from(json))
        .map((entry) => MapEntry(E.id(entry), entry));

class IncludesMap {
  factory IncludesMap.fromJson(Map<String, dynamic> includes) => IncludesMap(
        includes.map((type, entriesForType) => MapEntry(
              type,
              Map.fromEntries(_mapEntriesFromList(entriesForType)),
            )),
      );

  IncludesMap(this._map);

  final Map<String, Map<String, Map<String, dynamic>>> _map;

  Option<Map<String, dynamic>> resolveLink(Map<String, dynamic> link) {
    final String type = link['sys']['linkType'];
    final String id = link['sys']['id'];
    return optionOf(_map[type]?[id]);
  }
}
