# ================================================================
# Maple phenology plots with legends (academic style)
# ================================================================

library(dplyr)
library(ggplot2)
library(lubridate)
library(zoo)

# ------------------------------------------------
# 0) Prep: DOY fields and regional summaries
# ------------------------------------------------

sap_wide <- sap_wide %>%
  mutate(
    FSW_doy = yday(FSW),
    LSW_doy = yday(LSW)
  )

sap_region <- sap_wide %>%
  group_by(year_sap) %>%
  summarise(
    mean_FSW       = mean(FSW_doy,        na.rm = TRUE),
    mean_LSW       = mean(LSW_doy,        na.rm = TRUE),
    mean_window    = mean(WindowDays,     na.rm = TRUE),
    mean_sap_index = mean(sap_days_index, na.rm = TRUE),
    .groups = "drop"
  )

sap_region_roll <- sap_region %>%
  arrange(year_sap) %>%
  mutate(
    mean_FSW_roll10 = rollmean(mean_FSW, k = 10,
                               fill = NA, align = "right")
  )

# ------------------------------------------------
# Reusable "academic" theme
# ------------------------------------------------

theme_maple <- theme_minimal() +
  theme(
    legend.position = "top",
    legend.title    = element_text(size = 10),
    legend.text     = element_text(size = 9),
    axis.title      = element_text(size = 10),
    axis.text       = element_text(size = 9)
  )

theme_maple_facet <- theme_maple +
  theme(
    strip.text = element_text(size = 8)
  )

# ------------------------------------------------
# Figure 1 — First sap-favorable day by year
# ------------------------------------------------

fig1_all <- ggplot() +
  # individual stations
  geom_line(
    data = sap_wide,
    aes(x = year_sap, y = FSW_doy,
        group = station_id,
        color = "Individual stations"),
    alpha = 0.25
  ) +
  # regional mean
  geom_line(
    data = sap_region,
    aes(x = year_sap, y = mean_FSW,
        color = "Regional mean"),
    linewidth = 1
  ) +
  # linear trend
  geom_smooth(
    data = sap_region,
    aes(x = year_sap, y = mean_FSW,
        color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.6
  ) +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Individual stations" = "grey60",
      "Regional mean"       = "black",
      "Linear trend"        = "blue"
    )
  ) +
  labs(
    title = "First sap-favorable day by year",
    x     = "Year",
    y     = "Day of year (first sap day)"
  ) +
  theme_maple

fig1_facets <- ggplot(sap_wide, aes(x = year_sap, y = FSW_doy)) +
  geom_line(aes(color = "Station series")) +
  geom_smooth(
    aes(color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.5
  ) +
  facet_wrap(~ station_name, scales = "free_y") +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Station series" = "black",
      "Linear trend"   = "blue"
    )
  ) +
  labs(
    title = "First sap-favorable day by station",
    x     = "Year",
    y     = "Day of year (first sap day)"
  ) +
  theme_maple_facet

# ------------------------------------------------
# Figure 2 — Last sap-favorable day by year
# ------------------------------------------------

fig2_all <- ggplot() +
  geom_line(
    data = sap_wide,
    aes(x = year_sap, y = LSW_doy,
        group = station_id,
        color = "Individual stations"),
    alpha = 0.25
  ) +
  geom_line(
    data = sap_region,
    aes(x = year_sap, y = mean_LSW,
        color = "Regional mean"),
    linewidth = 1
  ) +
  geom_smooth(
    data = sap_region,
    aes(x = year_sap, y = mean_LSW,
        color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.6
  ) +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Individual stations" = "grey60",
      "Regional mean"       = "black",
      "Linear trend"        = "blue"
    )
  ) +
  labs(
    title = "Last sap-favorable day by year",
    x     = "Year",
    y     = "Day of year (last sap day)"
  ) +
  theme_maple

fig2_facets <- ggplot(sap_wide, aes(x = year_sap, y = LSW_doy)) +
  geom_line(aes(color = "Station series")) +
  geom_smooth(
    aes(color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.5
  ) +
  facet_wrap(~ station_name, scales = "free_y") +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Station series" = "black",
      "Linear trend"   = "blue"
    )
  ) +
  labs(
    title = "Last sap-favorable day by station",
    x     = "Year",
    y     = "Day of year (last sap day)"
  ) +
  theme_maple_facet

# ------------------------------------------------
# Figure 3 — Sap window length by year
# ------------------------------------------------

