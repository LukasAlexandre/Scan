# Feedback - Bloco 09 - Logs, Lock File e Summary

## Objetivo do bloco

Consolidar a estrategia de logs estruturados, protecao contra execucao duplicada e resumo final da execucao, corrigindo o problema de `summary.json` ser sobrescrito quando os quatro terminais rodam em paralelo dentro do mesmo `RunLogDirectory`.

## Arquivos analisados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_09_logs_lockfile_summary.md`
- `Docs/06_scripts_funcoes/funcoes_startup.md`
- `Docs/06_scripts_funcoes/funcoes_launcher.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/10_feedback/feedback_bloco_07_modo_maintenance_real.md`
- `Docs/10_feedback/feedback_bloco_08_tarefa_agendada_windows.md`
- `config/terminals.json`
- `config/visual_settings.json`
- `config/schedule_settings.json`
- `scripts/common/common.ps1`
- `scripts/common/logger.ps1`
- `scripts/common/lock_file.ps1`
- `scripts/common/summary_writer.ps1`
- `scripts/common/command_runner.ps1`
- `scripts/terminals/terminal_runner.ps1`
- `scripts/launchers/launcher_common.ps1`
- `scripts/launchers/launcher_grid_2x2.ps1`
- `scripts/launchers/launcher_maintenance_real.ps1`
- `scripts/launchers/maintenance_real_common.ps1`
- `scripts/startup/startup_common.ps1`
- `scripts/startup/launcher_startup_safe.ps1`
- `scripts/startup/create_scheduled_task.ps1`
- `scripts/startup/remove_scheduled_task.ps1`

Todos os arquivos obrigatorios foram encontrados e lidos antes das alteracoes. O Bloco 08 ja estava commitado (`62c19d0`, "feat: add scheduled task installer") e sincronizado com `origin/master`; nenhuma acao de git foi necessaria antes de iniciar.

## Arquivos criados

- `scripts/common/run_context.ps1`
- `scripts/common/log_retention.ps1`
- `Docs/10_feedback/feedback_bloco_09_logs_lock_file_summary.md`

## Arquivos alterados

- `scripts/common/logger.ps1`
- `scripts/common/lock_file.ps1`
- `scripts/common/summary_writer.ps1`
- `scripts/common/common.ps1`
- `scripts/terminals/terminal_runner.ps1`
- `scripts/launchers/launcher_common.ps1`
- `scripts/launchers/launcher_grid_2x2.ps1`
- `scripts/launchers/launcher_maintenance_real.ps1`
- `scripts/startup/startup_common.ps1`
- `scripts/startup/launcher_startup_safe.ps1`

`scripts/launchers/maintenance_real_common.ps1` foi analisado mas **nao** foi alterado, pois nao constava na lista de arquivos permitidos para este bloco. Como consequencia, o log interno de `Invoke-MaintenanceExecutionPlan` continua usando `Write-WarningLog`/`Write-ErrorLog` simples, sem eventos `ndjson`. Isso ficou registrado como limitacao conhecida em "Riscos e limitacoes conhecidas".

## Estrutura final de logs

```text
logs/<YYYY-MM-DD_HH-mm-ss_RunId>/
  run_metadata.json
  execution_events.ndjson
  launcher.log
  startup_safe.log
  maintenance_real.log
  terminals/
    analytics.log
    scanning.log
    processing.log
    cleaning.log
  summaries/
    analytics_summary.json
    scanning_summary.json
    processing_summary.json
    cleaning_summary.json
  summary.json
```

- `New-RunContext` cria o `RunId` (timestamp + sufixo aleatorio) e a pasta correspondente, incluindo `terminals/` e `summaries/`.
- `Write-RunMetadata`/`Read-RunMetadata` persistem e releem `run_metadata.json`, garantindo que o mesmo `RunId` seja reutilizado por todo o processo filho (terminal) e pelos launchers, em vez de gerar um novo a cada chamada.
- `Write-ExecutionEvent` grava uma linha `ndjson` por evento em `execution_events.ndjson`; `Write-TerminalLog`, `Write-LauncherLog`, `Write-StartupLog` e `Write-MaintenanceLog` escrevem a linha legivel no arquivo `.log` correspondente e, em seguida, o evento estruturado.

## Mecanica do lock file

- Caminho: `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock` (antes `grid.lock`).
- Conteudo: `runId`, `mode`, `startedAt`, `pid`, `projectRoot`, `logDirectory`, `expiresAt`, `createdBy`, `machineName`, `userName`.
- `Test-LockFile` calcula `ProcessActive` (via `Get-Process -Id`), `IsExpired` (baseado em `expiresAt`) e `IsStale` (processo morto ou expirado).
- `New-LockFile` so bloqueia quando o lock pertence a outro PID vivo, nao expirado e nao obsoleto; um lock pertencente ao **mesmo PID** nunca e tratado como conflito (reentrancia segura). Isso permite que `launcher_startup_safe.ps1` chame `launcher_grid_2x2.ps1` via `&` no mesmo processo sem se autobloquear, mantendo o bloqueio real para uma segunda execucao concorrente de outro processo.
- `Remove-LockFile` so remove o arquivo se o PID (e, quando informado, o `RunId`) gravado no lock corresponder ao esperado; caso contrario, lanca erro em vez de remover um lock de outro processo.
- O lock e usado apenas pelos tres launchers (`launcher_grid_2x2.ps1`, `launcher_maintenance_real.ps1`, `launcher_startup_safe.ps1`), nunca pelos quatro scripts de terminal, evitando que os terminais se bloqueiem entre si dentro da mesma execucao.

