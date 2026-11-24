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
  src_ice["src_ice<br/><small></small>"]:::source
  platform_ICE["platform_ICE<br/><small>ICE tabele na platformi (GASOIL_RAW, GASOIL_P</small>"]:::store
  ice_import["ice_import<br/><small>task ice-update-database</small>"]:::step
  src_ice --> ice_import
  ice_import --> platform_ICE
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