fig3_all <- ggplot() +
  geom_line(
    data = sap_wide,
    aes(x = year_sap, y = WindowDays,
        group = station_id,
        color = "Individual stations"),
    alpha = 0.25
  ) +
  geom_line(
    data = sap_region,
    aes(x = year_sap, y = mean_window,
        color = "Regional mean"),
    linewidth = 1
  ) +
  geom_smooth(
    data = sap_region,
    aes(x = year_sap, y = mean_window,
        color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.6
  ) +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Individual stations" = "grey60",
      "Regional mean"       = "black",
      "Linear trend"        = "blue"
    )
  ) +
  labs(
    title = "Sap window length by year",
    x     = "Year",
    y     = "Window length (days)"
  ) +
  theme_maple

fig3_facets <- ggplot(sap_wide, aes(x = year_sap, y = WindowDays)) +
  geom_line(aes(color = "Season length")) +
  geom_smooth(
    aes(color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.5
  ) +
  facet_wrap(~ station_name, scales = "free_y") +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Season length" = "black",
      "Linear trend"  = "blue"
    )
  ) +
  labs(
    title = "Sap window length by station",
    x     = "Year",
    y     = "Window length (days)"
  ) +
  theme_maple_facet

# ------------------------------------------------
# Figure 4 — Sap-favorable days index by year
# ------------------------------------------------

fig4_all <- ggplot() +
  geom_line(
    data = sap_wide,
    aes(x = year_sap, y = sap_days_index,
        group = station_id,
        color = "Individual stations"),
    alpha = 0.25
  ) +
  geom_line(
    data = sap_region,
    aes(x = year_sap, y = mean_sap_index,
        color = "Regional mean"),
    linewidth = 1
  ) +
  geom_smooth(
    data = sap_region,
    aes(x = year_sap, y = mean_sap_index,
        color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.6
  ) +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Individual stations" = "grey60",
      "Regional mean"       = "black",
      "Linear trend"        = "blue"
    )
  ) +
  labs(
    title = "Total sap-favorable days per year",
    x     = "Year",
    y     = "Sap-favorable days (Feb–Apr)"
  ) +
  theme_maple

fig4_facets <- ggplot(sap_wide, aes(x = year_sap, y = sap_days_index)) +
  geom_line(aes(color = "Season opportunity")) +
  geom_smooth(
    aes(color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.5
  ) +
  facet_wrap(~ station_name, scales = "free_y") +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Season opportunity" = "black",
      "Linear trend"       = "blue"
    )
  ) +
  labs(
    title = "Sap-favorable days per year by station",
    x     = "Year",
    y     = "Sap-favorable days (Feb–Apr)"
  ) +
  theme_maple_facet

# ------------------------------------------------
# Figure 5 — 10-year rolling mean (first sap day)
# ------------------------------------------------

fig5_roll_FSW <- ggplot(sap_region_roll, aes(x = year_sap)) +
  geom_line(aes(y = mean_FSW, color = "Annual mean"), alpha = 0.4) +
  geom_line(aes(y = mean_FSW_roll10, color = "10-year rolling mean"),
            linewidth = 1) +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Annual mean"        = "grey50",
      "10-year rolling mean" = "black"
    )
  ) +
  labs(
    title = "First sap-favorable day (10-year rolling average)",
    x     = "Year",
    y     = "Day of year (first sap day)"
  ) +
  theme_maple

# ------------------------------------------------
# Figure 6 — Station comparison grid (window length)
# ------------------------------------------------

fig6_station_grid <- ggplot(sap_wide, aes(x = year_sap, y = WindowDays)) +
  geom_line(aes(color = "Season length")) +
  geom_smooth(
    aes(color = "Linear trend"),
    method = "lm", se = FALSE,
    linetype = "dashed", linewidth = 0.5
  ) +
  facet_wrap(~ station_name, scales = "free_y") +
  scale_color_manual(
    name   = "Series",
    values = c(
      "Season length" = "black",
      "Linear trend"  = "blue"
    )
  ) +
  labs(
    title = "Sap season length by station",
    x     = "Year",
    y     = "Window length (days)"
  ) +
  theme_maple_facet


ggsave("results/figures/fig1_first_sap.png", fig1_all, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig1_first_sap_by_station.png", fig1_facets, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig2_last_sap.png", fig2_all, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig2_last_sap_by_station.png", fig2_facets, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig3_window_length.png", fig3_all, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig3_window_length_by_station.png", fig3_facets, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig4_sap_days.png", fig4_all, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig4_sap_days_by_station.png", fig4_facets, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig5_roll_first.png", fig5_roll_FSW, width = 10, height = 6, dpi = 300)
ggsave("results/figures/fig6_station_grid.png", fig6_station_grid, width = 10, height = 7, dpi = 300)

# ggsave("fig1_all_first_sap.png", fig1_all, width = 7, height = 4, dpi = 300)
