# Runner conventions

How scheduled pipelines in `umar-automation-scripts` are built, logged and
maintained. Every runner migrated to UmarDataBotR follows this; use it as the
checklist when migrating the next one. For *what* each pipeline connects, see
[the pipeline registry](../registry/README.md).

## 1. Layout and naming

```
R/
  common/admin-common.R        platform_con(), admin_do() and the generic admin functions
<source>/                    one folder per data source or job
<stem>.R                   the scheduled runner
<source>-admin.R           manual admin functions (see §7)
umar-data/
  umar_data_update.R         runner: feeders -> ingest -> post-processing -> derived
feeders/_helpers.R         newest_file(), upsert_umar_data()
feeders/feed_<content>_<FOLDER>.R
derived/<output>.R
archive/                   one-off backfills, never sourced
batch-scripts/<stem>.bat
logs/<stem>.Rout               runner log, overwritten each run, history in git
logs/<SOURCE>-admin.log        admin log, appended
registry/pipelines.yml
```

**One stem per job.** The script, the UmarDataBotR run name (= email subject),
the log and ideally the `.bat` share one name, so an email leads straight to
the script and the log.

## 2. The .bat file

- Runs **R 4.5.2**. Move a runner to 4.5.2 when you migrate it.
- Redirects all output to `logs\<stem>.Rout` (`> ... 2>&1`). This catches crashes
before `run_start()`, such as a failed `library()`. Don't add `log_file` to
  scheduled runners: the redirect plus git history is the archive.
- Commits and pushes the log, then exits with R's exit code, so Task Scheduler's
  "Last Result" is meaningful.
- Task Scheduler: "Run whether user is logged on or not". Never "Interactive only".

`.Rprofile` is loaded by every R version and every script: **base R only**, no
package calls.

## 3. Runner skeleton

```r
setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
source("R/common/admin-common.R")          # platform_con()

run <- UmarDataBotR::run_start(
  "<stem>",
  maintainer = "maja.zaloznik@gmail.com",
  recipients = character(),                # users who want the notice, if any
  heartbeat  = TRUE)                       # FALSE for daily jobs

UmarDataBotR::with_run(run, {
  con <- UmarDataBotR::run_step(run, "connect platform", platform_con())

  res <- purrr::map(items, \(x) UmarDataBotR::run_step(
    run, paste("import", x), import_one(x, con), critical = FALSE))

  UmarDataBotR::run_summary(run, "%d new, %d failed", n_new, n_failed)
  UmarDataBotR::new_data(run, n_new > 0)

  if (n_new > 0) {
    # vintage cleanup per affected table, view refresh
  }
  DBI::dbDisconnect(con)
})
```

- **`critical = TRUE`** (the default) for steps nothing can work without: a connection,
  the list of tables. Everything per item is **`critical = FALSE`**, so one bad table
  becomes an `[ISSUES]` email and the rest still runs.
- **Wrap every step that can fail in `run_step()`**, including reading config files.
  The log then says which step failed.
- **`log_msg()` is `sprintf()`**: every `%s` needs an argument. With one argument the
  string is printed as is.
- **Run names and emails:**
  - `[FAILED]` and `[ISSUES]` go to the maintainer, with the full log.
  - `[OK]` heartbeats go to the maintainer and `recipients`.
  - Daily jobs: `heartbeat = FALSE`. Weekly and monthly: `TRUE`, so silence means
    something is wrong.

## 4. Idempotence: every runner is safe to re-run

- **"Nothing new" is not an error.** It returns 0 and logs "no new data".
- **Partial overlap is an error.** Some periods already loaded and some not means
  something unexpected happened: stop and say which periods.
- **Gate expensive post-processing on new data.** Vintage cleanup only for tables
  that got new vintages; view refresh only if anything was imported.
- **Derived outputs check for themselves.** They compare their inputs' latest period
with the output's and write only when the input is ahead. A run that failed is
  caught up by the next one.
- Where re-running has a side effect (emails users, overwrites a "last updated"
  date), say so in the registry's `rerun_note`.

## 5. Packages vs. scripts

