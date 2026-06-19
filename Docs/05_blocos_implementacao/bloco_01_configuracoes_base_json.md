# Bloco 01 - Configuracoes Base JSON

## Objetivo

Planejar e criar os arquivos JSON base: `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json`.

## Contexto

As configuracoes devem separar dados editaveis da logica PowerShell. Isso permite alterar cores, titulos, delays e flags sem mexer nos scripts.

## Escopo

- Criar arquivos JSON com exemplos seguros.
- Documentar campos obrigatorios.
- Validar JSON sintaticamente.
- Manter comandos pesados desativados no startup.

## Fora de Escopo

- Executar comandos configurados.
- Criar validacao PowerShell completa.
- Abrir terminais.
- Instalar tarefa agendada.

## Arquivos que devem ser criados ou alterados

- `config/terminals.json`
- `config/visual_settings.json`
- `config/schedule_settings.json`
- `Docs/10_feedback/feedback_bloco_01.md` opcional.

## Funcoes esperadas

Nenhuma obrigatoria. Pode ser planejada uma futura funcao `Read-ProjectConfig`.

## Configuracoes necessarias

- `defaultMode`
- `terminalEngine`
- `layout`
- `delayAfterLoginSeconds`
- lista `terminals`
- comandos por terminal
- flags `autoRunInStartupSafe` e `autoRunInMaintenanceReal`

## Regras tecnicas

- `autoRunInStartupSafe` deve ser `false` para DISM, SFC e defrag.
- `chkdsk C: /r` deve aparecer apenas como comando profundo.
- JSON nao deve conter comentarios, pois JSON puro nao suporta comentarios.
- Usar caminhos relativos.

## Riscos

- JSON invalido quebrar launchers.
- Config permitir comando pesado no login.
- Duplicar comandos em scripts e JSON sem regra de precedencia.

## Passo a passo de implementacao

1. Criar pasta `config/`.
2. Criar `terminals.json`.
3. Criar `visual_settings.json`.
4. Criar `schedule_settings.json`.
5. Validar sintaxe com `ConvertFrom-Json`.
6. Registrar feedback.

## Fluxo de teste

1. Carregar cada JSON no PowerShell com `Get-Content -Raw | ConvertFrom-Json`.
2. Verificar os quatro terminais.
3. Confirmar que comandos pesados nao estao habilitados no startup.

## Criterios de aceite

- Os tres JSON existem e sao validos.
- Cada terminal tem id, titulo, cor, script e modo permitido.
- O startup seguro permanece sem manutencao pesada.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 01. Crie os arquivos JSON em config/ com campos documentados nesta pasta Docs. Valide sintaxe JSON. Nao execute comandos configurados e nao crie scripts funcionais alem do necessario para validacao segura.
```

## Feedback esperado apos implementacao

- Conteudo dos JSON criados.
- Resultado da validacao.
- Decisoes sobre campos.
- Pendencias para funcoes comuns.
