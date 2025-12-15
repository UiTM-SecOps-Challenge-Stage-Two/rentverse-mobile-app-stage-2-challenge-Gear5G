import 'package:flutter/material.dart';
import 'package:rentverse/common/utils/network_utils.dart';
import 'package:rentverse/common/widget/pull_to_refresh.dart';
import 'package:rentverse/core/services/service_locator.dart';
import 'package:rentverse/features/review/domain/usecase/get_property_reviews_usecase.dart';
import 'package:rentverse/core/resources/data_state.dart';

class PropertyReviewsWidget extends StatefulWidget {
  final String propertyId;
  const PropertyReviewsWidget({super.key, required this.propertyId});

  @override
  State<PropertyReviewsWidget> createState() => _PropertyReviewsWidgetState();
}

class _PropertyReviewsWidgetState extends State<PropertyReviewsWidget> {
  List<dynamic> _items = [];
  String? _cursor;
  bool _hasMore = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    if (_loading) return;
    setState(() {
      _items = [];
      _cursor = null;
      _hasMore = false;
    });
    await _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final usecase = sl<GetPropertyReviewsUseCase>();
      final params = GetPropertyReviewsParams(
        propertyId: widget.propertyId,
        limit: 5,
        cursor: _cursor,
      );
      final res = await usecase.call(param: params);
      if (res is DataSuccess<Map<String, dynamic>> && res.data != null) {
        final map = res.data as Map<String, dynamic>;
        final items = map['items'] as List<dynamic>? ?? [];
        final meta = map['meta'] as Map<String, dynamic>? ?? {};
        // Ensure items are maps and safe to render
        final safeItems = <Map<String, dynamic>>[];
        for (final it in items) {
          if (it is Map<String, dynamic>) {
            safeItems.add(it);
          } else if (it is Map) {
            safeItems.add(Map<String, dynamic>.from(it));
          }
        }
        setState(() {
          _items.addAll(safeItems);
          _cursor = meta['nextCursor'] as String?;
          _hasMore = meta['hasMore'] == true;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter only tenant reviews (role == TENANT)
    final tenantItems = _items.where((it) {
      final role = (it['role'] as String?) ?? '';
      return role.toUpperCase() == 'TENANT';
    }).toList();

    return NotificationListener<ReloadDataNotification>(
      onNotification: (_) {
        _refreshAll();
        return true;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          final nearBottom = metrics.extentAfter < 150;
          if (nearBottom && _hasMore && !_loading) {
            _load();
          }
          return false;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (tenantItems.isEmpty && !_loading)
              const Text(
                'BELUM ADA NILAI',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            for (final it in tenantItems) ...[
              _buildReviewItem(it),
              const SizedBox(height: 8),
            ],
            if (_hasMore)
              Center(
                child: TextButton(
                  onPressed: _loading ? null : _load,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Load more'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(dynamic it) {
    final reviewer = it['reviewer'] as Map<String, dynamic>?;
    final reviewerName = reviewer != null
        ? (reviewer['name'] ?? 'User')
        : 'User';
    final avatarRaw = reviewer != null
        ? reviewer['avatarUrl'] as String?
        : null;
    final avatar = makeDeviceAccessibleUrl(avatarRaw) ?? avatarRaw;
    final rating = it['rating']?.toString() ?? '0';
    final comment = it['comment'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
          child: avatar == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    reviewerName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text('· $rating', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              if ((comment as String).isNotEmpty) Text(comment),
            ],
          ),
        ),
      ],
    );
  }
}
