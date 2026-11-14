# language: pt
# Etapa 2 — Fundação: preferências salvas, fontes offline e dados do shopping
# Rastreabilidade: RF44, RF47, RNF08, RNF11, RNF13, RN03, RN06, RN14, CA02, CA14
# Automatizados em app/test/data/ e app/test/widget_test.dart, exceto "Manual".

Funcionalidade: Fundação de dados e preferências do Acessa+

  Cenário: Preferências continuam ao reabrir o app (RF47, CA02)
    Dado que ativei "Texto ampliado" e escolhi o idioma "Español"
    Quando fecho e abro o aplicativo de novo
    Então "Texto ampliado" continua ativado
    E o idioma continua "Español"

  Cenário: Apagar preferências pede confirmação (CA14)
    Dado que ativei "Alto contraste" e "Rotas sem escadas"
    Quando toco em "Apagar minhas preferências"
    Então vejo a pergunta "Apagar suas preferências?"
    Quando toco em "Cancelar"
    Então minhas preferências continuam ativadas

  Cenário: Apagar preferências limpa o aparelho (RNF13, CA14)
    Dado que ativei "Alto contraste" e "Rotas sem escadas"
    Quando toco em "Apagar minhas preferências" e confirmo em "Apagar"
    Então vejo "Preferências apagadas deste aparelho."
    E nenhuma preferência fica salva no aparelho
    E ao reabrir o app vejo "Nenhum recurso ativo"

  Cenário: Dado salvo corrompido não trava o app
    Dado que o armazenamento do aparelho tem um valor inválido
    Quando abro o aplicativo
    Então as preferências voltam ao padrão

  Cenário: Só escolhas de recursos são salvas (RN01, RNF13)
    Quando as preferências são salvas
    Então só ficam guardadas as escolhas de recursos e o idioma
    E nenhum dado pessoal, de saúde ou de deficiência

  Cenário: Informação desconhecida (RNF08, RN06)
    Dado um local sem horário cadastrado
    Quando o horário é exibido
    Então aparece "Não informado"
    E a ausência do dado não é apresentada como recurso acessível

  Cenário: Trechos com escada sempre marcados (RN03)
    Dado o cadastro de trechos do shopping
    Então todo trecho que chega à escada está marcado como "com escada"
    E existe ligação entre os pisos pelo elevador, sem escada

  Cenário: Sugestões "Neste local" sempre com ação definida (RN14)
    Dado o cadastro de sugestões por ponto
    Então cada sugestão prepara uma mensagem ou ativa uma preferência

  Cenário: Fontes funcionam sem internet (Manual)
    Dado que o aparelho está sem internet
    Quando abro o aplicativo
    Então títulos aparecem em Fredoka e textos em Atkinson Hyperlegible
