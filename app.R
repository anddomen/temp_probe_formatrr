# Load libraries ----
library(shiny)
library(bslib)
library(tidyverse)
library(readxl)
library(writexl)


# Define UI----
ui <- page_fillable(
  # Page theme ----
  theme = bs_theme(bootswatch = "minty"),

    # Application title----
    titlePanel("Combine temperature probe data"),
    
    # Organize upload box, interval box, and download box ----
  layout_column_wrap(
    # Value box for file upload----
    # only accepts .xlsx files and allows for multiple uploads
    value_box(
      title = "Upload your temperature data here",
      value = fileInput(
        "upload",
        label = h6("Highlight multiple files to upload"),
        multiple = TRUE,
        accept = ".xlsx",
      ),
      showcase = bsicons::bs_icon("filetype-xlsx"),
      tableOutput("files"),
      theme = value_box_theme(bg = "#364754", fg = "#FAE2C6"),
      min_height = "200px"
    ),
    
    # Value box for timing interval----
    value_box(
      title = "What was your reading interval?",
      value = numericInput(
        "interval",
        label = h6("Enter in seconds. Must have same interval for all probes used"),
        value = NULL
      ),
        showcase = bsicons::bs_icon("clock"),
      theme = value_box_theme(bg = "#E5BCAF", fg = "#5D6562"),
      min_height = "200px"
    )
  ),
  
  # organize the two data preview cards----
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
        tableOutput("results_table_stats")
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
    req(input$interval)
    
    # make an empty list to store each file's data
    file_list <- lapply(input$upload$datapath, 
                        function(file) 
                          import_edit(file, input$interval))
    
    # glue everything together
    combined_df <- bind_rows(file_list)
    
    return(combined_df)
  })
  
  # File stats box section----
  # Display the number of rows of the combined data
  output$row_count <- renderText({
    format(nrow(combinedData()), big.mark = ",")
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
