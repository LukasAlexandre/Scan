# Relatorio de Validacao Local - Bloco 10

## Objetivo

Registrar a execucao real da suite de testes seguros locais criada no Bloco 10
(`tests/*.ps1`), comprovando que os comportamentos centrais do projeto — configuracao,
modulos comuns, terminais, launchers, startup safe, gates do modo manutencao real,
logs/lock/summary, tarefa agendada e varredura de seguranca estatica — funcionam
como esperado, sem que nenhum comando real de manutencao, autoelevacao ou alteracao
de tarefa agendada tenha sido executado.

## Ambiente de execucao

- Sistema operacional: Windows 11 Pro 10.0.26200.
- Shell usado para a execucao: Windows PowerShell 5.1 (`powershell.exe`); `pwsh`
  (PowerShell 7+) nao esta instalado neste ambiente.
- Diretorio do projeto: `c:\Users\LARos\Documents\Dev\Scan`.
- Privilegio do usuario durante a execucao: nao administrador (sessao padrao).
- `wt.exe` (Windows Terminal): presente no PATH, mas nenhum teste abriu janela real —
  todas as chamadas a scripts de terminal/launcher usaram `-DryRun`/`-ConsolidateSummaries`
  ou chamaram funcoes diretamente.

## Suite de testes executada

Comando usado: `powershell.exe -NoProfile -File tests\run_all_safe_tests.ps1`.

O runner executa, em sequencia, os 9 scripts abaixo e consolida o resultado em
`tests/results/<timestamp>/test_summary.json` e `test_report.md`:

1. `test_config_json.ps1`
2. `test_common_modules.ps1`
3. `test_terminal_scripts_dry_run.ps1`
4. `test_launchers_dry_run.ps1`
5. `test_startup_safe_dry_run.ps1`
6. `test_maintenance_real_gates.ps1`
7. `test_logs_lock_summary.ps1`
8. `test_scheduled_task_dry_run.ps1`
9. `test_security_static_scan.ps1`

## Resultado por teste

Execucao final (`tests/results/2026-06-19_15-06-32/test_summary.json`):

| Teste | Resultado | Checagens | Erros |
| --- | --- | --- | --- |
| test_config_json | PASS | 13 | 0 |
| test_common_modules | PASS | 54 | 0 |
| test_terminal_scripts_dry_run | PASS | 28 | 0 |
| test_launchers_dry_run | PASS | 15 | 0 |
| test_startup_safe_dry_run | PASS | 16 | 0 |
| test_maintenance_real_gates | PASS | 20 | 0 |
| test_logs_lock_summary | PASS | 30 | 0 |
| test_scheduled_task_dry_run | PASS | 12 | 0 |
| test_security_static_scan | PASS | 11 | 0 |
| **Total** | **PASS** | **199** | **0** |

### Falso positivo encontrado e corrigido durante a validacao

A primeira execucao (`tests/results/2026-06-19_15-04-37/`) reportou 1 erro em
`test_security_static_scan`: a checagem `register_scheduled_task_only_in_permitted_script`
apontou `scripts/startup/remove_scheduled_task.ps1` como violacao. Investigacao confirmou que
o arquivo so contem a chamada legitima `Unregister-ScheduledTask -TaskName $taskName -Confirm:$false`
(linha 62) — o padrao `Register-ScheduledTask` casava (case-insensitive, comportamento padrao de
`-match` no PowerShell) com a subcadeia `Register-ScheduledTask` dentro de `Unregister-ScheduledTask`.
Corrigido trocando o padrao para `(?<!Un)Register-ScheduledTask` em
`tests/test_security_static_scan.ps1`. Apos a correcao, a suite completa roda com 0 erros
(`tests/results/2026-06-19_15-06-32/`). Nenhum codigo fora de `tests/` foi alterado por causa
deste ajuste — o problema era do proprio teste, nao do script de producao.

## Evidencias e logs

- Logs de console por teste: `tests/results/2026-06-19_15-06-32/<teste>.console.log`.
- Resultado estruturado por teste: `tests/results/2026-06-19_15-06-32/<teste>.json`.
- Resumo agregado: `tests/results/2026-06-19_15-06-32/test_summary.json` e
  `test_report.md`.
- `test_common_modules` confirmou, via `Get-Command`, que todas as funcoes publicas
  esperadas de `scripts/common/*.ps1` (logger, lock file, run context, summary writer,
  log retention, banner, spinner, admin check, config loader, command runner) estao
  disponiveis depois de carregar `common.ps1`.
- `test_logs_lock_summary` gerou, em pasta temporaria sob `logs/_tests_tmp_*`,
  `run_metadata.json`, `execution_events.ndjson`, 4 logs de terminal, 4
  `summaries/<id>_summary.json` e o `summary.json` consolidado com as 4 chaves de
  terminal — confirmando que os individuais nao sao sobrescritos pela consolidacao
  (continuacao da garantia entregue no Bloco 09).
