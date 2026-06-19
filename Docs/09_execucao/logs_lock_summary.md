# Logs, Lock File e Summary

## Objetivo

Explicar, com base no codigo real de `scripts/common/` (Bloco 09), como
interpretar a pasta de logs de uma execucao, o lock file e os arquivos de
summary — individual por terminal e consolidado.

## Estrutura de uma pasta de execucao

Cada execucao (terminal, launcher, startup safe ou manutencao real) cria
ou reutiliza uma pasta `logs/<RunId>/`:

```text
logs/<RunId>/
  run_metadata.json
  execution_events.ndjson
  launcher.log | startup_safe.log | maintenance_real.log   (um por origem)
  terminals/
    <terminal>.log
  summaries/
    <terminal>_summary.json
  summary.json                 (somente apos consolidacao pelo launcher)
```

`RunId` segue o formato `<source>_<YYYY-MM-DD_HH-mm-ss>_<6 caracteres
aleatorios>` (gerado por `New-RunId`), por exemplo
`startup_safe_2026-06-19_15-04-37_a1b2c3`. Quando o launcher de grid abre
os 4 terminais, ele cria a pasta uma vez e passa o mesmo
`-RunLogDirectory` para cada script de terminal — por isso todos os logs
de uma mesma execucao ficam juntos na mesma pasta.

## `run_metadata.json`

Gravado uma vez, no inicio da execucao (`Write-RunMetadata`):

```json
{
  "runId": "...",
  "mode": "startup_safe | maintenance_real | visual_only",
  "source": "...",
  "startedAt": "2026-06-19T15:04:37...",
  "dryRun": true,
  "projectRoot": "...",
  "logDirectory": "...",
  "machineName": "...",
  "userName": "...",
  "processId": 1234
}
```

## `execution_events.ndjson`

Um evento por linha (newline-delimited JSON), gravado por
`Write-ExecutionEvent`. Todos os wrappers de log por origem
(`Write-LauncherLog`, `Write-TerminalLog`, `Write-MaintenanceLog`,
`Write-StartupLog`) convergem para esta mesma funcao — e a fonte unica de
verdade para contar erros/avisos (`Get-WmtgExecutionEventStats`, usada na
consolidacao do summary).

## Logs por origem (`.log`)

Texto legivel por humano, um arquivo por origem (`launcher.log`,
`startup_safe.log`, `maintenance_real.log`) na raiz da pasta de execucao,
e um por terminal em `terminals/<terminal>.log`. Use estes arquivos como
primeira leitura ao investigar um problema — eles tem o mesmo conteudo dos
eventos NDJSON, em formato mais facil de ler manualmente.

## Summary individual por terminal (`summaries/<terminal>_summary.json`)

Gravado por `Write-TerminalSummaryJson`, chamado apenas por
`Start-TerminalRoutine` (cada script de terminal grava somente o seu
proprio arquivo). Contem `entries` (uma por comando planejado/executado,
com `command`, `arguments`, `dryRun`, `status`, `exitCode`, `error`,
`startedAt`, `finishedAt`), `status` geral (`completed` ou
`completed_with_errors`) e `terminalId`.

## Summary consolidado (`summary.json`)

Gravado **apenas** por `Write-ConsolidatedSummaryJson`, chamado apenas
pelos launchers (`Invoke-LauncherSummaryConsolidation` no grid launcher,
ou diretamente em `launcher_maintenance_real.ps1`). Nunca e escrito por um
script de terminal individual — isso evita que a consolidacao sobrescreva
os summaries por terminal. Contem:

- `terminals`: objeto (nao array) com uma chave por `terminalId`, valor =
  o conteudo do `summaries/<terminal>_summary.json` correspondente.
- `eventsCount`, `errorsCount`, `warningsCount`: agregados de
  `execution_events.ndjson`.
- `status`: `completed`, `completed_with_errors`, ou `blocked` (se algum
  terminal/etapa tiver status contendo `blocked`, como
  `blocked_deep_disk_repair` ou `blocked_gate`).

> **Importante:** `launcher_grid_2x2.ps1` abre os terminais como
> processos destacados e nao espera a conclusao deles. O `summary.json`
> consolidado so reflete os summaries individuais que ja existirem em
> `summaries/` no momento em que `-ConsolidateSummaries` for chamado — se
> os terminais ainda estiverem rodando, chame novamente apos eles
> terminarem.

## Lock file

Caminho fixo: `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock`
(`Get-LockFilePath`). Conteudo (JSON):

```json
{
  "runId": "...",
  "mode": "startup_safe | maintenance_real",
  "startedAt": "...",
  "pid": 1234,
  "projectRoot": "...",
  "logDirectory": "...",
  "expiresAt": "...",
  "createdBy": "DOMAIN\\user",
  "machineName": "...",
  "userName": "..."
}
```

Regras de `New-LockFile`:

- Mesmo PID pode reentrar (reexecutar) sem erro.
- Lock de outro PID **vivo** e **nao expirado** bloqueia uma nova
  execucao (lanca excecao).
- Lock de PID morto, ou com `expiresAt` no passado, e considerado
  **obsoleto** (`IsStale`) — `Assert-NoActiveLock`/`New-LockFile` o
  removem automaticamente antes de criar um novo.
- Expiracao: 30 minutos para `startup_safe`, 180 minutos para
  `maintenance_real`.
- `Remove-LockFile` so remove o arquivo se quem chama souber o `Pid`/`RunId`
  esperado (passado pelos launchers no bloco `finally`), evitando que um
  processo remova o lock de outro.

Se precisar limpar um lock manualmente (ex.: processo travado sem ter
passado pelo `finally`), confirme primeiro que o PID gravado no JSON nao
esta mais ativo (`Get-Process -Id <pid>`) antes de apagar o arquivo — ver
[troubleshooting.md](troubleshooting.md).

## Retencao de logs antigos

`scripts/common/log_retention.ps1` expõe `Get-LogRetentionDays`
(le `config/schedule_settings.json` -> `logs.retentionDays`, padrao 30) e
`Clear-OldRunLogs` (lista candidatos mais antigos que o limite; só
remove de fato com `-Apply`). **Nenhum launcher chama isso
automaticamente** nesta fase do projeto — e uma operacao manual/futura,
nao uma limpeza automatica em background.

## Arquivos Relacionados

- `scripts/common/run_context.ps1`, `summary_writer.ps1`, `lock_file.ps1`,
  `logger.ps1`, `log_retention.ps1`
- `Docs/03_arquitetura/estrategia_de_logs.md`
- [troubleshooting.md](troubleshooting.md), [validacao_local.md](validacao_local.md)

## Riscos

- Remover o lock file manualmente sem confirmar que o PID esta morto pode
  permitir execucao duplicada simultanea.
- Tratar a ausencia de `summary.json` consolidado como erro, quando na
  verdade so significa que `-ConsolidateSummaries` ainda nao foi chamado
  apos os terminais terminarem.

## Criterios de Aceite

- Cada tipo de arquivo (`run_metadata.json`, `execution_events.ndjson`,
  `.log`, summary individual, summary consolidado, lock file) tem dono e
  formato documentados.
- A diferenca entre summary individual e consolidado, e quem escreve cada
  um, esta explicita.
