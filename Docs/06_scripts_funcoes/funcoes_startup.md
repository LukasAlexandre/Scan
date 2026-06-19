# Funcoes Startup

## Objetivo

Documentar funcoes e regras para instalacao, remocao e validacao da tarefa agendada.

## Contexto

O startup automatico deve abrir o modo seguro no logon do usuario. Nao deve rodar comandos pesados nem processos invisiveis.

## Funcoes Planejadas

| Funcao | Responsabilidade |
| --- | --- |
| `New-WmtgScheduledTask` | Criar tarefa de logon |
| `Remove-WmtgScheduledTask` | Remover tarefa |
| `Test-WmtgScheduledTask` | Verificar se tarefa existe |
| `Get-WmtgScheduledTaskConfig` | Ler configuracao de schedule |
| `Write-InstallLog` | Registrar instalacao/remocao |

## Decisoes Tecnicas

- Tarefa deve apontar para `launcher_startup_safe.ps1`.
- O trigger deve ser logon do usuario.
- O processo deve rodar em sessao interativa para exibir janela.
- `uninstall.ps1` deve tolerar tarefa ausente.

## Regras

- Nao agendar `launcher_maintenance_real.ps1`.
- Nao usar modo que esconda a janela do usuario.
- Nao criar multiplas tarefas com nomes diferentes.
- Registrar caminho exato configurado.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_08_tarefa_agendada_windows.md`
- `Docs/07_configuracoes/scheduled_task_config.md`
- `Docs/09_execucao/como_instalar.md`

## Riscos

- Tarefa invisivel.
- Delay nao aplicado.
- Remocao incompleta.

## Criterios de Aceite

- Funcoes cobrem criar, remover e validar.
- O alvo da tarefa e somente startup safe.
- Install e uninstall sao auditaveis.
