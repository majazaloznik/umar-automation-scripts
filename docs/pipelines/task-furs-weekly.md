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
  src_furs_racuni["src_furs_racuni<br/><small></small>"]:::source
  src_udb_metadata["src_udb_metadata<br/><small>UDB</small>"]:::source
  platform_DAVCNE["platform_DAVCNE<br/><small>davčne serije (UDB) na platformi</small>"]:::store
  davcne_db["davcne_db<br/><small>baza davcne, tabela davcni_racuni</small>"]:::store
  furs_weekly_update["furs_weekly_update<br/><small>task furs-weekly</small>"]:::step
  davcne_update_platform["davcne_update_platform<br/><small>task furs-weekly</small>"]:::step
  src_furs_racuni --> furs_weekly_update
  furs_weekly_update --> davcne_db
  davcne_db --> davcne_update_platform
  src_udb_metadata --> davcne_update_platform
  davcne_update_platform --> platform_DAVCNE
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

