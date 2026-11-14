# Como contribuir

## Divisão de trabalho

Uma branch por entrega e um pull request com objetivo claro. Combinar divisão de arquivos antes de editar simultaneamente a mesma tela. Registrar tarefa, responsável, requisitos e critérios de aceite.

| Prefixo | Uso |
|---|---|
| feat/ | Funcionalidade |
| fix/ | Correção |
| docs/ | Documentação |
| test/ | Testes |
| chore/ | Manutenção |

## Iniciar uma tarefa

```powershell
git status
git fetch origin
```

Somente com árvore limpa:

```powershell
git switch main
git pull --ff-only origin main
git switch -c docs/atualizacao-documentacao
```

Se houver trabalho em andamento, conclua ou preserve antes de trocar de branch. Não usar reset destrutivo, limpeza de arquivos ou push forçado para organizar o projeto.

## Preparar entrega

Revisar diff, executar verificações pertinentes e adicionar caminhos explícitos.

```powershell
git diff
git add README.md docs/README.md
git diff --cached
git commit -m "docs: atualiza apresentação e índice"
git push -u origin HEAD
```

O exemplo inclui somente dois arquivos; adicione explicitamente os demais da sua entrega. Evite git add . sem conferir arquivos locais e mudanças de outras pessoas. Mensagens: feat:, fix:, docs:, test: ou chore:.

## Pull request

Informar problema, mudança, validação, requisitos/tarefas e limitações. Usar o template do repositório. Não declarar testes aprovados sem execução.

Manter pubspec.lock, fontes e licenças versionados. Não incluir builds, caches, credenciais, .env ou configurações locais. Não publicar plantas reais ou dados operacionais privados usados como referência.

Atualizar estado atual quando entregar funcionalidade e registrar mudanças de escopo com os IDs existentes. Não excluir branches compartilhadas sem conferir integração e uso por outras pessoas.

