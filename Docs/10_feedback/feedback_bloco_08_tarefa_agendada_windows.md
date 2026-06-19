# Feedback - Bloco 08 - Tarefa Agendada Windows

## Objetivo do bloco

Criar scripts seguros de instalacao e remocao da tarefa agendada do Windows para abrir somente o modo `startup_safe` no logon do usuario, mantendo dry-run por padrao e sem conectar `maintenance_real` ao startup.

## Arquivos analisados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_08_tarefa_agendada_windows.md`
- `Docs/06_scripts_funcoes/funcoes_startup.md`
- `Docs/06_scripts_funcoes/funcoes_launcher.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/07_configuracoes/scheduled_task_config.md`
- `Docs/10_feedback/feedback_bloco_00_baseline_organizacao_repositorio.md`
- `Docs/10_feedback/feedback_bloco_01_configuracoes_base_json.md`
- `Docs/10_feedback/feedback_bloco_02_funcoes_comuns_powershell.md`
- `Docs/10_feedback/feedback_bloco_03_banners_loading_logs_visuais.md`
- `Docs/10_feedback/feedback_bloco_04_scripts_dos_terminais.md`
- `Docs/10_feedback/feedback_bloco_05_launcher_grid_2x2.md`
- `Docs/10_feedback/feedback_bloco_06_modo_startup_safe.md`
- `Docs/10_feedback/feedback_bloco_07_modo_maintenance_real.md`
- `config/terminals.json`
- `config/visual_settings.json`
- `config/schedule_settings.json`
- `scripts/common/common.ps1`
- `scripts/startup/launcher_startup_safe.ps1`
- `scripts/launchers/launcher_grid_2x2.ps1`
- `scripts/launchers/launcher_maintenance_real.ps1`
- `README.md`

Todos os arquivos obrigatorios foram encontrados e lidos antes das alteracoes.

## Arquivos criados

- `scripts/startup/create_scheduled_task.ps1`
- `scripts/startup/remove_scheduled_task.ps1`
- `install.ps1`
- `uninstall.ps1`
- `Docs/10_feedback/feedback_bloco_08_tarefa_agendada_windows.md`

## Arquivos alterados

- `scripts/startup/startup_common.ps1`

Foram adicionados helpers para resolver caminhos seguros do startup, montar o plano da tarefa agendada e validar que o alvo e somente `scripts/startup/launcher_startup_safe.ps1`.

## Scripts de instalacao/remocao implementados

`scripts/startup/create_scheduled_task.ps1`:

- carrega `common.ps1`;
- carrega `config/terminals.json` e `config/schedule_settings.json`;
- monta a acao da tarefa usando `powershell.exe`;
- aponta para `scripts/startup/launcher_startup_safe.ps1`;
- inclui `-DryRun` na acao agendada;
- repassa `-UseFallback` e `-NoPause` quando solicitados;
- usa trigger `AtLogon`;
- usa o usuario atual;
- configura `LogonType=Interactive`;
- configura `RunLevel=Limited`;
- aplica delay de `startup.delaySeconds` quando suportado;
- opera em dry-run quando `-Apply` nao e informado.

`scripts/startup/remove_scheduled_task.ps1`:

- procura a tarefa `WindowsMaintenanceTerminalGrid`;
- mostra plano de remocao;
- opera em dry-run quando `-Apply` nao e informado;
- remove somente com token explicito.

`install.ps1` e `uninstall.ps1`:

- sao wrappers amigaveis;
- repassam parametros aos scripts em `scripts/startup/`;
- nao duplicam logica pesada.

## Tarefa agendada planejada

- Nome: `WindowsMaintenanceTerminalGrid`
- Trigger: `AtLogon`
- Usuario: usuario atual no momento da instalacao
- Executavel: `powershell.exe`
- Argumentos: `-NoProfile -ExecutionPolicy Bypass -File <root>/scripts/startup/launcher_startup_safe.ps1 -DryRun`
- Janela: visivel por usar PowerShell interativo, sem `-WindowStyle Hidden`
- Logon: `Interactive`
- RunLevel: `Limited`
- Delay: `startup.delaySeconds`, atualmente 20 segundos
- Alvo proibido: o plano nao aponta para modo real

## Parametros disponiveis

`install.ps1` e `create_scheduled_task.ps1`:

```powershell
param(
    [switch]$DryRun,
    [switch]$Apply,
    [string]$ConfirmationToken = '',
    [switch]$UseFallback,
    [switch]$NoPause
)
```

`uninstall.ps1` e `remove_scheduled_task.ps1`:

```powershell
param(
    [switch]$DryRun,
    [switch]$Apply,
    [string]$ConfirmationToken = ''
)
```

## Gates de seguranca

Instalacao real exige:

