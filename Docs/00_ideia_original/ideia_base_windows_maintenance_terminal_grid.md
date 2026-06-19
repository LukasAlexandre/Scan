# Planejamento — Windows Maintenance Terminal Grid 2x2

## 1. Objetivo

Criar um utilitário visual e funcional para Windows chamado **Windows Maintenance Terminal Grid**, com abertura automática de **4 terminais em layout 2x2** no monitor principal/monitor 1, cada um executando um fluxo de manutenção separado com estética “hacker”, logs detalhados, banners grandes, loading animado, cores diferentes e registro em arquivo.

A ideia visual é:

```text
┌───────────────────────────────┬───────────────────────────────┐
│ TERMINAL 01 — ANALYTICS       │ TERMINAL 02 — SCANNING        │
│ Verde                         │ Azul                          │
│ DISM RestoreHealth            │ SFC Scannow                   │
├───────────────────────────────┼───────────────────────────────┤
│ TERMINAL 03 — PROCESSING      │ TERMINAL 04 — CLEANING        │
│ Vermelho                      │ Laranja                       │
│ CHKDSK /scan ou /r controlado │ Defrag/Optimize C:            │
└───────────────────────────────┴───────────────────────────────┘
```

O objetivo real é **diagnosticar, reparar e otimizar o Windows com segurança**, sem transformar o boot do notebook em um processo pesado demais.

---

## 2. Correção técnica importante

Os comandos abaixo são úteis, porém **não devem ser executados todos os dias, em paralelo e automaticamente a cada inicialização**, porque podem deixar o notebook mais lento, travar o disco, consumir CPU/RAM e aumentar o tempo de boot.

Comandos informados pelo usuário:

```cmd
DISM /online /cleanup-image /restorehealth
sfc /scannow
chkdsk /r c:
```

### Ajuste recomendado para o projeto

O sistema deve ter dois modos:

### Modo 01 — Startup Visual Seguro

Executa automaticamente ao ligar o Windows.

Abre os 4 terminais em grade 2x2 com:

- banner grande;
- loading animado;
- logs visuais;
- coleta de status do Windows;
- verificação leve;
- sem forçar reparos pesados a cada boot.

Esse modo serve para manter a estética visual e mostrar atividade real sem degradar o computador.

### Modo 02 — Manutenção Real Sob Demanda

Executado manualmente pelo usuário.

Roda os comandos pesados com permissão de administrador:

- DISM RestoreHealth;
- SFC Scannow;
- CHKDSK controlado;
- otimização de unidade.

Esse modo deve salvar logs completos e impedir execução duplicada.

---

## 3. Comando adicional recomendado

Além dos 3 comandos citados, o quarto comando recomendado é:

```cmd
defrag C: /O /U /V
```

### Função

Esse comando pede para o Windows otimizar a unidade `C:` conforme o tipo de disco.

- Em HDD, pode executar desfragmentação.
- Em SSD, o Windows tende a aplicar otimização/TRIM quando apropriado.
- `/O` escolhe a otimização correta para o tipo de mídia.
- `/U` mostra progresso.
- `/V` mostra saída detalhada.

### Observação

Esse comando não deve ser executado em todo boot. O ideal é execução manual, semanal ou mensal.

---

## 4. Estratégia dos 4 terminais

## Terminal 01 — ANALYTICS

### Cor

Verde.

### Palavra grande no terminal

```text
 █████╗ ███╗   ██╗ █████╗ ██╗  ██╗   ██╗████████╗██╗ ██████╗███████╗
██╔══██╗████╗  ██║██╔══██╗██║  ╚██╗ ██╔╝╚══██╔══╝██║██╔════╝██╔════╝
███████║██╔██╗ ██║███████║██║   ╚████╔╝    ██║   ██║██║     ███████╗
██╔══██║██║╚██╗██║██╔══██║██║    ╚██╔╝     ██║   ██║██║     ╚════██║
██║  ██║██║ ╚████║██║  ██║███████╗██║      ██║   ██║╚██████╗███████║
╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝      ╚═╝   ╚═╝ ╚═════╝╚══════╝
```

