# Task jk-update_smtk_data

| | |
|---|---|
| Task Scheduler | `\jk-update_smtk_data` |
| Kdaj | dnevno 10:15 (samo ko je mzaloznik prijavljena!) |
| .bat | `batch-scripts/jk-update_smtk_data.bat` |
| Log | `logs/jk_update_smtk_data.Rout` |
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
  
  subgraph task_jk_update_smtk_data["task: jk-update_smtk_data"]
    jk_smtk["jk_smtk"]:::step
  end
  style task_jk_update_smtk_data fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

