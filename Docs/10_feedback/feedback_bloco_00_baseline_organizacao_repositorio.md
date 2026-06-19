# Feedback - Bloco 00 - Baseline e Organizacao do Repositorio

## Objetivo do bloco

Criar a estrutura fisica inicial do codigo do projeto Windows Maintenance Terminal Grid, preparando o repositorio para o Bloco 01 sem implementar logica funcional, scripts reais, configuracoes JSON ou tarefas agendadas.

## Arquivos analisados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_00_baseline_organizacao_repositorio.md`
- `Docs/10_feedback/feedback_organizacao_documentacao.md`
- `README.md`

Todos os arquivos obrigatorios foram encontrados e lidos antes das alteracoes.

## Pastas criadas

- `config/`
- `scripts/`
- `scripts/common/`
- `scripts/terminals/`
- `scripts/startup/`
- `scripts/launchers/`
- `logs/`
- `tmp/`

## Arquivos criados

- `.gitignore`
- `config/.gitkeep`
- `scripts/.gitkeep`
- `scripts/common/.gitkeep`
- `scripts/terminals/.gitkeep`
- `scripts/startup/.gitkeep`
- `scripts/launchers/.gitkeep`
- `logs/.gitkeep`
- `tmp/.gitkeep`
- `Docs/10_feedback/feedback_bloco_00_baseline_organizacao_repositorio.md`

## Arquivos alterados

- `README.md`

O README foi atualizado sem sobrescrita destrutiva para informar o status atual do projeto como Bloco 00, explicar que scripts reais ainda nao foram implementados e indicar o Bloco 01 como proximo passo.

## Pastas duplicadas removidas anteriormente

As pastas legadas duplicadas foram removidas manualmente pelo usuario antes da execucao deste bloco e nao foram recriadas.

Durante a validacao local, foram encontrados remanescentes dessas pastas no disco. Elas foram removidas com verificacao previa de caminho dentro do workspace e com a ideia oficial ja preservada em `Docs/00_ideia_original/ideia_base_windows_maintenance_terminal_grid.md`.

Pastas legadas que nao fazem parte da estrutura oficial:

- `Docs/ideia/`
- `Docs/blocos/`
- `Docs/como_rodar/`
- `Docs/configurações/`
- `Docs/fluxos_de_testes/`
- `Docs/funcionalidades/`
- `Docs/planejamento/`

## Decisoes tecnicas

- Manter `Docs/` versionavel e fora do `.gitignore`.
- Manter `config/` versionavel para os futuros JSON do Bloco 01.
- Ignorar conteudo dinamico de `logs/` e `tmp/`, preservando apenas `.gitkeep`.
- Criar somente placeholders seguros, sem scripts executaveis.
- Atualizar README apenas no necessario para refletir o baseline atual.

## O que nao foi implementado propositalmente

- Nenhum `config/*.json` real.
- Nenhum `launcher.ps1` funcional.
- Nenhum script real em `scripts/terminals/`.
- Nenhum script de tarefa agendada.
- Nenhuma logica de Windows Terminal.
- Nenhum comando de manutencao do Windows.
- Nenhuma alteracao de politica de execucao PowerShell.
- Nenhuma solicitacao de administrador.

## Validacao realizada

- Verificada existencia das pastas base.
- Verificada existencia dos `.gitkeep`.
- Verificada existencia de `.gitignore`.
- Verificada existencia de `README.md`.
- Verificado que as pastas legadas nao permanecem na estrutura oficial.
- Verificada criacao deste feedback.
- Verificado que nao foram criados arquivos `.ps1` nem `config/*.json`.

## Riscos identificados

- O Bloco 01 deve evitar criar JSON que habilite comandos pesados no startup.
- O Bloco 02 deve manter funcoes comuns em modo seguro e com dry run.
- O Bloco 05 deve validar cuidadosamente a sintaxe real do `wt.exe`.
- O Bloco 08 deve impedir tarefa agendada invisivel ou apontando para modo real.

## Pendencias para o Bloco 01

- Criar `config/terminals.json`.
- Criar `config/visual_settings.json`.
- Criar `config/schedule_settings.json`.
- Validar sintaxe JSON.
- Manter DISM, SFC, CHKDSK profundo e defrag desabilitados no modo `startup_safe`.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_01_configuracoes_base_json.md e implemente somente o Bloco 01. Crie config/terminals.json, config/visual_settings.json e config/schedule_settings.json com exemplos seguros e sintaxe JSON valida. Nao execute comandos de manutencao do Windows, nao crie scripts funcionais e nao configure tarefa agendada.
```

## Confirmacao de seguranca

Nenhum comando de manutencao do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, tarefa agendada ou comando administrativo foi rodado neste bloco.
