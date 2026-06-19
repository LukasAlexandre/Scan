# Como Instalar

## Objetivo

Explicar como instalar a tarefa agendada do Windows que abre o modo
`startup_safe` no logon, usando o codigo real implementado (Blocos 06 e 08).

## Contexto

A instalacao cria a tarefa agendada `WindowsMaintenanceTerminalGrid`, que
roda em `AtLogon`, sessao interativa (`LogonType=Interactive`), com
privilegio limitado (`RunLevel=Limited`). A acao da tarefa **sempre** chama
`scripts/startup/launcher_startup_safe.ps1` com `-DryRun` — nao existe
caminho de codigo que agende `launcher_maintenance_real.ps1`.

## Comando

Sem `-Apply`, ou sem o token correto, `install.ps1` apenas simula a
instalacao e nao cria nada:

```powershell
# Dry-run (recomendado primeiro) - nao cria a tarefa
powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1
```

```powershell
# Instalacao real
powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Apply -ConfirmationToken I_ACCEPT_STARTUP_SAFE_TASK
```

### Parametros aceitos

| Parametro | Tipo | Efeito |
| --- | --- | --- |
| `-DryRun` | switch | Forca simulacao mesmo se `-Apply` for passado. |
| `-Apply` | switch | Necessario para tentar a criacao real (junto com o token). |
| `-ConfirmationToken` | string | Deve ser exatamente `I_ACCEPT_STARTUP_SAFE_TASK` para criar a tarefa real. |
| `-UseFallback` | switch | Inclui `-UseFallback` na acao agendada, fazendo o `startup_safe` usar o fallback de janelas do Windows em vez de `wt.exe` quando a tarefa rodar no logon. |
| `-NoPause` | switch | Inclui `-NoPause` na acao agendada (nao pausa o terminal ao final). |

`-Apply` sozinho, sem `-ConfirmationToken` correto, lanca excecao **antes**
de chamar `Register-ScheduledTask` — nada e criado.

## O que o comando faz

1. Resolve a raiz do projeto e carrega `config/terminals.json` e
   `config/schedule_settings.json`.
2. Monta o plano da tarefa (`New-StartupScheduledTaskPlan`): nome
   `WindowsMaintenanceTerminalGrid`, alvo
   `scripts/startup/launcher_startup_safe.ps1`, acao
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <caminho> -DryRun [-UseFallback] [-NoPause]`,
   delay de login (`config/schedule_settings.json` -> `startup.delaySeconds`,
   padrao 20s, maximo 300s), `RunLevel=Limited`, `LogonType=Interactive`.
3. Valida o plano (`Test-StartupScheduledTaskPlan`) — bloqueia se o modo de
   startup nao for `startup_safe`, se qualquer flag de comando pesado
   estiver `true`, se o nome da tarefa for diferente do esperado, se o alvo
   nao for `launcher_startup_safe.ps1`, se a acao nao contiver `-DryRun`,
   se o alvo/argumentos contiverem `maintenance_real`, ou se `RunLevel`/`LogonType`
   nao forem `Limited`/`Interactive`. Qualquer violacao lanca excecao antes
   de qualquer chamada ao Task Scheduler.
4. Se for dry-run (sem `-Apply`, ou com `-DryRun`), registra um aviso no log
   e retorna um objeto `Action = 'dry_run_create'` sem tocar no sistema.
5. Se for `-Apply` com o token correto, cria a tarefa com
   `Register-ScheduledTask` e retorna `Action = 'created'`.

## Decisoes Tecnicas

- `install.ps1` (raiz) e um wrapper fino que apenas repassa os parametros a
  `scripts/startup/create_scheduled_task.ps1`.
- A instalacao e reversivel por `uninstall.ps1` (ver
  [como_remover.md](como_remover.md)).
- O delay de login vem de `config/schedule_settings.json`
  (`startup.delaySeconds`); pode ser sobrescrito apenas internamente (o
  comando de instalacao nao expoe um parametro de delay customizado).

## Regras

- Nunca agendar `launcher_maintenance_real.ps1` — bloqueado estruturalmente
  por `Test-StartupScheduledTaskPlan`.
- Nenhum comando DISM, SFC, CHKDSK ou defrag e executado durante a
  instalacao (a tarefa apenas e registrada; o script alvo so roda no logon,
  e mesmo ai roda em dry-run).
- Se a politica de execucao do PowerShell bloquear o script, use
  `-ExecutionPolicy Bypass` exatamente como nos exemplos acima (ela nao
  altera a politica do sistema, apenas a do processo atual).

## Arquivos Relacionados

- `install.ps1`, `scripts/startup/create_scheduled_task.ps1`,
  `scripts/startup/startup_common.ps1`
- `Docs/05_blocos_implementacao/bloco_08_tarefa_agendada_windows.md`
- `Docs/07_configuracoes/scheduled_task_config.md`
- [como_remover.md](como_remover.md), [modos_de_operacao.md](modos_de_operacao.md)

## Riscos

- Politica de execucao do PowerShell pode impedir o script (resolvido com
  `-ExecutionPolicy Bypass`, escopo do processo, sem alterar o sistema).
- Falta de permissao para criar tarefa agendada na conta atual.
- Digitar o token de confirmacao incorretamente apenas bloqueia a criacao
  (lanca excecao) — nao ha risco de criacao parcial.

## Criterios de Aceite

- Sem `-Apply` (ou com `-DryRun`), nenhuma tarefa e criada.
- Com `-Apply` e token invalido ou ausente, a criacao e bloqueada antes de
  `Register-ScheduledTask`.
- Com `-Apply -ConfirmationToken I_ACCEPT_STARTUP_SAFE_TASK`, a tarefa
  `WindowsMaintenanceTerminalGrid` e criada apontando para
  `launcher_startup_safe.ps1 -DryRun`, com `RunLevel=Limited` e
  `LogonType=Interactive`.
- A instalacao real e a unica validada automaticamente por
  `tests/test_scheduled_task_dry_run.ps1`; a validacao manual do disparo
  real por logon continua pendente (ver
  [Docs/10_feedback/feedback_bloco_10_testes_validacao_local.md](../10_feedback/feedback_bloco_10_testes_validacao_local.md)).
