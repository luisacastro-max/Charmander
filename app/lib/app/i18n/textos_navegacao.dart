import 'i18n.dart';

/// Traduções: Navegação, bússola, mapa e instruções de rota (inclui textos gerados em domain/rules).
/// Chave = texto em português, exatamente como aparece no código.
/// Use {nome} para partes variáveis. Nomes de lojas e lugares não se traduzem.
const Map<String, Traducao> textosNavegacao = {
  // ---- Pisos (catalogo.json) e valores gerados em domain/rules ----
  'Térreo': ('Ground floor', 'Planta baja'),
  'Mezanino': ('Mezzanine', 'Entrepiso'),
  '2º piso': ('2nd floor', '2.º piso'),
  'próximo piso': ('next floor', 'siguiente piso'),
  'Não informado': ('Not provided', 'No informado'),
  // Corredores aparecem com artigo nas instruções ("até o Corredor Oeste").
  'o Corredor Oeste': ('the Corredor Oeste', 'el Corredor Oeste'),
  'o Corredor Central': ('the Corredor Central', 'el Corredor Central'),
  'o Corredor Leste': ('the Corredor Leste', 'el Corredor Leste'),
  'o Corredor do 2º piso': (
    'the Corredor do 2º piso',
    'el Corredor do 2º piso',
  ),

  // ---- Instruções de rota (MotorRotas.instrucao, rotas.dart) ----
  'Siga {n} metros até {alvo}.': (
    'Walk {n} meters to {alvo}.',
    'Camina {n} metros hasta {alvo}.',
  ),
  'Siga {n} metros até {alvo}. Atenção: trecho com degraus.': (
    'Walk {n} meters to {alvo}. Caution: this stretch has steps.',
    'Camina {n} metros hasta {alvo}. Atención: tramo con escalones.',
  ),
  'Siga {n} metros até {alvo}. Trecho com mais movimento de pessoas.': (
    'Walk {n} meters to {alvo}. This stretch is busier.',
    'Camina {n} metros hasta {alvo}. Tramo con más movimiento de personas.',
  ),
  'Siga {n} metros até {alvo}. Atenção: trecho com degraus. '
      'Trecho com mais movimento de pessoas.': (
    'Walk {n} meters to {alvo}. Caution: this stretch has steps. '
        'This stretch is busier.',
    'Camina {n} metros hasta {alvo}. Atención: tramo con escalones. '
        'Tramo con más movimiento de personas.',
  ),
  'Pegue o elevador até o {piso}.': (
    'Take the elevator to the {piso}.',
    'Toma el ascensor hasta {piso}.',
  ),
  'Suba pela escada rolante até o {piso}.': (
    'Take the escalator up to the {piso}.',
    'Sube por la escalera mecánica hasta {piso}.',
  ),
  'Use a escada até o {piso}. Atenção: trecho com degraus.': (
    'Take the stairs to the {piso}. Caution: this stretch has steps.',
    'Usa la escalera hasta {piso}. Atención: tramo con escalones.',
  ),
  'Siga pela rampa até o {piso}.': (
    'Follow the ramp to the {piso}.',
    'Sigue por la rampa hasta {piso}.',
  ),

  // ---- Curvas (curva(), viagem.dart) ----
  'Siga em frente': ('Go straight ahead', 'Sigue recto'),
  'Volte no sentido contrário': ('Turn around', 'Da la vuelta'),
  'Vire à direita': ('Turn right', 'Gira a la derecha'),
  'Vire à esquerda': ('Turn left', 'Gira a la izquierda'),
  'Siga em frente.': ('Go straight ahead.', 'Sigue recto.'),
  'Volte no sentido contrário.': ('Turn around.', 'Da la vuelta.'),
  'Vire à direita.': ('Turn right.', 'Gira a la derecha.'),
  'Vire à esquerda.': ('Turn left.', 'Gira a la izquierda.'),

  // ---- Direção da seta (direcaoEmTexto, bussola.dart) ----
  'para cima no mapa': ('up on the map', 'hacia arriba en el mapa'),
  'para cima e à direita no mapa': (
    'up and to the right on the map',
    'hacia arriba y a la derecha en el mapa',
  ),
  'à direita no mapa': ('to the right on the map', 'a la derecha en el mapa'),
  'para baixo e à direita no mapa': (
    'down and to the right on the map',
    'hacia abajo y a la derecha en el mapa',
  ),
  'para baixo no mapa': ('down on the map', 'hacia abajo en el mapa'),
  'para baixo e à esquerda no mapa': (
    'down and to the left on the map',
    'hacia abajo y a la izquierda en el mapa',
  ),
  'à esquerda no mapa': ('to the left on the map', 'a la izquierda en el mapa'),
  'para cima e à esquerda no mapa': (
    'up and to the left on the map',
    'hacia arriba y a la izquierda en el mapa',
  ),
  'MAPA': ('MAP', 'MAPA'),

  // ---- Tela de navegação ----
  'Encerrar navegação': ('End navigation', 'Terminar navegación'),
  'Cartão de ajuda': ('Help card', 'Tarjeta de ayuda'),
  'Destino final · {nome}': (
    'Final destination · {nome}',
    'Destino final · {nome}',
  ),
  'Parada {n} de {total} · {nome}': (
    'Stop {n} of {total} · {nome}',
    'Parada {n} de {total} · {nome}',
  ),
  'Indo para {nome}': ('Going to {nome}', 'Yendo a {nome}'),
  'Progresso da rota': ('Route progress', 'Progreso de la ruta'),
  'Rota concluída': ('Route completed', 'Ruta completada'),
  'Faltam {m} m · {min} min · chegada às {h}': (
    '{m} m to go · {min} min · arrival at {h}',
    'Faltan {m} m · {min} min · llegada a las {h}',
  ),
  'Bússola': ('Compass', 'Brújula'),
  'Mapa': ('Map', 'Mapa'),
  'A seta aponta para o próximo ponto no mapa do shopping '
      '(para cima = topo do mapa). Não usa a bússola do celular.': (
    'The arrow points to the next point on the mall map '
        '(up = top of the map). It does not use the phone compass.',
    'La flecha apunta al siguiente punto en el mapa del centro comercial '
        '(arriba = parte superior del mapa). No usa la brújula del celular.',
  ),
  'Simular chegada: {nome}': (
    'Simulate arrival: {nome}',
    'Simular llegada: {nome}',
  ),
  'Representa o celular detectar o beacon {b}': (
    'Represents the phone detecting beacon {b}',
    'Representa que el celular detecta el beacon {b}',
  ),
  'Demonstração: no shopping real, o celular detecta o beacon {b} sozinho '
      'ao chegar perto.': (
    'Demo: in the real mall, the phone detects beacon {b} on its own when '
        'you get close.',
    'Demostración: en el centro comercial real, el celular detecta el beacon '
        '{b} solo al acercarse.',
  ),
  'Pedir ajuda': ('Ask for help', 'Pedir ayuda'),
  'Abre o Ajuda+ com a sua localização atual': (
    'Opens Ajuda+ with your current location',
    'Abre Ajuda+ con tu ubicación actual',
  ),
  'Repetir instrução': ('Repeat instruction', 'Repetir instrucción'),
  'Fala de novo a orientação atual': (
    'Speaks the current guidance again',
    'Vuelve a decir la indicación actual',
  ),
  'Toque para ouvir de novo': (
    'Tap to hear it again',
    'Toca para oírla de nuevo',
  ),

  // Cartão da instrução
  'Seta {dir}.': ('Arrow {dir}.', 'Flecha {dir}.'),
  'Você está em {nome}, {piso}.': (
    'You are at {nome}, {piso}.',
    'Estás en {nome}, {piso}.',
  ),
  'Você está em {nome} · {piso}': (
    'You are at {nome} · {piso}',
    'Estás en {nome} · {piso}',
  ),
  'Depois: {instrucao}': ('Then: {instrucao}', 'Después: {instrucao}'),
  'Depois': ('Then', 'Después'),

  // Cartão da parada intermediária
  'Você chegou à parada {n}': (
    'You reached stop {n}',
    'Llegaste a la parada {n}',
  ),
  'Você chegou à parada {n}: {nome}.': (
    'You reached stop {n}: {nome}.',
    'Llegaste a la parada {n}: {nome}.',
  ),
  'Próxima parada: {nome} ({piso}). Quando estiver pronto, siga.': (
    'Next stop: {nome} ({piso}). Continue when you are ready.',
    'Próxima parada: {nome} ({piso}). Cuando estés listo, sigue.',
  ),
  'Seguir para {nome}': ('Continue to {nome}', 'Seguir hacia {nome}'),

  // Cartão de chegada
  'Você chegou!': ('You have arrived!', '¡Llegaste!'),
  'Encontrar com a câmera': ('Find with the camera', 'Buscar con la cámara'),
  'Ajuda a achar porta, balcão ou cadeira por perto': (
    'Helps find a door, counter or chair nearby',
    'Ayuda a encontrar una puerta, mostrador o silla cerca',
  ),
  'Escolher novo destino': ('Choose a new destination', 'Elegir nuevo destino'),

  // Fala: troca de piso
  'Você chegou ao {piso}.': (
    'You are now on the {piso}.',
    'Llegaste a {piso}.',
  ),

  // ---- Mapa interativo ----
  'Piso:': ('Floor:', 'Piso:'),
  '{piso} (você)': ('{piso} (you)', '{piso} (tú)'),
  'Vendo o {piso}. Você está no {atual}.': (
    'Viewing the {piso}. You are on the {atual}.',
    'Viendo: {piso}. Estás en: {atual}.',
  ),
  'Ver meu piso': ('Show my floor', 'Ver mi piso'),
  'Girar o mapa na direção da caminhada': (
    'Rotate the map to your walking direction',
    'Girar el mapa en la dirección de la caminata',
  ),
  'Deixar o norte do mapa para cima': (
    'Keep the map north up',
    'Dejar el norte del mapa arriba',
  ),
  'Aproximar o mapa': ('Zoom in', 'Acercar el mapa'),
  'Afastar o mapa': ('Zoom out', 'Alejar el mapa'),
  'Ver a rota inteira': ('Show the whole route', 'Ver la ruta completa'),
  'Recentralizar': ('Recenter', 'Recentrar'),
  'Norte do mapa para cima. Toque na bússola para o mapa girar na direção '
      'da caminhada.': (
    'Map north is up. Tap the compass to rotate the map to your walking '
        'direction.',
    'Norte del mapa arriba. Toca la brújula para que el mapa gire en la '
        'dirección de la caminata.',
  ),
  'O mapa gira para a sua direção ficar para cima. Toque na bússola para '
      'fixar o norte do mapa. Mapa ilustrativo, com dados fictícios.': (
    'The map rotates so your direction is up. Tap the compass to keep the '
        'map north fixed. Illustrative map with fictional data.',
    'El mapa gira para que tu dirección quede arriba. Toca la brújula para '
        'fijar el norte del mapa. Mapa ilustrativo, con datos ficticios.',
  ),
  // Descrição do mapa para leitores de tela
  'Mapa do {piso}.': ('Map of the {piso}.', 'Mapa de: {piso}.'),
  'Você está em {nome}.': ('You are at {nome}.', 'Estás en {nome}.'),
  'Você está no {piso}.': ('You are on the {piso}.', 'Estás en: {piso}.'),
  'A rota não passa por este piso.': (
    'The route does not go through this floor.',
    'La ruta no pasa por este piso.',
  ),
  'Neste piso a rota passa por {pontos}.': (
    'On this floor the route goes through {pontos}.',
    'En este piso la ruta pasa por {pontos}.',
  ),
  'Próximo ponto: {nome}.': ('Next point: {nome}.', 'Siguiente punto: {nome}.'),
  'O mapa acompanha você, com o norte do mapa para cima.': (
    'The map follows you, with map north up.',
    'El mapa te sigue, con el norte del mapa arriba.',
  ),
  'O mapa acompanha você e gira na direção da caminhada.': (
    'The map follows you and rotates to your walking direction.',
    'El mapa te sigue y gira en la dirección de la caminata.',
  ),
  'O mapa está solto; use Recentralizar para voltar a seguir.': (
    'The map is free; use Recenter to follow you again.',
    'El mapa está suelto; usa Recentrar para volver a seguirte.',
  ),
  // Legenda
  'Você': ('You', 'Tú'),
  'A percorrer': ('Still to go', 'Por recorrer'),
  'Já percorrido': ('Already covered', 'Ya recorrido'),
  'Parada': ('Stop', 'Parada'),

  'Rota mais usada (tracejada)': (
    'Most used route (dashed)',
    'Ruta más usada (discontinua)',
  ),
  'A linha tracejada mostra a rota mais usada, que a sua rota evita.': (
    'The dashed line shows the most used route, which your route avoids.',
    'La línea discontinua muestra la ruta más usada, que tu ruta evita.',
  ),
};
