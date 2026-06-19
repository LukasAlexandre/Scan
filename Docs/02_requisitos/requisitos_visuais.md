# Requisitos Visuais

## Objetivo

Definir a experiencia visual esperada para os quatro terminais e limitar efeitos que possam confundir o usuario.

## Contexto

A estetica desejada e inspirada em paines de diagnostico tecnico: fundo escuro, cores ANSI, banners grandes, loading e logs. O visual deve reforcar identidade sem mascarar falhas reais.

## Requisitos Visuais

| ID | Requisito | Detalhe |
| --- | --- | --- |
| RV-001 | Layout 2x2 | Quatro paineis no monitor principal |
| RV-002 | Titulo por terminal | Nome e funcao tecnica |
| RV-003 | Cor por terminal | Verde, azul, vermelho e laranja |
| RV-004 | Banner ASCII | Palavra principal do terminal |
| RV-005 | Loading 0 a 100 | Apenas preparacao visual |
| RV-006 | Logs com timestamp | Mesmo formato em todos os terminais |
| RV-007 | Fonte recomendada | Cascadia Mono |
| RV-008 | Fundo escuro | Alto contraste |
| RV-009 | Terminal aberto ao final | Resumo visivel |

## Decisoes Tecnicas

- Cores ANSI devem ser configuraveis.
- Banners podem ficar em `assets/ascii/` ou em funcao PowerShell.
- A fonte deve ser recomendada, nao uma dependencia obrigatoria.
- O layout deve preferir paineis do Windows Terminal.

## Regras

- Nao exibir mensagens de sucesso antes de confirmacao real.
- Nao simular porcentagem de progresso dos comandos nativos se o comando nao fornecer esse dado.
- Loading visual deve ser rotulado como preparacao.
- Logs decorativos devem usar prefixo claro como `[VISUAL]`.

## Arquivos Relacionados

- `Docs/03_arquitetura/estrategia_de_layout_terminal.md`
- `Docs/05_blocos_implementacao/bloco_03_banners_loading_logs_visuais.md`
- `Docs/07_configuracoes/visual_settings_json.md`

## Riscos

- Banners muito largos podem quebrar em paineis pequenos.
- Cores podem ficar ilegiveis em temas diferentes.
- Efeitos visuais podem atrasar execucao se exagerados.

## Criterios de Aceite

- Cada terminal tem identidade visual definida.
- O documento proibe resultados tecnicos falsos.
- A experiencia visual e configuravel e tolerante a fallback.