- `test_maintenance_real_gates` confirmou que `Test-MaintenanceRealGates` bloqueia
  corretamente a ausencia isolada de token, admin ou flag de sessao, e que
  `Invoke-CommandWithLog` lanca excecao antes de criar qualquer processo quando o
  token de confirmacao esta incorreto.
- `test_scheduled_task_dry_run` confirmou que `install.ps1`/`uninstall.ps1` sem
  `-Apply` retornam `DryRun=$true`, e que `-Apply -ConfirmationToken 'wrong_token_value'`
  lanca excecao antes de alcancar `Register-ScheduledTask`/`Unregister-ScheduledTask`.

## Cobertura por cenario (`Docs/08_testes/fluxo_de_testes.md`)

| Cenario do roteiro oficial | Cobertura automatizada no Bloco 10 |
| --- | --- |
| 01 - Organizacao Base | `test_config_json.ps1`, `test_common_modules.ps1` |
| 02 - Modo Visual Seguro | `test_terminal_scripts_dry_run.ps1`, `test_launchers_dry_run.ps1`, `test_startup_safe_dry_run.ps1` |
| 03 - Modo Manutencao Real | `test_maintenance_real_gates.ps1` |
| 04 - CHKDSK Profundo | `test_maintenance_real_gates.ps1` (checagens `deep_disk_repair_*`), `test_security_static_scan.ps1` |
| 05 - Logs | `test_logs_lock_summary.ps1` (Parte A) |
| 06 - Summary JSON | `test_logs_lock_summary.ps1` (Parte A, consolidacao) |
| 07 - Startup Automatico | `test_scheduled_task_dry_run.ps1` (dry-run e bloqueio por token; **nao** cobre logoff/logon real, ver limitacoes) |
| 08 - Uninstall | `test_scheduled_task_dry_run.ps1` (dry-run e bloqueio por token; **nao** cobre remocao real, ver limitacoes) |

## Riscos e limitacoes conhecidas

- Os Cenarios 07 e 08 do roteiro oficial pedem validar a tarefa agendada real (criar,
  disparar por logon, remover). Por decisao de seguranca deste bloco, nenhum teste
  automatizado cria a tarefa agendada real `WindowsMaintenanceTerminalGrid` nem o lock
  file real em `%LOCALAPPDATA%`; esses dois cenarios ficam cobertos apenas pelo
  caminho dry-run e pelo bloqueio por token invalido, nunca pela criacao real. Validacao
  manual da criacao/remocao real e do disparo por logon continua pendente e deve ser
  feita manualmente, fora desta suite, quando autorizado explicitamente.
- `launcher_maintenance_real.ps1` nao e invocado como script em nenhum teste (criaria o
  lock real sem `-Path` customizado); a cobertura desse arquivo se limita as funcoes de
  gate chamadas isoladamente (`Test-MaintenanceRealGates`, `Test-MaintenanceConfigurationSafety`,
  `New-MaintenanceExecutionPlan`, `Invoke-CommandWithLog`).
- `launcher_startup_safe.ps1` nao tem um caminho seguro de execucao ponta-a-ponta sem
  abrir janelas reais; sua cobertura combina checagem estatica de conteudo com chamadas
  diretas as funcoes auxiliares de `startup_common.ps1`.
- A suite depende de Windows PowerShell 5.1 (`powershell.exe`); no ambiente usado para
  esta validacao, `pwsh` (PowerShell 7+) nao estava disponivel.

## Confirmacao de seguranca

Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, modo real, startup automático real durante validação, alteração de registro, autoelevação ou comando administrativo foi rodado neste bloco.

Confirmado adicionalmente apos a execucao completa da suite:

- `Get-ScheduledTask -TaskName 'WindowsMaintenanceTerminalGrid'` retornou vazio (tarefa
  inexistente) antes e depois da execucao.
- `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock` nao existe.
- Nenhum processo `dism`, `sfc`, `chkdsk` ou `defrag` foi encontrado em execucao apos a
  suite.
- `logs/` nao contem nenhuma pasta `_tests_tmp_*` remanescente (todas removidas em
  bloco `finally` pelos proprios testes).
- `git diff` em `config/terminals.json`, `config/visual_settings.json` e
  `config/schedule_settings.json` esta vazio.

## Criterios de aceite

- Todos os 9 testes da suite passaram na execucao final (199 checagens, 0 erros).
- Os 8 cenarios do roteiro oficial (`fluxo_de_testes.md`) tem cobertura automatizada
  identificada, com as duas exclusoes de seguranca documentadas explicitamente
  (criacao real de tarefa agendada e disparo por logon).
- Nenhum comando de manutencao real, alteracao de registro, autoelevacao ou
  criacao/remocao real de tarefa agendada foi executado durante a validacao.
- O unico problema encontrado durante a validacao (falso positivo do scanner de
  seguranca) foi diagnosticado, corrigido e re-validado com uma segunda execucao
  completa da suite.
