# Feedback - Bloco 07 - Modo Maintenance Real

## Objetivo do bloco

Implementar a infraestrutura manual e controlada do modo `maintenance_real`, mantendo dry-run por padrao, exigindo gates fortes para qualquer execucao real futura e preservando separacao total de `startup_safe`, tarefa agendada e configuracoes persistentes.

## Arquivos analisados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md`
- `Docs/06_scripts_funcoes/funcoes_common.md`
- `Docs/06_scripts_funcoes/funcoes_launcher.md`
- `Docs/06_scripts_funcoes/funcoes_terminais.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/10_feedback/feedback_bloco_00_baseline_organizacao_repositorio.md`
- `Docs/10_feedback/feedback_bloco_01_configuracoes_base_json.md`
- `Docs/10_feedback/feedback_bloco_02_funcoes_comuns_powershell.md`
- `Docs/10_feedback/feedback_bloco_03_banners_loading_logs_visuais.md`
- `Docs/10_feedback/feedback_bloco_04_scripts_dos_terminais.md`
- `Docs/10_feedback/feedback_bloco_05_launcher_grid_2x2.md`
- `Docs/10_feedback/feedback_bloco_06_modo_startup_safe.md`
- `config/terminals.json`
- `config/visual_settings.json`
- `config/schedule_settings.json`
- `scripts/common/common.ps1`
- `scripts/common/command_runner.ps1`
- `scripts/common/admin_check.ps1`
- `scripts/terminals/terminal_runner.ps1`
- `scripts/launchers/launcher_grid_2x2.ps1`
- `scripts/startup/launcher_startup_safe.ps1`
- `README.md`

Todos os arquivos obrigatorios foram encontrados e lidos antes das alteracoes.

## Arquivos criados

- `scripts/launchers/maintenance_real_common.ps1`
- `scripts/launchers/launcher_maintenance_real.ps1`
- `Docs/10_feedback/feedback_bloco_07_modo_maintenance_real.md`

## Arquivos alterados

- `scripts/common/command_runner.ps1`

O runner comum foi aprimorado para aceitar autorizacao real de sessao via `AllowSessionRealMaintenance` e validar executaveis contra uma allowlist antes de qualquer execucao real.

## Maintenance real implementado

`scripts/launchers/launcher_maintenance_real.ps1` foi criado como launcher manual de manutencao real controlada. Ele:

- importa `scripts/common/common.ps1`;
- importa `scripts/launchers/maintenance_real_common.ps1`;
- carrega os tres JSON;
- cria pasta de logs compartilhada;
- cria `maintenance_real.log`;
- monta fila sequencial de manutencao;
- gera `summary.json`;
- opera em dry-run por padrao;
- bloqueia `RunReal` se qualquer gate falhar;
- nao chama `startup_safe`;
- nao abre tarefa agendada;
- nao altera JSON.

## Parametros disponiveis

`launcher_maintenance_real.ps1` aceita:

```powershell
param(
    [switch]$DryRun,
    [switch]$RunReal,
    [string]$ConfirmationToken = '',
    [switch]$AllowSessionRealMaintenance,
    [switch]$IncludeDiskScan,
    [switch]$IncludeDeepDiskRepair,
    [switch]$UseFallback,
    [switch]$NoPause
)
```

Regras implementadas:

- sem `-RunReal`, o modo efetivo e dry-run;
- com `-DryRun`, o modo efetivo continua dry-run mesmo que outros parametros existam;
- `-RunReal` exige administrador, autorizacao de sessao e token textual;
- `-IncludeDiskScan` inclui `chkdsk C: /scan` no plano;
- `-IncludeDeepDiskRepair` nao libera `chkdsk C: /r` neste bloco;
- `-UseFallback` e aceito por simetria de interface, mas o Bloco 07 usa fila sequencial controlada em vez de abrir janelas;
- `-NoPause` e aceito, mas o launcher nao faz pausa interativa.

## Gates de seguranca

Para sair de dry-run e tentar execucao real futura, todos os gates precisam passar:

- `-RunReal`;
- ausencia de `-DryRun`;
- PowerShell em administrador;
- `-AllowSessionRealMaintenance`;
- `-ConfirmationToken "I_ACCEPT_WINDOWS_MAINTENANCE"`;
- configuracoes de startup/agendamento ainda seguras;
- comando dentro da allowlist;
- comando conhecido de manutencao liberado explicitamente pelo runner;
- fila sequencial, nao paralela.

Se qualquer gate falhar, o launcher registra erro, grava summary e encerra antes de invocar comandos reais.

## Estrategia de execucao real futura

A fila controlada e montada nesta ordem:

1. `DISM /Online /Cleanup-Image /RestoreHealth`
2. `sfc /scannow`
3. `chkdsk C: /scan`, somente com `-IncludeDiskScan`
4. `defrag C: /O /U /V`
5. `chkdsk C: /r`, sempre bloqueado neste bloco

Em dry-run, os itens habilitados sao registrados via `Invoke-DryRunCommand`. Em modo real futuro, apos gates aprovados, a fila usara `Invoke-CommandWithLog` de forma sequencial.

## Bloqueio do CHKDSK profundo

`chkdsk C: /r` permanece bloqueado por padrao e tambem fica bloqueado quando `-IncludeDeepDiskRepair` e informado.

