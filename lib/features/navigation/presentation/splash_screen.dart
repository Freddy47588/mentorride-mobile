import 'package:flutter/material.dart';
import 'package:mentorride/app/theme/app_theme.dart';

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
              Icon(
                Icons.two_wheeler_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              SizedBox(height: 20),
              Text(
                'MentorRide',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
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
