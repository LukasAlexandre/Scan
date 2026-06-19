# Feedback - Bloco 10 - Testes e Validacao Local

## Objetivo do bloco

Criar uma suite de testes locais seguros que exercite o codigo real do projeto
(configuracao, modulos comuns, terminais, launchers, startup safe, gates do modo
manutencao real, logs/lock/summary, instalador/desinstalador da tarefa agendada e
varredura estatica de seguranca), sem nunca executar um comando real de manutencao,
criar a tarefa agendada real, tocar no lock file real ou abrir janelas de terminal.

## Arquivos analisados

- `Docs/05_blocos_implementacao/bloco_10_testes_validacao_local.md`
- `Docs/08_testes/fluxo_de_testes.md`
- `Docs/08_testes/checklist_de_validacao.md`
- `Docs/08_testes/criterios_de_aceite.md`
- `Docs/08_testes/testes_modo_startup_safe.md`
- `Docs/08_testes/testes_modo_maintenance_real.md`
- `Docs/10_feedback/feedback_bloco_09_logs_lock_file_summary.md`
- `Docs/03_arquitetura/graphify_relatorio_arquitetura.md`
- `config/terminals.json`, `config/visual_settings.json`, `config/schedule_settings.json`
- `scripts/common/common.ps1`, `admin_check.ps1`, `banner.ps1`, `command_runner.ps1`,
  `config_loader.ps1`, `lock_file.ps1`, `logger.ps1`, `log_retention.ps1`,
  `run_context.ps1`, `spinner.ps1`, `summary_writer.ps1`, `visual_demo.ps1`
- `scripts/terminals/analytics_dism.ps1`, `terminal_runner.ps1` (e os demais scripts de
  terminal pelo mesmo padrao de `Start-TerminalRoutine`)
- `scripts/launchers/launcher_common.ps1`, `launcher_grid_2x2.ps1`,
  `launcher_fallback_windows.ps1`, `launcher_maintenance_real.ps1`,
  `maintenance_real_common.ps1`
- `scripts/startup/startup_common.ps1`, `launcher_startup_safe.ps1`,
  `create_scheduled_task.ps1`, `remove_scheduled_task.ps1`
- `install.ps1`, `uninstall.ps1`

