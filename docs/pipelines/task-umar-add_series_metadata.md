# Task umar-add_series_metadata

| | |
|---|---|
| Task Scheduler | `\umar-add_series_metadata` |
| Kdaj | ročno (inicialke avtorja v Actions / Add arguments) |
| .bat | `batch-scripts/umar-add_new_series_metadata.bat` |
| Log | `logs/umar-add_new_series_metadata.Rout` |
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
  
  subgraph task_umar_add_series_metadata["task: umar-add_series_metadata"]
    add_metadata["add_metadata"]:::step
  end
  style task_umar_add_series_metadata fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

