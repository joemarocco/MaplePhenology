# Climate & Maple Phenology in Northern NY and VT  
**Author:** Joe Marocco  
**Status:** In Progress | 2025

## Project Overview

This project explores whether the timing of maple sap flow in northern New York and Vermont has shifted over the past century. Sap flow depends on freeze–thaw temperature cycles, and changes in winter climate may influence when the sugaring season begins, ends, and how long it lasts.

Using NOAA Global Historical Climatology Network (GHCN Daily) records from seven long-term stations, I reconstructed:

- First sap-favorable day  
- Last sap-favorable day  
- Sap-window length (days between first and last sap days)  
- Sap-favorable day index (total freeze–thaw days, Feb–Apr)

I expected climate warming to compress the sap window. Surprisingly, the long-term trends were small and not statistically significant.

## Motivation

Maple sugaring has deep cultural and personal meaning in the region where I live. I wanted to understand whether long-term weather records support the idea that sap season is shifting due to climate change. This project also served as a hands-on data analysis and R programming exercise.

## Repository Structure

```
├── RawData/              # Raw GHCN station CSV files and metadata
├── Scripts/              # R scripts for cleaning and analysis
├── Results/              # Exported plots and summary tables
├── Results/Visuals       # Exported .png visuals
├── MaplePhenology.R      # Main analysis script
├── MaplePhenologyVisuals.R     # Visuals script
└── README.md             # Project overview (this file)
```

## Data Sources

All climate data was downloaded from the NOAA Global Historical Climatology Network (GHCN Daily):

https://www.ncei.noaa.gov/products/land-based-station/global-historical-climatology-network-daily

Stations used in this analysis:

- Colebrook, NH  
- Hanover, NH  
- Newport, VT  
- Enosburg Falls, VT  
- Lake Placid, NY  
- Tupper Lake, NY  
- Dannemora, NY  

These sites have long and relatively complete temperature records suitable for century-scale analysis. They also reside in approximately the same latitudes.

## Methods

1. Download daily NOAA data for each station.  
2. Clean and reshape the raw data into a daily temperature table.  
3. Convert GHCN temperature units (tentths of °C) into °F.  
4. Identify “sap-favorable” freeze–thaw days:
   - Tmin ≤ 32°F  
   - Tmax between 33°F and 55°F  
5. Use a rolling 4-day window to determine the first sustained sap period, then the last sap day.  
6. Compute yearly metrics for each station.  
7. Visualize long-term trends with ggplot2.  
8. Fit simple linear models and run Mann–Kendall trend tests to evaluate statistical significance.

The entire workflow is implemented in `MaplePhenology.R`.

## Key Findings

Across all stations and metrics, long-term trends were **small and not statistically significant**.

**Summary:**

- First sap-favorable day: slight tendency toward earlier dates, not significant.  
- Last sap-favorable day: slight tendency toward later dates, not significant.  
- Sap-window length: weak tendency to lengthen, not significant.  
- Sap-favorable day index: effectively flat (no trend).

Although year-to-year variability is large, the overall sap season in this region appears to have been **remarkably stable** over the instrumental climate record.

## Visualizations

The `/Results/Visuals` folder contains:

- Trends in first sap day  
- Trends in last sap day  
- Sap-window length over time  
- Sap-favorable day index  
- Rolling 10-year averages  
- Station-level comparisons  

Plots were generated using ggplot2.

## Skills Demonstrated

- Data wrangling with tidyverse  
- Working with large climate datasets  
- Defining and computing environmental metrics  
- Rolling window operations (slider)  
- ggplot2 time-series visualization  
- Trend analysis (OLS, Mann–Kendall)  
- Reproducible R scripting  
- Project organization and documentation  

## Future Work

- Experiment with alternate freeze–thaw thresholds  
- Integrate maple syrup production records  

## Contact

If you have suggestions or want to discuss the project, feel free to open an issue or reach out.
# MaplePhenology
