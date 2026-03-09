library(UMARaccessR)
library(dplyr)
library(tidyr)
library(openxlsx2)

con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "192.168.38.21",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")


process_codes_vectorized <- function(codes, con, schema = "platform") {
  codes |>
    purrr::map(\(code) {
      vin <- sql_get_vintage_from_series_code(con, code, schema = schema)
      sql_get_data_points_from_vintage(con, vin, schema) |>
        dplyr::rename(!!code := value)
    }) |>
    purrr::reduce(dplyr::full_join, by = "period_id")
}

process_indicators <- function(raw, n_years = 3, n_quarters = 8, n_months = 24, full = FALSE, yoy = FALSE, agg_fun = "sum") {

  # Store original order
  indicator_order <- setdiff(names(raw), "period_id")

  # Set aggregation function
  agg_fn <- if(agg_fun == "mean") {
    function(x) mean(x, na.rm = TRUE)
  } else if(agg_fun == "last") {
    function(x) dplyr::last(x, na_rm = TRUE)
  } else {
    function(x) sum(x, na.rm = TRUE)
  }

  # Calculate GLOBAL max period (for determining which columns to show)
  global_max_period <- max(raw$period_id)
  global_max_year <- as.integer(substr(global_max_period, 1, 4))
  global_max_month <- as.integer(substr(global_max_period, 6, 7))
  global_last_complete_year <- if(global_max_month == 12) global_max_year else global_max_year - 1L
  global_last_complete_q <- if(global_max_month %% 3 == 0) {
    paste0(global_max_year, "Q", global_max_month / 3)
  } else if(global_max_month <= 3) {
    paste0(global_max_year - 1, "Q4")
  } else {
    paste0(global_max_year, "Q", floor((global_max_month - 1) / 3))
  }

  # Transpose and calculate per-indicator max periods (for determining completeness)
  df_long <- raw |>
    tidyr::pivot_longer(cols = -period_id, names_to = "indicator", values_to = "value") |>
    dplyr::filter(!is.na(value)) |>
    dplyr::mutate(
      year = as.integer(substr(period_id, 1, 4)),
      month = as.integer(substr(period_id, 6, 7)),
      quarter = paste0(year, "Q", ceiling(month/3))
    ) |>
    dplyr::mutate(
      max_period = max(period_id),
      max_year = as.integer(substr(max_period, 1, 4)),
      max_month = as.integer(substr(max_period, 6, 7)),
      last_complete_year = dplyr::if_else(max_month == 12L, max_year, max_year - 1L),
      last_complete_q = dplyr::case_when(
        max_month %% 3 == 0 ~ paste0(max_year, "Q", max_month / 3),
        max_month <= 3 ~ paste0(max_year - 1, "Q4"),
        TRUE ~ paste0(max_year, "Q", floor((max_month - 1) / 3))
      ),
      .by = indicator
    )

  if (full) {
    # Define target periods based on GLOBAL max
    target_years <- 2020:global_last_complete_year

    all_quarters_global <- expand.grid(
      y = 2020:global_max_year,
      q = 1:4
    ) |>
      dplyr::mutate(quarter = paste0(y, "Q", q)) |>
      dplyr::filter(quarter <= global_last_complete_q) |>
      dplyr::pull(quarter) |>
      sort()

    all_months_global <- raw$period_id[raw$period_id >= "2020-01" & raw$period_id <= global_max_period] |>
      unique() |>
      sort()

    # Annual
    annual <- df_long |>
      dplyr::filter(year >= if(yoy) 2019 else 2020) |>
      dplyr::filter(year <= last_complete_year) |>
      dplyr::arrange(indicator, period_id) |>
      dplyr::summarise(
        value = agg_fn(value),
        .by = c(indicator, year)
      ) |>
      dplyr::arrange(indicator, year)

    if (yoy) {
      annual <- annual |>
        dplyr::mutate(value = (value / dplyr::lag(value, default = NA) - 1) * 100,
                      .by = indicator) |>
        dplyr::filter(year >= 2020)
    }

    # Expand to all target years
    annual <- tidyr::expand_grid(
      indicator = indicator_order,
      year = target_years
    ) |>
      dplyr::left_join(annual, by = c("indicator", "year")) |>
      dplyr::mutate(period = as.character(year)) |>
      dplyr::select(indicator, period, value)

    # Quarterly
    if (n_quarters > 0) {
      quarterly <- df_long |>
        dplyr::filter(year >= if(yoy) 2019 else 2020) |>
        dplyr::filter(quarter <= last_complete_q) |>
        dplyr::arrange(indicator, period_id) |>
        dplyr::summarise(
          value = agg_fn(value),
          .by = c(indicator, quarter)
        ) |>
        dplyr::arrange(indicator, quarter)

      if (yoy) {
        quarterly <- quarterly |>
          dplyr::mutate(
            value = (value / dplyr::lag(value, n = 4, default = NA) - 1) * 100,
            year = as.integer(substr(quarter, 1, 4)),
            .by = indicator
          ) |>
          dplyr::filter(year >= 2020) |>
          dplyr::select(-year)
      }

      # Expand to all target quarters
      quarterly <- tidyr::expand_grid(
        indicator = indicator_order,
        quarter = all_quarters_global
      ) |>
        dplyr::left_join(quarterly, by = c("indicator", "quarter")) |>
        dplyr::mutate(period = paste0(substr(quarter, 3, 4), " Q", substr(quarter, 6, 6))) |>
        dplyr::select(indicator, period, value)
    } else {
      quarterly <- NULL
    }

    # Monthly
    if (n_months > 0) {
      monthly <- df_long |>
        dplyr::filter(year >= if(yoy) 2019 else 2020) |>
        dplyr::arrange(indicator, period_id)

      if (yoy) {
        monthly <- monthly |>
          dplyr::mutate(
            value = (value / dplyr::lag(value, n = 12, default = NA) - 1) * 100,
            .by = indicator
          ) |>
          dplyr::filter(year >= 2020)
      }

      monthly <- monthly |>
        dplyr::select(indicator, period_id, value)

      # Expand to all target months
      monthly <- tidyr::expand_grid(
        indicator = indicator_order,
        period_id = all_months_global
      ) |>
        dplyr::left_join(monthly, by = c("indicator", "period_id")) |>
        dplyr::mutate(period = paste0(substr(period_id, 3, 4), "-", substr(period_id, 6, 7))) |>
        dplyr::select(indicator, period, value)
    } else {
      monthly <- NULL
    }

  } else {
    # Define target periods based on GLOBAL max and n_* parameters
    target_years <- (global_last_complete_year - n_years + 1):global_last_complete_year

    all_quarters_sorted <- df_long |>
      dplyr::pull(quarter) |>
      unique() |>
      sort()
    global_q_idx <- which(all_quarters_sorted == global_last_complete_q)
    target_quarters <- all_quarters_sorted[max(1, global_q_idx - n_quarters + 1):global_q_idx]

    all_months_sorted <- raw$period_id |> unique() |> sort()
    global_m_idx <- which(all_months_sorted == global_max_period)
    target_months <- all_months_sorted[max(1, global_m_idx - n_months + 1):global_m_idx]

    # Annual
    if (n_years > 0) {
      years_for_calc <- if(yoy) (min(target_years) - 1):max(target_years) else target_years

      annual <- df_long |>
        dplyr::filter(year %in% years_for_calc) |>
        dplyr::filter(year <= last_complete_year) |>
        dplyr::arrange(indicator, period_id) |>
        dplyr::summarise(
          value = agg_fn(value),
          .by = c(indicator, year)
        ) |>
        dplyr::arrange(indicator, year)

      if (yoy) {
        annual <- annual |>
          dplyr::mutate(value = (value / dplyr::lag(value, default = NA) - 1) * 100,
                        .by = indicator) |>
          dplyr::filter(year %in% target_years)
      }

      # Expand to all target years
      annual <- tidyr::expand_grid(
        indicator = indicator_order,
        year = target_years
      ) |>
        dplyr::left_join(annual, by = c("indicator", "year")) |>
        dplyr::mutate(period = as.character(year)) |>
        dplyr::select(indicator, period, value)
    } else {
      annual <- NULL
    }

    # Quarterly
    if (n_quarters > 0) {
      quarters_for_calc <- if(yoy) {
        q_idx <- which(all_quarters_sorted == min(target_quarters))
        all_quarters_sorted[max(1, q_idx - 4):global_q_idx]
      } else {
        target_quarters
      }

      quarterly <- df_long |>
        dplyr::filter(quarter %in% quarters_for_calc) |>
        dplyr::filter(quarter <= last_complete_q) |>
        dplyr::arrange(indicator, period_id) |>
        dplyr::summarise(
          value = agg_fn(value),
          .by = c(indicator, quarter)
        ) |>
        dplyr::arrange(indicator, quarter)

      if (yoy) {
        quarterly <- quarterly |>
          dplyr::mutate(
            value = (value / dplyr::lag(value, n = 4, default = NA) - 1) * 100,
            .by = indicator
          ) |>
          dplyr::filter(quarter %in% target_quarters)
      }

      # Expand to all target quarters
      quarterly <- tidyr::expand_grid(
        indicator = indicator_order,
        quarter = target_quarters
      ) |>
        dplyr::left_join(quarterly, by = c("indicator", "quarter")) |>
        dplyr::mutate(period = paste0(substr(quarter, 3, 4), " Q", substr(quarter, 6, 6))) |>
        dplyr::select(indicator, period, value)
    } else {
      quarterly <- NULL
    }

    # Monthly
    if (n_months > 0) {
      months_for_calc <- if(yoy) {
        m_idx <- which(all_months_sorted == min(target_months))
        all_months_sorted[max(1, m_idx - 12):global_m_idx]
      } else {
        target_months
      }

      monthly <- df_long |>
        dplyr::filter(period_id %in% months_for_calc) |>
        dplyr::arrange(indicator, period_id)

      if (yoy) {
        monthly <- monthly |>
          dplyr::mutate(
            value = (value / dplyr::lag(value, n = 12, default = NA) - 1) * 100,
            .by = indicator
          ) |>
          dplyr::filter(period_id %in% target_months)
      }

      monthly <- monthly |>
        dplyr::select(indicator, period_id, value)

      # Expand to all target months
      monthly <- tidyr::expand_grid(
        indicator = indicator_order,
        period_id = target_months
      ) |>
        dplyr::left_join(monthly, by = c("indicator", "period_id")) |>
        dplyr::mutate(period = paste0(substr(period_id, 3, 4), "-", substr(period_id, 6, 7))) |>
        dplyr::select(indicator, period, value)
    } else {
      monthly <- NULL
    }
  }

  # Combine and pivot wide
  result <- dplyr::bind_rows(annual, quarterly, monthly) |>
    tidyr::pivot_wider(names_from = period, values_from = value) |>
    dplyr::mutate(indicator = factor(indicator, levels = indicator_order)) |>
    dplyr::arrange(indicator) |>
    dplyr::mutate(indicator = as.character(indicator))

  result
}


