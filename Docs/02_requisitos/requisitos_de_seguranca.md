# Requisitos de Seguranca

## Objetivo

Definir regras de seguranca operacional para evitar execucao indevida de comandos de manutencao, sobrecarga do sistema ou automacao invisivel.

## Contexto

DISM, SFC, CHKDSK e defrag sao ferramentas legitimas do Windows, mas podem consumir muitos recursos, exigir administrador ou alterar estado do sistema. O projeto deve ser conservador por padrao.

## Requisitos

| ID | Requisito | Regra |
| --- | --- | --- |
| RS-001 | Administrador no modo real | `maintenance_real` deve validar elevacao |
| RS-002 | Sem manutencao pesada no login | `startup_safe` nao executa DISM, SFC, CHKDSK `/r` ou defrag |
| RS-003 | Confirmacao para CHKDSK profundo | `chkdsk C: /r` deve perguntar antes |
| RS-004 | Lock file | Impedir execucao duplicada |
| RS-005 | Logs auditaveis | Registrar comando, horario, status e exit code |
| RS-006 | Sem tarefa invisivel | Tarefa deve rodar em sessao interativa |
| RS-007 | Sem resultado falso | Nao declarar reparo sem saida real |
| RS-008 | Fallback seguro | Se requisito critico falhar, abortar com log |

## Decisoes Tecnicas

- `Test-IsAdmin` sera uma funcao comum.
- `Start-AsAdmin` sera usado somente para launchers reais.
- Lock file ficara em `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\grid.lock`.
- Logs locais ficam no repositorio em `logs/` por execucao.

## Regras

- Scripts devem falhar de forma explicita quando nao houver permissao.
- Scripts nao devem elevar silenciosamente sem informar o usuario.
- Scripts de agendamento devem ser reversiveis.
- Nenhuma etapa documental deve executar manutencao real.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_02_funcoes_comuns_powershell.md`
- `Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md`
- `Docs/05_blocos_implementacao/bloco_09_logs_lockfile_summary.md`

## Riscos

- Rodar `chkdsk C: /r` pode levar horas e exigir reboot.
- Rodar otimizacao em horario inadequado pode afetar desempenho.
- Relancar com administrador pode perder argumentos se mal implementado.

## Criterios de Aceite

- Requisitos protegem modo de login, modo real e CHKDSK profundo.
- Ha regra de logs e lock file.
- A documentacao explicita que esta fase nao executa comandos.
