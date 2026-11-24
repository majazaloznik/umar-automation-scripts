# Task tgg-si-update

| | |
|---|---|
| Task Scheduler | `\tgg-si-update` |
| Kdaj | onemogočen (bil petek 10:45) |
| .bat | `batch-scripts/tgg-si-update.bat` |
| Log | `logs/tgg-tabela-update.Rout` |
| Email (ime runa) | — |
| R | 4.1.3 |
| Teče po | — |
| Pred | — |
| Ponovni zagon | varen |

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  tgg_tabela_si["tgg_tabela_si<br/><small>task tgg-si-update</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

