# Estrategia de Logs

## Objetivo

Definir padrao de logs, estrutura de diretorios, conteudo minimo e formato do `summary.json`.

## Contexto

Logs sao parte central do projeto. Eles precisam atender tanto a experiencia visual quanto a rastreabilidade tecnica.

## Estrutura de Logs

```text
logs/
  YYYY-MM-DD_HH-mm-ss/
    analytics_dism_restorehealth.log
    scanning_sfc_scannow.log
    processing_chkdsk.log
    cleaning_optimize_drive.log
    launcher.log
    summary.json
```

## Padrao de Linha

```text
[2026-06-19 04:32:10] [ANALYTICS] [INFO] Mensagem
```

## Campos Minimos do `summary.json`

| Campo | Descricao |
| --- | --- |
| `startedAt` | Inicio da execucao |
| `finishedAt` | Fim da execucao |
| `mode` | Modo usado |
| `runId` | Identificador da pasta de log |
| `commands` | Lista de comandos executados |
| `exitCode` | Resultado final agregado |

## Decisoes Tecnicas

- Usar uma pasta de log por execucao.
- Separar logs por terminal.
- Usar `Tee-Object` ou equivalente para logar e exibir.
- Centralizar escrita em `Write-Log` e `Invoke-CommandWithLog`.

## Regras

- Logs visuais devem ser identificados como visuais.
- Resultados de comandos devem vir da saida real.
- O comando exato e argumentos devem ser registrados antes da execucao.
- Exit code deve ser capturado depois da execucao.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_09_logs_lockfile_summary.md`
- `Docs/06_scripts_funcoes/funcoes_common.md`
- `Docs/08_testes/fluxo_de_testes.md`

## Riscos

- Perder output de erro se stream `2>&1` nao for tratado.
- Sobrescrever logs de execucoes anteriores.
- Criar `summary.json` incompleto se um terminal falhar.

## Criterios de Aceite

- Estrutura de logs esta definida.
- `summary.json` tem campos minimos.
- O padrao impede resultados falsos.
