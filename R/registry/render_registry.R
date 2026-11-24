################################################################################
# PIPELINE REGISTRY: validate + render
#
#   Rscript R/registry/render_registry.R [path/to/schtasks.csv]
#
# Reads registry/pipelines.yml, checks it against the repo (and optionally
# against a `schtasks /query /fo csv /v` export), and writes docs/pipelines/:
#   index.md            outputs, tasks and sources, linked
#   task-<id>.md        runbook per scheduled task
#   output-<id>.md      upstream trace per output, with sources and logs
#
# Exits with status 1 if there are errors (unknown ids, missing files), so it
# can run as a check. Warnings (TODOs, unregistered .bat files) don't fail.
# Run from the repo root.
################################################################################

registry_file <- "registry/pipelines.yml"
docs_dir      <- "docs/pipelines"
args          <- commandArgs(trailingOnly = TRUE)

if (!exists("%||%", baseenv())) `%||%` <- function(x, y) if (is.null(x)) y else x  # base R >= 4.4
schtasks_csv  <- if (length(args) >= 1) args[1] else NA_character_

# ---- read and flatten ---------------------------------------------------------

#' Turn a reads/writes list into a data frame of (id, detail)
#'
#' Entries are either a bare id ("platform_SURS") or a one-element map
#' (`platform_SURS: 0701029S`).
#' @param x list from yaml
#' @return data.frame with columns id, detail
#' @keywords internal
parse_refs <- function(x) {
  if (is.null(x) || length(x) == 0) return(data.frame(id = character(), detail = character()))
  purrr::map(x, \(e) {
    if (is.list(e)) data.frame(id = names(e)[1], detail = as.character(e[[1]]))
    else data.frame(id = as.character(e), detail = NA_character_)
  }) |> purrr::list_rbind()
}

#' Read the registry into node and edge tables
#'
#' @param file path to pipelines.yml
#' @return list(reg = raw yaml, nodes = data.frame, edges = data.frame)
#' @keywords internal
read_registry <- function(file) {
  reg <- yaml::read_yaml(file, fileEncoding = "UTF-8")

  simple_nodes <- purrr::imap(c(sources = "source", stores = "store", outputs = "output"),
                              \(type, section) {
                                items <- reg[[section]]
                                if (is.null(items)) return(NULL)
                                data.frame(id = names(items), type = type, task = NA_character_,
                                           what = purrr::map_chr(items, \(i) i$what %||% NA_character_))
                              }) |> purrr::list_rbind()

  task_nodes <- data.frame(id = names(reg$tasks), type = "task", task = NA_character_,
                           what = purrr::map_chr(reg$tasks, \(t) t$schedule %||% NA_character_))

  step_nodes <- purrr::imap(reg$tasks, \(t, tid) {
    if (is.null(t$steps)) return(NULL)
    data.frame(id = names(t$steps), type = "step", task = tid,
               what = purrr::map_chr(t$steps, \(s) s$script %||% NA_character_))
  }) |> purrr::list_rbind()

  nodes <- rbind(simple_nodes, task_nodes, step_nodes)

  flow <- purrr::imap(reg$tasks, \(t, tid) {
    purrr::imap(t$steps, \(s, sid) {
      r <- parse_refs(s$reads)
      w <- parse_refs(s$writes)
      rbind(
        if (nrow(r)) data.frame(from = r$id, to = sid, kind = "flow", detail = r$detail),
        if (nrow(w)) data.frame(from = sid, to = w$id, kind = "flow", detail = w$detail))
    }) |> purrr::list_rbind()
  }) |> purrr::list_rbind()

  after <- purrr::imap(reg$tasks, \(t, tid) {
    if (length(t$after) == 0) return(NULL)
    data.frame(from = unlist(t$after), to = tid, kind = "after", detail = NA_character_)
  }) |> purrr::list_rbind()

  list(reg = reg, nodes = nodes, edges = rbind(flow, after))
}

# ---- checks -------------------------------------------------------------------

