# Como Rodar Maintenance Real

## Objetivo

Orientar a execucao do modo de manutencao real sob demanda, usando o
codigo real implementado (Blocos 07 e 09).

## Contexto

> **Atencao:** este modo pode executar comandos reais que alteram ou
> verificam o estado do Windows (DISM, SFC, CHKDSK, defrag). DISM e SFC
> podem levar de minutos a horas dependendo da maquina; defrag aumenta o
> uso de disco durante a execucao. Use sempre o dry-run primeiro e execute
> o modo real apenas quando tiver tempo e contexto para acompanhar.

Este modo nunca e acionado pela tarefa agendada de login — apenas por
execucao manual direta deste script.

## Comando Dry-Run (recomendado primeiro)

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\launchers\launcher_maintenance_real.ps1 -DryRun
```

## Comando Real

Requer PowerShell **elevado (administrador)**, a flag de sessao
`-AllowSessionRealMaintenance` e o token de confirmacao
`I_ACCEPT_WINDOWS_MAINTENANCE`. Faltando qualquer um dos tres, a execucao e
bloqueada antes de qualquer comando real:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\launchers\launcher_maintenance_real.ps1 -RunReal -AllowSessionRealMaintenance -ConfirmationToken I_ACCEPT_WINDOWS_MAINTENANCE
```

### Parametros aceitos

| Parametro | Tipo | Efeito |
| --- | --- | --- |
| `-DryRun` | switch | Forca simulacao mesmo se `-RunReal` for passado. |
| `-RunReal` | switch | Necessario (junto com os dois itens abaixo) para tentar execucao real. |
| `-ConfirmationToken` | string | Deve ser exatamente `I_ACCEPT_WINDOWS_MAINTENANCE` para execucao real. |
| `-AllowSessionRealMaintenance` | switch | Confirmacao explicita de sessao, exigida junto com o token. |
| `-IncludeDiskScan` | switch | Inclui `chkdsk C: /scan` (verificacao online, sem reparo) no plano. Sem essa flag, a etapa e pulada (`skipped_not_requested`). |
| `-IncludeDeepDiskRepair` | switch | **Nao tem efeito.** O reparo profundo (`chkdsk C: /r`) esta bloqueado no codigo atual independentemente desta flag — ver abaixo. |
| `-UseFallback` | switch | Aceito por simetria de interface; o modo real usa uma fila sequencial controlada, nao janelas de fallback. |
| `-NoPause` | switch | Aceito; a fila controlada nao pausa interativamente. |

A execucao e bloqueada (excecao lancada **antes** de qualquer comando real)
se: faltar `-RunReal`, faltar administrador, faltar
`-AllowSessionRealMaintenance`, ou o token estiver incorreto/ausente.

## Plano de execucao (ordem real, `New-MaintenanceExecutionPlan`)

| # | Terminal | Comando | Condicao |
| --- | --- | --- | --- |
| 1 | ANALYTICS | `DISM /Online /Cleanup-Image /RestoreHealth` | sempre, se gates aprovados |
| 2 | SCANNING | `sfc /scannow` | sempre, se gates aprovados |
| 3 | PROCESSING | `chkdsk C: /scan` | somente com `-IncludeDiskScan` |
| 4 | CLEANING | `defrag C: /O /U /V` | sempre, se gates aprovados |
| 5 | PROCESSING (deep) | `chkdsk C: /r` | **sempre bloqueado** (`blocked_deep_disk_repair`), com ou sem `-IncludeDeepDiskRepair` |

A etapa 5 esta marcada `Enabled:$false` diretamente no codigo de
`New-MaintenanceExecutionPlan` — nao e apenas um padrao de configuracao,
e uma trava estrutural deste estagio de implementacao. Detalhes do risco
de cada comando em [comandos_seguros.md](comandos_seguros.md).

## O que acontece, na ordem real

1. Cria o lock file (`maintenance_real`, expira em 180 minutos).
2. Valida a configuracao (`Test-MaintenanceConfigurationSafety`) — bloqueia
   se `startup.enabled`, `scheduledTask.autoCreate`,
   `startup.allowHeavyCommandsOnStartup` ou `allowStartupHeavyCommands`
   estiverem `true`.
3. Se `-RunReal` e nao `-DryRun`: verifica administrador
   (`Test-IsAdmin`).
4. Avalia os gates (`Test-MaintenanceRealGates`): admin, flag de sessao e
   token. Se nao aprovados, registra cada violacao, grava o
   `summary.json` consolidado com status `blocked_gate` e lanca excecao —
   **nenhum comando real e executado**.
5. Monta o plano de 5 etapas (tabela acima).
6. Se efetivamente dry-run, cada etapa habilitada roda via
   `Invoke-DryRunCommand` (apenas log, nenhum processo real). Se
   efetivamente real, roda via `Invoke-CommandWithLog`, restrito a
   `DISM`, `sfc`, `chkdsk`, `defrag` (`-AllowedExecutables`) e exigindo o
   mesmo token de confirmacao novamente nesta camada.
7. Grava o `summary.json` consolidado e libera o lock file.

## Decisoes Tecnicas

- Dry-run deve ser validado antes do modo real.
- Execucao real e sequencial (fila controlada), nunca paralela.
- `chkdsk C: /r` permanece bloqueado nesta fase — quando uma futura
  liberacao for implementada, a confirmacao tera de ser tratada com o
  mesmo rigor dos outros tokens (nunca automatica).
- O summary final registra status por etapa (`completed`, `skipped_not_requested`,
  `blocked_deep_disk_repair`, `blocked_gate`, etc.), nunca apenas "sucesso".

## Regras

- Nao roda no login (sem caminho de codigo conecta a tarefa agendada a
  este script).
- Nao roda comandos pesados em paralelo.
- Nao libera CHKDSK profundo automaticamente — esta bloqueado no codigo.
- Nao esconde falhas: cada etapa registra `exitCode` e `error` no summary.

## Arquivos Relacionados

- `scripts/launchers/launcher_maintenance_real.ps1`,
  `scripts/launchers/maintenance_real_common.ps1`
- `Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md`
- `Docs/02_requisitos/matriz_de_comandos.md`
- `Docs/08_testes/testes_modo_maintenance_real.md`
- [comandos_seguros.md](comandos_seguros.md), [modos_de_operacao.md](modos_de_operacao.md), [logs_lock_summary.md](logs_lock_summary.md)

## Riscos

- Processo demorado (DISM/SFC podem levar minutos a horas).
- Pode exigir reinicializacao dependendo do estado do Windows.
- Alto uso de disco/CPU durante defrag.
- Falha por ausencia de permissao administrativa interrompe antes de
  qualquer comando.

## Criterios de Aceite

- Sem administrador, a execucao real nao ocorre.
- Com dry-run, todas as etapas habilitadas sao simuladas com log, sem
  processo real.
- Com execucao real aprovada, cada etapa registra saida e `exitCode` no
  summary.
- CHKDSK profundo nunca executa, independentemente dos parametros.
