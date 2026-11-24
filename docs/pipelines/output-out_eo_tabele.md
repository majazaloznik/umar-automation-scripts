# EO tabele (ID, EX; SLO in ENG)

`out_eo_tabele` · workbook · TODO

Uporabniki: TODO

## Od kod pride

```mermaid
flowchart LR
  src_surs["src_surs"]:::source
  src_denis_place["src_denis_place<br/>DR"]:::source
  platform_SURS["platform_SURS<br/>SURS tabele na platformi"]:::store
  platform_UMAR_DR["platform_UMAR_DR<br/>tabele DR0xx na platformi"]:::store
  umardata_DR["umardata_DR<br/>umar-data/DR/umar_serije_poda…"]:::store
  out_eo_tabele["out_eo_tabele<br/>EO tabele (ID, EX; SLO in ENG)"]:::output
  subgraph task_umar_add_data["task: umar-add_data"]
    feed_place_DR["feed_place_DR"]:::step
    ingest_DR["ingest_DR"]:::step
  end
  style task_umar_add_data fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  subgraph task_surs_update_database["task: surs-update-database"]
    surs_import["surs_import"]:::step
  end
  style task_surs_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  subgraph task_eo_tabele_update["task: eo_tabele_update"]
    eo_04_place["eo_04_place"]:::step
  end
  style task_eo_tabele_update fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_denis_place --> feed_place_DR
  feed_place_DR --> umardata_DR
  umardata_DR --> ingest_DR
  ingest_DR --> platform_UMAR_DR
  src_surs --> surs_import
  surs_import --> platform_SURS
  platform_SURS --> eo_04_place
  platform_UMAR_DR --> eo_04_place
  eo_04_place --> out_eo_tabele
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Viri

| Vir | Kdo | Kje | Kdaj pride |
|---|---|---|---|
| SiStat PX tabele | — | pxweb.stat.si | samodejno, po koledarju objav SURS |
| masa plač in prejemniki plač po SKD | DR | Users/DRogan/EO/Plače (nove SKD skupine).xlsx | Denis posodobi datoteko po objavi SURS (~45 dni po koncu meseca) |

## Taski

| Task | Kdaj | .bat | Log |
|---|---|---|---|
| [umar-add_data](task-umar-add_data.md) | dnevno 10:20, petek še 12:00, 13:00, 14:00 | `batch-scripts/umar-add_new_data.bat` | `logs/umar-data_update.log` |
| [surs-update-database](task-surs-update-database.md) | dnevno 10:32 | `batch-scripts/surs-update-database.bat` | `logs/surs-update-database.Rout` |
| [eo_tabele_update](task-eo_tabele_update.md) | petek 11:00 | `batch-scripts/eo_tabele_update.bat` | `logs/eo_tabele_update.Rout` |
