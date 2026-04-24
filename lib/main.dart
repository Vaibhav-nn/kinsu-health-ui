import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/health_connect_sync_registry.dart';
import 'core/network/dio_client.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'firebase_options.dart';
import 'providers/family_provider.dart';
import 'providers/health_sync_provider.dart';
import 'providers/illness_provider.dart';
import 'providers/medications_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/symptoms_provider.dart';
import 'providers/vault_provider.dart';
import 'providers/vitals_provider.dart';
import 'services/exercise_service.dart';
import 'services/family_service.dart';
import 'services/health_connect_service.dart';
import 'services/home_service.dart';
import 'services/illness_service.dart';
import 'services/medications_service.dart';
import 'services/reminders_service.dart';
import 'services/symptoms_service.dart';
import 'services/vault_service.dart';
import 'services/vitals_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppFlags.disableAuth) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final dio = DioClient.create(baseUrl: ApiConstants.baseUrl);
  runApp(KinsuHealthApp(dio: dio, prefs: prefs));
}

class KinsuHealthApp extends StatefulWidget {
  final Dio dio;
  final SharedPreferences prefs;

  const KinsuHealthApp({super.key, required this.dio, required this.prefs});

  @override
  State<KinsuHealthApp> createState() => _KinsuHealthAppState();
}

class _KinsuHealthAppState extends State<KinsuHealthApp> {
  // Pre-created so they can be wired together before MultiProvider sees them.
  late final HealthConnectService _hcService;
  late final HCSyncRegistry _registry;
  late final VitalsProvider _vitalsProvider;
  late final ExerciseService _exerciseService;
  late final HealthSyncProvider _healthSyncProvider;

  @override
  void initState() {
    super.initState();
    _hcService = HealthConnectService();
    _registry = HCSyncRegistry(widget.prefs);
    _vitalsProvider = VitalsProvider(VitalsService(widget.dio));
    _exerciseService = ExerciseService(widget.dio);
    _healthSyncProvider = HealthSyncProvider(
      hcService: _hcService,
      registry: _registry,
      vitalsProvider: _vitalsProvider,
      exerciseService: _exerciseService,
      prefs: widget.prefs,
    );
    // Fire-and-forget — init checks availability and loads prefs asynchronously.
    _healthSyncProvider.init();
  }

  @override
  void dispose() {
    _vitalsProvider.dispose();
    _healthSyncProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HomeService>.value(value: HomeService(widget.dio)),
        // ExerciseService pre-created so HealthSyncProvider can wire HC into it.
        Provider<ExerciseService>.value(value: _exerciseService),
        // VitalsProvider pre-created so HealthSyncProvider can wire HC into it.
        ChangeNotifierProvider<VitalsProvider>.value(value: _vitalsProvider),
        // HealthSyncProvider orchestrates HC availability, permissions, and import.
        ChangeNotifierProvider<HealthSyncProvider>.value(
            value: _healthSyncProvider),
        ChangeNotifierProvider(
          create: (_) => SymptomsProvider(SymptomsService(widget.dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => IllnessProvider(IllnessService(widget.dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicationsProvider(MedicationsService(widget.dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => RemindersProvider(RemindersService(widget.dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => VaultProvider(VaultService(widget.dio)),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              FamilyProvider(FamilyService(widget.dio))..loadFamilyData(),
        ),
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<AppThemeProvider>().themeMode;
          return MaterialApp(
            title: 'Kinsu Health',
            debugShowCheckedModeBanner: false,
            theme: KinsuTheme.lightTheme,
            darkTheme: KinsuTheme.darkTheme,
            themeMode: themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
