# Feedback - Bloco 06 - Modo Startup Safe

## Objetivo do bloco

Criar uma entrada segura de Startup Safe para ser chamada manualmente agora e futuramente pelo bloco de agendamento, sempre usando `startup_safe`, forcando `-DryRun`, aplicando delay configuravel e mantendo comandos pesados, modo real e startup automatico bloqueados.

## Arquivos analisados

- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/05_blocos_implementacao/bloco_06_modo_startup_safe.md`
- `Docs/06_scripts_funcoes/funcoes_launcher.md`
- `Docs/06_scripts_funcoes/funcoes_startup.md`
- `Docs/06_scripts_funcoes/matriz_de_scripts.md`
- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/10_feedback/feedback_bloco_00_baseline_organizacao_repositorio.md`
- `Docs/10_feedback/feedback_bloco_01_configuracoes_base_json.md`
- `Docs/10_feedback/feedback_bloco_02_funcoes_comuns_powershell.md`
- `Docs/10_feedback/feedback_bloco_03_banners_loading_logs_visuais.md`
- `Docs/10_feedback/feedback_bloco_04_scripts_dos_terminais.md`
- `Docs/10_feedback/feedback_bloco_05_launcher_grid_2x2.md`
- `config/terminals.json`
- `config/visual_settings.json`
- `config/schedule_settings.json`
- `scripts/common/common.ps1`
- `scripts/launchers/launcher_grid_2x2.ps1`
- `scripts/launchers/launcher_fallback_windows.ps1`
- `scripts/launchers/launcher_common.ps1`
- `README.md`

Todos os arquivos obrigatorios foram encontrados e lidos antes das alteracoes.

## Arquivos criados

- `scripts/startup/startup_common.ps1`
- `scripts/startup/launcher_startup_safe.ps1`
- `Docs/10_feedback/feedback_bloco_06_modo_startup_safe.md`

## Arquivos alterados

- `scripts/launchers/launcher_grid_2x2.ps1`

O launcher do Bloco 05 recebeu o parametro opcional `-RunLogDirectory`, mantendo compatibilidade com chamadas antigas e permitindo que o Startup Safe use uma pasta de logs compartilhada.

## Startup safe implementado

`scripts/startup/launcher_startup_safe.ps1` foi criado como wrapper seguro. Ele:

- importa `scripts/startup/startup_common.ps1`;
- resolve o root do projeto;
- importa `scripts/common/common.ps1`;
- carrega `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json`;
- valida as flags de seguranca antes de abrir qualquer terminal;
- cria pasta de log compartilhada;
- registra `startup_safe.log`;
- calcula e aplica delay inicial;
- chama `scripts/launchers/launcher_grid_2x2.ps1`;
- passa `-Mode startup_safe`, `-RunLogDirectory`, `-DryRun`, `-UseFallback` quando solicitado e `-NoPause` quando solicitado.

## Parametros disponiveis

`launcher_startup_safe.ps1` aceita:

```powershell
param(
    [switch]$DryRun,
    [switch]$UseFallback,
    [switch]$NoPause,
    [int]$DelaySeconds = -1
)
```

Regras implementadas:

- `DryRun` e tratado como verdadeiro mesmo quando o switch nao e informado.
- `DelaySeconds >= 0` sobrescreve o valor do JSON.
- `DelaySeconds = -1` usa `startup.delaySeconds` de `config/schedule_settings.json`.
- delay invalido usa fallback seguro de 20 segundos.
- delay acima de 300 segundos e limitado a 300 segundos.
- o delay escolhido e registrado em `startup_safe.log`.

## Fluxo de execucao

1. Resolver root do projeto.
2. Importar funcoes comuns.
3. Carregar os tres JSON.
4. Criar pasta de logs compartilhada.
5. Registrar inicio em `startup_safe.log`.
6. Validar configuracao segura.
7. Aplicar delay configurado.
8. Montar argumentos seguros para o launcher do grid.
9. Chamar `launcher_grid_2x2.ps1` em `startup_safe` com `-DryRun`.
10. Registrar handoff para o launcher.

## Validacoes de seguranca

O wrapper bloqueia a execucao antes de abrir terminais se detectar:

- `startup.mode` diferente de `startup_safe`;
- `allowStartupHeavyCommands=true`;
- `startup.allowHeavyCommandsOnStartup=true`;
- `allowRealMaintenance=true`;
- `scheduledTask.autoCreate=true`;
- `startup.enabled=true` antes do bloco de agendamento.

## Validacao realizada

