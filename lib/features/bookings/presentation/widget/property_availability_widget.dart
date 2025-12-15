import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentverse/core/services/service_locator.dart';
import 'package:rentverse/features/bookings/domain/usecase/get_property_availability_usecase.dart';
import 'package:logger/logger.dart';

class _AvailabilityItem {
  final DateTime start;
  final DateTime end;
  final String? reason;

  _AvailabilityItem({required this.start, required this.end, this.reason});
}

class PropertyAvailabilityWidget extends StatefulWidget {
  final String propertyId;
  const PropertyAvailabilityWidget({super.key, required this.propertyId});

  @override
  State<PropertyAvailabilityWidget> createState() =>
      _PropertyAvailabilityWidgetState();
}

class _PropertyAvailabilityWidgetState
    extends State<PropertyAvailabilityWidget> {
  bool _loading = false;
  String? _error;
  List<_AvailabilityItem> _ranges = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usecase = sl<GetPropertyAvailabilityUseCase>();
      final logger = Logger();
      final res = await usecase(param: widget.propertyId);

      logger.i(
        'Loaded ${res.length} availability ranges for property ${widget.propertyId}',
      );

      setState(() {
        _ranges = res
            .map(
              (e) => _AvailabilityItem(
                start: e.start,
                end: e.end,
                reason: e.reason,
              ),
            )
            .toList();
      });
    } catch (e, st) {
      Logger().e(
        'Failed to load availability for ${widget.propertyId}: $e\n$st',
      );
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Header Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: const [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Colors.black87,
              ),
              SizedBox(width: 8),
              Text(
                'Unavailable Dates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Loading State
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

        // Error State
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Text(
              'Gagal memuat ketersediaan: $_error',
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),

        // Empty State (Fully Available)
        if (!_loading && _ranges.isEmpty && _error == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Properti tersedia sepenuhnya',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // List Unavailable Dates
        if (_ranges.isNotEmpty)
          SizedBox(
            height: 110, // Sedikit dipertinggi agar layout lebih lega
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Menambah padding di awal dan akhir list agar tidak terpotong
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              itemCount: _ranges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final item = _ranges[idx];
                return Container(
                  width: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // Menggunakan Border, bukan Shadow
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Baris Label "Booked/Unavailable"
                      Row(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 14,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Telah dibooking",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Baris Tanggal
                      Text(
                        '${f.format(item.start)} — ${f.format(item.end)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Baris Alasan (Opsional)
                      if (item.reason != null &&
                          item.reason!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.reason!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
