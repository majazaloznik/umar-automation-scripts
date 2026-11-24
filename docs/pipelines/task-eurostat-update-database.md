# Task eurostat-update-database

| | |
|---|---|
| Task Scheduler | `\eurostat-update-database` |
| Kdaj | dnevno 11:00 in 23:00 |
| .bat | `batch-scripts/eurostat-update-database.bat` |
| Log | `logs/eurostat-update-database.Rout` |
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
  src_eurostat["src_eurostat<br/><small></small>"]:::source
  platform_EUROSTAT["platform_EUROSTAT<br/><small>Eurostat tabele na platformi</small>"]:::store
  eurostat_import["eurostat_import<br/><small>task eurostat-update-database</small>"]:::step
  src_eurostat --> eurostat_import
  eurostat_import --> platform_EUROSTAT
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

## Napaja

- [out_gt_si](output-out_gt_si.md)
