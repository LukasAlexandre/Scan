# Bloco 03 - Banners, Loading e Logs Visuais

## Objetivo

Implementar a camada visual segura: banners ASCII, loading de 0 a 100, efeito de digitacao, spinner, cores ANSI e logs com timestamp.

## Contexto

O visual e parte importante da experiencia, mas deve ser honesto. Ele nao pode sugerir que reparos aconteceram se nenhum comando real retornou isso.

## Escopo

- Criar ou carregar banners para ANALYTICS, SCANNING, PROCESSING e CLEANING.
- Implementar loading visual.
- Implementar efeito de digitacao configuravel.
- Padronizar prefixos `[VISUAL]`, `[STATUS]`, `[COMMAND]` e `[ERROR]`.

## Fora de Escopo

- Executar comandos reais.
- Abrir grid 2x2.
- Criar tarefa agendada.

## Arquivos que devem ser criados ou alterados

- `scripts/common/banner.ps1`
- `scripts/common/spinner.ps1`
- `assets/ascii/analytics.txt`
- `assets/ascii/scanning.txt`
- `assets/ascii/processing.txt`
- `assets/ascii/cleaning.txt`

## Funcoes esperadas

- `Show-Banner`
- `Show-LoadingBar`
- `Show-Spinner`
- `Write-TypewriterText`
- `Write-ColoredLog`

## Configuracoes necessarias

- Cores ANSI por terminal.
- Velocidade de loading.
- Velocidade de digitacao.
- Largura maxima de banner.

## Regras tecnicas

- Loading visual deve ser preparatorio.
- Nao simular progresso de DISM, SFC, CHKDSK ou defrag.
- Mensagens visuais devem ser identificadas.
- Banners devem degradar bem em janelas estreitas.

## Riscos

- Banner quebrar layout.
- Animacoes ficarem lentas demais.
- Usuario interpretar visual como resultado tecnico.

## Passo a passo de implementacao

1. Definir banners ASCII.
2. Criar funcao de exibicao com cor.
3. Criar loading visual configuravel.
4. Criar efeito de digitacao opcional.
5. Testar em uma janela PowerShell normal.
6. Registrar feedback.

## Fluxo de teste

1. Executar demo visual em modo `visual_only`.
2. Confirmar que nenhum comando de manutencao roda.
3. Verificar cores e legibilidade.
4. Confirmar que logs visuais indicam `[VISUAL]`.

## Criterios de aceite

- Quatro banners existem.
- Loading chega de 0 a 100 sem travar.
- Cores por terminal aparecem.
- Nenhuma mensagem declara reparo falso.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 03. Crie banners, loading, spinner, efeito de digitacao e logs visuais usando as funcoes comuns. Nao execute comandos reais e rotule mensagens decorativas como VISUAL.
```

## Feedback esperado apos implementacao

- Banners criados.
- Funcoes visuais implementadas.
- Evidencia de teste visual seguro.
- Ajustes recomendados de tamanho e cor.