#' Is this a path inside the repo (as opposed to a share or another repo)?
#' @keywords internal
in_repo <- function(p) !grepl("^(\\.\\./|[A-Za-z]:/|data\\$|Users/|\\\\\\\\)", p)

#' Repo-relative paths of the R scripts a .bat file sources
#'
#' Picks up `source('...')` calls, keeps those under umar-automation-scripts
#' and returns them relative to the repo root with forward slashes.
#' @param bat path to a .bat file
#' @return character vector
#' @keywords internal
bat_scripts <- function(bat) {
  txt <- paste(readLines(bat, warn = FALSE, encoding = "latin1"), collapse = "\n")
  # expand the %REPO2:\=/% style used in davcne-weekly-update.bat
  txt <- gsub("%REPO2:\\\\=/%", "//192.168.38.7/public$/Avtomatizacija/umar-automation-scripts", txt)
  hits <- regmatches(txt, gregexpr("source\\('[^']+'\\)", txt))[[1]]
  paths <- gsub("\\\\+", "/", sub("^source\\('(.*)'\\)$", "\\1", hits))
  paths <- paths[grepl("umar-automation-scripts/", paths)]
  sub(".*umar-automation-scripts/", "", paths)
}

#' Run all checks
#'
#' @param r output of read_registry()
#' @param schtasks optional data.frame from a schtasks csv export
#' @return data.frame(level = "error"|"warning", msg)
#' @keywords internal
check_registry <- function(r, schtasks = NULL) {
  out <- list()
  add <- function(level, ...) out[[length(out) + 1]] <<- data.frame(level = level, msg = paste0(...))

  # unexpected keys usually mean a typo, or an unquoted comma inside {...}
  allowed <- list(
    tasks   = c("scheduler", "schedule", "bat", "log", "email", "r", "after", "rerun_note", "notes", "steps"),
    steps   = c("script", "reads", "writes"),
    sources = c("what", "owner", "where", "arrives"),
    stores  = c("what", "where"),
    outputs = c("what", "type", "where", "users"))
  check_keys <- function(items, ok, label)
    for (id in names(items)) for (k in setdiff(names(items[[id]]), ok))
      add("warning", label, " ", id, ": unknown key '", k, "' (typo, or a comma that needs quotes?)")
  for (sec in c("tasks", "sources", "stores", "outputs")) check_keys(r$reg[[sec]], allowed[[sec]], sec)
  for (tid in names(r$reg$tasks)) check_keys(r$reg$tasks[[tid]]$steps, allowed$steps, paste0("step in ", tid, ":"))

  dup <- unique(r$nodes$id[duplicated(r$nodes$id)])
  for (d in dup) add("error", "id used more than once: ", d)

  unknown <- setdiff(c(r$edges$from, r$edges$to), r$nodes$id)
  for (u in unknown) add("error", "unknown id in reads/writes/after: ", u)

  for (tid in names(r$reg$tasks)) {
    t <- r$reg$tasks[[tid]]
    for (f in c(t$bat, unlist(t$log)))
      if (!is.null(f) && in_repo(f) && !file.exists(f)) add("error", tid, ": file not found: ", f)
    for (sid in names(t$steps)) {
      s <- t$steps[[sid]]
      if (!is.null(s$script) && in_repo(s$script) && !file.exists(s$script))
        add("error", tid, "/", sid, ": script not found: ", s$script)
      if (is.null(s$reads) && is.null(s$writes)) add("warning", tid, "/", sid, ": no reads/writes yet")
    }
    if (!is.null(t$bat) && file.exists(t$bat))
      for (p in bat_scripts(t$bat))
        if (!file.exists(p)) add("error", t$bat, " runs a script that is not in the repo: ", p)
  }

  bats <- list.files("batch-scripts", "\\.bat$", full.names = TRUE)
  registered <- unlist(purrr::map(r$reg$tasks, "bat"))
  for (b in setdiff(bats, registered)) add("warning", "bat not in any task: ", b)

  flow <- r$edges[r$edges$kind == "flow", ]
  for (o in r$nodes$id[r$nodes$type == "output"])
    if (!o %in% flow$to) add("warning", "output not written by any step: ", o)
  for (s in r$nodes$id[r$nodes$type == "source"])
    if (!s %in% flow$from) add("warning", "source not read by any step: ", s)

  if (!is.null(schtasks)) {
    # schtasks exports in the console code page, so compare without diacritics
    ascii <- function(x) iconv(x, "UTF-8", "ASCII//TRANSLIT", sub = "?")
    ours <- unique(schtasks$TaskName)
    reg_names <- stats::na.omit(purrr::map_chr(r$reg$tasks, \(t) t$scheduler %||% NA_character_))
    for (n in ours[!ascii(ours) %in% ascii(reg_names)])
      add("warning", "Task Scheduler task not in registry: ", n)
    for (n in reg_names[!ascii(reg_names) %in% ascii(ours)])
      add("warning", "registry task not in Task Scheduler: ", n)

    interactive_only <- unique(schtasks$TaskName[schtasks$`Logon Mode` == "Interactive only"])
    for (n in interactive_only)
      add("warning", n, ": runs only while its user is logged in (Interactive only)")

    once <- schtasks[schtasks$`Schedule Type` == "One Time Only", ]
    if (nrow(once)) {
      once$start <- as.Date(once$`Start Date`, format = "%d. %m. %Y")
      last <- tapply(once$start, once$TaskName, max)
      for (n in names(last)) {
        d <- as.Date(last[[n]])
        if (!is.na(d) && d < Sys.Date() + 45)
          add("warning", n, ": one-off triggers only, last one on ", format(d, "%d. %m. %Y"),
              " -- add next ones or the task stops")
      }
    }
  }
  if (length(out)) purrr::list_rbind(out) else data.frame(level = character(), msg = character())
}

