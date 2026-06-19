# Configuracoes Necessarias

## Objetivo

Documentar ambiente, permissoes e configuracoes necessarias para implementar e operar o projeto.

## Contexto

O projeto depende de recursos do Windows e deve funcionar com seguranca em maquinas diferentes.

## Ambiente

| Item | Requisito |
| --- | --- |
| Sistema operacional | Windows 10 ou Windows 11 |
| Shell minimo | Windows PowerShell 5.1 |
| Shell recomendado | PowerShell 7+ |
| Terminal recomendado | Windows Terminal |
| Fonte recomendada | Cascadia Mono |
| Permissao admin | Obrigatoria no modo `maintenance_real` |
| Politica de execucao | Pode exigir `-ExecutionPolicy Bypass` |
| Logs | `logs/YYYY-MM-DD_HH-mm-ss/` |
| Lock file | `%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\grid.lock` |
| Monitor | Principal |

## Fallback sem `wt.exe`

Se Windows Terminal nao existir, o sistema deve:

- registrar aviso;
- abrir quatro janelas PowerShell separadas;
- tentar posicionar janelas em quadrantes;
- manter modo seguro como padrao;
- abortar modo real se o layout/launcher falhar de forma critica.

## Decisoes Tecnicas

- Configuracoes devem ficar em `config/`.
- JSON deve ser validado antes de uso.
- Caminhos devem ser relativos ao root do projeto.
- A tarefa agendada deve abrir janela visivel.

## Regras

- Nao depender de fonte instalada para funcionamento.
- Nao baixar dependencias automaticamente sem consentimento.
- Nao usar caminho absoluto do ambiente do desenvolvedor.
- Nao executar manutencao real para validar configuracao.

## Arquivos Relacionados

- `Docs/07_configuracoes/terminals_json.md`
- `Docs/07_configuracoes/visual_settings_json.md`
- `Docs/07_configuracoes/scheduled_task_config.md`

## Riscos

- Politica de execucao bloquear launchers.
- Sem admin, modo real deve falhar de forma clara.
- Maquina sem Windows Terminal usar fallback menos preciso.

## Criterios de Aceite

- Todas as configuracoes de ambiente estao descritas.
- Ha fallback documentado.
- Permissao administrativa esta limitada ao modo real.
