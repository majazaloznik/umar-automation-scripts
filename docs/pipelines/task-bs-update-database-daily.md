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
  src_bs["src_bs<br/><small></small>"]:::source
  platform_BS["platform_BS<br/><small>BS tabele na platformi</small>"]:::store
  bs_import["bs_import<br/><small>task bs-update-database-daily</small>"]:::step
  src_bs --> bs_import
  bs_import --> platform_BS
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

## Napaja

- [out_gt_si](output-out_gt_si.md)
