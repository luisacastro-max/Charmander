# Etapa 1 — Amostra visual do Acessa+

Situação: **proposta para revisão**. Nada aqui é a identidade visual definitiva.

## Histórico

| Rodada | Decisão |
|---|---|
| 1 | Primeira amostra: fundo creme, estilo "adesivo", animações discretas |
| 2 | Pedido da equipe: mais impacto visual. Paleta escolhida: **B · Noite neon**. Fundo com bolinhas descartado; no lugar entrou o **mapa vivo**, que conta o problema |

## Direção visual

**"Noite neon com propósito."** Energia de palco, mas cada efeito explica algo.

| Referência | O que aproveitamos | O que evitamos |
|---|---|---|
| [Pibaru](https://pibaru.com/) | Títulos arredondados, cartões "adesivo" (borda forte + sombra deslocada sem desfoque), blocos de cor | Mascote copiado |
| [Nexo](https://www.somosnexo.app/pt) | Fundo noturno, marca-texto inclinado atrás de uma palavra, tipografia de impacto | Violeta e brilhos difusos (pouco contraste) |
| [GSAP skills](https://github.com/greensock/gsap-skills) | Princípios: sequência, stagger, easing, `matchMedia` + movimento reduzido | A biblioteca em si (JavaScript; o app é Flutter) |
| [motion-and-storytelling](https://skills.sh/dembrandt/dembrandt-skills/motion-and-storytelling) | 12 princípios da Disney na interface, tempos de 80–650 ms, cascata, respeito ao movimento reduzido | — |
| [taste-skill](https://github.com/Leonxlnx/taste-skill) | Regras: tudo responde ao toque, sem loop longo, nada escondido com movimento reduzido, sem violeta | As ferramentas (feitas para páginas HTML) |

## Tipografia

| Uso | Fonte | Motivo |
|---|---|---|
| Títulos | Fredoka (700/600) | Arredondada, acolhedora e com impacto |
| Texto e botões | Atkinson Hyperlegible | Criada pelo Braille Institute para leitura por pessoas com baixa visão |

As fontes vêm pela internet (pacote `google_fonts`). Na Etapa 2 serão empacotadas no app, para funcionar offline.

Em telas estreitas (360 dp), o título das boas-vindas encolhe por inteiro em vez de quebrar "Acessibilidade" no meio.

## Paleta Noite neon e contraste

| Papel | Cor |
|---|---|
| Fundo | `#111A36` azul-noite |
| Cartões neutros | `#1B2547` |
| Texto / secundário | `#F4F6FF` / `#B8C0E0` |
| Comunicação · marca-texto | `#FF5C9D` rosa |
| Navegação Viva · foco | `#3FE0E0` ciano |
| Ajuda+ · botão principal | `#DFFF5E` limão |
| Texto sobre as cores neon | `#111A36` |
| Aviso de simulação | `#FF9F43` laranja |

| Combinação | Contraste |
|---|---|
| Texto sobre fundo / sobre cartão | 15,90 / 13,89:1 |
| Secundário sobre fundo / sobre cartão | 9,51 / 8,31:1 |
| Texto escuro sobre rosa / ciano / limão | 5,94 / 10,57 / 15,19:1 |
| Laranja de simulação sobre fundo | 8,40:1 |
| Redução de estímulos — texto / secundário | 13,56 / 7,75:1 |
| Redução de estímulos — escuro sobre rosa / ciano / limão | 7,41 / 9,75 / 11,03:1 |
| Alto contraste — branco/preto, preto/amarelo | 21,00 / 16,57:1 |

Todas acima de 4,5:1 (WCAG AA). Fórmula de luminância relativa da WCAG 2.x.

**Cuidado conhecido:** texto claro sobre fundo escuro cansa mais em leituras longas e incomoda pessoas com astigmatismo. Por isso o modo **Alto contraste** e o modo **Redução de estímulos** continuam disponíveis; um tema claro opcional pode ser avaliado depois.

## Componentes

| Componente | Arquivo | Comportamento |
|---|---|---|
| `LivingMap` | `core/widgets/living_map.dart` | Mapa vivo (ver abaixo) |
| `BrandLogo` | `core/widgets/brand_logo.dart` | "+" gira e encaixa; voa entre telas (Hero) |
| `StickerButton` | `core/widgets/sticker_button.dart` | Afunda na sombra neon ao pressionar; foco de 4 px |
| `StickerCard` / `SimulationNotice` | `core/widgets/sticker_card.dart` | Cartão padrão; selo de simulação (RNF10) |
| `PreferenceToggle` | `core/widgets/preference_toggle.dart` | Estado em texto + cor + posição; explosão de pontos ao ativar |
| `ThemeReveal` | `core/widgets/theme_reveal.dart` | Novo tema se espalha em círculo a partir do interruptor |
| `Burst` | `core/widgets/burst.dart` | Explosão curta de pontos (500 ms) |
| `MarkerHighlight` | `core/widgets/marker_highlight.dart` | Marca-texto que se desenha uma vez |
| `Entrance` | `core/widgets/entrance.dart` | Entradas em cascata: subir, leque e giro |

## Mapa vivo — o problema contado em 4 segundos

1. A planta do shopping aparece em linhas finas.
2. O percurso (ciano) sai da **Entrada** e encontra uma **Escada**.
3. A escada recebe um ✕ rosa e o trecho apaga — a barreira.
4. O percurso (limão) desvia pelo **Elevador**; um balão de conversa surge no caminho.
5. O **Destino** acende com um anel.

Toca uma vez e para. Os pontos têm rótulos em texto; leitores de tela ouvem: "Ilustração: no mapa do shopping, o caminho encontra uma escada, desvia pelo elevador e chega ao destino."

## Movimento

| Animação | Duração | Onde |
|---|---|---|
| "+" do logo | 650 ms, elástico | Boas-vindas |
| Mapa vivo | 4,2 s, uma vez | Boas-vindas |
| Título linha a linha + marca-texto | 320 ms por linha; marca-texto 600 ms | Boas-vindas |
| Pilares em leque | 650 ms, "pulo" leve | Boas-vindas |
| Troca de tema em círculo | 650 ms | Alto contraste |
| Explosão de pontos | 500 ms | Ao ativar uma preferência |
| Prévia ao vivo | 320 ms | Preferências |
| Troca de tela | 320 ms + logo voando | Navegação |

**Regras:** nenhuma animação se repete em loop; nenhuma informação depende só de animação; tudo é desligado quando o aparelho pede menos movimento **ou** o visitante ativa "Redução de estímulos" (`app/lib/app/theme/motion.dart`).

## Capturas

Em `docs/design/prints-etapa-1/` (rodada 2): `06-boas-vindas-neon.jpg` e `07-preferencias-revelacao.jpg`. As capturas 01–05 são da rodada 1 (paleta creme), mantidas para comparação.
