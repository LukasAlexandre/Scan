# Comandos Seguros

## Objetivo

Explicar, comando por comando, o que cada um faz, qual risco real carrega
e qual controle do codigo atual o protege. Complementa a matriz oficial em
`Docs/02_requisitos/matriz_de_comandos.md` com o estado real de
implementacao (Blocos 07/09).

## Regra geral

Nenhum comando desta pagina executa automaticamente. Todos exigem
execucao manual de `launcher_maintenance_real.ps1` com `-RunReal`,
administrador, `-AllowSessionRealMaintenance` e o token
`I_ACCEPT_WINDOWS_MAINTENANCE` (ver
[como_rodar_maintenance_real.md](como_rodar_maintenance_real.md)). O modo
`startup_safe` nunca executa nenhum destes comandos, mesmo que o JSON de
configuracao seja alterado para tentar permitir — `launcher_grid_2x2.ps1`
forca `DryRun=$true` nesta camada independentemente de flags.

## Tabela de risco

| Comando | Terminal | O que faz | Tempo tipico | Risco | Status no codigo atual |
| --- | --- | --- | --- | --- | --- |
| `DISM /Online /Cleanup-Image /RestoreHealth` | ANALYTICS | Verifica e repara a imagem do componente do Windows (Component Store) | Minutos a ~1h | Pode depender de Windows Update; falha se a imagem estiver corrompida alem do reparo local | Executavel em modo real (gates completos) |
| `sfc /scannow` | SCANNING | Verifica integridade de todos os arquivos de sistema protegidos e repara a partir do cache/imagem | Minutos a ~1h | Pode reportar reparos pendentes que exigem novo DISM | Executavel em modo real (gates completos) |
| `chkdsk C: /scan` | PROCESSING | Verificacao **online** do volume `C:`, sem desmontar nem exigir reboot | Minutos, depende do tamanho do disco | Baixo — somente leitura/relatorio | Executavel em modo real, somente com `-IncludeDiskScan`; sem a flag, a etapa e pulada (`skipped_not_requested`) |
| `defrag C: /O /U /V` | CLEANING | Otimiza a unidade (TRIM/defrag conforme tipo de disco), com saida verbosa | Minutos a horas, dependendo do disco | Uso elevado de disco/CPU durante a execucao | Executavel em modo real (gates completos), sempre a ultima etapa habilitada da fila |
| `chkdsk C: /r` | PROCESSING (deep) | Localiza setores defeituosos e recupera dados legiveis; normalmente exige agendamento para o proximo reboot se o volume estiver em uso | Pode exigir reboot e rodar antes do Windows iniciar | Alto — pode forcar reinicializacao e indisponibilidade do disco durante a checagem | **Bloqueado estruturalmente.** `New-MaintenanceExecutionPlan` cria esta etapa com `Enabled:$false` e status `blocked_deep_disk_repair` sempre, com ou sem `-IncludeDeepDiskRepair`. Nao existe, no codigo atual, nenhum parametro ou token que libere este comando. |

## Por que `chkdsk C: /r` esta bloqueado e nao apenas "requer confirmacao"

A matriz oficial (`Docs/02_requisitos/matriz_de_comandos.md`) classifica
`chkdsk C: /r` como modo `maintenance_real_deep`, exigindo "confirmacao
explicita". Na implementacao atual (Bloco 07), essa exigencia foi
traduzida como **bloqueio total**: a etapa 5 do plano de execucao real e
sempre desabilitada no codigo, independente de qualquer flag ou token.
Isso e mais restritivo do que "exige confirmacao" — significa que, nesta
fase do projeto, nao ha nenhuma forma de executar reparo profundo de disco
atraves deste sistema. Liberar esse comando exigiria uma decisao explicita
em um bloco futuro, com seu próprio fluxo de confirmacao dedicado.

## Tokens de confirmacao exatos usados no projeto

| Token | Acao protegida | Onde e exigido |
| --- | --- | --- |
| `I_ACCEPT_STARTUP_SAFE_TASK` | Criar a tarefa agendada real | `install.ps1 -Apply -ConfirmationToken ...` |
| `I_ACCEPT_REMOVE_STARTUP_SAFE_TASK` | Remover a tarefa agendada real | `uninstall.ps1 -Apply -ConfirmationToken ...` |
| `I_ACCEPT_WINDOWS_MAINTENANCE` | Executar qualquer comando real de manutencao (DISM/SFC/CHKDSK online/defrag) | `launcher_maintenance_real.ps1 -RunReal -AllowSessionRealMaintenance -ConfirmationToken ...` |

Os tokens sao comparados por igualdade exata de string (case-sensitive).
Nao existe "quase certo" — qualquer diferenca bloqueia a acao antes de
qualquer mudanca real no sistema.

## Arquivos Relacionados

- `scripts/launchers/maintenance_real_common.ps1`
- `Docs/02_requisitos/matriz_de_comandos.md`
- [como_rodar_maintenance_real.md](como_rodar_maintenance_real.md), [modos_de_operacao.md](modos_de_operacao.md)

## Riscos

- Mesmo os comandos "executaveis" desta tabela alteram o estado real do
  Windows — sempre valide com `-DryRun` antes de rodar com `-RunReal`.
- DISM e SFC podem retornar exit codes diferentes de 0 mesmo em execucoes
  "bem sucedidas" (ex.: reparos pendentes); o summary registra o
  `exitCode` exato, nunca apenas "ok"/"falhou".

## Criterios de Aceite

- Todo comando real listado aqui corresponde exatamente ao
  `plannedRealCommand`/`plannedSafeCommand`/`plannedDeepCommand` em
  `config/terminals.json`.
- `chkdsk C: /r` esta documentado como bloqueado, nao apenas como "requer
  confirmacao", refletindo o codigo atual.