#' Read a schtasks /fo csv /v export, keeping only our own tasks
#' @param file path to csv
#' @keywords internal
read_schtasks <- function(file) {
  x <- utils::read.csv(file, check.names = FALSE, encoding = "UTF-8", fileEncoding = "UTF-8-BOM")
  x[x$TaskName != "TaskName" & grepl("^\\\\[^\\\\]+$", x$TaskName) &
      !grepl("^\\\\(OneDrive|User_Feed)", x$TaskName), ]
}

# ---- traversal and rendering ------------------------------------------------------

#' All nodes upstream of `id` along flow edges (including `id`)
#' @keywords internal
upstream <- function(id, edges) {
  flow <- edges[edges$kind == "flow", ]
  seen <- id
  frontier <- id
  while (length(frontier)) {
    nxt <- setdiff(flow$from[flow$to %in% frontier], seen)
    seen <- c(seen, nxt)
    frontier <- nxt
  }
  seen
}

#' All outputs downstream of `id`
#' @keywords internal
downstream_outputs <- function(id, edges, nodes) {
  flow <- edges[edges$kind == "flow", ]
  seen <- id
  frontier <- id
  while (length(frontier)) {
    nxt <- setdiff(flow$to[flow$from %in% frontier], seen)
    seen <- c(seen, nxt)
    frontier <- nxt
  }
  intersect(seen, nodes$id[nodes$type == "output"])
}

mmd_id <- function(x) gsub("[^A-Za-z0-9_]", "_", x)
md_esc <- function(x) {
  x <- paste(unlist(x), collapse = ", ")
  if (is.na(x) || x == "") "—" else gsub("\\|", "\\\\|", x)
}

