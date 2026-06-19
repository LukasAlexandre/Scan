# Criterios de Aceite

## Objetivo

Definir quando o projeto pode ser considerado pronto para uso inicial.

## Contexto

Os criterios combinam requisitos visuais, seguranca operacional, logs, instalacao e remocao.

## Criterios Obrigatorios

- [ ] `install.ps1` instala tarefa agendada de startup seguro.
- [ ] `uninstall.ps1` remove tarefa agendada.
- [ ] `launcher_startup_safe.ps1` abre o grid sem comandos pesados.
- [ ] `launcher_maintenance_real.ps1` exige administrador.
- [ ] O layout aparece em 2x2 ou fallback documentado.
- [ ] Cada terminal possui cor e titulo.
- [ ] Cada terminal mostra banner e loading.
- [ ] Logs sao exibidos no terminal.
- [ ] Logs sao salvos em arquivo.
- [ ] `chkdsk C: /r` pede confirmacao.
- [ ] Existe protecao contra execucao duplicada.
- [ ] Existe `summary.json`.
- [ ] README explica instalacao, uso, remocao, logs e riscos.

## Decisoes Tecnicas

- Sem logs, a execucao nao e aceitavel.
- Sem lock, startup automatico nao e aceitavel.
- Sem dry run, modo real nao deve ser liberado.

## Regras

- Criterios visuais nao substituem criterios de seguranca.
- Qualquer item nao atendido deve virar pendencia.
- Testes devem informar se foram reais ou simulados.

## Arquivos Relacionados

- `Docs/08_testes/checklist_de_validacao.md`
- `Docs/04_planejamento/divisao_em_blocos.md`
- `Docs/09_execucao/`

## Riscos

- Aceitar projeto sem testar uninstall.
- Aceitar modo real sem validar admin.
- Aceitar summary sem cobrir falhas.

## Criterios de Aceite deste Documento

- Lista cobre instalacao, execucao, seguranca, logs e remocao.
- Pode ser usada como gate final do projeto.
