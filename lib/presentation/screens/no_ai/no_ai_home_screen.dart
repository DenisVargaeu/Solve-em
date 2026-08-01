library;

import 'package:flutter/material.dart';

import '../../../core/widgets/gradient_card.dart';
import '../../../core/theme/app_colors.dart';
import '../history_screen.dart';
import 'calculator_screen.dart';
import 'formula_library_screen.dart';
import 'notes_screen.dart';

/// Hub for the fully offline "No AI Mode" tools.

class NoAiHomeScreen extends StatelessWidget {
  const NoAiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('No AI Mode')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientCard(
              title: 'Calculator',
              subtitle: 'A fast offline calculator for quick math.',
              icon: Icons.calculate_rounded,
              colors: const [AppColors.noAiAmber, AppColors.noAiAmberLight],
              onTap: () => _open(context, const CalculatorScreen()),
            ),
            const SizedBox(height: 16),
            GradientCard(
              title: 'Formula Library',
              subtitle: 'Browse common math formulas with examples.',
              icon: Icons.functions_rounded,
              colors: const [AppColors.aiViolet, AppColors.aiVioletLight],
              onTap: () => _open(context, const FormulaLibraryScreen()),
            ),
            const SizedBox(height: 16),
            GradientCard(
              title: 'Math Notes',
              subtitle: 'Jot down ideas, definitions and reminders.',
              icon: Icons.sticky_note_2_rounded,
              colors: const [AppColors.controlTeal, AppColors.controlTealLight],
              onTap: () => _open(context, const NotesScreen()),
            ),
            const SizedBox(height: 16),
            GradientCard(
              title: 'History',
              subtitle: 'Review problems you solved before.',
              icon: Icons.history_rounded,
              colors: const [AppColors.seed, AppColors.aiViolet],
              onTap: () => _open(context, const HistoryScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