load_wb_id <- function(){
  path <- paste0("\\\\192.168.38.7\\data$\\",
                 "EO\\AVTOMATIZIRANE STANDARDNE TABELE\\",
                 "Statisti\u010dna priloga indesign.xlsx")
  openxlsx2::wb_load(path)
}

load_wb_ex <- function(){
  path <- paste0("\\\\192.168.38.7\\data$\\",
                 "EO\\AVTOMATIZIRANE STANDARDNE TABELE\\",
                 "Statisti\u010dna priloga excel.xlsx")
  openxlsx2::wb_load(path)
}

load_wb_id_en <- function(){
  path <- paste0("\\\\192.168.38.7\\data$\\",
                 "EO\\AVTOMATIZIRANE STANDARDNE TABELE\\",
                 "Statisti\u010dna priloga indesign_en.xlsx")
  openxlsx2::wb_load(path)
}

load_wb_ex_en <- function(){
  path <- paste0("\\\\192.168.38.7\\data$\\",
                 "EO\\AVTOMATIZIRANE STANDARDNE TABELE\\",
                 "Statisti\u010dna priloga excel_en.xlsx")
  openxlsx2::wb_load(path)
}

fix_wb_encoding <- function(wb) {
  # Get correct names with UTF-8 encoding
  correct_names <- wb$get_sheet_names()
  Encoding(correct_names) <- "UTF-8"

  # Update XML strings in workbook metadata
  for(i in seq_along(wb$workbook$sheets)) {
    wb$workbook$sheets[i] <- sub(
      'name="[^"]*"',
      sprintf('name="%s"', correct_names[i]),
      wb$workbook$sheets[i]
    )
  }

  # Update worksheet list names for consistency
  names(wb$worksheets) <- correct_names

  wb
}