## Como o summary deixou de ser sobrescrito

O bug original: os quatro terminais compartilhavam o mesmo `RunLogDirectory` e cada um chamava a mesma funcao de escrita de `summary.json`, entao o ultimo terminal a terminar sobrescrevia o resultado dos outros tres.

Correcao aplicada:

- Cada terminal agora chama `Write-TerminalSummaryJson`, que grava **seu proprio arquivo** em `summaries/<terminalId>_summary.json`. Quatro arquivos distintos, sem concorrencia de escrita no mesmo caminho.
- Apenas os launchers chamam `Write-ConsolidatedSummaryJson`, que usa `Merge-TerminalSummaries` para ler os quatro arquivos em `summaries/` e `Get-WmtgExecutionEventStats` para contar eventos/erros/avisos em `execution_events.ndjson`, produzindo um unico `summary.json` no topo do `RunLogDirectory` com a chave `terminals` contendo os quatro resumos.
- Teste em diretorio temporario confirmou: apos escrever os 4 `summaries/*_summary.json` e consolidar, os 4 arquivos por terminal continuaram intactos e o `summary.json` final contem as chaves `analytics`, `scanning`, `processing`, `cleaning`.

## Resultados da validacao

- Sintaxe validada com `[System.Management.Automation.Language.Parser]::ParseFile()` (ferramenta PowerShell, ja que `pwsh` nao esta disponivel no ambiente Git Bash) para os 12 arquivos novos/alterados: todos `OK`.
- `common.ps1` carregado isoladamente; todas as funcoes esperadas (antigas e novas) resolvidas via `Get-Command -CommandType Function`.
- `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json` validados com `ConvertFrom-Json`: todos validos.
- `git diff --stat` nesses tres arquivos de configuracao: vazio (nenhuma alteracao).
- Teste de lock file em `%LOCALAPPDATA%` isolado (diretorio temporario):
  - Lock inexistente detectado corretamente (`Exists=False`).
  - Lock com PID morto e `expiresAt` no passado detectado como `ProcessActive=False`, `IsExpired=True`, `IsStale=True`; removido com sucesso por `Clear-StaleLockFile`.
  - Lock criado com o PID do processo atual; nova chamada de `New-LockFile` com o mesmo PID nao lancou erro (reentrancia same-PID confirmada).
  - Lock simulado com PID de um processo realmente vivo e diferente (`explorer.exe`) bloqueou corretamente uma nova chamada de `New-LockFile`, lancando excecao.
  - `Remove-LockFile` com `-ExpectedPid` recusou remover um lock pertencente a outro PID (erro esperado), confirmando a protecao contra remocao indevida.
