# Funcoes Launcher

## Objetivo

Documentar as funcoes esperadas para launchers e layout 2x2.

## Contexto

Launchers coordenam modo, logs, lock, grid e repasse de parametros. Eles nao devem conter logica profunda dos comandos de manutencao.

## Funcoes Planejadas

| Funcao | Responsabilidade |
| --- | --- |
| `Resolve-ProjectRoot` | Encontrar root do projeto a partir do script atual |
| `Read-ProjectConfig` | Carregar e validar JSON |
| `Test-WindowsTerminalAvailable` | Detectar `wt.exe` |
| `Start-TerminalGrid` | Abrir quatro paineis com scripts |
| `Start-TerminalFallbackWindows` | Abrir quatro janelas separadas se necessario |
| `Build-TerminalCommand` | Montar comando de cada painel com quoting seguro |
| `Get-PrimaryMonitorLayout` | Obter area do monitor principal para fallback |

## Decisoes Tecnicas

- `launcher.ps1` deve aceitar `-Mode`.
- `launcher_startup_safe.ps1` e `launcher_maintenance_real.ps1` podem chamar o launcher generico.
- Fallback deve ser registrado no log.

## Regras

- Modo padrao deve ser seguro.
- Launchers devem criar pasta de log antes de abrir terminais.
- Caminhos com espaco devem ser tratados.
- Falha ao abrir grid deve abortar modo real antes de comandos.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_05_launcher_grid_2x2.md`
- `Docs/03_arquitetura/estrategia_de_layout_terminal.md`
- `Docs/07_configuracoes/visual_settings_json.md`

## Riscos

- Quoting incorreto no `wt.exe`.
- Fallback incompleto em monitores com escala.
- Launcher iniciar modo real sem preparacao visual.

## Criterios de Aceite

- Funcoes separam montagem de comando, deteccao e execucao.
- O modo e repassado para cada terminal.
- Existe fallback para ausencia de Windows Terminal.
