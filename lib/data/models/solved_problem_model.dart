library;

import 'package:ai_photomat/domain/entities/ai_provider.dart';
import 'package:ai_photomat/domain/entities/mistake.dart';
import 'package:ai_photomat/domain/entities/solved_problem.dart';
import 'package:ai_photomat/domain/entities/solution_step.dart';

/// Serialization adapter between [SolvedProblem] and the plain maps Hive
/// stores. Keeps the domain entity free of any persistence concerns.

class SolvedProblemModel {
  const SolvedProblemModel._();

  static Map<String, dynamic> toMap(SolvedProblem p) => {
    'id': p.id,
    'mode': p.mode.id,
    'createdAt': p.createdAt.toIso8601String(),
    'problem': p.problem,
    'imagePath': p.imagePath,
    'answer': p.answer,
    'steps': p.steps.map((s) => s.toJson()).toList(),
    'explanation': p.explanation,
    'simpleExplanation': p.simpleExplanation,
    'correct': p.correct,
    'score': p.score,
    'mistakes': p.mistakes.map((m) => m.toJson()).toList(),
    'hint': p.hint,
    'feedback': p.feedback,
    'solutionText': p.solutionText,
    'calculatorExpression': p.calculatorExpression,
    'calculatorResult': p.calculatorResult,
    'rawText': p.rawText,
  };

  static SolvedProblem fromMap(Map<dynamic, dynamic> map) {
    String str(String key) => (map[key] as String?) ?? '';
    bool b(String key) => (map[key] as bool?) ?? false;
    int i(String key) => (map[key] as num?)?.toInt() ?? 0;

    final steps =
        (map['steps'] as List?)
            ?.whereType<Map>()
            .map((e) => SolutionStep.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <SolutionStep>[];

    final mistakes =
        (map['mistakes'] as List?)
            ?.whereType<Map>()
            .map((e) => Mistake.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <Mistake>[];

    return SolvedProblem(
      id: str('id'),
      mode: SolveMode.fromId(str('mode')),
      createdAt:
          DateTime.tryParse(str('createdAt')) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      problem: str('problem'),
      imagePath: map['imagePath'] as String?,
      answer: str('answer'),
      steps: steps,
      explanation: str('explanation'),
      simpleExplanation: str('simpleExplanation'),
      correct: b('correct'),
      score: i('score'),
      mistakes: mistakes,
      hint: str('hint'),
      feedback: str('feedback'),
      solutionText: str('solutionText'),
      calculatorExpression: str('calculatorExpression'),
      calculatorResult: str('calculatorResult'),
      rawText: str('rawText'),
    );
  }
}
