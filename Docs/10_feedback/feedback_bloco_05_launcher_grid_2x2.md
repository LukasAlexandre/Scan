# Feedback - Bloco 05 - Launcher Grid 2x2

## Objetivo do bloco

Implementar o launcher seguro responsavel por abrir os quatro scripts de terminal em uma experiencia visual 2x2, preferindo Windows Terminal via `wt.exe`, mantendo fallback para janelas PowerShell separadas e preservando o modo `startup_safe` com `-DryRun`.

## Arquivos analisados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_05_launcher_grid_2x2.md`
- `Docs/06_scripts_funcoes/funcoes_launcher.md`
- `Docs/06_scripts_funcoes/funcoes_terminais.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/10_feedback/feedback_bloco_00_baseline_organizacao_repositorio.md`
- `Docs/10_feedback/feedback_bloco_01_configuracoes_base_json.md`
- `Docs/10_feedback/feedback_bloco_02_funcoes_comuns_powershell.md`
- `Docs/10_feedback/feedback_bloco_03_banners_loading_logs_visuais.md`
- `Docs/10_feedback/feedback_bloco_04_scripts_dos_terminais.md`
- `config/terminals.json`
- `config/visual_settings.json`
- `config/schedule_settings.json`
- `scripts/common/common.ps1`
- `scripts/terminals/terminal_runner.ps1`
- `README.md`

Todos os arquivos obrigatorios foram encontrados e lidos antes das alteracoes.

## Arquivos criados

- `scripts/launchers/launcher_common.ps1`
- `scripts/launchers/launcher_grid_2x2.ps1`
- `scripts/launchers/launcher_fallback_windows.ps1`
- `Docs/10_feedback/feedback_bloco_05_launcher_grid_2x2.md`

## Arquivos alterados

Nenhum arquivo preexistente foi alterado neste bloco.

## Launcher principal implementado

`scripts/launchers/launcher_grid_2x2.ps1` foi criado com os parametros:

```powershell
param(
    [string]$Mode = 'startup_safe',
    [switch]$DryRun,
    [switch]$UseFallback,
    [switch]$NoPause
)
```

Comportamento implementado:

- importa `scripts/common/common.ps1`;
- carrega `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json`;
- cria uma pasta compartilhada de logs somente quando o launcher for executado;
- valida as flags de seguranca antes de abrir terminais;
- bloqueia `maintenance_real` e `maintenance_real_deep` no Bloco 05;
- monta quatro comandos PowerShell com `-Mode startup_safe`, `-RunLogDirectory`, `-DryRun` e `-NoPause` quando solicitado;
- prefere `wt.exe` quando disponivel;
- registra atividade em `launcher.log`;
- delega para o fallback quando `wt.exe` nao existe ou quando `-UseFallback` e informado.

## Fallback implementado

`scripts/launchers/launcher_fallback_windows.ps1` foi criado para abrir quatro janelas PowerShell separadas usando os mesmos comandos seguros.

O fallback:

- importa as mesmas funcoes comuns do launcher;
- usa a mesma pasta compartilhada de logs recebida do launcher principal ou cria uma nova quando executado diretamente;
- passa `-DryRun` para todos os terminais;
- nao tenta forcar layout 2x2 no Bloco 05;
- registra no log que o fallback foi usado;
- nao solicita administrador e nao cria tarefa agendada.

## Estrategia de layout 2x2

O helper `Build-WindowsTerminalArgumentList` monta a sequencia de `wt.exe` com:

- `new-tab` para `ANALYTICS`;
- `split-pane -H` para `SCANNING`;
- `split-pane -V` para `PROCESSING`;
- `move-focus left`;
- `split-pane -V` para `CLEANING`.

Essa estrategia busca formar dois paineis na coluna esquerda e dois na coluna direita. A sintaxe foi validada por construcao de argumentos, mas o launcher nao foi executado durante a validacao para evitar abrir janelas no ambiente de teste.

## Parametros utilizados

Todos os comandos de terminal sao montados com:

- `powershell.exe`
- `-NoExit`
- `-NoProfile`
- `-ExecutionPolicy Bypass`
- `-File <script do terminal>`
- `-Mode startup_safe`
- `-RunLogDirectory <pasta compartilhada>`
- `-DryRun`
- `-NoPause`, somente quando o launcher recebe `-NoPause`

Mesmo quando `-DryRun` nao e fornecido ao launcher, o Bloco 05 forca `-DryRun` nos quatro comandos.

