####################################################
#      Text Network App    #
####################################################

library("shiny")
library("igraph")
library("tm")
library('visNetwork')
library('stringr')
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
    #sliderInput("cex2", "Vertex Size", min = 0.1,  max = 20, value = 5,round = FALSE),
    
    
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
                tabPanel("Overview & Example Dataset",
                         
                         h4(p("Overview")),
                         p("Network analysis refers to a family of methods that describe relationships between units of analysis. A network is comprised of nodes as well as the edges or connections between them.
                           ", align = "Justify"),
                         
                         p("one can represent a corpus of documents as a network where each node is a document, and the thickness or strength of the edges between them describes similarities between the words used in any two documents. Or, one can create a textnetwork where individual words are the nodes, and the edges between them describe the regularity with which they co-occur in documents."
                           ,align="Justify"),
                         tags$a(href="https://sicss.io/2018/materials/day3-text-analysis/text-networks/rmarkdown/SICSS_Text_Networks.html#:~:text=What%20is%20a%20Text%20Network%3F,-Network%20analysis%20refers&text=For%20example%2C%20one%20can%20represent,used%20in%20any%20two%20documents",
                                "-Source"),
                         hr(),
                         h4(p("How to use this App")),
                         p("", align = "justify"),
                         p("Upload data to sidebar panel it will generate varity of plots. One can adjust sliders for various plot attributes.
                           ", align = "Justify"),
                         h4(p("Input Data Format")),
                         p("Application takes input in following format
                           ", align = "Justify"),
                         img(src = "dataset.png"),
                         hr(),
                         h4(p("Download Sample input file")),
                         # 
                         downloadButton('dwnld', 'Download'),br(),br(),
                        # p("Please note that download will not work with RStudio interface. Download will work only in web-browsers. So open this app in a web-browser and then download the example file. For opening this app in web-browser click on \"Open in Browser\" as shown below -"),
                        # img(src = "example1.png"),
                         #, height = 280, width = 400
                         
                         
                         ),
                tabPanel("Bipartite graph",visNetworkOutput("graph5", height = 800, width = 840)),
                tabPanel("Doc-Doc COG",visNetworkOutput("graph3", height = 800, width = 840),
                         h4("Download Doc-Doc Matrix"),
                         downloadButton('downloadData2', 'Download Doc-Doc Matrix'),h4("Sample Doc-Doc Matrix"),tableOutput('doc_doc')),
                tabPanel("Term-Term COG",
                         visNetworkOutput("graph4", height = 800, width = 840),
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

