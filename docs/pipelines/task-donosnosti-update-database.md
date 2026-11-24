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
  
  subgraph task_donosnosti_update_database["task: donosnosti-update-database"]
    donosnosti_import["donosnosti_import"]:::step
  end
  style task_donosnosti_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

