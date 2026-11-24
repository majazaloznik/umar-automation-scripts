# Task mf_update_database

| | |
|---|---|
| Task Scheduler | `\mf_update_database` |
| Kdaj | mesečno, prvi in zadnji delovni dan 10:15 |
| .bat | `batch-scripts/mf_update_database.bat` |
| Log | `logs/mf_update.Rout` |
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
  mf_import["mf_import<br/><small>task mf_update_database</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

