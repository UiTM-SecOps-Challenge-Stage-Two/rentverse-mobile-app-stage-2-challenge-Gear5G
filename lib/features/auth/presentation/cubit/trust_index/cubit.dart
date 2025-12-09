import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentverse/common/bloc/auth/auth_state.dart';
import 'package:rentverse/core/resources/data_state.dart';
import 'package:rentverse/core/services/service_locator.dart';
import 'package:rentverse/features/auth/domain/entity/user_entity.dart';
import 'package:rentverse/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:rentverse/features/auth/presentation/cubit/trust_index/state.dart';

class TrustIndexCubit extends Cubit<TrustIndexState> {
  TrustIndexCubit() : super(const TrustIndexState());

  GetUserUseCase get _getUserUseCase => sl<GetUserUseCase>();

  void loadFromAuthState(AuthState authState) {
    if (authState is! Authenticated) return;

    final UserEntity user = authState.user;
    final double score = _scoreFromUser(user);
    _emitWithScore(score, user);
  }

  Future<void> refreshFromApi() async {
    emit(state.copyWith(isLoading: true));

    final result = await _getUserUseCase();
    if (result is DataSuccess<UserEntity> && result.data != null) {
      final user = result.data!;
      final double score = _scoreFromUser(user);
      _emitWithScore(score, user);
    } else {
      emit(state.copyWith(isLoading: false, error: 'Failed to load profile'));
    }
  }

  double _scoreFromUser(UserEntity user) {
    // Prefer landlord LRS when landlord role + data exists; otherwise tenant TTI; fallback to any available score.
    if (user.isLandlord && user.landlordProfile?.lrsScore != null) {
      return user.landlordProfile!.lrsScore;
    }
    if (user.isTenant && user.tenantProfile?.ttiScore != null) {
      return user.tenantProfile!.ttiScore;
    }
    return user.landlordProfile?.lrsScore ?? user.tenantProfile?.ttiScore ?? 0;
  }

  void _emitWithScore(double score, UserEntity user) {
    developer.log(
      'TrustIndexCubit score=$score (isTenant=${user.isTenant}, isLandlord=${user.isLandlord}, tti=${user.tenantProfile?.ttiScore}, lrs=${user.landlordProfile?.lrsScore})',
      name: 'TrustIndex',
    );

    const double avgRating = 4.5;
    const int totalReviews = 7;
    final reviews = _mockReviews();

    emit(
      state.copyWith(
        trustScore: score,
        rating: avgRating,
        reviewCount: totalReviews,
        reviews: reviews,
        isLoading: false,
        resetError: true,
      ),
    );
  }

  List<TrustReview> _mockReviews() {
    return const [
      TrustReview(
        reviewerName: 'Jackson',
        rating: 4.5,
        propertyTitle: 'Joane Residence',
        city: 'Kuala Lumpur',
        priceLabel: 'Rp1.000.000/mon',
        comment:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        imageUrl:
            'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=800&q=60',
      ),
      TrustReview(
        reviewerName: 'Jackson',
        rating: 4.5,
        propertyTitle: 'Joane Residence',
        city: 'Kuala Lumpur',
        priceLabel: 'Rp1.000.000/mon',
        comment:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        imageUrl:
            'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=800&q=60',
      ),
    ];
  }
}
