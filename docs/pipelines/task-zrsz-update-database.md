# Task zrsz-update-database

| | |
|---|---|
| Task Scheduler | `\zrsz-update-database` |
| Kdaj | mesečno 4. in 5. ob 09:00 |
| .bat | `batch-scripts/zrsz-update-database.bat` |
| Log | `logs/zrsz-update-database.Rout` |
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
  zrsz_import["zrsz_import<br/><small>task zrsz-update-database</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