### Função

Analisar e reparar a imagem do Windows.

### Comando real

```cmd
DISM /Online /Cleanup-Image /RestoreHealth
```

### Logs desejados

Exemplos de logs exibidos antes e durante o comando:

```text
[ANALYTICS] Inicializando análise da imagem do Windows...
[ANALYTICS] Verificando permissões administrativas...
[ANALYTICS] Coletando versão do sistema operacional...
[ANALYTICS] Verificando integridade do Component Store...
[ANALYTICS] Executando DISM RestoreHealth...
[ANALYTICS] Aguardando resposta do Windows Update/Component Store...
[ANALYTICS] Processo finalizado. Salvando log...
```

### Arquivo de log

```text
logs/YYYY-MM-DD_HH-mm-ss/analytics_dism_restorehealth.log
```

---

## Terminal 02 — SCANNING

### Cor

Azul.

### Palavra grande no terminal

```text
███████╗ ██████╗ █████╗ ███╗   ██╗███╗   ██╗██╗███╗   ██╗ ██████╗
██╔════╝██╔════╝██╔══██╗████╗  ██║████╗  ██║██║████╗  ██║██╔════╝
███████╗██║     ███████║██╔██╗ ██║██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
╚════██║██║     ██╔══██║██║╚██╗██║██║╚██╗██║██║██║╚██╗██║██║   ██║
███████║╚██████╗██║  ██║██║ ╚████║██║ ╚████║██║██║ ╚████║╚██████╔╝
╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝
```

### Função

Verificar e reparar arquivos protegidos do sistema.

### Comando real

```cmd
sfc /scannow
```

### Logs desejados

```text
[SCANNING] Inicializando varredura de arquivos protegidos...
[SCANNING] Preparando System File Checker...
[SCANNING] Verificando arquivos críticos do Windows...
[SCANNING] Analisando divergências de hash...
[SCANNING] Reparando arquivos quando necessário...
[SCANNING] Processo finalizado. Salvando log...
```

### Arquivo de log

```text
logs/YYYY-MM-DD_HH-mm-ss/scanning_sfc_scannow.log
```

---

## Terminal 03 — PROCESSING

### Cor

Vermelho.

### Palavra grande no terminal

```text
██████╗ ██████╗  ██████╗  ██████╗███████╗███████╗███████╗██╗███╗   ██╗ ██████╗
██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔════╝██╔════╝██╔════╝██║████╗  ██║██╔════╝
██████╔╝██████╔╝██║   ██║██║     █████╗  ███████╗███████╗██║██╔██╗ ██║██║  ███╗
██╔═══╝ ██╔══██╗██║   ██║██║     ██╔══╝  ╚════██║╚════██║██║██║╚██╗██║██║   ██║
██║     ██║  ██║╚██████╔╝╚██████╗███████╗███████║███████║██║██║ ╚████║╚██████╔╝
╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝
```

### Função

Verificar integridade lógica do disco.

### Comando seguro para o modo automático

```cmd
chkdsk C: /scan
```

### Comando profundo sob demanda

```cmd
chkdsk C: /r
```

### Regra obrigatória

O comando `chkdsk C: /r` **não deve rodar automaticamente em todo boot**, porque:

- pode demorar horas;
- pode exigir reinicialização;
- pode travar acesso ao disco;
- força leitura completa da unidade;
- pode acelerar desgaste quando usado com frequência desnecessária.

### Implementação recomendada

No modo automático:

```cmd
chkdsk C: /scan
```

No modo manutenção profunda:

```cmd
chkdsk C: /r
```

Se o volume estiver em uso, o script deve perguntar:

```text
Deseja agendar CHKDSK /R para a próxima reinicialização? [S/N]
```

### Logs desejados

