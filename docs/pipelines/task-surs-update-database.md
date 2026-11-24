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
  src_surs["src_surs<br/><small></small>"]:::source
  platform_SURS["platform_SURS<br/><small>SURS tabele na platformi</small>"]:::store
  out_indicator_report["out_indicator_report<br/><small>poročilo o indikatorjih</small>"]:::output
  surs_import["surs_import<br/><small>task surs-update-database</small>"]:::step
  indicator_report["indicator_report<br/><small>task surs-update-database</small>"]:::step
  src_surs --> surs_import
  surs_import --> platform_SURS
  platform_SURS --> indicator_report
  indicator_report --> out_indicator_report
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

## Napaja

- [out_indicator_report](output-out_indicator_report.md)
- [out_eo_tabele](output-out_eo_tabele.md)
- [out_gt_si](output-out_gt_si.md)
