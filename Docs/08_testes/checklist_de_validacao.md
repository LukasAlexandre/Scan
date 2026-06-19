# Checklist de Validacao

## Objetivo

Fornecer uma lista objetiva para validar a implementacao por bloco e no fim do projeto.

## Contexto

Este checklist deve ser usado pelo implementador antes de declarar o projeto pronto.

## Checklist

- [ ] Ideia original preservada em `Docs/00_ideia_original/`.
- [ ] README existe e aponta para a documentacao.
- [ ] `config/terminals.json` e valido.
- [ ] `config/visual_settings.json` e valido.
- [ ] `config/schedule_settings.json` e valido.
- [ ] Funcoes comuns carregam sem erro.
- [ ] `Write-Log` cria arquivo com timestamp.
- [ ] Lock file cria, detecta duplicidade e remove.
- [ ] Quatro banners aparecem.
- [ ] Loading visual nao simula resultado tecnico.
- [ ] Quatro scripts de terminal aceitam `-Mode`.
- [ ] `startup_safe` nao executa DISM.
- [ ] `startup_safe` nao executa SFC.
- [ ] `startup_safe` nao executa `chkdsk C: /r`.
- [ ] `startup_safe` nao executa defrag.
- [ ] `maintenance_real` exige admin.
- [ ] `maintenance_real` suporta dry run.
- [ ] `chkdsk C: /r` pede confirmacao.
- [ ] `wt.exe` e detectado quando existe.
- [ ] Fallback e registrado quando `wt.exe` nao existe.
- [ ] Logs por terminal sao criados.
- [ ] `summary.json` e criado no modo real.
- [ ] Tarefa agendada aponta para `launcher_startup_safe.ps1`.
- [ ] `uninstall.ps1` remove a tarefa.
- [ ] Troubleshooting cobre politica de execucao.

## Decisoes Tecnicas

- Itens de seguranca tem prioridade sobre itens visuais.
- Falha em logs ou lock bloqueia aprovacao do modo real.

## Regras

- Marcar item apenas apos teste.
- Registrar motivo quando item nao puder ser testado.
- Nao usar sucesso visual como prova de comando real.

## Arquivos Relacionados

- `Docs/08_testes/fluxo_de_testes.md`
- `Docs/08_testes/criterios_de_aceite.md`
- `Docs/05_blocos_implementacao/bloco_10_testes_validacao_local.md`

## Riscos

- Checklist ser preenchido sem evidencia.
- Ambiente unico esconder falhas de compatibilidade.

## Criterios de Aceite

- Todos os itens criticos estao marcados ou justificados.
- Pendencias estao documentadas.
