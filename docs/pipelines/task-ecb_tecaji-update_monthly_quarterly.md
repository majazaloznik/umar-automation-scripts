# Task ecb_tecaji-update_monthly_quarterly

| | |
|---|---|
| Task Scheduler | `\ecb_tečaji-update_monthly_quarterly` |
| Kdaj | enkratni sprožilci, zadnji 7. 12. 2026 |
| .bat | `batch-scripts/ecb_tečaji-monthly_quarterly_update.bat` |
| Log | `logs/tecaji-update_monthly_quarterly.Rout` |
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
  tecaji_monthly["tecaji_monthly<br/><small>task ecb_tecaji-update_monthly_quarterly</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