## Validacao realizada

- Executados `git status --short`, `git branch --show-current` e `git log --oneline -5` antes das alteracoes.
- Confirmado que o Bloco 04 estava commitado em `aba8e1fa5d594121d7ea7d489b7ae6fd1aae19cf`.
- Sintaxe dos tres scripts criados validada com parser do PowerShell em processo isolado com `-ExecutionPolicy Bypass`.
- `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json` validados com `ConvertFrom-Json`.
- Flags de seguranca confirmadas como `false`:
  - `allowRealMaintenance=false`
  - `allowStartupHeavyCommands=false`
  - `startup.allowHeavyCommandsOnStartup=false`
  - `startup.enabled=false`
  - `scheduledTask.autoCreate=false`
- Confirmada existencia dos quatro scripts:
  - `scripts/terminals/analytics_dism.ps1`
  - `scripts/terminals/scanning_sfc.ps1`
  - `scripts/terminals/processing_chkdsk.ps1`
  - `scripts/terminals/cleaning_optimize.ps1`
- Validado que a montagem de comandos produz quatro entradas.
- Validado que todos os comandos montados incluem `-DryRun`.
- Validado que o modo padrao normalizado e `startup_safe`.
- Validado que a linha de argumentos do Windows Terminal inclui `split-pane`, `startup_safe` e `-DryRun`.
- Consultado que a tarefa agendada `WindowsMaintenanceTerminalGrid` nao existe.
- Confirmado que `config/*.json` nao teve diff.
- Confirmado que `logs/` permaneceu apenas com `.gitkeep`.

## Seguranca aplicada

- O launcher bloqueia `maintenance_real` e `maintenance_real_deep` no Bloco 05.
- `DryRun` e efetivamente forcado para todos os terminais.
- Nenhum comando de manutencao e montado pelo launcher.
- Nenhuma elevacao administrativa e solicitada.
- Nenhuma autoelevacao foi implementada.
- Nenhum agendamento foi criado.
- Nenhuma politica persistente do PowerShell foi alterada.
- A validacao nao executou o launcher principal nem o fallback, evitando abertura de janelas e criacao de logs temporarios.

## O que nao foi implementado propositalmente

- Execucao real de DISM.
- Execucao real de SFC.
- Execucao real de CHKDSK.
- Execucao real de defrag/otimizacao.
- Modo `maintenance_real`.
- Modo `maintenance_real_deep`.
- Startup automatico.
- Criacao de tarefa agendada.
- Posicionamento forcado das janelas de fallback via Win32 API.
- Alteracao de `README.md`, que continua como pendencia documental futura.

## Riscos identificados

- A sintaxe do `wt.exe` foi validada por construcao de argumentos, mas nao por abertura real do Windows Terminal neste bloco.
- O fallback abre quatro janelas separadas e nao garante organizacao visual 2x2.
- Como os quatro terminais recebem a mesma pasta de log, o arquivo `summary.json` atual dos terminais pode ser sobrescrito pelo ultimo terminal a terminar. Isso deve ser tratado em bloco futuro de logs/summary.
- Caminhos com espaco foram tratados por quoting no launcher, mas o teste completo com janelas reais deve ser feito em uma validacao manual segura.

## Pendencias para o Bloco 06

- Criar o modo/entrada de `startup_safe` usando o launcher do Bloco 05.
- Definir se o Bloco 06 tera wrapper especifico para startup seguro.
- Manter `startup.enabled=false` e `scheduledTask.autoCreate=false` ate o Bloco 08.
- Validar abertura manual segura do grid antes de qualquer integracao de startup.
- Avaliar a estrategia de `summary.json` compartilhado entre terminais.

## Git

- Branch antes do bloco: `master`.
- Hash base antes do bloco: `aba8e1fa5d594121d7ea7d489b7ae6fd1aae19cf`.
- Commit planejado apos validacao: `feat: add safe terminal grid launcher`.
- Push planejado: `git push origin master`, sem `--force`.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_06_modo_startup_safe.md e implemente somente o Bloco 06 - Modo Startup Safe. Use o launcher seguro do Bloco 05, mantenha -DryRun, nao execute comandos de manutencao do Windows, nao crie tarefa agendada e nao habilite startup automatico fora do escopo previsto.
```

## Confirmacao de seguranca

Nenhum comando de manutencao do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, tarefa agendada, modo real, startup automatico ou comando administrativo foi rodado neste bloco.
