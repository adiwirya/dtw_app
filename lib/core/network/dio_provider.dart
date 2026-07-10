import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(Ref ref) => Dio(
      // The empty-string default is intentional: it reads API_BASE_URL from
      // --dart-define at build time, which happens to match BaseOptions'
      // own default when undefined.
      // ignore: avoid_redundant_argument_values
      BaseOptions(baseUrl: const String.fromEnvironment('API_BASE_URL')),
    )..interceptors.add(LogInterceptor());
