import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recette/core/data/datasources/api_client.dart';
import 'package:recette/core/data/datasources/api_request.dart';
import 'package:recette/core/data/datasources/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('isSuccess should be true for successful responses', () {
      final successResponse = ApiResponse<String>(data: 'Success');
      expect(successResponse.isSuccess, isTrue);
      expect(successResponse.isError, isFalse);
    });

    test('isError should be true for error responses', () {
      final errorResponse = ApiResponse<String>(error: ApiError(message: 'Failed'));
      expect(errorResponse.isError, isTrue);
      expect(errorResponse.isSuccess, isFalse);
    });
  });

  group('ApiClient', () {
    test('post returns successful ApiResponse on 200 OK', () async {
      // 1. Arrange
      final mockClient = MockClient((request) async {
        // Simulate a successful server response
        return http.Response('{"message": "Data saved"}', 200);
      });

      // We'll create the ApiClient next
      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'example.com',
      );
      final request = MockApiRequest();

      // 2. Act
      final response = await apiClient.post<Map<String, dynamic>>(
        request: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // 3. Assert
      expect(response.isSuccess, isTrue);
      expect(response.data!['message'], 'Data saved');

      // TODO: Add tests for 404, 500, network error, timeouts, bad JSON, etc.
    });

    test('post returns error ApiResponse on 404 Not Found', () async {
      // 1. Arrange
      final mockClient = MockClient((request) async {
        // Simulate a 404 Not Found response
        return http.Response('{"error": "Resource not found"}', 404);
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'example.com',
      );
      final request = MockApiRequest();

      // 2. Act
      final response = await apiClient.post<Map<String, dynamic>>(
        request: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // 3. Assert
      expect(response.isError, isTrue);
      expect(response.error!.message, contains('Resource not found'));
    });
    
    test('post returns error ApiResponse on malformed JSON response', () async {
      // 1. Arrange
      final mockClient = MockClient((request) async {
        // Simulate a 200 OK but with invalid JSON
        return http.Response('{"message": "Incomplete"', 200);
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'example.com',
      );
      final request = MockApiRequest();

      // 2. Act
      final response = await apiClient.post(request: request, fromJson: (_) => null);

      // 3. Assert
      expect(response.isError, isTrue);
      // Check that your ApiClient's catch block correctly identified a parsing error
      expect(response.error!.message, contains('Failed to parse response'));
    });

    test('post returns error ApiResponse on network failure', () async {
      // 1. Arrange
      final mockClient = MockClient((request) async {
        // Simulate a complete network failure
        throw const SocketException('No Internet');
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'example.com',
      );
      final request = MockApiRequest();

      // 2. Act
      final response = await apiClient.post(request: request, fromJson: (_) => null);

      // 3. Assert
      expect(response.isError, isTrue);
      expect(response.error!.message, contains('Network error'));
    });

    test('post returns error ApiResponse on request timeout', () async {
      // 1. Arrange
      final mockClient = MockClient((request) async {
        // Simulate a server that takes 2 seconds to respond.
        await Future.delayed(const Duration(seconds: 2));
        return http.Response('{"message": "Finally here"}', 200);
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'example.com',
      );
      final request = MockApiRequest();

      // 2. Act
      // We expect the ApiClient to be configured with a timeout shorter than 2 seconds.
      final response = await apiClient.post(request: request, fromJson: (_) => null);

      // 3. Assert
      expect(response.isError, isTrue);
      expect(response.error!.message, contains('Request timed out'));
    });
    
    test('post returns error on 200 OK with non-JSON body', () async {
      // 1. Arrange
      final mockClient = MockClient((request) async {
        // Simulate a 200 OK but with an HTML body, not JSON.
        return http.Response('<html><body>Error</body></html>', 200);
      });
      
      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'example.com',
      );
      final request = MockApiRequest();

      // 2. Act
      final response = await apiClient.post(request: request, fromJson: (_) => null);

      // 3. Assert
      expect(response.isError, isTrue);
      expect(response.error!.message, contains('Failed to parse response'));
    });
  });
}

// Helper class for the test
class MockApiRequest implements ApiRequest {
  @override
  String get endpoint => 'test';

  @override
  Map<String, dynamic> toJson() => {'key': 'value'};
}