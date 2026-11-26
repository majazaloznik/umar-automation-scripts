# UMAR pipelines

Generirano iz `registry/pipelines.yml` z `R/registry/render_registry.R`. Ne urejaj ročno.

## Izhodi

| Izhod | Tip | Uporabniki |
|---|---|---|
| [EO tabele (ID, EX; SLO in ENG)](output-out_eo_tabele.md) | workbook | TODO |
| [GT tabela SI (SLO in ENG)](output-out_gt_si.md) | workbook | UB, TNS, BBF |
| [četrtletni koeficienti rasti trošarin](output-out_trosarine_preracuni.md) | workbook | LF |
| [poročilo o indikatorjih](output-out_indicator_report.md) | report | TODO |

## Taski

| Task | Kdaj | Log |
|---|---|---|
| [bs-update-database-daily](task-bs-update-database-daily.md) | dnevno 11:00 | `logs/bs-update-database-daily.Rout` |
| [furs-weekly](task-furs-weekly.md) | sreda 08:15 | `logs/furs_weekly_update.txt, logs/davcne_update_platform.txt` |
| [umar-add_data](task-umar-add_data.md) | dnevno 10:20, petek še 12:00, 13:00, 14:00 | `logs/umar-data_update.log` |
| [surs-update-database](task-surs-update-database.md) | dnevno 10:32 | `logs/surs-update-database.Rout` |
| [eo_tabele_update](task-eo_tabele_update.md) | petek 11:00 | `logs/eo_tabele_update.Rout` |
| [gt-tabela-si-update](task-gt-tabela-si-update.md) | petek 13:00 | `logs/gt-tabela-si-update.Rout` |
| [desez-update-database-daily](task-desez-update-database-daily.md) | dnevno 14:00 | `logs/desez_update.Rout` |
| [donosnosti-update-database](task-donosnosti-update-database.md) | dnevno 12:00 | `logs/donosnosti-update-database.log` |
| [ecb-update-database](task-ecb-update-database.md) | dnevno 10:00 | `logs/ecb-update-database.Rout` |
| [ecb_tecaji-update_daily](task-ecb_tecaji-update_daily.md) | dnevno 16:00 | `logs/tecaji-update_daily.Rout` |
| [ecb_tecaji-update_monthly_quarterly](task-ecb_tecaji-update_monthly_quarterly.md) | enkratni sprožilci, ob 10:00 po ECB koledarju za Harmonized Competitiveness Indicators EXR, vneseni enkrat na leto za 12 mesecev naprej. | `logs/tecaji-update_monthly_quarterly.Rout` |
| [eurostat-update-database](task-eurostat-update-database.md) | dnevno 11:00 in 23:00 | `logs/eurostat-update-database.Rout` |
| [eurostat-update-metabase](task-eurostat-update-metabase.md) | dnevno 11:03 in 23:03 | `logs/eurostat_metabase.Rout` |
| [gt-tabela-ea-update](task-gt-tabela-ea-update.md) | petek 13:00 | `logs/gt-tabela-ea-update.Rout` |
| [gt_grafi_update](task-gt_grafi_update.md) | dnevno 11:03, petek še 12:03, 13:03, 14:03 | `logs/gt_grafi_update.Rout` |
| [ice-update-database](task-ice-update-database.md) | dnevno 07:00 | `logs/ice-update-database.log` |
| [mf_update_database](task-mf_update_database.md) | mesečno, prvi in zadnji delovni dan 10:15 | `logs/mf_update.Rout` |
| [produktivnost-eurostat_update](task-produktivnost-eurostat_update.md) | enkratni sprožilci, zadnji 7. 12. 2026, Get dates from Eurostat release calendar for GDP main aggregates and employment and flash estimates | `logs/produktivnost-eurostat_update.Rout` |
| [produktivnost-surs_update](task-produktivnost-surs_update.md) | dnevno 10:30 | `logs/produktivnost-surs_update.Rout` |
| [surs-changes-api-update](task-surs-changes-api-update.md) | dnevno 17:25 | `logs/surs-changes-api-update.Rout` |
| [zrsz-update-database](task-zrsz-update-database.md) | mesečno 4. in 5. ob 09:00 | `logs/zrsz-update-database.Rout` |
| [tgg-si-update](task-tgg-si-update.md) | onemogočen (bil petek 10:45) | `logs/tgg-tabela-update.Rout` |
| [umar-add_series_metadata](task-umar-add_series_metadata.md) | ročno (inicialke avtorja v Actions / Add arguments) | `logs/umar-add_new_series_metadata.Rout` |
| [umar-update_indicator_report](task-umar-update_indicator_report.md) | ročno | `logs/update_indicator_report.Rout` |
| [spicka-posodobitev_tabele_zaposlenih](task-spicka-posodobitev_tabele_zaposlenih.md) | ročno | `D:/umar_dd/logs/batch.Rout` |

## Viri

