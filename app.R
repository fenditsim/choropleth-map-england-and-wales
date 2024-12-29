library(shiny)
library(leaflet)
library(sf)
library(dplyr)
library(shinycssloaders)

# Import data
local.authorities <- read.csv("Local_Authority_District_to_Region_(December_2023)_Lookup_in_England.csv", header = T) %>% select(c(LAD23NM, RGN23NM))  # local authority with its regions
regions <- sort(unique(local.authorities$RGN23NM))  # List the regions in England in alphabetical order
load(file = "shapefiles.RData") # Load simplified shapefiles

# Shiny page
shinyApp(
  # ui
  ui = navbarPage(
    title = "Choropleth Map for England & Wales",
    tags$head(
      tags$style(HTML("
            code {
                display:block;
                padding:9.5px;
                margin:0 0 10px;
                margin-top:10px;
                font-size:13px;
                line-height:20px;
                word-break:break-all;
                word-wrap:break-word;
                white-space:pre-wrap;
                background-color:#F5F5F5;
                border:1px solid rgba(0,0,0,0.15);
                border-radius:4px; 
                font-family:monospace;
            }"))),
    # Info tab
    tabPanel(title = "Info",
             h3("Welcome!"),
             p("In this Shiny page, you can download shapefiles for each region in England and Wales."),
             p("Shapefile data (May 2024) and Local Authority District to Region (December 2023) were downloaded from data.gov.uk."),
             p("Head over to Map tab, select a region in England and Wales (e.g., London) and download the corresponding shapefiles (as .zip file)!"),
             p("Also, you can hover/click on each polygon (with the name of corresponding Local Authority) in the choropleth map."), 
             p("Inside the zip file, there are four files with extensions (.shp, .shx, .dbf and .prj). Store all these files in a directory and create corresponding choropleth map with ", a(href = "https://r-spatial.github.io/sf/", "sf"), " and ", a(href = "https://rstudio.github.io/leaflet/articles/leaflet.html", "leaflet"),   " packages in R."),
             p("Have a look at the following example code of creating a choropleth map with shapefiles of London (shapefile_London.shp):"),
             code("# Load packages\nlibrary(sf)\nlibrary(leaflet)\n\n# Import data\nsf <- read_sf('shapefile_London.shp')\n\n# Draw the map\nleaflet(sf) %>% addPolygons(data=sf$geometry, color = 'purple', fillOpacity = 0.6, smoothFactor = 0.5, label = sf$LAD24NM)"), 
             br(),
             h3("Remarks"),
             p("This Shiny page, which uses relevant materials of digital boundary products supplied under the Open Government Licence, provide the following copyright statements:"),
             p("Sources: Office for National Statistics licensed under the Open Government Licence v.3.0"),
             p("Contains OS data © Crown copyright and database right [2024]"),
             br(),
             p("© 2024", a(href = "https://github.com/fenditsim", "Fendi Tsim")," | Built with ", a(href = "https://shiny.posit.co/", "Shiny"))
             ),
    # Map tab
    tabPanel(title = "Map",
             fluidRow(
               column(width = 10, 
                      tags$table(
                        tags$tr(width = "100%",
                                tags$td(width = "60%", p("Choosing a particular region in England and Wales")),
                                tags$td(width = "40%", selectInput(inputId = "region", label = NULL, choices = c("United Kingdom", regions), selected = "United Kingdom"))
                                )
                        )
                      ),
               column(width = 2, downloadButton("download", "Download the shapefile", style = "color: #fff; background-color: #32cd32"))
               ),
             br(),
             fluidRow(
               withSpinner(
                 leafletOutput(outputId = "map", height = 800)
                 )
               )
             ),
    # Log tab
    tabPanel(title = "Log",
             h3("Version Log"),
             h4("0.2.5 - 2024.12.29"),
             tags$div(
               tags$ul(
                 tags$li("Added Spinner on the plot area via ", a(href = "https://github.com/daattali/shinycssloaders", "shinycssloaders"), " package."),
               )
             ),
             h4("0.2 - 2024.12.27"),
             tags$div(
               tags$ul(
                 tags$li("Initial commit."),
                 tags$li("Published this site as a Github page via ", a(href = "https://github.com/RamiKrispin/shinylive-r", "Shinylive"), " package.")
               )
             ),
             h4("0.1.5 - 2024.12.25"),
             tags$div(
               tags$ul(
                 tags$li("Modified Map tab layout."),
                 tags$li("Fixed download situation."),
               )
             ),
             h4("0.1 - 2024.11.27"),
             tags$div(
               tags$ul(
                 tags$li("Initial structure complete."),
                 tags$li("Shrink the size of polygons."),
                 )
               )
             
             )
    ),
  
  # server
  server = function(input, output){
    # Create an reactive object for selected region
    local.authority <- reactive({
      character <- if (input$region != "United Kingdom") local.authorities %>% filter(RGN23NM==input$region) else local.authorities
      character <- as.character(unlist(character %>% select(LAD23NM)))
      return(character)
    })
    
    # Generate shapefile based on selected region
    sf <- reactive({
      req(local.authority())
      shapefile <- if (input$region!="United Kingdom") shapefiles %>% filter(LAD24NM %in% local.authority()) else shapefiles
      shapefile <- shapefile %>% select(-LAD24NMW)  # Remove unnecessary column
      return(shapefile)
    })
    
    # Create the choropleth map based on generated shapefile
    output$map <- renderLeaflet({
      Sys.sleep(1)
      leaflet(sf()) %>%
        addPolygons(data=sf()$geometry, color = "purple", fillOpacity = 0.6, smoothFactor = 0.5, label = sf()$LAD24NM)
    })
    
    # Download the generated shapefile
    output$download <- downloadHandler(
      filename = function() {
        paste0("shapefile_", input$region, ".zip")  # Name the zip file
      },
      content = function(file) {
        # Create a temporary directory to store exported shapefiles
        temp_directory <- file.path(tempdir(), as.integer(Sys.time()))
        dir.create(temp_directory)
        
        sf::st_write(sf(), file.path(temp_directory, paste0("shapefile_", input$region, ".shp"))) # Export generated shapefiles to temp_directory
        zip::zip(zipfile = file, files = dir(temp_directory), root = temp_directory)  # Zip all generated shapefiles in temp_directory
      },
      contentType = "application/zip"
    )
  }
)
