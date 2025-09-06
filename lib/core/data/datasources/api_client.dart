import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:recette/core/data/datasources/api_request.dart';
import 'package:recette/core/data/datasources/api_response.dart';

class ApiClient {
  final http.Client client; // Replace with your actual HTTP client type
  final String baseUrl;
  // final LoggingService loggingService;

  ApiClient({
    required this.client,
    required this.baseUrl,
    // required this.loggingService,
  });
  
  Future<ApiResponse<T>> post<T>({
    required ApiRequest request,
    required T Function(dynamic json) fromJson,
  }) async {
    // Implement the actual HTTP POST logic here using your preferred HTTP client.
    // For demonstration, we'll return a dummy successful response.
    try {
      // Simulate a network call and response
      
      // 1. Prepare the request details.
      final url = Uri.parse('$baseUrl/${request.endpoint}');
      final headers = {'Content-Type': 'application/json'};
      final encodedBody = json.encode(request.toJson());
      
      // 2. Make the actual call. The `await` pauses execution until a response is received.
      final http.Response httpResponse = await client.post(
        url,
        headers: headers,
        body: encodedBody,
      ).timeout(const Duration(seconds: 1));

      // 3. Check the result.
      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        // This is the success case (like 200 OK).
        final jsonResponse = json.decode(httpResponse.body);
        final data = fromJson(jsonResponse); // <-- This is where parsing happens!
        return ApiResponse<T>(data: data, statusCode: httpResponse.statusCode);
      } else {
        // This is a controlled error from the backend (like 404 or 500).
        final errorBody = json.decode(httpResponse.body);
        final errorMessage = errorBody['error'] ?? 'Unknown API Error';
        return ApiResponse<T>(
          error: ApiError(message: errorMessage),
          statusCode: httpResponse.statusCode,
        );
      }
    } on TimeoutException {
      return ApiResponse<T>(error: ApiError(message: 'Request timed out'));
    }  on SocketException catch (e) {
      return ApiResponse<T>(error: ApiError(message: 'Network error: ${e.toString()}'));
    } on FormatException {
      return ApiResponse<T>(error: ApiError(message: 'Failed to parse response'));
    } catch (e) {
      return ApiResponse<T>(error: ApiError(message: 'An unknown error occurred: $e'));
    }
  }
}