#' Mermaid flowchart for a set of node ids
#' @keywords internal
mermaid <- function(ids, nodes, edges, reg) {
  n <- nodes[nodes$id %in% ids & nodes$type != "task", ]
  e <- edges[edges$kind == "flow" & edges$from %in% n$id & edges$to %in% n$id, ]
  short <- function(x, k = 30) ifelse(nchar(x) > k, paste0(substr(x, 1, k - 1), "\u2026"), x)
  label <- function(i, type) {
    sub <- switch(type,
                  source = reg$sources[[i]]$owner %||% "",
                  step   = "",
                  store  = reg$stores[[i]]$what %||% "",
                  output = reg$outputs[[i]]$what %||% "")
    sub <- gsub('"', "'", short(sub))
    txt <- if (nzchar(sub)) paste0(i, "<br/>", sub) else i
    sprintf('%s["%s"]:::%s', mmd_id(i), txt, type)
  }
  other <- n[n$type != "step", ]
  steps <- n[n$type == "step", ]
  # steps grouped in a box per task, so the task name needn't be on every node
  task_boxes <- unlist(purrr::map(unique(steps$task), \(t) c(
    sprintf('  subgraph %s["task: %s"]', mmd_id(paste0("task_", t)), t),
    paste0("    ", purrr::map_chr(steps$id[steps$task == t], \(i) label(i, "step"))),
    "  end",
    sprintf("  style %s fill:none,stroke:#888780,stroke-dasharray:4 3,color:#888780",
            mmd_id(paste0("task_", t))))))
  # mid-tone fills with dark text: readable in both light and dark GitHub themes
  c("```mermaid", "flowchart LR",
    paste0("  ", purrr::map2_chr(other$id, other$type, label)),
    task_boxes,
    if (nrow(e)) paste0("  ", mmd_id(e$from), " --> ", mmd_id(e$to)),
    "  classDef source fill:#F0997B,stroke:#712B13,color:#4A1B0C,stroke-width:1px",
    "  classDef step fill:#D3D1C7,stroke:#444441,color:#2C2C2A,stroke-width:1px",
    "  classDef store fill:#5DCAA5,stroke:#085041,color:#04342C,stroke-width:1px",
    "  classDef output fill:#AFA9EC,stroke:#3C3489,color:#26215C,stroke-width:1px",
    "```")
}

task_of <- function(ids, nodes) unique(stats::na.omit(nodes$task[nodes$id %in% ids]))
fmt_log <- function(x) paste(unlist(x), collapse = ", ")