- Teste de `New-RunContext` em projeto temporario: pastas `terminals/` e `summaries/` criadas, `run_metadata.json` gravado e relido com o mesmo `RunId`, 4 logs de terminal e 4 `summaries/*_summary.json` gerados, `execution_events.ndjson` com todas as linhas validas em JSON, `summary.json` consolidado com as 4 chaves de terminal e os arquivos individuais preservados.
- Teste de `Clear-OldRunLogs`/`Get-LogRetentionDays`: retencao padrao lida de `config/schedule_settings.json` (30 dias); execucao sem `-Apply` listou a pasta antiga sem remove-la; execucao com `-Apply` removeu apenas a pasta mais antiga que o limite, preservando a pasta recente.
- Confirmado que a pasta real `logs/` continua contendo apenas `.gitkeep`.
- Confirmado que nao existe tarefa agendada `WindowsMaintenanceTerminalGrid` (`Get-ScheduledTask` retornou vazio).
- Confirmado que nao existe `run.lock` real em `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\`.
- `git status --short` ao final mostra somente os arquivos deste bloco (10 alterados + 2 novos), sem nenhum arquivo de configuracao ou log real modificado.

## Confirmacao que nenhum comando pesado foi executado

Nenhum `DISM`, `SFC`, `CHKDSK`, `defrag` ou qualquer comando real de manutencao foi executado durante a implementacao ou validacao. Todos os testes usaram diretorios temporarios (`$env:TEMP`) e `%LOCALAPPDATA%` isolado, sem tocar `maintenance_real_common.ps1` nem invocar `launcher_maintenance_real.ps1 -RunReal`.

## Confirmacao que nenhuma tarefa agendada foi criada

Nenhuma tarefa agendada foi criada, alterada ou removida. `install.ps1`, `uninstall.ps1`, `create_scheduled_task.ps1` e `remove_scheduled_task.ps1` nao foram executados neste bloco. `Get-ScheduledTask -TaskName 'WindowsMaintenanceTerminalGrid'` confirmou ausencia da tarefa antes e depois da validacao.

## Riscos e limitacoes conhecidas

- `launcher_grid_2x2.ps1` abre os quatro terminais via `Start-Process`/`wt.exe` de forma nao bloqueante; o launcher nao tem como esperar os processos filhos terminarem. Por isso a consolidacao do `summary.json` final foi isolada no novo switch `-ConsolidateSummaries`, que deve ser chamado separadamente apos os quatro terminais terminarem. Esse limite arquitetural foi documentado em log (`Write-LauncherLog`) e nao foi "resolvido" de forma forcada (por exemplo, com polling ou espera fixa), para nao mascarar o comportamento real de processos detached.
- `scripts/launchers/maintenance_real_common.ps1` nao foi alterado (fora da lista de arquivos permitidos); o log interno de `Invoke-MaintenanceExecutionPlan` ainda nao emite eventos `ndjson`. Fica como pendencia explicita.
- O encadeamento `startup_safe -> grid launcher` no mesmo processo depende da exencao de reentrancia same-PID no lock; se algum dia o `launcher_grid_2x2.ps1` passar a ser chamado via `Start-Process` (processo separado) a partir do `startup_safe`, esse comportamento de reentrancia deixa de se aplicar e precisara ser revisado.
- `Clear-OldRunLogs` ainda nao e chamado automaticamente por nenhum launcher; permanece disponivel apenas como funcao utilitaria.

## Pendencias para o Bloco 10

- Acionar `-ConsolidateSummaries` (ou um mecanismo equivalente de espera) automaticamente apos a finalizacao dos quatro terminais, em vez de depender de chamada manual.
- Levar `maintenance_real_common.ps1` para o padrao de log estruturado (`Write-MaintenanceLog`/`Write-ExecutionEvent`) quando esse arquivo entrar no escopo permitido.
- Agendar/automatizar `Clear-OldRunLogs` (por exemplo, no inicio do `startup_safe`) respeitando `logs.retentionDays`.
- Revisar a reentrancia do lock se o modelo de chamada entre `startup_safe` e `launcher_grid_2x2.ps1` mudar de `&` (mesmo processo) para um processo separado.

## Git

- Branch antes do bloco: `master`.
- Hash base antes do bloco: `62c19d0` ("feat: add scheduled task installer").
- Commit aplicado apos validacao: `feat: improve logs lock and summary`.
- Push aplicado: `git push origin master`, sem `--force`.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_10_*.md (ou o proximo bloco definido em divisao_em_blocos.md) e implemente somente o Bloco 10. Use a base de logs, lock file e summary do Bloco 09 sem executar comandos de manutencao real.
```

## Analise adicional com Graphify

- Graphify foi usado: sim
- Comando executado: `uv tool install graphifyy` seguido de `graphify update <raiz-do-projeto>` (modo somente-codigo, sem chave de LLM, sem custo de API)
- Arquivos gerados: `graphify-out/graph.json`, `graphify-out/graph.html`, `graphify-out/GRAPH_REPORT.md` (nao versionados; `graphify-out/` adicionado ao `.gitignore`). Conclusoes curadas registradas em `Docs/03_arquitetura/graphify_relatorio_arquitetura.md`.
- Principais relacoes identificadas: `New-RunContext()` e chamado por `Start-TerminalRoutine()`, `New-LauncherContext()` e `New-StartupRunContext()`; `Write-ConsolidatedSummaryJson()` so e chamado por `Invoke-LauncherSummaryConsolidation()` (launcher); `Write-TerminalSummaryJson()` so e chamado por `Start-TerminalRoutine()` (terminal); `Write-ExecutionEvent()` e chamado pelos quatro wrappers de log (`Write-LauncherLog`, `Write-TerminalLog`, `Write-MaintenanceLog`, `Write-StartupLog`).
- Impacto na implementacao do Bloco 09: nenhuma mudanca de codigo foi feita por causa do Graphify, pois a analise foi executada **depois** da implementacao/validacao manual. Serviu como segunda confirmacao independente de que a separacao entre summary por terminal e summary consolidado, e a concentracao de logs estruturados em `Write-ExecutionEvent()`, estao corretas.
- Observacoes: a extracao foi feita somente em modo codigo (sem chave de LLM configurada), portanto nao houve cruzamento semantico com `Docs/*.md`. A travessia reversa de `New-LockFile()` no grafo so encontrou `New-LauncherRunLock()` como chamador, mas a leitura direta do codigo confirmou que `launcher_maintenance_real.ps1` e `launcher_startup_safe.ps1` tambem chamam `New-LockFile()` diretamente — gap conhecido da extracao heuristica sem etapa semantica, nao um problema de arquitetura.

## Confirmacao de seguranca

Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, modo real, startup automático real durante validação, alteração de registro, autoelevação ou comando administrativo foi rodado neste bloco.
