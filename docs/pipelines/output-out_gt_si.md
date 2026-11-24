# GT tabela SI (SLO in ENG)

`out_gt_si` · workbook · data$/GT/GT_tabele_ZA WORD_ne spreminjaj/GT_tabela_SI_slo.xlsx, GT_tabela_SI_angl.xlsx

Uporabniki: UB, TNS, BBF

## Od kod pride

```mermaid
flowchart LR
  src_surs["src_surs<br/><small></small>"]:::source
  src_bs["src_bs<br/><small></small>"]:::source
  src_eurostat["src_eurostat<br/><small></small>"]:::source
  src_ecb["src_ecb<br/><small></small>"]:::source
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
  bs_import["bs_import<br/><small>task bs-update-database-daily</small>"]:::step
  surs_import["surs_import<br/><small>task surs-update-database</small>"]:::step
  gt_tabela_si["gt_tabela_si<br/><small>task gt-tabela-si-update</small>"]:::step
  ecb_import["ecb_import<br/><small>task ecb-update-database</small>"]:::step
  eurostat_import["eurostat_import<br/><small>task eurostat-update-database</small>"]:::step
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
  classDef source fill:#FAECE7,stroke:#993C1D
  classDef step fill:#F1EFE8,stroke:#5F5E5A
  classDef store fill:#E1F5EE,stroke:#0F6E56
  classDef output fill:#EEEDFE,stroke:#534AB7
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
