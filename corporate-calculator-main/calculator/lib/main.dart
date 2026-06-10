import 'package:flutter/material.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/router/app_router.dart';
import 'package:calculator/core/theme/app_styles.dart';

void main() {
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Калькулятор',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyles.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppStyles.background,
        appBarTheme: AppStyles.appBarTheme,
        cardTheme: AppStyles.cardTheme,
      ),
      routerConfig: appRouter,
    );
  }
}