Todos os arquivos obrigatorios foram encontrados e lidos antes da escrita dos testes. O
Bloco 09 ja estava commitado e sincronizado com `origin/master` (`b43d484`, "docs: add
graphify-assisted architecture review for block 09"); nenhuma acao de git foi necessaria
antes de iniciar.

## Arquivos criados

- `tests/test_config_json.ps1`
- `tests/test_common_modules.ps1`
- `tests/test_terminal_scripts_dry_run.ps1`
- `tests/test_launchers_dry_run.ps1`
- `tests/test_startup_safe_dry_run.ps1`
- `tests/test_maintenance_real_gates.ps1`
- `tests/test_logs_lock_summary.ps1`
- `tests/test_scheduled_task_dry_run.ps1`
- `tests/test_security_static_scan.ps1`
- `tests/run_all_safe_tests.ps1`
- `tests/README.md`
- `tests/results/.gitkeep`
- `Docs/08_testes/relatorio_validacao_local_bloco_10.md`
- `Docs/10_feedback/feedback_bloco_10_testes_validacao_local.md` (este arquivo)

## Arquivos alterados

- `.gitignore` — adicionado `tests/results/*` / `!tests/results/.gitkeep`, mesmo padrao
  ja usado para `logs/*` e `tmp/*`, para nao versionar pastas de resultado por execucao.
- `Docs/03_arquitetura/graphify_relatorio_arquitetura.md` — adicionado o addendum
  "Re-execucao para o Bloco 10".

Nenhum arquivo de `scripts/`, `config/` ou os instaladores (`install.ps1`/`uninstall.ps1`)
foi alterado neste bloco — o objetivo era validar o comportamento existente, nao mudar
funcionalidade. A unica correcao de codigo feita durante o bloco foi dentro do proprio
teste novo (`tests/test_security_static_scan.ps1`, ver "Resultados da validacao").

## Estrutura final da suite de testes

```text
tests/
  README.md
  run_all_safe_tests.ps1
  test_config_json.ps1
  test_common_modules.ps1
  test_terminal_scripts_dry_run.ps1
  test_launchers_dry_run.ps1
  test_startup_safe_dry_run.ps1
  test_maintenance_real_gates.ps1
  test_logs_lock_summary.ps1
  test_scheduled_task_dry_run.ps1
  test_security_static_scan.ps1
  results/
    .gitkeep
    <YYYY-MM-DD_HH-mm-ss>/        (gerado a cada execucao, ignorado pelo git)
      <teste>.console.log
      <teste>.json
      test_summary.json
      test_report.md
```

Cada script de teste segue o mesmo contrato: `[CmdletBinding()] param([string]$ResultsDirectory = '')`,
uma lista interna de `checks` (nome + passou/falhou + mensagem), um resultado JSON gravado
em `$ResultsDirectory/<testName>.json` quando informado, e um codigo de saida `0`/`1`. O
runner (`run_all_safe_tests.ps1`) cria `tests/results/<timestamp>/`, executa os 9 scripts
nessa ordem, grava o console de cada um, releva o JSON estruturado de cada teste e produz
`test_summary.json`/`test_report.md` consolidados, retornando `1` se qualquer teste falhar.

## Estrategia de seguranca dos testes (isolamento de lock, tarefa agendada e comandos reais)

- **Lock file**: todo teste de lock usa `-Path` explicito sob `$env:TEMP`
  (`tests/test_logs_lock_summary.ps1`, Parte B); o lock real em
  `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock` nunca e referenciado por
  nenhuma chamada de escrita/remocao.
- **Tarefa agendada**: `tests/test_scheduled_task_dry_run.ps1` so chama
  `install.ps1`/`uninstall.ps1` sem `-Apply` (dry-run real do script) ou com
  `-Apply -ConfirmationToken 'wrong_token_value'` — o token incorreto lanca excecao
  antes do script alcancar `Register-ScheduledTask`/`Unregister-ScheduledTask`. A
  ausencia da tarefa `WindowsMaintenanceTerminalGrid` e conferida antes e depois do
  teste.
- **Modo manutencao real**: `tests/test_maintenance_real_gates.ps1` nunca invoca
  `launcher_maintenance_real.ps1` como script (ele cria o lock real sem `-Path`
  customizado); chama apenas `Test-MaintenanceRealGates`,
  `Test-MaintenanceConfigurationSafety`, `New-MaintenanceExecutionPlan` e
  `Invoke-CommandWithLog` diretamente, sempre com um token de confirmacao deliberadamente
  errado quando o teste exige que a chamada va at[e] o chokepoint de execucao.
- **Janelas de terminal**: nenhum teste abre `wt.exe`, `cmd.exe` ou `powershell.exe`
  interativo; `launcher_grid_2x2.ps1` so e exercitado via `-ConsolidateSummaries`
  (caminho que nao abre janelas).
- **Varredura estatica**: `tests/test_security_static_scan.ps1` so le e analisa
  conteudo de arquivos (`Get-Content`/regex); nunca executa, apaga ou modifica nada.

## Resultados da validacao

- Sintaxe validada com `[System.Management.Automation.Language.Parser]::ParseFile()`
  para os scripts de instalacao/tarefa agendada e manutencao real reutilizados nos
  testes — sem erros de parse.
- Execucao completa via `powershell.exe -NoProfile -File tests\run_all_safe_tests.ps1`:
  primeira rodada (`tests/results/2026-06-19_15-04-37/`) — 8/9 testes PASS, 1 erro em
  `test_security_static_scan` (falso positivo, ver abaixo); segunda rodada, apos a
  correcao (`tests/results/2026-06-19_15-06-32/`) — **9/9 testes PASS, 199 checagens,
  0 erros**.
- Falso positivo identificado: `register_scheduled_task_only_in_permitted_script`
  apontou `scripts/startup/remove_scheduled_task.ps1`, porque o padrao
  `Register-ScheduledTask` casava (case-insensitive) com a subcadeia presente dentro de
  `Unregister-ScheduledTask`. Corrigido com `(?<!Un)Register-ScheduledTask` em
  `tests/test_security_static_scan.ps1`. Nenhum script de producao precisou de ajuste —
  o problema era exclusivamente do teste.
- Detalhe completo de evidencias por teste em
  `Docs/08_testes/relatorio_validacao_local_bloco_10.md`.

## Confirmacao que nenhum comando pesado foi executado

Nenhum `DISM`, `SFC`, `CHKDSK`, `defrag` ou qualquer comando real de manutencao foi
executado durante a criacao ou execucao da suite. `Get-Process -Name 'dism','sfc','chkdsk','defrag'`
nao encontrou nenhum processo correspondente apos a execucao completa. Os unicos
caminhos que tocam comandos de manutencao (`maintenance_real_common.ps1`,
`Invoke-CommandWithLog`) foram exercitados apenas com tokens de confirmacao incorretos
ou em modo dry-run, nunca com aprovacao real.

## Confirmacao que nenhuma tarefa agendada foi criada

Nenhuma tarefa agendada foi criada, alterada ou removida. `install.ps1`/`uninstall.ps1`
so foram chamados sem `-Apply` (dry-run) ou com `-Apply` e um token de confirmacao
deliberadamente invalido. `Get-ScheduledTask -TaskName 'WindowsMaintenanceTerminalGrid'`
confirmou ausencia da tarefa antes e depois de toda a execucao da suite.

## Riscos e limitacoes conhecidas

- Os Cenarios 07 e 08 de `Docs/08_testes/fluxo_de_testes.md` (tarefa agendada disparando
  no logon real, remocao real) continuam exigindo validacao manual fora desta suite —
  nenhum teste automatizado cria a tarefa real, por decisao de seguranca.
- `launcher_startup_safe.ps1` nao tem caminho seguro de execucao ponta-a-ponta sem abrir
  janelas reais; a cobertura combina checagem estatica de conteudo com chamada direta as
  funcoes auxiliares de `startup_common.ps1`.
- A suite depende de Windows PowerShell 5.1 (`powershell.exe`); o ambiente usado nao tem
  `pwsh` (PowerShell 7+) instalado, entao a suite nao foi validada nesse runtime.
- O scanner de seguranca estatico (`test_security_static_scan.ps1`) e baseado em regex
  sobre o conteudo dos arquivos; ele complementa, mas nao substitui, a leitura manual de
  codigo para revisões futuras — o proprio falso positivo encontrado neste bloco é prova
  de que o regex precisa de atencao ao ser estendido.

## Pendencias para o Bloco 11

- Validar manualmente, em ambiente controlado e autorizado, a criacao real da tarefa
  agendada e o disparo por logon (Cenario 07 de `fluxo_de_testes.md`), o que esta fora
  do escopo desta suite automatizada.
- Considerar instalar PowerShell 7+ (`pwsh`) no ambiente de desenvolvimento para validar
  a suite tambem nesse runtime, ja que o projeto roda em Windows PowerShell 5.1 por
  padrao mas pode ser executado em maquinas com `pwsh`.
- Incorporar `tests/run_all_safe_tests.ps1` ao README final como o comando oficial de
  validacao local antes de qualquer release.

## Git

- Branch antes do bloco: `master`.
- Hash base antes do bloco: `b43d484` ("docs: add graphify-assisted architecture review
  for block 09").
- Commit aplicado apos validacao: `test: add safe local validation suite`.
- Push aplicado: `git push origin master`, sem `--force`.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_11_documentacao_final_readme.md e implemente
somente o Bloco 11, usando como base a suite de testes do Bloco 10
(tests/run_all_safe_tests.ps1) como evidencia de validacao para o README final.
```

## Analise adicional com Graphify

- Graphify foi usado: sim.
- Comando executado: `graphify update .` (modo somente-codigo, sem chave de LLM, sem
  custo de API) — mesmo modo do Bloco 09.
- Resultado: 1061 nos / 1101 arestas / 105 comunidades, a partir de 105 arquivos de
  codigo (antes da pasta `tests/`: 1024 nos / 1076 arestas / 91 comunidades a partir de
  31 arquivos PowerShell). O aumento corresponde exatamente aos 10 novos scripts deste
  bloco.
- Limitacao confirmada: a extracao heuristica sem LLM nao modela aresta de chamada
  quando um script invoca outro via operador de chamada (`& $scriptPath ...`) ou apenas
  dot-source `common.ps1` e chama as funcoes carregadas — padrao usado pelos 9 testes.
  Por isso varios nos de teste aparecem com grau baixo ou zero no grafo (ex.:
  `run_all_safe_tests.ps1` com grau 0), apesar de, na leitura direta do codigo, cada
  script efetivamente exercitar dezenas de funcoes de `scripts/common/`.
- Impacto na implementacao do Bloco 10: nenhuma mudanca de codigo foi feita por causa do
  Graphify. A re-execucao serviu como segunda confirmacao de que a pasta `tests/` nao
  introduziu nenhuma arvore de chamada nova em direcao a `Register-ScheduledTask`,
  `Unregister-ScheduledTask` ou aos comandos reais de manutencao —
  `graphify affected "Invoke-CommandWithLog()"` continua apontando apenas para
  `Invoke-MaintenanceExecutionPlan()`, igual ao Bloco 09.
- Detalhes completos: addendum "Re-execucao para o Bloco 10" em
  `Docs/03_arquitetura/graphify_relatorio_arquitetura.md`.

## Confirmacao de seguranca

Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, modo real, startup automático real durante validação, alteração de registro, autoelevação ou comando administrativo foi rodado neste bloco.
