import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'core/network/dio_client.dart';

import 'services/vitals_service.dart';
import 'services/symptoms_service.dart';
import 'services/illness_service.dart';
import 'services/medications_service.dart';
import 'services/reminders_service.dart';
import 'services/vault_service.dart';

import 'providers/vitals_provider.dart';
import 'providers/symptoms_provider.dart';
import 'providers/illness_provider.dart';
import 'providers/medications_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/vault_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';

import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create a shared Dio instance
  final dio = DioClient.create(baseUrl: ApiConstants.baseUrl);

  runApp(KinsuHealthApp(dio: dio));
}

class KinsuHealthApp extends StatelessWidget {
  final Dio dio;

  const KinsuHealthApp({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VitalsProvider(VitalsService(dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => SymptomsProvider(SymptomsService(dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => IllnessProvider(IllnessService(dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicationsProvider(MedicationsService(dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => RemindersProvider(RemindersService(dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => VaultProvider(VaultService(dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => AppThemeProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Kinsu Health',
            debugShowCheckedModeBanner: false,
            theme: KinsuTheme.lightTheme,
            darkTheme: KinsuTheme.darkTheme,
            themeMode: context.watch<AppThemeProvider>().themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
