library;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/problem_local_datasource.dart';
import '../../data/datasources/remote/ai/ai_gateway_factory.dart';
import '../../data/datasources/remote/ocr_service.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../data/repositories/problem_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/ai_settings.dart';
import '../../domain/repositories/ai_gateway.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/repositories/ocr_gateway.dart';
import '../../domain/repositories/problem_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/analyze_problem_usecase.dart';
import '../../domain/usecases/ask_follow_up_usecase.dart';
import '../../domain/usecases/chat_usecase.dart';
import '../../domain/usecases/check_solution_usecase.dart';
import '../../domain/usecases/list_models_usecase.dart';
import '../../domain/usecases/note_usecases.dart';
import '../../domain/usecases/problem_usecases.dart';

/// Manual dependency container.
///
/// Everything the app needs is constructed once here and shared through
/// Provider. Keeping it in one class makes the wiring obvious and easy to
/// swap for a DI framework later.
class AppDependencies {
  AppDependencies._(
    this.settingsRepository,
    this.problemRepository,
    this.notesRepository,
    this.ocrGateway,
  );

  final SettingsRepository settingsRepository;
  final ProblemRepository problemRepository;
  final NotesRepository notesRepository;
  final OcrGateway ocrGateway;

  /// Resolves the correct AI gateway for any settings (provider dispatch).
  AiGateway gatewayFor(AiSettings settings) =>
      AiGatewayFactory.create(settings);

  // --- Use cases ----------------------------------------------------------

  late final analyzeProblem = AnalyzeProblemUseCase(
    ocrGateway: ocrGateway,
    resolveGateway: gatewayFor,
  );
  late final checkSolution = CheckSolutionUseCase(
    ocrGateway: ocrGateway,
    resolveGateway: gatewayFor,
  );
  late final askFollowUp = AskFollowUpUseCase(resolveGateway: gatewayFor);
  late final chat = ChatUseCase(resolveGateway: gatewayFor);
  late final listModels = ListModelsUseCase(resolveGateway: gatewayFor);

  late final saveProblem = SaveProblemUseCase(problemRepository);
  late final getProblems = GetProblemsUseCase(problemRepository);
  late final getProblemById = GetProblemByIdUseCase(problemRepository);
  late final deleteProblem = DeleteProblemUseCase(problemRepository);
  late final clearHistory = ClearHistoryUseCase(problemRepository);

  late final saveNote = SaveNoteUseCase(notesRepository);
  late final getNotes = GetNotesUseCase(notesRepository);
  late final deleteNote = DeleteNoteUseCase(notesRepository);

  /// Initializes storage backends and wires the whole graph.
  static Future<AppDependencies> create() async {
    await Hive.initFlutter();

    final problemsBox = await Hive.openBox<dynamic>(
      AppConstants.problemsBoxName,
    );
    final notesBox = await Hive.openBox<dynamic>(AppConstants.notesBoxName);
    final prefs = await SharedPreferences.getInstance();

    return AppDependencies._(
      SettingsRepositoryImpl(prefs),
      ProblemRepositoryImpl(ProblemLocalDatasource(problemsBox)),
      NotesRepositoryImpl(notesBox),
      OcrService(),
    );
  }
}
