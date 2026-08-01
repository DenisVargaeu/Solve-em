library;

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/ai_settings.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/solved_problem.dart';
import '../../domain/repositories/ocr_gateway.dart';
import '../../domain/usecases/analyze_problem_usecase.dart';
import '../../domain/usecases/check_solution_usecase.dart';
import '../../domain/usecases/problem_usecases.dart';

/// Stage of the analysis pipeline, shown to the user on the Analyzing screen.
enum AnalysisStage {
  preparing,
  readingImage,
  sendingToAi,
  formatting,
  done,
  error,
}

/// Drives the full analyze/check pipeline for one photo.
///
/// The pipeline is: OCR the image → send to the chosen AI → parse result →
/// save to history. Progress is reported through [AnalysisStage] so the UI can
/// show live status messages.

class AnalysisController extends ChangeNotifier {
  AnalysisController({
    required AnalyzeProblemUseCase analyze,
    required CheckSolutionUseCase check,
    required SaveProblemUseCase save,
    required OcrGateway ocrGateway,
  }) : _analyze = analyze,
       _check = check,
       _save = save,
       _ocrGateway = ocrGateway;

  final AnalyzeProblemUseCase _analyze;
  final CheckSolutionUseCase _check;
  final SaveProblemUseCase _save;
  final OcrGateway _ocrGateway;

  AnalysisStage _stage = AnalysisStage.preparing;
  AnalysisStage get stage => _stage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _ocrText = '';
  String get ocrText => _ocrText;

  String _imagePath = '';
  String get imagePath => _imagePath;

  SolvedProblem? _result;
  SolvedProblem? get result => _result;

  bool _started = false;
  bool get started => _started;

  void reset() {
    _stage = AnalysisStage.preparing;
    _errorMessage = null;
    _result = null;
    _started = false;
    _ocrText = '';
  }

  /// Runs **AI Mode**: full step-by-step solution of a photographed problem.
  Future<SolvedProblem?> analyze({
    required String imagePath,
    required AiSettings settings,
    bool ocrEnabled = true,
    String ocrText = '',
  }) {
    return _run(
      mode: SolveMode.ai,
      imagePath: imagePath,
      settings: settings,
      ocrEnabled: ocrEnabled,
      ocrText: ocrText,
    );
  }

  /// Runs **Control Mode**: checks the user's own written solution.
  Future<SolvedProblem?> check({
    required String imagePath,
    required AiSettings settings,
    bool ocrEnabled = true,
    String ocrText = '',
    String problemText = '',
  }) {
    return _run(
      mode: SolveMode.control,
      imagePath: imagePath,
      settings: settings,
      ocrEnabled: ocrEnabled,
      ocrText: ocrText,
      problemText: problemText,
    );
  }

  Future<SolvedProblem?> _run({
    required SolveMode mode,
    required String imagePath,
    required AiSettings settings,
    required bool ocrEnabled,
    String ocrText = '',
    String problemText = '',
  }) async {
    reset();
    _started = true;
    _imagePath = imagePath;
    notifyListeners();

    try {
      if (!settings.isConfigured) {
        throw const MissingApiKeyException();
      }

      var extracted = ocrText.trim();
      if (extracted.isNotEmpty) {
        // Text was already confirmed by the user (or injected); reuse it.
        _ocrText = extracted;
        notifyListeners();
      } else if (ocrEnabled) {
        _setStage(AnalysisStage.readingImage);
        extracted = await _safeOcr(imagePath);
        _ocrText = extracted;
        notifyListeners();
      }

      _setStage(AnalysisStage.sendingToAi);
      // Let the status animation breathe before the network call.
      await Future<void>.delayed(const Duration(milliseconds: 350));

      _setStage(AnalysisStage.formatting);
      final problem = switch (mode) {
        SolveMode.ai => SolvedProblem.fromAnalysis(
          analysis: await _analyze(
            AnalyzeProblemParams(
              imagePath: imagePath,
              settings: settings,
              ocrText: extracted,
              sendImage: !ocrEnabled,
            ),
          ),
          mode: mode,
          imagePath: imagePath,
        ),
        SolveMode.control => SolvedProblem.fromCheck(
          check: await _check(
            CheckSolutionParams(
              imagePath: imagePath,
              settings: settings,
              ocrText: extracted,
              problemText: problemText,
              sendImage: !ocrEnabled,
            ),
          ),
          imagePath: imagePath,
        ),
        SolveMode.noAi => throw const UnsupportedProviderException('noai'),
      };

      await _save(problem);
      _result = problem;
      _setStage(AnalysisStage.done);
      return problem;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _setStage(AnalysisStage.error);
      return null;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setStage(AnalysisStage.error);
      return null;
    }
  }

  /// OCR is best-effort: when nothing readable is found the model can still
  /// read the problem directly from the photo.
  Future<String> _safeOcr(String path) async {
    try {
      return await _ocrGateway.extractText(path);
    } on OcrException {
      return '';
    } on UnsupportedPlatformException {
      return '';
    } on Exception {
      return '';
    }
  }

  void _setStage(AnalysisStage stage) {
    _stage = stage;
    notifyListeners();
  }
}
