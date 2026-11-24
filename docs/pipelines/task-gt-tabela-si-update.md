# Task gt-tabela-si-update

| | |
|---|---|
| Task Scheduler | `\gt-tabela-si-update` |
| Kdaj | petek 13:00 |
| .bat | `batch-scripts/gt-tabela-si-update.bat` |
| Log | `logs/gt-tabela-si-update.Rout` |
| Email (ime runa) | — |
| R | 4.5.2 |
| Teče po | — |
| Pred | — |
| Ponovni zagon | ponovni zagon pošlje mail uporabnikom GT tabele in prepiše datum "Zadnja posodobitev" |

## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  src_desez_trg_dela["src_desez_trg_dela<br/><small>DR</small>"]:::source
  src_desez_zunanja["src_desez_zunanja<br/><small>DR</small>"]:::source
  src_denis_gt_place["src_denis_gt_place<br/><small>DR</small>"]:::source
  src_donosnosti["src_donosnosti<br/><small>MP</small>"]:::source
  src_surs_koledar["src_surs_koledar<br/><small></small>"]:::source
  src_zrsz_days["src_zrsz_days<br/><small></small>"]:::source
  platform_SURS["platform_SURS<br/><small>SURS tabele na platformi</small>"]:::store
  platform_BS["platform_BS<br/><small>BS tabele na platformi</small>"]:::store
  platform_EUROSTAT["platform_EUROSTAT<br/><small>Eurostat tabele na platformi</small>"]:::store
  platform_ECB["platform_ECB<br/><small>ECB tabele na platformi</small>"]:::store
  out_gt_si["out_gt_si<br/><small>GT tabela SI (SLO in ENG)</small>"]:::output
  gt_tabela_si["gt_tabela_si<br/><small>task gt-tabela-si-update</small>"]:::step
  platform_SURS --> gt_tabela_si
  platform_BS --> gt_tabela_si
  platform_EUROSTAT --> gt_tabela_si
  platform_ECB --> gt_tabela_si
  src_desez_trg_dela --> gt_tabela_si
  src_desez_zunanja --> gt_tabela_si
  src_denis_gt_place --> gt_tabela_si
  src_donosnosti --> gt_tabela_si
  src_surs_koledar --> gt_tabela_si
  src_zrsz_days --> gt_tabela_si
  gt_tabela_si --> out_gt_si
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

## Napaja

- [out_gt_si](output-out_gt_si.md)
