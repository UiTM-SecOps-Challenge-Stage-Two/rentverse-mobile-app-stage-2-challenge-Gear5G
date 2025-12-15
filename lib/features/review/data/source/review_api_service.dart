import 'package:logger/logger.dart';
import 'package:rentverse/core/network/dio_client.dart';
import 'package:rentverse/core/network/response/base_response_model.dart';

abstract class ReviewApiService {
  Future<BaseResponseModel<Map<String, dynamic>>> submitReview(
    Map<String, dynamic> body,
  );

  Future<BaseResponseModel<Map<String, dynamic>>> getPropertyReviews(
    String propertyId,
    int limit,
    String? cursor,
  );
}

class ReviewApiServiceImpl implements ReviewApiService {
  final DioClient _dioClient;
  ReviewApiServiceImpl(this._dioClient);

  @override
  Future<BaseResponseModel<Map<String, dynamic>>> submitReview(
    Map<String, dynamic> body,
  ) async {
    final response = await _dioClient.post('/reviews', data: body);
    return BaseResponseModel.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  @override
  Future<BaseResponseModel<Map<String, dynamic>>> getPropertyReviews(
    String propertyId,
    int limit,
    String? cursor,
  ) async {
    final q = <String, dynamic>{'limit': limit};
    if (cursor != null) q['cursor'] = cursor;
    final response = await _dioClient.get(
      '/reviews/property/$propertyId',
      queryParameters: q,
    );

    final logger = Logger();
    final respData = response.data;

    // Normalize possible shapes:
    // 1) { status, message, meta, data: [ ... ] }
    // 2) { status, message, meta, data: { items: [...] } }
    // 3) [ ... ] (direct list)
    // We'll return BaseResponseModel where `data` is a Map with keys 'items' and 'meta'.
    List<dynamic> items = [];
    Map<String, dynamic> meta = {};

    try {
      if (respData is Map<String, dynamic>) {
        final maybeData = respData['data'];
        if (maybeData is List) {
          items = maybeData;
        } else if (maybeData is Map) {
          // data might itself contain items/meta
          if (maybeData['items'] is List) {
            items = maybeData['items'] as List<dynamic>;
          } else {
            // fallback: try to interpret keys as item map
            logger.w(
              'Unexpected `data` shape for property reviews: ${maybeData.runtimeType}',
            );
          }
        } else if (respData['items'] is List) {
          items = respData['items'] as List<dynamic>;
        }

        if (respData['meta'] is Map) {
          meta = Map<String, dynamic>.from(respData['meta'] as Map);
        } else if (maybeData is Map && maybeData['meta'] is Map) {
          meta = Map<String, dynamic>.from(maybeData['meta'] as Map);
        }
      } else if (respData is List) {
        items = respData;
      } else {
        logger.w(
          'Unexpected response type for getPropertyReviews: ${respData.runtimeType}',
        );
      }
    } catch (e) {
      logger.e('Failed to normalize reviews response');
    }

    final normalized = {'items': items, 'meta': meta};

    final payload = respData is Map<String, dynamic>
        ? respData
        : {'status': 'success', 'data': normalized};

    return BaseResponseModel.fromJson(payload, (json) => normalized);
  }
}
