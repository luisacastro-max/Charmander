/// Regras do "último metro": achar objetos perto do visitante com a câmera.
///
/// Tudo aqui é puro (sem Flutter) para poder testar: dado o que a câmera
/// "vê", decide o ritmo da vibração e a frase a anunciar.
library;

/// Objetos que o visitante pode procurar ao chegar no destino.
enum Alvo {
  porta('Porta'),
  balcao('Balcão'),
  cadeira('Cadeira'),
  caixa('Caixa'),
  elevador('Elevador'),
  banheiro('Banheiro');

  const Alvo(this.nome);
  final String nome;
}

/// Um objeto presente no ambiente (cena simulada). [anguloGraus] é a
/// direção em relação à frente inicial do visitante (positivo = direita).
class ObjetoCena {
  const ObjetoCena(this.alvo, this.anguloGraus, this.distanciaM);
  final Alvo alvo;
  final double anguloGraus;
  final double distanciaM;
}

/// Um objeto que a câmera detectou no quadro atual.
///
/// [deslocamento] vai de -1 (borda esquerda) a 1 (borda direita); 0 é o
/// centro da imagem. É o que um detector real (ML Kit/TFLite) entrega a
/// partir da caixa delimitadora.
class Deteccao {
  const Deteccao(this.alvo, this.deslocamento, this.distanciaM);
  final Alvo alvo;
  final double deslocamento;
  final double distanciaM;
}

/// Campo de visão horizontal típico de câmera de celular.
const campoDeVisaoGraus = 60.0;

/// Abaixo deste deslocamento o objeto conta como "bem à frente".
const limiteCentro = 0.15;

/// Normaliza um ângulo para o intervalo (-180, 180].
double normalizar(double graus) {
  var g = graus % 360;
  if (g > 180) g -= 360;
  if (g <= -180) g += 360;
  return g;
}

/// O que a câmera vê apontada para [direcaoGraus] numa [cena].
/// Mais perto do centro primeiro.
List<Deteccao> detectar(List<ObjetoCena> cena, double direcaoGraus) {
  const meio = campoDeVisaoGraus / 2;
  final vistos = <Deteccao>[];
  for (final o in cena) {
    final dif = normalizar(o.anguloGraus - direcaoGraus);
    if (dif.abs() <= meio) {
      vistos.add(Deteccao(o.alvo, dif / meio, o.distanciaM));
    }
  }
  vistos.sort((a, b) => a.deslocamento.abs().compareTo(b.deslocamento.abs()));
  return vistos;
}

String distanciaEmTexto(double m) => m < 2
    ? 'perto'
    : m < 5
    ? 'a poucos passos'
    : 'longe';

String ladoEmTexto(double deslocamento) {
  if (deslocamento.abs() < limiteCentro) return 'à frente';
  final forte = deslocamento.abs() > .6;
  if (deslocamento > 0) return forte ? 'à direita' : 'um pouco à direita';
  return forte ? 'à esquerda' : 'um pouco à esquerda';
}

/// "Cadeira, à frente, perto."
String descrever(Deteccao d) =>
    '${d.alvo.nome}, ${ladoEmTexto(d.deslocamento)}, '
    '${distanciaEmTexto(d.distanciaM)}.';

/// Resposta ao "O que tem aqui?".
String descreverCena(List<Deteccao> vistos) => vistos.isEmpty
    ? 'Não reconheço nada aqui. Gire devagar.'
    : vistos.map(descrever).join(' ');

/// Ritmo da vibração no modo "procurar".
enum Forca { leve, media, forte }

class Sinal {
  const Sinal({
    required this.intervalo,
    required this.forca,
    required this.centralizado,
    this.deteccao,
  });

  /// Tempo entre um pulso e outro: quanto menor, mais "quente".
  final Duration intervalo;
  final Forca forca;

  /// O alvo está bem à frente (vibração quase contínua).
  final bool centralizado;
  final Deteccao? deteccao;

  bool get encontrado => deteccao != null;
}

/// Quente ou frio: decide a vibração para procurar [alvo] em [vistos].
///
/// - Fora da imagem: pulsos lentos e leves (procurando).
/// - Entrando na imagem: pulsos aceleram conforme chega ao centro.
/// - Bem à frente: pulsos fortes quase contínuos.
Sinal sinalPara(Alvo alvo, List<Deteccao> vistos) {
  final d = vistos.where((v) => v.alvo == alvo).firstOrNull;
  if (d == null) {
    return const Sinal(
      intervalo: Duration(milliseconds: 1000),
      forca: Forca.leve,
      centralizado: false,
    );
  }
  final x = d.deslocamento.abs().clamp(0.0, 1.0);
  if (x < limiteCentro) {
    return Sinal(
      intervalo: const Duration(milliseconds: 90),
      forca: Forca.forte,
      centralizado: true,
      deteccao: d,
    );
  }
  // De 550 ms na borda até 150 ms perto do centro.
  final ms = (150 + 400 * (x - limiteCentro) / (1 - limiteCentro)).round();
  return Sinal(
    intervalo: Duration(milliseconds: ms),
    forca: Forca.media,
    centralizado: false,
    deteccao: d,
  );
}

/// Ambiente de demonstração: o visitante acabou de chegar ao destino e
/// está parado perto da entrada. Começa olhando para 0° (nenhum alvo
/// bem à frente), para precisar girar e sentir o "quente ou frio".
const cenaDemonstracao = [
  ObjetoCena(Alvo.porta, 45, 3),
  ObjetoCena(Alvo.cadeira, 100, 1.5),
  ObjetoCena(Alvo.balcao, -40, 6),
  ObjetoCena(Alvo.caixa, -60, 7),
  ObjetoCena(Alvo.banheiro, 160, 9),
  ObjetoCena(Alvo.elevador, -120, 12),
];
