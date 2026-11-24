# Task furs-weekly

| | |
|---|---|
| Task Scheduler | `\furs-weekly` |
| Kdaj | sreda 08:15 |
| .bat | `batch-scripts/davcne-weekly-update.bat` |
| Log | `logs/furs_weekly_update.txt, logs/davcne_update_platform.txt` |
| Email (ime runa) | furs_weekly_update, davcne_update_platform |
| R | 4.5.2 |
| Teče po | — |
| Pred | — |
| Ponovni zagon | ponovni zagon pošlje heartbeat uporabnikom (Kušar, Koprivnikar, Kuštrin, Hazler) |

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  src_furs_racuni["src_furs_racuni"]:::source
  src_udb_metadata["src_udb_metadata<br/>UDB"]:::source
  platform_DAVCNE["platform_DAVCNE<br/>davčne serije (UDB) na platfo…"]:::store
  davcne_db["davcne_db<br/>baza davcne, tabela davcni_ra…"]:::store
  subgraph task_furs_weekly["task: furs-weekly"]
    furs_weekly_update["furs_weekly_update"]:::step
    davcne_update_platform["davcne_update_platform"]:::step
  end
  style task_furs_weekly fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_furs_racuni --> furs_weekly_update
  furs_weekly_update --> davcne_db
  davcne_db --> davcne_update_platform
  src_udb_metadata --> davcne_update_platform
  davcne_update_platform --> platform_DAVCNE
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

