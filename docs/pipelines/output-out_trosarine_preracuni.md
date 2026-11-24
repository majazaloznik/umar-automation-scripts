# četrtletni koeficienti rasti trošarin

`out_trosarine_preracuni` · workbook · Users/LFajic/trošarine/trošarine_preračuni.xlsx

Uporabniki: LF

## Od kod pride

```mermaid
flowchart LR
  src_mf_trosarine["src_mf_trosarine<br/><small>LF</small>"]:::source
  platform_UMAR_LF["platform_UMAR_LF<br/><small>tabele LF0xx na platformi</small>"]:::store
  umardata_LF["umardata_LF<br/><small>umar-data/LF/umar_serije_podatki_LF.xlsx</small>"]:::store
  out_trosarine_preracuni["out_trosarine_preracuni<br/><small>četrtletni koeficienti rasti trošarin</small>"]:::output
  feed_trosarine_LF["feed_trosarine_LF<br/><small>task umar-add_data</small>"]:::step
  ingest_LF["ingest_LF<br/><small>task umar-add_data</small>"]:::step
  trosarine_preracuni["trosarine_preracuni<br/><small>task umar-add_data</small>"]:::step
  src_mf_trosarine --> feed_trosarine_LF
  feed_trosarine_LF --> umardata_LF
  umardata_LF --> ingest_LF
  ingest_LF --> platform_UMAR_LF
  platform_UMAR_LF --> trosarine_preracuni
  trosarine_preracuni --> out_trosarine_preracuni
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

## Viri

| Vir | Kdo | Kje | Kdaj pride |
|---|---|---|---|
| mesečni podatki o trošarinah | LF | data/trosarine/ (ročno odloženo) | MF pošlje datoteko, ki jo je treba ročno odložiti v mapo |

## Taski

| Task | Kdaj | .bat | Log |
|---|---|---|---|
| [umar-add_data](task-umar-add_data.md) | dnevno 10:20, petek še 12:00, 13:00, 14:00 | `batch-scripts/umar-add_new_data.bat` | `logs/umar-data_update.log` |