Neste bloco:

- nao executa `chkdsk C: /r`;
- nao agenda reparo;
- nao solicita reinicializacao;
- nao cria token separado de reparo profundo;
- registra o item no plano apenas como `blocked_deep_disk_repair`.

## Validacao realizada

- Executados `git status --short`, `git branch --show-current` e `git log --oneline -5` antes das alteracoes.
- Confirmado que o Bloco 06 estava commitado em `ed9c7f3b72cb02a13c529acb65d65716f877fe3a`.
- Sintaxe validada com parser do PowerShell para:
  - `scripts/launchers/maintenance_real_common.ps1`
  - `scripts/launchers/launcher_maintenance_real.ps1`
  - `scripts/common/command_runner.ps1`
- `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json` validados com `ConvertFrom-Json`.
- Flags confirmadas como seguras:
  - `startup.enabled=false`
  - `scheduledTask.autoCreate=false`
  - `startup.allowHeavyCommandsOnStartup=false`
  - `allowStartupHeavyCommands=false`
- Confirmada existencia de `scripts/launchers/launcher_maintenance_real.ps1`.
- Validado por helper que o modo padrao e dry-run.
- Validado por helper que `-RunReal` sem token e bloqueado.
- Validado por helper que `-RunReal` sem administrador e bloqueado.
- Validado por helper que `-RunReal` sem `-AllowSessionRealMaintenance` e bloqueado.
- Validado que `chkdsk C: /r` fica como `blocked_deep_disk_repair`.
- Validado que `chkdsk C: /scan` so entra habilitado quando `-IncludeDiskScan` e solicitado.
- Validado que a allowlist do runner aceita `DISM` e bloqueia executavel fora da lista antes de execucao.
- Executado teste seguro do launcher sem `-RunReal`; resultado efetivo foi dry-run.
- Executado teste seguro de bloqueio com `-RunReal` sem token/sessao/admin; foi bloqueado antes de qualquer comando.
- Logs temporarios dos testes foram removidos apos validacao.
- Confirmado que `logs/` permaneceu apenas com `.gitkeep`.
- Confirmado que a tarefa agendada `WindowsMaintenanceTerminalGrid` nao existe.
- Confirmado que `config/*.json` nao teve diff.
- Confirmado que os arquivos `install.ps1`, `uninstall.ps1`, `scripts/startup/create_scheduled_task.ps1` e `scripts/startup/remove_scheduled_task.ps1` nao foram criados.

## Seguranca aplicada

- Dry-run permanece o padrao absoluto.
- Modo real exige opt-in manual por parametros.
- Admin e validado somente quando `-RunReal` e solicitado.
- Nao ha autoelevacao.
- Nao ha alteracao de politica persistente do PowerShell.
- Nao ha alteracao de registro.
- Nao ha criacao de tarefa agendada.
- Nao ha conexao com `startup_safe`.
- Configuracoes JSON nao foram alteradas para ativar modo real permanente.
- Comandos reais, quando futuramente autorizados, passam por allowlist e pelo runner comum.

## O que nao foi implementado propositalmente

- Execucao real durante a validacao.
- Execucao paralela dos quatro comandos.
- Integracao com Windows Terminal para modo real.
- Integracao com `startup_safe`.
- Criacao de tarefa agendada.
- `install.ps1`.
- `uninstall.ps1`.
- Alteracao de `config/*.json`.
- Autoelevacao.
- Agendamento ou execucao de `chkdsk C: /r`.
- Token separado para reparo profundo de disco.

## Riscos identificados

- O launcher agora possui caminho de execucao real futura; uso indevido de parametros completos podera acionar comandos pesados.
- `defrag C: /O /U /V` continua sendo operacao pesada e permanece por ultimo na fila.
- `DISM` pode depender de Windows Update e demorar bastante quando futuramente executado.
- `sfc /scannow` pode retornar estados que exigem interpretacao humana.
- `chkdsk C: /scan` e opcional porque pode consumir recursos durante o uso da maquina.
- `chkdsk C: /r` exige desenho separado por risco de reinicializacao e longa duracao.

## Pendencias para o Bloco 08

- Criar scripts de instalacao/remocao de tarefa agendada somente para `startup_safe`.
- Garantir que a tarefa agendada nunca aponte para `launcher_maintenance_real.ps1`.
- Manter janela visivel no startup.
- Preservar `scheduledTask.autoCreate=false` salvo decisao explicita do bloco.
- Validar install/uninstall sem conectar modo real ao login.

## Git

- Branch antes do bloco: `master`.
- Hash base antes do bloco: `ed9c7f3b72cb02a13c529acb65d65716f877fe3a`.
- Commit planejado apos validacao: `feat: add controlled maintenance real mode`.
- Push planejado: `git push origin master`, sem `--force`.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_08_tarefa_agendada_windows.md e implemente somente o Bloco 08 - Tarefa Agendada Windows. Crie install/uninstall seguros apontando apenas para launcher_startup_safe.ps1, sem conectar maintenance_real ao startup e sem executar comandos de manutencao do Windows.
```

## Confirmacao de seguranca

Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, tarefa agendada, startup automático, alteração de registro, autoelevação ou comando administrativo foi rodado durante este bloco.
