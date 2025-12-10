import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentverse/core/constant/api_urls.dart';
import 'package:rentverse/features/bookings/domain/entity/res/booking_response_entity.dart';
import 'package:rentverse/role/tenant/presentation/widget/midtrans/card_property.dart';
import 'package:rentverse/role/tenant/presentation/widget/receipt_booking/property_rent_details.dart';
import 'package:rentverse/role/tenant/presentation/pages/rent/midtrans_payment_snap_page.dart';

class MidtransPaymentPage extends StatefulWidget {
  const MidtransPaymentPage({
    super.key,
    required this.booking,
    required this.redirectUrl,
    required this.snapToken,
    required this.clientKey,
  });

  final BookingResponseEntity booking;
  final String redirectUrl;
  final String snapToken;
  final String clientKey;

  @override
  State<MidtransPaymentPage> createState() => _MidtransPaymentPageState();
}

class _MidtransPaymentPageState extends State<MidtransPaymentPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final billingPeriodLabel = booking.billingPeriod?.label ?? 'Monthly';
    final priceLabel = _formatCurrency(booking.amount, booking.currency);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardProperty(
              property: booking.property,
              billingPeriod: billingPeriodLabel,
              startDate: booking.checkIn,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Property & Rent Details',
              child: PropertyRentDetailsCard(
                location: booking.property?.address ?? '-',
                startDate: _fmtDate(booking.checkIn),
                billingPeriod: billingPeriodLabel,
                propertyType: booking.property?.title ?? '-',
                priceLabel: priceLabel,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total Price',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                priceLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF00B0FF),
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1CD8D2), Color(0xFF0097F6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _openSnap,
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSnap() async {
    final clientKey = widget.clientKey.isNotEmpty
        ? widget.clientKey
        : ApiConstants.midtransClientKey;

    if (widget.snapToken.isEmpty || clientKey.isEmpty) {
      _showSnack('Token atau client key tidak valid');
      return;
    }

    setState(() => _isProcessing = true);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MidtransPaymentSnapPage(
          token: widget.snapToken,
          clientKey: clientKey,
          redirectUrl: widget.redirectUrl,
        ),
      ),
    );

    if (mounted) setState(() => _isProcessing = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

String _fmtDate(DateTime? date) {
  if (date == null) return '-';
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatCurrency(int amount, String currency) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: currency.isEmpty ? 'Rp ' : '$currency ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}
