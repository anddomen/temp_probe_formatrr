# This is the initial code to clean up and glue together the temp probe data. 
# Thoeretically this will turn into the shiny app at some point

# load libraries ----
library(tidyverse)
library(readxl)
library(writexl)



# custom function to edit data ----
  # does all the renaming and cleaning to prepare for rbind()
  # all upladed data needs to go through this
import_edit <- function(path, interval){
  # import, chop off the trailing columns that are empty, and remove blank NAs
  raw.import <- read_xlsx(path, sheet = 2)[1:5] |> 
    drop_na() 
    
  # take the name of the first column (user inputted name at time of setup)
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
}



# for loop time ----
# point the for loop at a file with the excel files of the temp probes

# set wd to the file where the data are
setwd("Data/")
base_dir <- getwd()

# define the files for both their names and how many of them there are for the for loop
files <- dir(pattern = "*.xlsx")


# use i = 1 for testing
# i = 1


for (i in 1:length(files)) {
  # run all the files through the import_edit to clean them all up
  df.probe_data <- import_edit(paste0(base_dir, "/", files[i]), interval = 30)
  
  # take the first iteration and make it the "master" that the others are then added on to
  if (i == 1) {
    df.master <- df.probe_data
    next
  }
  
  # take the master dataframe and glue the rest of the iterations onto it
  df.master <- full_join(df.master, df.probe_data)
}

write_csv(df.master, file = "")


