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
  platform_SURS["platform_SURS<br/><small>SURS tabele na platformi</small>"]:::store
  platform_UMAR_DR["platform_UMAR_DR<br/><small>tabele DR0xx na platformi</small>"]:::store
  out_eo_tabele["out_eo_tabele<br/><small>EO tabele (ID, EX; SLO in ENG)</small>"]:::output
  eo_02_ind["eo_02_ind<br/><small>task eo_tabele_update</small>"]:::step
  eo_03_trg_dela["eo_03_trg_dela<br/><small>task eo_tabele_update</small>"]:::step
  eo_04_place["eo_04_place<br/><small>task eo_tabele_update</small>"]:::step
  eo_05_cene["eo_05_cene<br/><small>task eo_tabele_update</small>"]:::step
  eo_06_pb["eo_06_pb<br/><small>task eo_tabele_update</small>"]:::step
  eo_07_fin_trgi["eo_07_fin_trgi<br/><small>task eo_tabele_update</small>"]:::step
  eo_08_jf["eo_08_jf<br/><small>task eo_tabele_update</small>"]:::step
  platform_SURS --> eo_04_place
  platform_UMAR_DR --> eo_04_place
  eo_04_place --> out_eo_tabele
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

## Napaja

- [out_eo_tabele](output-out_eo_tabele.md)
