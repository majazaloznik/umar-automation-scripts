# četrtletni koeficienti rasti trošarin

`out_trosarine_preracuni` · workbook · Users/LFajic/trošarine/trošarine_preračuni.xlsx

Uporabniki: LF

## Od kod pride

```mermaid
flowchart LR
  src_mf_trosarine["src_mf_trosarine<br/>LF"]:::source
  platform_UMAR_LF["platform_UMAR_LF<br/>tabele LF0xx na platformi"]:::store
  umardata_LF["umardata_LF<br/>umar-data/LF/umar_serije_poda…"]:::store
  out_trosarine_preracuni["out_trosarine_preracuni<br/>četrtletni koeficienti rasti …"]:::output
  subgraph task_umar_add_data["task: umar-add_data"]
    feed_trosarine_LF["feed_trosarine_LF"]:::step
    ingest_LF["ingest_LF"]:::step
    trosarine_preracuni["trosarine_preracuni"]:::step
  end
  style task_umar_add_data fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_mf_trosarine --> feed_trosarine_LF
  feed_trosarine_LF --> umardata_LF
  umardata_LF --> ingest_LF
  ingest_LF --> platform_UMAR_LF
  platform_UMAR_LF --> trosarine_preracuni
  trosarine_preracuni --> out_trosarine_preracuni
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Viri

| Vir | Kdo | Kje | Kdaj pride |
|---|---|---|---|
| mesečni podatki o trošarinah | LF | data/trosarine/ (ročno odloženo) | MF pošlje datoteko, ki jo je treba ročno odložiti v mapo |

## Taski

| Task | Kdaj | .bat | Log |
|---|---|---|---|
| [umar-add_data](task-umar-add_data.md) | dnevno 10:20, petek še 12:00, 13:00, 14:00 | `batch-scripts/umar-add_new_data.bat` | `logs/umar-data_update.log` |