```text
[PROCESSING] Inicializando verificação lógica do disco C:...
[PROCESSING] Verificando status do volume...
[PROCESSING] Executando CHKDSK em modo online...
[PROCESSING] Detectando erros de sistema de arquivos...
[PROCESSING] Finalizando análise e salvando log...
```

### Arquivo de log

```text
logs/YYYY-MM-DD_HH-mm-ss/processing_chkdsk.log
```

---

## Terminal 04 — CLEANING

### Cor

Laranja.

### Palavra grande no terminal

```text
 ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗
██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║████╗  ██║██╔════╝
██║     ██║     █████╗  ███████║██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║██║╚██╗██║██║   ██║
╚██████╗███████╗███████╗██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝
 ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝
```

### Função

Otimizar unidade e exibir progresso detalhado.

### Comando real

```cmd
defrag C: /O /U /V
```

### Logs desejados

```text
[CLEANING] Inicializando otimização da unidade C:...
[CLEANING] Detectando tipo da mídia...
[CLEANING] Aplicando estratégia de otimização do Windows...
[CLEANING] Exibindo progresso detalhado...
[CLEANING] Processo finalizado. Salvando log...
```

### Arquivo de log

```text
logs/YYYY-MM-DD_HH-mm-ss/cleaning_optimize_drive.log
```

---

## 5. Layout dos terminais

## Requisito visual

O sistema deve abrir os 4 terminais no **monitor 1** em formato 2x2.

### Distribuição

```text
Monitor 1
1920x1080 exemplo

┌──────────────────────┬──────────────────────┐
│ X=0    Y=0           │ X=960  Y=0           │
│ W=960  H=540         │ W=960  H=540         │
├──────────────────────┼──────────────────────┤
│ X=0    Y=540         │ X=960  Y=540         │
│ W=960  H=540         │ W=960  H=540         │
└──────────────────────┴──────────────────────┘
```

### Regra

O script não deve assumir resolução fixa. Ele deve detectar:

- monitor primário;
- largura;
- altura;
- escala;
- posição X/Y do monitor;
- taskbar, se possível.

### Implementação sugerida

Usar PowerShell com Win32 API:

- `EnumDisplayMonitors`;
- `GetMonitorInfo`;
- `SetWindowPos`;
- `MoveWindow`;
- `Get-Process`;
- `MainWindowHandle`.

Alternativa mais simples:

- abrir 1 janela do Windows Terminal maximizada;
- criar 4 painéis internos usando `wt.exe split-pane`;
- cada painel roda um runner separado.

### Recomendação

Preferir **Windows Terminal com 4 painéis**, porque:

- facilita fonte;
- facilita cores;
- facilita layout;
- é mais moderno que o CMD clássico;
- permite usar `Cascadia Mono`;
- permite perfis visuais por tema;
- evita limitações antigas do console clássico.

---

## 6. Fonte e aparência

## Fonte recomendada

```text
Cascadia Mono
```

Alternativas:

```text
Cascadia Code
Consolas
JetBrains Mono
Fira Code
```

### Observação

Alterar fonte do `cmd.exe` clássico em tempo real é limitado. A abordagem correta é usar o **Windows Terminal** com arquivo de configuração.

### Configuração desejada do Windows Terminal

Criar ou orientar configuração com:

- fonte: `Cascadia Mono`;
- tamanho: 12 a 14;
- cursor: `bar` ou `filledBox`;
- fundo escuro;
- opacidade 85% a 95%;
- padding interno;
- título por terminal;
- cores por painel.

### Cores

| Terminal | Nome       | Cor principal | ANSI sugerido |
|---------:|------------|---------------|---------------|
| 01       | ANALYTICS  | Verde         | `\x1b[32m` |
| 02       | SCANNING   | Azul          | `\x1b[34m` |
| 03       | PROCESSING | Vermelho      | `\x1b[31m` |
| 04       | CLEANING   | Laranja       | `\x1b[38;5;208m` |

---

## 7. Estrutura de pastas do projeto

