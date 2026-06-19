# Bloco 08 - Tarefa Agendada Windows

## Objetivo

Planejar e implementar instalacao e remocao da tarefa agendada que abre o modo `startup_safe` no logon do usuario.

## Contexto

A tarefa agendada deve abrir janela visivel. Configuracoes incorretas podem fazer o processo rodar em segundo plano sem UI.

## Escopo

- Criar `install.ps1`.
- Criar `uninstall.ps1`.
- Criar `scripts/startup/create_scheduled_task.ps1`.
- Criar `scripts/startup/remove_scheduled_task.ps1`.
- Registrar configuracao da tarefa.

## Fora de Escopo

- Agendar `maintenance_real`.
- Rodar comandos pesados no logon.
- Criar tarefa invisivel.

## Arquivos que devem ser criados ou alterados

- `install.ps1`
- `uninstall.ps1`
- `scripts/startup/create_scheduled_task.ps1`
- `scripts/startup/remove_scheduled_task.ps1`
- `config/schedule_settings.json`

## Funcoes esperadas

- `New-WmtgScheduledTask`
- `Remove-WmtgScheduledTask`
- `Test-WmtgScheduledTask`

## Configuracoes necessarias

- Nome da tarefa.
- Delay no logon.
- Caminho do `launcher_startup_safe.ps1`.
- Usuario atual.
- Execucao interativa.

## Regras tecnicas

- Trigger deve ser `At logon`.
- Tarefa deve rodar quando usuario estiver logado.
- Janela deve ser visivel.
- `uninstall.ps1` deve remover a tarefa.
- Nao configurar `maintenance_real` no startup.

## Riscos

- Tarefa rodar invisivel.
- Caminho com espaco quebrar argumento.
- Tarefa exigir privilegio e falhar sem aviso.

## Passo a passo de implementacao

1. Criar script de criacao da tarefa.
2. Criar script de remocao.
3. Criar wrappers `install.ps1` e `uninstall.ps1`.
4. Validar existencia da tarefa sem executa-la.
5. Documentar comandos de instalacao.

## Fluxo de teste

1. Rodar install em ambiente controlado.
2. Verificar tarefa no Task Scheduler.
3. Confirmar acao aponta para `launcher_startup_safe.ps1`.
4. Rodar uninstall.
5. Confirmar remocao.

## Criterios de aceite

- Tarefa e criada com nome correto.
- Tarefa aponta para modo seguro.
- Tarefa e removivel.
- Nenhum comando pesado e agendado.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 08. Crie install/uninstall e scripts de tarefa agendada para abrir launcher_startup_safe.ps1 no logon em janela visivel. Nao agende maintenance_real e nao execute manutencao pesada.
```

## Feedback esperado apos implementacao

- Nome e configuracao da tarefa.
- Resultado de criacao/remocao.
- Observacoes sobre privilegios.
- Evidencia de que o alvo e startup_safe.
