# Task surs-changes-api-update

| | |
|---|---|
| Task Scheduler | `\surs-changes-api-update` |
| Kdaj | dnevno 17:25 |
| .bat | `batch-scripts/surs-changes-api-update.bat` |
| Log | `logs/surs-changes-api-update.Rout` |
| Email (ime runa) | — |
| R | 4.1.3 |
| Teče po | — |
| Pred | — |
| Ponovni zagon | ponovni zagon pošlje maile uporabnikom |

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  surs_changes["surs_changes<br/><small>task surs-changes-api-update</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

