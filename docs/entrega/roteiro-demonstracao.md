# Roteiro de demonstração

Base: edbc8e9, integrada à main por 4cb0ea1. Consulte o [guia de avaliação](guia-avaliacao.md).

1. Apresentar as barreiras de comunicação e mobilidade e os três pilares do Acessa+.
2. Ajustar texto ampliado, contraste e rotas sem escadas.
3. Buscar destino e explicar o ponto atual como beacon simulado.
4. Adicionar, reordenar ou remover paradas e iniciar.
5. Alternar visualização, simular chegadas e confirmar parada intermediária.
6. Abrir o cartão de ajuda, escolher frase e idioma, usar frente a frente e responder por toque.
7. Abrir Ajuda+, conferir local e categoria, revisar e confirmar o pedido demonstrativo.
8. Avançar estados, cancelar quando permitido ou concluir e retomar o percurso.
9. Ao chegar, mostrar o último metro com cena e direção simuladas.
10. Demonstrar incompatibilidade do Mezanino quando escadas estão proibidas.

## Roteiro curto: rota adaptada (2–3 min)

Em validação; rótulos de tela prováveis, a confirmar com a versão apresentada. Cenários: [rota-adaptada.feature](../qa/rota-adaptada.feature).

1. (20 s) Sem restrições, escolher “Praça de Alimentação” e mostrar que a rota mais usada sobe pela escada rolante.
2. (30 s) Voltar às preferências, em “Como você vai circular hoje?” tocar em “Sobre rodas (cadeira de rodas, carrinho de bebê, mala)”. Mostrar que só liga “Rotas sem escadas” e “Preferência por elevadores” e dizer que a opção não é salva nem pede diagnóstico (RN01).
3. (45 s) Escolher de novo “Praça de Alimentação”. Mostrar “Rota mais usada × Rota adaptada para você”: o que foi evitado (escada rolante), o que substitui (elevador) e quanto a mais em metros e minutos.
4. (45 s) Tocar em “Simular elevador em manutenção”. Apontar o aviso de simulação, a mensagem de que não há caminho sem escadas, a preferência ainda ativa e o botão “Pedir ajuda” para o Ajuda+.
5. (10 s) Encerrar a simulação e mostrar a rota pelo elevador de volta.

Os dados de distância, acessibilidade e status do elevador são fictícios; não há validação com usuários de cadeira de rodas ainda.

## Roteiro curto: mapa colaborativo de alertas com duas sessões (3–4 min)

PROPOSTA de novo escopo, em desenvolvimento ([MUD-04](../backlog/mudancas-de-escopo.md)). Rótulos prováveis, a confirmar com a versão apresentada. Cenários: [alertas-comunidade.feature](../qa/alertas-comunidade.feature).

**Preparação (antes da banca):**

1. Gerar o build web (`flutter build web` em `app/`) e ligar o servidor de demonstração pela configuração `acessa-web-celular` (porta 8098, aberta para a rede local). Conferir com o back-end se essa configuração já serve também a API de alertas (`.claude/api-ocorrencias.js`); sem a API, o app entra em simulação.
2. Sessão A: navegador do computador em `http://localhost:8098`. Sessão B: celular na **mesma Wi-Fi** em `http://<IP do computador>:8098`. Se o celular não conectar (firewall, rede de visitantes), usar duas janelas do navegador no computador, lado a lado.
3. Ativar “Rotas sem escadas” na sessão B. Apagar alertas antigos do arquivo de dados do servidor de demonstração, se houver.
4. Conferir que **nenhuma** das duas sessões mostra o aviso “Simulação: os alertas ficam só neste aparelho”. Se aparecer, o servidor não está respondendo e a demonstração de compartilhamento não vai funcionar.

**Demonstração:**

1. (20 s) Explicar: relatos da comunidade, anônimos e **não verificados**; inspiração nos alertas do Waze, voltada a barreiras de acessibilidade.
2. (40 s) Na sessão A, tocar em “Reportar problema”, escolher “Elevador fora de serviço”, confirmar o ponto e o andar na mini-planta (mostrar o ajuste manual e a lista “Perto de”) e enviar sem descrição.
3. (20 s) Mostrar na sessão B o marcador aparecendo sozinho em poucos segundos, sem recarregar. Apontar a forma do marcador de bloqueio e o texto “não verificado”.
4. (40 s) Na sessão B, pedir rota até a Praça de Alimentação. Mostrar a explicação de que não há caminho sem escadas por causa do alerta, que “Rotas sem escadas” continua ligada e o botão “Pedir ajuda”.
5. (30 s) Na sessão A, relatar “Piso molhado ou escorregadio” em um corredor e mostrar em B o aviso na rota (aviso, não bloqueio).
6. (30 s) Na sessão B, abrir o card do elevador e tocar em “Já foi resolvido”. Mostrar em A o alerta saindo como resolvido e, em B, a rota voltando a usar o elevador.
7. (20 s) Opcional: relatar de novo o mesmo problema no mesmo ponto e mostrar que vira confirmação, não marcador novo.

**O que dizer que é simulado ou limitado:** a posição no shopping é escolhida pela pessoa (não há GPS interno nem beacons reais); o servidor é de demonstração (arquivo JSON, sem login, sem moderação), só funciona na mesma rede; na publicação da Vercel o app usa **simulação local** e os alertas não são compartilhados; o shopping e os dados são fictícios; não houve validação com pessoas usuárias.

Não há câmera real, GPS interno, beacons conectados, tradução livre ou funcionários acionados. Voz e traduções ampliadas só devem ser demonstradas se estiverem na revisão apresentada e validadas no aparelho.

Registrar o commit e testar o fluxo antes da banca. Não anunciar hospedagem ou testes aprovados sem verificar. O HTML é uma referência separada.