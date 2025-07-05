import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  late http.Client _client;

  ApiService() {
    _client = http.Client();
  }

  void dispose() {
    _client.close();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  T _handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = json.decode(response.body);
      final apiResponse = ApiResponse<T>.fromJson(jsonMap, fromJson);
      if (!apiResponse.success) {
        throw ApiException(apiResponse.error ?? 'Unknown API error');
      }
      return apiResponse.data as T;
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      throw ValidationException('Client error: ${response.body}');
    } else if (response.statusCode >= 500) {
      throw ServerException('Server error: ${response.body}');
    } else {
      throw ApiException('Unexpected status code: ${response.statusCode}');
    }
  }

  Future<List<Message>> getMessages() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/messages'), headers: _getHeaders())
          .timeout(timeout);
      final List<dynamic> list = json.decode(response.body);
      return list.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      throw NetworkException('Failed to load messages: $e');
    }
  }

  Future<Message> createMessage(CreateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) throw ValidationException(validationError);
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/api/messages'),
              headers: _getHeaders(), body: json.encode(request.toJson()))
          .timeout(timeout);
      return _handleResponse<Message>(response, (json) => Message.fromJson(json));
    } catch (e) {
      throw NetworkException('Failed to create message: $e');
    }
  }

  Future<Message> updateMessage(int id, UpdateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) throw ValidationException(validationError);
    try {
      final response = await _client
          .put(Uri.parse('$baseUrl/api/messages/$id'),
              headers: _getHeaders(), body: json.encode(request.toJson()))
          .timeout(timeout);
      return _handleResponse<Message>(response, (json) => Message.fromJson(json));
    } catch (e) {
      throw NetworkException('Failed to update message: $e');
    }
  }

  Future<void> deleteMessage(int id) async {
    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl/api/messages/$id'), headers: _getHeaders())
          .timeout(timeout);
      if (response.statusCode != 204) {
        throw ApiException('Failed to delete message');
      }
    } catch (e) {
      throw NetworkException('Failed to delete message: $e');
    }
  }

  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/status/$statusCode'), headers: _getHeaders())
          .timeout(timeout);
      return _handleResponse<HTTPStatusResponse>(response, (json) => HTTPStatusResponse.fromJson(json));
    } catch (e) {
      throw NetworkException('Failed to get HTTP status: $e');
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/health'), headers: _getHeaders())
          .timeout(timeout);
      return json.decode(response.body);
    } catch (e) {
      throw NetworkException('Health check failed: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}
