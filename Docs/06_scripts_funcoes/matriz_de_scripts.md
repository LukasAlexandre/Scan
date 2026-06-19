# Matriz de Scripts

## Objetivo

Listar todos os scripts esperados, sua funcao, modo de uso, necessidade de administrador, geracao de logs e observacoes de seguranca.

## Contexto

Esta matriz serve como inventario tecnico para a implementacao futura. Nenhum script funcional foi criado nesta etapa documental.

## Matriz

| Script | Funcao | Modo | Precisa Admin | Gera Log | Observacao |
| --- | --- | --- | --- | --- | --- |
| `install.ps1` | Instalar tarefa agendada segura | Instalacao | Sim/recomendado | Sim | Deve apontar apenas para `launcher_startup_safe.ps1` |
| `uninstall.ps1` | Remover tarefa agendada | Remocao | Sim/recomendado | Sim | Deve ser reversivel |
| `launcher.ps1` | Abrir grid 2x2 generico | `visual_only`, `startup_safe`, `maintenance_real` | Depende do modo | Sim | Modo padrao deve ser seguro |
| `launcher_startup_safe.ps1` | Abrir grid no login com checks leves | `startup_safe` | Nao obrigatorio | Sim | Nao executa comandos pesados |
| `launcher_maintenance_real.ps1` | Rodar manutencao real sob demanda | `maintenance_real` | Sim | Sim | Exige admin e fila controlada |
| `scripts/common/banner.ps1` | Exibir banners ASCII | Todos | Nao | Opcional | Visual apenas |
| `scripts/common/logger.ps1` | Criar logs e escrever mensagens | Todos | Nao | Sim | Base para rastreabilidade |
| `scripts/common/spinner.ps1` | Loading, spinner e digitacao | Todos | Nao | Opcional | Nao simula resultado tecnico |
| `scripts/common/admin_check.ps1` | Validar e solicitar elevacao | `maintenance_real`, install | Sim para elevacao | Sim | Evitar loop de RunAs |
| `scripts/common/monitor_layout.ps1` | Detectar monitor e fallback de janelas | Launchers | Nao | Sim | Usado se `wt.exe` falhar |
| `scripts/common/command_runner.ps1` | Executar comandos com log e exit code | `maintenance_real`, dry run | Sim para comandos reais | Sim | Deve suportar dry run |
| `scripts/terminals/analytics_dism.ps1` | Terminal DISM | `visual_only`, `startup_safe`, `maintenance_real` | Sim no real | Sim | DISM bloqueado no startup |
| `scripts/terminals/scanning_sfc.ps1` | Terminal SFC | `visual_only`, `startup_safe`, `maintenance_real` | Sim no real | Sim | SFC bloqueado no startup |
| `scripts/terminals/processing_chkdsk.ps1` | Terminal CHKDSK | `visual_only`, `startup_safe`, `maintenance_real` | Sim para profundo | Sim | `/r` exige confirmacao |
| `scripts/terminals/cleaning_optimize.ps1` | Terminal Optimize Drive | `visual_only`, `startup_safe`, `maintenance_real` | Sim no real | Sim | Defrag bloqueado no startup |
| `scripts/startup/create_scheduled_task.ps1` | Criar tarefa de logon | Instalacao | Sim/recomendado | Sim | Janela visivel, usuario logado |
| `scripts/startup/remove_scheduled_task.ps1` | Remover tarefa de logon | Remocao | Sim/recomendado | Sim | Deve tolerar tarefa ausente |

## Decisoes Tecnicas

- Scripts comuns devem ser reutilizados por launchers e terminais.
- Scripts de terminal recebem modo por parametro.
- Scripts de startup nao executam manutencao; apenas configuram agendamento.

## Regras

- Nenhum script deve executar manutencao real sem modo explicito.
- Scripts devem registrar o que pretendem fazer antes de fazer.
- Scripts de instalacao devem ser reversiveis.

## Arquivos Relacionados

- `Docs/03_arquitetura/estrutura_de_pastas_codigo.md`
- `Docs/05_blocos_implementacao/`
- `Docs/08_testes/checklist_de_validacao.md`

## Riscos

- Um script comum alterar comportamento de todos os modos.
- Falta de dry run dificultar testes seguros.
- Admin check mal feito causar loop.

## Criterios de Aceite

- Todos os scripts obrigatorios estao listados.
- A necessidade de administrador esta clara.
- Observacoes bloqueiam comandos pesados no startup.
