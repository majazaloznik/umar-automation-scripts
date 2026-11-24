# Pipeline registry

`pipelines.yml` describes every scheduled pipeline: where its data comes from,
what it runs, where the data rests, and what people look at in the end.
`R/registry/render_registry.R` checks it and writes the pages in `docs/pipelines/`.

**Looking for something?** Start at [docs/pipelines/index.md](../docs/pipelines/index.md).
Each output page traces the output back to its sources, with the tasks, `.bat`
files and logs on the way.

## The model

| Kind | What it is | Example |
|---|---|---|
| **task** | one Task Scheduler task = one `.bat` file | `umar-add_data` |
| **step** | one script inside a task | `feed_place_DR` |
| **source** | where data comes from, usually a person or an agency | `src_denis_place` |
| **store** | where data rests between steps | `umardata_DR`, `platform_UMAR_DR` |
| **output** | what somebody looks at | `out_eo_tabele` |

The arrows live on steps: `reads` and `writes`. Every trace has the same shape:
output ← step ← store ← step ← … ← source.

## Fields

```yaml
tasks:
  <task id>:                    # the Task Scheduler name without the backslash
    scheduler: '\task-name'     # exactly as in Task Scheduler (quote it: backslash)
    schedule: dnevno 10:20
    bat: batch-scripts/x.bat
    log: logs/x.Rout            # or a list, if the .bat writes several logs
    email: [run_name]           # UmarDataBotR run name(s) = email subject
    r: 4.5.2
    after: [other-task]         # tasks whose output this one needs
    rerun_note: ...             # only if re-running has a side effect (emails users, ...)
    notes: ...
    steps:
      <step id>:
        script: R/x.R
        reads:  [store_a, src_b]
        writes: [store_c]

sources:  {<id>: {what, owner, where, arrives}}   # arrives: kdo/kdaj, v slovenščini
stores:   {<id>: {what, where}}
outputs:  {<id>: {what, type, where, users}}
```

A `reads`/`writes` entry is either an id or `id: detail`, when it helps to say
which tables or sheets:

```yaml
reads:
  - platform_SURS: 0701029S
  - platform_UMAR_DR: DR012 DR013
```

## Rules of thumb

- **Ids are unique across all kinds.** Prefixes help: `src_`, `out_`, `platform_`, `umardata_`.
- **Stores fine enough to trace through.** One store per database source (SURS, BS, …)
  and one per umar-data folder. A store that everything writes to makes every trace
  lead everywhere.
- **Commas inside `{...}` need quotes**: `{what: "a, b"}`. Without them YAML cuts the
  text at the comma. The check warns about this ("unknown key").
- **`arrives` is the useful bit.** "Denis desezonira podatke in jih odloži v mapo"
  answers "why hasn't it updated" before anyone opens a log.
- **Config in code is a source too**, if someone has to update it by hand
  (`src_zrsz_days`).
- **TODO** marks what isn't filled in yet. Steps without `reads`/`writes` show up as warnings.

## Running it

From the repo root, on the server:

```
chcp 65001 > nul
schtasks /query /fo csv /v > %TEMP%\tasks.csv
"C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe" R/registry/render_registry.R %TEMP%\tasks.csv
```

Without the csv it checks only the repo. With it, it also compares against Task
Scheduler, flags tasks that run only while their user is logged in, and flags
tasks that only have one-off triggers left. `chcp 65001` keeps č/š/ž intact in
the export.

It exits with an error if an id is unknown or a referenced file is missing.
Commit `docs/pipelines/` together with your change to `pipelines.yml`.
