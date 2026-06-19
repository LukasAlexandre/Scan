# Requisitos Funcionais

## Objetivo

Listar os comportamentos funcionais que a implementacao futura deve entregar.

## Contexto

O sistema sera implementado em PowerShell com arquivos JSON de configuracao. A documentacao deve permitir que os scripts sejam criados em blocos sem perda de rastreabilidade.

## Requisitos

| ID | Requisito | Prioridade | Observacao |
| --- | --- | --- | --- |
| RF-001 | Abrir quatro terminais em layout 2x2 | Alta | Preferir Windows Terminal |
| RF-002 | Executar modo `startup_safe` sem comandos pesados | Alta | Deve rodar no login |
| RF-003 | Executar modo `maintenance_real` sob demanda | Alta | Exige administrador |
| RF-004 | Exibir banner por terminal | Media | ASCII em arquivos ou funcao |
| RF-005 | Exibir loading progressivo | Media | Nao deve simular resultado tecnico |
| RF-006 | Gravar logs por terminal | Alta | Um arquivo por fluxo |
| RF-007 | Gerar `summary.json` | Alta | Necessario no modo real |
| RF-008 | Proteger contra execucao duplicada | Alta | Lock file em `%LOCALAPPDATA%` |
| RF-009 | Confirmar `chkdsk C: /r` antes de agendar | Alta | Nunca automatico |
| RF-010 | Manter terminal aberto ao final | Media | Facilita leitura manual |
| RF-011 | Instalar tarefa agendada via `install.ps1` | Media | Somente em bloco futuro |
| RF-012 | Remover tarefa agendada via `uninstall.ps1` | Media | Reversibilidade |

## Decisoes Tecnicas

- Requisitos de execucao real devem depender do modo selecionado.
- Comandos devem ser definidos em configuracao, mas validados pelo script.
- Exit codes devem ser preservados e refletidos no resumo.

## Regras

- Requisitos de manutencao real nao podem ser atendidos no modo seguro.
- A abertura visual do grid pode ocorrer antes da execucao real dos comandos.
- A fila de execucao deve evitar sobrecarga.

## Arquivos Relacionados

- `Docs/02_requisitos/matriz_de_comandos.md`
- `Docs/03_arquitetura/arquitetura_de_execucao.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`

## Riscos

- Implementar todos os comandos em paralelo por engano.
- Nao propagar falhas de comando para o resumo.
- Nao tratar ausencia de `wt.exe`.

## Criterios de Aceite

- Cada requisito tem prioridade e observacao.
- Os requisitos cobrem visual, execucao, logs, lock e instalacao.
- O modo seguro fica protegido contra manutencao pesada.
