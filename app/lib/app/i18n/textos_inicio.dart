import 'i18n.dart';

/// Traduções: Boas-vindas e preferências.
/// Chave = texto em português, exatamente como aparece no código.
/// Use {nome} para partes variáveis. Nomes de lojas e lugares não se traduzem.
///
/// "Acessa+" e "Ajuda+" são nomes da marca e ficam como estão. Os nomes dos
/// idiomas no seletor aparecem sempre na própria língua.
const Map<String, Traducao> textosInicio = {
  // ── Marca ──
  'Acessa mais': ('Acessa plus', 'Acessa más'),

  // ── Boas-vindas ──
  'Acessibilidade que conecta pessoas.': (
    'Accessibility that connects people.',
    'Accesibilidad que conecta personas.',
  ),
  'Acessibilidade': ('Accessibility', 'Accesibilidad'),
  'que ': ('that ', 'que '),
  'conecta': ('connects', 'conecta'),
  'pessoas.': ('people.', 'personas.'),
  'Comunique-se do seu jeito, encontre caminhos que fazem '
      'sentido para você e peça apoio quando quiser. '
      'Sem cadastro e sem precisar explicar nada.': (
    'Communicate your way, find routes that make sense for you and ask '
        'for support whenever you want. No sign-up and nothing to explain.',
    'Comunícate a tu manera, encuentra caminos que tengan sentido para ti '
        'y pide apoyo cuando quieras. Sin registro y sin tener que explicar '
        'nada.',
  ),
  'Comunicação Universal': (
    'Universal Communication',
    'Comunicación Universal',
  ),
  'Texto, voz, cartões e frases em 3 idiomas.': (
    'Text, voice, cards and phrases in 3 languages.',
    'Texto, voz, tarjetas y frases en 3 idiomas.',
  ),
  'Navegação Viva': ('Live Navigation', 'Navegación Viva'),
  'Rotas que respeitam o seu jeito de se locomover.': (
    'Routes that respect the way you get around.',
    'Rutas que respetan tu forma de desplazarte.',
  ),
  'Peça apoio só quando quiser, do seu jeito.': (
    'Ask for support only when you want, your way.',
    'Pide apoyo solo cuando quieras, a tu manera.',
  ),
  'Começar': ('Start', 'Empezar'),
  'Abre as preferências de acessibilidade': (
    'Opens the accessibility preferences',
    'Abre las preferencias de accesibilidad',
  ),
  'Configurar depois': ('Set up later', 'Configurar después'),
  'Protótipo de demonstração: shopping, beacons e '
      'atendimentos são simulados, com dados fictícios.': (
    'Demo prototype: the mall, beacons and assistance are simulated, '
        'with fictional data.',
    'Prototipo de demostración: el centro comercial, los beacons y la '
        'atención son simulados, con datos ficticios.',
  ),

  // ── Mapa vivo ──
  'Ilustração: no mapa do shopping, o caminho encontra uma escada, '
      'desvia pelo elevador e chega ao destino.': (
    'Illustration: on the mall map, the route meets a staircase, '
        'goes around it by elevator and reaches the destination.',
    'Ilustración: en el mapa del centro comercial, el camino encuentra una '
        'escalera, se desvía por el ascensor y llega al destino.',
  ),
  'Entrada': ('Entrance', 'Entrada'),
  'Escada': ('Stairs', 'Escalera'),
  'Elevador': ('Elevator', 'Ascensor'),
  'Destino': ('Destination', 'Destino'),

  // ── Preferências ──
  'Voltar': ('Back', 'Volver'),
  'Continuar': ('Continue', 'Continuar'),
  'Minha acessibilidade': ('My accessibility', 'Mi accesibilidad'),
  'Combine o que ajuda você. Não é preciso declarar nenhuma '
      'deficiência. Dá para mudar quando quiser.': (
    'Mix what helps you. You don\'t need to state any disability. '
        'You can change it anytime.',
    'Combina lo que te ayuda. No hace falta declarar ninguna '
        'discapacidad. Puedes cambiarlo cuando quieras.',
  ),
  'Nenhum recurso ativo': ('No features on', 'Ningún recurso activo'),
  '1 recurso ativo': ('1 feature on', '1 recurso activo'),
  '{n} recursos ativos': ('{n} features on', '{n} recursos activos'),
  'Ver e ouvir': ('See and hear', 'Ver y oír'),
  'Texto ampliado': ('Larger text', 'Texto ampliado'),
  'Letras maiores em todo o app.': (
    'Bigger letters across the app.',
    'Letras más grandes en toda la app.',
  ),
  'Alto contraste': ('High contrast', 'Alto contraste'),
  'Fundo preto, texto branco e destaques amarelos.': (
    'Black background, white text and yellow highlights.',
    'Fondo negro, texto blanco y destacados amarillos.',
  ),
  'Orientações por áudio': ('Audio guidance', 'Indicaciones por audio'),
  'Instruções faladas durante a navegação.': (
    'Spoken instructions while you navigate.',
    'Instrucciones habladas durante la navegación.',
  ),
  'Orientações por áudio ligadas.': (
    'Audio guidance on.',
    'Indicaciones por audio activadas.',
  ),
  'Comunicar': ('Communicate', 'Comunicar'),
  'Comunicação por texto': ('Text communication', 'Comunicación por texto'),
  'A Central abre direto na conversa escrita.': (
    'The Help Desk opens straight in the written chat.',
    'La Central abre directo en la conversación escrita.',
  ),
  'Mensagens rápidas em destaque': (
    'Quick messages first',
    'Mensajes rápidos destacados',
  ),
  'Frases prontas aparecem primeiro.': (
    'Ready-made phrases show up first.',
    'Las frases listas aparecen primero.',
  ),
  'Locomover-se': ('Getting around', 'Desplazarse'),
  'Rotas sem escadas': ('Step-free routes', 'Rutas sin escaleras'),
  'Nenhuma rota passará por degraus.': (
    'No route will use steps.',
    'Ninguna ruta pasará por escalones.',
  ),
  'Preferência por elevadores': ('Prefer elevators', 'Preferir ascensores'),
  'Elevadores têm prioridade nas trocas de piso.': (
    'Elevators come first when changing floors.',
    'Los ascensores tienen prioridad al cambiar de piso.',
  ),
  'Conforto e clareza': ('Comfort and clarity', 'Comodidad y claridad'),
  'Redução de estímulos': ('Fewer stimuli', 'Menos estímulos'),
  'Sem animações e com cores mais suaves.': (
    'No animations and softer colors.',
    'Sin animaciones y con colores más suaves.',
  ),
  'Navegação simplificada': (
    'Simplified navigation',
    'Navegación simplificada',
  ),
  'Menos informações em cada tela.': (
    'Less information on each screen.',
    'Menos información en cada pantalla.',
  ),
  'Ativado': ('On', 'Activado'),
  'Desativado': ('Off', 'Desactivado'),
  'Idioma': ('Language', 'Idioma'),
  'Muda os textos do app, a voz e as frases prontas.': (
    'Changes the app texts, the voice and the ready-made phrases.',
    'Cambia los textos de la app, la voz y las frases listas.',
  ),
  'Idioma: {idioma}.': ('Language: {idioma}.', 'Idioma: {idioma}.'),
  'Apagar minhas preferências': (
    'Delete my preferences',
    'Borrar mis preferencias',
  ),
  'Apaga as escolhas salvas neste aparelho. Pede confirmação.': (
    'Deletes the choices saved on this device. Asks for confirmation.',
    'Borra las opciones guardadas en este dispositivo. Pide confirmación.',
  ),
  'Suas escolhas ficam salvas só neste aparelho. Nada é '
      'enviado para fora.': (
    'Your choices are saved only on this device. Nothing is sent out.',
    'Tus opciones se guardan solo en este dispositivo. No se envía nada '
        'afuera.',
  ),
  'Apagar suas preferências?': (
    'Delete your preferences?',
    '¿Borrar tus preferencias?',
  ),
  'As escolhas salvas neste aparelho serão apagadas e o app volta '
      'ao padrão. Dá para escolher de novo quando quiser.': (
    'The choices saved on this device will be deleted and the app goes '
        'back to default. You can choose again anytime.',
    'Las opciones guardadas en este dispositivo se borrarán y la app '
        'vuelve a lo predeterminado. Puedes elegir de nuevo cuando quieras.',
  ),
  'Cancelar': ('Cancel', 'Cancelar'),
  'Apagar': ('Delete', 'Borrar'),
  'Preferências apagadas deste aparelho.': (
    'Preferences deleted from this device.',
    'Preferencias borradas de este dispositivo.',
  ),

  // ── Prévia ao vivo ──
  'Prévia ao vivo': ('Live preview', 'Vista previa en vivo'),
  'Prévia ao vivo.': ('Live preview.', 'Vista previa en vivo.'),
  'A Central abre na conversa escrita.': (
    'The Help Desk opens in the written chat.',
    'La Central abre en la conversación escrita.',
  ),
  'A Central abre nos cartões de comunicação.': (
    'The Help Desk opens on the communication cards.',
    'La Central abre en las tarjetas de comunicación.',
  ),
  'Sem escadas': ('No stairs', 'Sin escaleras'),
  'Rota mais curta': ('Shortest route', 'Ruta más corta'),
  'Áudio ligado': ('Audio on', 'Audio activado'),
  'Frases rápidas': ('Quick phrases', 'Frases rápidas'),
  'Sem animações': ('No animations', 'Sin animaciones'),
  'Onde fica o banheiro?': ('Where is the restroom?', '¿Dónde está el baño?'),

  // Atalho "Como você vai circular hoje?" (não é salvo).
  'Como você vai circular hoje?': (
    'How will you get around today?',
    '¿Cómo vas a desplazarte hoy?',
  ),
  'Atalho: liga os recursos de rota abaixo. Não guardamos esta escolha.': (
    "Shortcut: turns on the route features below. We don't save this choice.",
    'Atajo: activa los recursos de ruta de abajo. No guardamos esta elección.',
  ),
  'Sobre rodas': ('On wheels', 'Sobre ruedas'),
  'cadeira de rodas, carrinho de bebê, mala': (
    'wheelchair, stroller, suitcase',
    'silla de ruedas, cochecito, maleta',
  ),
  'Com apoio': ('With support', 'Con apoyo'),
  'andador, muletas, bengala': (
    'walker, crutches, cane',
    'andador, muletas, bastón',
  ),
  'Liga Rotas sem escadas e Preferência por elevadores': (
    'Turns on Step-free routes and Prefer elevators',
    'Activa Rutas sin escaleras y Preferir ascensores',
  ),
  'Ativamos "Rotas sem escadas" e "Preferência por elevadores". '
      'Dá para desligar cada um logo abaixo.': (
    'We turned on "Step-free routes" and "Prefer elevators". '
        'You can turn each one off just below.',
    'Activamos "Rutas sin escaleras" y "Preferir ascensores". '
        'Puedes desactivar cada una justo abajo.',
  ),
};
