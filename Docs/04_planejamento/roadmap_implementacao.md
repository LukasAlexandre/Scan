# Roadmap de Implementacao

## Objetivo

Organizar a implementacao futura do Windows Maintenance Terminal Grid em fases pequenas, testaveis e seguras.

## Contexto

O projeto combina documentacao, configuracao, PowerShell, Windows Terminal, tarefa agendada, logs e comandos de manutencao. O roadmap evita que comandos reais sejam implementados antes das protecoes.

## Fases

| Fase | Blocos | Resultado esperado |
| --- | --- | --- |
| Fundacao | 00, 01 | Repositorio organizado e JSON planejado |
| Base PowerShell | 02, 03 | Funcoes comuns, banners, loading e logs visuais |
| Terminais e layout | 04, 05 | Scripts por terminal e grid 2x2 |
| Modos | 06, 07 | Startup seguro e manutencao real controlada |
| Integracao Windows | 08, 09 | Tarefa agendada, lock file, logs e summary |
| Validacao | 10, 11 | Testes locais e README final |

## Decisoes Tecnicas

- Implementar seguranca antes dos comandos reais.
- Testar visual em modo seguro antes do modo real.
- Criar configuracoes JSON antes dos launchers.
- Criar logs e lock antes de agendamento.

## Regras

- Nenhum bloco deve executar manutencao real sem estar explicitamente no escopo.
- Cada bloco deve deixar feedback em Markdown.
- Cada bloco deve indicar arquivos criados e alterados.
- Cada bloco deve ter teste local manual ou automatizado.

## Arquivos Relacionados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/`
- `Docs/08_testes/fluxo_de_testes.md`

## Riscos

- Pular blocos de seguranca e chegar cedo demais em comandos reais.
- Criar launchers antes da configuracao e duplicar informacao.
- Agendar startup antes de validar logs e lock.

## Criterios de Aceite

- Roadmap cobre todos os 12 blocos.
- A ordem protege o sistema antes da manutencao real.
- Cada fase tem entregavel claro.
