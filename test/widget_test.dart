import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinsu_health_app/providers/theme_provider.dart';
import 'package:kinsu_health_app/screens/shell/main_shell.dart';

void main() {
  testWidgets('App shell renders bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppThemeProvider(),
        child: const MaterialApp(home: MainShell()),
      ),
    );
    await tester.pump();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Track'), findsWidgets);
  });
}
