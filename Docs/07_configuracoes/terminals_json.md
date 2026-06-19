# terminals.json

## Objetivo

Documentar o exemplo planejado para `config/terminals.json`.

## Contexto

Este JSON descreve os quatro terminais, comandos planejados, scripts e flags por modo. Ele nao executa nada sozinho.

## Exemplo Documentado

```json
{
  "defaultMode": "startup_safe",
  "terminalEngine": "windows_terminal",
  "layout": "grid_2x2",
  "monitor": "primary",
  "delayAfterLoginSeconds": 30,
  "terminals": [
    {
      "id": "analytics",
      "title": "ANALYTICS - DISM RESTOREHEALTH",
      "banner": "ANALYTICS",
      "colorName": "green",
      "ansiColor": "\\u001b[32m",
      "script": "scripts/terminals/analytics_dism.ps1",
      "command": {
        "file": "DISM.exe",
        "args": ["/Online", "/Cleanup-Image", "/RestoreHealth"]
      },
      "autoRunInStartupSafe": false,
      "autoRunInMaintenanceReal": true
    },
    {
      "id": "scanning",
      "title": "SCANNING - SFC SCANNOW",
      "banner": "SCANNING",
      "colorName": "blue",
      "ansiColor": "\\u001b[34m",
      "script": "scripts/terminals/scanning_sfc.ps1",
      "command": {
        "file": "sfc.exe",
        "args": ["/scannow"]
      },
      "autoRunInStartupSafe": false,
      "autoRunInMaintenanceReal": true
    },
    {
      "id": "processing",
      "title": "PROCESSING - CHKDSK",
      "banner": "PROCESSING",
      "colorName": "red",
      "ansiColor": "\\u001b[31m",
      "script": "scripts/terminals/processing_chkdsk.ps1",
      "startupCommand": {
        "file": "chkdsk.exe",
        "args": ["C:", "/scan"]
      },
      "deepCommand": {
        "file": "chkdsk.exe",
        "args": ["C:", "/r"]
      },
      "autoRunInStartupSafe": false,
      "autoRunInMaintenanceReal": true,
      "requiresConfirmationForDeep": true
    },
    {
      "id": "cleaning",
      "title": "CLEANING - DRIVE OPTIMIZATION",
      "banner": "CLEANING",
      "colorName": "orange",
      "ansiColor": "\\u001b[38;5;208m",
      "script": "scripts/terminals/cleaning_optimize.ps1",
      "command": {
        "file": "defrag.exe",
        "args": ["C:", "/O", "/U", "/V"]
      },
      "autoRunInStartupSafe": false,
      "autoRunInMaintenanceReal": true
    }
  ]
}
```

## Decisoes Tecnicas

- Comandos sao separados em `file` e `args` para evitar problemas de parsing.
- Startup safe vem como modo padrao.
- CHKDSK profundo tem campo de confirmacao.

## Regras

- JSON real nao deve conter comentarios.
- DISM, SFC e defrag ficam bloqueados no startup.
- `deepCommand` nao deve ser usado sem confirmacao.

## Arquivos Relacionados

- `Docs/02_requisitos/matriz_de_comandos.md`
- `Docs/05_blocos_implementacao/bloco_01_configuracoes_base_json.md`
- `Docs/06_scripts_funcoes/funcoes_terminais.md`

## Riscos

- Erro de escape em ANSI.
- Comando em string unica dificultar execucao segura.
- Alteracao manual liberar comando pesado.

## Criterios de Aceite

- Exemplo tem os quatro terminais.
- Campos criticos estao presentes.
- Flags de startup seguro estao conservadoras.
