# Feedback - Bloco 04 - Scripts dos Terminais

## Objetivo do bloco

Criar os scripts de entrada dos quatro terminais do Windows Maintenance Terminal Grid usando as funcoes comuns e visuais existentes, mantendo execucao em modo seguro, visual-only e dry-run.

## Arquivos analisados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_04_scripts_dos_terminais.md`
- `Docs/06_scripts_funcoes/funcoes_common.md`
- `Docs/06_scripts_funcoes/funcoes_terminais.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/10_feedback/feedback_bloco_00_baseline_organizacao_repositorio.md`
- `Docs/10_feedback/feedback_bloco_01_configuracoes_base_json.md`
- `Docs/10_feedback/feedback_bloco_02_funcoes_comuns_powershell.md`
- `Docs/10_feedback/feedback_bloco_03_banners_loading_logs_visuais.md`
- `config/terminals.json`
- `config/visual_settings.json`
- `config/schedule_settings.json`
- `scripts/common/common.ps1`
- `README.md`

Todos os arquivos obrigatorios foram encontrados e lidos antes das alteracoes.

## Arquivos criados

- `scripts/terminals/terminal_runner.ps1`
- `scripts/terminals/analytics_dism.ps1`
- `scripts/terminals/scanning_sfc.ps1`
- `scripts/terminals/processing_chkdsk.ps1`
- `scripts/terminals/cleaning_optimize.ps1`
- `Docs/10_feedback/feedback_bloco_04_scripts_dos_terminais.md`

## Arquivos alterados

Nenhum arquivo preexistente foi alterado neste bloco.

## Scripts implementados

- `analytics_dism.ps1`: entrada segura do terminal `ANALYTICS`.
- `scanning_sfc.ps1`: entrada segura do terminal `SCANNING`.
- `processing_chkdsk.ps1`: entrada segura do terminal `PROCESSING`.
- `cleaning_optimize.ps1`: entrada segura do terminal `CLEANING`.

Todos aceitam:

```powershell
param(
  [string]$Mode = "startup_safe",
  [string]$RunLogDirectory = "",
  [switch]$NoPause,
  [switch]$DryRun
)
```

Os scripts aceitam os modos `visual_only`, `startup_safe`, `maintenance_real` e `maintenance_real_deep`, mas o Bloco 04 forca comportamento efetivo em dry-run.

## Helper criado, se aplicavel

Foi criado `scripts/terminals/terminal_runner.ps1` com a funcao principal:

- `Start-TerminalRoutine`

O helper centraliza:

- localizacao do root do projeto;
- importacao de `scripts/common/common.ps1`;
- carregamento de `config/terminals.json` e `config/visual_settings.json`;
- selecao da configuracao por `TerminalId`;
- criacao de pasta de log quando necessario;
- exibicao de banner, intro visual, loading e spinner;
- montagem do comando planejado como dado;
- chamada de `Invoke-DryRunCommand`;
- escrita de `summary.json`;
- pausa final controlada por `-NoPause`.

## Comportamento por terminal

`ANALYTICS`:

- mostra banner `ANALYTICS`;
- registra planejamento do comando `DISM /Online /Cleanup-Image /RestoreHealth`;
- executa apenas dry-run visual;
- registra que nenhuma manutencao foi executada.

`SCANNING`:

- mostra banner `SCANNING`;
- registra planejamento do comando `sfc /scannow`;
- executa apenas dry-run visual;
- registra que nenhuma verificacao real foi executada.

`PROCESSING`:

- mostra banner `PROCESSING`;
- registra planejamento do comando seguro `chkdsk C: /scan`;
- registra `chkdsk C: /r` como comando profundo futuro;
- registra que o comando profundo exige confirmacao manual futura;
- nao agenda reparo de disco e nao pede reinicializacao.

`CLEANING`:

- mostra banner `CLEANING`;
- registra planejamento do comando `defrag C: /O /U /V`;
- executa apenas dry-run visual;
- registra que nenhuma otimizacao real foi executada.

