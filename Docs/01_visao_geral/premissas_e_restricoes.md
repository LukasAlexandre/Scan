# Premissas e Restricoes

## Objetivo

Registrar as condicoes assumidas para o projeto e as restricoes que a implementacao deve obedecer.

## Contexto

O projeto atua em ambiente Windows e pode chamar utilitarios nativos de manutencao. Por isso, a documentacao precisa evitar qualquer ambiguidade sobre privilegio, agendamento, consumo de recursos e comandos de disco.

## Premissas

- O alvo principal e Windows 10 ou Windows 11.
- PowerShell 5.1 deve ser suportado; PowerShell 7+ e desejavel.
- Windows Terminal e recomendado, mas nao obrigatorio.
- O monitor principal deve ser usado como referencia para o grid.
- O usuario aceita abrir janelas visiveis durante a execucao.
- A manutencao real sera iniciada manualmente.

## Restricoes Tecnicas

- Nao executar comandos reais durante a fase de organizacao documental.
- Nao criar tarefa agendada real nesta fase.
- Nao depender de resolucao fixa como 1920x1080.
- Nao executar `chkdsk C: /r` sem confirmacao explicita.
- Nao executar comandos pesados em paralelo sem controle de fila.
- Nao apagar a ideia original.

## Decisoes Tecnicas

- Lock file em `%LOCALAPPDATA%` sera usado para evitar duplicidade.
- Logs de execucao ficarao em `logs/YYYY-MM-DD_HH-mm-ss/`.
- Configuracao de terminais ficara em `config/terminals.json`.
- Configuracao visual ficara em `config/visual_settings.json`.
- Configuracao de agendamento ficara em `config/schedule_settings.json`.

## Regras

- Qualquer script que altere estado do sistema deve declarar pre-condicoes.
- Qualquer script real deve registrar comando, horario, exit code e status.
- Qualquer fallback deve ser documentado antes de ser implementado.
- O modo startup nao deve degradar o boot.

## Arquivos Relacionados

- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/03_arquitetura/estrategia_de_logs.md`
- `Docs/05_blocos_implementacao/bloco_06_modo_startup_safe.md`
- `Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md`

## Riscos

- Maquina sem Windows Terminal.
- Politica de execucao PowerShell bloqueando scripts locais.
- Usuario sem permissao administrativa.
- CHKDSK profundo exigir reinicializacao.
- Defrag/Optimize consumir recursos por tempo prolongado.

## Criterios de Aceite

- Premissas e restricoes estao explicitas.
- Comandos pesados estao protegidos por regras.
- A documentacao reconhece dependencias reais do Windows.
