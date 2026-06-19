# Bloco 09 - Logs, Lock File e Summary

## Objetivo

Consolidar a estrategia de logs, protecao contra duplicidade e resumo final da execucao.

## Contexto

Embora logs e lock aparecam em blocos anteriores, este bloco fecha a integracao e padroniza comportamento em todos os modos.

## Escopo

- Garantir pasta `logs/YYYY-MM-DD_HH-mm-ss/`.
- Garantir logs por terminal.
- Garantir `launcher.log`.
- Garantir `summary.json`.
- Implementar limpeza de lock antigo.
- Proteger contra execucao duplicada.

## Fora de Escopo

- Criar novos comandos de manutencao.
- Alterar layout visual.
- Criar tarefa agendada.

## Arquivos que devem ser criados ou alterados

- `scripts/common/logger.ps1`
- `scripts/common/command_runner.ps1`
- `launcher_startup_safe.ps1`
- `launcher_maintenance_real.ps1`
- `scripts/terminals/*.ps1`

## Funcoes esperadas

- `New-RunLogDirectory`
- `Write-Log`
- `Test-LockFile`
- `New-LockFile`
- `Remove-LockFile`
- `Write-SummaryJson`
- `Get-RunSummary`

## Configuracoes necessarias

- `logRoot`
- `lockFilePath`
- `staleLockMinutes`
- `summaryFileName`

## Regras tecnicas

- Lock deve conter PID, horario, modo e caminho de log.
- Lock antigo deve ser removido apenas se processo nao estiver ativo.
- Logs nao devem ser sobrescritos.
- Summary deve incluir comandos ignorados e falhos, nao apenas sucesso.

## Riscos

- Lock preso impedir uso.
- Summary incompleto em caso de falha.
- Logs ficarem grandes demais.

## Passo a passo de implementacao

1. Revisar funcoes de log.
2. Padronizar nomes de arquivos.
3. Implementar lock com PID.
4. Implementar limpeza segura de lock antigo.
5. Centralizar escrita do summary.
6. Testar fluxo com falha simulada.

## Fluxo de teste

1. Criar lock fake com PID inexistente e confirmar limpeza.
2. Criar lock com PID atual e confirmar bloqueio.
3. Rodar dry run e verificar logs.
4. Simular falha e verificar summary.

## Criterios de aceite

- Lock impede duplicidade real.
- Lock antigo e limpo com seguranca.
- Summary registra sucesso, falha e comandos ignorados.
- Logs por terminal existem.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 09. Consolide logs, lock file e summary.json em todos os launchers e terminais. Teste duplicidade, lock antigo e falha simulada sem executar manutencao real.
```

## Feedback esperado apos implementacao

- Estrutura de logs gerada.
- Exemplo de summary.
- Resultado dos testes de lock.
- Pendencias de retencao/limpeza de logs.
