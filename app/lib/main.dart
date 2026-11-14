import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/repositories/http_ocorrencias.dart';
import 'data/shopping_data.dart';
import 'features/alertas/alertas_controller.dart';
import 'features/welcome_preferences/preferences_scope.dart';
import 'features/welcome_preferences/preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Recupera as preferências salvas (RF47), carrega os dados do shopping
  // demonstrativo e escolhe o serviço de alertas, em paralelo. Se os dados
  // falharem, as telas tentam de novo.
  final (controller, dados, alertas) = await (
    PreferencesController.restore(LocalPreferencesStore()),
    ShoppingData.carregar().then<ShoppingData?>((d) => d, onError: (_) => null),
    escolherAlertas(),
  ).wait;
  runApp(AcessaApp(controller: controller, dados: dados, alertas: alertas));
}

/// Endereço da API de alertas definido no build
/// (`--dart-define=OCORRENCIAS_API=http://localhost:8097/api/ocorrencias`).
const _apiDefinida = String.fromEnvironment('OCORRENCIAS_API');

/// Alertas compartilhados quando a API responde; senão, **simulação** local
/// (a tela avisa, porque `compartilhado == false`).
///
/// Sem `OCORRENCIAS_API`, na web tenta a mesma origem (`/api/ocorrencias`,
/// servida por `.claude/serve-web.js`). Fora da web, sem endereço, fica no
/// modo simulado.
Future<AlertasController> escolherAlertas() async {
  final Uri? base = _apiDefinida.isNotEmpty
      ? Uri.tryParse(_apiDefinida)
      : (kIsWeb ? Uri.base.resolve('/api/ocorrencias') : null);
  if (base != null && await HttpOcorrenciasRepository.disponivel(base)) {
    return AlertasController(
      HttpOcorrenciasRepository(base, sessao: sessaoAnonima()),
    );
  }
  return AlertasController.simulado();
}
