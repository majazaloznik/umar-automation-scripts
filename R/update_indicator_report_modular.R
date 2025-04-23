# script to render all the modular indicator report files and update the index files.
rmd_files <- c(
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\01-nacionalni_kvartalno.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\02-nacionalni_letno.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\03-kazalniki_razpolozenja.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\04-kazalniki_aktivnosti.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\05-trg_dela.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\06-cene.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\07-gradbenistvo.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\08-predelovalne_dejavnosti.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\09-mojca.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\10-zasebna.Rmd",
  "\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\11-tujina.Rmd"
)

out_files <-list.files("\\\\192.168.38.7\\public$\\Avtomatizacija\\indikatorji_porocilo\\indikatorji_po_poglavjih")[-1]

time <- format(Sys.time(), "%d.%b%Y_%H%m")
render_rename <- function(rmd_file, outfile_name) {
  # Create temp directory for intermediates
  temp_dir <- file.path(tempdir(), "rmd_temp")
  dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)

  # The file name with timestamp
  outfile <- paste0("\\\\192.168.38.7\\public$\\Avtomatizacija\\indikatorji_porocilo\\indikatorji_po_poglavjih\\",
                    format(Sys.time(), "%d.%b%Y_%H%m"), "_", outfile_name)
  # The file name without timestamp
  origfile <- paste0("\\\\192.168.38.7\\public$\\Avtomatizacija\\indikatorji_porocilo\\indikatorji_po_poglavjih\\", outfile_name)

  # Render with explicit intermediates directory
  rmarkdown::render(
    input = rmd_file,
    output_file = outfile,
    intermediates_dir = temp_dir
  )

  # Rename the file
  tryCatch({
    file.rename(outfile, origfile)
  }, warning = function(w) {
    print(paste("Warning: ", w))
  }, error = function(e) {
    print(paste("Error: ", e))
  })
}

### render all the Rmd files
# Apply the function to all Rmd files
mapply(render_rename, rmd_file = rmd_files, outfile_name = out_files)


### Update the index file
index_update <- function(){
  # Step 1: Read the file
  lines <- readLines("\\\\192.168.38.7\\public$\\Avtomatizacija\\indikatorji_porocilo\\indikatorji_po_poglavjih\\00-index.html")

  # Step 2: Generate timestamp
  timestamp <- Sys.time()

  insert_at <- grep("</body>", lines)
  timestamp_line <- grep("Posodobljeno:", lines)

  # If timestamp exists, remove it
  if(length(timestamp_line) > 0) {
    lines <- lines[-timestamp_line]
    # If the timestamp line was before the insert point, decrease the insert point by 1
    if(timestamp_line < insert_at) {
      insert_at <- insert_at - 1
    }
  }

  # Step 4: Insert the timestamp
  lines <- append(lines, sprintf("<p><i>Posodobljeno: %s</i></p>", timestamp), after = insert_at - 1)

  # Step 5: Write the lines back to the file
  writeLines(lines, "\\\\192.168.38.7\\public$\\Avtomatizacija\\indikatorji_porocilo\\indikatorji_po_poglavjih\\00-index.html")
}

tryCatch({
  # Try to rename the file
  index_update()
}, warning = function(w) {
  # Handle warnings here
  print(paste("Warning: ", w))
}, error = function(e) {
  # Handle errors here
  print(paste("Error: ", e))
})
