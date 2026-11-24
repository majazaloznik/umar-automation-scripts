# Task desez-update-database-daily

| | |
|---|---|
| Task Scheduler | `\desez-update-database-daily` |
| Kdaj | dnevno 14:00 |
| .bat | `batch-scripts/desez_update_database.bat` |
| Log | `logs/desez_update.Rout` |
| Email (ime runa) | — |
| R | 4.5.2 |
| Teče po | — |
| Pred | — |
| Ponovni zagon | varen |

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  desez_import["desez_import<br/><small>task desez-update-database-daily</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