try_save_id <- function(){
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  original_path <- paste0("\\\\192.168.38.7\\data$\\",
                          "EO\\AVTOMATIZIRANE STANDARDNE TABELE\\",
                          "Statisti\u010dna priloga indesign.xlsx")

  backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)

  # Try to save, if fails, use backup path
  tryCatch({
    wb_save(wb, original_path)
    message("Statisti\u010dna priloga indesign.xlsx saved successfully to original location")
  }, error = function(e) {
    message("Could not save to original file, likely opened by another user")
    message("Error was: ", e$message)
    message("Saving to backup location: ", backup_path)
    wb_save(wb, backup_path)
    message("Statisti\u010dna priloga indesign.xlsx file saved successfully to backup location")
  })
}


try_save_id_en <- function(){
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  original_path <- paste0("\\\\192.168.38.7\\data$\\",
                          "EO\\AVTOMATIZIRANE STANDARDNE TABELE\\",
                          "Statisti\u010dna priloga indesign_en.xlsx")

  backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)

  # Try to save, if fails, use backup path
  tryCatch({
    wb_save(wb, original_path)
    message("Statisti\u010dna priloga indesign_en.xlsx saved successfully to original location")
  }, error = function(e) {
    message("Could not save to original file, likely opened by another user")
    message("Error was: ", e$message)
    message("Saving to backup location: ", backup_path)
    wb_save(wb, backup_path)
    message("Statisti\u010dna priloga indesign_en.xlsx file saved successfully to backup location")
  })
}

