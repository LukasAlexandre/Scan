# Validacao Local

## Objetivo

Explicar como validar o projeto localmente antes de instalar a tarefa
agendada ou rodar manutencao real, usando a suite criada no Bloco 10
(`tests/`).

## Por que validar antes de usar

A suite exercita o codigo real (configuracao, modulos comuns, terminais,
launchers, startup safe, gates de manutencao real, logs/lock/summary,
instalador/desinstalador e uma varredura estatica de seguranca) **sem
nunca**:

- criar ou remover a tarefa agendada real `WindowsMaintenanceTerminalGrid`;
- tocar no lock file real (`%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock`);
- executar DISM, SFC, CHKDSK ou defrag reais;
- abrir janelas de terminal.

Rodar a suite e o passo recomendado antes de qualquer instalacao real ou
antes de atualizar o codigo para uma nova maquina.

## Comando

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\run_all_safe_tests.ps1
```

> O ambiente de desenvolvimento usado para validar este projeto so tinha
> Windows PowerShell 5.1 (`powershell.exe`) disponivel; `pwsh`
> (PowerShell 7+) nao foi testado. Se sua maquina tiver `pwsh` instalado,
> ele tambem deve funcionar (`pwsh -File tests\run_all_safe_tests.ps1`),
> mas isso ainda nao foi validado neste projeto.

## O que o runner faz

1. Cria `tests/results/<timestamp>/` (pasta nova a cada execucao).
2. Executa, em ordem, os 9 scripts `test_*.ps1` de `tests/`.
3. Grava um log de console (`<teste>.console.log`) e o resultado
   estruturado (`<teste>.json`) de cada teste.
4. Gera `test_summary.json` (legivel por maquina) e `test_report.md`
   (legivel por humano).
5. Retorna codigo de saida `0` se todos os testes passarem, `1` se
   qualquer um falhar.

## Os 9 testes

| Arquivo | O que valida |
| --- | --- |
| `test_config_json.ps1` | Os 3 arquivos JSON de configuracao existem, sao validos e respeitam o schema esperado. |
| `test_common_modules.ps1` | Os modulos em `scripts/common/` carregam sem erro e expoem as funcoes esperadas. |
| `test_terminal_scripts_dry_run.ps1` | Os scripts de terminal rodam em dry-run real, sem disparar comandos de manutencao. |
| `test_launchers_dry_run.ps1` | `launcher_grid_2x2.ps1 -ConsolidateSummaries` e a montagem de comandos dos launchers funcionam em modo seguro. |
| `test_startup_safe_dry_run.ps1` | Conteudo e funcoes auxiliares de `launcher_startup_safe.ps1`/`startup_common.ps1` nunca chamam o launcher de manutencao real. |
| `test_maintenance_real_gates.ps1` | Os gates de `maintenance_real_common.ps1` bloqueiam corretamente quando falta token, admin ou flag de sessao. |
| `test_logs_lock_summary.ps1` | Logs estruturados, lock file (isolado em `$env:TEMP`) e summaries individuais/consolidados funcionam corretamente. |
| `test_scheduled_task_dry_run.ps1` | `install.ps1`/`uninstall.ps1` ficam em dry-run sem `-Apply`, e bloqueiam com token de confirmacao invalido. |
| `test_security_static_scan.ps1` | Varredura estatica (somente alerta) garante que padroes sensiveis so aparecem nos arquivos esperados. |

Detalhes de cada teste em [tests/README.md](../../tests/README.md).

## Ultimo resultado registrado

Execucao local mais recente (ambiente: Windows 11 Pro, Windows PowerShell
5.1, usuario sem privilegio administrativo):

**9/9 testes PASS, 199 checagens, 0 erros.**

Relatorio completo, incluindo um falso positivo encontrado e corrigido
durante a validacao (no proprio teste, nao no codigo de producao), em
[Docs/08_testes/relatorio_validacao_local_bloco_10.md](../08_testes/relatorio_validacao_local_bloco_10.md).

## O que a suite NAO cobre (validacao manual pendente)

- Criacao real da tarefa agendada e disparo por logon real (Cenarios 07 e
  08 de `Docs/08_testes/fluxo_de_testes.md`) — por decisao de seguranca,
  nenhum teste automatizado cria a tarefa real. Validar manualmente, em
  ambiente controlado e autorizado, quando necessario.
- Execucao da suite em `pwsh` (PowerShell 7+) — nao disponivel no ambiente
  de desenvolvimento usado.
- `launcher_maintenance_real.ps1` como processo completo (a suite testa as
  funcoes de gate isoladamente, para nao criar o lock real sem um `-Path`
  customizado).

## Arquivos Relacionados

- `tests/run_all_safe_tests.ps1`, `tests/README.md`
- `Docs/08_testes/relatorio_validacao_local_bloco_10.md`,
  `Docs/08_testes/fluxo_de_testes.md`
- [logs_lock_summary.md](logs_lock_summary.md)

## Riscos

- Um resultado PASS local nao substitui a validacao manual dos cenarios de
  tarefa agendada real listados acima.
- A varredura estatica de seguranca e baseada em regex; ela complementa,
  mas nao substitui, a leitura manual de codigo ao estender o projeto.

## Criterios de Aceite

- A suite roda do zero (`tests\run_all_safe_tests.ps1`) e produz
  `test_summary.json`/`test_report.md` em uma nova pasta de
  `tests/results/`.
- Nenhuma execucao da suite cria a tarefa agendada real, toca o lock real
  ou executa comando de manutencao real.