- **Fix behaviour in the package, not with a wrapper.** If a fetch function swallows
errors or returns the wrong thing, change it in its package (BSfetchR, UMARfetchR …).
- **Package import functions:**
  - raise errors, don't return them in a list;
  - signal "nothing new" with a classed condition (e.g. `bs_not_new`) that the
    function itself turns into zero counts;
  - return counts (`new_vintages`, `new_datapoints`, `rows` …);
  - clean up after themselves (`remove_empty_vintages()` if data import fails after
    vintages were inserted);
  - send **no emails** and open **no sinks**. `message()` is fine; the runner decides
    what to log and whom to email.
- **Use `pkg::fn()`, never `library()`** in packages and runners. Base pipe `|>`;
  packages declare `Depends: R (>= 4.1.0)`.
- **Reusability threshold:** only genuinely reusable code goes into a package.
  Orchestration (which tables, which emails) stays in the runner.

## 6. Feeders (umar-data)

A feeder turns a source file into a umar-data Excel file, which the ingest then loads.

- Name: `feed_<content>_<FOLDER>.R`, in `R/umar-data/feeders/`. The runner picks up
  every `feed_*.R`; adding a feeder needs no runner change.
- Header block:
  ```r
  ################################################################################
  # FEEDER: <what>
  #   reads:  <source file>
  #   writes: umar-data/<FOLDER>/umar_serije_podatki_<FOLDER>.xlsx, sheet M
  #   owner:  <initials>
  ################################################################################
  ```
- Starts with `log_msg("<content> | start")`, logs which file it used, and **ends
  with the number of new periods** as its last expression (`run_script()` returns it).
- Uses `newest_file()` and `upsert_umar_data()`, which writes only when something
  changed and logs the outcome.
- **Check the source's structure before renaming by position.** Number of columns
and rows, or better, the labels. A colleague inserting a row must cause an error,
not shifted series codes.

## 7. Manual admin tasks

No commented-out one-off code in runners. Manual operations are functions in
`R/<source>/<source>-admin.R` (source-specific: add table, update table) and
`R/common/admin-common.R` (generic: `delete_table()`, `delete_latest_vintages()`).

- Every call goes through `admin_do()`, which logs to `logs/<SOURCE>-admin.log`
with the Windows user and the action.
- Destructive functions show a preview (table code, name, counts) and ask for
confirmation. `askYesNo()` defaults to no in non-interactive sessions.
- Log what was actually done: counts of inserted or deleted rows.
- Usage: `source("R/<source>/<source>-admin.R"); <source>_add_table("CODE")`.

## 8. Keeping the log readable

One timestamped line per step plus a summary. Specifically:

  - no package attach messages: `pkg::fn()`, or `suppressPackageStartupMessages()` for
old scripts that need `library()`;
- `download.file(..., quiet = TRUE)`;
- `read_excel(..., .name_repair = "unique_quiet")`;
- known, harmless warnings are suppressed **at the call**, with a comment saying why;
- no `print()` in packages or runners: `message()` or `log_msg()`.

## 9. Changing a package that production depends on

1. Note the installed commit: `packageDescription("<pkg>")$RemoteSha`.
2. Install the new version into a test library, without dependencies:
  `pak::pkg_install("majazaloznik/<pkg>", lib = "C:/R/lib-test", dependencies = FALSE)`.
3. Test with a **copy of the `.bat`** pointing at the new runner, whose first line is
`.libPaths(c("C:/R/lib-test", .libPaths()))`. A fresh R session, no interactive
prompts, same conditions as the scheduled run.
4. Switch: install into the main library from the same R the task uses, remove the
`.libPaths()` line, point the scheduled `.bat` at the new runner.
5. Revert if needed: `pak::pkg_install("majazaloznik/<pkg>@<sha>")` and the old `.bat`.

A loaded package isn't replaced by reinstalling: restart R.

## 10. Migration checklist

- [ ] One-off code moved out of the runner into `<source>-admin.R`
- [ ] Runner uses `run_start()` / `with_run()` / `run_step()`; names follow the stem
- [ ] Package functions raise errors and return counts (§5); no wrappers in the runner
- [ ] Post-processing gated on new data; re-run tested
- [ ] `.bat` on R 4.5.2, log name = stem, exit code passed on
- [ ] Task Scheduler: runs when not logged in
- [ ] Log reads cleanly (§8)
- [ ] Entry in `registry/pipelines.yml` filled in (reads, writes, sources' `arrives`);
`render_registry.R` runs clean; `docs/pipelines/` committed
