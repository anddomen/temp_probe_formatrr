# Load libraries ----
library(shiny)
library(bslib)
library(tidyverse)
library(readxl)
library(writexl)

ui <- page_fillable(
  # Page theme ----
  theme = bs_theme(bootswatch = "minty"),
  
  # Application title----
  titlePanel("Combine temperature probe data"),
  
  # Upload section ----
  value_box(
    title = "Upload your temperature data here",
    value = fileInput(
      "upload",
      label = h6("Highlight multiple files to upload"),
      multiple = TRUE,
      accept = ".xlsx",
    ),
    showcase = bsicons::bs_icon("filetype-xlsx"),
    div(
      style = "max-height: 150px; overflow-y: auto;",
      tableOutput("files")
    ),
    theme = value_box_theme(bg = "#364754", fg = "#FAE2C6"),
    min_height = "200px"
  ),
  
  # File statistics and download section ----
  layout_columns(
    col_widths = c(8, 4),
    
    # Card/value box for displaying the number of rows----
    card(
      card_header("File Statistics"),
      # Total number of rows in the collated file
      # just as a 'gut check' for users
      value_box(
        title = "Number of rows",
        value = textOutput("row_count"),
        showcase = bsicons::bs_icon("table"),
        min_height = "200px",
        theme = value_box_theme(bg = "#96BCA5")
      ),
      # Average/min/max for each probe----
      card(
        card_header("Average, minimum, and maximum temperature per probe"),
        tableOutput("results_table_stats"),
        min_height = "200px"
      ),
      min_height = "200px"
    ),
    
    # Value box for download----
    value_box(
      title = "Download your file",
      value = textInput(
        "filename",
        h6("What do you want your file to be called?"),
        value = "Enter text..."),
      # Download button ----
      downloadButton("downloadData", "Download"),
      showcase = bsicons::bs_icon("box-arrow-down"),
      min_height = "200px",
      theme = value_box_theme(bg = "#DEDAA8", fg = "#746851"),
    )
  ),
  
  # Add graphing box ----
  card(
    card_header("Temperature probe graphs"),
    plotOutput("probePlot")
  )
)


# Define server logic----
server <- function(input, output) {
  # Output for showing files uploaded----
  output$files <- renderTable({
    req(input$upload)
    data.frame(
      "Name" = input$upload$name,
      "Size" = sapply(input$upload$size, function(size) {
        format(size, units = "auto", standard = "SI")
      })
    )
  })

  # Data manipulation----
  combinedData <- reactive({
    # require files are uploaded and an interval is present
    req(input$upload)

    # make an empty list to store each file's data
    file_list <- lapply(input$upload$datapath,
                        function(file)
                          import_edit(file))
    
    # glue everything together and round the time for calculation later
    combined_df_long <- bind_rows(file_list) |>
      mutate(Time_for_calc = floor_date(Time, unit = "minute"),
             min_Time = floor_date(min_Time, unit = "minute"))
    
    # grab the last starting time
    latest_start <- combined_df_long |>
      filter(min_Time == max(min_Time)) |>
      pull(min_Time) |>
      unique()

    # Calculate minutes and hours based off the last started probe
    combined_df <- combined_df_long |>
      mutate(
        Minutes = as.numeric(difftime(Time_for_calc, latest_start, units = "mins")),
        Hours = Minutes/60
      ) |> 
      # Now calculate seconds based off each probe interval and where minutes = 0
      group_by(Probe_name) |> 
      mutate(
        # Find where Minutes >= 0 starts for each probe
        first_positive_row = which(Minutes >= 0)[1],
        
        # Calculate seconds based on position relative to first positive minute
        Seconds = case_when(
          # For rows before Minutes = 0, count backwards
          is.na(first_positive_row) ~ (row_number() - n() - 1) * interval,
          row_number() < first_positive_row ~ (row_number() - first_positive_row) * interval,
          # For rows after Minutes = 0, count forwards from 0
          TRUE ~ (row_number() - first_positive_row) * interval)) |> 
      select(-first_positive_row) |>
      ungroup() |> 
      select(-min_Time, -Time_for_calc, -interval)  # remove extra columns

    return(combined_df)
  })

  # File stats box section----
  # Display the number of rows of the combined data
  output$row_count <- renderText({
    if (is.null(input$upload)) {
      "No files uploaded"
    } else {
      tryCatch({
        format(nrow(combinedData()), big.mark = ",")
      }, error = function(e) {
        "Processing files..."
      })
    }
  })
  

  # display the average, min, and max temp per probe
  output$results_table_stats <- renderTable({
    req(combinedData())

    group_by(combinedData(), Probe_name) |>
      summarize(avg = mean(Temp_C),
                min = min(Temp_C),
                max = max(Temp_C)) |>
      # this is super vain but I don't like that it has an underscore so i'm going to
      # temporarily get rid of it
      rename_with(~c("Probe name", "Average (°C)", "Min temperature (°C)", "Max temperature (°C)"))
  })
  
  ## Plot server side ----
  # make the plot
  probe_plot <- reactive({
    combinedData() |> 
      ggplot(aes(x = Minutes,
                 y = Temp_C,
                 color = Probe_name)) +
      geom_point() +
      theme_classic() +
      labs(y = "Temperature (°C)",
           color = "Probe Name")
  })
  
  # map the plot to the UI
  output$probePlot <- renderPlot({
    probe_plot()
  })


  # Download data server side----
  output$downloadData <- downloadHandler(
    filename = function(){
      paste(input$filename, "_", Sys.Date(), ".xlsx", sep = "")
    },

    content = function(file){
      write_xlsx(combinedData(), file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)