| Vir | Kdo | Kdaj pride | Vpliva na |
|---|---|---|---|
| SiStat PX tabele | — | samodejno, po koledarju objav SURS | [out_indicator_report](output-out_indicator_report.md), [out_eo_tabele](output-out_eo_tabele.md), [out_gt_si](output-out_gt_si.md) |
| BS PX tabele | — | samodejno; BS objavlja nepravilno, zato tečemo dnevno | [out_gt_si](output-out_gt_si.md) |
| Eurostat API | — | samodejno | [out_gt_si](output-out_gt_si.md) |
| ECB Data Portal | — | samodejno | [out_gt_si](output-out_gt_si.md) |
| ICE gasoil futures | — | samodejno, delovni dnevi | — |
| tedenski izvoz davčnih računov FURS | — | FURS tedensko odloži zip; če je najnovejši starejši od 10 dni, runner javi ISSUES | — |
| metapodatki davčnih serij | UDB | ročno, ob novih serijah | — |
| World Bank commodity prices (CMO) | — | samodejno, mesečno v začetku meseca | — |
| poraba elektrike po odjemnih skupinah | AK | Andrej odloži novo datoteko v mapo | — |
| finančna vzdržnost gospodinjstev | HM | ročno odložena datoteka | — |
| masa plač in prejemniki plač po SKD | DR | Denis posodobi datoteko po objavi SURS (~45 dni po koncu meseca) | [out_eo_tabele](output-out_eo_tabele.md) |
| rezultati kratkoročnega dinamičnega faktorskega modela (nowcast BDP) | AK | Andrej odloži novo datoteko ob vsaki oceni modela; ob reestimaciji se spremenijo tudi pretekle vrednosti | — |
| mesečni podatki o trošarinah | LF | MF pošlje datoteko, ki jo je treba ročno odložiti v mapo | [out_trosarine_preracuni](output-out_trosarine_preracuni.md) |
| desezonirani delovno aktivni, registrirani brezposelni, ILO | DR | Denis desezonira podatke in jih odloži v mapo tekočega meseca | [out_gt_si](output-out_gt_si.md) |
| desezonirani realni izvoz in uvoz blaga | DR | Denis desezonira podatke in jih odloži v mapo tekočega meseca | [out_gt_si](output-out_gt_si.md) |
| plače za GT tabelo | DR | Denis posodobi datoteko | [out_gt_si](output-out_gt_si.md) |
| donosnosti 10-letnih obveznic | MP | Marjan ročno dopiše mesec | [out_gt_si](output-out_gt_si.md) |
| SURS koledar objav | — | samodejno | [out_gt_si](output-out_gt_si.md) |
| datumi objav ZRSZ | — | ročno, enkrat letno s https://www.ess.gov.si/partnerji/trg-dela/koledar-objav/ | [out_gt_si](output-out_gt_si.md) |

## Odprte točke

- warning: eo_tabele_update/eo_02_ind: no reads/writes yet
- warning: eo_tabele_update/eo_03_trg_dela: no reads/writes yet
- warning: eo_tabele_update/eo_05_cene: no reads/writes yet
- warning: eo_tabele_update/eo_06_pb: no reads/writes yet
- warning: eo_tabele_update/eo_07_fin_trgi: no reads/writes yet
- warning: eo_tabele_update/eo_08_jf: no reads/writes yet
- warning: desez-update-database-daily/desez_import: no reads/writes yet
- warning: donosnosti-update-database/donosnosti_import: no reads/writes yet
- warning: ecb_tecaji-update_daily/tecaji_daily: no reads/writes yet
- warning: ecb_tecaji-update_monthly_quarterly/tecaji_monthly: no reads/writes yet
- warning: gt-tabela-ea-update/gt_tabela_ea: no reads/writes yet
- warning: gt_grafi_update/gt_eo_grafi: no reads/writes yet
- warning: mf_update_database/mf_import: no reads/writes yet
- warning: produktivnost-eurostat_update/produktivnost_eurostat: no reads/writes yet
- warning: produktivnost-surs_update/produktivnost_surs: no reads/writes yet
- warning: surs-changes-api-update/surs_changes: no reads/writes yet
- warning: zrsz-update-database/zrsz_import: no reads/writes yet
- warning: tgg-si-update/tgg_tabela_si: no reads/writes yet
- warning: umar-add_series_metadata/add_metadata: no reads/writes yet
- warning: umar-update_indicator_report/indicator_report_manual: no reads/writes yet
- warning: spicka-posodobitev_tabele_zaposlenih/spicka: no reads/writes yet
- warning: bat not in any task: batch-scripts/jk-update_smtk_data.bat
- warning: bat not in any task: batch-scripts/local-surs-changes-api-update.bat
- warning: bat not in any task: batch-scripts/mf_database_update_and_excels.bat
- warning: bat not in any task: batch-scripts/umar_dd_app_start.bat
