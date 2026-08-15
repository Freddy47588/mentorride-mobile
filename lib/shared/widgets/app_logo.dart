import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Logo MentorRide',
      child: Image.asset(
        'assets/images/mentorride_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}
