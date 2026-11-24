# Task produktivnost-eurostat_update

| | |
|---|---|
| Task Scheduler | `\produktivnost-eurostat_update` |
| Kdaj | enkratni sprožilci, zadnji 7. 12. 2026 |
| .bat | `batch-scripts/produktivnost-eurostat_update.bat` |
| Log | `logs/produktivnost-eurostat_update.Rout` |
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
  produktivnost_eurostat["produktivnost_eurostat<br/><small>task produktivnost-eurostat_update</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

