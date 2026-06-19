# Divisao em Blocos

## Objetivo

Definir a sequencia oficial de implementacao DDAD para o Claude Code seguir com seguranca.

## Contexto

Cada bloco deve ser implementado, testado e revisado antes do proximo. A divisao evita misturar planejamento, visual, comandos reais e agendamento em uma unica etapa.

## Matriz dos Blocos

| Bloco | Nome | Resultado | Depende de |
| --- | --- | --- | --- |
| 00 | Baseline e organizacao do repositorio | Estrutura base, README inicial, pastas esperadas | Nenhum |
| 01 | Configuracoes base JSON | `config/*.json` documentados e validados | 00 |
| 02 | Funcoes comuns PowerShell | Logger, admin, lock, runner, summary | 01 |
| 03 | Banners, loading e logs visuais | Experiencia visual segura | 02 |
| 04 | Scripts dos terminais | Entradas por terminal | 02, 03 |
| 05 | Launcher Grid 2x2 | Abertura em Windows Terminal ou fallback | 04 |
| 06 | Modo Startup Safe | Login visual seguro | 05 |
| 07 | Modo Maintenance Real | Manutencao real controlada | 02, 04, 05 |
| 08 | Tarefa Agendada Windows | Install/uninstall de startup | 06 |
| 09 | Logs, lock file e summary | Execucao rastreavel e sem duplicidade | 02, 06, 07 |
| 10 | Testes e validacao local | Checklist de cenarios | 00-09 |
| 11 | README e documentacao final | Uso final consolidado | 10 |

## Regras Gerais para Todos os Blocos

- Nao apagar a ideia original.
- Nao executar comandos reais fora do bloco apropriado.
- Nao configurar tarefa agendada sem bloco 08.
- Nao declarar que algo funciona sem teste.
- Registrar pendencias ao final do bloco.

## Fluxo de Trabalho por Bloco

1. Ler documento do bloco em `Docs/05_blocos_implementacao/`.
2. Confirmar arquivos existentes.
3. Implementar somente o escopo.
4. Rodar testes seguros do bloco.
5. Atualizar feedback do bloco.
6. Parar antes do proximo bloco.

## Arquivos Relacionados

- `Docs/04_planejamento/roadmap_implementacao.md`
- `Docs/04_planejamento/dependencias_e_pre_requisitos.md`
- `Docs/05_blocos_implementacao/`

## Riscos

- Implementar comandos reais antes de logs e lock file.
- Fazer fallback de layout sem registrar aviso.
- Criar tarefa agendada invisivel.

## Criterios de Aceite

- Todos os blocos obrigatorios estao listados.
- Dependencias estao claras.
- Existe fluxo repetivel para o Claude Code.
