# poročilo o indikatorjih

`out_indicator_report` · report · TODO

Uporabniki: TODO

## Od kod pride

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

## Viri

| Vir | Kdo | Kje | Kdaj pride |
|---|---|---|---|
| SiStat PX tabele | — | pxweb.stat.si | samodejno, po koledarju objav SURS |

## Taski

| Task | Kdaj | .bat | Log |
|---|---|---|---|
| [surs-update-database](task-surs-update-database.md) | dnevno 10:32 | `batch-scripts/surs-update-database.bat` | `logs/surs-update-database.Rout` |
