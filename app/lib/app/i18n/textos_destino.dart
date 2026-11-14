import 'i18n.dart';

/// Traduções: Destino e rota.
/// Chave = texto em português, exatamente como aparece no código.
/// Use {nome} para partes variáveis. Nomes de lojas e lugares não se traduzem.
const Map<String, Traducao> textosDestino = {
  // ---------------------------------------------------------------------
  // Tela "Para onde você quer ir?"
  // ---------------------------------------------------------------------
  'Voltar': ('Back', 'Volver'),
  'Para onde você quer ir?': (
    'Where do you want to go?',
    '¿Adónde quieres ir?',
  ),
  'Qual a próxima parada?': (
    "What's the next stop?",
    '¿Cuál es la próxima parada?',
  ),
  'Não foi possível carregar o mapa do shopping. '
      'Peça ajuda no Balcão de Informações.': (
    "Couldn't load the mall map. Ask for help at the Information Desk.",
    'No fue posible cargar el mapa del centro comercial. '
        'Pide ayuda en el Mostrador de Información.',
  ),
  'Carregando o mapa do shopping': (
    'Loading the mall map',
    'Cargando el mapa del centro comercial',
  ),
  'Piso: {p}': ('Floor: {p}', 'Piso: {p}'),
  'Todos': ('All', 'Todos'),
  'Escolher o piso dos resultados': (
    'Choose the floor of the results',
    'Elegir el piso de los resultados',
  ),
  'Revisar minhas preferências de rota': (
    'Review my route preferences',
    'Revisar mis preferencias de ruta',
  ),
  'Sem escadas': ('No stairs', 'Sin escaleras'),
  'Prefere elevador': ('Prefers elevator', 'Prefiere ascensor'),
  'Caminho tranquilo': ('Quiet path', 'Camino tranquilo'),
  'Caminho mais curto': ('Shortest path', 'Camino más corto'),
  'Adicionar parada': ('Add stop', 'Agregar parada'),
  'Limite de {n} paradas': ('Limit of {n} stops', 'Límite de {n} paradas'),
  'Escolha a parada {n}.': ('Choose stop {n}.', 'Elige la parada {n}.'),
  '{nome} removida das paradas.': (
    '{nome} removed from the stops.',
    '{nome} quitada de las paradas.',
  ),
  '{nome} é a parada {n}. Agora escolha para onde quer ir.': (
    '{nome} is stop {n}. Now choose where you want to go.',
    '{nome} es la parada {n}. Ahora elige adónde quieres ir.',
  ),
  'Parada cancelada.': ('Stop canceled.', 'Parada cancelada.'),
  'Nenhum resultado': ('No results', 'Ningún resultado'),
  '1 resultado': ('1 result', '1 resultado'),
  '{n} resultados': ('{n} results', '{n} resultados'),
  'mais perto primeiro': ('closest first', 'más cerca primero'),
  'Adicionar como parada': ('Add as a stop', 'Agregar como parada'),
  'Ver rota': ('See route', 'Ver ruta'),
  'Mostrar resultados de qual piso?': (
    'Show results from which floor?',
    '¿Mostrar resultados de qué piso?',
  ),
  'Todos os pisos': ('All floors', 'Todos los pisos'),
  'Simular que estou perto de…': (
    "Pretend I'm near…",
    'Simular que estoy cerca de…',
  ),
  'Na demonstração, escolher um ponto representa o celular '
      'detectar o beacon BLE daquele lugar.': (
    'In the demo, choosing a point stands for the phone '
        'detecting the BLE beacon at that place.',
    'En la demostración, elegir un punto representa que el celular '
        'detecta el beacon BLE de ese lugar.',
  ),
  '(simulado)': ('(simulated)', '(simulado)'),
  'Depois de': ('After', 'Después de'),
  'Você está aqui': ('You are here', 'Estás aquí'),
  'Trocar': ('Change', 'Cambiar'),
  'Parada {n}': ('Stop {n}', 'Parada {n}'),
  'Remover {nome}': ('Remove {nome}', 'Quitar {nome}'),
  'Buscar loja ou serviço': (
    'Search store or service',
    'Buscar tienda o servicio',
  ),
  'Ex.: banheiro, pizza, livraria': (
    'E.g.: restroom, pizza, bookstore',
    'Ej.: baño, pizza, librería',
  ),
  'Limpar busca': ('Clear search', 'Borrar búsqueda'),
  'Cancelar parada': ('Cancel stop', 'Cancelar parada'),

  // Atalhos
  'Banheiro': ('Restroom', 'Baño'),
  'Banheiro acessível': ('Accessible restroom', 'Baño accesible'),
  'Elevador': ('Elevator', 'Ascensor'),
  'Comer': ('Eat', 'Comer'),
  'Saída': ('Exit', 'Salida'),
  'Espaço tranquilo': ('Quiet space', 'Espacio tranquilo'),

  // Linha de resultado
  'Você já está aqui': ("You're already here", 'Ya estás aquí'),
  '{n} min a pé': ('{n} min walk', '{n} min a pie'),
  'Só há caminho com escadas': (
    'Only a path with stairs',
    'Solo hay camino con escaleras',
  ),
  'Sem caminho cadastrado': ('No registered path', 'Sin camino registrado'),
  'aqui': ('here', 'aquí'),

  // Critérios ativos
  'Rotas pelo caminho mais curto. Para evitar escadas, ative '
      '"Rotas sem escadas" nas preferências.': (
    'Routes take the shortest path. To avoid stairs, turn on '
        '"Step-free routes" in preferences.',
    'Rutas por el camino más corto. Para evitar escaleras, activa '
        '"Rutas sin escaleras" en las preferencias.',
  ),
  'Rotas consideram suas preferências:': (
    'Routes follow your preferences:',
    'Las rutas siguen tus preferencias:',
  ),
  'sem escadas': ('no stairs', 'sin escaleras'),
  'prefere elevador': ('prefers elevator', 'prefiere ascensor'),
  'evita movimento': ('avoids crowds', 'evita multitudes'),

  // Sem resultados
  'Nada encontrado com esses filtros.': (
    'Nothing found with these filters.',
    'No se encontró nada con estos filtros.',
  ),
  'Nada encontrado para "{q}".': (
    'Nothing found for "{q}".',
    'No se encontró nada para "{q}".',
  ),
  'Tente "banheiro", "elevador" ou "comida", ou limpe os filtros.': (
    'Try "restroom", "elevator" or "food", or clear the filters.',
    'Prueba "baño", "ascensor" o "comida", o borra los filtros.',
  ),
  'Limpar busca e filtros': (
    'Clear search and filters',
    'Borrar búsqueda y filtros',
  ),

  // ---------------------------------------------------------------------
  // Tela da rota
  // ---------------------------------------------------------------------
  'Voltar para a busca': ('Back to search', 'Volver a la búsqueda'),
  'Rota até': ('Route to', 'Ruta hasta'),
  '{nome} já é a última parada.': (
    '{nome} is already the last stop.',
    '{nome} ya es la última parada.',
  ),
  '{nome} adicionada como parada {n}. Rota recalculada.': (
    '{nome} added as stop {n}. Route recalculated.',
    '{nome} agregada como parada {n}. Ruta recalculada.',
  ),
  '{nome} removida. Rota recalculada.': (
    '{nome} removed. Route recalculated.',
    '{nome} quitada. Ruta recalculada.',
  ),
  '{nome} agora é a parada {n}. Rota recalculada.': (
    '{nome} is now stop {n}. Route recalculated.',
    '{nome} ahora es la parada {n}. Ruta recalculada.',
  ),
  'Saindo de': ('Leaving from', 'Saliendo de'),
  'Destino': ('Destination', 'Destino'),
  'Destino final': ('Final destination', 'Destino final'),
  'Sem caminho compatível até aqui': (
    'No suitable path to here',
    'Sin camino compatible hasta aquí',
  ),
  'Mover {nome} para antes': ('Move {nome} earlier', 'Mover {nome} antes'),
  'Mover {nome} para depois': ('Move {nome} later', 'Mover {nome} después'),
  'Adicionar outra parada': ('Add another stop', 'Agregar otra parada'),
  'Você já está aqui.': ("You're already here.", 'Ya estás aquí.'),
  'Tem degraus': ('Has steps', 'Tiene escalones'),
  'Usa elevador': ('Uses elevator', 'Usa ascensor'),
  'Evita movimento': ('Avoids crowds', 'Evita multitudes'),
  '{n} paradas': ('{n} stops', '{n} paradas'),
  'Esta rota tem degraus. Se precisar evitar escadas, '
      'ative "Rotas sem escadas" nas preferências.': (
    'This route has steps. If you need to avoid stairs, '
        'turn on "Step-free routes" in preferences.',
    'Esta ruta tiene escalones. Si necesitas evitar escaleras, '
        'activa "Rutas sin escaleras" en las preferencias.',
  ),
  'Iniciar navegação': ('Start navigation', 'Iniciar navegación'),
  'Abre a bússola e o mapa interativo': (
    'Opens the compass and the interactive map',
    'Abre la brújula y el mapa interactivo',
  ),
  'Passo a passo': ('Step by step', 'Paso a paso'),
  'Até o destino final: {nome}': (
    'To the final destination: {nome}',
    'Hasta el destino final: {nome}',
  ),
  'Até a parada {n}: {nome}': (
    'To stop {n}: {nome}',
    'Hasta la parada {n}: {nome}',
  ),
  '{d} metros, cerca de {m} minutos.': (
    '{d} meters, about {m} minutes.',
    '{d} metros, unos {m} minutos.',
  ),
  'Pisos:': ('Floors:', 'Pisos:'),
  'para': ('to', 'a'),
  'cerca de {n} min a pé': ('about {n} min walk', 'unos {n} min a pie'),
  'Sobre o destino': ('About the destination', 'Sobre el destino'),
  'Piso': ('Floor', 'Piso'),
  'Horário': ('Opening hours', 'Horario'),
  'Descrição': ('Description', 'Descripción'),
  'Recursos': ('Features', 'Recursos'),
  'Informações de demonstração, com dados fictícios.': (
    'Demo information, with fictional data.',
    'Información de demostración, con datos ficticios.',
  ),
  'Sua preferência "Rotas sem escadas" continua ativa. '
      'O app não muda isso sozinho.': (
    'Your "Step-free routes" preference is still on. '
        "The app doesn't change it on its own.",
    'Tu preferencia "Rutas sin escaleras" sigue activa. '
        'La app no la cambia por sí sola.',
  ),
  'Nenhum percurso cadastrado liga estes dois pontos.': (
    'No registered path connects these two points.',
    'Ningún recorrido registrado une estos dos puntos.',
  ),
  'Remover a parada {nome}': (
    'Remove the stop {nome}',
    'Quitar la parada {nome}',
  ),
  'Escolher outro destino': (
    'Choose another destination',
    'Elegir otro destino',
  ),
  'Pedir ajuda (Ajuda+)': ('Ask for help (Ajuda+)', 'Pedir ayuda (Ajuda+)'),
  'O Ajuda+ chega numa próxima etapa (simulado).': (
    'Ajuda+ arrives in a later stage (simulated).',
    'Ajuda+ llega en una próxima etapa (simulado).',
  ),
  'Revisar minhas preferências': (
    'Review my preferences',
    'Revisar mis preferencias',
  ),
  'Abre as preferências. Nada muda sem sua escolha.': (
    'Opens preferences. Nothing changes without your choice.',
    'Abre las preferencias. Nada cambia sin tu elección.',
  ),

  // Resumo falado ao abrir a rota (Voz).
  'Rota até {destino}: {d} metros, cerca de {m} minutos a pé.': (
    'Route to {destino}: {d} meters, about {m} minutes on foot.',
    'Ruta hasta {destino}: {d} metros, unos {m} minutos a pie.',
  ),

  // ---------------------------------------------------------------------
  // Mensagens de domain/rules exibidas nestas telas
  // ---------------------------------------------------------------------
  'Não informado': ('Not provided', 'No informado'),
  'Não há caminho sem escadas até {x}.': (
    'There is no step-free path to {x}.',
    'No hay camino sin escaleras hasta {x}.',
  ),
  'Não encontramos caminho cadastrado até {x}.': (
    "We couldn't find a registered path to {x}.",
    'No encontramos camino registrado hasta {x}.',
  ),
  // Com trecho indisponível simulado (ex.: elevador em manutenção).
  'Não há caminho sem escadas até {x}. Em manutenção: {y}.': (
    'There is no step-free path to {x}. Under maintenance: {y}.',
    'No hay camino sin escaleras hasta {x}. En mantenimiento: {y}.',
  ),
  'Não encontramos caminho cadastrado até {x}. Em manutenção: {y}.': (
    "We couldn't find a registered path to {x}. Under maintenance: {y}.",
    'No encontramos camino registrado hasta {x}. En mantenimiento: {y}.',
  ),
  // Instruções de etapa (RotaMotor.instrucao): traduzidas em
  // textos_navegacao.dart, que é dona desses textos.

  // ---------------------------------------------------------------------
  // Dados do catálogo (assets/data/catalogo.json): textos genéricos.
  // Nomes de lojas e lugares ficam como estão.
  // ---------------------------------------------------------------------
  // Pisos
  'Térreo': ('Ground floor', 'Planta baja'),
  'Mezanino': ('Mezzanine', 'Entrepiso'),
  '1º piso': ('1st floor', '1.er piso'),
  '2º piso': ('2nd floor', '2.º piso'),
  '3º piso': ('3rd floor', '3.er piso'),
  // Categorias
  'Serviços': ('Services', 'Servicios'),
  'Saídas': ('Exits', 'Salidas'),
  'Lazer': ('Leisure', 'Ocio'),
  'Lojas': ('Stores', 'Tiendas'),
  'Banheiros': ('Restrooms', 'Baños'),
  'Circulação': ('Getting around', 'Circulación'),
  'Alimentação': ('Food', 'Alimentación'),
  // Recursos
  'Balcão rebaixado': ('Lowered counter', 'Mostrador bajo'),
  'Atendimento por escrito': ('Written service', 'Atención por escrito'),
  'Piso tátil': ('Tactile paving', 'Piso táctil'),
  'Vagas largas': ('Wide parking spaces', 'Plazas amplias'),
  'Piso nivelado': ('Level floor', 'Piso nivelado'),
  'Porta automática': ('Automatic door', 'Puerta automática'),
  'Espaço amplo': ('Spacious area', 'Espacio amplio'),
  'Corredores largos': ('Wide aisles', 'Pasillos anchos'),
  'Provador acessível': ('Accessible fitting room', 'Probador accesible'),
  'Livros em braille': ('Braille books', 'Libros en braille'),
  'Assentos': ('Seating', 'Asientos'),
  'Barras de apoio': ('Grab bars', 'Barras de apoyo'),
  'Espaço para giro de cadeira': (
    'Wheelchair turning space',
    'Espacio de giro para silla de ruedas',
  ),
  'Pia acessível': ('Accessible sink', 'Lavabo accesible'),
  'Trocador': ('Changing table', 'Cambiador'),
  'Poltrona': ('Armchair', 'Sillón'),
  'Baixo estímulo': ('Low stimulation', 'Bajo estímulo'),
  'Sem música': ('No music', 'Sin música'),
  'Braille': ('Braille', 'Braille'),
  'Aviso sonoro': ('Audio signal', 'Aviso sonoro'),
  'Mesas adaptadas': ('Adapted tables', 'Mesas adaptadas'),
  'Cardápio ampliado': ('Large-print menu', 'Menú ampliado'),
  // Horários
  'Até 21h': ('Until 9 pm', 'Hasta las 21 h'),
  '10h às 22h': ('10 am to 10 pm', 'De 10 a 22 h'),
  // Descrições
  'Balcão rebaixado. Aceita conversa por escrito.': (
    'Lowered counter. Written conversation welcome.',
    'Mostrador bajo. Acepta conversación por escrito.',
  ),
  'Vagas largas perto da Entrada Principal.': (
    'Wide spaces near the Main Entrance.',
    'Plazas amplias cerca de la Entrada Principal.',
  ),
  'Porta automática e piso tátil.': (
    'Automatic door and tactile paving.',
    'Puerta automática y piso táctil.',
  ),
  'Acesso pela avenida lateral.': (
    'Access from the side avenue.',
    'Acceso por la avenida lateral.',
  ),
  'Área aberta para eventos. Pode ter muito movimento e som.': (
    'Open area for events. May be crowded and loud.',
    'Área abierta para eventos. Puede haber mucha gente y sonido.',
  ),
  'Loja de departamento fictícia.': (
    'Fictional department store.',
    'Tienda departamental ficticia.',
  ),
  'Utilidades para casa.': ('Home goods.', 'Artículos para el hogar.'),
  'Ótica fictícia.': ('Fictional optician.', 'Óptica ficticia.'),
  'Livros e papelaria. Tem livros em braille.': (
    'Books and stationery. Has braille books.',
    'Libros y papelería. Tiene libros en braille.',
  ),
  'Feminino e masculino.': ("Women's and men's.", 'Femenino y masculino.'),
  'Cabine ampla com barras de apoio.': (
    'Spacious stall with grab bars.',
    'Cabina amplia con barras de apoyo.',
  ),
  'Fraldário e área de amamentação.': (
    'Baby changing and nursing area.',
    'Cambiador y área de lactancia.',
  ),
  'Sala com pouca luz e sem música, para pausar de ruídos.': (
    'Dim room without music, to take a break from noise.',
    'Sala con poca luz y sin música, para descansar del ruido.',
  ),
  'Botões em braille e aviso sonoro de andar.': (
    'Braille buttons and audio floor announcements.',
    'Botones en braille y aviso sonoro de piso.',
  ),
  'Exposição de arte. Acesso somente por escada.': (
    'Art exhibition. Access by stairs only.',
    'Exposición de arte. Acceso solo por escalera.',
  ),
  'Mesas com espaço para cadeira de rodas e cardápio ampliado.': (
    'Tables with room for wheelchairs and a large-print menu.',
    'Mesas con espacio para silla de ruedas y menú ampliado.',
  ),
  'Restaurante de comida regional (fictício).': (
    'Regional food restaurant (fictional).',
    'Restaurante de comida regional (ficticio).',
  ),
  'Pizzaria fictícia.': ('Fictional pizzeria.', 'Pizzería ficticia.'),
  'Experiência com luzes e sons. Pode ter estímulos intensos.': (
    'Light and sound experience. May be intense.',
    'Experiencia con luces y sonidos. Puede tener estímulos intensos.',
  ),

  // ---------------------------------------------------------------------
  // Rota adaptada x rota mais usada e simulação de manutenção
  // ---------------------------------------------------------------------
  'Rota adaptada para você': ('Route adapted for you', 'Ruta adaptada para ti'),
  'Rota mais usada': ('Most used route', 'Ruta más usada'),
  'Para você': ('For you', 'Para ti'),
  'Evita:': ('Avoids:', 'Evita:'),
  'Usa:': ('Uses:', 'Usa:'),
  'Desvio:': ('Detour:', 'Desvío:'),
  'Troca de piso:': ('Floor change:', 'Cambio de piso:'),
  'Sem troca de piso': ('No floor change', 'Sin cambio de piso'),
  'escada rolante': ('escalator', 'escalera mecánica'),
  'escada': ('stairs', 'escalera'),
  'degraus': ('steps', 'escalones'),
  'elevador': ('elevator', 'ascensor'),
  'rampa': ('ramp', 'rampa'),
  'Rota mais usada: {m} metros, cerca de {min} minutos.': (
    'Most used route: {m} meters, about {min} minutes.',
    'Ruta más usada: {m} metros, unos {min} minutos.',
  ),
  'Para você: {m} metros, cerca de {min} minutos.': (
    'For you: {m} meters, about {min} minutes.',
    'Para ti: {m} metros, unos {min} minutos.',
  ),
  '{m} metros e {min} min a mais.': (
    '{m} meters and {min} min more.',
    '{m} metros y {min} min más.',
  ),
  'Simular elevador em manutenção': (
    'Simulate elevator under maintenance',
    'Simular ascensor en mantenimiento',
  ),
  'Simulação para demonstração: recalcula a rota como se o '
      'elevador parasse. Nada muda no shopping.': (
    'Demo simulation: recalculates the route as if the elevator stopped. '
        'Nothing changes in the mall.',
    'Simulación de demostración: recalcula la ruta como si el ascensor se '
        'detuviera. Nada cambia en el centro comercial.',
  ),
  'Simulação: elevador em manutenção. '
      'Desligue a simulação para voltar à rota pelo elevador.': (
    'Simulation: elevator under maintenance. '
        'Turn off the simulation to get the elevator route back.',
    'Simulación: ascensor en mantenimiento. '
        'Desactiva la simulación para volver a la ruta por el ascensor.',
  ),
  'Simulação: elevador em manutenção. Rota recalculada.': (
    'Simulation: elevator under maintenance. Route recalculated.',
    'Simulación: ascensor en mantenimiento. Ruta recalculada.',
  ),
  'Simulação encerrada. Rota recalculada.': (
    'Simulation ended. Route recalculated.',
    'Simulación terminada. Ruta recalculada.',
  ),
};
