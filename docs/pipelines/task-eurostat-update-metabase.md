# Task eurostat-update-metabase

| | |
|---|---|
| Task Scheduler | `\eurostat-update-metabase` |
| Kdaj | dnevno 11:03 in 23:03 |
| .bat | `batch-scripts/eurostat-update-metabase.bat` |
| Log | `logs/eurostat_metabase.Rout` |
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
  eurostat_metabase["eurostat_metabase<br/><small>shema eurostat (metabaza, SCD2)</small>"]:::store
  metabase["metabase<br/><small>task eurostat-update-metabase</small>"]:::step
  src_eurostat --> metabase
  metabase --> eurostat_metabase
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

