# visual_settings.json

## Objetivo

Documentar o exemplo planejado para `config/visual_settings.json`.

## Contexto

Configuracoes visuais devem ser ajustaveis sem alterar scripts. O visual e importante, mas nao pode mascarar resultados tecnicos.

## Exemplo Documentado

```json
{
  "fontFace": "Cascadia Mono",
  "fontSize": 13,
  "sessionZoomOutSteps": 5,
  "sessionZoomDelayMilliseconds": 2500,
  "opacity": 92,
  "theme": "dark",
  "keepTerminalOpen": true,
  "loading": {
    "enabled": true,
    "stepPercent": 10,
    "delayMilliseconds": 120,
    "label": "Preparing visual diagnostics"
  },
  "typewriter": {
    "enabled": true,
    "delayMilliseconds": 8
  },
  "colors": {
    "analytics": "\\u001b[32m",
    "scanning": "\\u001b[34m",
    "processing": "\\u001b[31m",
    "cleaning": "\\u001b[38;5;208m",
    "reset": "\\u001b[0m"
  },
  "banners": {
    "analytics": "assets/ascii/analytics.txt",
    "scanning": "assets/ascii/scanning.txt",
    "processing": "assets/ascii/processing.txt",
    "cleaning": "assets/ascii/cleaning.txt"
  }
}
```

## Decisoes Tecnicas

- Visual deve ser configuravel por terminal.
- `sessionZoomOutSteps` aplica o equivalente a pressionar `Ctrl+Minus`
  em cada pane apos a grade 2x2 abrir no Windows Terminal, sem alterar
  configuracoes globais do aplicativo.
- `sessionZoomDelayMilliseconds` aguarda a montagem do grid terminar antes
  de navegar entre panes para aplicar zoom, evitando corrida com os splits.
- Loading deve ter texto que indique preparacao visual.
- `keepTerminalOpen` evita fechamento antes de leitura.

## Regras

- Nao usar loading visual como progresso real do comando.
- Nao depender da fonte para funcionamento.
- Nao alterar `settings.json` global do Windows Terminal para resolver zoom
  visual de uma sessao do projeto.
- ANSI deve ter reset ao final.

## Arquivos Relacionados

- `Docs/02_requisitos/requisitos_visuais.md`
- `Docs/05_blocos_implementacao/bloco_03_banners_loading_logs_visuais.md`
- `Docs/03_arquitetura/estrategia_de_layout_terminal.md`

## Riscos

- Atrasos visuais ficarem excessivos.
- Cor sem reset afetar mensagens seguintes.
- Banner quebrar em largura pequena.

## Criterios de Aceite

- Exemplo cobre fonte, loading, typewriter, cores e banners.
- Configuracao nao sugere resultado tecnico falso.
- Campos podem ser validados por script.
