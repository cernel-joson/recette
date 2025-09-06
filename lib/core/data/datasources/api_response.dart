import 'package:flutter/foundation.dart';

@immutable
class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final int statusCode;

  const ApiResponse({
    this.data,
    this.error,
    this.statusCode = 200,
  }) : assert(data != null || error != null, 'Either data or error must be provided');

  bool get isSuccess => error == null && data != null;
  bool get isError => error != null;
}

@immutable
class ApiError {
  final String message;
  final int? code;

  const ApiError({required this.message, this.code});
}