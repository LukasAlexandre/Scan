# Fluxo de Testes

## Objetivo

Definir o roteiro de validacao local do Windows Maintenance Terminal Grid.

## Contexto

Os testes devem priorizar dry run e modo visual seguro antes de qualquer manutencao real. Cada cenario deve registrar resultado, logs e pendencias.

## Cenario 01 - Organizacao Base

### Objetivo

Validar se a estrutura do projeto foi criada.

### Passos

1. Listar arquivos do repositorio.
2. Confirmar `README.md`.
3. Confirmar `Docs/`.
4. Confirmar `config/`, `scripts/`, `assets/` e `logs/` apos Bloco 00.

### Criterios de aceite

- Estrutura esperada existe.
- Ideia original continua preservada.
- Nenhum comando pesado foi executado.

## Cenario 02 - Modo Visual Seguro

### Objetivo

Validar se os quatro terminais abrem sem rodar comandos pesados.

### Passos

1. Rodar `launcher.ps1 -Mode visual_only`.
2. Rodar `launcher_startup_safe.ps1`.
3. Verificar banners, cores e loading.
4. Conferir logs.

### Criterios de aceite

- Quatro areas visuais aparecem.
- Logs indicam modo seguro.
- DISM, SFC, CHKDSK `/r` e defrag nao aparecem como executados.

## Cenario 03 - Modo Manutencao Real

### Objetivo

Validar se o modo real pede administrador e executa comandos controlados.

### Passos

1. Rodar sem administrador e confirmar bloqueio.
2. Rodar com `-DryRun` como administrador.
3. Verificar fila planejada.
4. Verificar `summary.json`.

### Criterios de aceite

- Sem admin, o modo real aborta.
- Com dry run, nenhum comando real e executado.
- Summary registra comandos simulados.

## Cenario 04 - CHKDSK Profundo

### Objetivo

Validar se `chkdsk C: /r` pede confirmacao antes de agendar.

### Passos

1. Solicitar modo profundo em dry run.
2. Responder negativamente.
3. Confirmar que comando foi ignorado.
4. Responder positivamente somente em ambiente controlado.

### Criterios de aceite

- Sem confirmacao, `/r` nao executa.
- Log registra decisao do usuario.

## Cenario 05 - Logs

### Objetivo

Validar criacao de logs por terminal.

### Passos

1. Rodar modo seguro.
2. Abrir pasta `logs/YYYY-MM-DD_HH-mm-ss/`.
3. Conferir arquivos por terminal.
4. Conferir `launcher.log`.

### Criterios de aceite

- Logs existem.
- Linhas possuem timestamp.
- Mensagens visuais estao identificadas.

## Cenario 06 - Summary JSON

### Objetivo

Validar resumo final.

### Passos

1. Rodar fluxo dry run do modo real.
2. Abrir `summary.json`.
3. Validar `startedAt`, `finishedAt`, `mode`, `commands` e `exitCode`.

### Criterios de aceite

- JSON e valido.
- Comandos possuem status.
- Falhas simuladas aparecem no resumo.

## Cenario 07 - Startup Automatico

### Objetivo

Validar se a tarefa agendada abre no login.

### Passos

1. Rodar `install.ps1`.
2. Conferir tarefa no Task Scheduler.
3. Fazer logoff/logon ou executar trigger manual controlado.
4. Confirmar que abre `startup_safe`.

### Criterios de aceite

- Tarefa existe.
- Janela e visivel.
- Modo seguro e usado.

## Cenario 08 - Uninstall

### Objetivo

Validar remocao.

### Passos

1. Rodar `uninstall.ps1`.
2. Conferir ausencia da tarefa.
3. Confirmar que logs historicos nao foram apagados sem permissao.

### Criterios de aceite

- Tarefa removida.
- Projeto permanece intacto.

## Decisoes Tecnicas

- Dry run e obrigatorio antes de comandos reais.
- Logs sao criterio de aceite, nao apenas efeito colateral.
- Startup automatico deve ser testado apos validacao manual.

## Regras

- Nao executar CHKDSK profundo sem confirmacao.
- Nao considerar teste aprovado se nao houver log.
- Registrar ambiente do teste.

## Arquivos Relacionados

- `Docs/08_testes/checklist_de_validacao.md`
- `Docs/08_testes/testes_modo_startup_safe.md`
- `Docs/08_testes/testes_modo_maintenance_real.md`

## Riscos

- Confundir dry run com execucao real.
- Testar agendamento em sessao nao interativa.
- Nao validar fallback sem `wt.exe`.
