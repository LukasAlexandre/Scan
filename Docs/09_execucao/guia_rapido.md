# Guia Rapido

## Objetivo

Caminho mais curto para validar, testar e (opcionalmente) instalar o
projeto, na ordem recomendada. Para detalhes de cada passo, siga os links.

## Pre-requisitos

- Windows 10/11.
- Windows PowerShell 5.1 (incluso no Windows) ou superior. A validacao
  local deste projeto foi feita em PowerShell 5.1; `pwsh` (7+) nao foi
  testado neste ambiente.
- Windows Terminal (`wt.exe`) recomendado, mas nao obrigatorio — sem ele,
  o sistema usa um fallback de janelas separadas automaticamente.
- Administrador, somente se for usar o modo `maintenance_real` real.

## Passo 1 — Validar o projeto localmente

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\run_all_safe_tests.ps1
```

Espera-se `9/9 testes PASS` (ultimo resultado registrado: 199 checagens, 0
erros). Detalhes em [validacao_local.md](validacao_local.md).

## Passo 2 — Testar o modo seguro manualmente

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\startup\launcher_startup_safe.ps1 -DryRun
```

Abre os 4 terminais com banners e checks leves, sem nenhum comando real.
Detalhes em [como_rodar_startup_safe.md](como_rodar_startup_safe.md).

## Passo 3 (opcional) — Instalar a tarefa agendada de login

```powershell
# Simular primeiro
powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1

# Instalar de fato
powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Apply -ConfirmationToken I_ACCEPT_STARTUP_SAFE_TASK
```

A tarefa criada sempre aponta para o modo seguro em dry-run — nunca para
manutencao real. Detalhes em [como_instalar.md](como_instalar.md).

## Passo 4 (opcional, com cautela) — Rodar manutencao real

```powershell
# Simular primeiro, sempre
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\launchers\launcher_maintenance_real.ps1 -DryRun
```

Leia [comandos_seguros.md](comandos_seguros.md) e
[como_rodar_maintenance_real.md](como_rodar_maintenance_real.md)
**antes** de adicionar `-RunReal -AllowSessionRealMaintenance
-ConfirmationToken I_ACCEPT_WINDOWS_MAINTENANCE`. Requer administrador.

## Passo 5 (se necessario) — Remover a tarefa agendada

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1 -Apply -ConfirmationToken I_ACCEPT_REMOVE_STARTUP_SAFE_TASK
```

Detalhes em [como_remover.md](como_remover.md).

## Se algo der errado

Veja [troubleshooting.md](troubleshooting.md) e
[logs_lock_summary.md](logs_lock_summary.md) para interpretar logs, lock
file e summaries.

## Mapa dos modos

Veja [modos_de_operacao.md](modos_de_operacao.md) para a diferenca exata
entre `startup_safe`, dry-run e `maintenance_real`.
