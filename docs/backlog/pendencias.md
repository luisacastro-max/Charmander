# Pendências e evolução

Revisão: 14/11/2026. Referência publicada: edbc8e9 / merge 4cb0ea1. Prioridades são propostas de planejamento.

## Entregas já presentes no fonte

Cartão de frases traduzidas e respostas, Ajuda+ com revisão/acompanhamento e último metro demonstrativo já estão implementados. Isso não comprova validação assistiva ou operação real.

## Próximas verificações e melhorias

| Prioridade | Trabalho | Resultado esperado |
|---|---|---|
| Alta | Validar build e testes no aparelho da apresentação | Evidência com commit, versões e resultado |
| Alta | Validar cartão, assistência e último metro com leitor de tela | Fluxo compreensível sem depender do visual |
| Alta | Corrigir instrução de escada rolante em descida | Texto coerente nos dois sentidos |
| Média | Ordenar escritas e tratar falhas de preferências | Estado salvo coerente com última escolha/exclusão |
| Média | Recuperar erro de carga JSON | Nova tentativa sem cache permanente de erro |
| Média | Finalizar e validar voz e traduções locais | Publicar somente após conferir idioma e dispositivo |
| Média | Completar Home, retomada e controles de navegação | Contexto previsível entre recursos |
| Média | Barreira e rota alternativa | Preservar restrições e permitir escolha |
| Média | Card “Neste local” | Ação contextual apenas por escolha do visitante |
| Média | Revisar Word e rastreabilidade | Alinhar fluxo, 13 telas e status |
| Baixa | Separar enum de idioma da apresentação | Reduzir acoplamento do domínio |
| A definir | Chat livre, voz para texto, OCR, emergência e painel | Decisão de escopo e requisitos antes da implementação |

O último metro usa cena fixa e não resolve OCR. API, banco e beacons reais são evolução, sem dependência para avaliar o MVP. Cada tarefa deve ter responsável, requisito, critério de aceite e evidência.
