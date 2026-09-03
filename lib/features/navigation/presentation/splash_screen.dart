import 'package:flutter/material.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/shared/widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.96 + (0.04 * value),
                      child: child,
                    ),
                  );
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogo(size: 112),
                    SizedBox(height: 20),
                    Text(
                      'MentorRide',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Menyiapkan aplikasi...'),
            ],
          ),
        ),
      ),
    );
  }
}
