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
  
  subgraph task_desez_update_database_daily["task: desez-update-database-daily"]
    desez_import["desez_import"]:::step
  end
  style task_desez_update_database_daily fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