try_save_ex <- function(){
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  original_path <- paste0("\\\\192.168.38.7\\data$\\",
                          "EO\\AVTOMATIZIRANE STANDARDNE TABELE\\",
                          "Statisti\u010dna priloga excel.xlsx")

  backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)

  # Try to save, if fails, use backup path
  tryCatch({
    wb_save(wb, original_path)
    message("Statisti\u010dna priloga excel.xlsx saved successfully to original location")
  }, error = function(e) {
    message("Could not save to original file, likely opened by another user")
    message("Error was: ", e$message)
    message("Saving to backup location: ", backup_path)
    wb_save(wb, backup_path)
    message("Statisti\u010dna priloga excel.xlsx file saved successfully to backup location")
  })
}


try_save_ex_en <- function(){
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  original_path <- paste0("\\\\192.168.38.7\\data$\\",
                          "EO\\AVTOMATIZIRANE STANDARDNE TABELE\\",
                          "Statisti\u010dna priloga excel_en.xlsx")

  backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)

  # Try to save, if fails, use backup path
  tryCatch({
    wb_save(wb, original_path)
    message("Statisti\u010dna priloga excel_en.xlsx saved successfully to original location")
  }, error = function(e) {
    message("Could not save to original file, likely opened by another user")
    message("Error was: ", e$message)
    message("Saving to backup location: ", backup_path)
    wb_save(wb, backup_path)
    message("Statisti\u010dna priloga excel_en.xlsx file saved successfully to backup location")
  })
}
