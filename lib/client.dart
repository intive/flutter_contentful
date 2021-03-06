import 'dart:async';
import 'dart:convert';
import 'package:contentful/includes.dart';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:contentful/lib/conversion.dart' as convert;
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
    String environment = 'master',
  }) {
    final client = HttpClient(accessToken);
    return Client._(client, spaceId, host: host, environment: environment);
  }

  Client._(
    this._client,
    this.spaceId, {
    required this.host,
    required this.environment,
  });

  final HttpClient _client;
  final String spaceId;
  final String host;
  final String environment;

  Uri _uri(String path, {Map<String, dynamic>? params}) => Uri(
        scheme: 'https',
        host: host,
        path: '/spaces/$spaceId/environments/$environment$path',
        queryParameters: params,
      );

  void close() {
    _client.close();
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

    Map<String, dynamic> jsonr = json.decode(utf8.decode(response.bodyBytes));

    // If it has includes, then resolve all the links inside the items
    jsonr = optionOf(jsonr['includes'])
        .map(convert.map)
        .map(Includes.fromJson)
        .map((includes) => includes.resolveLinks(jsonr['items']))
        .fold(
          () => jsonr,
          (items) => {
            ...jsonr,
            'items': items,
          },
        );

    return EntryCollection.fromJson(jsonr, fromJson);
  }
}