```text
windows-maintenance-terminal-grid/
│
├── README.md
├── install.ps1
├── uninstall.ps1
├── launcher.ps1
├── launcher_startup_safe.ps1
├── launcher_maintenance_real.ps1
│
├── config/
│   ├── terminals.json
│   ├── visual_settings.json
│   └── schedule_settings.json
│
├── scripts/
│   ├── common/
│   │   ├── banner.ps1
│   │   ├── logger.ps1
│   │   ├── spinner.ps1
│   │   ├── admin_check.ps1
│   │   ├── monitor_layout.ps1
│   │   └── command_runner.ps1
│   │
│   ├── terminals/
│   │   ├── analytics_dism.ps1
│   │   ├── scanning_sfc.ps1
│   │   ├── processing_chkdsk.ps1
│   │   └── cleaning_optimize.ps1
│   │
│   └── startup/
│       ├── create_scheduled_task.ps1
│       └── remove_scheduled_task.ps1
│
├── logs/
│   └── YYYY-MM-DD_HH-mm-ss/
│       ├── analytics_dism_restorehealth.log
│       ├── scanning_sfc_scannow.log
│       ├── processing_chkdsk.log
│       ├── cleaning_optimize_drive.log
│       └── summary.json
│
└── assets/
    └── ascii/
        ├── analytics.txt
        ├── scanning.txt
        ├── processing.txt
        └── cleaning.txt
```

---

## 8. Arquivo de configuração dos terminais

Criar `config/terminals.json`.

```json
{
  "defaultMode": "startup_safe",
  "terminalEngine": "windows_terminal",
  "fontFace": "Cascadia Mono",
  "fontSize": 13,
  "opacity": 92,
  "monitor": "primary",
  "layout": "grid_2x2",
  "delayAfterLoginSeconds": 30,
  "terminals": [
    {
      "id": "analytics",
      "title": "ANALYTICS — DISM RESTOREHEALTH",
      "banner": "ANALYTICS",
      "colorName": "green",
      "ansiColor": "\u001b[32m",
      "script": "scripts/terminals/analytics_dism.ps1",
      "command": "DISM /Online /Cleanup-Image /RestoreHealth",
      "autoRunInStartupSafe": false,
      "autoRunInMaintenanceReal": true
    },
    {
      "id": "scanning",
      "title": "SCANNING — SFC SCANNOW",
      "banner": "SCANNING",
      "colorName": "blue",
      "ansiColor": "\u001b[34m",
      "script": "scripts/terminals/scanning_sfc.ps1",
      "command": "sfc /scannow",
      "autoRunInStartupSafe": false,
      "autoRunInMaintenanceReal": true
    },
    {
      "id": "processing",
      "title": "PROCESSING — CHKDSK",
      "banner": "PROCESSING",
      "colorName": "red",
      "ansiColor": "\u001b[31m",
      "script": "scripts/terminals/processing_chkdsk.ps1",
      "startupCommand": "chkdsk C: /scan",
      "deepCommand": "chkdsk C: /r",
      "autoRunInStartupSafe": true,
      "autoRunInMaintenanceReal": true
    },
    {
      "id": "cleaning",
      "title": "CLEANING — DRIVE OPTIMIZATION",
      "banner": "CLEANING",
      "colorName": "orange",
      "ansiColor": "\u001b[38;5;208m",
      "script": "scripts/terminals/cleaning_optimize.ps1",
      "command": "defrag C: /O /U /V",
      "autoRunInStartupSafe": false,
      "autoRunInMaintenanceReal": true
    }
  ]
}
```

---

## 9. Fluxo de inicialização automática

## Startup seguro

Ao ligar o Windows:

1. Aguardar 30 segundos após login.
2. Verificar se já existe uma instância rodando.
3. Criar pasta de log com data/hora.
4. Abrir Windows Terminal em grade 2x2.
5. Cada painel exibe:
   - banner grande;
   - loading;
   - logs de inicialização;
   - status do sistema;
   - verificações leves.
6. Não executar manutenção pesada automaticamente.
7. Salvar logs.
8. Manter janelas abertas após finalizar.

