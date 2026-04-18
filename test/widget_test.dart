import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:kinsu_health/models/home_models.dart';
import 'package:kinsu_health/providers/family_provider.dart';
import 'package:kinsu_health/providers/illness_provider.dart';
import 'package:kinsu_health/providers/medications_provider.dart';
import 'package:kinsu_health/providers/reminders_provider.dart';
import 'package:kinsu_health/providers/theme_provider.dart';
import 'package:kinsu_health/providers/vault_provider.dart';
import 'package:kinsu_health/providers/vitals_provider.dart';
import 'package:kinsu_health/screens/home/home_screen.dart';
import 'package:kinsu_health/screens/shell/main_shell.dart';
import 'package:kinsu_health/screens/track/illness/illness_list_screen.dart';
import 'package:kinsu_health/screens/track/medications/add_medication_screen.dart';
import 'package:kinsu_health/screens/track/reminders/add_reminder_screen.dart';
import 'package:kinsu_health/screens/track/vitals/vitals_trends_screen.dart';
import 'package:kinsu_health/services/family_service.dart';
import 'package:kinsu_health/services/home_service.dart';
import 'package:kinsu_health/services/illness_service.dart';
import 'package:kinsu_health/services/medications_service.dart';
import 'package:kinsu_health/services/reminders_service.dart';
import 'package:kinsu_health/services/vault_service.dart';
import 'package:kinsu_health/services/vitals_service.dart';

/// Minimal go_router that wraps [MainShell] for unit tests.
/// Uses 5 empty branches matching production branch indices.
GoRouter _testShellRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (_, __) => const SizedBox()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/track', builder: (_, __) => const SizedBox()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/vault', builder: (_, __) => const SizedBox()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/family', builder: (_, __) => const SizedBox()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/ai', builder: (_, __) => const SizedBox()),
            ]),
          ],
        ),
      ],
    );

Dio _testDio() {
  return Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:9',
      connectTimeout: const Duration(milliseconds: 25),
      receiveTimeout: const Duration(milliseconds: 25),
      sendTimeout: const Duration(milliseconds: 25),
    ),
  );
}

class _FakeHomeService extends HomeService {
  _FakeHomeService() : super(_testDio());

  @override
  Future<HomeOverviewData> fetchOverview() async {
    return const HomeOverviewData(
      searchPlaceholder: 'Search records...',
      notificationUnreadCount: 1,
      themeMode: 'light',
      profile: HomeTopBarProfileData(
        displayName: 'QA User',
        email: 'qa@test.com',
        initials: 'QU',
      ),
      activeProfileType: 'self',
      activeProfileId: null,
      activeProfileLabel: null,
    );
  }

  @override
  Future<HomeDashboardData> fetchDashboard() async {
    return HomeDashboardData(
      streakDay: 4,
      aiAlert: null,
      appointments: <HomeAppointmentCardData>[
        HomeAppointmentCardData(
          id: 1,
          doctorName: 'Dr. QA Kapoor',
          specialty: 'Cardiologist',
          appointmentAt: DateTime(2026, 4, 11, 10, 30),
          location: 'Apollo Hospital',
          status: 'scheduled',
          notes: 'Bring reports',
        ),
      ],
      medicationsTaken: 0,
      medicationsMissed: 0,
      medicationsLeft: 0,
      medicationItems: const <HomeMedicationStatusItem>[],
      insights: const <HomeInsightCardData>[],
      recentRecords: const <HomeRecentRecordData>[],
      notifications: const <HomeNotificationItem>[],
    );
  }
}

void main() {
  testWidgets('Main shell renders all bottom tabs',
      (WidgetTester tester) async {
    final dio = _testDio();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => VitalsProvider(VitalsService(dio))),
        ChangeNotifierProvider(
            create: (_) => MedicationsProvider(MedicationsService(dio))),
        ChangeNotifierProvider(create: (_) => VaultProvider(VaultService(dio))),
        ChangeNotifierProvider(
            create: (_) => FamilyProvider(FamilyService(dio))),
      ],
      child: MaterialApp.router(routerConfig: _testShellRouter()),
    ));

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('HOME'), findsWidgets);
    expect(find.text('VAULT'), findsWidgets);
    expect(find.text('TRACK'), findsWidgets);
    expect(find.text('AI'), findsWidgets);
  });

  testWidgets('Vitals trends opens log vital screen',
      (WidgetTester tester) async {
    final dio = _testDio();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VitalsProvider(VitalsService(dio)),
        child: const MaterialApp(home: VitalsTrendsScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Vitals Trends'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Log Vital'));
    await tester.pumpAndSettle();

    expect(find.text('Log Vitals'), findsWidgets);
    expect(find.text('Blood Pressure'), findsOneWidget);
  });

  testWidgets('Illness list shows add episode inner sheet',
      (WidgetTester tester) async {
    final dio = _testDio();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => IllnessProvider(IllnessService(dio)),
        child: const MaterialApp(home: IllnessListScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Illness Episodes'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'New Episode'),
        findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New Episode'));
    await tester.pumpAndSettle();

    expect(find.text('New Illness Episode'), findsOneWidget);
    expect(find.text('Create Episode'), findsOneWidget);
  });

  testWidgets('Add medication and add reminder screens render core fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddMedicationScreen()));
    await tester.pump();

    expect(find.text('Log Medicine'), findsOneWidget);
    expect(find.text('MEDICINE NAME'), findsOneWidget);
    expect(find.text('WHEN TO TAKE'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: AddReminderScreen()));
    await tester.pump();

    expect(find.textContaining('What would you like'), findsOneWidget);
    expect(find.text('Doctor\nConsultation'), findsOneWidget);
    expect(find.text('Medicine'), findsOneWidget);
  });

  testWidgets('Home appointments open inner overview sheet',
      (WidgetTester tester) async {
    final dio = _testDio();
    await tester.binding.setSurfaceSize(const Size(1440, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<HomeService>.value(value: _FakeHomeService()),
          ChangeNotifierProvider(create: (_) => AppThemeProvider()),
          ChangeNotifierProvider(
              create: (_) => VitalsProvider(VitalsService(dio))),
          ChangeNotifierProvider(
              create: (_) => MedicationsProvider(MedicationsService(dio))),
          ChangeNotifierProvider(
              create: (_) => RemindersProvider(RemindersService(dio))),
          ChangeNotifierProvider(
              create: (_) => FamilyProvider(FamilyService(dio))),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    final Finder scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Upcoming Appointments'),
      300,
      scrollable: scrollable,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Upcoming Appointments'), findsOneWidget);
    await tester.tap(find.text('Dr. QA Kapoor').first);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cardiologist'), findsWidgets);
    expect(find.text('Where'), findsOneWidget);
  });
}
