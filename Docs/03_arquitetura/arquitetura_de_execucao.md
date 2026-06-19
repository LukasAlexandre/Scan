# Arquitetura de Execucao

## Objetivo

Descrever como os modos de execucao devem iniciar, validar ambiente, abrir terminais e controlar comandos.

## Contexto

A experiencia visual abre quatro terminais, mas a execucao de manutencao real deve ser coordenada. O sistema nao deve confundir grid visual com paralelismo irrestrito.

## Fluxo `startup_safe`

```text
launcher_startup_safe.ps1
  -> aguarda delay configurado
  -> cria/valida lock file
  -> cria pasta de logs
  -> abre grid 2x2
  -> cada terminal exibe banner, loading e status leve
  -> grava logs
  -> remove lock quando aplicavel
```

## Fluxo `maintenance_real`

```text
launcher_maintenance_real.ps1
  -> valida administrador
  -> cria/valida lock file
  -> cria pasta de logs
  -> abre grid 2x2
  -> inicia fila controlada de comandos
  -> registra saida e exit code
  -> gera summary.json
  -> mantem terminais abertos para leitura
```

## Decisoes Tecnicas

- O launcher real deve coordenar ou sinalizar ordem de execucao.
- A fila pode ser implementada por lock/sentinelas de etapa ou por processo controlador.
- `Invoke-CommandWithLog` sera a funcao unica para comandos reais.
- `Write-SummaryJson` centraliza o resumo.

## Regras

- `maintenance_real` deve abortar se nao houver administrador.
- `startup_safe` deve abortar comandos pesados mesmo se configuracao estiver incorreta.
- `chkdsk C: /r` deve exigir confirmacao interativa.
- Falha em um comando deve ser registrada e nao escondida por visual.

## Arquivos Relacionados

- `Docs/03_arquitetura/modos_de_operacao.md`
- `Docs/05_blocos_implementacao/bloco_05_launcher_grid_2x2.md`
- `Docs/05_blocos_implementacao/bloco_07_modo_maintenance_real.md`

## Riscos

- Janela de terminal abrir sem conseguir carregar script.
- Fila mal implementada deixar terminais esperando indefinidamente.
- Falha de admin causar loop de relancamento.

## Criterios de Aceite

- Fluxos de execucao estao separados por modo.
- O modo real tem validacao administrativa.
- A arquitetura registra logs antes e depois dos comandos.
