# =====================================================================
# 0) Packages & setup
# =====================================================================

rm(list = ls())
cat("Environment cleared\n")

required <- c("tidyverse", "lubridate", "slider", "stringr", "readr", "glue")
to_install <- setdiff(required, rownames(installed.packages()))
if (length(to_install)) install.packages(to_install, dependencies = TRUE)

library(tidyverse)
library(lubridate)
library(slider)
library(stringr)
library(readr)
library(glue)

# Root folder assumption:
# - Your .Rproj lives in the project root
# - RawData/ contains:
#     * USCxxxxx.csv station files (headerless GHCN daily)
#     * ghcnd-stations.txt (NOAA station metadata)

# Download data from NOAA


download_ghcn_station <- function(station_id, out_file) {
  
  # Remove GHCND: prefix if present
  id_clean <- sub("^GHCND:", "", station_id)
  
  base_url <- "https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/by_station/"
  file_url <- paste0(base_url, id_clean, ".csv.gz")
  
  message("Downloading: ", file_url)
  
  # download the gz file
  download.file(file_url, destfile = paste0(out_file, ".gz"), mode = "wb")
  
  # unzip it
  R.utils::gunzip(paste0(out_file, ".gz"), overwrite = TRUE)
  
  message("Saved to: ", out_file)
}


stations <- c(
  "GHCND:USC00435542",  # Newport VT
  "GHCND:USC00304555",  # Lake Placid NY
  "GHCND:USC00273850",  # Hanover NH
  "GHCND:USC00301966",   # Dannemora, NY
  "GHCND:USC00308631",  # Tupper Lake NY
  "GHCND:USC00432769", # Enosburg Falls VT
  "GHCND:USC00271647"  # Colebrook NH
  
)

for (id in stations) {
  name <- sub("^GHCND:", "", id)
  out_file <- paste0("RawData/", name, ".csv")
  download_ghcn_station(id, out_file)
}


# =====================================================================
# 1) Helper: read + reshape a headerless GHCN station CSV
# =====================================================================

prepare_ghcn_station <- function(path) {
  raw <- read_csv(
    path,
    #"RawData/USC00273850.csv",
    col_names = c(
      "STATION", "DATE_ghcn", "ELEMENT", "VALUE",
      "MFLAG", "QFLAG", "SFLAG", "OBS_TIME"
    ),
    show_col_types = FALSE
  )
  
  daily <- raw %>%
    # we only care about daily max/min temp for sap logic
    filter(ELEMENT %in% c("TMAX", "TMIN")) %>%
    mutate(
      DATE  = ymd(DATE_ghcn),
      VALUE = as.numeric(VALUE)
    ) %>%
    select(STATION, DATE, ELEMENT, VALUE) %>%
    
    # long -> wide: one row per date with TMAX/TMIN columns
    pivot_wider(
      names_from  = ELEMENT,
      values_from = VALUE
    ) %>%
    
    # convert tenths °C -> °F (GHCN convention)
    mutate(
      TMAX_C = TMAX / 10,
      TMIN_C = TMIN / 10,
      TMAX_F = TMAX_C * 9/5 + 32,
      TMIN_F = TMIN_C * 9/5 + 32
    ) %>%
    arrange(DATE)
  
  daily
}

