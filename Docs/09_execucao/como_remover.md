# Como Remover

## Objetivo

Explicar como remover a tarefa agendada e desfazer a instalacao automatica.

## Contexto

A remocao deve ser simples e segura. Ela nao deve apagar logs historicos sem permissao explicita.

## Comando Planejado

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## O que o comando deve fazer

- Remover tarefa agendada `WindowsMaintenanceTerminalGrid`.
- Registrar log de remocao.
- Informar se a tarefa nao existir.
- Preservar documentacao e logs, salvo opcao explicita futura.

## Decisoes Tecnicas

- `uninstall.ps1` deve ser idempotente.
- A remocao deve tolerar tarefa ausente.
- Lock file antigo pode ser removido se nao houver processo ativo.

## Regras

- Nao apagar a pasta do projeto.
- Nao apagar logs por padrao.
- Nao alterar configuracoes do Windows Terminal.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_08_tarefa_agendada_windows.md`
- `Docs/06_scripts_funcoes/funcoes_startup.md`
- `Docs/08_testes/fluxo_de_testes.md`

## Riscos

- Falta de permissao para remover tarefa.
- Tarefa com nome diferente ficar sobrando.
- Usuario esperar remocao completa de arquivos locais.

## Criterios de Aceite

- Tarefa removida.
- Comando pode ser executado mais de uma vez.
- Logs historicos permanecem preservados.
