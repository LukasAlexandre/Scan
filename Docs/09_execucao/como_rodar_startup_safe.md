# Como Rodar Startup Safe

## Objetivo

Orientar a execucao manual do modo seguro (`startup_safe`), usando o codigo
real implementado (Blocos 05, 06 e 09).

## Contexto

`startup_safe` e o modo recomendado para validacao visual e para uso
automatico no login (via tarefa agendada, ver
[como_instalar.md](como_instalar.md)). Ele nunca executa manutencao
pesada: `launcher_startup_safe.ps1` sempre repassa `-DryRun` ao chamar o
launcher de grid, e o proprio `launcher_grid_2x2.ps1` cria seu contexto
com `DryRun` fixo em `$true`, independentemente do switch recebido. Ou
seja, nesta camada, comandos reais sao estruturalmente impossiveis.

## Comando

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\startup\launcher_startup_safe.ps1 -DryRun
```

Se `-DryRun` for omitido, o script ainda assim forca dry-run ao chamar o
launcher de grid — apenas registra um aviso (`WARN`) no log avisando que o
switch nao foi informado.

### Parametros aceitos

| Parametro | Tipo | Efeito |
| --- | --- | --- |
| `-DryRun` | switch | Documenta a intencao explicita de dry-run (sempre aplicado de qualquer forma). |
| `-UseFallback` | switch | Usa o fallback de janelas do Windows em vez de `wt.exe` (repassado ao launcher de grid). |
| `-NoPause` | switch | Nao pausa os terminais ao final da execucao (repassado ao launcher de grid). |
| `-DelaySeconds` | int | Sobrescreve o delay de login. `-1` (padrao) usa `config/schedule_settings.json` -> `startup.delaySeconds`; valor e limitado a 300s. |

## Comando Alternativo: apenas consolidar summaries (sem abrir terminais)

Util para validar logs/summary sem abrir nenhuma janela:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\launchers\launcher_grid_2x2.ps1 -Mode startup_safe -ConsolidateSummaries
```

## O que acontece, na ordem real

1. Carrega `config/terminals.json`, `config/visual_settings.json` e
   `config/schedule_settings.json`.
2. Valida a configuracao (`Test-StartupSafeConfiguration`) — bloqueia se
   `startup.mode` nao for `startup_safe`, se qualquer flag de comando
   pesado estiver `true`, ou se `startup.enabled`/`scheduledTask.autoCreate`
   estiverem `true` fora do bloco de agendamento.
3. Cria o lock file (`%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock`),
   modo `startup_safe`, expira em 30 minutos.
4. Aguarda o delay de login (padrao 20s, configuravel, maximo 300s).
5. Chama `scripts/launchers/launcher_grid_2x2.ps1` com `-DryRun` (sempre).
6. O launcher de grid abre os quatro terminais (ou usa o fallback de
   janelas se `wt.exe` nao estiver disponivel ou `-UseFallback` for
   passado), cada um exibindo banner, loading e status leve — nenhum
   exibe execucao real de comando.
7. Libera o lock file no bloco `finally`, somente se ainda pertencer ao
   mesmo PID que o criou.

## Decisoes Tecnicas

- Modo seguro e o default operacional e o unico caminho que a tarefa
  agendada pode acionar.
- Comandos pesados sao bloqueados em duas camadas independentes: a
  validacao de configuracao (`Test-StartupSafeConfiguration`) e o
  `DryRun=$true` hardcoded em `New-LauncherContext` dentro do launcher de
  grid.
- O launcher de grid abre os terminais como processos destacados e **nao
  espera a conclusao deles** — `-ConsolidateSummaries` precisa ser chamado
  separadamente depois que os terminais terminarem, se for necessario um
  `summary.json` consolidado fora do fluxo interativo.

## Regras

- Nao executa DISM.
- Nao executa SFC.
- Nao executa `chkdsk C: /r` nem `chkdsk C: /scan`.
- Nao executa `defrag C: /O /U /V`.

## Arquivos Relacionados

- `scripts/startup/launcher_startup_safe.ps1`,
  `scripts/startup/startup_common.ps1`,
  `scripts/launchers/launcher_grid_2x2.ps1`
- `Docs/05_blocos_implementacao/bloco_06_modo_startup_safe.md`
- `Docs/08_testes/testes_modo_startup_safe.md`
- [modos_de_operacao.md](modos_de_operacao.md), [logs_lock_summary.md](logs_lock_summary.md)

## Riscos

- Lock antigo (de execucao anterior travada) pode bloquear a abertura;
  resolvido automaticamente se o processo dono estiver morto ou o lock
  estiver expirado, senao exige limpeza manual (ver
  [troubleshooting.md](troubleshooting.md)).
- Windows Terminal ausente aciona o fallback de janelas automaticamente.
- O delay configurado pode parecer travamento se o usuario nao souber que
  e esperado — o log de `STARTUP` registra a duracao escolhida e a origem
  (`parameter`/`config`/`fallback`).

## Criterios de Aceite

- Grid abre (via `wt.exe` ou fallback).
- Logs e lock file sao criados em `logs/<RunId>/` e
  `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock`.
- Nenhum comando pesado e executado, independentemente dos parametros
  informados.
