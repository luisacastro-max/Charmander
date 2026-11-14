import 'package:flutter/material.dart';

/// Ícones dos locais (chave `icone` do catálogo). Sempre acompanhados de
/// texto — o ícone nunca é a única informação (RNF04).
IconData iconeDoLocal(String chave) => switch (chave) {
  'info' => Icons.info_outline,
  'estacionamento' => Icons.local_parking,
  'saida' => Icons.logout,
  'eventos' => Icons.celebration_outlined,
  'loja' => Icons.storefront_outlined,
  'banheiro' => Icons.wc,
  'banheiro_acessivel' => Icons.accessible,
  'familia' => Icons.baby_changing_station,
  'tranquilo' => Icons.spa_outlined,
  'elevador' => Icons.elevator_outlined,
  'galeria' => Icons.palette_outlined,
  'alimentacao' => Icons.restaurant,
  'imersivo' => Icons.auto_awesome_outlined,
  _ => Icons.place_outlined,
};
