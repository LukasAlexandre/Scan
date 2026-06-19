# Estrutura de Pastas do Codigo

## Objetivo

Definir a estrutura esperada do codigo futuro sem implementar scripts funcionais nesta etapa.

## Contexto

A documentacao deve permitir que o Claude Code crie os arquivos em blocos, mantendo separacao entre launchers, configuracoes, funcoes comuns, terminais, startup e logs.

## Estrutura Planejada

```text
windows-maintenance-terminal-grid/
  README.md
  install.ps1
  uninstall.ps1
  launcher.ps1
  launcher_startup_safe.ps1
  launcher_maintenance_real.ps1
  config/
    terminals.json
    visual_settings.json
    schedule_settings.json
  scripts/
    common/
      banner.ps1
      logger.ps1
      spinner.ps1
      admin_check.ps1
      monitor_layout.ps1
      command_runner.ps1
    terminals/
      analytics_dism.ps1
      scanning_sfc.ps1
      processing_chkdsk.ps1
      cleaning_optimize.ps1
    startup/
      create_scheduled_task.ps1
      remove_scheduled_task.ps1
  logs/
  assets/
    ascii/
      analytics.txt
      scanning.txt
      processing.txt
      cleaning.txt
```

## Decisoes Tecnicas

- Arquivos PowerShell em `scripts/common/` devem conter funcoes reutilizaveis.
- Arquivos em `scripts/terminals/` devem ser entradas executaveis por painel.
- Arquivos em `config/` devem ser exemplos validados antes de uso real.
- `logs/` deve ser ignoravel por versionamento em etapa futura.

## Regras

- Nao misturar documentacao e codigo funcional.
- Nao colocar logs reais dentro de `Docs/`.
- Nao hardcodar caminhos absolutos do usuario.
- Caminhos devem ser resolvidos a partir do root do projeto.

## Arquivos Relacionados

- `Docs/06_scripts_funcoes/matriz_de_scripts.md`
- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_00_baseline_organizacao_repositorio.md`

## Riscos

- Criar scripts antes das configuracoes gerar retrabalho.
- Deixar caminho absoluto quebrar portabilidade.
- Versionar logs grandes sem necessidade.

## Criterios de Aceite

- Estrutura planejada esta completa.
- Cada pasta tem responsabilidade clara.
- A criacao fisica dos scripts fica para os blocos futuros.
