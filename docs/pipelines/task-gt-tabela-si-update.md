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
  src_desez_trg_dela["src_desez_trg_dela<br/>DR"]:::source
  src_desez_zunanja["src_desez_zunanja<br/>DR"]:::source
  src_denis_gt_place["src_denis_gt_place<br/>DR"]:::source
  src_donosnosti["src_donosnosti<br/>MP"]:::source
  src_surs_koledar["src_surs_koledar"]:::source
  src_zrsz_days["src_zrsz_days"]:::source
  platform_SURS["platform_SURS<br/>SURS tabele na platformi"]:::store
  platform_BS["platform_BS<br/>BS tabele na platformi"]:::store
  platform_EUROSTAT["platform_EUROSTAT<br/>Eurostat tabele na platformi"]:::store
  platform_ECB["platform_ECB<br/>ECB tabele na platformi"]:::store
  out_gt_si["out_gt_si<br/>GT tabela SI (SLO in ENG)"]:::output
  subgraph task_gt_tabela_si_update["task: gt-tabela-si-update"]
    gt_tabela_si["gt_tabela_si"]:::step
  end
  style task_gt_tabela_si_update fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
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
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Napaja

- [out_gt_si](output-out_gt_si.md)
