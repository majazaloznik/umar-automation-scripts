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
  src_eurostat["src_eurostat"]:::source
  platform_EUROSTAT["platform_EUROSTAT<br/>Eurostat tabele na platformi"]:::store
  subgraph task_eurostat_update_database["task: eurostat-update-database"]
    eurostat_import["eurostat_import"]:::step
  end
  style task_eurostat_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_eurostat --> eurostat_import
  eurostat_import --> platform_EUROSTAT
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Napaja

- [out_gt_si](output-out_gt_si.md)
