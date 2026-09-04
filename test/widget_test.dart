import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:solveem/domain/entities/ai_settings.dart';
import 'package:solveem/domain/repositories/settings_repository.dart';
import 'package:solveem/presentation/screens/home_screen.dart';
import 'package:solveem/presentation/state/app_controller.dart';
import 'package:solveem/presentation/state/settings_controller.dart';

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<AiSettings> loadAiSettings() async => const AiSettings();

  @override
  Future<void> saveAiSettings(AiSettings settings) async {}

  @override
  Future<String> loadThemeMode() async => 'system';

  @override
  Future<void> saveThemeMode(String mode) async {}

  @override
  Future<bool> loadOcrEnabled() async => true;

  @override
  Future<void> saveOcrEnabled(bool enabled) async {}

  @override
  Future<double> loadTextScale() async => 1.0;

  @override
  Future<void> saveTextScale(double scale) async {}

  @override
  Future<bool> loadReduceMotion() async => false;

  @override
  Future<void> saveReduceMotion(bool enabled) async {}
}

void main() {
  testWidgets('Home screen renders hero and mode cards',
      (WidgetTester tester) async {
    final controller = SettingsController(_FakeSettingsRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: controller),
          ChangeNotifierProvider.value(
            value: AppController(_FakeSettingsRepository())..init(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text("Solve 'em"), findsOneWidget);
    expect(find.text('Snap it.\nSolved it.'), findsOneWidget);
    expect(find.text('Solve'), findsOneWidget);
    expect(find.text('Ask tutor'), findsOneWidget);
    expect(find.text('AI Mode'), findsOneWidget);
    expect(find.text('Control'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('No AI'), findsOneWidget);
    expect(
      find.text('Ready whenever you are — add an API key to go AI.'),
      findsOneWidget,
    );
  });
}
