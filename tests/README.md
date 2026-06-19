# Suite de testes seguros locais (Bloco 10)

Esta pasta contem uma suite de validacao local que exercita o codigo real do
projeto (configuracao, modulos comuns, terminais, launchers, startup,
manutencao real, logs/lock/summary, tarefa agendada e varredura de
seguranca) **sem nunca**:

- criar ou remover a tarefa agendada real `WindowsMaintenanceTerminalGrid`;
- criar, ler ou apagar o lock file real em
  `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock`;
- executar comandos reais de manutencao do Windows (`DISM`, `SFC`, `CHKDSK`,
  `defrag`);
- abrir janelas de terminal (`Windows Terminal`/`wt.exe`, `cmd.exe`,
  `powershell.exe` em modo interativo);
- alterar o registro do Windows, usar autoelevacao (`-Verb RunAs`) ou
  registrar entradas em `shell:startup`;
- deixar arquivos temporarios em `logs/` ou em qualquer pasta de configuracao
  real do projeto.

Todo teste que precisa de um diretorio de execucao usa uma pasta temporaria
isolada (sob `logs/_tests_tmp_*` dentro do projeto, ou sob `$env:TEMP`) e
remove essa pasta no bloco `finally`, mesmo se o teste falhar.

## Como executar

Execute todos os testes de uma vez, a partir da raiz do projeto:

```powershell
pwsh -File tests/run_all_safe_tests.ps1
```

O runner:

1. cria `tests/results/<timestamp>/` (pasta nova a cada execucao);
2. executa, em ordem, os 9 scripts `test_*.ps1` desta pasta;
3. grava um log de console por teste (`<teste>.console.log`) e o resultado
   estruturado de cada teste (`<teste>.json`) na mesma pasta de resultados;
4. gera `test_summary.json` (resumo agregado, legivel por maquina) e
   `test_report.md` (resumo legivel por humano, com tabela de resultados);
5. retorna codigo de saida `0` se todos os testes passarem, ou `1` se
   qualquer teste falhar.

Tambem e possivel executar um teste individual, passando opcionalmente uma
pasta de resultados:

```powershell
pwsh -File tests/test_config_json.ps1 -ResultsDirectory tests/results/manual
```

## Testes incluidos

| Arquivo | O que valida |
| --- | --- |
| `test_config_json.ps1` | Os 3 arquivos JSON de configuracao existem, tem JSON valido e respeitam o schema esperado. |
| `test_common_modules.ps1` | Os modulos em `scripts/common/` carregam sem erro e expõem as funcoes esperadas. |
| `test_terminal_scripts_dry_run.ps1` | Os scripts de terminal rodam em modo dry-run real, sem disparar comandos de manutencao. |
| `test_launchers_dry_run.ps1` | `launcher_grid_2x2.ps1 -ConsolidateSummaries` e a montagem de comandos dos launchers funcionam em modo seguro. |
| `test_startup_safe_dry_run.ps1` | Conteudo e funcoes auxiliares de `launcher_startup_safe.ps1`/`startup_common.ps1` sao seguros (nunca chamam o launcher de manutencao real). |
| `test_maintenance_real_gates.ps1` | Os gates de seguranca de `maintenance_real_common.ps1` bloqueiam corretamente quando falta token, admin ou flag de sessao. |
| `test_logs_lock_summary.ps1` | Logs estruturados, lock file (isolado em `$env:TEMP`) e summaries individuais/consolidados funcionam corretamente. |
| `test_scheduled_task_dry_run.ps1` | `install.ps1`/`uninstall.ps1` ficam em dry-run sem `-Apply`, e bloqueiam com token de confirmacao invalido. |
| `test_security_static_scan.ps1` | Varredura estatica (somente alerta) garante que padroes sensiveis so aparecem nos arquivos esperados. |
| `run_all_safe_tests.ps1` | Executa todos os testes acima e consolida os resultados. |

## Resultados

Cada execucao cria uma subpasta nova em `tests/results/`. Essas subpastas
sao ignoradas pelo Git (`tests/results/*` no `.gitignore`, exceto o
`.gitkeep` que mantem a pasta versionada vazia).
