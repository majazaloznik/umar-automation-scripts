# Task umar-update_indicator_report

| | |
|---|---|
| Task Scheduler | `\umar-update_indicator_report` |
| Kdaj | ročno |
| .bat | `batch-scripts/update_report.bat` |
| Log | `logs/update_indicator_report.Rout` |
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
  indicator_report_manual["indicator_report_manual<br/><small>task umar-update_indicator_report</small>"]:::step
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

