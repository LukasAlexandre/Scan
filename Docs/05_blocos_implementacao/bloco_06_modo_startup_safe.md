# Bloco 06 - Modo Startup Safe

## Objetivo

Planejar e implementar `launcher_startup_safe.ps1`, modo seguro para abrir o grid no login sem executar manutencao pesada.

## Contexto

O usuario quer a experiencia visual ao iniciar o Windows. Esse modo deve preservar desempenho do boot e bloquear comandos como DISM, SFC, CHKDSK `/r` e defrag.

## Escopo

- Criar launcher especifico de startup.
- Aguardar delay configurado.
- Criar logs.
- Criar lock file.
- Abrir quatro terminais.
- Executar apenas visual e checks leves.

## Fora de Escopo

- Executar comandos reais pesados.
- Instalar tarefa agendada.
- Solicitar elevacao obrigatoria.

## Arquivos que devem ser criados ou alterados

- `launcher_startup_safe.ps1`
- `config/schedule_settings.json`
- `scripts/common/logger.ps1`
- `scripts/common/command_runner.ps1`

## Funcoes esperadas

- `New-RunLogDirectory`
- `Test-LockFile`
- `New-LockFile`
- `Remove-LockFile`
- `Start-TerminalGrid`

## Configuracoes necessarias

- `delayAfterLoginSeconds`
- `defaultMode`
- `keepTerminalOpen`
- `lockFilePath`
- `startupSafeChecks`

## Regras tecnicas

- Bloquear DISM, SFC, CHKDSK `/r` e defrag.
- `chkdsk C: /scan` so pode rodar se explicitamente configurado como leve.
- Tarefa de login deve abrir janela visivel em etapa futura.
- Lock file deve impedir duplicidade.

## Riscos

- Startup atrasar o login.
- Configuracao indevida liberar comando pesado.
- Lock antigo bloquear execucao legitima.

## Passo a passo de implementacao

1. Criar `launcher_startup_safe.ps1`.
2. Carregar `schedule_settings.json`.
3. Aguardar delay.
4. Criar pasta de logs.
5. Criar lock file.
6. Chamar `launcher.ps1 -Mode startup_safe`.
7. Garantir limpeza de lock ao final.
8. Registrar feedback.

## Fluxo de teste

1. Rodar manualmente `launcher_startup_safe.ps1`.
2. Confirmar delay.
3. Confirmar abertura visual.
4. Confirmar logs.
5. Confirmar que nenhum comando pesado foi executado.

## Criterios de aceite

- Startup safe abre grid.
- Logs sao criados.
- Lock impede duplicidade.
- Nenhum comando pesado roda automaticamente.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 06. Crie launcher_startup_safe.ps1 com delay configuravel, logs e lock file. Ele deve abrir o grid em modo startup_safe e bloquear comandos pesados. Nao crie tarefa agendada ainda.
```

## Feedback esperado apos implementacao

- Delay configurado.
- Logs gerados.
- Resultado de teste manual.
- Confirmacao de bloqueio de comandos pesados.