#' Write all pages
#' @keywords internal
render_docs <- function(r, problems) {
  reg <- r$reg
  dir.create(docs_dir, showWarnings = FALSE, recursive = TRUE)
  unlink(list.files(docs_dir, "\\.md$", full.names = TRUE))
  w <- function(name, lines) writeLines(enc2utf8(lines), file.path(docs_dir, name), useBytes = TRUE)

  # outputs
  for (oid in names(reg$outputs)) {
    o <- reg$outputs[[oid]]
    up <- upstream(oid, r$edges)
    srcs <- intersect(up, names(reg$sources))
    tasks <- task_of(up, r$nodes)
    w(paste0("output-", oid, ".md"), c(
      paste("#", o$what %||% oid), "",
      paste0("`", oid, "` · ", o$type %||% "", " · ", o$where %||% ""), "",
      paste("Uporabniki:", paste(unlist(o$users), collapse = ", ")), "",
      "## Od kod pride", "", mermaid(up, r$nodes, r$edges, reg), "",
      "## Viri", "", "| Vir | Kdo | Kje | Kdaj pride |", "|---|---|---|---|",
      purrr::map_chr(srcs, \(s) { x <- reg$sources[[s]]
      sprintf("| %s | %s | %s | %s |", md_esc(x$what), md_esc(x$owner), md_esc(x$where), md_esc(x$arrives)) }),
      "", "## Taski", "", "| Task | Kdaj | .bat | Log |", "|---|---|---|---|",
      purrr::map_chr(tasks, \(t) { x <- reg$tasks[[t]]
      sprintf("| [%s](task-%s.md) | %s | `%s` | `%s` |", t, t, md_esc(x$schedule), x$bat %||% "", fmt_log(x$log)) })))
  }

  # tasks
  for (tid in names(reg$tasks)) {
    t <- reg$tasks[[tid]]
    steps <- names(t$steps)
    near <- unique(c(steps, r$edges$from[r$edges$to %in% steps], r$edges$to[r$edges$from %in% steps]))
    outs <- unique(unlist(purrr::map(steps, \(s) downstream_outputs(s, r$edges, r$nodes))))
    feeds <- r$edges$to[r$edges$kind == "after" & r$edges$from == tid]
    w(paste0("task-", tid, ".md"), c(
      paste("# Task", tid), "",
      "| | |", "|---|---|",
      sprintf("| Task Scheduler | `%s` |", t$scheduler %||% "—"),
      sprintf("| Kdaj | %s |", md_esc(t$schedule)),
      sprintf("| .bat | `%s` |", t$bat %||% "—"),
      sprintf("| Log | `%s` |", fmt_log(t$log)),
      sprintf("| Email (ime runa) | %s |", md_esc(paste(unlist(t$email), collapse = ", "))),
      sprintf("| R | %s |", md_esc(t$r)),
      sprintf("| Teče po | %s |", md_esc(paste(unlist(t$after), collapse = ", "))),
      sprintf("| Pred | %s |", md_esc(paste(feeds, collapse = ", "))),
      sprintf("| Ponovni zagon | %s |", t$rerun_note %||% "varen"),
      "", if (!is.null(t$notes)) c(t$notes, ""),
      "## Ponovni zagon", "",
      "V Task Schedulerju desni klik na task → Run, ali poženi .bat. Izid je v logu zgoraj in v mailu bota.", "",
      "## Koraki", "", mermaid(near, r$nodes, r$edges, reg), "",
      if (length(outs)) c("## Napaja", "", paste0("- [", outs, "](output-", outs, ".md)"))))
  }

  # index
  src_rows <- purrr::map_chr(names(reg$sources), \(s) { x <- reg$sources[[s]]
  outs <- downstream_outputs(s, r$edges, r$nodes)
  sprintf("| %s | %s | %s | %s |", md_esc(x$what), md_esc(x$owner), md_esc(x$arrives),
          if (length(outs)) paste0("[", outs, "](output-", outs, ".md)", collapse = ", ") else "—") })
  w("index.md", c(
    "# UMAR pipelines", "",
    "Generirano iz `registry/pipelines.yml` z `R/registry/render_registry.R`. Ne urejaj ročno.", "",
    "## Izhodi", "", "| Izhod | Tip | Uporabniki |", "|---|---|---|",
    purrr::imap_chr(reg$outputs, \(o, id)
                    sprintf("| [%s](output-%s.md) | %s | %s |", o$what %||% id, id, md_esc(o$type),
                            md_esc(paste(unlist(o$users), collapse = ", ")))),
    "", "## Taski", "", "| Task | Kdaj | Log |", "|---|---|---|",
    purrr::imap_chr(reg$tasks, \(t, id)
                    sprintf("| [%s](task-%s.md) | %s | `%s` |", id, id, md_esc(t$schedule), fmt_log(t$log))),
    "", "## Viri", "", "| Vir | Kdo | Kdaj pride | Vpliva na |", "|---|---|---|---|", src_rows,
    if (nrow(problems)) c("", "## Odprte točke", "", paste0("- ", problems$level, ": ", problems$msg))))
}

# ---- main ---------------------------------------------------------------------

r <- read_registry(registry_file)
schtasks <- if (!is.na(schtasks_csv)) read_schtasks(schtasks_csv) else NULL
problems <- check_registry(r, schtasks)
render_docs(r, problems)

for (i in seq_len(nrow(problems))) message(toupper(problems$level[i]), ": ", problems$msg[i])
message(sprintf("%d nodes, %d edges, %d error(s), %d warning(s); docs in %s/",
                nrow(r$nodes), nrow(r$edges), sum(problems$level == "error"),
                sum(problems$level == "warning"), docs_dir))
if (!interactive() && any(problems$level == "error")) quit(status = 1)
