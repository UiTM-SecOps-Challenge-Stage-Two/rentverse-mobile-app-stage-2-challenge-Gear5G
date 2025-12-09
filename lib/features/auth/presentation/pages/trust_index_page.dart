import 'dart:math' as math;

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentverse/common/bloc/auth/auth_cubit.dart';
import 'package:rentverse/common/bloc/auth/auth_state.dart';
import 'package:rentverse/common/colors/custom_color.dart';
import 'package:rentverse/features/auth/presentation/cubit/trust_index/cubit.dart';
import 'package:rentverse/features/auth/presentation/cubit/trust_index/state.dart';

class TrustIndexPage extends StatelessWidget {
  const TrustIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = TrustIndexCubit();
        cubit.loadFromAuthState(context.read<AuthCubit>().state);
        // Ensure fresh data from /auth/me
        cubit.refreshFromApi();

        // Log current auth/me fetch for debugging
        try {
          final authState = context.read<AuthCubit>().state;
          if (authState is Authenticated) {
            final user = authState.user;
            developer.log(
              'TrustIndex - fetched auth/me',
              name: 'TrustIndexPage',
            );
            developer.log('user.id: ${user.id}', name: 'TrustIndexPage');
            developer.log(
              'roles: ${user.roles?.map((r) => r.role?.name).toList()}',
              name: 'TrustIndexPage',
            );
            developer.log(
              'tenant.ttiScore: ${user.tenantProfile?.ttiScore}',
              name: 'TrustIndexPage',
            );
            developer.log(
              'landlord.lrsScore: ${user.landlordProfile?.lrsScore}',
              name: 'TrustIndexPage',
            );
          } else {
            developer.log(
              'Auth state (not authenticated): $authState',
              name: 'TrustIndexPage',
            );
          }
        } catch (e, st) {
          developer.log(
            'Error while logging auth state: $e',
            name: 'TrustIndexPage',
            error: e,
            stackTrace: st,
          );
        }

        return cubit;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Trust Index'),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: BlocBuilder<TrustIndexCubit, TrustIndexState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ScoreCard(score: state.trustScore),
                  const SizedBox(height: 16),
                  _ReviewsHeader(
                    rating: state.rating,
                    count: state.reviewCount,
                  ),
                  const SizedBox(height: 12),
                  ...state.reviews.map((r) => _ReviewCard(review: r)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});

  final double score;

  // Definisi warna agar sesuai dengan gambar referensi
  // Warna hijau mint cerah
  static const Color _mintGreen = Color(0xFF00FCA8);
  // Warna background abu-abu terang untuk track lingkaran
  static const Color _trackColor = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    // Pastikan score di antara 0 dan 100
    final double clampedScore = score.clamp(0, 100);
    final double percentage = clampedScore / 100;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Trust Index',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Menggunakan CustomPaint sebagai pengganti CircularProgressIndicator
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _CircularProgressBarPainter(
                      percentage: percentage,
                      strokeWidth: 24,
                      color: _mintGreen,
                      backgroundColor: _trackColor,
                    ),
                  ),
                  // Teks Angka di tengah
                  Text(
                    clampedScore.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 48, // Ukuran font lebih besar
                      fontWeight: FontWeight.bold,
                      color: _mintGreen, // Warna teks mengikuti warna progress
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressBarPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  _CircularProgressBarPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    // Radius dihitung agar stroke tidak terpotong di pinggir widget
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // 1. Gambar Track Latar Belakang (Lingkaran Abu-abu Penuh)
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      // StrokeCap.round membuat ujung lingkaran membulat
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 2. Gambar Progress Arc (Busur Hijau)
    final Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      // KUNCI UTAMA: StrokeCap.round membuat ujung busur membulat
      ..strokeCap = StrokeCap.round;

    // Menghitung sudut sapuan berdasarkan persentase
    final double sweepAngle = 2 * math.pi * percentage;
    // Mulai dari -pi/2 (jam 12 tepat)
    const double startAngle = -math.pi / 2;

    // Menggambar busur
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false, // useCenter false agar jadi cincin, bukan potongan pie
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressBarPainter oldDelegate) {
    // Gambar ulang jika persentase atau warna berubah
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}

class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reviews from Owner',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Text('($count) Tenant Assessment'),
              ],
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text('View All', style: TextStyle(color: appPrimaryColor)),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final TrustReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  review.reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _RatingStars(rating: review.rating),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PropertyThumb(imageUrl: review.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.propertyTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            review.city,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        review.priceLabel,
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment, style: const TextStyle(height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          Icons.star,
          size: 16,
          color: index < rating.round() ? Colors.amber : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _PropertyThumb extends StatelessWidget {
  const _PropertyThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 96,
        height: 72,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}

class _InfoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.bed_outlined, size: 14, color: Colors.grey),
        SizedBox(width: 4),
        Text('3'),
        SizedBox(width: 10),
        Icon(Icons.bathtub_outlined, size: 14, color: Colors.grey),
        SizedBox(width: 4),
        Text('1'),
        SizedBox(width: 10),
        Icon(Icons.square_foot, size: 14, color: Colors.grey),
        SizedBox(width: 4),
        Text('500 Sqft'),
      ],
    );
  }
}
