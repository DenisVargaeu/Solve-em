import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ai_photomat/domain/entities/ai_settings.dart';
import 'package:ai_photomat/domain/repositories/settings_repository.dart';
import 'package:ai_photomat/presentation/screens/home_screen.dart';
import 'package:ai_photomat/presentation/state/settings_controller.dart';

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
}

void main() {
  testWidgets('Home screen renders hero and mode cards',
      (WidgetTester tester) async {
    final controller = SettingsController(_FakeSettingsRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text("Solve 'em"), findsOneWidget);
    expect(find.text('Snap it.\nSolved it.'), findsOneWidget);
    expect(find.text('Start solving'), findsOneWidget);
    expect(find.text('AI Mode'), findsOneWidget);
    expect(find.text('Control'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('No AI'), findsOneWidget);
    expect(find.text('Add an API key to unlock AI modes'), findsOneWidget);
  });
}