## Validacao realizada

- Executados `git status`, `git branch --show-current` e `git log --oneline -5` antes das alteracoes.
- Confirmado que o Bloco 03 estava commitado em `bf8ecc3a47dbaa619ac948c8e982bb1dc1be1bc9`.
- Sintaxe de todos os `.ps1` em `scripts/common/` e `scripts/terminals/` validada com parser do PowerShell.
- `scripts/common/common.ps1` importado com sucesso em processo seguro com `-ExecutionPolicy Bypass`, sem alterar politica persistente do PowerShell.
- `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json` continuam validos.
- Flags de seguranca continuam preservadas:
  - `allowRealMaintenance=false`
  - `allowStartupHeavyCommands=false`
  - `startup.allowHeavyCommandsOnStartup=false`
  - `startup.enabled=false`
  - `scheduledTask.autoCreate=false`
- Os quatro scripts foram executados em `startup_safe` com `-NoPause -DryRun`.
- A validacao gerou logs e summaries temporarios, removidos ao final.
- `logs/` permanece apenas com `.gitkeep`.
- Verificado que nao existe tarefa agendada `WindowsMaintenanceTerminalGrid`.
- Verificado que `scripts/launchers/` continua sem launcher funcional.
- Verificado que os scripts em `scripts/terminals/` nao contem chamadas a `Invoke-CommandWithLog`, `Start-Process`, `schtasks`, `Register-ScheduledTask` ou comandos literais de manutencao.

## Seguranca aplicada

- `DryRun` e efetivamente verdadeiro por padrao no helper.
- `startup_safe` e `visual_only` registram explicitamente que nenhum comando de manutencao sera executado.
- `maintenance_real` e `maintenance_real_deep` registram bloqueio seguro porque `allowRealMaintenance=false`.
- Nenhum script pede administrador.
- Nenhum script tenta autoelevacao.
- Nenhum script abre Windows Terminal.
- Nenhum script cria tarefa agendada.
- Nenhum JSON foi alterado.

## O que nao foi implementado propositalmente

- Execucao real de DISM.
- Execucao real de SFC.
- Execucao real de CHKDSK.
- Execucao real de defrag/otimizacao.
- Launcher Grid 2x2.
- Tarefa agendada.
- Autoelevacao.
- Alteracao de politica PowerShell.
- Confirmacao/agendamento de `chkdsk C: /r`.

## Riscos identificados

- Os scripts ja exibem e registram comandos planejados em dry-run; blocos futuros devem manter separacao clara entre planejamento e execucao real.
- O helper centraliza a logica dos terminais; qualquer mudanca futura nele afeta os quatro terminais.
- O Bloco 05 deve passar `RunLogDirectory` compartilhado para manter logs dos quatro terminais na mesma execucao.
- Quando o modo real for implementado futuramente, sera necessario validar administrador, fila de execucao e confirmacao explicita antes de liberar comandos.

## Pendencias para o Bloco 05

- Criar launcher/grid 2x2.
- Abrir os quatro scripts em paineis ou janelas separadas.
- Passar `Mode`, `RunLogDirectory`, `-NoPause` e `-DryRun` corretamente.
- Preferir Windows Terminal com fallback seguro.
- Nao habilitar manutencao real no launcher do Bloco 05.

## Git

- Branch atual antes do bloco: `master`.
- Hash base antes do bloco: `bf8ecc3a47dbaa619ac948c8e982bb1dc1be1bc9`.
- Commit planejado apos validacao: `feat: add safe terminal entry scripts`.
- Push planejado: `git push origin master`, sem `--force`.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_05_launcher_grid_2x2.md e implemente somente o Bloco 05. Crie o launcher Grid 2x2 para abrir os quatro scripts de terminal em modo seguro/dry-run, preferindo Windows Terminal e documentando fallback. Nao execute comandos de manutencao do Windows e nao crie tarefa agendada.
```

## Confirmação de segurança

Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, tarefa agendada, launcher funcional ou comando administrativo foi rodado neste bloco.
