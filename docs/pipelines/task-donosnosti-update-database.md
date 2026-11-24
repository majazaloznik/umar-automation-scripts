# Task donosnosti-update-database

| | |
|---|---|
| Task Scheduler | `\donosnosti-update-database` |
| Kdaj | dnevno 12:00 |
| .bat | `batch-scripts/donosnosti-update-database.bat` |
| Log | `logs/donosnosti-update-database.log` |
| Email (ime runa) | — |
| R | — |
| Teče po | — |
| Pred | — |
| Ponovni zagon | varen |

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  donosnosti_import["donosnosti_import<br/><small>task donosnosti-update-database</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