### Exemplo de logs do startup seguro

```text
[BOOT] Windows Maintenance Terminal Grid iniciado.
[BOOT] Modo: startup_safe.
[BOOT] Monitor primário detectado.
[BOOT] Layout 2x2 aplicado.
[BOOT] Coletando informações do sistema...
[BOOT] CPU, RAM e disco analisados.
[BOOT] Nenhum comando pesado foi executado automaticamente.
```

---

## 10. Fluxo de manutenção real

Executado manualmente pelo usuário.

1. Verificar administrador.
2. Abrir 4 terminais.
3. Exibir banner e loading.
4. Rodar comandos reais.
5. Salvar logs por terminal.
6. Gerar `summary.json`.
7. Exibir resumo final.

### Ordem recomendada dos comandos

Embora existam 4 terminais, os comandos pesados devem ter controle para evitar sobrecarga.

Ordem segura:

1. `DISM /Online /Cleanup-Image /RestoreHealth`
2. `sfc /scannow`
3. `chkdsk C: /scan` ou `chkdsk C: /r` sob confirmação
4. `defrag C: /O /U /V`

### Observação

Se o objetivo visual for manter os 4 terminais ativos ao mesmo tempo, os terminais podem abrir juntos, mas o script deve controlar a execução real por fila.

Exemplo:

```text
TERMINAL 01: rodando DISM
TERMINAL 02: aguardando DISM finalizar para iniciar SFC
TERMINAL 03: aguardando SFC finalizar para iniciar CHKDSK
TERMINAL 04: aguardando CHKDSK finalizar para iniciar otimização
```

Isso mantém o visual 2x2 sem forçar tudo em paralelo.

---

## 11. Loading e animações

## Loading inicial

Cada terminal deve exibir uma animação antes dos comandos.

Exemplo:

```text
[ANALYTICS] Loading system core [■□□□□□□□□□] 10%
[ANALYTICS] Loading system core [■■□□□□□□□□] 20%
[ANALYTICS] Loading system core [■■■□□□□□□□] 30%
[ANALYTICS] Loading system core [■■■■□□□□□□] 40%
[ANALYTICS] Loading system core [■■■■■□□□□□] 50%
[ANALYTICS] Loading system core [■■■■■■□□□□] 60%
[ANALYTICS] Loading system core [■■■■■■■□□□] 70%
[ANALYTICS] Loading system core [■■■■■■■■□□] 80%
[ANALYTICS] Loading system core [■■■■■■■■■□] 90%
[ANALYTICS] Loading system core [■■■■■■■■■■] 100%
```

## Spinner

```text
[PROCESSING] Working |
[PROCESSING] Working /
[PROCESSING] Working -
[PROCESSING] Working \
```

## Efeito de digitação

Criar função para imprimir texto caractere por caractere:

```text
Initializing Windows Maintenance Core...
Loading diagnostics modules...
Injecting terminal visual profile...
Starting controlled maintenance sequence...
```

---

## 12. Logs reais e logs visuais

O projeto pode ter logs decorativos, mas eles não devem mentir sobre resultado técnico.

### Permitido

```text
[VISUAL] Carregando módulo de análise...
[VISUAL] Preparando interface...
[STATUS] CPU atual: 18%
[STATUS] RAM em uso: 62%
[STATUS] Disco C: livre: 128 GB
```

### Não permitido

```text
[OK] 500 erros corrigidos
```

Não exibir correções falsas.

### Regra

Só mostrar como corrigido aquilo que o comando real retornou.

---

## 13. Captura de saída dos comandos

Cada comando deve ser executado com captura de saída.

Exemplo em PowerShell:

```powershell
$command = "DISM.exe"
$args = "/Online /Cleanup-Image /RestoreHealth"

& $command $args.Split(" ") 2>&1 | Tee-Object -FilePath $LogPath -Append
```

Para comandos com argumentos complexos, preferir array:

```powershell
& DISM.exe /Online /Cleanup-Image /RestoreHealth 2>&1 | Tee-Object -FilePath $LogPath -Append
```

