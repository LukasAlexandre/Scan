# Funcoes Terminais

## Objetivo

Documentar o comportamento comum dos quatro scripts de terminal.

## Contexto

Cada terminal tem identidade propria, mas todos devem seguir uma assinatura comum para facilitar o launcher e os testes.

## Assinatura Recomendada

```powershell
param(
  [ValidateSet("visual_only", "startup_safe", "maintenance_real", "maintenance_real_deep")]
  [string]$Mode = "visual_only",
  [string]$RunLogDirectory,
  [switch]$DryRun,
  [switch]$KeepOpen
)
```

## Fluxo Padrao

1. Resolver root do projeto.
2. Carregar funcoes comuns.
3. Carregar configuracao do terminal.
4. Criar ou receber caminho de log.
5. Exibir banner.
6. Exibir loading visual.
7. Executar comportamento por modo.
8. Registrar status.
9. Manter janela aberta se solicitado.

## Decisoes Tecnicas

- Modo `visual_only` deve ser o mais seguro para testes.
- Modo `startup_safe` deve bloquear manutencao pesada.
- Modo `maintenance_real` deve depender de admin validado pelo launcher.
- `processing_chkdsk.ps1` deve tratar `/scan` e `/r` separadamente.

## Regras

- Scripts nao devem assumir que estao em admin sem verificar ou receber confirmacao.
- Scripts devem retornar exit code.
- Scripts devem logar comandos ignorados por regra de modo.
- Scripts devem manter mensagens tecnicas honestas.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_04_scripts_dos_terminais.md`
- `Docs/02_requisitos/matriz_de_comandos.md`
- `Docs/07_configuracoes/terminals_json.md`

## Riscos

- Divergencia de parametros entre scripts.
- Comando pesado escapar no startup.
- Terminal fechar apos erro.

## Criterios de Aceite

- Os quatro scripts seguem assinatura comum.
- Cada terminal respeita modo.
- Logs e exit code sao consistentes.
