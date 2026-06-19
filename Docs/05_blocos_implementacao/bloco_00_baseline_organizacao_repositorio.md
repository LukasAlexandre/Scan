# Bloco 00 - Baseline e Organizacao do Repositorio

## Objetivo

Validar a estrutura atual, preservar a ideia original, criar a estrutura base do projeto e preparar um README inicial sem implementar logica pesada.

## Contexto

O repositorio atual possui `Docs/` e a ideia original em `Docs/ideia/planejamento_windows_maintenance_terminal_grid.md`. Nao ha scripts PowerShell, configs JSON ou README na raiz no momento da organizacao documental.

## Escopo

- Criar ou validar pastas base do codigo futuro.
- Criar `README.md` inicial.
- Criar `.gitkeep` apenas se for necessario preservar pastas vazias.
- Copiar a ideia original para `Docs/00_ideia_original/`.
- Registrar estrutura encontrada.

## Fora de Escopo

- Implementar comandos DISM, SFC, CHKDSK ou defrag.
- Criar tarefa agendada.
- Executar scripts como administrador.
- Implementar layout real do Windows Terminal.

## Arquivos que devem ser criados ou alterados

- `README.md`
- `config/`
- `scripts/common/`
- `scripts/terminals/`
- `scripts/startup/`
- `assets/ascii/`
- `logs/`
- `Docs/10_feedback/feedback_bloco_00.md` se o implementador optar por feedback por bloco.

## Funcoes esperadas

Nenhuma funcao PowerShell funcional e obrigatoria neste bloco.

## Configuracoes necessarias

Nenhuma configuracao JSON funcional. Apenas preparar diretorios para o bloco 01.

## Regras tecnicas

- Nao apagar arquivos existentes.
- Nao mover a ideia original sem manter copia rastreavel.
- Nao criar scripts que executem manutencao real.
- Usar nomes em `snake_case`.

## Riscos

- Apagar pastas antigas sem necessidade.
- Criar arquivos placeholder que parecam funcionais.
- Versionar logs reais por engano.

## Passo a passo de implementacao

1. Rodar listagem segura do repositorio.
2. Confirmar arquivos existentes.
3. Criar pastas base do codigo.
4. Copiar ideia original para area de referencia se ainda nao existir.
5. Criar README inicial com aviso de planejamento.
6. Registrar feedback do bloco.

## Fluxo de teste

1. Listar arquivos com `rg --files`.
2. Confirmar que `README.md` existe.
3. Confirmar que a ideia original continua acessivel.
4. Confirmar que nenhum `.ps1` funcional pesado foi criado.

## Criterios de aceite

- Estrutura base existe.
- Ideia original foi preservada.
- README inicial aponta para `Docs/`.
- Nenhum comando de manutencao foi executado.

## Prompt sugerido para o Claude Code implementar este bloco

```text
Implemente somente o Bloco 00. Valide a estrutura atual, crie pastas base do codigo, preserve a ideia original em Docs/00_ideia_original, crie README inicial e registre feedback. Nao implemente comandos de manutencao, nao crie tarefa agendada e nao execute scripts como administrador.
```

## Feedback esperado apos implementacao

- Estrutura encontrada.
- Arquivos criados.
- Arquivos preservados.
- Pendencias para o Bloco 01.
- Confirmacao de que nenhum comando pesado foi executado.
