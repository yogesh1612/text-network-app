####################################################
#      Text Network App    #
####################################################

library("shiny")
library("igraph")
library("tm")
#library("foreign")

shinyUI(fluidPage(
  # Header:
  #headerPanel("Text Network App"),
  titlePanel(title=div(img(src="logo.png",align='right'),"Text Network App")),
  # Input in sidepanel:
  sidebarPanel(
    
   # h5(p("Data Input")),
    fileInput("file", "Upload Data"),
    #fileInput("file1", "Upload Demographics data (csv file with header))"),
    # selectInput("mode","Mode of Graph",c("directed", "undirected","max", "min", "upper",
    #                                      "lower", "plus"),"undirected"),
    # htmlOutput("yvarselect"),
    # sliderInput("cex", "Data point labels font size", min = 0.1,  max = 3, value = 1,round = FALSE),
    # sliderInput("cex2", "Vertex Size", min = 0.1,  max = 20, value = 5,round = FALSE),
    
    numericInput("npoint", "Number of max users in graph", 50),
    uiOutput("interactive_slider"),
    #sliderInput("cutoff", " Minimum number of times brand is selected", min = 1,max = 50,value = 5,step = 1),
    sliderInput("cex", "Data point labels font size", min = 0.1,  max = 3, value = 1,round = FALSE),
    sliderInput("cex2", "Vertex Size", min = 0.1,  max = 20, value = 5,round = FALSE),
    
    
    numericInput("nodes", "Number of Central Nodes in COG graph", 4),
    numericInput("connection", "Number of Max Connection with Central Node in COG graph", 5),
    
    br()
  ),
  # Main:
  mainPanel( 
    
    tabsetPanel(type = "tabs",
                
                
                
                #
                # tabPanel("Doc-Doc Network",plotOutput("graph1", height = 800, width = 840)),
                # tabPanel("Term-Term Network",plotOutput("graph2", height = 800, width = 840)),
                
                tabPanel("Bipartite graph",plotOutput("graph5", height = 800, width = 840)),
                tabPanel("Doc-Doc COG",plotOutput("graph3", height = 800, width = 840),
                         h4("Download Doc-Doc Matrix"),
                         downloadButton('downloadData2', 'Download Doc-Doc Matrix'),h4("Sample Doc-Doc Matrix"),tableOutput('doc_doc')),
                tabPanel("Term-Term COG",
                         plotOutput("graph4", height = 800, width = 840),
                         h4("Download Term-Term Matrix (Top 200)"),
                         downloadButton('downloadData3', 'Download Term-Term Matrix'),h4("Sample Term-Term Matrix"),tableOutput('term_term')
                         ),
                tabPanel("Download dataset", h4(p("Download DTM for network an")), 
                downloadButton('downloadData1', 'Download DTM'),h4("Sample DTM"),tableOutput('dtm'))
                # tabPanel("Network Centralities",dataTableOutput("centdata"))
    )
  ) 
) 
)

