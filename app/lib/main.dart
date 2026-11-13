import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/welcome_preferences/preferences_scope.dart';
import 'features/welcome_preferences/preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Recupera as preferências salvas neste aparelho (RF47).
  final controller = await PreferencesController.restore(
    LocalPreferencesStore(),
  );
  runApp(AcessaApp(controller: controller));
}
