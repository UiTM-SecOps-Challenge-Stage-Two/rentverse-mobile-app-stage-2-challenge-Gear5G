import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentverse/core/resources/data_state.dart';
import 'package:rentverse/features/auth/domain/entity/update_profile_request_entity.dart';
import 'package:rentverse/features/auth/domain/entity/user_entity.dart';
import 'package:rentverse/features/auth/domain/usecase/get_local_user_usecase.dart';
import 'package:rentverse/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:rentverse/features/auth/domain/usecase/update_profile_usecase.dart';
import 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(
    this._getLocalUserUseCase,
    this._getUserUseCase,
    this._updateProfileUseCase,
  ) : super(EditProfileState.initial());

  final GetLocalUserUseCase _getLocalUserUseCase;
  final GetUserUseCase _getUserUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true, resetError: true, resetMessage: true));
    UserEntity? user;

    final remote = await _getUserUseCase();
    if (remote is DataSuccess<UserEntity> && remote.data != null) {
      user = remote.data;
    } else {
      user = await _getLocalUserUseCase();
    }

    final name = user?.name ?? '';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final emailVerified = user?.emailVerifiedAt != null;
    final phoneVerified = user?.phoneVerifiedAt != null;
    final kycStatus =
        user?.tenantProfile?.kycStatus ??
        user?.landlordProfile?.kycStatus ??
        '';

    emit(
      state.copyWith(
        isLoading: false,
        user: user,
        nameValue: name,
        emailValue: email,
        phoneValue: phone,
        isEmailVerified: emailVerified,
        isPhoneVerified: phoneVerified,
        kycStatus: kycStatus,
        error: user == null && remote is DataFailed<UserEntity>
            ? remote.error?.message
            : null,
        resetMessage: true,
      ),
    );
  }

  void setName(String value) {
    emit(
      state.copyWith(nameValue: value, resetMessage: true, resetError: true),
    );
  }

  void setPhone(String value) {
    emit(
      state.copyWith(phoneValue: value, resetMessage: true, resetError: true),
    );
  }

  void setEmail(String value) {
    emit(
      state.copyWith(emailValue: value, resetMessage: true, resetError: true),
    );
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    emit(state.copyWith(isSaving: true, resetError: true, resetMessage: true));
    final result = await _updateProfileUseCase(
      param: UpdateProfileRequestEntity(
        name: name ?? state.nameValue,
        phone: phone ?? state.phoneValue,
      ),
    );

    if (result is DataSuccess<UserEntity>) {
      final updatedUser = result.data ?? state.user;
      emit(
        state.copyWith(
          isSaving: false,
          user: updatedUser,
          nameValue: updatedUser?.name ?? state.nameValue,
          emailValue: updatedUser?.email ?? state.emailValue,
          phoneValue: updatedUser?.phone ?? state.phoneValue,
          isEmailVerified:
              (updatedUser?.emailVerifiedAt != null) || state.isEmailVerified,
          isPhoneVerified:
              (updatedUser?.phoneVerifiedAt != null) || state.isPhoneVerified,
          kycStatus:
              updatedUser?.tenantProfile?.kycStatus ??
              updatedUser?.landlordProfile?.kycStatus ??
              state.kycStatus,
          successMessage: 'Profile updated successfully',
        ),
      );
    } else if (result is DataFailed<UserEntity>) {
      emit(
        state.copyWith(
          isSaving: false,
          error: result.error?.message ?? 'Update profile failed',
        ),
      );
    } else {
      emit(state.copyWith(isSaving: false, error: 'Unknown error'));
    }
  }
}
