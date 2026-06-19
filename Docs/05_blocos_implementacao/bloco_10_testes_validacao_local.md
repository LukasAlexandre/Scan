# Bloco 10 - Testes e Validacao Local

## Objetivo

Criar e executar um fluxo de teste local completo para validar modos, layout, logs, lock, tarefa agendada e remocao.

## Contexto

Antes do README final, o projeto precisa demonstrar que os comportamentos principais funcionam em ambiente Windows real ou controlado.

## Escopo

- Criar checklist de validacao.
- Testar sem administrador.
- Testar com administrador.
- Testar com e sem `wt.exe`.
- Testar startup safe.
- Testar maintenance real em dry run.
- Testar tarefa agendada.
- Testar uninstall.

## Fora de Escopo

- Executar comandos reais em maquina do usuario sem autorizacao explicita.
- Automatizar teste destrutivo.
- Forcar reboot para CHKDSK.

## Arquivos que devem ser criados ou alterados

- `Docs/08_testes/fluxo_de_testes.md`
- `Docs/08_testes/checklist_de_validacao.md`
- `Docs/10_feedback/feedback_bloco_10.md` opcional.

## Funcoes esperadas

Nenhuma nova obrigatoria. Ajustes podem ser feitos em funcoes existentes se testes revelarem falhas.

## Configuracoes necessarias

- Configuracao de dry run.
- Caminho de logs.
- Ambiente com Windows Terminal para teste positivo.
- Ambiente ou simulacao sem `wt.exe` para fallback.

## Regras tecnicas

- Registrar resultado de cada cenario.
- Diferenciar teste dry run de teste real.
- Nao executar `chkdsk C: /r` sem confirmacao.
- Nao considerar aprovado sem logs.

## Riscos

- Teste manual incompleto.
- Teste com admin executar algo real sem querer.
- Fallback sem `wt.exe` nao ser validado.

## Passo a passo de implementacao

1. Revisar cenarios em `Docs/08_testes/`.
2. Executar testes seguros.
3. Registrar evidencia textual.
4. Corrigir falhas pequenas.
5. Marcar pendencias maiores.

## Fluxo de teste

Usar `Docs/08_testes/fluxo_de_testes.md` como roteiro oficial.

## Criterios de aceite

- Todos os cenarios foram executados ou marcados com motivo.
- Logs e summary foram inspecionados.
- Startup e uninstall foram validados.
- Riscos residuais foram documentados.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 10. Execute e registre os testes locais documentados, priorizando dry run e seguranca. Nao execute comandos destrutivos ou CHKDSK profundo sem confirmacao explicita.
```

## Feedback esperado apos implementacao

- Resultado por cenario.
- Logs inspecionados.
- Falhas encontradas.
- Recomendacoes antes do README final.
