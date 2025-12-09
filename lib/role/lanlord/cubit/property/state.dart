import 'package:equatable/equatable.dart';
import 'package:rentverse/features/property/domain/entity/list_property_by_owner.dart';

enum LandlordPropertyStatus { initial, loading, success, failure }

class LandlordPropertyState extends Equatable {
  final LandlordPropertyStatus status;
  final List<OwnerPropertyEntity> items;
  final String? error;

  const LandlordPropertyState({
    this.status = LandlordPropertyStatus.initial,
    this.items = const [],
    this.error,
  });

  LandlordPropertyState copyWith({
    LandlordPropertyStatus? status,
    List<OwnerPropertyEntity>? items,
    String? error,
  }) {
    return LandlordPropertyState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}
