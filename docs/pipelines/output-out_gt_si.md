# GT tabela SI (SLO in ENG)

`out_gt_si` · workbook · data$/GT/GT_tabele_ZA WORD_ne spreminjaj/GT_tabela_SI_slo.xlsx, GT_tabela_SI_angl.xlsx

Uporabniki: UB, TNS, BBF

## Od kod pride

```mermaid
flowchart LR
  src_surs["src_surs"]:::source
  src_bs["src_bs"]:::source
  src_eurostat["src_eurostat"]:::source
  src_ecb["src_ecb"]:::source
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
  subgraph task_bs_update_database_daily["task: bs-update-database-daily"]
    bs_import["bs_import"]:::step
  end
  style task_bs_update_database_daily fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  subgraph task_surs_update_database["task: surs-update-database"]
    surs_import["surs_import"]:::step
  end
  style task_surs_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  subgraph task_gt_tabela_si_update["task: gt-tabela-si-update"]
    gt_tabela_si["gt_tabela_si"]:::step
  end
  style task_gt_tabela_si_update fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  subgraph task_ecb_update_database["task: ecb-update-database"]
    ecb_import["ecb_import"]:::step
  end
  style task_ecb_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  subgraph task_eurostat_update_database["task: eurostat-update-database"]
    eurostat_import["eurostat_import"]:::step
  end
  style task_eurostat_update_database fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780
  src_bs --> bs_import
  bs_import --> platform_BS
  src_surs --> surs_import
  surs_import --> platform_SURS
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
  src_ecb --> ecb_import
  ecb_import --> platform_ECB
  src_eurostat --> eurostat_import
  eurostat_import --> platform_EUROSTAT
  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px
  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px
  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px
  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px
```

## Viri

| Vir | Kdo | Kje | Kdaj pride |
|---|---|---|---|
| desezonirani delovno aktivni, registrirani brezposelni, ILO | DR | DESEZONIRANJE/Trg dela/<serija>/Leto YYYY/MM/ | Denis desezonira podatke in jih odloži v mapo tekočega meseca |
| desezonirani realni izvoz in uvoz blaga | DR | DESEZONIRANJE/Zunanja trgovina/<serija>/Leto YYYY/MM/ | Denis desezonira podatke in jih odloži v mapo tekočega meseca |
| plače za GT tabelo | DR | Users/DRogan/GT/GT-place (REK).xlsx, list "tgg - tabela" | Denis posodobi datoteko |
| donosnosti 10-letnih obveznic | MP | data/donosnosti/Donosnosti_10Ya.xlsx, list Mesecno | Marjan ročno dopiše mesec |
| SURS koledar objav | — | stat.si ReleaseCalendarCsv | samodejno |
| datumi objav ZRSZ | — | R/gt-tabela-si-update.R, vektor zrsz_days (v kodi!) | ročno, enkrat letno s https://www.ess.gov.si/partnerji/trg-dela/koledar-objav/ |
| BS PX tabele | — | px.bsi.si | samodejno; BS objavlja nepravilno, zato tečemo dnevno |
| SiStat PX tabele | — | pxweb.stat.si | samodejno, po koledarju objav SURS |
| ECB Data Portal | — | data.ecb.europa.eu | samodejno |
| Eurostat API | — | ec.europa.eu/eurostat | samodejno |

## Taski

| Task | Kdaj | .bat | Log |
|---|---|---|---|
| [bs-update-database-daily](task-bs-update-database-daily.md) | dnevno 11:00 | `batch-scripts/bs-update-database-daily.bat` | `logs/bs-update-database-daily.Rout` |
| [surs-update-database](task-surs-update-database.md) | dnevno 10:32 | `batch-scripts/surs-update-database.bat` | `logs/surs-update-database.Rout` |
| [gt-tabela-si-update](task-gt-tabela-si-update.md) | petek 13:00 | `batch-scripts/gt-tabela-si-update.bat` | `logs/gt-tabela-si-update.Rout` |
| [ecb-update-database](task-ecb-update-database.md) | dnevno 10:00 | `batch-scripts/ecb-update-database.bat` | `logs/ecb-update-database.Rout` |
| [eurostat-update-database](task-eurostat-update-database.md) | dnevno 11:00 in 23:00 | `batch-scripts/eurostat-update-database.bat` | `logs/eurostat-update-database.Rout` |
