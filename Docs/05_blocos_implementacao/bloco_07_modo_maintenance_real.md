# Bloco 07 - Modo Maintenance Real

## Objetivo

Planejar e implementar `launcher_maintenance_real.ps1` para executar manutencao real sob demanda, com administrador, controle de fila, logs e resumo.

## Contexto

Este e o primeiro bloco em que comandos reais podem ser integrados. A implementacao deve ser conservadora, auditavel e confirmada pelo usuario.

## Escopo

- Validar administrador.
- Abrir os quatro terminais.
- Executar comandos reais em ordem controlada.
- Confirmar antes de `chkdsk C: /r`.
- Salvar logs e gerar `summary.json`.

## Fora de Escopo

- Rodar automaticamente no login.
- Criar tarefa agendada.
- Executar comandos em paralelo sem controle.

## Arquivos que devem ser criados ou alterados

- `launcher_maintenance_real.ps1`
- `scripts/common/admin_check.ps1`
- `scripts/common/command_runner.ps1`
- `scripts/common/logger.ps1`
- `scripts/terminals/*.ps1`

## Funcoes esperadas

- `Test-IsAdmin`
- `Start-AsAdmin`
- `Invoke-CommandWithLog`
- `Write-SummaryJson`
- `Confirm-DeepDiskCheck` ou funcao equivalente.

## Configuracoes necessarias

- Lista de comandos reais permitidos.
- Ordem de execucao.
- Flag para CHKDSK profundo.
- Caminho de logs.

## Regras tecnicas

- Exigir administrador antes de abrir execucao real.
- Registrar comando antes de executar.
- Capturar stdout, stderr e exit code.
- Se um comando falhar, registrar falha e decidir se continua com base em regra configurada.
- `chkdsk C: /r` nunca roda sem confirmacao.

## Riscos

- Comando real demorar muito.
- DISM depender de Windows Update.
- SFC retornar reparo pendente.
- CHKDSK exigir reboot.
- Defrag/Optimize consumir recurso em horario ruim.

## Passo a passo de implementacao

1. Criar `launcher_maintenance_real.ps1`.
2. Validar administrador.
3. Criar logs e lock.
4. Abrir grid.
5. Executar fila DISM, SFC, CHKDSK, Optimize.
6. Pedir confirmacao para CHKDSK profundo se solicitado.
7. Gerar `summary.json`.
8. Manter terminais abertos.

## Fluxo de teste

1. Testar sem administrador e confirmar bloqueio.
2. Testar com `-DryRun` e comandos inofensivos.
3. Testar confirmacao negativa para CHKDSK profundo.
4. Testar criacao de `summary.json`.

## Criterios de aceite

- Sem administrador, o modo real nao executa.
- Dry run funciona.
- CHKDSK profundo pede confirmacao.
- Logs e summary sao gerados.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 07. Crie launcher_maintenance_real.ps1 com validacao admin, dry run, fila controlada, logs e summary.json. Integre comandos reais somente atras de modo explicito e confirmacao para chkdsk C: /r.
```

## Feedback esperado apos implementacao

- Resultado do teste sem admin.
- Resultado do teste dry run.
- Como a fila foi implementada.
- Como o summary e preenchido.
