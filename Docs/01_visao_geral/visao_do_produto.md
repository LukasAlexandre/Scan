# Visao do Produto

## Objetivo

Documentar a visao do **Windows Maintenance Terminal Grid**, um utilitario visual para Windows que organiza quatro terminais em grade 2x2 para exibir rotinas de diagnostico, manutencao e logs com identidade visual propria.

## Contexto

O projeto nasce de uma ideia visual forte: abrir quatro terminais no monitor principal, cada um com cor, titulo, banner, loading e fluxo de log dedicado. A experiencia deve parecer tecnica e intensa, mas a execucao real precisa ser segura, controlada e transparente.

## Proposta do Produto

O sistema deve oferecer dois modos principais:

| Modo | Finalidade | Execucao pesada automatica |
| --- | --- | --- |
| `startup_safe` | Abrir o grid no login, mostrar status e logs leves | Nao |
| `maintenance_real` | Executar manutencao real sob demanda | Sim, com controle e administrador |

## Terminais do Grid

| Terminal | Cor | Funcao | Comando real planejado |
| --- | --- | --- | --- |
| ANALYTICS | Verde | Reparar imagem do Windows | `DISM /Online /Cleanup-Image /RestoreHealth` |
| SCANNING | Azul | Verificar arquivos protegidos | `sfc /scannow` |
| PROCESSING | Vermelho | Verificar disco | `chkdsk C: /scan` ou `chkdsk C: /r` sob confirmacao |
| CLEANING | Laranja | Otimizar unidade | `defrag C: /O /U /V` |

## Decisoes Tecnicas

- Separar experiencia visual de manutencao real.
- Usar Windows Terminal como motor preferencial do layout.
- Registrar logs reais em arquivo, sem inventar resultados.
- Exigir confirmacao para qualquer operacao profunda ou potencialmente demorada.
- Preparar a documentacao para implementacao incremental por blocos.

## Regras

- O modo automatico de login nao deve executar DISM, SFC, CHKDSK profundo ou defrag.
- O modo real deve exigir permissao administrativa.
- Cada terminal deve ter identidade visual consistente.
- Logs visuais podem existir, mas resultados tecnicos devem vir de comandos reais.

## Arquivos Relacionados

- `Docs/00_ideia_original/ideia_base_windows_maintenance_terminal_grid.md`
- `Docs/01_visao_geral/objetivo_do_sistema.md`
- `Docs/03_arquitetura/modos_de_operacao.md`
- `Docs/05_blocos_implementacao/`

## Riscos

- Execucao paralela de comandos pesados pode degradar desempenho.
- Tarefa agendada invisivel pode nao exibir janelas ao usuario.
- Dependencia de `wt.exe` pode falhar em maquinas sem Windows Terminal.
- Banners e efeitos visuais podem gerar falsa percepcao de sucesso se nao forem bem rotulados.

## Criterios de Aceite

- A visao diferencia claramente modo seguro e modo real.
- Os quatro terminais estao definidos com papel, cor e comando planejado.
- As regras de seguranca impedem manutencao pesada automatica.
- A documentacao aponta para os documentos tecnicos seguintes.
