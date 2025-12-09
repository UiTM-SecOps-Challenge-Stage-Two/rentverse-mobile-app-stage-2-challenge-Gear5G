import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rentverse/core/services/service_locator.dart';
import 'package:rentverse/features/property/domain/entity/list_property_by_owner.dart';
import 'package:rentverse/role/lanlord/cubit/property/cubit.dart';
import 'package:rentverse/role/lanlord/cubit/property/state.dart';

class LandlordPropertyPage extends StatelessWidget {
  const LandlordPropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: BlocProvider(
        create: (_) => LandlordPropertyCubit(sl())..load(),
        child: const _LandlordPropertyView(),
      ),
    );
  }
}

class _LandlordPropertyView extends StatelessWidget {
  const _LandlordPropertyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Property',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Color(0xFF1CD8D2),
          labelColor: Color(0xFF1CD8D2),
          unselectedLabelColor: Colors.black,
          tabs: [
            Tab(text: 'Submission'),
            Tab(text: 'My Listing'),
            Tab(text: 'Request'),
            Tab(text: 'Payment'),
          ],
        ),
      ),
      body: TabBarView(
        children: const [
          _SubmissionTab(),
          _ListingTab(),
          _PlaceholderTab(label: 'Request'),
          _PlaceholderTab(label: 'Payment'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1CD8D2),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SubmissionTab extends StatelessWidget {
  const _SubmissionTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandlordPropertyCubit, LandlordPropertyState>(
      builder: (context, state) {
        if (state.status == LandlordPropertyStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == LandlordPropertyStatus.failure) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.error ?? 'Failed to load properties'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<LandlordPropertyCubit>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.items.isEmpty) {
          return const Center(child: Text('No submissions yet'));
        }

        final submissions = state.items
            .where((item) => !item.isVerified)
            .toList();

        if (submissions.isEmpty) {
          return const Center(child: Text('No submissions yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: submissions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = submissions[index];
            return _PropertyCard(item: item);
          },
        );
      },
    );
  }
}

class _ListingTab extends StatelessWidget {
  const _ListingTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandlordPropertyCubit, LandlordPropertyState>(
      builder: (context, state) {
        if (state.status == LandlordPropertyStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == LandlordPropertyStatus.failure) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.error ?? 'Failed to load properties'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<LandlordPropertyCubit>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final listings = state.items.where((item) => item.isVerified).toList();

        if (listings.isEmpty) {
          return const Center(child: Text('No listings yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = listings[index];
            return _PropertyCard(item: item);
          },
        );
      },
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.item});

  final OwnerPropertyEntity item;

  @override
  Widget build(BuildContext context) {
    final priceText = _formatCurrency(item.currency, item.price);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!item.isVerified) ...[
            Row(
              children: const [
                Icon(Icons.access_time, size: 18, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  'Waiting for Admin approval',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.image ??
                      'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=600&q=80',
                  width: 110,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.city,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$priceText /mon',
                      style: const TextStyle(
                        color: Color(0xFF00BFA6),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoBadge(
                          icon: Icons.home_work_outlined,
                          label: item.type,
                        ),
                        const SizedBox(width: 12),
                        _InfoBadge(
                          icon: Icons.bookmark_added_outlined,
                          label: '${item.stats.totalBookings}',
                        ),
                        const SizedBox(width: 12),
                        _InfoBadge(
                          icon: item.isVerified
                              ? Icons.verified
                              : Icons.verified_outlined,
                          label: item.isVerified ? 'Verified' : 'Unverified',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$label is coming soon'));
  }
}

String _formatCurrency(String currency, num amount) {
  try {
    final symbol = currency.toUpperCase() == 'IDR' ? 'Rp' : currency;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: symbol.isNotEmpty ? '$symbol ' : 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  } catch (_) {
    return '$currency $amount';
  }
}
