# Bloco 02 - Funcoes Comuns PowerShell

## Objetivo

Planejar e implementar funcoes compartilhadas para logs, banners, spinner, admin, lock file, execucao de comandos e resumo JSON.

## Contexto

Os quatro terminais e launchers devem reutilizar as mesmas funcoes para evitar divergencia de comportamento.

## Escopo

- Criar scripts em `scripts/common/`.
- Implementar funcoes comuns seguras.
- Criar testes basicos sem executar manutencao real.
- Documentar parametros e retorno.

## Fora de Escopo

- Executar DISM, SFC, CHKDSK ou defrag.
- Abrir grid 2x2.
- Criar tarefa agendada.

## Arquivos que devem ser criados ou alterados

- `scripts/common/logger.ps1`
- `scripts/common/banner.ps1`
- `scripts/common/spinner.ps1`
- `scripts/common/admin_check.ps1`
- `scripts/common/monitor_layout.ps1`
- `scripts/common/command_runner.ps1`

## Funcoes esperadas

- `Write-Log`
- `Write-ColoredLog`
- `Show-Banner`
- `Show-LoadingBar`
- `Show-Spinner`
- `Test-IsAdmin`
- `Start-AsAdmin`
- `New-RunLogDirectory`
- `Test-LockFile`
- `New-LockFile`
- `Remove-LockFile`
- `Invoke-CommandWithLog`
- `Write-SummaryJson`

## Configuracoes necessarias

- Caminho do root do projeto.
- Caminho da pasta de logs.
- Modo atual.
- Identificador do terminal.

## Regras tecnicas

- Funcoes devem receber parametros explicitos.
- `Invoke-CommandWithLog` deve aceitar modo simulado para teste.
- `Start-AsAdmin` deve preservar argumentos.
- `Remove-LockFile` deve ser chamado em bloco `finally` quando possivel.

## Riscos

- Funcao de runner executar comando real durante teste.
- Lock file ficar preso apos falha.
- Escrita de logs quebrar em caminho inexistente.

## Passo a passo de implementacao

1. Criar arquivos em `scripts/common/`.
2. Implementar logger.
3. Implementar visual seguro.
4. Implementar admin check.
5. Implementar lock file.
6. Implementar runner com modo dry run.
7. Implementar summary JSON.
8. Testar com comando inofensivo como `powershell -Command "Write-Output test"` ou equivalente seguro.

## Fluxo de teste

1. Dot-source dos arquivos comuns.
2. Chamar `Write-Log` em pasta temporaria do projeto.
3. Chamar `Test-IsAdmin` sem exigir elevacao.
4. Criar e remover lock file de teste.
5. Gerar `summary.json` de teste.

## Criterios de aceite

- Funcoes carregam sem erro.
- Logs sao criados com timestamp.
- Lock file cria, detecta e remove.
- Runner possui modo seguro de teste.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 02. Crie funcoes comuns PowerShell listadas no documento, com testes seguros e sem executar comandos de manutencao do Windows. O runner deve permitir dry run e registrar logs corretamente.
```

## Feedback esperado apos implementacao

- Lista de funcoes criadas.
- Como foram testadas.
- Limites do runner.
- Pendencias para banners e scripts de terminais.
