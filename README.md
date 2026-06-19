# Windows Maintenance Terminal Grid

## Objetivo

Projeto em fase de implementacao controlada por DDAD para criar um utilitario Windows que abre quatro terminais em layout 2x2, com visual tecnico, banners, loading, logs e modos seguros de manutencao.

## Status Atual

Bloco 00 - baseline e organizacao do repositorio.

Neste bloco foram preparados apenas diretorios base e placeholders seguros. Scripts reais, launchers funcionais, configuracoes JSON e tarefas agendadas ainda nao foram implementados.

## Modos de Operacao

| Modo | Uso | Comandos pesados |
| --- | --- | --- |
| `startup_safe` | Abrir no login com visual e checks leves | Nao |
| `maintenance_real` | Manutencao real manual | Sim, com administrador |
| `visual_only` | Testar visual e logs | Nao |

## Estrutura da Documentacao

- `Docs/00_ideia_original/` - ideia base preservada.
- `Docs/01_visao_geral/` - visao, objetivo e premissas.
- `Docs/02_requisitos/` - requisitos, seguranca e matriz de comandos.
- `Docs/03_arquitetura/` - arquitetura, modos, logs e layout.
- `Docs/04_planejamento/` - roadmap e divisao em blocos.
- `Docs/05_blocos_implementacao/` - prompts e escopos por bloco.
- `Docs/06_scripts_funcoes/` - matriz de scripts e funcoes esperadas.
- `Docs/07_configuracoes/` - exemplos documentados de JSON.
- `Docs/08_testes/` - fluxo de testes e criterios de aceite.
- `Docs/09_execucao/` - guias de instalacao, execucao e remocao.
- `Docs/10_feedback/` - feedback da organizacao.

## Como Instalar

Implementacao futura, ainda nao disponivel no Bloco 00:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## Como Executar Modo Seguro

Implementacao futura, ainda nao disponivel no Bloco 00:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\launcher_startup_safe.ps1
```

## Como Executar Manutencao Real

Implementacao futura, ainda nao disponivel no Bloco 00. Quando implementado, devera exigir administrador:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\launcher_maintenance_real.ps1
```

Para validar sem executar comandos reais:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\launcher_maintenance_real.ps1 -DryRun
```

## Como Remover

Implementacao futura, ainda nao disponivel no Bloco 00:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## Seguranca

- O modo `startup_safe` nao deve executar DISM, SFC, CHKDSK `/r` ou defrag.
- O modo `maintenance_real` deve exigir administrador.
- `chkdsk C: /r` deve pedir confirmacao antes de qualquer agendamento.
- Logs visuais nao podem declarar reparos falsos.
- Lock file deve impedir execucao duplicada.

## Logs

Estrutura planejada:

```text
logs/YYYY-MM-DD_HH-mm-ss/
  analytics_dism_restorehealth.log
  scanning_sfc_scannow.log
  processing_chkdsk.log
  cleaning_optimize_drive.log
  launcher.log
  summary.json
```

## Proximos Passos

Seguir para o Bloco 01 - Configuracoes base JSON, descrito em `Docs/05_blocos_implementacao/bloco_01_configuracoes_base_json.md`.
