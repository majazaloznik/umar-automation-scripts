# Task ecb_tecaji-update_daily

| | |
|---|---|
| Task Scheduler | `\ecb_tečaji-update_daily` |
| Kdaj | dnevno 16:00 |
| .bat | `batch-scripts/ecb_tečaji-daily_update.bat` |
| Log | `logs/tecaji-update_daily.Rout` |
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
  tecaji_daily["tecaji_daily<br/><small>task ecb_tecaji-update_daily</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

