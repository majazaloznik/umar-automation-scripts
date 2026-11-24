# Task umar-add_data

| | |
|---|---|
| Task Scheduler | `\umar-add_data` |
| Kdaj | dnevno 10:20, petek še 12:00, 13:00, 14:00 |
| .bat | `batch-scripts/umar-add_new_data.bat` |
| Log | `logs/umar-data_update.log` |
| Email (ime runa) | umar_data_update |
| R | 4.5.2 |
| Teče po | — |
| Pred | eo_tabele_update |
| Ponovni zagon | varen |

Feederji in uvoz posameznih map so neodvisni: napaka v enem pošlje ISSUES, ostali tečejo naprej. Logi uvoza po avtorjih: logs/UMARfetchR/.


## Ponovni zagon

V Task Schedulerju desni klik na task › Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.

## Koraki

```mermaid
flowchart LR
  src_wb_cmo["src_wb_cmo<br/><small></small>"]:::source
  src_elektrika["src_elektrika<br/><small>AK</small>"]:::source
  src_fin_distress["src_fin_distress<br/><small>HM</small>"]:::source
  src_denis_place["src_denis_place<br/><small>DR</small>"]:::source
  src_mf_trosarine["src_mf_trosarine<br/><small>LF</small>"]:::source
  platform_UMAR_AK["platform_UMAR_AK<br/><small>tabele AK0xx na platformi</small>"]:::store
  platform_UMAR_DR["platform_UMAR_DR<br/><small>tabele DR0xx na platformi</small>"]:::store
  platform_UMAR_HM["platform_UMAR_HM<br/><small>tabele HM0xx na platformi</small>"]:::store
  platform_UMAR_LF["platform_UMAR_LF<br/><small>tabele LF0xx na platformi</small>"]:::store
  platform_UMAR_UB["platform_UMAR_UB<br/><small>tabele UB0xx na platformi</small>"]:::store
  platform_UMAR_other["platform_UMAR_other<br/><small>ostale UMAR tabele na platformi (AJPES, CE, J</small>"]:::store
  umardata_AK["umardata_AK<br/><small>umar-data/AK/umar_serije_podatki_AK.xlsx</small>"]:::store
  umardata_DR["umardata_DR<br/><small>umar-data/DR/umar_serije_podatki_DR.xlsx</small>"]:::store
  umardata_HM["umardata_HM<br/><small>umar-data/HM/umar_serije_podatki_HM.xlsx</small>"]:::store
  umardata_LF["umardata_LF<br/><small>umar-data/LF/umar_serije_podatki_LF.xlsx</small>"]:::store
  umardata_UB["umardata_UB<br/><small>umar-data/UB/umar_serije_podatki_UB.xlsx</small>"]:::store
  umardata_other["umardata_other<br/><small>ostale mape v umar-data (AJPES, CE, JK, MH, M</small>"]:::store
  out_trosarine_preracuni["out_trosarine_preracuni<br/><small>četrtletni koeficienti rasti trošarin</small>"]:::output
  feed_commodity_prices_UB["feed_commodity_prices_UB<br/><small>task umar-add_data</small>"]:::step
  feed_elektrika_AK["feed_elektrika_AK<br/><small>task umar-add_data</small>"]:::step
  feed_fin_vzdrznost_HM["feed_fin_vzdrznost_HM<br/><small>task umar-add_data</small>"]:::step
  feed_place_DR["feed_place_DR<br/><small>task umar-add_data</small>"]:::step
  feed_trosarine_LF["feed_trosarine_LF<br/><small>task umar-add_data</small>"]:::step
  ingest_AK["ingest_AK<br/><small>task umar-add_data</small>"]:::step
  ingest_DR["ingest_DR<br/><small>task umar-add_data</small>"]:::step
  ingest_HM["ingest_HM<br/><small>task umar-add_data</small>"]:::step
  ingest_LF["ingest_LF<br/><small>task umar-add_data</small>"]:::step
  ingest_UB["ingest_UB<br/><small>task umar-add_data</small>"]:::step
  ingest_other["ingest_other<br/><small>task umar-add_data</small>"]:::step
  trosarine_preracuni["trosarine_preracuni<br/><small>task umar-add_data</small>"]:::step
  src_wb_cmo --> feed_commodity_prices_UB
  feed_commodity_prices_UB --> umardata_UB
  src_elektrika --> feed_elektrika_AK
  feed_elektrika_AK --> umardata_AK
  src_fin_distress --> feed_fin_vzdrznost_HM
  feed_fin_vzdrznost_HM --> umardata_HM
  src_denis_place --> feed_place_DR
  feed_place_DR --> umardata_DR
  src_mf_trosarine --> feed_trosarine_LF
  feed_trosarine_LF --> umardata_LF
  umardata_AK --> ingest_AK
  ingest_AK --> platform_UMAR_AK
  umardata_DR --> ingest_DR
  ingest_DR --> platform_UMAR_DR
  umardata_HM --> ingest_HM
  ingest_HM --> platform_UMAR_HM
  umardata_LF --> ingest_LF
  ingest_LF --> platform_UMAR_LF
  umardata_UB --> ingest_UB
  ingest_UB --> platform_UMAR_UB
  umardata_other --> ingest_other
  ingest_other --> platform_UMAR_other
  platform_UMAR_LF --> trosarine_preracuni
  trosarine_preracuni --> out_trosarine_preracuni
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
```

## Napaja

- [out_eo_tabele](output-out_eo_tabele.md)
- [out_trosarine_preracuni](output-out_trosarine_preracuni.md)
