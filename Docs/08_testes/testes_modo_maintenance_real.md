# Testes do Modo Maintenance Real

## Objetivo

Validar o modo de manutencao real com foco em administrador, dry run, fila, confirmacao e logs.

## Contexto

Este modo pode executar comandos que impactam o sistema. Testes iniciais devem ser dry run.

## Casos de Teste

| ID | Caso | Resultado esperado |
| --- | --- | --- |
| TR-001 | Rodar sem admin | Bloqueia ou solicita elevacao |
| TR-002 | Rodar com admin e dry run | Simula fila sem executar manutencao |
| TR-003 | Simular falha de comando | Summary registra falha |
| TR-004 | Solicitar CHKDSK profundo e negar | `/r` nao executa |
| TR-005 | Validar logs por terminal | Arquivos criados |
| TR-006 | Validar summary | JSON valido com status |
| TR-007 | Validar terminal aberto ao final | Usuario consegue ler resultado |

## Decisoes Tecnicas

- Dry run e etapa obrigatoria antes de comandos reais.
- O teste real completo deve ser manual e autorizado.
- CHKDSK profundo pode exigir janela de manutencao dedicada.

## Regras

- Nao executar modo real completo durante documentacao.
- Nao executar `chkdsk C: /r` sem confirmacao.
- Registrar ambiente e horario dos testes reais.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md`
- `Docs/02_requisitos/matriz_de_comandos.md`
- `Docs/03_arquitetura/estrategia_de_logs.md`

## Riscos

- Comandos demorados.
- Saida de comando com encoding diferente.
- Reboot pendente alterar resultado.

## Criterios de Aceite

- Admin e dry run foram validados.
- Confirmacao de CHKDSK funciona.
- Logs e summary refletem status real ou simulado.
