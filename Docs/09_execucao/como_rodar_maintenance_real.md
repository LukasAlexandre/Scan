# Como Rodar Maintenance Real

## Objetivo

Orientar a execucao futura do modo de manutencao real sob demanda.

## Contexto

Este modo pode executar comandos que alteram ou verificam o estado do Windows. Deve ser usado manualmente, com administrador e com logs.

## Comando Dry Run Planejado

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\launcher_maintenance_real.ps1 -DryRun
```

## Comando Real Planejado

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\launcher_maintenance_real.ps1
```

## Comandos Reais Envolvidos

```cmd
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow
chkdsk C: /scan
defrag C: /O /U /V
```

`chkdsk C: /r` deve ser opcional, profundo e confirmado antes de qualquer agendamento.

## Decisoes Tecnicas

- Dry run deve ser testado antes do modo real.
- Modo real exige admin.
- Execucao real deve ser controlada por fila.
- Summary final deve registrar status.

## Regras

- Nao rodar no login.
- Nao rodar todos os comandos pesados em paralelo.
- Nao confirmar CHKDSK profundo automaticamente.
- Nao esconder falhas.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md`
- `Docs/02_requisitos/matriz_de_comandos.md`
- `Docs/08_testes/testes_modo_maintenance_real.md`

## Riscos

- Processo demorado.
- Necessidade de reinicializacao.
- Alto uso de disco/CPU.
- Falhas por ausencia de permissao.

## Criterios de Aceite

- Sem admin, nao executa.
- Com dry run, simula com logs.
- Com real, registra saida e exit code.
- CHKDSK profundo pede confirmacao.
