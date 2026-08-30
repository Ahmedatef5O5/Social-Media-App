import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import '../models/gif_result_model.dart';

class GiphyServices {
  GiphyServices._();
  static final GiphyServices instance = GiphyServices._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.giphy.com/v1/gifs',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<GifResult>> trending({int limit = 24, int offset = 0}) {
    return _request('/trending', {'offset': offset}, limit: limit);
  }

  Future<List<GifResult>> search(
    String query, {
    int limit = 24,
    int offset = 0,
  }) {
    if (query.trim().isEmpty) return trending(limit: limit, offset: offset);
    return _request('/search', {'q': query, 'offset': offset}, limit: limit);
  }

  Future<List<GifResult>> _request(
    String path,
    Map<String, dynamic> extraParams, {
    required int limit,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: {
          'api_key': AppSecrets.giphyApiKey,
          'limit': limit,
          'rating': 'pg-13',
          ...extraParams,
        },
      );

      final data = response.data['data'] as List<dynamic>;
      return data
          .map((e) => GifResult.fromGiphyJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Giphy request failed: $e');
      rethrow;
    }
  }
}
