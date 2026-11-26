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
  src_wb_cmo["src_wb_cmo"]:::source
  src_elektrika["src_elektrika<br/>AK"]:::source
  src_fin_distress["src_fin_distress<br/>HM"]:::source
  src_denis_place["src_denis_place<br/>DR"]:::source
  src_smtk["src_smtk<br/>AK"]:::source
  src_mf_trosarine["src_mf_trosarine<br/>LF"]:::source
  platform_UMAR_AK["platform_UMAR_AK<br/>tabele AK0xx na platformi"]:::store
  platform_UMAR_DR["platform_UMAR_DR<br/>tabele DR0xx na platformi"]:::store
  platform_UMAR_HM["platform_UMAR_HM<br/>tabele HM0xx na platformi"]:::store
  platform_UMAR_JK["platform_UMAR_JK<br/>tabele JK001, JK002 na platfo…"]:::store
  platform_UMAR_LF["platform_UMAR_LF<br/>tabele LF0xx na platformi"]:::store
  platform_UMAR_UB["platform_UMAR_UB<br/>tabele UB0xx na platformi"]:::store
  platform_UMAR_other["platform_UMAR_other<br/>ostale UMAR tabele na platfor…"]:::store
  umardata_AK["umardata_AK<br/>umar-data/AK/umar_serije_poda…"]:::store
  umardata_DR["umardata_DR<br/>umar-data/DR/umar_serije_poda…"]:::store
  umardata_HM["umardata_HM<br/>umar-data/HM/umar_serije_poda…"]:::store
  umardata_JK["umardata_JK<br/>umar-data/JK/umar_serije_poda…"]:::store
  umardata_LF["umardata_LF<br/>umar-data/LF/umar_serije_poda…"]:::store
  umardata_UB["umardata_UB<br/>umar-data/UB/umar_serije_poda…"]:::store
  umardata_other["umardata_other<br/>ostale mape v umar-data (AJPE…"]:::store
  out_trosarine_preracuni["out_trosarine_preracuni<br/>četrtletni koeficienti rasti …"]:::output
  subgraph task_umar_add_data["task: umar-add_data"]
    feed_commodity_prices_UB["feed_commodity_prices_UB"]:::step
    feed_elektrika_AK["feed_elektrika_AK"]:::step
    feed_fin_vzdrznost_HM["feed_fin_vzdrznost_HM"]:::step
    feed_place_DR["feed_place_DR"]:::step
    feed_smtk_JK["feed_smtk_JK"]:::step
    feed_trosarine_LF["feed_trosarine_LF"]:::step
    ingest_AK["ingest_AK"]:::step
    ingest_DR["ingest_DR"]:::step
    ingest_HM["ingest_HM"]:::step
    ingest_JK["ingest_JK"]:::step
    ingest_LF["ingest_LF"]:::step
    ingest_UB["ingest_UB"]:::step
    ingest_other["ingest_other"]:::step
    trosarine_preracuni["trosarine_preracuni"]:::step
  end
  style task_umar_add_data fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_wb_cmo --> feed_commodity_prices_UB
  feed_commodity_prices_UB --> umardata_UB
  src_elektrika --> feed_elektrika_AK
  feed_elektrika_AK --> umardata_AK
  src_fin_distress --> feed_fin_vzdrznost_HM
  feed_fin_vzdrznost_HM --> umardata_HM
  src_denis_place --> feed_place_DR
  feed_place_DR --> umardata_DR
  src_smtk --> feed_smtk_JK
  feed_smtk_JK --> umardata_JK
  src_mf_trosarine --> feed_trosarine_LF
  feed_trosarine_LF --> umardata_LF
  umardata_AK --> ingest_AK
  ingest_AK --> platform_UMAR_AK
  umardata_DR --> ingest_DR
  ingest_DR --> platform_UMAR_DR
  umardata_HM --> ingest_HM
  ingest_HM --> platform_UMAR_HM
  umardata_JK --> ingest_JK
  ingest_JK --> platform_UMAR_JK
  umardata_LF --> ingest_LF
  ingest_LF --> platform_UMAR_LF
  umardata_UB --> ingest_UB
  ingest_UB --> platform_UMAR_UB
  umardata_other --> ingest_other
  ingest_other --> platform_UMAR_other
  platform_UMAR_LF --> trosarine_preracuni
  trosarine_preracuni --> out_trosarine_preracuni
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Napaja

- [out_eo_tabele](output-out_eo_tabele.md)
- [out_trosarine_preracuni](output-out_trosarine_preracuni.md)
