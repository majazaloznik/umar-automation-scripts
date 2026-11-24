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
  src_ecb["src_ecb<br/><small></small>"]:::source
  platform_ECB["platform_ECB<br/><small>ECB tabele na platformi</small>"]:::store
  ecb_import["ecb_import<br/><small>task ecb-update-database</small>"]:::step
  src_ecb --> ecb_import
  ecb_import --> platform_ECB
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

## Napaja

- [out_gt_si](output-out_gt_si.md)
