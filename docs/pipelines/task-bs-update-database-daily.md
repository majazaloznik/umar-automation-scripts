# Task bs-update-database-daily

| | |
|---|---|
| Task Scheduler | `\bs-update-database-daily` |
| Kdaj | dnevno 11:00 |
| .bat | `batch-scripts/bs-update-database-daily.bat` |
| Log | `logs/bs-update-database-daily.Rout` |
| Email (ime runa) | BS-platform |
| R | 4.1.3 |
| Teče po | — |
| Pred | — |
| Ponovni zagon | varen |

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  src_bs["src_bs"]:::source
  platform_BS["platform_BS<br/>BS tabele na platformi"]:::store
  subgraph task_bs_update_database_daily["task: bs-update-database-daily"]
    bs_import["bs_import"]:::step
  end
  style task_bs_update_database_daily fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_bs --> bs_import
  bs_import --> platform_BS
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Napaja

- [out_gt_si](output-out_gt_si.md)
