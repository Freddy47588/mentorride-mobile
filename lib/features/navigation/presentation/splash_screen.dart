import 'package:flutter/material.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/shared/widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
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
              SizedBox(height: 28),
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Menyiapkan aplikasi...'),
            ],
          ),
        ),
      ),
    );
  }
}
