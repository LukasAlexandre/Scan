# scheduled_task_config

## Objetivo

Documentar o exemplo planejado para `config/schedule_settings.json` e as regras da tarefa agendada.

## Contexto

A tarefa agendada deve abrir o modo seguro no logon do usuario. Ela nao deve executar manutencao real nem rodar invisivel.

## Exemplo Documentado

```json
{
  "taskName": "WindowsMaintenanceTerminalGrid",
  "description": "Abre o grid visual seguro de manutencao do Windows no logon.",
  "trigger": "AtLogOn",
  "delayAfterLoginSeconds": 30,
  "launcher": "launcher_startup_safe.ps1",
  "runOnlyWhenUserIsLoggedOn": true,
  "runLevel": "HighestAvailable",
  "executionPolicy": "Bypass",
  "visibleWindow": true,
  "lockFilePath": "%LOCALAPPDATA%/WindowsMaintenanceTerminalGrid/grid.lock",
  "staleLockMinutes": 180
}
```

## Decisoes Tecnicas

- Tarefa aponta somente para `launcher_startup_safe.ps1`.
- Usar logon interativo para permitir janela visivel.
- Delay reduz impacto imediato apos login.
- Lock file evita duplicidade.

## Regras

- Nao apontar tarefa para `launcher_maintenance_real.ps1`.
- Nao usar modo invisivel.
- `uninstall.ps1` deve remover a tarefa.
- Caminho do projeto deve ser resolvido no momento da instalacao.

## Arquivos Relacionados

- `Docs/05_blocos_implementacao/bloco_08_tarefa_agendada_windows.md`
- `Docs/06_scripts_funcoes/funcoes_startup.md`
- `Docs/09_execucao/como_instalar.md`

## Riscos

- Tarefa nao exibir UI se configurada para rodar sem usuario logado.
- Caminho absoluto ficar invalido se projeto for movido.
- Delay nao ser respeitado por versao/parametrizacao incorreta.

## Criterios de Aceite

- Exemplo aponta para startup safe.
- Janelas visiveis estao exigidas.
- Remocao via uninstall esta prevista.
