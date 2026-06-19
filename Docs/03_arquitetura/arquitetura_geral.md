# Arquitetura Geral

## Objetivo

Definir a organizacao tecnica do projeto, os componentes principais e a responsabilidade de cada grupo de arquivos.

## Contexto

O projeto deve ser implementado em PowerShell, com configuracoes JSON e documentacao DDAD. A arquitetura separa launchers, scripts de terminais, funcoes comuns, configuracoes, logs e instalacao.

## Componentes

| Componente | Responsabilidade |
| --- | --- |
| Launchers | Escolher modo, validar ambiente e abrir grid |
| Scripts de terminais | Exibir visual, executar fluxo do terminal e gravar log |
| Funcoes comuns | Logger, admin, banner, spinner, lock e command runner |
| Configuracoes JSON | Declarar terminais, visual e schedule |
| Logs | Registrar saida e resumo da execucao |
| Startup scripts | Criar/remover tarefa agendada |
| README | Orientar uso final |

## Fluxo de Alto Nivel

```text
Usuario ou tarefa agendada
  -> launcher do modo
  -> validacao de ambiente
  -> lock file
  -> pasta de logs
  -> Windows Terminal 2x2
  -> scripts dos terminais
  -> logs por terminal
  -> summary.json
```

## Decisoes Tecnicas

- `launcher.ps1` sera entrada generica.
- `launcher_startup_safe.ps1` sera entrada segura de login.
- `launcher_maintenance_real.ps1` sera entrada manual para manutencao real.
- Scripts comuns devem ser carregados por dot-sourcing.
- Configuracoes devem ser lidas e validadas antes da execucao.

## Regras

- Launchers nao devem conter toda a logica dos terminais.
- Scripts de terminais nao devem criar tarefa agendada.
- Funcoes comuns nao devem depender de estado global nao documentado.
- Logs devem ser criados antes de comandos reais.

## Arquivos Relacionados

- `Docs/03_arquitetura/arquitetura_de_execucao.md`
- `Docs/03_arquitetura/estrutura_de_pastas_codigo.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`

## Riscos

- Misturar responsabilidades entre launcher e terminal.
- Duplicar funcoes em varios scripts.
- Criar configuracao JSON sem validacao.

## Criterios de Aceite

- Componentes e responsabilidades estao claros.
- Existe fluxo de alto nivel.
- A arquitetura suporta modo seguro e modo real.
