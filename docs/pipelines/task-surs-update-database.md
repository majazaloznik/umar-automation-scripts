# Task surs-update-database

| | |
|---|---|
| Task Scheduler | `\surs-update-database` |
| Kdaj | dnevno 10:32 |
| .bat | `batch-scripts/surs-update-database.bat` |
| Log | `logs/surs-update-database.Rout` |
| Email (ime runa) | — |
| R | 4.1.3 |
| Teče po | — |
| Pred | eo_tabele_update |
| Ponovni zagon | varen |

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  src_surs["src_surs"]:::source
  platform_SURS["platform_SURS<br/>SURS tabele na platformi"]:::store
  out_indicator_report["out_indicator_report<br/>poročilo o indikatorjih"]:::output
  subgraph task_surs_update_database["task: surs-update-database"]
    surs_import["surs_import"]:::step
    indicator_report["indicator_report"]:::step
  end
  style task_surs_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_surs --> surs_import
  surs_import --> platform_SURS
  platform_SURS --> indicator_report
  indicator_report --> out_indicator_report
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Napaja

- [out_indicator_report](output-out_indicator_report.md)
- [out_eo_tabele](output-out_eo_tabele.md)
- [out_gt_si](output-out_gt_si.md)
