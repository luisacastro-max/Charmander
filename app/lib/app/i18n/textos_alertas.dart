import 'i18n.dart';

/// Traduções: mapa colaborativo de alertas (relatos da comunidade).
/// Chave = texto em português, exatamente como aparece no código.
/// Use {nome} para partes variáveis. Nomes de lojas e lugares não se traduzem.
const Map<String, Traducao> textosAlertas = {
  // ---------------------------------------------------------------------
  // Tipos de alerta (TipoOcorrencia.rotulo) e o que a forma significa
  // ---------------------------------------------------------------------
  'Piso molhado ou escorregadio': (
    'Wet or slippery floor',
    'Piso mojado o resbaladizo',
  ),
  'Passagem interditada': ('Passage closed', 'Paso cerrado'),
  'Obstáculo no caminho': ('Obstacle in the way', 'Obstáculo en el camino'),
  'Elevador fora de serviço': (
    'Elevator out of service',
    'Ascensor fuera de servicio',
  ),
  'Escada rolante parada': ('Escalator stopped', 'Escalera mecánica parada'),
  'Rampa bloqueada': ('Ramp blocked', 'Rampa bloqueada'),
  'Local muito cheio': ('Very crowded area', 'Lugar muy lleno'),
  'Outro problema': ('Other problem', 'Otro problema'),
  'Bloqueia a passagem': ('Blocks the way', 'Bloquea el paso'),
  'Atenção no caminho': ('Caution on the way', 'Atención en el camino'),

  // ---------------------------------------------------------------------
  // Estado da conexão e filtro
  // ---------------------------------------------------------------------
  'Carregando alertas da comunidade…': (
    'Loading community alerts…',
    'Cargando alertas de la comunidad…',
  ),
  'Sem conexão com os alertas.': (
    'No connection to the alerts.',
    'Sin conexión con las alertas.',
  ),
  'Não foi possível carregar os alertas.': (
    "Couldn't load the alerts.",
    'No fue posible cargar las alertas.',
  ),
  'Não foi possível falar com o serviço de alertas.': (
    "Couldn't reach the alert service.",
    'No fue posible comunicarse con el servicio de alertas.',
  ),
  'Este alerta não existe mais.': (
    'This alert no longer exists.',
    'Esta alerta ya no existe.',
  ),
  'Os alertas mostrados podem estar desatualizados.': (
    'The alerts shown may be out of date.',
    'Las alertas mostradas pueden estar desactualizadas.',
  ),
  'Tentar de novo': ('Try again', 'Intentar de nuevo'),
  'Simulação: os alertas ficam só neste aparelho': (
    'Simulation: alerts stay on this device only',
    'Simulación: las alertas quedan solo en este dispositivo',
  ),
  'Filtrar por tipo': ('Filter by type', 'Filtrar por tipo'),
  'Mostrando todos os tipos': (
    'Showing all types',
    'Mostrando todos los tipos',
  ),
  'Mostrando {n} de {t} tipos': (
    'Showing {n} of {t} types',
    'Mostrando {n} de {t} tipos',
  ),
  'Mostrar todos': ('Show all', 'Mostrar todos'),

  // ---------------------------------------------------------------------
  // Mapa de alertas
  // ---------------------------------------------------------------------
  'Mapa de alertas': ('Alert map', 'Mapa de alertas'),
  'Alertas': ('Alerts', 'Alertas'),
  'Relatos de visitantes sobre o que atrapalha o caminho. '
      'Não são verificados pelo shopping nem garantem a sua segurança.': (
    'Visitor reports about what gets in the way. They are not verified by '
        'the mall and do not guarantee your safety.',
    'Reportes de visitantes sobre lo que dificulta el camino. No son '
        'verificados por el centro comercial ni garantizan tu seguridad.',
  ),
  '1 alerta ativo no shopping': (
    '1 active alert in the mall',
    '1 alerta activa en el centro comercial',
  ),
  '{n} alertas ativos no shopping': (
    '{n} active alerts in the mall',
    '{n} alertas activas en el centro comercial',
  ),
  'Começa na sua posição atual; você pode ajustar': (
    'Starts at your current position; you can adjust it',
    'Empieza en tu posición actual; puedes ajustarla',
  ),
  '1 ativo': ('1 active', '1 activa'),
  '{n} ativos': ('{n} active', '{n} activas'),
  'Relatos da comunidade sobre o caminho': (
    'Community reports about the way',
    'Reportes de la comunidad sobre el camino',
  ),
  'Ver o piso inteiro': ('See the whole floor', 'Ver el piso entero'),
  'Alerta da comunidade:': ('Community alert:', 'Alerta de la comunidad:'),
  '{n} alertas neste local': (
    '{n} alerts at this spot',
    '{n} alertas en este lugar',
  ),
  'Toque para ver os detalhes': (
    'Tap to see details',
    'Toca para ver detalles',
  ),
  'Alertas neste piso': ('Alerts on this floor', 'Alertas en este piso'),
  'Nenhum alerta da comunidade neste piso.': (
    'No community alerts on this floor.',
    'Ninguna alerta de la comunidad en este piso.',
  ),
  '1 alerta da comunidade neste piso.': (
    '1 community alert on this floor.',
    '1 alerta de la comunidad en este piso.',
  ),
  '{n} alertas da comunidade neste piso.': (
    '{n} community alerts on this floor.',
    '{n} alertas de la comunidad en este piso.',
  ),
  '{t}, perto de {l}.': ('{t}, near {l}.', '{t}, cerca de {l}.'),
  'Perto de: {x}': ('Near: {x}', 'Cerca de: {x}'),
  'confirmado {q}': ('confirmed {q}', 'confirmada {q}'),
  'Enviando…': ('Sending…', 'Enviando…'),
  'Não enviado': ('Not sent', 'No enviada'),
  'Não enviado.': ('Not sent.', 'No enviada.'),
  'Não enviado. {e}': ('Not sent. {e}', 'No enviada. {e}'),
  'Alerta enviado.': ('Alert sent.', 'Alerta enviada.'),
  'Descartar': ('Discard', 'Descartar'),

  // ---------------------------------------------------------------------
  // Card de detalhes
  // ---------------------------------------------------------------------
  'Relato da comunidade, não verificado': (
    'Community report, not verified',
    'Reporte de la comunidad, no verificado',
  ),
  'Perto de': ('Near', 'Cerca de'),
  'Andar': ('Floor', 'Piso'),
  'Quando': ('When', 'Cuándo'),
  'Situação': ('Status', 'Situación'),
  'Criado às {h} · confirmado {q}': (
    'Created at {h} · confirmed {q}',
    'Creada a las {h} · confirmada {q}',
  ),
  'agora mesmo': ('just now', 'ahora mismo'),
  'há {n} min': ('{n} min ago', 'hace {n} min'),
  'há {n} h': ('{n} h ago', 'hace {n} h'),
  'Ativo · {c} · vale até {h}': (
    'Active · {c} · valid until {h}',
    'Activa · {c} · vale hasta las {h}',
  ),
  '1 confirmação': ('1 confirmation', '1 confirmación'),
  '{n} confirmações': ('{n} confirmations', '{n} confirmaciones'),
  'Resolvido': ('Resolved', 'Resuelta'),
  'Expirado': ('Expired', 'Vencida'),
  'Ainda está aqui': ('Still here', 'Sigue aquí'),
  'Confirma que o problema continua': (
    'Confirms the problem is still there',
    'Confirma que el problema sigue',
  ),
  'Já foi resolvido': ('Already resolved', 'Ya se resolvió'),
  'Avisa que o problema não está mais lá': (
    'Reports that the problem is gone',
    'Avisa que el problema ya no está',
  ),
  'Enviando resposta…': ('Sending answer…', 'Enviando respuesta…'),
  'Você já confirmou este alerta. Obrigado!': (
    'You already confirmed this alert. Thank you!',
    'Ya confirmaste esta alerta. ¡Gracias!',
  ),
  'Você já avisou que foi resolvido. Obrigado!': (
    'You already reported it as resolved. Thank you!',
    'Ya avisaste que se resolvió. ¡Gracias!',
  ),
  'Obrigado! Você confirmou que o problema continua.': (
    'Thank you! You confirmed the problem is still there.',
    '¡Gracias! Confirmaste que el problema sigue.',
  ),
  'Obrigado! Você avisou que o problema foi resolvido.': (
    'Thank you! You reported the problem as resolved.',
    '¡Gracias! Avisaste que el problema se resolvió.',
  ),
  'Não foi possível enviar a resposta.': (
    "Couldn't send the answer.",
    'No fue posible enviar la respuesta.',
  ),
  'Os alertas ajudam a escolher o caminho, mas não garantem a sua '
      'segurança. Siga a sinalização e as orientações do shopping.': (
    'Alerts help you choose the way, but they do not guarantee your '
        "safety. Follow the mall's signs and staff guidance.",
    'Las alertas ayudan a elegir el camino, pero no garantizan tu '
        'seguridad. Sigue la señalización y las indicaciones del centro '
        'comercial.',
  ),

  // ---------------------------------------------------------------------
  // Reportar problema
  // ---------------------------------------------------------------------
  'Reportar problema': ('Report a problem', 'Reportar un problema'),
  'Avise outras pessoas sobre algo que atrapalha o caminho. '
      'O alerta é um relato seu, não uma informação oficial do shopping.': (
    'Let others know about something in the way. The alert is your report, '
        'not official information from the mall.',
    'Avisa a otras personas sobre algo que dificulta el camino. La alerta '
        'es un reporte tuyo, no información oficial del centro comercial.',
  ),
  '1. O que está acontecendo?': ("1. What's happening?", '1. ¿Qué pasa?'),
  '2. Onde?': ('2. Where?', '2. ¿Dónde?'),
  '3. Detalhes (opcional)': ('3. Details (optional)', '3. Detalles (opcional)'),
  'Andar:': ('Floor:', 'Piso:'),
  'Planta do {p}.': ('Floor plan of the {p}.', 'Plano del {p}.'),
  'Pino perto de: {x}': ('Pin near: {x}', 'Marcador cerca de: {x}'),
  'Toque para posicionar o pino.': (
    'Tap to place the pin.',
    'Toca para colocar el marcador.',
  ),
  'Mover o pino para a esquerda': (
    'Move the pin left',
    'Mover el marcador a la izquierda',
  ),
  'Mover o pino para a direita': (
    'Move the pin right',
    'Mover el marcador a la derecha',
  ),
  'Mover o pino para cima': (
    'Move the pin up',
    'Mover el marcador hacia arriba',
  ),
  'Mover o pino para baixo': (
    'Move the pin down',
    'Mover el marcador hacia abajo',
  ),
  'A posição dentro do shopping pode ser imprecisa. '
      'Confira o ponto e o andar antes de enviar.': (
    'Indoor position may be inaccurate. Check the spot and the floor '
        'before sending.',
    'La posición dentro del centro comercial puede ser imprecisa. Revisa el '
        'punto y el piso antes de enviar.',
  ),
  'Escolher o ponto mais próximo numa lista': (
    'Choose the nearest spot from a list',
    'Elegir el punto más cercano en una lista',
  ),
  'Descrição (opcional)': ('Description (optional)', 'Descripción (opcional)'),
  'Ex.: poça perto da entrada da loja': (
    'E.g.: puddle near the store entrance',
    'Ej.: charco cerca de la entrada de la tienda',
  ),
  'Não escreva nomes, telefones ou outros dados pessoais.': (
    "Don't write names, phone numbers or other personal data.",
    'No escribas nombres, teléfonos ni otros datos personales.',
  ),
  'Escolha o que está acontecendo para enviar.': (
    "Choose what's happening to send.",
    'Elige qué pasa para enviar.',
  ),
  'Enviar alerta': ('Send alert', 'Enviar alerta'),
  '{t}, {p}, perto de {l}': ('{t}, {p}, near {l}', '{t}, {p}, cerca de {l}'),
  'Enviando alerta…': ('Sending alert…', 'Enviando alerta…'),
  'Alerta enviado. Obrigado!': (
    'Alert sent. Thank you!',
    'Alerta enviada. ¡Gracias!',
  ),
  'Somado a um alerta igual que já existia.': (
    'Added to an identical alert that already existed.',
    'Sumado a una alerta igual que ya existía.',
  ),
  'Outras pessoas neste shopping já podem ver o alerta.': (
    'Other people in this mall can now see the alert.',
    'Otras personas en este centro comercial ya pueden ver la alerta.',
  ),
  'Concluir': ('Done', 'Listo'),
  'Não foi possível enviar o alerta.': (
    "Couldn't send the alert.",
    'No fue posible enviar la alerta.',
  ),
  'O relato fica guardado neste aparelho até você decidir.': (
    'The report stays on this device until you decide.',
    'El reporte queda guardado en este dispositivo hasta que decidas.',
  ),

  // ---------------------------------------------------------------------
  // Rota e navegação com alertas
  // ---------------------------------------------------------------------
  'Alertas da comunidade no caminho': (
    'Community alerts on the way',
    'Alertas de la comunidad en el camino',
  ),
  'Relatos de visitantes, não verificados. A rota passa por estes '
      'trechos; vá com atenção.': (
    'Visitor reports, not verified. The route goes through these '
        'sections; take care.',
    'Reportes de visitantes, no verificados. La ruta pasa por estos '
        'tramos; ve con atención.',
  ),
  'Desviamos de:': ('We avoided:', 'Evitamos:'),
  'Rota atualizada para desviar de alerta da comunidade.': (
    'Route updated to avoid a community alert.',
    'Ruta actualizada para evitar una alerta de la comunidad.',
  ),
  'Avisa outras pessoas sobre algo que atrapalha o caminho': (
    'Lets others know about something in the way',
    'Avisa a otras personas sobre algo que dificulta el camino',
  ),
  'Avisa outras pessoas sobre algo no caminho, a partir de onde '
      'você está': (
    'Lets others know about something on the way, from where you are',
    'Avisa a otras personas sobre algo en el camino, desde donde estás',
  ),
  'Um alerta da comunidade bloqueia o caminho que você usaria. É um relato '
      'e pode já ter sido resolvido; a rota volta sozinha quando o alerta '
      'deixar de valer. Um funcionário do shopping pode ajudar.': (
    'A community alert blocks the way you would take. It is a report and '
        'may already be resolved; the route comes back on its own when the '
        'alert is no longer valid. Mall staff can help.',
    'Una alerta de la comunidad bloquea el camino que usarías. Es un '
        'reporte y puede que ya se haya resuelto; la ruta vuelve sola cuando '
        'la alerta deja de valer. El personal del centro comercial puede '
        'ayudar.',
  ),
  'Alerta da comunidade neste trecho: {t}': (
    'Community alert on this section: {t}',
    'Alerta de la comunidad en este tramo: {t}',
  ),
  'Alerta da comunidade neste trecho: {t}.': (
    'Community alert on this section: {t}.',
    'Alerta de la comunidad en este tramo: {t}.',
  ),
  'Alerta da comunidade no seu caminho: {f}': (
    'Community alert on your way: {f}',
    'Alerta de la comunidad en tu camino: {f}',
  ),
  'Caminho bloqueado por alerta da comunidade': (
    'Way blocked by a community alert',
    'Camino bloqueado por una alerta de la comunidad',
  ),
  'Alerta da comunidade no caminho': (
    'Community alert on the way',
    'Alerta de la comunidad en el camino',
  ),
  'Não encontramos outro caminho. Você pode pedir ajuda.': (
    "We couldn't find another way. You can ask for help.",
    'No encontramos otro camino. Puedes pedir ayuda.',
  ),
  'O caminho está bloqueado. Toque em Recalcular rota.': (
    'The way is blocked. Tap Recalculate route.',
    'El camino está bloqueado. Toca Recalcular ruta.',
  ),
  'Não encontramos outro caminho compatível com as suas preferências. '
      'Um funcionário do shopping pode ajudar.': (
    "We couldn't find another way that matches your preferences. Mall staff "
        'can help.',
    'No encontramos otro camino compatible con tus preferencias. El personal '
        'del centro comercial puede ayudar.',
  ),
  'Tentar recalcular de novo': (
    'Try recalculating again',
    'Intentar recalcular de nuevo',
  ),
  'Recalcular rota': ('Recalculate route', 'Recalcular ruta'),
  'Procura um caminho que desvie do alerta': (
    'Looks for a way around the alert',
    'Busca un camino que evite la alerta',
  ),
  'Seguir assim': ('Keep going this way', 'Seguir así'),
  'Mantém a rota atual, com atenção no trecho': (
    'Keeps the current route, with care on that section',
    'Mantiene la ruta actual, con atención en el tramo',
  ),
  'Não há caminho melhor. A rota continua a mesma; '
      'siga com atenção no trecho com alerta.': (
    'There is no better way. The route stays the same; take care on the '
        'section with the alert.',
    'No hay un camino mejor. La ruta sigue igual; ve con atención en el '
        'tramo con la alerta.',
  ),
  'Rota recalculada para desviar do alerta.': (
    'Route recalculated to avoid the alert.',
    'Ruta recalculada para evitar la alerta.',
  ),
  'Tudo bem. A rota continua a mesma.': (
    'All right. The route stays the same.',
    'Está bien. La ruta sigue igual.',
  ),

  // Motivo de "sem rota" com bloqueio por alerta (MotorRotas.calcular),
  // combinado com os modelos de manutenção de textos_destino.dart.
  'Não há caminho sem escadas até {x}. '
      'Bloqueado por alerta da comunidade: {y}.': (
    'There is no step-free path to {x}. Blocked by a community alert: {y}.',
    'No hay camino sin escaleras hasta {x}. '
        'Bloqueado por una alerta de la comunidad: {y}.',
  ),
  'Não encontramos caminho cadastrado até {x}. '
      'Bloqueado por alerta da comunidade: {y}.': (
    "We couldn't find a registered path to {x}. "
        'Blocked by a community alert: {y}.',
    'No encontramos camino registrado hasta {x}. '
        'Bloqueado por una alerta de la comunidad: {y}.',
  ),
  'Não há caminho sem escadas até {x}. Em manutenção: {y}. '
      'Bloqueado por alerta da comunidade: {z}.': (
    'There is no step-free path to {x}. Under maintenance: {y}. '
        'Blocked by a community alert: {z}.',
    'No hay camino sin escaleras hasta {x}. En mantenimiento: {y}. '
        'Bloqueado por una alerta de la comunidad: {z}.',
  ),
  'Não encontramos caminho cadastrado até {x}. Em manutenção: {y}. '
      'Bloqueado por alerta da comunidade: {z}.': (
    "We couldn't find a registered path to {x}. Under maintenance: {y}. "
        'Blocked by a community alert: {z}.',
    'No encontramos camino registrado hasta {x}. En mantenimiento: {y}. '
        'Bloqueado por una alerta de la comunidad: {z}.',
  ),
};
