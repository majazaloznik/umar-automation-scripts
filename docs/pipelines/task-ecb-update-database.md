# Task ecb-update-database

| | |
|---|---|
| Task Scheduler | `\ecb-update-database` |
| Kdaj | dnevno 10:00 |
| .bat | `batch-scripts/ecb-update-database.bat` |
| Log | `logs/ecb-update-database.Rout` |
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
  src_ecb["src_ecb"]:::source
  platform_ECB["platform_ECB<br/>ECB tabele na platformi"]:::store
  subgraph task_ecb_update_database["task: ecb-update-database"]
    ecb_import["ecb_import"]:::step
  end
  style task_ecb_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_ecb --> ecb_import
  ecb_import --> platform_ECB
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Napaja

- [out_gt_si](output-out_gt_si.md)
