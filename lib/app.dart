library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/di/app_dependencies.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/state/analysis_controller.dart';
import 'presentation/state/app_controller.dart';
import 'presentation/state/chat_controller.dart';
import 'presentation/state/history_controller.dart';
import 'presentation/state/notes_controller.dart';
import 'presentation/state/settings_controller.dart';

/// Root widget: wires all controllers and applies the app theme.

class SolveEmApp extends StatelessWidget {
  const SolveEmApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: dependencies),

        ChangeNotifierProvider(
          create: (_) => AppController(dependencies.settingsRepository)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              SettingsController(dependencies.settingsRepository)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryController(
            getProblems: dependencies.getProblems,
            saveProblem: dependencies.saveProblem,
            deleteProblem: dependencies.deleteProblem,
            clearHistory: dependencies.clearHistory,
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesController(
            getNotes: dependencies.getNotes,
            saveNote: dependencies.saveNote,
            deleteNote: dependencies.deleteNote,
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatController(chat: dependencies.chat),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisController(
            analyze: dependencies.analyzeProblem,
            check: dependencies.checkSolution,
            save: dependencies.saveProblem,
            ocrGateway: dependencies.ocrGateway,
          ),
        ),
      ],
      child: Consumer<AppController>(
        builder: (context, app, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: app.themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(app.textScale),
            ),
            child: child!,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
