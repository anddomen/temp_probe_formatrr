library(shiny)
library(bslib)
library(tidyverse)
library(readxl)
library(writexl)

# Define UI----
ui <- page_fillable(
  # Page theme ----
  theme = bs_theme(bootswatch = "lux"),

    # Application title
    titlePanel("Combine temperature probe data"),
    
    
    # Value box for file upload----
    # only accepts .xlsx files and allows for multiple uploads
    value_box(
      title = "Upload your temperature data here",
      value = fileInput(
        "upload",
        label = h6("Highlight multiple files to upload"),
        multiple = TRUE,
        accept = ".xlsx"
      ),
      tableOutput("files")
    ),
    
    # Value box for timing interval----
    value_box(
      title = "What was your reading interval?",
      value = numericInput(
        "interval",
        label = h6("Enter in seconds. Must have same interval for all probes used"),
        value = NULL
      )
    ),
    
    # # Value box for download----
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
      theme = value_box_theme(bg = "#D8E7DE", fg = "#45644A" )
    ),
    
     # output: data changing table----
      # remove when done testing
    card(
      tableOutput("contents")
    )
    
    
    

)

# Define server logic----
server <- function(input, output) {
  # Output for showing files uploaded
  output$files <- renderTable({
    req(input$upload)
    data.frame(
      "Name" = input$upload$name,
      "Size" = sapply(input$upload$size, function(size) {
        format(size, units = "auto", standard = "SI")
      })
    )
  })
  
  combinedData <- reactive({
    # require files are uploaded and an interval is present
    req(input$upload)
    req(input$interval)
    
    # make an empty list to store each file's data
    file_list <- lapply(input$upload$datapath, 
                        function(file) import_edit(file, input$interval))
    
    combined_df <- bind_rows(file_list)
    
    return(combined_df)
  })
  
  

  
  # Render real time preview of data
  output$contents <- renderTable(
    head(combinedData(), n = 10)
    
  )
  

  
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