### Padrão de log

```text
[2026-06-19 04:32:10] [ANALYTICS] Starting DISM RestoreHealth
[2026-06-19 04:32:11] [ANALYTICS] Command: DISM /Online /Cleanup-Image /RestoreHealth
[2026-06-19 04:34:20] [ANALYTICS] Output: ...
[2026-06-19 04:50:44] [ANALYTICS] ExitCode: 0
```

---

## 14. Verificação de administrador

Os comandos reais precisam de privilégios administrativos.

Criar função:

```powershell
function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
```

Se não for administrador:

```text
[SECURITY] Permissão administrativa não detectada.
[SECURITY] Reiniciando launcher como administrador...
```

O script deve relançar com `Start-Process -Verb RunAs`.

---

## 15. Agendamento no boot

Criar tarefa agendada no Windows com:

- nome: `WindowsMaintenanceTerminalGrid`;
- trigger: `At logon`;
- delay: 30 segundos;
- executar somente quando usuário estiver logado;
- executar com privilégios mais altos;
- ação: rodar `launcher_startup_safe.ps1`.

### PowerShell esperado

```powershell
$Action = New-ScheduledTaskAction `
  -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ProjectRoot\launcher_startup_safe.ps1`""

$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal `
  -UserId $env:USERNAME `
  -LogonType Interactive `
  -RunLevel Highest

Register-ScheduledTask `
  -TaskName "WindowsMaintenanceTerminalGrid" `
  -Action $Action `
  -Trigger $Trigger `
  -Principal $Principal `
  -Description "Abre o grid visual de manutenção do Windows no login."
```

### Importante

Não usar `Run whether user is logged on or not`, porque nesse modo a janela pode não aparecer na área de trabalho.

---

## 16. Proteção contra execução duplicada

Criar lock file:

```text
%LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\grid.lock
```

Se o lock existir e o processo ainda estiver rodando:

```text
[BOOT] Instância já ativa. Abortando nova abertura.
```

Se o lock existir, mas o processo não existir:

```text
[BOOT] Lock antigo detectado. Limpando lock e continuando.
```

---

## 17. Resumo final

Após a execução, gerar:

```text
logs/YYYY-MM-DD_HH-mm-ss/summary.json
```

Exemplo:

```json
{
  "startedAt": "2026-06-19T04:32:10",
  "finishedAt": "2026-06-19T05:12:44",
  "mode": "maintenance_real",
  "commands": [
    {
      "terminal": "ANALYTICS",
      "command": "DISM /Online /Cleanup-Image /RestoreHealth",
      "exitCode": 0,
      "status": "completed"
    },
    {
      "terminal": "SCANNING",
      "command": "sfc /scannow",
      "exitCode": 0,
      "status": "completed"
    },
    {
      "terminal": "PROCESSING",
      "command": "chkdsk C: /scan",
      "exitCode": 0,
      "status": "completed"
    },
    {
      "terminal": "CLEANING",
      "command": "defrag C: /O /U /V",
      "exitCode": 0,
      "status": "completed"
    }
  ]
}
```

---

## 18. Prompt base para o Claude Code

