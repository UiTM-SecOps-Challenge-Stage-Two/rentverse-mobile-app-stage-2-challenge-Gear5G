import 'package:dio/dio.dart';
import 'package:rentverse/core/resources/data_state.dart';
import '../../domain/repository/review_repository.dart';
import '../source/review_api_service.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewApiService _apiService;

  ReviewRepositoryImpl(this._apiService);

  @override
  Future<DataState<void>> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final body = {
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      };
      final resp = await _apiService.submitReview(body);
      if (resp.status.toLowerCase() == 'success') {
        return const DataSuccess(data: null);
      }
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/reviews'),
          error: resp.message ?? 'Failed',
        ),
      );
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<Map<String, dynamic>>> getPropertyReviews(
    String propertyId,
    int limit,
    String? cursor,
  ) async {
    try {
      final resp = await _apiService.getPropertyReviews(
        propertyId,
        limit,
        cursor,
      );
      if (resp.data != null) {
        // resp.data is expected to be a Map with 'items' and 'meta'
        final raw = resp.data!;
        final items = raw['items'];
        final meta = raw['meta'];

        final normalizedItems = <Map<String, dynamic>>[];
        if (items is List) {
          for (final it in items) {
            if (it is Map<String, dynamic>) {
              normalizedItems.add(it);
            } else if (it is Map) {
              normalizedItems.add(Map<String, dynamic>.from(it));
            }
          }
        }

        final normalizedMeta = <String, dynamic>{};
        if (meta is Map) {
          normalizedMeta.addAll(Map<String, dynamic>.from(meta));
        }

        return DataSuccess(
          data: {'items': normalizedItems, 'meta': normalizedMeta},
        );
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/reviews/property/$propertyId'),
          error: resp.message ?? 'No data',
        ),
      );
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}
