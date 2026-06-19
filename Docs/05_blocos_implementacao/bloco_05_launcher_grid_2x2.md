# Bloco 05 - Launcher Grid 2x2

## Objetivo

Planejar e implementar `launcher.ps1` para abrir os quatro scripts de terminal em layout 2x2, preferindo Windows Terminal e documentando fallback.

## Contexto

O grid visual e o ponto central da experiencia. O launcher deve abrir paineis corretamente e passar parametros seguros para cada terminal.

## Escopo

- Detectar `wt.exe`.
- Montar comando de abertura em quatro paineis.
- Aplicar titulos.
- Passar modo e pasta de log.
- Registrar fallback quando Windows Terminal nao existir.

## Fora de Escopo

- Criar tarefa agendada.
- Executar manutencao real sem modo explicito.
- Implementar Win32 API completa se o fallback for apenas planejado.

## Arquivos que devem ser criados ou alterados

- `launcher.ps1`
- `scripts/common/monitor_layout.ps1`
- `scripts/common/logger.ps1`

## Funcoes esperadas

- `Test-WindowsTerminalAvailable`
- `Start-TerminalGrid`
- `Start-TerminalFallbackWindows`
- `Get-PrimaryMonitorLayout` se fallback real for implementado.

## Configuracoes necessarias

- `terminalEngine`
- `layout`
- `fontFace`
- `fontSize`
- titulos e scripts dos terminais.

## Regras tecnicas

- Preferir Windows Terminal.
- Fallback deve avisar o usuario.
- O launcher deve aceitar `-Mode`.
- Modo padrao deve ser seguro.
- Nao executar comandos reais apenas por abrir o grid.

## Riscos

- Sintaxe `wt.exe` incorreta.
- Quoting de caminhos com espaco falhar.
- Fallback posicionar janelas fora da tela.

## Passo a passo de implementacao

1. Detectar root do projeto.
2. Carregar configuracoes.
3. Criar pasta de logs se necessario.
4. Montar comandos por terminal.
5. Testar `wt.exe` com comandos seguros.
6. Implementar fallback minimo.
7. Registrar log do launcher.

## Fluxo de teste

1. Rodar `launcher.ps1 -Mode visual_only`.
2. Confirmar abertura dos quatro paineis ou fallback.
3. Verificar titulos.
4. Confirmar logs do launcher.
5. Confirmar que nenhum comando pesado rodou.

## Criterios de aceite

- `launcher.ps1` abre quatro areas visuais.
- O modo e repassado para todos os terminais.
- Ha fallback documentado ou implementado.
- Quoting de caminhos funciona.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 05. Crie launcher.ps1 para abrir quatro scripts em Windows Terminal 2x2 no modo visual_only/startup_safe. Nao execute manutencao real. Inclua fallback seguro se wt.exe nao existir.
```

## Feedback esperado apos implementacao

- Comando `wt.exe` usado.
- Resultado do teste de grid.
- Limites do fallback.
- Pendencias para modo startup.
