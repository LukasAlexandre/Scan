# Dependencias e Pre-Requisitos

## Objetivo

Listar os requisitos de ambiente e dependencias tecnicas para implementar e testar o projeto.

## Contexto

O projeto usa recursos do Windows e deve funcionar com o minimo de dependencias externas. Ainda assim, alguns recursos melhoram a experiencia.

## Pre-Requisitos

| Item | Obrigatorio | Observacao |
| --- | --- | --- |
| Windows 10/11 | Sim | Ambiente alvo |
| PowerShell 5.1 | Sim | Disponivel nativamente no Windows |
| PowerShell 7+ | Nao | Recomendado para desenvolvimento |
| Windows Terminal | Nao | Preferencial para grid 2x2 |
| Cascadia Mono | Nao | Fonte recomendada |
| Administrador | Sim para modo real | Necessario para manutencao |
| Politica de execucao permissiva | Depende | Pode usar `-ExecutionPolicy Bypass` no comando |

## Decisoes Tecnicas

- Nenhuma dependencia de pacote externo deve ser obrigatoria na primeira versao.
- `wt.exe` deve ser detectado antes de uso.
- Scripts devem resolver caminhos relativos ao root do projeto.
- A tarefa agendada deve rodar em sessao interativa.

## Regras

- Se uma dependencia opcional faltar, usar fallback ou registrar instrucao clara.
- Se uma dependencia obrigatoria faltar, abortar com mensagem objetiva.
- Nao tentar instalar Windows Terminal automaticamente nesta fase.

## Arquivos Relacionados

- `Docs/07_configuracoes/configuracoes_necessarias.md`
- `Docs/09_execucao/como_instalar.md`
- `Docs/09_execucao/troubleshooting.md`

## Riscos

- Politica de execucao bloquear script.
- Usuario sem admin tentar modo real.
- Windows Terminal ausente mudar o layout esperado.

## Criterios de Aceite

- Dependencias obrigatorias e opcionais estao separadas.
- Ha orientacao para ausencia de `wt.exe`.
- Pre-requisitos de admin estao claros.
