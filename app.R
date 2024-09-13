library(shiny)
library(bslib)
library(tidyverse)
library(readxl)
library(writexl)

# Define UI----
ui <- page_fillable(

    # Application title
    titlePanel("Combine temperature probe data"),
    
    
    # Value box for file upload
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
    
    # Value box for timing interval
    value_box(
      title = "What was your reading interval?",
      value = numericInput(
        "interval",
        label = h6("Enter in seconds. Must have same interval for all probes used"),
        value = 0
      )
    )
    
    
    
    

)

# Define server logic----
server <- function(input, output) {
  # Output for showing files uploaded
  output$files <- renderTable({
    req(input$upload)
    data.frame(
      "File Name" = input$upload$name,
      "File Size" = sapply(input$upload$size, function(size) {
        format(size, units = "auto", standard = "SI")
      })
    )
  })jnjkn
  

  
  
  
  
  
  

}

# Run the application 
shinyApp(ui = ui, server = server)
