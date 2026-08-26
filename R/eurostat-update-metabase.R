# run-eurostat-monitor.R — entry point for the scheduled job.
# Sources the monitor function files, then runs main().

monitor_dir <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\eurostat-metabase"

for (f in list.files(monitor_dir, pattern = "\\.R$", full.names = TRUE)) source(f)

tryCatch(
  main(),
  error = function(e) message("FAILED: ", conditionMessage(e)))
