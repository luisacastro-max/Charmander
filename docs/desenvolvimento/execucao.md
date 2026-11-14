# Instalação, configuração e execução

## 1. Pré-requisitos

| Ferramenta | Necessidade |
|---|---|
| Git | Clonar o repositório |
| Flutter 3.47.5 / Dart 3.13.4 | Versões identificadas no ambiente; pubspec exige Dart ^3.13.4 |
| Chrome | Execução web |
| Android SDK e aparelho/emulador | Somente para execução Android |
| Node.js 18+ | Somente servidor demonstrativo compartilhado e seus testes |

Instale Flutter e adicione seu diretório bin ao PATH. Confira flutter --version e flutter doctor. Não são necessárias chaves de API, PostgreSQL ou Spring Boot. iOS exige macOS/Xcode e não foi validado nesta revisão.

## 2. Obter o código

```powershell
git clone https://github.com/luisacastro-max/Charmander.git
cd Charmander
git rev-parse HEAD
cd app
flutter pub get
flutter devices
```

A main contém a entrega. Para reproduzir exclusivamente o código-base desta revisão, antes de entrar em app/, use git checkout 0500d9d. Registrar o SHA permite comparar resultados. Não usar uma branch antiga de documentação como versão mais recente do produto.

## 3. Executar sem servidor

```powershell
flutter run -d chrome
```

Para Android: flutter run -d <id-do-dispositivo>, com o identificador de flutter devices.

Na web, a inicialização tenta /api/ocorrencias na mesma origem. Se não responder, ativa a simulação local identificada na interface. Nesse modo, relatos não aparecem em outro aparelho. Funcionalidades principais não exigem banco ou servidor externo.

## 4. Executar alertas compartilhados

Na pasta app/:

```powershell
flutter build web --release
cd ..
node .claude/serve-web.js 8097 localhost
```

Abra http://localhost:8097 em dois navegadores/perfis. O servidor entrega app/build/web e a API /api/ocorrencias. A atualização ocorre por polling de três segundos, não por WebSocket.

Dados gerados: .claude/dados/ocorrencias.json, ignorado pelo Git. Reiniciar mantém esse arquivo; apagar os dados de demonstração deve ser uma ação consciente com o servidor parado.

Para testar no celular da mesma rede, execute node .claude/serve-web.js 8097 0.0.0.0 e acesse http://IP-DO-COMPUTADOR:8097. Isso depende de firewall e conectividade. Não use localhost no celular para apontar ao computador. Prefira servir interface e API na mesma origem: a política CORS do servidor é restritiva.

## 5. API em endereço próprio

```powershell
flutter run -d chrome --dart-define=OCORRENCIAS_API=http://localhost:8097/api/ocorrencias
```

Para build:

```powershell
flutter build web --release --dart-define=OCORRENCIAS_API=https://SEU-SERVIDOR/api/ocorrencias
```

O domínio acima é um exemplo a substituir. O endereço deve estar acessível ao dispositivo; em site HTTPS, a API deve usar HTTPS e permitir a origem quando diferente. O servidor de demonstração não foi preparado para operação pública segura. Sem API saudável, o app inicia em simulação.

## 6. Validar

Em app/:

```powershell
flutter analyze
flutter test
flutter test --coverage
flutter build web --release
```

Cobertura é opcional. Na raiz:

```powershell
node --check .claude/api-ocorrencias.js
node --check .claude/serve-web.js
node .claude/api-ocorrencias.test.js
```

O teste Node sobe seu próprio servidor local; não exige manter serve-web.js aberto.

## 7. Build e hospedagem

A saída web está em app/build/web. Sirva por HTTP, sem abrir o HTML diretamente. Para subpasta, configure --base-href /subpasta/.

O MVP é disponibilizado pela equipe na Vercel. O endereço será incluído em ENTREGA_FINAL.md quando informado. As instruções desta página permitem reproduzir a aplicação localmente e não exigem uma nova publicação.

Uma hospedagem estática não executa .claude/serve-web.js nem cria a API de alertas. Configure uma API separada ou mantenha o modo simulado. Não há garantia de instalação offline ou de suporte a voz idêntico em todos os aparelhos.

## 8. Solução de problemas

| Sintoma | Verificação |
|---|---|
| SDK incompatível | Versão Dart e pubspec |
| Nenhum dispositivo | flutter devices e flutter doctor |
| Sem voz | Ativar áudio, conferir vozes do sistema e interação/permissões do navegador; texto continua disponível |
| Alertas não compartilham | Conferir modo mostrado, API /saude, mesma origem e endereço do aparelho |
| Erro CORS ou conteúdo misto | Origem, HTTPS e política do servidor |
| Falha no lockfile, temporários ou dev do SDK | Usar instalação Flutter completa em diretório gravável |
| Porta 8097 ocupada | Parar o processo conhecido ou usar outra porta em ambos os acessos |

Resultados desta revisão estão no [registro de validação](../qa/validacao-entrega-final.md).
