import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mentorride/app/theme/app_theme.dart';

class MentorRideApp extends StatelessWidget {
  const MentorRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MentorRide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        body: Center(child: Text('Menyiapkan MentorRide...')),
      ),
    );
  }
}
