# Funcoes Common

## Objetivo

Documentar as funcoes compartilhadas que devem existir em `scripts/common/`.

## Contexto

As funcoes comuns formam a base tecnica do projeto. Elas reduzem duplicacao e garantem que logs, admin, lock e execucao de comandos sigam o mesmo padrao.

## Funcoes Planejadas

| Funcao | Responsabilidade | Arquivo sugerido |
| --- | --- | --- |
| `Write-Log` | Escrever linha com timestamp em arquivo e console | `logger.ps1` |
| `Write-ColoredLog` | Escrever mensagem com cor ANSI | `logger.ps1` |
| `Show-Banner` | Exibir banner do terminal | `banner.ps1` |
| `Show-LoadingBar` | Exibir loading visual | `spinner.ps1` |
| `Show-Spinner` | Exibir indicador de trabalho | `spinner.ps1` |
| `Test-IsAdmin` | Verificar elevacao | `admin_check.ps1` |
| `Start-AsAdmin` | Relancar script com RunAs | `admin_check.ps1` |
| `New-RunLogDirectory` | Criar pasta datada de logs | `logger.ps1` |
| `Test-LockFile` | Validar lock e PID | `logger.ps1` ou `command_runner.ps1` |
| `New-LockFile` | Criar lock da execucao | `logger.ps1` |
| `Remove-LockFile` | Remover lock com seguranca | `logger.ps1` |
| `Invoke-CommandWithLog` | Rodar comando com captura de saida | `command_runner.ps1` |
| `Write-SummaryJson` | Gravar resumo final | `command_runner.ps1` |

## Decisoes Tecnicas

- Funcoes devem aceitar parametros nomeados.
- Funcoes nao devem depender de variaveis globais implicitas.
- Runner deve ter `-DryRun`.
- Summary deve ser criado com objeto PowerShell convertido para JSON.

## Regras

- Nao executar comando real em funcao visual.
- Nao suprimir erros sem log.
- Nao remover lock se o lock nao pertence a execucao atual, salvo limpeza de lock antigo validada.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_02_funcoes_comuns_powershell.md`
- `Docs/03_arquitetura/estrategia_de_logs.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`

## Riscos

- Funcoes com estado global ficarem frageis.
- Runner executar string mal escapada.
- Summary perder detalhes de falha.

## Criterios de Aceite

- Cada funcao tem responsabilidade unica.
- Funcoes criticas possuem parametros e retorno previsiveis.
- Dry run existe para testes seguros.