```text
Você é um engenheiro Windows/PowerShell especialista em automação visual, manutenção do Windows, Windows Terminal, Scheduled Tasks e logs avançados.

Implemente um projeto chamado Windows Maintenance Terminal Grid.

Objetivo:
Criar um utilitário para Windows que abre automaticamente 4 terminais em layout 2x2 no monitor principal, com estética hacker, banners grandes, loading animado, logs detalhados, cores por terminal e execução controlada de comandos de manutenção do Windows.

Estrutura obrigatória:
- README.md
- install.ps1
- uninstall.ps1
- launcher.ps1
- launcher_startup_safe.ps1
- launcher_maintenance_real.ps1
- config/terminals.json
- config/visual_settings.json
- scripts/common/banner.ps1
- scripts/common/logger.ps1
- scripts/common/spinner.ps1
- scripts/common/admin_check.ps1
- scripts/common/monitor_layout.ps1
- scripts/common/command_runner.ps1
- scripts/terminals/analytics_dism.ps1
- scripts/terminals/scanning_sfc.ps1
- scripts/terminals/processing_chkdsk.ps1
- scripts/terminals/cleaning_optimize.ps1
- scripts/startup/create_scheduled_task.ps1
- scripts/startup/remove_scheduled_task.ps1
- logs/

Terminais:
1. ANALYTICS — verde — DISM /Online /Cleanup-Image /RestoreHealth
2. SCANNING — azul — sfc /scannow
3. PROCESSING — vermelho — chkdsk C: /scan no modo seguro e chkdsk C: /r apenas no modo profundo sob confirmação
4. CLEANING — laranja — defrag C: /O /U /V

Regras críticas:
- Não rodar DISM, SFC, CHKDSK /r e defrag em paralelo sem controle.
- Abrir os 4 terminais visualmente juntos, mas controlar a execução real por fila quando estiver no modo manutenção real.
- O modo startup_safe deve abrir automaticamente no login e executar somente verificações leves/logs/status, sem comandos pesados.
- O modo maintenance_real deve ser executado manualmente e pedir elevação de administrador.
- Criar logs reais em logs/YYYY-MM-DD_HH-mm-ss/.
- Criar summary.json com status, horário, exitCode e comando executado.
- Não exibir correções falsas. Logs visuais são permitidos, mas resultados técnicos precisam vir da saída real dos comandos.
- Preferir Windows Terminal com 4 painéis. Caso não seja possível, abrir 4 janelas e posicionar com Win32 API.
- Usar fonte Cascadia Mono, fundo escuro, título por terminal, cores ANSI:
  - verde: \x1b[32m
  - azul: \x1b[34m
  - vermelho: \x1b[31m
  - laranja: \x1b[38;5;208m
- Criar install.ps1 para instalar tarefa agendada de startup seguro.
- Criar uninstall.ps1 para remover tarefa agendada e limpar configuração.
- Criar README.md com instruções de uso.

Experiência visual:
- Cada terminal deve começar com banner ASCII grande:
  - ANALYTICS
  - SCANNING
  - PROCESSING
  - CLEANING
- Exibir loading progressivo de 0% a 100%.
- Exibir efeito de digitação em mensagens iniciais.
- Exibir logs com timestamp.
- Manter terminal aberto no fim mostrando resumo.

Entregáveis:
- Código PowerShell funcional.
- Configuração JSON.
- README.
- Segurança contra execução duplicada com lock file.
- Teste manual documentado.
- Feedback final em Markdown informando o que foi implementado, arquivos criados, como instalar, como remover e como executar manutenção real.
```

---

## 19. Checklist de aceite

O projeto será considerado pronto quando:

- [ ] `install.ps1` instala a tarefa agendada.
- [ ] `uninstall.ps1` remove a tarefa agendada.
- [ ] Ao ligar o Windows, o modo `startup_safe` abre automaticamente.
- [ ] O layout aparece em 2x2.
- [ ] Cada terminal tem cor diferente.
- [ ] Cada terminal mostra banner ASCII grande.
- [ ] Cada terminal mostra loading.
- [ ] Logs aparecem no terminal.
- [ ] Logs são salvos em arquivo.
- [ ] O modo real pede administrador.
- [ ] O modo real executa comandos reais.
- [ ] `chkdsk C: /r` não roda sem confirmação.
- [ ] Existe proteção contra execução duplicada.
- [ ] Existe `summary.json`.
- [ ] O README explica instalação, remoção e uso.

---

## 20. Observação final

Visualmente, o projeto pode ter aparência intensa e tecnológica, mas tecnicamente precisa ser controlado.

A melhor arquitetura é:

```text
Boot automático = visual seguro + logs leves
Manutenção real = manual + administrador + comandos controlados
```

Isso entrega a estética desejada sem prejudicar a performance do notebook.
