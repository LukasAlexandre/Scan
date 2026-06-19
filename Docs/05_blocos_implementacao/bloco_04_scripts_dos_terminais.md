# Bloco 04 - Scripts dos Terminais

## Objetivo

Planejar e implementar as quatro entradas de terminal que carregam configuracao, exibem visual, executam modo seguro ou real e salvam logs.

## Contexto

Cada painel do grid deve rodar um script especifico. O script deve saber o modo atual e nunca executar comando pesado por acidente.

## Escopo

- Criar scripts em `scripts/terminals/`.
- Carregar funcoes comuns.
- Carregar configuracao.
- Exibir banner e loading.
- Executar fluxo por modo.
- Manter terminal aberto ao final.

## Fora de Escopo

- Implementar launcher 2x2.
- Criar tarefa agendada.
- Rodar comandos reais em testes automaticos.

## Arquivos que devem ser criados ou alterados

- `scripts/terminals/analytics_dism.ps1`
- `scripts/terminals/scanning_sfc.ps1`
- `scripts/terminals/processing_chkdsk.ps1`
- `scripts/terminals/cleaning_optimize.ps1`

## Funcoes esperadas

- Uso de `Write-Log`
- Uso de `Show-Banner`
- Uso de `Show-LoadingBar`
- Uso de `Invoke-CommandWithLog`
- Uso de `Write-SummaryJson` quando aplicavel ao coordenador

## Configuracoes necessarias

- `TerminalId`
- `Mode`
- `RunLogDirectory`
- `DryRun`
- Campos do terminal no JSON.

## Regras tecnicas

- `analytics_dism.ps1` nao roda DISM em `startup_safe`.
- `scanning_sfc.ps1` nao roda SFC em `startup_safe`.
- `processing_chkdsk.ps1` usa `/scan` somente quando permitido.
- `cleaning_optimize.ps1` nao roda defrag em `startup_safe`.
- `chkdsk C: /r` exige confirmacao.

## Riscos

- Parametro ausente cair em modo real.
- Script de terminal duplicar logica de launcher.
- Terminal fechar antes do usuario ler o resultado.

## Passo a passo de implementacao

1. Criar assinatura comum de parametros.
2. Dot-source funcoes comuns.
3. Carregar JSON.
4. Exibir visual.
5. Implementar `switch` por modo.
6. Usar dry run por padrao nos testes.
7. Manter terminal aberto ao fim se configurado.

## Fluxo de teste

1. Rodar cada script com `-Mode visual_only`.
2. Rodar cada script com `-Mode startup_safe`.
3. Confirmar que comandos pesados nao sao chamados.
4. Verificar logs gerados.

## Criterios de aceite

- Quatro scripts existem.
- Scripts carregam funcoes e config.
- Modo seguro nao executa manutencao pesada.
- Logs por terminal sao criados.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 04. Crie os quatro scripts de terminal com parametros Mode, RunLogDirectory e DryRun. Use funcoes comuns, exiba visual e gere logs. Em testes, nao execute comandos reais de manutencao.
```

## Feedback esperado apos implementacao

- Scripts criados.
- Parametros aceitos.
- Resultado dos testes `visual_only` e `startup_safe`.
- Pendencias para launcher 2x2.
