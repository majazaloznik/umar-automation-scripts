UmarDataBotR::log_msg("commodity prices | start")
# scrape dynamic url to excel file
get_wb_commodity_url <- function(link_text = "Monthly prices") {
  page <- rvest::read_html("https://www.worldbank.org/en/research/commodity-markets")
  links <- rvest::html_elements(page, "a")
  idx <- which(trimws(rvest::html_text2(links)) == link_text)
  if (length(idx) == 0) stop("Link '", link_text, "' not found")
  rvest::html_attr(links[[idx[1]]], "href")
}

url <- get_wb_commodity_url()
tmp <- tempfile(fileext = ".xlsx")
utils::download.file(url, tmp, mode = "wb", quiet = TRUE)

ids_indices <- c("WB-UMAR--UB001--TOT--M",
                    "WB-UMAR--UB001--ENE--M",
                    "WB-UMAR--UB001--NON--M",
                    "WB-UMAR--UB001--AGR--M",
                    "WB-UMAR--UB001--BEV--M",
                    "WB-UMAR--UB001--FOOD--M",
                    "WB-UMAR--UB001--OM--M",
                    "WB-UMAR--UB001--GR--M",
                    "WB-UMAR--UB001--OTF--M",
                    "WB-UMAR--UB001--RM--M",
                    "WB-UMAR--UB001--TIMB--M",
                    "WB-UMAR--UB001--ORM--M",
                    "WB-UMAR--UB001--FERT--M",
                    "WB-UMAR--UB001--MM--M",
                    "WB-UMAR--UB001--BM--M",
                    "WB-UMAR--UB001--PRM--M")

ids_prices <- c("WB-UMAR--UB002--COA--M",
                    "WB-UMAR--UB002--COB--M",
                    "WB-UMAR--UB002--COD--M",
                    "WB-UMAR--UB002--COW--M",
                    "WB-UMAR--UB002--CAU--M",
                    "WB-UMAR--UB002--CSA--M",
                    "WB-UMAR--UB002--NGUS--M",
                    "WB-UMAR--UB002--NGEU--M",
                    "WB-UMAR--UB002--LNGJ--M",
                    "WB-UMAR--UB002--NGI--M",
                    "WB-UMAR--UB002--CC--M",
                    "WB-UMAR--UB002--CFA--M",
                    "WB-UMAR--UB002--CFR--M",
                    "WB-UMAR--UB002--TA3--M",
                    "WB-UMAR--UB002--TC--M",
                    "WB-UMAR--UB002--TK--M",
                    "WB-UMAR--UB002--TM--M",
                    "WB-UMAR--UB002--CCO--M",
                    "WB-UMAR--UB002--GN--M",
                    "WB-UMAR--UB002--FM--M",
                    "WB-UMAR--UB002--GNO--M",
                    "WB-UMAR--UB002--PO--M",
                    "WB-UMAR--UB002--PKO--M",
                    "WB-UMAR--UB002--SY--M",
                    "WB-UMAR--UB002--SYO--M",
                    "WB-UMAR--UB002--SYM--M",
                    "WB-UMAR--UB002--RSO--M",
                    "WB-UMAR--UB002--SFO--M",
                    "WB-UMAR--UB002--BRL--M",
                    "WB-UMAR--UB002--MZ--M",
                    "WB-UMAR--UB002--SRG--M",
                    "WB-UMAR--UB002--RT5--M",
                    "WB-UMAR--UB002--RT25--M",
                    "WB-UMAR--UB002--RTA1--M",
                    "WB-UMAR--UB002--RVN5--M",
                    "WB-UMAR--UB002--WUSS--M",
                    "WB-UMAR--UB002--WUSH--M",
                    "WB-UMAR--UB002--BNEU--M",
                    "WB-UMAR--UB002--BNUS--M",
                    "WB-UMAR--UB002--ORN--M",
                    "WB-UMAR--UB002--BEEF--M",
                    "WB-UMAR--UB002--CHIC--M",
                    "WB-UMAR--UB002--LAMB--M",
                    "WB-UMAR--UB002--SHR--M",
                    "WB-UMAR--UB002--SGEU--M",
                    "WB-UMAR--UB002--SHUS--M",
                    "WB-UMAR--UB002--SHWD--M",
                    "WB-UMAR--UB002--TBC--M",
                    "WB-UMAR--UB002--LOGC--M",
                    "WB-UMAR--UB002--LOGM--M",
                    "WB-UMAR--UB002--SWC--M",
                    "WB-UMAR--UB002--SWM--M",
                    "WB-UMAR--UB002--PLYW--M",
                    "WB-UMAR--UB002--CTNA--M",
                    "WB-UMAR--UB002--RBT--M",
                    "WB-UMAR--UB002--RBR--M",
                    "WB-UMAR--UB002--PHR--M",
                    "WB-UMAR--UB002--DAP--M",
                    "WB-UMAR--UB002--TSP--M",
                    "WB-UMAR--UB002--UREA--M",
                    "WB-UMAR--UB002--KCL--M",
                    "WB-UMAR--UB002--AL--M",
                    "WB-UMAR--UB002--IO--M",
                    "WB-UMAR--UB002--CU--M",
                    "WB-UMAR--UB002--PB--M",
                    "WB-UMAR--UB002--SN--M",
                    "WB-UMAR--UB002--NI--M",
                    "WB-UMAR--UB002--ZN--M",
                    "WB-UMAR--UB002--AU--M",
                    "WB-UMAR--UB002--PT--M",
                    "WB-UMAR--UB002--AG--M")

# defensive programming because they randomly add new header rows.. counting
# on the fact that the period data is always formatted the same way YYYYMMM
read_wb_sheet <- \(path, sheet, ids) {
  raw <- readxl::read_excel(path, sheet = sheet, col_names = FALSE,
                            col_types = "text", .name_repair = "minimal")
  raw <- raw[grepl("^\\d{4}M\\d{2}$", raw[[1]]), , drop = FALSE]
  if (nrow(raw) == 0) stop(sheet, ": no YYYYMmm rows found")
  if (ncol(raw) != length(ids) + 1L)
    stop(sheet, ": expected ", length(ids) + 1L, " columns, got ", ncol(raw))
  names(raw) <- c("period", ids)
  raw |>
    dplyr::mutate(
      dplyr::across(-period, \(x) suppressWarnings(as.numeric(x))),  # "…" -> NA
      period = as.Date(paste0(substr(period, 1, 4), "-", substr(period, 6, 7), "-01"))
    )
}

raw1 <- read_wb_sheet(tmp, "Monthly Indices", ids_indices)  # ids_indices = your 16 codes
raw2 <- read_wb_sheet(tmp, "Monthly Prices",  ids_prices)   # ids_prices  = your 71 codes
final <- dplyr::full_join(raw1, raw2, by = "period")

path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\UB\\umar_serije_podatki_UB.xlsx"
# Read existing file
existing <- readxl::read_excel(path)

# Update/merge with new data
if (nrow(existing) == 0) {
  updated <- final
} else {
  updated <- existing |> dplyr::rows_upsert(final, by = "period")
}

# Write back
openxlsx::write.xlsx(updated,
                     file = path,
                     sheetName = "M",
                     overwrite = TRUE)
