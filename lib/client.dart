import 'dart:async';
import 'dart:convert';
import 'package:contentful/includes.dart';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:contentful/lib/conversion.dart' as convert;
import 'package:contentful/models/entry.dart';

abstract class ContentfulHTTPClient {
  Future<http.Response> get(Uri url, {Map<String, String>? headers});
  void close();
}

class BearerTokenHTTPClient extends http.BaseClient
    implements ContentfulHTTPClient {
  BearerTokenHTTPClient(String accessToken)
      : _inner = http.Client(),
        accessToken = accessToken;

  final http.Client _inner;
  final String accessToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $accessToken';
    return _inner.send(request);
  }
}

class Client {
  Client({
    required String accessToken,
    Uri? baseURL,
    required String spaceId,
    String environment = 'master',
  }) : this.performingRequestsUsing(
          httpClient: BearerTokenHTTPClient(accessToken),
          baseURL: baseURL,
          spaceId: spaceId,
          environment: environment,
        );

  Client.performingRequestsUsing({
    required ContentfulHTTPClient httpClient,
    Uri? baseURL,
    required this.spaceId,
    this.environment = 'master',
  })  : _httpClient = httpClient,
        baseURL = baseURL ?? Uri.https('cdn.contentful.com', '');

  final ContentfulHTTPClient _httpClient;
  final String spaceId;
  final Uri baseURL;
  final String environment;

  Uri _uri(String path, {Map<String, dynamic>? params}) => baseURL.resolveUri(
        Uri(
          path: 'spaces/$spaceId/environments/$environment$path',
          queryParameters: params,
        ),
      );

  void close() => _httpClient.close();

  Future<T> getEntry<T extends Entry>(
    String id,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? params,
  }) async {
    final response =
        await _httpClient.get(_uri('/entries/$id', params: params));
    if (response.statusCode != 200) {
      throw Exception('getEntry failed');
    }
    return fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<EntryCollection<T>> getEntries<T extends Entry>(
    Map<String, dynamic> query,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _httpClient.get(_uri('/entries', params: query));
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
