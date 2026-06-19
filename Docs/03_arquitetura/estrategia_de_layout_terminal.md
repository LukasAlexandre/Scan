# Estrategia de Layout Terminal

## Objetivo

Definir como abrir os quatro terminais em formato 2x2 e quais fallbacks devem existir.

## Contexto

O requisito visual principal e ver quatro areas simultaneas no monitor principal. O Windows Terminal facilita esse resultado com paineis, mas o projeto deve documentar fallback para maquinas sem `wt.exe`.

## Estrategia Preferencial

Usar Windows Terminal:

```text
wt.exe new-tab --title ANALYTICS ...
  split-pane --horizontal --title SCANNING ...
  split-pane --vertical --title PROCESSING ...
  move-focus ...
  split-pane --vertical --title CLEANING ...
```

A sintaxe exata deve ser validada no bloco de implementacao, pois `wt.exe` tem regras especificas de encadeamento.

## Fallback

Se `wt.exe` nao existir:

- abrir quatro janelas PowerShell separadas;
- detectar monitor principal;
- calcular quadrantes;
- posicionar janelas com Win32 API;
- registrar aviso no log.

## Decisoes Tecnicas

- Preferir um unico Windows Terminal com quatro paineis.
- Documentar alternativa por janelas separadas.
- Nao assumir resolucao fixa.
- Usar fonte e cores por perfil quando possivel; caso contrario, usar ANSI.

## Regras

- O layout deve ser aplicado ao monitor principal.
- Falha de layout nao deve executar comandos reais sem aviso.
- Titulos devem identificar terminal e funcao.
- Cada painel deve chamar seu script com modo e caminho de log.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_05_launcher_grid_2x2.md`
- `Docs/06_scripts_funcoes/funcoes_launcher.md`
- `Docs/07_configuracoes/visual_settings_json.md`

## Riscos

- Sintaxe do `wt.exe` variar conforme versao.
- Posicionamento por Win32 API ser sensivel a escala/DPI.
- Taskbar reduzir area util do monitor.

## Criterios de Aceite

- Ha estrategia preferencial e fallback.
- O layout nao depende de resolucao fixa.
- A documentacao informa que a sintaxe final deve ser testada localmente.
