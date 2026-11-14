# Arquitetura atual

Revisão 14/11/2026, código 0500d9d / merge 54786c3.

A descrição consolidada está na [documentação técnica](../documentacao-tecnica.md). O app usa telas por funcionalidade, regras/modelos em domain, dados em data e componentes em core.

| Componente | Responsabilidade |
|---|---|
| main / AcessaApp | Inicialização e escopos |
| PreferencesController | Preferências, tema e armazenamento |
| ShoppingData e repositórios JSON | Shopping demonstrativo |
| MotorRotas / viagens | Caminhos e paradas |
| AlertasController | Relatos, estado de envio e efeitos nas rotas |
| HttpOcorrenciasRepository | Saúde, consultas periódicas e envios HTTP |
| SimuladoOcorrenciasRepository | Alternativa sem compartilhamento entre aparelhos |
| i18n / Voz | Tradução cadastrada e síntese de voz |
| API Node | Persistência demonstrativa em JSON |

OCORRENCIAS_API define o endereço. Na web sem parâmetro, a mesma origem é tentada. Falha na disponibilidade inicial escolhe simulação. HTTP atualiza a cada três segundos; a interface informa o modo.

Preferências/idioma são locais; ocorrências compartilhadas são enviadas ao servidor. Assistência continua simulada. Não há Spring Boot/PostgreSQL ou autenticação.

As camadas não são inteiramente isoladas: enum de idioma ainda está na feature de preferências. Controle de falhas de persistência e cache é ponto de evolução. Servidor demonstrativo não inclui moderação nem infraestrutura operacional.

[Execução com e sem API](../desenvolvimento/execucao.md).
