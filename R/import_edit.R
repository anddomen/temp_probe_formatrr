# load libraries ----
library(tidyverse)
library(readxl)
library(writexl)


# custom function to edit data ----
# does all the renaming and cleaning

import_edit <- function(path) {
  # Import only necessary columns initially and remove 'Serial Number' column
  raw.import <- read_xlsx(path, sheet = 2) |>
    select(-`Serial Number`) |>
    select(1:5)

  # Determine if it is a probe with humidity by checking the 4th column
  is_humidity_probe <- colnames(raw.import)[4] == 'Humidity(%rh)'

  # Slice the data based on the type of probe
  raw.import <- if (is_humidity_probe) raw.import[1:5] else raw.import[1:3]

  # Extract probe name from the first column
  probe_name <- colnames(raw.import)[1]

  # Add the probe name and remove NAs
  df.add_probe <- raw.import |>
    mutate(Probe_name = probe_name) |>
    select(-1) |>
    relocate(Probe_name) |>
    drop_na()

  # Rename columns appropriately
  if (is_humidity_probe) {
    df.add_probe <- df.add_probe |>
      rename_with(~c("Probe_name", "Time", "Temp_C", "Humidity_percent", "Dew_pt_C"))
  } else {
    df.add_probe <- df.add_probe |>
      rename_with(~c("Probe_name", "Time", "Temp_C"))
  }
  
  # Add the starting time in it's own column and calculate the interval
  df.add_min_Time <- df.add_probe |> 
    mutate(min_Time = min(Time),
           interval = as.numeric(difftime(Time[2], Time[1], units = "secs")))

  # Return the processed dataframe
  return(df.add_min_Time)
}
