# Modos de Operacao

## Objetivo

Definir os modos aceitos pelo projeto, suas permissividades e seus limites.

## Contexto

O projeto precisa equilibrar impacto visual e seguranca. Para isso, todo comportamento depende do modo de operacao selecionado.

## Modos

| Modo | Entrada planejada | Finalidade | Comandos pesados |
| --- | --- | --- | --- |
| `startup_safe` | `launcher_startup_safe.ps1` | Abrir no login com visual e checks leves | Bloqueados |
| `maintenance_real` | `launcher_maintenance_real.ps1` | Rodar manutencao real sob demanda | Permitidos com admin |
| `maintenance_real_deep` | Opcao interna ou parametro | Permitir CHKDSK profundo | Apenas com confirmacao |
| `visual_only` | Opcional para testes | Testar banners, cores e logs | Bloqueados |

## Decisoes Tecnicas

- O modo deve ser passado explicitamente aos scripts de terminal.
- A configuracao pode sugerir um modo padrao, mas o launcher tem a palavra final.
- O modo de login deve ser conservador mesmo se o JSON for alterado indevidamente.

## Regras

- `startup_safe` nao executa DISM, SFC, CHKDSK `/r` ou defrag.
- `maintenance_real` exige administrador.
- `maintenance_real_deep` exige confirmacao para `chkdsk C: /r`.
- `visual_only` deve ser usado em testes sem tocar no sistema.

## Arquivos Relacionados

- `Docs/07_configuracoes/terminals_json.md`
- `Docs/08_testes/testes_modo_startup_safe.md`
- `Docs/08_testes/testes_modo_maintenance_real.md`

## Riscos

- Parametro de modo ausente cair em modo real por engano.
- JSON permitir comando pesado no startup.
- Teste visual ser confundido com manutencao real.

## Criterios de Aceite

- Cada modo tem entrada, finalidade e limite.
- O modo seguro e o padrao operacional para startup.
- O modo profundo e separado e protegido.
