library;

import 'package:flutter/material.dart';

import 'app.dart';
import 'presentation/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.create();
  runApp(SolveEmApp(dependencies: dependencies));
}
