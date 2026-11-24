# Task eo_tabele_update

| | |
|---|---|
| Task Scheduler | `\eo_tabele_update` |
| Kdaj | petek 11:00 |
| .bat | `batch-scripts/eo_tabele_update.bat` |
| Log | `logs/eo_tabele_update.Rout` |
| Email (ime runa) | — |
| R | 4.1.3 |
| Teče po | surs-update-database, umar-add_data |
| Pred | — |
| Ponovni zagon | varen |

Teče vse skripte v R/tabele/ po abecedi; eo_00_setup.R je skupna.

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  platform_SURS["platform_SURS<br/>SURS tabele na platformi"]:::store
  platform_UMAR_DR["platform_UMAR_DR<br/>tabele DR0xx na platformi"]:::store
  out_eo_tabele["out_eo_tabele<br/>EO tabele (ID, EX; SLO in ENG)"]:::output
  subgraph task_eo_tabele_update["task: eo_tabele_update"]
    eo_02_ind["eo_02_ind"]:::step
    eo_03_trg_dela["eo_03_trg_dela"]:::step
    eo_04_place["eo_04_place"]:::step
    eo_05_cene["eo_05_cene"]:::step
    eo_06_pb["eo_06_pb"]:::step
    eo_07_fin_trgi["eo_07_fin_trgi"]:::step
    eo_08_jf["eo_08_jf"]:::step
  end
  style task_eo_tabele_update fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  platform_SURS --> eo_04_place
  platform_UMAR_DR --> eo_04_place
  eo_04_place --> out_eo_tabele
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Napaja

- [out_eo_tabele](output-out_eo_tabele.md)
