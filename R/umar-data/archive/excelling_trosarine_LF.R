# I think this is the conditional formatting for the trosarine preracuni excel file,
# just keeping it for archival purposes
#
# wb <- openxlsx2::wb_load(final_path) |>
#   # register the named style ONCE on the workbook
#   openxlsx2::wb_add_dxfs_style(
#     name     = "pinkRow",
#     bg_fill  = openxlsx2::wb_color(hex = "FFFFC0CB")
#   )
#
# # preserve original sheet position
# sheet_pos <- match("raw", wb$get_sheet_names())
#
# # remove old sheet (also clears its CF rules)
# if (!is.na(sheet_pos)) {
#   wb <- openxlsx2::wb_remove_worksheet(wb, sheet = "raw")
# }
#
# wb <- wb |>
#   openxlsx2::wb_add_worksheet("raw") |>
#   openxlsx2::wb_add_data_table(
#     sheet = "raw",
#     x     = final_table_named,
#     table_name = "datatable",
#     start_col = 1,
#     start_row = 1,
#     table_style = "TableStyleMedium2") |>
#   openxlsx2::wb_add_conditional_formatting(
#     sheet = "raw",
#     dims  = openxlsx2::wb_dims(rows = 2:(nrow(final_table) + 1), cols = 1:ncol(final_table)),
#     rule  = "$I2",
#     style = "pinkRow"          # <- string name, not a style object
#   ) |>
#   openxlsx2::wb_add_data(sheet = "metapodatki", x = metapodatki)
#
# # test next time for july!!!
# # # after wb_load(), before wb_save()
# # wb$pivotDefinitions <- vapply(wb$pivotDefinitions, function(xml) {
# #   if (grepl("refreshOnLoad=", xml, fixed = TRUE)) {
# #     sub('refreshOnLoad="[^"]*"', 'refreshOnLoad="1"', xml)
# #   } else {
# #     sub("(<pivotCacheDefinition\\b)", '\\1 refreshOnLoad="1"', xml)
# #   }
# # }, character(1))
#
# # save final
# openxlsx2::wb_save(wb, final_path, overwrite = TRUE)
#
