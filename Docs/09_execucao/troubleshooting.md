# Troubleshooting

## Objetivo

Listar problemas comuns e a resposta recomendada.

## Contexto

O projeto usa PowerShell, Windows Terminal, tarefa agendada e comandos administrativos. Falhas de permissao e ambiente sao esperadas em algumas maquinas.

## Problemas e Solucoes

| Problema | Causa provavel | Acao recomendada |
| --- | --- | --- |
| Script bloqueado | Politica de execucao | Usar `-ExecutionPolicy Bypass` no comando planejado |
| Grid nao abre | `wt.exe` ausente ou quoting falhou | Testar fallback e revisar log do launcher |
| Modo real nao inicia | Sem administrador | Abrir PowerShell como admin ou permitir RunAs |
| Terminal fecha rapido | `keepTerminalOpen` falso ou erro nao tratado | Revisar config visual e logs |
| Startup nao aparece | Tarefa invisivel ou usuario nao logado | Revisar configuracao da tarefa |
| Segunda execucao bloqueada | Lock file ativo | Verificar processo e limpar lock antigo apenas se seguro |
| Sem logs | Caminho invalido ou permissao | Validar `logs/` e root do projeto |
| CHKDSK profundo nao roda | Confirmacao negada ou volume em uso | Verificar log e agendamento para reboot |

## Decisoes Tecnicas

- Logs sao a primeira fonte de diagnostico.
- Fallback sem Windows Terminal deve ser tratado como degradacao, nao falha total.
- Lock antigo deve ser limpo somente apos validar PID.

## Regras

- Nao resolver falhas rodando comandos pesados sem entender causa.
- Nao apagar lock ativo de processo em execucao.
- Nao alterar Task Scheduler manualmente sem registrar o ajuste.

## Arquivos Relacionados

- `Docs/03_arquitetura/estrategia_de_logs.md`
- `Docs/05_blocos_implementacao/bloco_09_logs_lockfile_summary.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`

## Riscos

- Limpar lock incorretamente permitir duplicidade.
- Forcar admin sem explicar ao usuario.
- Confundir falha visual com falha de manutencao.

## Criterios de Aceite

- Problemas comuns tem causa e acao.
- Solucoes mantem seguranca operacional.
