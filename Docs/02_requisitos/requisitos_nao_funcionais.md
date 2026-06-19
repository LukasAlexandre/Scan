# Requisitos Nao Funcionais

## Objetivo

Definir criterios de qualidade para desempenho, seguranca, compatibilidade, manutencao e experiencia de uso.

## Contexto

O projeto pode impactar boot, disco, CPU, permissao administrativa e janelas visiveis. Os requisitos nao funcionais servem para conter esses riscos.

## Requisitos

| ID | Requisito | Medida esperada |
| --- | --- | --- |
| RNF-001 | Compatibilidade Windows | Windows 10/11 |
| RNF-002 | Compatibilidade PowerShell | 5.1 minimo, 7+ desejavel |
| RNF-003 | Baixo impacto no boot | `startup_safe` sem comandos pesados |
| RNF-004 | Observabilidade | Logs com timestamp e contexto |
| RNF-005 | Reversibilidade | `uninstall.ps1` remove agendamento |
| RNF-006 | Transparencia | Comandos reais devem ser exibidos/logados |
| RNF-007 | Resiliencia | Fallback sem Windows Terminal |
| RNF-008 | Configurabilidade | JSON para terminais, visual e schedule |
| RNF-009 | Suporte a erros | Mensagens claras e exit code preservado |
| RNF-010 | Nao intrusivo | Sem janelas invisiveis em tarefa de login |

## Decisoes Tecnicas

- Usar pasta de logs por execucao para facilitar auditoria.
- Usar lock file para evitar multiplas instancias.
- Evitar dependencias externas obrigatorias.
- Preferir comandos nativos do Windows.

## Regras

- A documentacao deve diferenciar recomendacao de requisito.
- Qualquer dependencia opcional deve ter fallback.
- O sistema deve continuar legivel mesmo sem fonte customizada.

## Arquivos Relacionados

- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/08_testes/fluxo_de_testes.md`
- `Docs/09_execucao/troubleshooting.md`

## Riscos

- Politica de execucao PowerShell bloquear scripts.
- Janelas nao abrirem em sessao interativa se a tarefa for criada incorretamente.
- Fontes ausentes alterarem o alinhamento visual.

## Criterios de Aceite

- Requisitos cobrem compatibilidade, desempenho, seguranca e suporte.
- Ha criterios para ausencia de Windows Terminal e politica de execucao.
