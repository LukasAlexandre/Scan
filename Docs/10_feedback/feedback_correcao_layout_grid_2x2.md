# Feedback — Correção Layout Grid 2x2

## Objetivo

Corrigir a montagem dos panes do Windows Terminal em `launcher_grid_2x2.ps1`
para que o grid final seja sempre uma grade real 2x2 — `ANALYTICS` (topo
esquerda), `SCANNING` (topo direita), `PROCESSING` (baixo esquerda),
`CLEANING` (baixo direita) — sem tocar em segurança, dry-run,
`maintenance_real`, `startup_safe` ou tarefa agendada.

## Problema visual identificado

O layout resultante estava assim:

```text
ANALYTICS | PROCESSING | CLEANING
----------------------------------
SCANNING (ocupando toda a largura inferior)
```

Em vez da grade 2x2 esperada:

```text
ANALYTICS  | SCANNING
PROCESSING | CLEANING
```

## Causa técnica

`Build-WindowsTerminalArgumentList` (em `scripts/launchers/launcher_common.ps1`)
usava os terminais por **posição no array** (`$TerminalCommands[1]`,
`$TerminalCommands[2]`, `$TerminalCommands[3]`), e a ordem fixa produzida por
`Get-LauncherTerminalDefinitions` é `analytics, scanning, processing,
cleaning`. Isso fazia o primeiro `split-pane -H` (divisão horizontal = pane
embaixo) usar o terminal de índice 1, que é `scanning`, em vez de
`processing`. O resultado: `SCANNING` virava o pane inferior inteiro (full
width) logo na primeira divisão, e a segunda/terceira divisão só fatiava a
metade superior (`ANALYTICS`) em três colunas (`ANALYTICS`, `PROCESSING`,
`CLEANING`), pois o Windows Terminal sempre divide o pane atualmente
focado — e o foco nunca voltava para o pane inferior antes da última divisão.

## Arquivos analisados

- `scripts/launchers/launcher_grid_2x2.ps1`
- `scripts/launchers/launcher_common.ps1`
- `scripts/launchers/launcher_fallback_windows.ps1`
- `Docs/10_feedback/feedback_fechamento_final_ddad.md`
- `config/terminals.json`
- `tests/test_launchers_dry_run.ps1`

## Arquivos alterados

- `scripts/launchers/launcher_common.ps1` — função
  `Build-WindowsTerminalArgumentList` reescrita para montar os panes por
  `Id` (`analytics`, `scanning`, `processing`, `cleaning`) em vez de por
  posição no array, e com a sequência de `split-pane`/`move-focus` corrigida.
- `tests/test_launchers_dry_run.ps1` — substituído o check que validava
  (incorretamente) a sequência antiga (`move-focus first ; move-focus
  right`) por checks que validam a nova sequência correta e a ordem final
  do grid 2x2.

`launcher_grid_2x2.ps1` e `launcher_fallback_windows.ps1` não precisaram de
nenhuma alteração — o bug estava isolado em
`Build-WindowsTerminalArgumentList`.

## Estratégia anterior

```text
new-tab ANALYTICS
; split-pane -H --size 0.5 SCANNING      (embaixo de ANALYTICS, full width)
; move-focus first                       (volta para ANALYTICS)
; split-pane -V --size 0.5 PROCESSING    (direita de ANALYTICS, só no topo)
; move-focus first ; move-focus right    (vai para PROCESSING)
; split-pane -V --size 0.5 CLEANING      (direita de PROCESSING, só no topo)
```

Resultado: 3 colunas no topo (`ANALYTICS | PROCESSING | CLEANING`) e
`SCANNING` ocupando toda a parte inferior.

## Estratégia nova

```text
new-tab ANALYTICS                         (único pane, foco em ANALYTICS)
; split-pane -H --size 0.5 PROCESSING     (embaixo de ANALYTICS; foco -> PROCESSING)
; move-focus up                           (volta para ANALYTICS)
; split-pane -V --size 0.5 SCANNING       (direita de ANALYTICS; foco -> SCANNING)
; move-focus down                         (desce para PROCESSING)
; split-pane -V --size 0.5 CLEANING       (direita de PROCESSING)
```

