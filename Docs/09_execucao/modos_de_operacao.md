# Modos de Operacao

## Objetivo

Explicar, com base no codigo real (Blocos 05-09), a diferenca pratica
entre `startup_safe`, dry-run e `maintenance_real`. Complementa
`Docs/03_arquitetura/modos_de_operacao.md` (visao arquitetural) com o
comportamento real observado nos scripts.

## Os tres conceitos, sem confundir

Estes nao sao tres modos paralelos — sao duas dimensoes que se cruzam:

1. **Modo** (`startup_safe` ou `maintenance_real`): qual launcher e qual
   conjunto de regras de seguranca se aplicam.
2. **Dry-run vs. real**: se os comandos sao apenas simulados/logados
   (`Invoke-DryRunCommand`) ou efetivamente executados
   (`Invoke-CommandWithLog`).

`startup_safe` **so existe em dry-run** — nao ha combinacao de parametros
que faca o modo seguro executar um comando real. `maintenance_real` pode
rodar em dry-run (recomendado, default) ou em modo real (somente com todos
os gates aprovados).

## `startup_safe`

- Script: `scripts/startup/launcher_startup_safe.ps1`.
- Quem aciona: execucao manual, ou a tarefa agendada `WindowsMaintenanceTerminalGrid`
  criada por `install.ps1` (trigger `AtLogon`).
- Comportamento real: sempre repassa `-DryRun` ao chamar
  `launcher_grid_2x2.ps1`. Mesmo que `-DryRun` seja omitido no comando,
  apenas um aviso (`WARN`) e logado — o comportamento nao muda.
- Camada extra de seguranca: `launcher_grid_2x2.ps1` cria seu contexto com
  `New-LauncherContext ... -DryRun $true` **hardcoded**, independente do
  switch recebido. Ou seja, mesmo um bug em `launcher_startup_safe.ps1`
  que deixasse de passar `-DryRun` nao seria suficiente para rodar
  comandos reais nesta camada.
- Comandos pesados (DISM/SFC/CHKDSK/defrag): nunca executados.
- Validacao de configuracao (`Test-StartupSafeConfiguration`): bloqueia se
  `startup.mode` nao for `startup_safe`, ou se qualquer flag de comando
  pesado (`allowStartupHeavyCommands`, `startup.allowHeavyCommandsOnStartup`,
  `allowRealMaintenance`) estiver `true`, ou se `startup.enabled`/
  `scheduledTask.autoCreate` estiverem `true` fora do fluxo de
  agendamento.
- Lock file: modo `startup_safe`, expira em 30 minutos.

## `visual_only` / dry-run de validacao

- Nao e um script separado — e o resultado de rodar qualquer launcher sem
  aprovar os gates reais, ou de chamar
  `launcher_grid_2x2.ps1 -ConsolidateSummaries` (que nem chega a abrir
  terminais, apenas consolida summaries existentes).
- Usado pela suite de testes (`tests/`) e para validar logs/summary sem
  efeitos colaterais visiveis.

## `maintenance_real`

- Script: `scripts/launchers/launcher_maintenance_real.ps1`.
- Quem aciona: **somente execucao manual direta.** Nao existe tarefa
  agendada, gatilho de login ou qualquer outro caminho automatico que
  chame este script — `tests/test_security_static_scan.ps1` verifica
  estaticamente que nenhum script de `scripts/startup/` referencia
  `launcher_maintenance_real.ps1`.
- Dry-run (default, sem `-RunReal` ou com `-DryRun`): cada etapa do plano
  roda via `Invoke-DryRunCommand` — apenas log, nenhum processo real
  iniciado.
- Modo real (`-RunReal` sem `-DryRun`, com todos os gates aprovados): cada
  etapa habilitada roda via `Invoke-CommandWithLog`, restrito a
  `DISM`/`sfc`/`chkdsk`/`defrag`.
- Gates exigidos para modo real (`Test-MaintenanceRealGates`):
  administrador (`Test-IsAdmin`), `-AllowSessionRealMaintenance`, e
  `-ConfirmationToken I_ACCEPT_WINDOWS_MAINTENANCE`. Falta qualquer um —
  excecao lancada antes de qualquer comando.
- `chkdsk C: /r` (reparo profundo): bloqueado estruturalmente, em qualquer
  combinacao de parametros (ver [comandos_seguros.md](comandos_seguros.md)).
- Lock file: modo `maintenance_real`, expira em 180 minutos (mais longo,
  pois DISM/SFC podem demorar).

## Tabela resumo

| Aspecto | `startup_safe` | `maintenance_real` (dry-run) | `maintenance_real` (real) |
| --- | --- | --- | --- |
| Acionamento | Manual ou tarefa agendada (logon) | Manual | Manual |
| Requer admin | Nao | Nao | Sim |
| Requer token | Nao (instalar a tarefa exige token separado) | Nao | Sim — `I_ACCEPT_WINDOWS_MAINTENANCE` |
| Executa DISM/SFC/CHKDSK/defrag | Nunca | Nunca (apenas log) | Sim, exceto CHKDSK profundo (sempre bloqueado) |
| Expiracao do lock | 30 min | 180 min | 180 min |
| Pode rodar no login | Sim (so este) | Nao | Nao |

## Arquivos Relacionados

- `Docs/03_arquitetura/modos_de_operacao.md`
- [como_rodar_startup_safe.md](como_rodar_startup_safe.md),
  [como_rodar_maintenance_real.md](como_rodar_maintenance_real.md),
  [comandos_seguros.md](comandos_seguros.md)

## Riscos

- Confundir "dry-run do modo real" com "modo seguro" — sao caminhos de
  codigo diferentes, ainda que o efeito observavel (nenhum comando real)
  seja o mesmo.
- Assumir que mudar `config/terminals.json`/`config/schedule_settings.json`
  manualmente seria suficiente para habilitar comandos reais no login —
  as validacoes de codigo (`Test-StartupSafeConfiguration`,
  `Test-StartupScheduledTaskPlan`) bloqueiam isso independentemente do
  JSON.

## Criterios de Aceite

- A diferenca entre os dois modos e a dimensao dry-run/real esta explicita
  e nao se sobrepoe.
- Nenhuma combinacao de parametros documentada aqui permite executar
  comando pesado a partir do modo `startup_safe`.
