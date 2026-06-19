# Como Remover

## Objetivo

Explicar como remover a tarefa agendada `WindowsMaintenanceTerminalGrid`
criada por `install.ps1`, usando o codigo real implementado (Bloco 08).

## Contexto

A remocao e idempotente: se a tarefa nao existir, o comando retorna um
status `not_found` sem erro. Ela nunca apaga logs, configuracao ou a pasta
do projeto — apenas a entrada no Agendador de Tarefas do Windows.

## Comando

```powershell
# Dry-run (recomendado primeiro) - nao remove nada
powershell.exe -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1
```

```powershell
# Remocao real
powershell.exe -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1 -Apply -ConfirmationToken I_ACCEPT_REMOVE_STARTUP_SAFE_TASK
```

### Parametros aceitos

| Parametro | Tipo | Efeito |
| --- | --- | --- |
| `-DryRun` | switch | Forca simulacao mesmo se `-Apply` for passado. |
| `-Apply` | switch | Necessario para tentar a remocao real (junto com o token). |
| `-ConfirmationToken` | string | Deve ser exatamente `I_ACCEPT_REMOVE_STARTUP_SAFE_TASK` para remover a tarefa real. |

## O que o comando faz

1. Le `config/schedule_settings.json` para confirmar o nome esperado da
   tarefa (`WindowsMaintenanceTerminalGrid`). Se o nome configurado for
   diferente do esperado, a remocao e bloqueada por seguranca.
2. Verifica se a tarefa existe (`Get-ScheduledTask -ErrorAction SilentlyContinue`).
3. Se for dry-run (sem `-Apply`, ou com `-DryRun`), retorna
   `Action = 'dry_run_remove'` com o status `Exists` atual, sem remover
   nada.
4. Se for `-Apply` sem o token correto, lanca excecao **antes** de chamar
   `Unregister-ScheduledTask`.
5. Se for `-Apply` com o token correto e a tarefa nao existir, retorna
   `Action = 'not_found'` (sem erro — comando pode ser repetido livremente).
6. Se for `-Apply` com o token correto e a tarefa existir, remove com
   `Unregister-ScheduledTask -Confirm:$false` e retorna `Action = 'removed'`.

## Decisoes Tecnicas

- `uninstall.ps1` (raiz) e um wrapper fino que repassa os parametros a
  `scripts/startup/remove_scheduled_task.ps1`.
- A remocao tolera tarefa ausente (idempotente) — pode ser chamada mais de
  uma vez sem efeito adicional.
- Lock file obsoleto (`%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock`)
  nao e removido por este comando; ele e tratado separadamente pelos
  proprios launchers (ver
  [logs_lock_summary.md](logs_lock_summary.md)).

## Regras

- Nao apaga a pasta do projeto.
- Nao apaga logs (`logs/`) nem resultados de teste (`tests/results/`).
- Nao altera nenhuma outra configuracao do Windows ou do Windows Terminal.

## Arquivos Relacionados

- `uninstall.ps1`, `scripts/startup/remove_scheduled_task.ps1`
- `Docs/05_blocos_implementacao/bloco_08_tarefa_agendada_windows.md`
- `Docs/06_scripts_funcoes/funcoes_startup.md`
- [como_instalar.md](como_instalar.md), [troubleshooting.md](troubleshooting.md)

## Riscos

- Falta de permissao para remover a tarefa na conta atual.
- Se o nome da tarefa em `config/schedule_settings.json` for alterado
  manualmente para um valor diferente de `WindowsMaintenanceTerminalGrid`,
  a remocao e bloqueada (protecao deliberada contra remover a tarefa
  errada).

## Criterios de Aceite

- Sem `-Apply` (ou com `-DryRun`), nenhuma tarefa e removida.
- Com `-Apply` e token invalido ou ausente, a remocao e bloqueada antes de
  `Unregister-ScheduledTask`.
- Com `-Apply -ConfirmationToken I_ACCEPT_REMOVE_STARTUP_SAFE_TASK`, a
  tarefa e removida se existir, ou retorna `not_found` se nao existir —
  nos dois casos, sem erro.
- O comando pode ser executado repetidamente sem efeito colateral.