Os terminais são resolvidos por `Id` em um hashtable
(`analytics`/`scanning`/`processing`/`cleaning`) dentro de
`Build-WindowsTerminalArgumentList`, não por índice posicional — eliminando a
causa raiz do bug (dependência implícita da ordem do array).

## Sequência final dos panes

```text
1. new-tab        --title ANALYTICS
2. split-pane -H  --size 0.5 --title PROCESSING
3. move-focus up
4. split-pane -V  --size 0.5 --title SCANNING
5. move-focus down
6. split-pane -V  --size 0.5 --title CLEANING
```

## Resultado visual esperado

```text
┌─────────────────────────┬─────────────────────────┐
│ ANALYTICS               │ SCANNING                │
├─────────────────────────┼─────────────────────────┤
│ PROCESSING              │ CLEANING                │
└─────────────────────────┴─────────────────────────┘
```

Cada painel ocupa ~50% da largura e ~50% da altura da janela.

## Validação automática

- Sintaxe PowerShell de `launcher_common.ps1`, `launcher_grid_2x2.ps1` e
  `test_launchers_dry_run.ps1` validada via
  `[System.Management.Automation.Language.Parser]::ParseFile` — 0 erros.
- `tests/test_launchers_dry_run.ps1` executado isoladamente: **22 checks,
  0 erros**, incluindo os novos checks
  `windows_terminal_grid_2x2_layout_order`,
  `windows_terminal_returns_to_analytics_before_scanning_split` e
  `windows_terminal_returns_to_processing_before_cleaning_split`, que
  validam a string de argumentos completa do `wt.exe` na ordem correta.
- Suite completa `tests/run_all_safe_tests.ps1` executada: **PASS — 9
  testes, 215 checks, 0 erros** (inclui `test_security_static_scan`,
  `test_maintenance_real_gates` e `test_scheduled_task_dry_run`, todos PASS).
- Confirmado por inspeção do argumento gerado que toda chamada ao
  `powershell.exe` de cada pane mantém `-DryRun` e `-Mode startup_safe`.
- Nenhuma referência a `launcher_maintenance_real.ps1` foi adicionada em
  `Build-WindowsTerminalArgumentList` ou em qualquer arquivo alterado.
- `git diff --stat config/` não mostra nenhuma alteração feita nesta
  correção (o único diff pendente em `config/visual_settings.json` já
  existia antes desta sessão e não foi tocado aqui).

## Validação manual

Comando executado:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\launchers\launcher_grid_2x2.ps1 -Mode startup_safe -DryRun
```

O launcher reportou `Launcher handed off to wt.exe with 4 panes` e o
argumento completo logado confirma a sequência:
`new-tab ANALYTICS ; split-pane -H PROCESSING ; move-focus up ; split-pane
-V SCANNING ; move-focus down ; split-pane -V CLEANING`, que corresponde à
grade 2x2 esperada. A confirmação visual final (observar a janela do
Windows Terminal aberta) deve ser feita por quem está com acesso à tela,
já que o agente que aplicou esta correção não tem acesso visual ao
ambiente gráfico.

## Segurança preservada

- `launcher_grid_2x2.ps1` continua forçando `DryRun=$true` via
  `New-LauncherContext` independentemente de qualquer flag recebida.
- Nenhuma chamada a `launcher_maintenance_real.ps1` foi adicionada.
- Nenhuma tarefa agendada foi criada ou modificada.
- Nenhum comando DISM, SFC, CHKDSK ou defrag foi executado — todos os
  terminais seguem em `-Mode startup_safe -DryRun`.
- `config/terminals.json`, `config/visual_settings.json` e
  `config/schedule_settings.json` não foram alterados por esta correção.
- `Test-LauncherSafetyFlags`, `Assert-LauncherModeAllowedForBlock05` e os
  gates de `maintenance_real` não foram tocados.

## Confirmação de segurança

```text
Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, tarefa agendada, modo real, alteração de registro ou autoelevação foi rodado neste ajuste.
```