- Executados `git status --short`, `git branch --show-current` e `git log --oneline -5` antes das alteracoes.
- Confirmado que o Bloco 05 estava commitado em `28403bbdc393177cfb646e76b44fd8b0cc77f134`.
- Sintaxe validada com parser do PowerShell para:
  - `scripts/startup/startup_common.ps1`
  - `scripts/startup/launcher_startup_safe.ps1`
  - `scripts/launchers/launcher_grid_2x2.ps1`
- `config/terminals.json`, `config/visual_settings.json` e `config/schedule_settings.json` validados com `ConvertFrom-Json`.
- Flags de seguranca confirmadas:
  - `allowRealMaintenance=false`
  - `allowStartupHeavyCommands=false`
  - `startup.allowHeavyCommandsOnStartup=false`
  - `startup.enabled=false`
  - `scheduledTask.autoCreate=false`
  - `startup.mode=startup_safe`
- Validado que `Build-StartupSafeLauncherArguments` monta argumentos com `startup_safe`, `-RunLogDirectory`, `-DryRun`, `-UseFallback` e `-NoPause`.
- Validado que o delay do JSON e 20 segundos.
- Validado que `-DelaySeconds 0` sobrescreve o delay para zero.
- Validado que delay acima de 300 segundos e limitado.
- Validado por busca estatica que os scripts de startup nao contem termos proibidos como comandos de manutencao, comandos de agendamento, alteracao de registro ou pasta de startup.
- Confirmado que a tarefa agendada `WindowsMaintenanceTerminalGrid` nao existe.
- Confirmado que `config/*.json` nao teve diff.
- Confirmado que `logs/` permaneceu apenas com `.gitkeep`.

O wrapper completo nao foi executado porque a execucao chamaria o launcher do grid e abriria janelas reais. A validacao foi feita por parser, importacao de helpers, montagem de argumentos e inspecao estatica segura.

## Seguranca aplicada

- Modo real nao e aceito pelo wrapper.
- O wrapper sempre chama o launcher com `startup_safe`.
- O wrapper sempre passa `-DryRun`.
- O wrapper nao solicita administrador.
- O wrapper nao faz autoelevacao.
- O wrapper nao cria tarefa agendada.
- O wrapper nao habilita startup automatico.
- O wrapper nao altera registro.
- O wrapper nao copia atalho para pasta de inicializacao.
- Nenhum arquivo `install.ps1` ou `uninstall.ps1` foi criado.

## O que nao foi implementado propositalmente

- Criacao de tarefa agendada.
- Remocao de tarefa agendada.
- `install.ps1`.
- `uninstall.ps1`.
- Startup automatico real.
- Alteracao de `shell:startup`.
- Alteracao de registro do Windows.
- Autoelevacao.
- Modo `maintenance_real`.
- Modo `maintenance_real_deep`.
- Execucao de comandos de manutencao do Windows.
- Teste com abertura real do grid.

## Riscos identificados

- A execucao manual do wrapper abrira o launcher do grid e, por consequencia, janelas reais de terminal.
- O script ainda depende da politica de execucao local; o uso recomendado permanece com `-ExecutionPolicy Bypass` em processo isolado.
- O Bloco 05 ainda abre processos reais de terminal; por isso a validacao automatizada do Bloco 06 ficou limitada a construcao e inspecao.
- O uso de uma pasta compartilhada melhora rastreabilidade, mas a estrategia de `summary.json` compartilhado ainda deve ser tratada em bloco futuro.

## Pendencias para o Bloco 07

- Implementar o Modo Maintenance Real de forma manual e controlada.
- Validar administrador somente no modo real.
- Exigir confirmacao explicita para comandos reais.
- Manter `startup_safe` separado do modo real.
- Nao reutilizar o Startup Safe para liberar comandos pesados.

## Git

- Branch antes do bloco: `master`.
- Hash base antes do bloco: `28403bbdc393177cfb646e76b44fd8b0cc77f134`.
- Commit planejado apos validacao: `feat: add safe startup launcher`.
- Push planejado: `git push origin master`, sem `--force`.

## Proximo prompt recomendado

```text
Leia Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md e implemente somente o Bloco 07 - Modo Maintenance Real. Mantenha startup_safe separado, exija validacoes de administrador e confirmacao explicita, preserve dry-run por padrao e nao crie tarefa agendada.
```

## Confirmacao de seguranca

Nenhum comando de manutenção do Windows foi executado. Nenhum DISM, SFC, CHKDSK, defrag, tarefa agendada, startup automático, modo real, alteração de registro, autoelevação ou comando administrativo foi rodado neste bloco.
