# Task produktivnost-surs_update

| | |
|---|---|
| Task Scheduler | `\produktivnost-surs_update` |
| Kdaj | dnevno 10:30 |
| .bat | `batch-scripts/produktivnost-surs_update.bat` |
| Log | `logs/produktivnost-surs_update.Rout` |
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
  produktivnost_surs["produktivnost_surs<br/><small>task produktivnost-surs_update</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

