import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KinsuHealthApp());
}

class KinsuHealthApp extends StatelessWidget {
  const KinsuHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinsu Health',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const HomeScreen(),
    );
  }
}
