# poročilo o indikatorjih

`out_indicator_report` · report · TODO

Uporabniki: TODO

## Od kod pride

```mermaid
flowchart LR
  src_surs["src_surs"]:::source
  platform_SURS["platform_SURS<br/>SURS tabele na platformi"]:::store
  out_indicator_report["out_indicator_report<br/>poročilo o indikatorjih"]:::output
  subgraph task_surs_update_database["task: surs-update-database"]
    surs_import["surs_import"]:::step
    indicator_report["indicator_report"]:::step
  end
  style task_surs_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_surs --> surs_import
  surs_import --> platform_SURS
  platform_SURS --> indicator_report
  indicator_report --> out_indicator_report
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Viri

| Vir | Kdo | Kje | Kdaj pride |
|---|---|---|---|
| SiStat PX tabele | — | pxweb.stat.si | samodejno, po koledarju objav SURS |

## Taski

| Task | Kdaj | .bat | Log |
|---|---|---|---|
| [surs-update-database](task-surs-update-database.md) | dnevno 10:32 | `batch-scripts/surs-update-database.bat` | `logs/surs-update-database.Rout` |
