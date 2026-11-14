import 'i18n.dart';

/// Traduções: Cartão de ajuda, mensagens rápidas, câmera (último metro) e Ajuda+.
/// Chave = texto em português, exatamente como aparece no código.
/// Use {nome} para partes variáveis. Nomes de lojas e lugares não se traduzem.
const Map<String, Traducao> textosComunicacao = {
  // ───────────── Comuns ─────────────
  'Voltar': ('Back', 'Volver'),
  'Fechar': ('Close', 'Cerrar'),
  'Cartão de ajuda': ('Help card', 'Tarjeta de ayuda'),

  // ───────────── Cartão de ajuda ─────────────
  'Não foi possível carregar as frases.': (
    'Could not load the phrases.',
    'No fue posible cargar las frases.',
  ),
  'Mostrar para alguém': ('Show someone', 'Mostrar a alguien'),
  'Escolha a frase. O celular mostra em letras grandes para a outra pessoa '
      'ler, e ela pode responder tocando na tela.': (
    'Choose a phrase. The phone shows it in large letters for the other '
        'person to read, and they can answer by tapping the screen.',
    'Elige la frase. El celular la muestra en letras grandes para que la '
        'otra persona la lea, y puede responder tocando la pantalla.',
  ),
  'Quem vai ler fala': ('The person reading speaks', 'Quien va a leer habla'),
  'Mostra em letras grandes': (
    'Shows it in large letters',
    'La muestra en letras grandes',
  ),
  'Traduções feitas previamente, não automáticas.': (
    'Translations prepared in advance, not automatic.',
    'Traducciones hechas previamente, no automáticas.',
  ),
  'Você está mostrando:': ('You are showing:', 'Estás mostrando:'),
  'Aguardando resposta…': ('Waiting for an answer…', 'Esperando respuesta…'),
  'Resposta: {resposta}': ('Answer: {resposta}', 'Respuesta: {resposta}'),
  'Frente a frente': ('Face to face', 'Cara a cara'),
  'Desvirar': ('Turn back', 'Enderezar'),
  'Ouvir': ('Listen', 'Escuchar'),
  'Ouvir a frase': ('Listen to the phrase', 'Escuchar la frase'),

  // ───────────── Mensagens rápidas ─────────────
  'Mensagens rápidas': ('Quick messages', 'Mensajes rápidos'),
  'Em destaque': ('Featured', 'Destacado'),
  'Toque numa frase para mostrar em letras grandes.': (
    'Tap a phrase to show it in large letters.',
    'Toca una frase para mostrarla en letras grandes.',
  ),

  // ───────────── Câmera (último metro) ─────────────
  'Encontrar com a câmera': ('Find with the camera', 'Encontrar con la cámara'),
  'Fechar câmera': ('Close camera', 'Cerrar cámara'),
  'Área da câmera. Objeto procurado': (
    'Camera area. Object you are looking for',
    'Área de la cámara. Objeto buscado',
  ),
  'Deslize para cima ou para baixo para trocar o objeto. Toque duas vezes '
      'para saber onde ele está.': (
    'Swipe up or down to change the object. Double tap to hear where it is.',
    'Desliza hacia arriba o hacia abajo para cambiar el objeto. Toca dos '
        'veces para saber dónde está.',
  ),
  'O que tem aqui?': ('What is here?', '¿Qué hay aquí?'),
  'Procurar {alvo}': ('Look for: {alvo}', 'Buscar: {alvo}'),
  'Procurando: {alvo}': ('Looking for: {alvo}', 'Buscando: {alvo}'),
  'Procurando: {alvo}. Segure o celular na altura do peito e gire devagar.': (
    'Looking for: {alvo}. Hold the phone at chest height and turn slowly.',
    'Buscando: {alvo}. Sostén el celular a la altura del pecho y gira '
        'despacio.',
  ),
  'Procurando: {alvo}. Gire devagar.': (
    'Looking for: {alvo}. Turn slowly.',
    'Buscando: {alvo}. Gira despacio.',
  ),
  '{alvo} não está à frente. Continue girando.': (
    '{alvo} is not ahead. Keep turning.',
    '{alvo} no está al frente. Sigue girando.',
  ),
  'Não reconheço nada aqui. Gire devagar.': (
    'I do not recognize anything here. Turn slowly.',
    'No reconozco nada aquí. Gira despacio.',
  ),
  // descrever() de procura.dart: "Cadeira, à frente, perto."
  '{obj}, {lado}, {dist}.': (
    '{obj}, {lado}, {dist}.',
    '{obj}, {lado}, {dist}.',
  ),
  'Porta': ('Door', 'Puerta'),
  'Balcão': ('Counter', 'Mostrador'),
  'Cadeira': ('Chair', 'Silla'),
  'Caixa': ('Checkout', 'Caja'),
  'Elevador': ('Elevator', 'Ascensor'),
  'Banheiro': ('Restroom', 'Baño'),
  'à frente': ('ahead', 'al frente'),
  'à direita': ('to the right', 'a la derecha'),
  'um pouco à direita': ('slightly to the right', 'un poco a la derecha'),
  'à esquerda': ('to the left', 'a la izquierda'),
  'um pouco à esquerda': ('slightly to the left', 'un poco a la izquierda'),
  'perto': ('close', 'cerca'),
  'a poucos passos': ('a few steps away', 'a pocos pasos'),
  'longe': ('far', 'lejos'),
  'Bem à frente!': ('Right ahead!', '¡Justo al frente!'),
  'Quente: está na imagem': (
    'Warm: it is in view',
    'Caliente: está en la imagen',
  ),
  'Frio: gire devagar': ('Cold: turn slowly', 'Frío: gira despacio'),
  'Simular giro do celular': (
    'Simulate turning the phone',
    'Simular el giro del celular',
  ),
  '{n} graus': ('{n} degrees', '{n} grados'),
  'Demonstração: a câmera e o reconhecimento de objetos ainda são simulados. '
      'No aparelho real, basta girar o corpo com o celular na mão; a imagem '
      'não sai do celular.': (
    'Demo: the camera and object recognition are still simulated. On a real '
        'device, just turn your body with the phone in your hand; the image '
        'never leaves the phone.',
    'Demostración: la cámara y el reconocimiento de objetos todavía son '
        'simulados. En el aparato real, basta con girar el cuerpo con el '
        'celular en la mano; la imagen no sale del celular.',
  ),
  'Como usar': ('How to use', 'Cómo usar'),
  'Pulsos lentos e leves': ('Slow, light pulses', 'Pulsos lentos y suaves'),
  'o objeto não está na imagem': (
    'the object is not in view',
    'el objeto no está en la imagen',
  ),
  'Pulsos acelerando': ('Pulses speeding up', 'Pulsos que se aceleran'),
  'está entrando, continue girando': (
    'it is coming into view, keep turning',
    'está entrando, sigue girando',
  ),
  'Vibração quase contínua': (
    'Almost continuous vibration',
    'Vibración casi continua',
  ),
  'está bem à sua frente': (
    'it is right ahead of you',
    'está justo frente a ti',
  ),
  'Deslizar para o lado': ('Swipe sideways', 'Deslizar hacia el lado'),
  'troca o objeto procurado': (
    'changes the object you are looking for',
    'cambia el objeto buscado',
  ),
  'Deslizar para cima': ('Swipe up', 'Deslizar hacia arriba'),
  'o que tem aqui?': ('what is here?', '¿qué hay aquí?'),
  'Dois toques': ('Double tap', 'Dos toques'),
  'repete onde o objeto está': (
    'repeats where the object is',
    'repite dónde está el objeto',
  ),

  // ───────────── Ajuda+ ─────────────
  'Confira seu pedido': ('Check your request', 'Revisa tu pedido'),
  'Acompanhamento': ('Tracking', 'Seguimiento'),
  'Pedir': ('Request', 'Pedir'),
  'Revisar': ('Review', 'Revisar'),
  'Acompanhar': ('Track', 'Seguir'),
  'Passo {n} de {total}: {etapa}': (
    'Step {n} of {total}: {etapa}',
    'Paso {n} de {total}: {etapa}',
  ),
  'Peça apoio só se quiser. Você decide como ser atendido(a).': (
    'Ask for support only if you want. You decide how to be assisted.',
    'Pide apoyo solo si quieres. Tú decides cómo ser atendido(a).',
  ),
  'O que está acontecendo?': ('What is happening?', '¿Qué está pasando?'),
  'Escolha uma opção para continuar.': (
    'Choose an option to continue.',
    'Elige una opción para continuar.',
  ),
  'Escolha o que está acontecendo.': (
    'Choose what is happening.',
    'Elige lo que está pasando.',
  ),
  'Não consigo encontrar meu destino': (
    'I cannot find my destination',
    'No consigo encontrar mi destino',
  ),
  'Preciso de acompanhamento': (
    'I need someone to accompany me',
    'Necesito acompañamiento',
  ),
  'Encontrei uma barreira no caminho': (
    'I found a barrier on the way',
    'Encontré una barrera en el camino',
  ),
  'Preciso de ajuda para me comunicar': (
    'I need help to communicate',
    'Necesito ayuda para comunicarme',
  ),
  'Preciso de apoio de um funcionário': (
    'I need support from a staff member',
    'Necesito apoyo de un empleado',
  ),
  'Onde você está': ('Where you are', 'Dónde estás'),
  'Local não informado': ('Location not provided', 'Lugar no informado'),
  'Pelo beacon {beacon} (simulado). Confira e troque se não estiver certo.': (
    'By beacon {beacon} (simulated). Check it and change it if it is wrong.',
    'Por el beacon {beacon} (simulado). Revísalo y cámbialo si no es '
        'correcto.',
  ),
  'Trocar local': ('Change location', 'Cambiar lugar'),
  // "Entrada Principal · Térreo": o nome do lugar fica; o piso traduz.
  '{lugar} · {piso}': ('{lugar} · {piso}', '{lugar} · {piso}'),
  'Térreo': ('Ground floor', 'Planta baja'),
  '2º piso': ('2nd floor', '2.º piso'),
  'Mezanino': ('Mezzanine', 'Entrepiso'),
  'Não informado': ('Not provided', 'No informado'),
  'Como prefere ser atendido(a)?': (
    'How do you prefer to be assisted?',
    '¿Cómo prefieres ser atendido(a)?',
  ),
  'Mensagem de texto': ('Text message', 'Mensaje de texto'),
  'Áudio': ('Audio', 'Audio'),
  'Atendimento presencial': ('In-person assistance', 'Atención presencial'),
  'É a sua preferência; a disponibilidade depende do shopping.': (
    'This is your preference; availability depends on the mall.',
    'Es tu preferencia; la disponibilidad depende del centro comercial.',
  ),
  'Detalhes (opcional)': ('Details (optional)', 'Detalles (opcional)'),
  'Frases para este local:': (
    'Phrases for this place:',
    'Frases para este lugar:',
  ),
  'Se quiser, conte mais': (
    'If you want, tell us more',
    'Si quieres, cuéntanos más',
  ),
  'Revisar pedido': ('Review request', 'Revisar pedido'),
  'Demonstração: o pedido fica só neste aparelho e nenhuma equipe real é '
      'acionada.': (
    'Demo: the request stays on this device and no real team is called.',
    'Demostración: el pedido queda solo en este aparato y no se llama a '
        'ningún equipo real.',
  ),
  'Está tudo certo?': ('Is everything right?', '¿Está todo bien?'),
  'O que acontece': ('What is happening', 'Qué pasa'),
  'Onde': ('Where', 'Dónde'),
  'Atendimento': ('Assistance', 'Atención'),
  'Detalhes': ('Details', 'Detalles'),
  'Nenhum': ('None', 'Ninguno'),
  'Confirmar e pedir ajuda': (
    'Confirm and ask for help',
    'Confirmar y pedir ayuda',
  ),
  'Corrigir': ('Edit', 'Corregir'),
  'Preferência: {forma}': ('Preference: {forma}', 'Preferencia: {forma}'),
  'Solicitação cancelada': ('Request canceled', 'Solicitud cancelada'),
  'Simulação para demonstração: nenhuma equipe real foi acionada.': (
    'Demo simulation: no real team was called.',
    'Simulación de demostración: no se llamó a ningún equipo real.',
  ),
  'Avançar etapa (demonstração)': (
    'Next stage (demo)',
    'Avanzar etapa (demostración)',
  ),
  'Mostrar cartão enquanto espera': (
    'Show card while you wait',
    'Mostrar tarjeta mientras esperas',
  ),
  'Cancelar solicitação': ('Cancel request', 'Cancelar solicitud'),
  'Retomar percurso': ('Resume route', 'Retomar recorrido'),
  'Voltar ao início': ('Back to start', 'Volver al inicio'),
  'Novo pedido': ('New request', 'Nuevo pedido'),
  'Etapa atual': ('Current stage', 'Etapa actual'),
  // Estados (assistencia.dart).
  'Solicitação registrada': ('Request registered', 'Solicitud registrada'),
  'Atendimento atribuído': ('Assistance assigned', 'Atención asignada'),
  'Apoio a caminho': ('Support on the way', 'Apoyo en camino'),
  'Concluída': ('Completed', 'Concluida'),
  // Avisos falados (PedidoAjuda.aviso).
  'Solicitação cancelada.': ('Request canceled.', 'Solicitud cancelada.'),
  'Solicitação registrada.': ('Request registered.', 'Solicitud registrada.'),
  'Um atendente recebeu seu pedido.': (
    'A staff member received your request.',
    'Un empleado recibió tu pedido.',
  ),
  'O apoio está a caminho de {local}.': (
    'Support is on the way to {local}.',
    'El apoyo está en camino a {local}.',
  ),
  'Atendimento concluído.': ('Assistance completed.', 'Atención concluida.'),
  // Sugestões por local (assets/data/comunicacao.json).
  'Pedir um mapa tátil': ('Ask for a tactile map', 'Pedir un mapa táctil'),
  'Gostaria de um mapa tátil, por favor.': (
    'I would like a tactile map, please.',
    'Me gustaría un mapa táctil, por favor.',
  ),
  'Atendimento por escrito': ('Written assistance', 'Atención por escrito'),
  'Gostaria de atendimento por escrito.': (
    'I would like written assistance.',
    'Me gustaría atención por escrito.',
  ),
  'Pedir acompanhante': ('Ask for a companion', 'Pedir acompañante'),
  'Preciso de acompanhamento até meu destino.': (
    'I need someone to accompany me to my destination.',
    'Necesito acompañamiento hasta mi destino.',
  ),
  'Pedir ajuda neste local': ('Ask for help here', 'Pedir ayuda en este lugar'),
  'Preciso de ajuda no banheiro acessível.': (
    'I need help in the accessible restroom.',
    'Necesito ayuda en el baño accesible.',
  ),
  'Pedir ajuda com a vaga': (
    'Ask for help with parking',
    'Pedir ayuda con el estacionamiento',
  ),
  'Preciso de ajuda perto do estacionamento.': (
    'I need help near the parking lot.',
    'Necesito ayuda cerca del estacionamiento.',
  ),
  'Preciso de um elevador': ('I need an elevator', 'Necesito un ascensor'),
  'Preciso de um elevador.': ('I need an elevator.', 'Necesito un ascensor.'),
  'Ajuda para usar o elevador': (
    'Help using the elevator',
    'Ayuda para usar el ascensor',
  ),
  'Preciso de ajuda para usar o elevador.': (
    'I need help using the elevator.',
    'Necesito ayuda para usar el ascensor.',
  ),
  'Pedir provador acessível': (
    'Ask for an accessible fitting room',
    'Pedir probador accesible',
  ),
  'Gostaria de usar o provador acessível.': (
    'I would like to use the accessible fitting room.',
    'Me gustaría usar el probador accesible.',
  ),
  'Cardápio ampliado': ('Large-print menu', 'Menú ampliado'),
  'Gostaria do cardápio em letras grandes.': (
    'I would like the menu in large print.',
    'Me gustaría el menú en letras grandes.',
  ),
  'Informar alergia': ('Report an allergy', 'Informar alergia'),
  'Tenho alergia alimentar. Pode me ajudar a escolher?': (
    'I have a food allergy. Can you help me choose?',
    'Tengo alergia alimentaria. ¿Puede ayudarme a elegir?',
  ),
  'Pedir água': ('Ask for water', 'Pedir agua'),
  'Gostaria de água.': ('I would like some water.', 'Me gustaría agua.'),
  'Preciso de ajuda no Espaço Família.': (
    'I need help at the Family Area.',
    'Necesito ayuda en el Espacio Familia.',
  ),
};
