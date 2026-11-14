import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/shopping_data.dart';
import 'features/welcome_preferences/preferences_scope.dart';
import 'features/welcome_preferences/preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Recupera as preferências salvas (RF47) e carrega os dados do shopping
  // demonstrativo, em paralelo. Se os dados falharem, as telas tentam de novo.
  final (controller, dados) = await (
    PreferencesController.restore(LocalPreferencesStore()),
    ShoppingData.carregar().then<ShoppingData?>((d) => d, onError: (_) => null),
  ).wait;
  runApp(AcessaApp(controller: controller, dados: dados));
}
