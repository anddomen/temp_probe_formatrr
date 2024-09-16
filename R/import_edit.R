# load libraries ----
library(tidyverse)
library(readxl)
library(writexl)


# custom function to edit data ----
# does all the renaming and cleaning

import_edit <- function(path, interval){
  # import, chop off the trailing columns that are empty, and remove blank NAs
  raw.import <- read_xlsx(path, sheet = 2)[1:6] |> 
    select(!'Serial Number')
  
  # after import, need to differentiate between probes that can read %rh and dew pt
  # this is done by checking if the fourth column name of the imported data is humidity
  if (colnames(raw.import)[4] == 'Humidity(%rh)') {
    # take the name of the first column (user inputted name at time of probe setup)
    # remove first column since it's no longer needed
    # remove NAs
    # rename columns to R friendly names
    df.add_probe <- raw.import |> 
      mutate(Probe_name = colnames(raw.import[1])) |> 
      select(!colnames(raw.import[1])) |> 
      relocate(Probe_name) |>
      drop_na() |> 
      rename_with(~c("Probe_name", "Time", "Temp_C", "Humidity_percent", "Dew_pt_C"))
    
    # make a seconds + minutes col
    df.add_time <- df.add_probe |> 
      mutate(Time_sec = seq(0, by = interval, length.out = nrow(df.add_probe))) |> 
      mutate(Time_min = Time_sec/60) |>
      relocate(c("Time_sec", "Time_min"), .after = "Time")
    
    # return the processed df
    return(df.add_time)
  } else {
    # now deal with the probes that only read temp
    raw.import <- read_xlsx(path, sheet = 2)[1:3]
    
    # take the name of the first column (user inputted name at time of probe setup)
    # remove first column since it's no longer needed
    # remove NAs
    # rename columns to R friendly names
    df.add_probe <- raw.import |> 
      mutate(Probe_name = colnames(raw.import[1])) |> 
      select(!colnames(raw.import[1])) |> 
      relocate(Probe_name) |>
      drop_na() |> 
      rename_with(~c("Probe_name", "Time", "Temp_C"))
    
    # make a seconds + minutes col
    df.add_time <- df.add_probe |> 
      mutate(Time_sec = seq(0, by = interval, length.out = nrow(df.add_probe))) |> 
      mutate(Time_min = Time_sec/60) |>
      relocate(c("Time_sec", "Time_min"), .after = "Time")
    
    # return the processed df
    return(df.add_time)
  }
}
