# Como Rodar Startup Safe

## Objetivo

Orientar a execucao manual do modo seguro.

## Contexto

`startup_safe` e o modo recomendado para validacao visual e uso automatico no login. Ele nao deve executar manutencao pesada.

## Comando Planejado

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\launcher_startup_safe.ps1
```

## Comando Alternativo para Teste Visual

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\launcher.ps1 -Mode visual_only
```

## O que deve acontecer

- Aguardar delay configurado se aplicavel.
- Criar pasta de logs.
- Criar lock file.
- Abrir quatro terminais.
- Exibir banners, loading e status leve.
- Manter terminais abertos.

## Decisoes Tecnicas

- Modo seguro deve ser o default operacional.
- Checks leves devem ser documentados e auditaveis.
- Comandos pesados devem ser bloqueados mesmo se aparecerem no JSON.

## Regras

- Nao executar DISM.
- Nao executar SFC.
- Nao executar `chkdsk C: /r`.
- Nao executar `defrag C: /O /U /V`.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_06_modo_startup_safe.md`
- `Docs/08_testes/testes_modo_startup_safe.md`
- `Docs/03_arquitetura/modos_de_operacao.md`

## Riscos

- Lock antigo bloquear abertura.
- Windows Terminal ausente acionar fallback.
- Delay parecer travamento se nao houver mensagem.

## Criterios de Aceite

- Grid abre.
- Logs sao criados.
- Comandos pesados nao sao executados.
