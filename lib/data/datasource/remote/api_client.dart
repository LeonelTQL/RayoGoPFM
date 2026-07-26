import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/config/app_config.dart';
import '../local/session_local_datasource.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<Map<String, dynamic>>? errors;
  ApiException(this.message, this.statusCode, {this.errors});

  @override
  String toString() => message;
}

class ApiClient {
  final SessionLocalDatasource session;
  final String baseUrl;

  ApiClient({required this.session, this.baseUrl = AppConfig.apiBaseUrl});

  Future<Map<String, String>> _headers() async {
    final token = await session.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(Future<http.Response> Function() requestFn) async {
    try {
      return await requestFn();
    } on SocketException {
      throw ApiException('No hay conexión a internet o la calidad de la señal es baja.', 0);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('SocketException') || errStr.contains('Failed host lookup') || errStr.contains('HandshakeException')) {
        throw ApiException('No hay conexión a internet o la calidad de la señal es baja.', 0);
      }
      rethrow;
    }
  }

  Future<dynamic> get(String path) async {
    final headers = await _headers();
    final response = await _send(() => http.get(Uri.parse('$baseUrl$path'), headers: headers));
    return _handle(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await _send(() => http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    ));
    return _handle(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await _send(() => http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    ));
    return _handle(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await _send(() => http.patch(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    ));
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final headers = await _headers();
    final response = await _send(() => http.delete(Uri.parse('$baseUrl$path'), headers: headers));
    return _handle(response);
  }

  Future<dynamic> uploadImage(String path, File file, {Map<String, String>? fields}) async {
    final token = await session.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    
    final ext = file.path.split('.').last.toLowerCase();
    MediaType? contentType;
    if (ext == 'png') {
      contentType = MediaType('image', 'png');
    } else if (ext == 'gif') {
      contentType = MediaType('image', 'gif');
    } else if (ext == 'webp') {
      contentType = MediaType('image', 'webp');
    } else {
      contentType = MediaType('image', 'jpeg');
    }
    
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      file.path,
      contentType: contentType,
    ));
    
    final response = await _send(() async {
      final streamed = await request.send();
      return await http.Response.fromStream(streamed);
    });
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    String? message;
    List<Map<String, dynamic>>? errors;

    if (decoded is Map<String, dynamic>) {
      message = decoded['message']?.toString();
      if (decoded['errors'] != null && decoded['errors'] is List) {
        errors = List<Map<String, dynamic>>.from(decoded['errors']);
      }
    }

    throw ApiException(message ?? 'Error de API', response.statusCode, errors: errors);
  }
}
