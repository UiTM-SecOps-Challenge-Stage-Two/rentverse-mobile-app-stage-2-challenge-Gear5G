import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentverse/common/colors/custom_color.dart';
import 'package:rentverse/core/services/service_locator.dart';
import 'package:rentverse/features/auth/presentation/cubit/edit_profile/edit_profile_cubit.dart';
import 'package:rentverse/features/auth/presentation/cubit/edit_profile/edit_profile_state.dart';
import 'package:rentverse/features/auth/presentation/widget/custom_text_field.dart';
import 'package:rentverse/features/auth/presentation/screen/verify_ikyc_screen.dart';
import 'package:rentverse/features/auth/presentation/screen/otp_verification_screen.dart';
import 'package:rentverse/features/auth/domain/usecase/send_otp_usecase.dart';
import 'package:rentverse/core/resources/data_state.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditProfileCubit(sl(), sl(), sl())..loadProfile(),
      child: BlocConsumer<EditProfileCubit, EditProfileState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<EditProfileCubit>();
          final hasPhone = state.phoneValue.isNotEmpty;
          final isKycSubmitted = state.kycStatus.toUpperCase() == 'SUBMITTED';

          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit User Profile'),
              centerTitle: false,
            ),
            body: SafeArea(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Name',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: 'Full Name',
                            initialValue: state.nameValue,
                            onChanged: cubit.setName,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Email',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: 'Email',
                            initialValue: state.emailValue,
                            onChanged: cubit.setEmail,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.grey,
                            ),
                            suffixIcon: TextButton(
                              onPressed: state.isEmailVerified
                                  ? null
                                  : () async {
                                      final target = state.emailValue;
                                      if (target.isEmpty) return;

                                      // send OTP then navigate to verification screen
                                      final sendUsecase = sl<SendOtpUseCase>();
                                      final params = SendOtpParams(
                                        target: target,
                                        channel: 'EMAIL',
                                      );
                                      final res = await sendUsecase.call(
                                        param: params,
                                      );
                                      if (res is DataSuccess<bool>) {
                                        final verified =
                                            await Navigator.of(
                                              context,
                                            ).push<bool>(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    OtpVerificationScreen(
                                                      target: target,
                                                      channel: 'EMAIL',
                                                    ),
                                              ),
                                            );

                                        if (verified == true) {
                                          // refresh profile on return
                                          cubit.loadProfile();
                                        }
                                      } else if (res is DataFailed) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to send OTP: ${res.error}',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: Text(
                                'Verify',
                                style: TextStyle(
                                  color: state.isEmailVerified
                                      ? Colors.grey
                                      : appSecondaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          state.isEmailVerified
                              ? Row(
                                  children: [
                                    const GradientCheck(),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Email verified',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  "Your email hasn't been verified yet",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                          const SizedBox(height: 20),
                          Text(
                            'Phone Number',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: '+62',
                            initialValue: state.phoneValue,
                            keyboardType: TextInputType.phone,
                            onChanged: cubit.setPhone,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: Colors.grey,
                            ),
                            suffixIcon: TextButton(
                              onPressed: () async {
                                final target = state.phoneValue;
                                if (target.isEmpty) return;

                                final sendUsecase = sl<SendOtpUseCase>();
                                final params = SendOtpParams(
                                  target: target,
                                  channel: 'WHATSAPP',
                                );
                                final res = await sendUsecase.call(
                                  param: params,
                                );
                                if (res is DataSuccess<bool>) {
                                  final verified = await Navigator.of(context)
                                      .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => OtpVerificationScreen(
                                            target: target,
                                            channel: 'WHATSAPP',
                                          ),
                                        ),
                                      );

                                  if (verified == true) {
                                    cubit.loadProfile();
                                  }
                                } else if (res is DataFailed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to send OTP: ${res.error}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                hasPhone && !state.isPhoneVerified
                                    ? 'Verify'
                                    : 'Add',
                                style: const TextStyle(
                                  color: appSecondaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          hasPhone
                              ? state.isPhoneVerified
                                    ? Row(
                                        children: [
                                          const GradientCheck(),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Phone number verified',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Phone number not verified',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      )
                              : const Text(
                                  'No phone number',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                          const SizedBox(height: 20),
                          Text(
                            'ID Card',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (isKycSubmitted) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: appSecondaryColor),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.hourglass_bottom,
                                    color: appSecondaryColor,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Menunggu verifikasi admin untuk KYC kamu.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Kami akan memberi tahu setelah verifikasi selesai.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ] else ...[
                            CustomTextField(
                              hintText: 'ID',
                              readOnly: true,
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: Colors.grey,
                              ),
                              suffixIcon: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const VerifyIKycScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Add'),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'You have not added an ID card',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.isSaving
                                  ? null
                                  : () {
                                      context
                                          .read<EditProfileCubit>()
                                          .updateProfile();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appPrimaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: state.isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class GradientCheck extends StatelessWidget {
  const GradientCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => customLinearGradient.createShader(bounds),
      child: const Icon(Icons.check_circle, color: Colors.white, size: 16),
    );
  }
}
