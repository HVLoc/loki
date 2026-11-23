import 'package:dio/dio.dart';

/// Reserved HTTP client per Constitution Technical Constraints.
class DioClient {
  DioClient({String? baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? '',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  final Dio dio;
}
