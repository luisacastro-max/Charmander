/// Ajuda+: pedido de assistência e seus estados demonstrativos
/// (RF36–RF43, RN11). Nada aqui aciona equipe real.
library;

/// O que está acontecendo (RF36).
enum CategoriaAjuda {
  encontrarLocal('Não consigo encontrar meu destino'),
  acompanhamento('Preciso de acompanhamento'),
  barreira('Encontrei uma barreira no caminho'),
  comunicacao('Preciso de ajuda para me comunicar'),
  funcionario('Preciso de apoio de um funcionário');

  const CategoriaAjuda(this.texto);
  final String texto;
}

/// Como o visitante prefere ser atendido. É preferência, não garantia
/// de disponibilidade (RN11).
enum FormaAtendimento {
  mensagem('Mensagem de texto'),
  audio('Áudio'),
  presencial('Atendimento presencial');

  const FormaAtendimento(this.texto);
  final String texto;
}

/// Estados demonstrativos do acompanhamento (RF40).
enum EstadoPedido {
  registrada('Solicitação registrada'),
  atribuido('Atendimento atribuído'),
  aCaminho('Apoio a caminho'),
  concluida('Concluída');

  const EstadoPedido(this.texto);
  final String texto;
}

class PedidoAjuda {
  const PedidoAjuda({
    required this.categoria,
    required this.forma,
    required this.local,
    this.detalhes = '',
    this.estado = EstadoPedido.registrada,
    this.cancelado = false,
  });

  final CategoriaAjuda categoria;
  final FormaAtendimento forma;

  /// "Balcão de Informações · Térreo" — confirmado pelo visitante (RF37).
  final String local;
  final String detalhes;
  final EstadoPedido estado;
  final bool cancelado;

  bool get concluido => estado == EstadoPedido.concluida;

  /// Ainda dá para cancelar ou avançar (demonstração).
  bool get emAndamento => !cancelado && !concluido;

  /// Próximo estado da demonstração. Parado se cancelado ou concluído.
  PedidoAjuda avancar() => emAndamento
      ? _copia(estado: EstadoPedido.values[estado.index + 1])
      : this;

  /// RF41: cancelar só enquanto está em andamento.
  PedidoAjuda cancelar() => emAndamento ? _copia(cancelado: true) : this;

  PedidoAjuda _copia({EstadoPedido? estado, bool? cancelado}) => PedidoAjuda(
    categoria: categoria,
    forma: forma,
    local: local,
    detalhes: detalhes,
    estado: estado ?? this.estado,
    cancelado: cancelado ?? this.cancelado,
  );

  /// Frase curta para o leitor de tela a cada mudança de estado.
  String get aviso {
    if (cancelado) return 'Solicitação cancelada.';
    return switch (estado) {
      EstadoPedido.registrada => 'Solicitação registrada.',
      EstadoPedido.atribuido => 'Um atendente recebeu seu pedido.',
      EstadoPedido.aCaminho => 'O apoio está a caminho de $local.',
      EstadoPedido.concluida => 'Atendimento concluído.',
    };
  }
}
