# Troubleshooting

## Objetivo

Listar problemas comuns e a resposta recomendada, com base no
comportamento real implementado (Blocos 02-10).

## Contexto

O projeto usa PowerShell, Windows Terminal (opcional), tarefa agendada e
comandos administrativos. Falhas de permissao e de ambiente sao esperadas
em algumas maquinas. A primeira fonte de diagnostico deve ser sempre
`logs/<RunId>/execution_events.ndjson` e os `.log` por origem.

## Problemas e Solucoes

| Problema | Causa provavel | Acao recomendada |
| --- | --- | --- |
| Script bloqueado pela politica de execucao | Execution Policy do PowerShell | Use `-ExecutionPolicy Bypass` exatamente como nos exemplos de `Docs/09_execucao/` (afeta apenas o processo atual, nao altera a politica do sistema). |
| Grid nao abre / abre em janelas separadas em vez de 2x2 | `wt.exe` ausente do PATH, ou `-UseFallback` foi passado | Verifique `wt.exe` no PATH; se ausente, o fallback de janelas (`launcher_fallback_windows.ps1`) e esperado, nao um erro. Revise o log do launcher em `logs/<RunId>/launcher.log`. |
| Grid abre com fonte grande em um ou mais panes | Zoom de sessao nao foi aplicado em todos os panes, ou `sessionZoomOutSteps` esta 0 | Revise `config/visual_settings.json` (`terminalApp.sessionZoomOutSteps`) e o log do launcher. O ajuste percorre os quatro panes e simula `Ctrl+Minus` em cada um, sem alterar configuracoes globais do Terminal. |
| Modo real nao inicia | PowerShell sem administrador, falta `-AllowSessionRealMaintenance`, ou token incorreto | Confira as 3 condicoes em [como_rodar_maintenance_real.md](como_rodar_maintenance_real.md): admin, flag de sessao, `-ConfirmationToken I_ACCEPT_WINDOWS_MAINTENANCE`. A excecao lancada nomeia exatamente qual violacao ocorreu. |
| Instalacao/remocao da tarefa nao faz nada | Faltou `-Apply` ou o `-ConfirmationToken` exato | Sem `-Apply` o comportamento e dry-run por padrao (proposital). Confira o token exato: `I_ACCEPT_STARTUP_SAFE_TASK` (instalar) ou `I_ACCEPT_REMOVE_STARTUP_SAFE_TASK` (remover). |
| Terminal fecha rapido | `keepTerminalOpenAfterFinish` falso em `config/terminals.json`, ou erro nao tratado no script do terminal | Revise `config/terminals.json` e o log do terminal em `logs/<RunId>/terminals/<terminal>.log`. |
| Startup automatico nao aparece no logon | Tarefa nao instalada, ou `install.ps1` rodou sem `-Apply`/token | Confirme com `Get-ScheduledTask -TaskName WindowsMaintenanceTerminalGrid`. Se ausente, repita a instalacao real (ver [como_instalar.md](como_instalar.md)). |
| Segunda execucao bloqueada ("Active lock file already exists...") | Lock file ativo de outro processo, ou de uma execucao anterior que nao saiu pelo caminho normal | Veja [logs_lock_summary.md](logs_lock_summary.md). So remova `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock` manualmente depois de confirmar que o PID gravado no arquivo nao esta mais ativo (`Get-Process -Id <pid>`). |
| Sem logs gerados | Caminho de `logs/` invalido, ou script executado fora da raiz do projeto | Confirme que `config/` e `scripts/common/common.ps1` existem a partir do diretorio de execucao — e o criterio usado por `Resolve-*ProjectRoot` para localizar a raiz. |
| CHKDSK profundo (`chkdsk C: /r`) nao roda mesmo com `-IncludeDeepDiskRepair` | Comportamento esperado: bloqueado estruturalmente no codigo atual | Nao e um bug — ver [comandos_seguros.md](comandos_seguros.md). Nao tente contornar editando `maintenance_real_common.ps1` sem registrar a decisao em um novo bloco/feedback. |
| `tests/run_all_safe_tests.ps1` falha em algum teste | Regressao real, ou ambiente sem `pwsh`/com permissoes diferentes | Rode `powershell.exe -NoProfile -File tests\run_all_safe_tests.ps1`, leia `tests/results/<timestamp>/test_report.md` e o `.console.log` do teste especifico. |

## Decisoes Tecnicas

- Logs (`execution_events.ndjson`, `.log` por origem, `summaries/*.json`,
  `summary.json`) sao a primeira fonte de diagnostico, antes de qualquer
  alteracao manual.
- Fallback sem Windows Terminal e degradacao esperada, nao falha total —
  os mesmos comandos seguros se aplicam.
- Um lock antigo so deve ser removido manualmente depois de validar que o
  PID gravado nao esta mais ativo; `New-LockFile`/`Assert-NoActiveLock` ja
  fazem essa verificacao automaticamente em toda nova execucao
  (`Clear-StaleLockFile` remove sozinho se o processo estiver morto ou o
  lock estiver expirado).

## Regras

- Nao tente resolver falhas executando comandos pesados manualmente sem
  entender a causa raiz.
- Nao apague o lock file enquanto o processo dono (`Pid` no JSON do lock)
  ainda estiver ativo.
- Nao altere o Agendador de Tarefas do Windows manualmente para
  `WindowsMaintenanceTerminalGrid` — use `install.ps1`/`uninstall.ps1` para
  manter o estado consistente com `config/schedule_settings.json`.

## Arquivos Relacionados

- `Docs/03_arquitetura/estrategia_de_logs.md`
- `Docs/05_blocos_implementacao/bloco_09_logs_lockfile_summary.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`
- [logs_lock_summary.md](logs_lock_summary.md), [validacao_local.md](validacao_local.md)

## Riscos

- Limpar o lock incorretamente (com o processo dono ainda ativo) pode
  permitir execucao duplicada.
- Forcar administrador sem explicar ao usuario por que e necessario.
- Confundir uma falha puramente visual (ex.: `wt.exe` ausente) com uma
  falha de manutencao real — sao camadas independentes no codigo.

## Criterios de Aceite

- Cada problema comum listado tem causa provavel e acao recomendada.
- Nenhuma solucao recomendada contorna um gate de seguranca (token,
  administrador, lock) — sempre orienta a usar o caminho oficial.
