import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiBaseUrl = 'https://rhik.uz';

/// Thrown when the access token could not be refreshed and the user
/// needs to log in again.
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Сессия истекла, войдите заново']);

  @override
  String toString() => message;
}

/// Calls the refresh endpoint and persists both the new access token and
/// the rotated refresh token (the backend has ROTATE_REFRESH_TOKENS and
/// BLACKLIST_AFTER_ROTATION enabled, so the old refresh token stops
/// working the moment a new one is issued).
Future<bool> refreshAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refresh_token');
  if (refreshToken == null) return false;

  try {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/token/refresh/'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode != 200) return false;

    final data = json.decode(utf8.decode(response.bodyBytes));
    await prefs.setString('access_token', data['access']);
    if (data['refresh'] != null) {
      await prefs.setString('refresh_token', data['refresh']);
    }
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');
}

/// Sends an authorized request, transparently refreshing the access token
/// and retrying once if the server responds with 401.
Future<http.Response> authorizedRequest(
  String method,
  Uri url, {
  Map<String, String>? headers,
  Object? body,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    throw SessionExpiredException('Токен авторизации не найден');
  }

  Future<http.Response> send(String accessToken) {
    final mergedHeaders = <String, String>{
      ...?headers,
      'Authorization': 'Bearer $accessToken',
    };
    switch (method) {
      case 'GET':
        return http.get(url, headers: mergedHeaders);
      case 'POST':
        return http.post(url, headers: mergedHeaders, body: body);
      case 'PUT':
        return http.put(url, headers: mergedHeaders, body: body);
      case 'PATCH':
        return http.patch(url, headers: mergedHeaders, body: body);
      case 'DELETE':
        return http.delete(url, headers: mergedHeaders, body: body);
      default:
        throw ArgumentError('Unsupported method: $method');
    }
  }

  var response = await send(token);

  if (response.statusCode == 401) {
    final refreshed = await refreshAccessToken();
    if (!refreshed) {
      await clearSession();
      throw SessionExpiredException();
    }
    final newToken = prefs.getString('access_token')!;
    response = await send(newToken);
  }

  return response;
}

Future<http.Response> apiGet(Uri url, {Map<String, String>? headers}) =>
    authorizedRequest('GET', url, headers: headers);

Future<http.Response> apiPost(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    authorizedRequest('POST', url, headers: headers, body: body);

Future<http.Response> apiPut(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    authorizedRequest('PUT', url, headers: headers, body: body);

Future<http.Response> apiPatch(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    authorizedRequest('PATCH', url, headers: headers, body: body);

Future<http.Response> apiDelete(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    authorizedRequest('DELETE', url, headers: headers, body: body);

/// Same 401-refresh-and-retry behavior as [authorizedRequest], for
/// multipart uploads. The image file is re-read from disk on retry since a
/// [http.MultipartFile] built from a stream can only be sent once.
Future<http.StreamedResponse> authorizedMultipartRequest(
  String method,
  Uri url, {
  required Map<String, String> fields,
  File? imageFile,
  String imageFieldName = 'photo',
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    throw SessionExpiredException('Токен авторизации не найден');
  }

  Future<http.StreamedResponse> send(String accessToken) async {
    final request = http.MultipartRequest(method, url)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields.addAll(fields);
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(imageFieldName, imageFile.path),
      );
    }
    return request.send();
  }

  var response = await send(token);

  if (response.statusCode == 401) {
    final refreshed = await refreshAccessToken();
    if (!refreshed) {
      await clearSession();
      throw SessionExpiredException();
    }
    final newToken = prefs.getString('access_token')!;
    response = await send(newToken);
  }

  return response;
}
