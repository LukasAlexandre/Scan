# Feedback - Bloco 02 - Funcoes Comuns PowerShell

## Objetivo do bloco

Criar a infraestrutura comum em PowerShell para leitura de configuracao, logs, banners visuais, loading, spinner, validacao de administrador, lock file, execucao controlada com dry run e escrita de `summary.json`.

## Arquivos analisados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_02_funcoes_comuns_powershell.md`
- `Docs/06_scripts_funcoes/funcoes_common.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/10_feedback/feedback_bloco_00_baseline_organizacao_repositorio.md`
- `Docs/10_feedback/feedback_bloco_01_configuracoes_base_json.md`
- `config/terminals.json`
- `config/visual_settings.json`
- `config/schedule_settings.json`
- `README.md`

Todos os arquivos obrigatorios foram encontrados e lidos antes das alteracoes.

## Arquivos criados

- `scripts/common/config_loader.ps1`
- `scripts/common/logger.ps1`
- `scripts/common/banner.ps1`
- `scripts/common/spinner.ps1`
- `scripts/common/admin_check.ps1`
- `scripts/common/lock_file.ps1`
- `scripts/common/command_runner.ps1`
- `scripts/common/summary_writer.ps1`
- `scripts/common/common.ps1`
- `Docs/10_feedback/feedback_bloco_02_funcoes_comuns_powershell.md`

## Arquivos alterados

Nenhum arquivo preexistente foi alterado neste bloco.

## Funcoes implementadas

`config_loader.ps1`:

- `Get-ProjectRoot`
- `Get-JsonConfig`
- `Get-TerminalsConfig`
- `Get-VisualSettings`
- `Get-ScheduleSettings`
- `Test-RequiredConfigFiles`

`logger.ps1`:

- `New-RunLogDirectory`
- `Write-Log`
- `Write-ColoredLog`
- `Write-SectionLog`
- `Write-WarningLog`
- `Write-ErrorLog`

`banner.ps1`:

- `Show-Banner`
- `Show-TerminalIntro`
- `Show-TypingText`

`spinner.ps1`:

- `Show-LoadingBar`
- `Show-Spinner`
- `Start-VisualDelay`

`admin_check.ps1`:

- `Test-IsAdmin`
- `Assert-AdminOrThrow`

`lock_file.ps1`:

- `Get-LockFilePath`
- `Test-LockFile`
- `New-LockFile`
- `Remove-LockFile`
- `Clear-StaleLockFile`

`command_runner.ps1`:

- `Invoke-CommandWithLog`
- `Invoke-DryRunCommand`

`summary_writer.ps1`:

- `Write-SummaryJson`
- `New-ExecutionSummary`
- `Add-SummaryEntry`

`common.ps1`:

- importa os modulos comuns por dot sourcing;
- valida a disponibilidade das funcoes principais;
- nao executa manutencao ao ser importado.

## Estrutura dos modulos comuns

Os modulos foram separados por responsabilidade:

- carregamento de configuracao;
- observabilidade/logs;
- visual seguro;
- validacao administrativa;
- lock file;
- runner com dry run por padrao;
- summary JSON;
- agregador central `common.ps1`.

## Decisoes tecnicas

- `Invoke-CommandWithLog` usa `DryRun=true` por padrao.
- Execucao real futura exige `AllowRealMaintenance=true`.
- Execucao real futura pode exigir administrador via `RequireAdmin`.
- Execucao real futura exige token explicito por padrao.
- Comandos conhecidos de manutencao do Windows sao bloqueados por uma trava adicional quando nao ha permissao explicita.
- Logs de arquivo sao restringidos a caminhos dentro do projeto.
- Lock file usa `%LOCALAPPDATA%/WindowsMaintenanceTerminalGrid/`.
- `Assert-AdminOrThrow` apenas lanca erro; nao solicita elevacao e nao abre novo processo.
- `common.ps1` nao roda rotinas de manutencao, apenas importa e valida funcoes.

## Validacao realizada

- Verificada a existencia dos nove arquivos `.ps1` comuns.
- Verificado que os tres JSON continuam validos via parse seguro.
- Verificado que as flags permanecem seguras:
  - `allowRealMaintenance=false`
  - `allowStartupHeavyCommands=false`
  - `startup.allowHeavyCommandsOnStartup=false`
  - `startup.enabled=false`
  - `scheduledTask.autoCreate=false`
- Validado que `common.ps1` importa com sucesso em processo isolado com `-ExecutionPolicy Bypass`, sem alterar a politica persistente do PowerShell.
- Validado que `Get-ProjectRoot`, `Get-TerminalsConfig`, `Get-VisualSettings` e `Get-ScheduleSettings` leem dados esperados.
- Validado `Invoke-DryRunCommand` com comando ficticio `example.exe`, sem executar processo real de manutencao.
- Verificado que nao foram criados scripts em `scripts/terminals/`.
- Verificado que nao foram criados launchers em `scripts/launchers/`.
- Verificado que nao existe tarefa agendada `WindowsMaintenanceTerminalGrid`.
- Verificado que `logs/` permanece apenas com `.gitkeep`.

Observacao: a tentativa direta de dot-source foi bloqueada pela politica local de execucao de scripts. Nenhuma politica foi alterada. A validacao de importacao foi feita em processo isolado com `-ExecutionPolicy Bypass`.

## Seguranca aplicada

- Nenhum comando planejado de manutencao foi chamado.
- O runner e seguro por padrao por causa de `DryRun=true`.
- Manutencao real futura precisa passar por flags explicitas.
- Admin check nao eleva automaticamente.
- Lock file so escreve fora do projeto quando a funcao for chamada explicitamente, no caminho esperado em `%LOCALAPPDATA%`.
- Banners, loading e spinner sao apenas visuais.

## O que nao foi implementado propositalmente

- Nenhum script de terminal.
- Nenhum launcher.
- Nenhuma tarefa agendada.
- Nenhum comando DISM, SFC, CHKDSK ou defrag.
- Nenhuma alteracao em `config/*.json`.
- Nenhuma alteracao em `README.md`.
- Nenhuma alteracao de politica de execucao PowerShell.
- Nenhuma abertura de Windows Terminal.

## Riscos identificados

- Blocos futuros devem carregar `common.ps1` respeitando a politica de execucao do ambiente.
- Blocos futuros precisam decidir como passar tokens de confirmacao para execucao real.
- O runner real existe como infraestrutura, mas so deve ser usado depois de validacoes adicionais no Bloco 07.
- Lock file precisa ser testado com processos reais nos blocos de launcher/startup.

## Pendencias para o Bloco 03

- Usar `banner.ps1` e `spinner.ps1` para melhorar a experiencia visual.
- Definir banners finais para `ANALYTICS`, `SCANNING`, `PROCESSING` e `CLEANING`.
- Ajustar velocidades visuais a partir de `config/visual_settings.json`.
- Garantir que mensagens visuais usem prefixo claro e nao simulem sucesso tecnico.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_03_banners_loading_logs_visuais.md e implemente somente o Bloco 03. Use as funcoes comuns do Bloco 02 para aprimorar banners, loading, spinner, efeito de digitacao e logs visuais. Nao execute comandos de manutencao do Windows, nao crie scripts reais dos terminais e nao crie tarefa agendada.
```

## Confirmação de segurança

Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, tarefa agendada, launcher funcional dos terminais ou comando administrativo foi rodado neste bloco.