# =====================================================================
# 2) Helper: compute sap-window metrics for one station
# =====================================================================
compute_sap_bounds <- function(weather_data,
                               station_id   = NA_character_,
                               tmin_freeze  = 32,   # °F
                               tmax_min     = 33,   # lower daytime bound
                               tmax_max     = 55,   # upper daytime bound
                               run_window   = 4,    # days in sliding window
                               min_run_len  = 3) {  # required SapDays in window
  
  wx <- weather_data %>%
    mutate(
      DATE     = as.Date(DATE),          # ensure Date class
      year_sap = lubridate::year(DATE),
      month    = lubridate::month(DATE),
      
      # restrict to core season for sap reporting
      in_window = month >= 2 & month <= 4,
      
      # candidate sap days: freeze at night, thaw in day, not too hot
      candidate = dplyr::case_when(
        in_window &
          !is.na(TMIN_F) & !is.na(TMAX_F) &
          TMIN_F <= tmin_freeze &
          TMAX_F >= tmax_min &
          TMAX_F <= tmax_max ~ TRUE,
        in_window ~ FALSE,   # in Feb–Apr but temps not sap-friendly
        TRUE      ~ NA       # outside Feb–Apr: ignore
      ),
      
      SapDay = candidate
    ) %>%
    arrange(DATE) %>%
    dplyr::group_by(year_sap) %>%
    dplyr::mutate(
      # rolling count of SapDays in a run_window-day window
      sap_roll = slider::slide_int(
        as.integer(SapDay %in% TRUE),
        sum,
        .before   = run_window - 1,
        .complete = TRUE
      ),
      
      # first point where we have ≥ min_run_len SapDays in any window
      start_marker = in_window & !is.na(sap_roll) & sap_roll >= min_run_len
    ) %>%
    dplyr::ungroup()
  
  # --- NEW: yearly sap_days_index from the same wx --------------------
  sap_index <- wx %>%
    dplyr::filter(in_window) %>%          # only Feb–Apr
    dplyr::group_by(year_sap) %>%
    dplyr::summarise(
      sap_days_index = sum(SapDay %in% TRUE, na.rm = TRUE),
      .groups = "drop"
    )
  # --------------------------------------------------------------------
  
  sap_bounds <- wx %>%
    dplyr::filter(in_window) %>%   # only Feb–Apr for reporting
    dplyr::group_by(year_sap) %>%
    dplyr::summarise(
      # first true sap-start in that year
      FSW_raw = suppressWarnings(min(DATE[start_marker], na.rm = TRUE)),
      
      # last SapDay *after the season has started*
      LSW_raw = suppressWarnings(
        max(DATE[SapDay %in% TRUE & DATE >= FSW_raw], na.rm = TRUE)
      ),
      
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      FSW_num = as.numeric(FSW_raw),
      LSW_num = as.numeric(LSW_raw),
      
      # years with no valid FSW/LSW → set to NA instead of Inf / -Inf
      FSW_num = ifelse(is.infinite(FSW_num), NA_real_, FSW_num),
      LSW_num = ifelse(is.infinite(LSW_num), NA_real_, LSW_num),
      
      FSW = as.Date(FSW_num, origin = "1970-01-01"),
      LSW = as.Date(LSW_num, origin = "1970-01-01"),
      
      # if you want inclusive counting, make this `LSW - FSW + 1L`
      WindowDays = as.integer(LSW - FSW),
      station_id = station_id
    ) %>%
    dplyr::select(station_id, year_sap, FSW, LSW, WindowDays)
  
  # --- NEW: attach sap_days_index to sap_bounds -----------------------
  sap_bounds <- sap_bounds %>%
    dplyr::left_join(sap_index, by = "year_sap")
  # --------------------------------------------------------------------
  
  sap_bounds
}


# =====================================================================
# 3) Station metadata from ghcnd-stations.txt
# =====================================================================

# Adjust the path if your metadata file lives somewhere else
stations_meta_path <- "RawData/ghcnd-stations.txt"

stations_meta <- read_fwf(
  stations_meta_path,
  fwf_cols(
    ID    = c(1, 11),
    LAT   = c(13, 20),
    LON   = c(22, 30),
    ELEV  = c(32, 37),
    STATE = c(39, 40),
    NAME  = c(42, 71)
  ),
  trim_ws   = TRUE,
  col_types = "cdddcc"
) %>%
  mutate(
    station_id = ID,
    name       = str_squish(NAME),
    station_name = if_else(
      STATE == "" | is.na(STATE),
      paste0(name, " (", station_id, ")"),
      paste0(name, ", ", STATE, " (", station_id, ")")
    )
  )

# =====================================================================
# 4) Loop over all USC station files in RawData/
# =====================================================================

station_files <- list.files(
  "RawData",
  pattern    = "^USC.*\\.csv$",  # only GHCN station CSVs
  full.names = TRUE
)

