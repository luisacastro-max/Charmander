import 'package:flutter/material.dart';

import '../features/welcome_preferences/preferences_scope.dart';
import '../core/widgets/theme_reveal.dart';
import '../data/shopping_data.dart';
import '../features/welcome_preferences/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

class AcessaApp extends StatefulWidget {
  const AcessaApp({super.key, this.controller, this.dados});

  /// Permite injetar o controlador nos testes.
  final PreferencesController? controller;

  /// Dados do shopping já carregados (main.dart). Se ausentes, as telas
  /// carregam sob demanda.
  final ShoppingData? dados;

  @override
  State<AcessaApp> createState() => _AcessaAppState();
}

class _AcessaAppState extends State<AcessaApp> {
  late final PreferencesController _prefs =
      widget.controller ?? PreferencesController();

  @override
  Widget build(BuildContext context) {
    final app = _buildApp();
    final dados = widget.dados;
    return dados == null ? app : DadosScope(dados: dados, child: app);
  }

  Widget _buildApp() {
    return PreferencesScope(
      controller: _prefs,
      child: ListenableBuilder(
        listenable: _prefs,
        builder: (context, _) {
          final p = _prefs.prefs;
          return MaterialApp(
            title: 'Acessa+',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(p),
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              // Texto ampliado: multiplica a escala escolhida no sistema,
              // sem ignorar a configuração do aparelho.
              final scaler = p.largeText
                  ? TextScaler.linear(mq.textScaler.scale(1) * 1.3)
                  : mq.textScaler;
              return MediaQuery(
                data: mq.copyWith(textScaler: scaler),
                child: ThemeReveal(
                  child: AnimatedContainer(
                    // Fundo acompanha a troca de tema (instantâneo se a
                    // revelação em círculo estiver ativa por cima).
                    duration: Duration.zero,
                    color: AcessaTheme.of(context).colors.background,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AcessaSpacing.maxContentWidth,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
            home: const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