- `-Apply`;
- ausencia de `-DryRun`;
- `-ConfirmationToken "I_ACCEPT_STARTUP_SAFE_TASK"`;
- `startup.mode=startup_safe`;
- `startup.allowHeavyCommandsOnStartup=false`;
- `allowStartupHeavyCommands=false`;
- `allowRealMaintenance=false`;
- `scheduledTask.taskName=WindowsMaintenanceTerminalGrid`;
- alvo igual a `scripts/startup/launcher_startup_safe.ps1`;
- `RunLevel=Limited`;
- `LogonType=Interactive`.

Remocao real exige:

- `-Apply`;
- ausencia de `-DryRun`;
- `-ConfirmationToken "I_ACCEPT_REMOVE_STARTUP_SAFE_TASK"`.

## Validacao realizada

- Executados `git status --short`, `git branch --show-current` e `git log --oneline -5` antes das alteracoes.
- Confirmado que o Bloco 07 estava commitado em `53c6b188414870ab23dd4349e135be799436cd14`.
- Sintaxe validada com parser do PowerShell para:
  - `scripts/startup/startup_common.ps1`
  - `scripts/startup/create_scheduled_task.ps1`
  - `scripts/startup/remove_scheduled_task.ps1`
  - `install.ps1`
  - `uninstall.ps1`
- `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json` validados com `ConvertFrom-Json`.
- Flags confirmadas como seguras:
  - `startup.enabled=false`
  - `scheduledTask.autoCreate=false`
  - `startup.allowHeavyCommandsOnStartup=false`
  - `allowStartupHeavyCommands=false`
  - `allowRealMaintenance=false`
- Validado que o plano aponta para `scripts/startup/launcher_startup_safe.ps1`.
- Validado que a acao planejada inclui `-DryRun`.
- Validado que os scripts de startup/install nao contem `launcher_maintenance_real.ps1`.
- Validado que os scripts de instalacao/remocao nao contem comandos literais de manutencao.
- Executado `install.ps1` sem `-Apply`; funcionou em dry-run e nao criou tarefa.
- Executado `uninstall.ps1` sem `-Apply`; funcionou em dry-run e nao removeu nada.
- Executado `install.ps1 -Apply -ConfirmationToken WRONG`; foi bloqueado antes de `Register-ScheduledTask`.
- Executado `uninstall.ps1 -Apply -ConfirmationToken WRONG`; foi bloqueado antes de `Unregister-ScheduledTask`.
- Confirmado que `New-ScheduledTaskAction` suporta `WorkingDirectory` no ambiente local.
- Confirmado que a tarefa `WindowsMaintenanceTerminalGrid` nao existia antes nem depois da validacao.
- Confirmado que `config/*.json` nao teve diff.
- Confirmado que `logs/` permaneceu apenas com `.gitkeep`.

## Seguranca aplicada

- Dry-run por padrao.
- Criacao real somente com `-Apply` e token correto.
- Remocao real somente com `-Apply` e token correto.
- Nenhuma tarefa foi criada na validacao.
- Nenhum JSON foi alterado para habilitar startup automatico.
- Nenhum modo real foi conectado ao startup.
- Nenhuma autoelevacao foi implementada.
- Nenhuma alteracao de registro foi implementada.
- Nenhum atalho foi copiado para pasta de inicializacao.
- Nenhum comando de manutencao foi executado.

## O que nao foi implementado propositalmente

- Execucao de `install.ps1 -Apply` com token valido durante validacao.
- Execucao de `uninstall.ps1 -Apply` com token valido durante validacao.
- Alteracao de `config/*.json`.
- Conexao de `launcher_maintenance_real.ps1` ao startup.
- `RunLevel Highest` por padrao.
- Autoelevacao.
- Alteracao de registro.
- Copia para `shell:startup`.
- Execucao de comandos de manutencao do Windows.

## Riscos identificados

- A tarefa usa caminho absoluto do repositorio no momento da instalacao; se o projeto for movido, a tarefa precisara ser reinstalada.
- A exibicao visivel depende de execucao interativa do usuario no logon.
- A criacao real pode exigir permissoes suficientes do usuario atual conforme politica local do Windows.
- O delay depende do suporte do Task Scheduler e da API `ScheduledTasks` no ambiente.

## Pendencias para o Bloco 09

- Melhorar logs, lock file e `summary.json` de execucao real do startup.
- Tratar duplicidade de execucao de forma integrada.
- Consolidar summaries dos quatro terminais.
- Validar retencao/limpeza de logs.
- Documentar fluxo final de instalacao/remocao apos testes locais.

## Git

- Branch antes do bloco: `master`.
- Hash base antes do bloco: `53c6b188414870ab23dd4349e135be799436cd14`.
- Commit planejado apos validacao: `feat: add scheduled task installer`.
- Push planejado: `git push origin master`, sem `--force`.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_09_logs_lock_file_summary.md e implemente somente o Bloco 09 - Logs, Lock File e Summary. Melhore rastreabilidade, bloqueio de execucao duplicada e summaries sem executar comandos de manutencao do Windows.
```

## Confirmacao de seguranca

Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, modo real, startup automático real durante validação, alteração de registro, autoelevação ou comando administrativo foi rodado neste bloco.
