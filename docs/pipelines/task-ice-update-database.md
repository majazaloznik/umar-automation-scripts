# Task ice-update-database

| | |
|---|---|
| Task Scheduler | `\ice-update-database` |
| Kdaj | dnevno 07:00 |
| .bat | `batch-scripts/ice-update-database.bat` |
| Log | `logs/ice-update-database.log` |
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
  src_ice["src_ice"]:::source
  platform_ICE["platform_ICE<br/>ICE tabele na platformi (GASO…"]:::store
  subgraph task_ice_update_database["task: ice-update-database"]
    ice_import["ice_import"]:::step
  end
  style task_ice_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_ice --> ice_import
  ice_import --> platform_ICE
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

