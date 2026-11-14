# Ambiente e execução

## Pré-requisitos

- Git e Flutter com Dart compatível com `^3.13.4`, conforme o pubspec.
- Chrome para web ou Android SDK e dispositivo/emulador Android.
- iOS exige macOS e Xcode; execução iOS não foi verificada nesta revisão.

A versão do Flutter não foi fixada pelo projeto. Registre a versão efetivamente usada na entrega.

## Preparação e execução

Na raiz do repositório:

```powershell
cd app
flutter --version
flutter doctor
flutter pub get
flutter devices
flutter run -d chrome
```

Para Android, substitua `chrome` pelo identificador do dispositivo. A localização é simulada na interface e dispensa beacon físico.

## Verificações

```powershell
flutter analyze
flutter test
flutter test --coverage
```

Cobertura é opcional; o relatório fica em `app/coverage/`, fora do Git. Cobertura de linhas não equivale a cobertura integral de requisitos.

## Build web

```powershell
flutter build web --release
```

Publique a saída `app/build/web/` em hospedagem estática. O build deve ser servido por HTTP; não basta abrir o HTML diretamente. Para subdiretório, configure `--base-href /subdiretorio/`.

Não há configuração de hospedagem ou pipeline CI versionado na base analisada. Este guia não publica o aplicativo.

## Problemas de ambiente

| Sintoma | Ação |
|---|---|
| Dart incompatível | Conferir a versão do SDK e a restrição do pubspec |
| Nenhum dispositivo | Usar flutter devices e flutter doctor |
| Falha no bin/cache/lockfile | Conferir permissões do SDK e processos concorrentes; não apagar lock de processo ativo |
| Dependências ausentes | Executar flutter pub get em app/ |

Na análise anterior, a execução ficou bloqueada por acesso ao lockfile do SDK. A atualização documental não comprova nova aprovação dos testes.

