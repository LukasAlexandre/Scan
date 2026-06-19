# Testes do Modo Startup Safe

## Objetivo

Validar o modo seguro de login sem executar manutencao pesada.

## Contexto

Esse modo deve ser leve, visual e rastreavel. Ele e o unico modo permitido para tarefa agendada de logon.

## Casos de Teste

| ID | Caso | Resultado esperado |
| --- | --- | --- |
| TS-001 | Rodar launcher manualmente | Grid abre em modo seguro |
| TS-002 | Validar delay | Execucao aguarda tempo configurado |
| TS-003 | Validar logs | Pasta datada e logs sao criados |
| TS-004 | Validar bloqueio DISM | DISM nao executa |
| TS-005 | Validar bloqueio SFC | SFC nao executa |
| TS-006 | Validar bloqueio CHKDSK profundo | `/r` nao executa |
| TS-007 | Validar bloqueio defrag | Defrag nao executa |
| TS-008 | Validar lock duplicado | Segunda execucao aborta ou avisa |

## Decisoes Tecnicas

- Os testes devem usar ambiente normal, sem admin obrigatorio.
- Pode usar logs e dry run para confirmar bloqueios.

## Regras

- Nao habilitar manutencao pesada para "ver se funciona" neste modo.
- Se uma configuracao tentar liberar comando pesado, o launcher deve bloquear.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_06_modo_startup_safe.md`
- `Docs/03_arquitetura/modos_de_operacao.md`
- `Docs/07_configuracoes/scheduled_task_config.md`

## Riscos

- Tarefa de login rodar em momento inoportuno.
- Lock antigo impedir teste.
- Usuario confundir checks leves com manutencao completa.

## Criterios de Aceite

- Startup safe abre visual e cria logs.
- Comandos pesados permanecem bloqueados.
- Lock funciona.
