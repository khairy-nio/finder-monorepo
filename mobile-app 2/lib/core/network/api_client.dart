import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

/// HTTP Client for API calls to Flask backend
class ApiClient {
  final http.Client client;
  String? authToken; // Optional auth token for Firebase Auth
  final Future<String?> Function()? tokenProvider;

  ApiClient({http.Client? client, this.authToken, this.tokenProvider})
      : client = client ?? http.Client();

  /// Helper to get headers with optional auth token
  Future<Map<String, String>> _getHeaders() async {
    final headers = Map<String, String>.from(ApiConstants.headers);
    final token = authToken ?? await tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
        final response = await client
          .get(url, headers: await _getHeaders())
          .timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await client
          .post(
            url,
        headers: await _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// POST request with multipart (for image upload)
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required String filePath,
    Map<String, String>? fields,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers.addAll(await _getHeaders());

      // Add file
      request.files.add(await http.MultipartFile.fromPath('image', filePath));

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(
        ApiConstants.receiveTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to upload image: $e');
    }
  }

  /// Generic PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await client
          .put(
            url,
        headers: await _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Generic PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await client
          .patch(
            url,
            headers: await _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
        final response = await client
          .delete(url, headers: await _getHeaders())
          .timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Unexpected error';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) {
          errorMessage = body['message'];
        } else if (body['error'] != null) {
          errorMessage = body['error'];
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Error ${response.statusCode}';
      }
      
      throw ServerException(
        errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  /// Dispose client
  void dispose() {
    client.close();
  }
}
