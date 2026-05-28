import 'dart:math';

/// Utility to simulate network behavior like delays and random errors
class NetworkSimulator {
  static final _random = Random();
  
  /// The global toggle controlling whether to use the mock API or real API
  static const bool USE_MOCK_API = true;

  /// Simulates network delay and optional random failure
  /// [minDelayMs] minimum artificial delay in milliseconds
  /// [maxDelayMs] maximum artificial delay in milliseconds
  /// [failureRate] probability of throwing a random network error (0.0 to 1.0)
  static Future<void> simulate({
    int minDelayMs = 300,
    int maxDelayMs = 1200,
    double failureRate = 0.1,
  }) async {
    // Artificial Delay
    final delay = minDelayMs + _random.nextInt(maxDelayMs - minDelayMs);
    await Future.delayed(Duration(milliseconds: delay));

    // Artificial Error
    if (_random.nextDouble() < failureRate) {
      throw MockNetworkException(
        message: "Simulated network connection error.",
        code: 503,
      );
    }
  }
}

class MockNetworkException implements Exception {
  final String message;
  final int code;

  MockNetworkException({required this.message, required this.code});

  @override
  String toString() => "MockNetworkException: $message (Code: $code)";
}

/// Standardized API Response shape matching typical backend responses
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  final MetaData? meta;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.meta,
  });

  factory ApiResponse.success(T data, {MetaData? meta}) {
    return ApiResponse(
      success: true,
      data: data,
      meta: meta,
    );
  }

  factory ApiResponse.error(String message, {int code = 400}) {
    return ApiResponse(
      success: false,
      error: ApiError(message: message, code: code),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (data != null) 'data': data,
      if (meta != null) 'meta': meta!.toJson(),
      if (error != null) 'error': error!.toJson(),
    };
  }
}

class ApiError {
  final String message;
  final int code;

  ApiError({required this.message, required this.code});

  Map<String, dynamic> toJson() => {
    'message': message,
    'code': code,
  };
}

class MetaData {
  final int page;
  final int total;
  final int totalPages;

  MetaData({required this.page, required this.total, required this.totalPages});

  Map<String, dynamic> toJson() => {
    'page': page,
    'total': total,
    'total_pages': totalPages,
  };
}
