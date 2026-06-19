# Relatorio de Arquitetura - Apoio do Graphify (pos Bloco 09)

## Objetivo deste documento

Registrar conclusoes uteis extraidas do Graphify (https://github.com/safishamsi/graphify.git) sobre a estrutura atual do projeto, usadas para validar a coerencia da arquitetura de logs, lock file e summary entregue no Bloco 09. Este arquivo contem apenas conclusoes; o dump bruto do grafo (`graphify-out/graph.json`, `graph.html`, `GRAPH_REPORT.md`) nao e versionado (ver `.gitignore`).

O Graphify e usado apenas como ferramenta auxiliar de leitura do repositorio. Ele nao e dependencia runtime do Windows Maintenance Terminal Grid e nenhum script do projeto foi executado por meio dele.

## Como foi gerado

- Instalacao isolada: `uv tool install graphifyy` (sem `winget`, ja que `uv`/`winget` ja estavam presentes no ambiente).
- Extracao: `graphify update <raiz-do-projeto>` — modo "no LLM needed", que reextrai apenas arquivos de codigo via AST (`tree-sitter-powershell`) sem enviar conteudo a nenhuma API de LLM.
- Não foi configurada nenhuma chave de API (`GEMINI_API_KEY`/`ANTHROPIC_API_KEY`/etc.), portanto a camada semantica que cruza `Docs/*.md` com o codigo nao foi gerada; apenas o grafo de codigo (PowerShell) foi construido.
- Resultado: 1024 nos, 1076 arestas, 91 comunidades, a partir de 31 arquivos de codigo (95% das arestas extraidas diretamente da AST, 5% inferidas por heuristica).

## Relacoes confirmadas relevantes ao Bloco 09

- `New-RunContext()` (`scripts/common/run_context.ps1`) e chamado por `Start-TerminalRoutine()`, `New-LauncherContext()` e `New-StartupRunContext()` — confirma que terminal, launcher e startup_safe compartilham o mesmo ponto de criacao/leitura de contexto de execucao.
- `Write-ConsolidatedSummaryJson()` (`scripts/common/summary_writer.ps1`) e chamado apenas por `Invoke-LauncherSummaryConsolidation()` (`scripts/launchers/launcher_common.ps1`) — confirma que somente os launchers consolidam o `summary.json` final.
- `Write-TerminalSummaryJson()` e chamado apenas por `Start-TerminalRoutine()` (`scripts/terminals/terminal_runner.ps1`) — confirma que cada terminal grava somente seu proprio arquivo em `summaries/`, nunca o `summary.json` consolidado.
- `Write-ExecutionEvent()` (`scripts/common/logger.ps1`) e chamado por `Write-LauncherLog()`, `Write-TerminalLog()`, `Write-MaintenanceLog()` e `Write-StartupLog()` — confirma que os quatro wrappers de log por origem convergem para o mesmo gravador de `execution_events.ndjson`.
- `New-LockFile()` (`scripts/common/lock_file.ps1`) e chamado por `New-LauncherRunLock()` (`scripts/launchers/launcher_common.ps1`).

## Limitacao observada na analise automatica (gap conhecido do grafo)

A travessia reversa (`graphify affected "New-LockFile()"`) so encontrou `New-LauncherRunLock()` como chamador, mas a leitura direta do codigo confirma que `scripts/launchers/launcher_maintenance_real.ps1` e `scripts/startup/launcher_startup_safe.ps1` tambem chamam `New-LockFile()` diretamente (sem passar por `New-LauncherRunLock()`). O Graphify, no modo somente-codigo sem LLM, nao capturou essas duas chamadas cruzadas de arquivo. Isso nao indica um problema de arquitetura — apenas uma limitacao da extracao heuristica sem o passo semantico (que exigiria uma chave de API de LLM, nao configurada neste ambiente). A conclusao foi validada por leitura manual dos tres launchers.

## Comunidades de maior destaque (God Nodes)

- `Start-TerminalRoutine()` (24 arestas) e `Write-Log()` (18 arestas) seguem como os nos de codigo mais conectados do projeto, reforcando que sao os pontos centrais de qualquer mudanca futura em logging/execucao de terminal.
- Os documentos de feedback de cada bloco (`Feedback - Bloco 07`, `Feedback - Bloco 08`, `Feedback - Bloco 09`, etc.) aparecem entre os nos mais conectados da camada de documentacao, o que e esperado dado o padrao DDAD do projeto (cada bloco referencia os blocos e arquivos anteriores).

## Impacto na implementacao do Bloco 09

Nenhuma mudanca de codigo foi feita por causa do Graphify — a ferramenta foi usada **depois** da implementacao e validacao do Bloco 09, como segunda fonte de confirmacao de que:

1. logs por origem (`Write-TerminalLog`/`Write-LauncherLog`/`Write-StartupLog`/`Write-MaintenanceLog`) convergem corretamente para `Write-ExecutionEvent()`;
2. a separacao entre `Write-TerminalSummaryJson()` (por terminal) e `Write-ConsolidatedSummaryJson()` (launcher) esta isolada como pretendido, sem nenhum chamador cruzado que pudesse reintroduzir a sobrescrita;
3. a criacao de lock file esta concentrada nos launchers, nunca nos scripts de terminal.

## Observacoes

- Para uma analise semantica completa cruzando `Docs/*.md` com o codigo, seria necessario configurar uma chave de API de LLM (`GEMINI_API_KEY`, `ANTHROPIC_API_KEY` ou equivalente) e rodar `graphify extract`. Isso nao foi feito neste momento para evitar enviar conteudo do repositorio a um servico externo sem autorizacao explicita adicional.
- O grafo de codigo gerado (`graphify-out/`) nao e versionado; pode ser regenerado a qualquer momento com `graphify update .` (sem custo de API).