all_sap <- purrr::map_dfr(station_files, function(fpath) {
  station_id <- basename(fpath) %>% str_remove("\\.csv$")
  
  wx <- prepare_ghcn_station(fpath)
  
  compute_sap_bounds(
    weather_data  = wx,
    station_id    = station_id,
    tmin_freeze   = 32,
    tmax_min      = 33,
    tmax_max      = 55,
    run_window    = 4,
    min_run_len   = 3
  )
})

# join metadata
sap_wide <- all_sap %>%
  left_join(
    stations_meta %>%
      select(station_id, LAT, LON, ELEV, STATE, name, station_name),
    by = "station_id"
  )

# =====================================================================
# 5) Prep for visualizations
# =====================================================================

sap_long <- sap_wide %>%
  mutate(
    FSW_doy = yday(FSW),
    LSW_doy = yday(LSW)
  ) %>%
  filter(!is.na(FSW_doy) | !is.na(LSW_doy)) %>%
  select(station_id, station_name, year_sap, FSW_doy, LSW_doy) %>%
  pivot_longer(
    cols      = c(FSW_doy, LSW_doy),
    names_to  = "type",
    values_to = "doy"
  ) %>%
  mutate(
    type = recode(
      type,
      FSW_doy = "First sap day",
      LSW_doy = "Last sap day"
    )
  )

sap_wide <- sap_wide %>%
  mutate(
    FSW_doy = yday(FSW),
    LSW_doy = yday(LSW)
  )


station_spans <- sap_wide %>%
  group_by(station_name) %>%        # or label if that's what you use
  summarise(
    start_year = min(year_sap, na.rm = TRUE),
    end_year   = max(year_sap, na.rm = TRUE),
    .groups    = "drop"
  ) %>%
  mutate(
    station_label = glue("{station_name} [{start_year}–{end_year}]")
  )

sap_wide <- sap_wide %>%
  left_join(station_spans, by = "station_name")

sap_long <- sap_long %>%
  left_join(station_spans, by = "station_name")

# trend_slopes <- sap_wide %>%
#   group_by(station_name) %>%
#   summarise(
#     station_label = first(station_label),
#     station_name = first(station_name),
#     slope_FSW = coef(lm(FSW_doy ~ year_sap))[2],
#     slope_LSW = coef(lm(LSW_doy ~ year_sap))[2],
#     slope_window = coef(lm(WindowDays ~ year_sap))[2]
#   ) %>%
#   ungroup()

all_sap <- purrr::map_dfr(station_files, function(fpath) {
  station_id <- basename(fpath) %>% str_remove("\\.csv$")
  
  wx <- prepare_ghcn_station(fpath)
  
  compute_sap_bounds(
    weather_data  = wx,
    station_id    = station_id,
    tmin_freeze   = 32,
    tmax_min      = 33,
    tmax_max      = 55,
    run_window    = 4,
    min_run_len   = 3
  )
})

sap_wide <- all_sap %>%
  left_join(
    stations_meta %>%
      select(station_id, LAT, LON, ELEV, STATE, name, station_name),
    by = "station_id"
  )

sap_region <- sap_wide %>%
  group_by(year_sap) %>%
  summarise(
    mean_FSW         = mean(yday(FSW), na.rm = TRUE),
    mean_LSW         = mean(yday(LSW), na.rm = TRUE),
    mean_window      = mean(WindowDays, na.rm = TRUE),
    mean_sap_index   = mean(sap_days_index, na.rm = TRUE),
    .groups = "drop"
  )

sap_wide <- sap_wide %>%
  mutate(
    FSW_doy = yday(FSW),
    LSW_doy = yday(LSW)
  )


sap_region_roll <- sap_region %>%
  arrange(year_sap) %>%
  mutate(
    mean_FSW_roll10 = rollmean(mean_FSW, k = 10,
                               fill = NA, align = "right")
  )



# =====================================================================
# 6) Optional: save results
# =====================================================================

readr::write_csv(sap_wide, "results/all_stations_sap_bounds.csv")
