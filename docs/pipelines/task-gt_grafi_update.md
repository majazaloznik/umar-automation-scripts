# Task gt_grafi_update

| | |
|---|---|
| Task Scheduler | `\gt_grafi_update` |
| Kdaj | dnevno 11:03, petek še 12:03, 13:03, 14:03 |
| .bat | `batch-scripts/gt_eo_grafi_update.bat` |
| Log | `logs/gt_grafi_update.Rout` |
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
  
  subgraph task_gt_grafi_update["task: gt_grafi_update"]
    gt_eo_grafi["gt_eo_grafi"]:::step
  end
  style task_gt_grafi_update fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

