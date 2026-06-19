# Matriz de Comandos

## Objetivo

Mapear os comandos de manutencao planejados, seus modos permitidos, riscos e controles obrigatorios.

## Contexto

Esta matriz e a referencia para impedir que comandos pesados sejam executados automaticamente ou fora de contexto. Ela deve ser consultada durante a implementacao dos scripts dos terminais.

## Matriz

| Terminal | Comando | Modo permitido | Precisa Admin | Pode rodar no login | Controle obrigatorio |
| --- | --- | --- | --- | --- | --- |
| ANALYTICS | `DISM /Online /Cleanup-Image /RestoreHealth` | `maintenance_real` | Sim | Nao | Fila, log, exit code |
| SCANNING | `sfc /scannow` | `maintenance_real` | Sim | Nao | Fila, log, exit code |
| PROCESSING | `chkdsk C: /scan` | `startup_safe` limitado ou `maintenance_real` | Recomendado | Somente se configurado como leve | Log e timeout planejado |
| PROCESSING | `chkdsk C: /r` | `maintenance_real_deep` | Sim | Nao | Confirmacao explicita |
| CLEANING | `defrag C: /O /U /V` | `maintenance_real` | Sim | Nao | Fila, log, exit code |

## Decisoes Tecnicas

- `chkdsk C: /scan` e o unico comando de disco aceitavel para verificacao leve, ainda assim deve ser configuravel.
- DISM, SFC e defrag ficam fora do startup automatico.
- A implementacao deve preferir argumentos separados em PowerShell, nao strings concatenadas.

## Regras

- Nao executar os comandos desta matriz nesta fase documental.
- Nao executar todos em paralelo sem coordenacao.
- Registrar comando exato antes de executar.
- Registrar saida padrao e erro no log do terminal.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_04_scripts_dos_terminais.md`
- `Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md`
- `Docs/06_scripts_funcoes/funcoes_terminais.md`

## Riscos

- DISM pode depender de Windows Update ou Component Store.
- SFC pode demorar e retornar reparos pendentes.
- CHKDSK profundo pode agendar verificacao no reboot.
- Defrag/Optimize pode consumir disco e CPU.

## Criterios de Aceite

- Cada comando tem modo permitido e controle obrigatorio.
- A matriz impede manutencao pesada no login.
- CHKDSK profundo esta separado de CHKDSK online.
