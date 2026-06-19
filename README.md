# Windows Maintenance Terminal Grid

## Objetivo

Utilitario Windows que abre quatro terminais em layout 2x2 (ANALYTICS/DISM,
SCANNING/SFC, PROCESSING/CHKDSK, CLEANING/defrag), com visual tecnico,
banners, loading e logs estruturados. O projeto e construido por DDAD
(Documentation-Driven Agentic Development), em blocos sequenciais, cada um
com escopo, validacao e feedback documentados em `Docs/`.

O sistema nao "melhora" o Windows automaticamente: ele e um orquestrador
visual e controlado para comandos de diagnostico/manutencao que o proprio
Windows ja oferece (DISM, SFC, CHKDSK, defrag). Nenhuma funcionalidade
descrita abaixo promete mais do que o que foi implementado e validado.

## Status Atual

Blocos 00 a 10 implementados, testados e commitados em `master`. Bloco 11
(este) consolida a documentacao final de uso. Nao ha pendencia de
implementacao de codigo em aberto; os itens que ainda exigem validacao
manual estao listados em [Riscos e Pendencias](#riscos-e-pendencias-conhecidas).

| Bloco | Entrega |
| --- | --- |
| 00 | Baseline e organizacao do repositorio |
| 01 | Configuracoes base em JSON (`config/`) |
| 02 | Funcoes comuns PowerShell (`scripts/common/`) |
| 03 | Banners, loading e logs visuais |
| 04 | Scripts dos 4 terminais (`scripts/terminals/`) |
| 05 | Launcher grid 2x2 (`scripts/launchers/launcher_grid_2x2.ps1`) |
| 06 | Modo `startup_safe` (`scripts/startup/`) |
| 07 | Modo `maintenance_real` (`scripts/launchers/launcher_maintenance_real.ps1`) |
| 08 | Tarefa agendada do Windows (`install.ps1`/`uninstall.ps1`) |
| 09 | Logs estruturados, lock file e summary consolidado |
| 10 | Suite de testes locais seguros (`tests/`) |
| 11 | Documentacao final e README (este bloco) |

## Modos de Operacao

| Modo | Uso | Comandos pesados | Requer administrador |
| --- | --- | --- | --- |
| `startup_safe` | Abrir no login (ou manualmente) com visual e checks leves | Nao — sempre dry-run | Nao |
| `maintenance_real` | Manutencao real, sob demanda manual | Sim, somente com confirmacao explicita | Sim |
| `visual_only` (`-ConsolidateSummaries` / dry-run) | Validar visual, logs e summaries sem comandos reais | Nao | Nao |

Detalhes completos de cada modo, incluindo o que cada camada de seguranca
bloqueia, estao em [Docs/09_execucao/modos_de_operacao.md](Docs/09_execucao/modos_de_operacao.md).

**O modo seguro (`startup_safe`/dry-run) e o fluxo recomendado para
qualquer primeiro uso ou avaliacao do projeto.**

## Inicio Rapido

Resumo de comandos; para passo a passo completo, leia
[Docs/09_execucao/guia_rapido.md](Docs/09_execucao/guia_rapido.md).

```powershell
# 1. Validar o projeto localmente (recomendado antes de qualquer uso)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\run_all_safe_tests.ps1

# 2. Testar o modo seguro manualmente (abre os 4 terminais em dry-run)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\startup\launcher_startup_safe.ps1 -DryRun

# 3. (Opcional, real) Instalar a tarefa agendada de login em modo seguro
powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Apply -ConfirmationToken I_ACCEPT_STARTUP_SAFE_TASK
```

> A tarefa agendada criada pelo passo 3 **sempre** aponta para
> `launcher_startup_safe.ps1` com `-DryRun`. Nao existe um caminho, manual ou
> automatico, em que `install.ps1` agende `maintenance_real`.

## Estrutura da Documentacao

- `Docs/00_ideia_original/` - ideia base preservada.
- `Docs/01_visao_geral/` - visao, objetivo e premissas.
- `Docs/02_requisitos/` - requisitos, seguranca e matriz de comandos.
- `Docs/03_arquitetura/` - arquitetura, modos, logs e layout.
- `Docs/04_planejamento/` - roadmap e divisao em blocos.
- `Docs/05_blocos_implementacao/` - prompts e escopos por bloco.
- `Docs/06_scripts_funcoes/` - matriz de scripts e funcoes esperadas.
- `Docs/07_configuracoes/` - exemplos documentados de JSON.
- `Docs/08_testes/` - fluxo de testes, criterios de aceite e relatorio de validacao local.
- `Docs/09_execucao/` - guias de instalacao, execucao, remocao e operacao segura.
- `Docs/10_feedback/` - feedback registrado ao final de cada bloco.

Guias de execucao disponiveis em `Docs/09_execucao/`:

| Arquivo | Conteudo |
| --- | --- |
| [guia_rapido.md](Docs/09_execucao/guia_rapido.md) | Caminho mais curto: validar, testar seguro, instalar, remover |
| [como_instalar.md](Docs/09_execucao/como_instalar.md) | Instalar a tarefa agendada (`install.ps1`) |
| [como_rodar_startup_safe.md](Docs/09_execucao/como_rodar_startup_safe.md) | Executar o modo seguro manualmente |
| [como_rodar_maintenance_real.md](Docs/09_execucao/como_rodar_maintenance_real.md) | Executar manutencao real, com todos os gates de seguranca |
| [como_remover.md](Docs/09_execucao/como_remover.md) | Remover a tarefa agendada (`uninstall.ps1`) |
| [comandos_seguros.md](Docs/09_execucao/comandos_seguros.md) | O que cada comando real faz e qual risco carrega |
| [modos_de_operacao.md](Docs/09_execucao/modos_de_operacao.md) | Diferenca real entre `startup_safe`, dry-run e `maintenance_real` |
| [validacao_local.md](Docs/09_execucao/validacao_local.md) | Como rodar a suite de testes antes de qualquer uso |
| [logs_lock_summary.md](Docs/09_execucao/logs_lock_summary.md) | Como interpretar logs, lock file e summaries |
| [troubleshooting.md](Docs/09_execucao/troubleshooting.md) | Problemas comuns e como resolver |

## Como Instalar

Instala a tarefa agendada do Windows que abre o modo `startup_safe` (sempre
em dry-run) no logon. Sem `-Apply` e o token de confirmacao correto, nada e
criado — apenas simulado.

```powershell
# Simulacao (nao cria nada)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1

# Instalacao real
powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Apply -ConfirmationToken I_ACCEPT_STARTUP_SAFE_TASK
```

Detalhes em [Docs/09_execucao/como_instalar.md](Docs/09_execucao/como_instalar.md).

## Como Executar Modo Seguro

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\startup\launcher_startup_safe.ps1 -DryRun
```

Abre os quatro terminais com banners, loading e checks leves, sem executar
DISM, SFC, CHKDSK ou defrag. Detalhes em
[Docs/09_execucao/como_rodar_startup_safe.md](Docs/09_execucao/como_rodar_startup_safe.md).

## Como Executar Manutencao Real

Exige PowerShell elevado (administrador), a flag de sessao
`-AllowSessionRealMaintenance` e o token de confirmacao
`I_ACCEPT_WINDOWS_MAINTENANCE`. **Comandos reais alteram o estado do
Windows — DISM e SFC podem levar minutos a horas, defrag aumenta uso de
disco durante a execucao.** Valide sempre em dry-run primeiro.

```powershell
# Simulacao (recomendado primeiro)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\launchers\launcher_maintenance_real.ps1 -DryRun

# Execucao real (requer administrador)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\launchers\launcher_maintenance_real.ps1 -RunReal -AllowSessionRealMaintenance -ConfirmationToken I_ACCEPT_WINDOWS_MAINTENANCE
```

`chkdsk C: /r` (reparo profundo de disco) esta **bloqueado estruturalmente
no codigo atual**, independente de flags — ver
[comandos_seguros.md](Docs/09_execucao/comandos_seguros.md). Detalhes
completos em [Docs/09_execucao/como_rodar_maintenance_real.md](Docs/09_execucao/como_rodar_maintenance_real.md).

## Como Remover

```powershell
# Simulacao (nao remove nada)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1

# Remocao real
powershell.exe -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1 -Apply -ConfirmationToken I_ACCEPT_REMOVE_STARTUP_SAFE_TASK
```

Idempotente: se a tarefa nao existir, retorna status `not_found` sem erro.
Detalhes em [Docs/09_execucao/como_remover.md](Docs/09_execucao/como_remover.md).

## Validacao Local

Antes de instalar ou usar o projeto em qualquer maquina, execute a suite de
testes locais seguros — ela nunca cria a tarefa agendada real, nunca toca o
lock file real e nunca executa comandos de manutencao real:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\run_all_safe_tests.ps1
```

Ultima execucao registrada (Bloco 10, ambiente local):
**9/9 testes PASS, 199 checagens, 0 erros**. Relatorio completo em
[Docs/08_testes/relatorio_validacao_local_bloco_10.md](Docs/08_testes/relatorio_validacao_local_bloco_10.md).
Guia de uso da suite em [Docs/09_execucao/validacao_local.md](Docs/09_execucao/validacao_local.md)
e em [tests/README.md](tests/README.md).

## Seguranca

- O modo `startup_safe` nunca executa DISM, SFC, CHKDSK ou defrag — o
  launcher de grid forca dry-run nas chamadas de terminal nesta camada.
- O modo `maintenance_real` so executa comandos reais com administrador,
  flag de sessao explicita e o token `I_ACCEPT_WINDOWS_MAINTENANCE`.
- `chkdsk C: /r` (reparo profundo) esta bloqueado no codigo atual, mesmo com
  todas as outras condicoes satisfeitas.
- A tarefa agendada criada por `install.ps1` sempre aponta para
  `launcher_startup_safe.ps1 -DryRun`, roda com `LogonType=Interactive` e
  `RunLevel=Limited` — nunca com privilegios elevados automaticos.
- Um lock file em `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock`
  impede execucao duplicada simultanea (mesmo PID pode reentrar; lock de
  outro processo vivo bloqueia; lock expirado/de processo morto e
  considerado obsoleto).
- Instalar e remover a tarefa agendada, e rodar manutencao real, exigem
  sempre um token de confirmacao exato digitado pelo usuario — nenhuma
  acao real ocorre apenas por rodar um script sem esses parametros.

Mapa completo de riscos por comando em
[Docs/09_execucao/comandos_seguros.md](Docs/09_execucao/comandos_seguros.md)
e na matriz oficial em [Docs/02_requisitos/matriz_de_comandos.md](Docs/02_requisitos/matriz_de_comandos.md).

## Logs, Lock File e Summary

```text
logs/<RunId>/                  (RunId = <source>_<YYYY-MM-DD_HH-mm-ss>_<6 chars aleatorios>)
  run_metadata.json
  execution_events.ndjson
  terminals/<terminal>.log
  summaries/<terminal>_summary.json
  summary.json                 (gerado apenas pelo launcher, ao consolidar)

%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock
```

Explicacao completa de cada arquivo, quem escreve o que e como interpretar
um `summary.json` em [Docs/09_execucao/logs_lock_summary.md](Docs/09_execucao/logs_lock_summary.md).

## Riscos e Pendencias Conhecidas

- A criacao real da tarefa agendada e o disparo por logon real (Cenarios 07
  e 08 de `Docs/08_testes/fluxo_de_testes.md`) nunca foram executados em
  ambiente de desenvolvimento — apenas dry-run e bloqueio por token
  invalido foram validados automaticamente. Validacao manual continua
  pendente e deve ser feita em ambiente controlado e autorizado.
- A suite de testes foi validada apenas em Windows PowerShell 5.1
  (`powershell.exe`); `pwsh` (PowerShell 7+) nao foi validado no ambiente
  de desenvolvimento atual.
- `launcher_grid_2x2.ps1` abre os terminais como processos destacados e nao
  espera a conclusao deles; `-ConsolidateSummaries` precisa ser chamado
  separadamente apos os terminais terminarem. Isso e uma limitacao
  arquitetural conhecida, nao um bug.
- A limpeza automatica de logs antigos (`Clear-OldRunLogs`,
  `retentionDays` em `config/schedule_settings.json`) existe como funcao
  utilitaria, mas **nao e chamada automaticamente** por nenhum launcher
  ainda — e uma operacao manual/futura.

## Proximos Passos

Documentacao final consolidada neste Bloco 11. Veja
[Docs/10_feedback/feedback_bloco_11_documentacao_final_readme.md](Docs/10_feedback/feedback_bloco_11_documentacao_final_readme.md)
para o detalhe completo do que foi revisado e quais pendencias de validacao
manual permanecem em aberto.
