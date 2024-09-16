# load libraries ----
library(tidyverse)
library(readxl)
library(writexl)



# custom function to edit data ----
# does all the renaming and cleaning

import_edit <- function(path, interval){
  # import, chop off the trailing columns that are empty, and remove blank NAs
  raw.import <- read_xlsx(path, sheet = 2)[1:5] |> 
    drop_na() 
  
  # take the name of the first column (user inputted name at time of probe setup)
  # remove first column since it's no longer needed
  # rename columns to R friendly names
  df.add_probe <- raw.import |> 
    mutate(Probe_name = colnames(raw.import[1])) |> 
    select(!colnames(raw.import[1])) |> 
    relocate(Probe_name) |>  
    rename_with(~c("Probe_name", "Time", "Temp_C", "Humidity_percent", "Dew_pt_C"))
  
  # make a seconds + minutes col
  df.add_time <- df.add_probe |> 
    mutate(Time_sec = seq(0, by = interval, length.out = nrow(df.add_probe))) |> 
    mutate(Time_min = Time_sec/60) |> 
    relocate(c("Time_sec", "Time_min"), .after = "Time")
  
  # return the processed df
  return(df.add_time)
}
