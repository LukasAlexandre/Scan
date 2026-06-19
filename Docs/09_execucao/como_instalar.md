# Como Instalar

## Objetivo

Explicar como a instalacao futura deve ser executada quando os scripts estiverem implementados.

## Contexto

A instalacao deve criar a tarefa agendada que abre o modo `startup_safe` no logon. Ela nao deve instalar o modo `maintenance_real` como tarefa automatica.

## Comando Planejado

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## O que o comando deve fazer

- Validar que esta no root do projeto.
- Carregar configuracao de schedule.
- Criar tarefa agendada `WindowsMaintenanceTerminalGrid`.
- Apontar a tarefa para `launcher_startup_safe.ps1`.
- Registrar log de instalacao.

## Decisoes Tecnicas

- `install.ps1` deve ser reversivel por `uninstall.ps1`.
- Tarefa deve rodar em sessao interativa.
- Delay de login deve vir de `config/schedule_settings.json`.

## Regras

- Nao agendar `launcher_maintenance_real.ps1`.
- Nao executar DISM, SFC, CHKDSK ou defrag durante instalacao.
- Informar se PowerShell bloquear execucao.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_08_tarefa_agendada_windows.md`
- `Docs/07_configuracoes/scheduled_task_config.md`
- `Docs/09_execucao/como_remover.md`

## Riscos

- Politica de execucao impedir script.
- Falta de permissao para criar tarefa.
- Tarefa invisivel se configurada errado.

## Criterios de Aceite

- Tarefa criada aponta para startup safe.
- Instalacao gera log.
- Usuario recebe orientacao para remover.
