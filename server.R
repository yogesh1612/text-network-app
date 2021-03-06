#################################################
#     Text Network App    #
#################################################

shinyServer(function(input, output,session) {
  library("shiny")
  library("igraph")
  library("tm")  
  #---------------------------------------------
  
  # sample dataset
  
  output$dwnld <- downloadHandler(
    filename = function() { "B2C_brands_pgp21.csv" },
    content = function(file) {
      write.csv(read.csv("data/B2C brands pgp21.csv"), file,row.names = FALSE)
    }
  )
  
  text.clean1 = function(x)                          # text data
  { 
    # x = gsub("[^[:alnum:]['-][\\s]", "-", x)        # replace intra-word space with dash
    x  =  gsub("<.*?>", " ", x)                  # regex for removing HTML tags
    x  =  iconv(x, "latin1", "ASCII", sub=" ")   # Keep only ASCII characters
    x  =  gsub("[^[:alnum:]['-]", " ", x)       # keep apostrophe 
    x  =  tolower(x)                          # convert to lower case characters
    x  =  removeNumbers(x)                    # removing numbers
    x  =  stripWhitespace(x)                  # removing white space
    x  =  gsub("^\\s+|\\s+$", " ", x)          # remove leading and trailing white space
    return(x)
  }
  
  plot.one.mode <- function(mat, network.name, cutoff,cex,cex2){
    
    mat.network = mat %*% t(mat)
    
    mat.network[upper.tri(mat.network, diag = T)] = NA
    
    s = quantile(setdiff(as.vector(mat.network*lower.tri(mat.network)),NA),cutoff)
    mat.network[is.na(mat.network)] = 0
    
    mat.adj = mat.network
    mat.adj[mat.adj < s] = 0
    mat.adj[mat.adj > 0] = 1
    
    
    graph1e = graph.adjacency(mat.adj, mode = "undirected")
    
    E(graph1e)$weight <- count.multiple(graph1e)
    graph1e <- simplify(graph1e)
    
    # Set vertex attributes
    V(graph1e)$label = V(graph1e)$name
    V(graph1e)$label.color = rgb(0,0,.2,.8)
    V(graph1e)$label.cex = cex
    V(graph1e)$size = cex2
    V(graph1e)$frame.color = NA
    V(graph1e)$color = rgb(0,0,1,.5)
    
    # Set edge gamma according to edge weight
    egam = (log(E(graph1e)$weight)+.3)/max(log(E(graph1e)$weight)+.3)
    E(graph1e)$color = rgb(.5,.5,0,egam)
    
    plot(graph1e, main = network.name, layout=layout.kamada.kawai)
    # plot(graph1e, main = "layout.fruchterman.reingold", layout=layout.fruchterman.reingold)
  }
  
  
  distill.cog <- function(dtm1, s, k1, network.name,cex,cex2){
    # s = 5  # no. of seed nodes
    # k1 = 7   # max no. of connections
    # n1 = 100 # restrict to the top n1 words
    
    mat = as.matrix((dtm1))  # input dtm here
    mat1 = mat %*% t(mat)    # build 1 mode term term matrix
    
    a = colSums(mat1)  # collect colsums into a vector obj a
    b = order(-a)     # nice syntax for ordering vector in decr order  
    mat2 = mat1[b,b]  # 
    diag(mat2) =  0
    
    ## +++ go row by row and find top k adjacencies +++ ##
    
    wc = NULL
    for (i1 in 1:s){ 
      thresh1 = mat2[i1,][order(-mat2[i1, ])[k1]]
      mat2[i1, mat2[i1,] < thresh1] = 0   # wow. didn't need 2 use () in the subset here.
      mat2[i1, mat2[i1,] > 0 ] = 1
      word = names(mat2[i1, mat2[i1,] > 0])
      mat2[(i1+1):nrow(mat2), match(word,colnames(mat2))] = 0
      wc = c(wc,word)
    } # i1 loop ends
    mat3 = mat2[match(wc, colnames(mat2)), match(wc, colnames(mat2))]
    ord = colnames(mat2)[which(!is.na(match(colnames(mat2), colnames(mat3))))]  # removed any NAs from the list
    mat4 = mat3[match(ord, colnames(mat3)), match(ord, colnames(mat3))]
    
    graph <- graph.adjacency(mat4, mode = "undirected", weighted=T)    # Create Network object
    graph = simplify(graph)  
    
    V(graph)$color[1:s] = "darkgoldenrod2"
    V(graph)$color[s+1:length(V(graph))] = adjustcolor("cyan3", alpha.f = 0.7)
    plot(graph,
         vertex.label.cex = cex, 
         vertex.label.color='black',		#the color of the name labels
         vertex.size = cex2,     # size of the vertex
         main = network.name, 
         layout=layout.kamada.kawai)
  } # func ends
  #---------------------------------------------
  
  Dataset <- reactive({
    if (is.null(input$file)) { return(NULL) }
    else{
      Dataset <- read.csv(input$file$datapath ,header=TRUE, sep = ",", stringsAsFactors = F)
      Dataset[,1] <- str_to_title(Dataset[,1])
      Dataset[,1] <- make.names(Dataset[,1], unique=TRUE)
      Dataset[,1] <- tolower(Dataset[,1])
      Dataset[,1] <- str_replace_all(Dataset[,1],"\\.","_")
      rownames(Dataset) <- Dataset[,1]
      
      
      rownames(Dataset) <- make.names(Dataset[,1], unique=TRUE)
      
      colnames(Dataset) <- make.names(colnames(Dataset),unique=TRUE)
#      row.names(Dataset) = Dataset[,1]
#      Dataset = Dataset[,2:ncol(Dataset)]
      return(Dataset)
    }
  })
  #---------------------------------------------  
    dtm = reactive({
      
      stp_word1 = stopwords('en')
      stp_word2 = readLines("data/stopwords.txt")
      comn  = unique(c(stp_word1, stp_word2))
      stp_word = unique(c(gsub("'","",comn),comn))
      sto = unique(c(stp_word)) #,unlist(strsplit(input$stopw,","))
      
      text = text.clean1(Dataset()[,2])
      myCorpus = tm_map(Corpus(VectorSource(text)), removeWords,c(sto))
      # myCorpus = tm_map(myCorpus, stripWhitespace)   # removes white space
      # myCorpus = as.character(unlist(myCorpus))
      # x1 = myCorpus
      # 
      # ngram <- function(x1) NGramTokenizer(x1, Weka_control(min = 2, max = 2))  
      # 
      # tdm0 <- TermDocumentMatrix(x1, control = list(tokenize = ngram,
      #                                               tolower = TRUE, 
      #                                               removePunctuation = TRUE,
      #                                               removeNumbers = TRUE,
      #                                               stopwords = TRUE ))
      # tdm = tdm0; rm('tdm0')
      # a1 = apply(tdm, 1, sum)  
      # a2 = ((a1 > 3))
      # tdm.new = tdm[a2, ]
      # rm('a1','a2','tdm')
      # 
      # dim(tdm.new)    # reduced tdm
      # x1mat = t(tdm.new)    # don't do tfidf, not mentioned anywhere for topic modeling.
      # dim(x1mat);    # store[i1, 5] = ncol(x2mat);
      # 
      # test = colnames(x1mat); 
      # test1 = gsub(" ",".", test);  # replace spaces with dots
      # colnames(x1mat) = test1
      # 
      # a11 = apply(x1mat, 2, sum)
      # a12 = order(a11, decreasing = T)
      # a13 = as.matrix(a11[a12])
      # 
      # #x1 = tm_map(x1, stripWhitespace)
      # x1 = unlist(lapply(x1, content)) 
      # for (i in 1:nrow(a13)){    
      #   focal.term = gsub("\\.", " ", rownames(a13)[i])
      #   replacement.term = gsub(" ", "-", focal.term)
      #   replacement.term=paste("",replacement.term,"")
      #   x1 = gsub(focal.term, replacement.term, x1)  
      #   
      # }	# now, our x corpus has the top 400 bigrams encoded as unigrams
      
      # progress$set(message = 'TDM creation in progress',
      #              detail = 'This may take a while...')
      # progress$set(value = 4)

      # x1 = Corpus(VectorSource(x1))    # Constructs a source for a vector as input
      tdm = TermDocumentMatrix(myCorpus)
      
      #tdm = TermDocumentMatrix(t) 
      
      Brands_DTM <- t(as.matrix(tdm))
      
      rownames(Brands_DTM) <- Dataset()[,1]
      return(Brands_DTM)
      })
    #---------------------------------------------  
    
    dtm1 <- reactive({
      
      
      dtm1 = dtm()[order(rowSums(dtm()),decreasing = T),]
      if (input$npoint > nrow(dtm1)){
        n = nrow(dtm1)
      } else {
        n = input$npoint
      }
      
      dtm1 = dtm1[1:n,]
      return(dtm1)
      })
    #-------------------------------------------
    dtm2 <- reactive({
      
      
      dtm2 = dtm()[,order(colSums(dtm()),decreasing = T)]
      if (input$npoint > ncol(dtm2)){
        n = ncol(dtm2)
      } else {
        n = input$npoint
      }
      
      dtm2 = dtm2[,1:n]
      return(dtm2)
    })
    #-------------------------------------------
  # output$graph1 <- renderPlot({
   # if (is.null(input$file)) { return(NULL) }
   # else{
  # plot.one.mode(dtm1(), "Doc-Doc", input$cutoff,input$cex,input$cex2)
  #  }
  # })
  
 # output$graph2 <- renderPlot({
  #  if (is.null(input$file)) { return(NULL) }
  #  else{
 # plot.one.mode(t(dtm2()), "Term-Term",input$cutoff,input$cex,input$cex2)
 #   }
 # })
  
  output$graph3 <- renderVisNetwork({
    if (is.null(input$file)) { return(NULL) }
    else{
      distill.cog.tcm(t(dtm()),mattype = "DTM", k=input$nodes, s=input$connection, title="Doc-Doc",cex=input$cex,cex2 = input$cex2)#,input$cex2)
    }
  })
  
  
  
  
  output$graph4 <- renderVisNetwork({ if (is.null(input$file)) { return(NULL) }
    else{
  #distill.cog(t(dtm()),input$nodes, input$connection, "Term-Term",input$cex,input$cex2)
      distill.cog.tcm(dtm(),mattype = "DTM", k=input$nodes, s=input$connection, title="Term-Term",cex=input$cex,cex2 = input$cex2)
    }
  })
  
  
  
  
  
  dtm_to_download <- reactive({
    if (is.null(input$file)) { return(NULL)}
      
      else{
        namesList = as.character(read.csv(input$file$datapath)[,1])
        l1 = duplicated(namesList)
        l2 = seq(1:sum(l1))
       # print(l2)
        namesList_new = paste0(namesList[l1],l2)
        namesList[l1] = namesList_new
        
        data =  as.data.frame(dtm())# select Loyal_Brands_DTM.csv file
        rownames(data) = namesList  # Assign row names
        data = as.data.frame(unique(data))
  }})
  
  
  doc_doc_mat <- reactive({
                if (is.null(input$file)) { return(NULL)}
    else{
      mat = as.matrix((dtm()))  # input dtm here
      mat1 = mat %*% t(mat)    # build 1 mode term term matrix
      
      a = colSums(mat1)  # collect colsums into a vector obj a
      b = order(-a)     # nice syntax for ordering vector in decr order  
      mat2 = mat1[b,b]  # 
      diag(mat2) =  0
      return(mat2)
    }
    
  })
  
  
  term_term_mat<- reactive({
                  if (is.null(input$file)) { return(NULL)}
                  else{
                    mat = as.matrix((t(dtm())))  # input dtm here
                    mat1 = mat %*% t(mat)    # build 1 mode term term matrix
                    
                    a = colSums(mat1)  # collect colsums into a vector obj a
                    b = order(-a)     # nice syntax for ordering vector in decr order  
                    mat2 = mat1[b,b]  # 
                    mat3 = mat2[1:200,1:200]
                    diag(mat3) =  0
                    return(mat3)
                  }
  })
  
  output$downloadData2 <- downloadHandler(
    filename = function() { paste(str_split(input$file$name,"\\.")[[1]][1],"_doc_doc_mat.csv",collapse = "") },
    content = function(file) {
      print(2)
      write.csv(doc_doc_mat(), file, row.names=T)
      
      
    }
  )
  
  
  output$downloadData3 <- downloadHandler(
    filename = function() { paste(str_split(input$file$name,"\\.")[[1]][1],"_term_term_mat.csv",collapse = "")},
    content = function(file) {
      print(2)
      write.csv(term_term_mat(), file, row.names=T)
      
      
    }
  )
  
  output$dtm <- renderTable({if (is.null(input$file)) { return(NULL)}
    
                      else{
                       return(head(dtm_to_download()[,1:10],n = 10))
                  }
                  
                  
                },rownames = TRUE,digits = 0)
  
  
  output$doc_doc <- renderTable({if (is.null(input$file)) { return(NULL)}
    
    else{
      return(head(doc_doc_mat()[,1:10],n = 10))
    }
    
    
  },rownames = TRUE,digits = 0)
  
  
  output$term_term <- renderTable({if (is.null(input$file)) { return(NULL)}
    
    else{
      return(head(term_term_mat()[,1:10],n = 10))
    }
    
    
  },rownames = TRUE,digits = 0)
  
  
  
  
  output$downloadData1 <- downloadHandler(
    filename = function() { paste(str_split(input$file$name,"\\.")[[1]][1],"_dtm_to_network.csv",collapse = "") },
    content = function(file) {
      
      
        new_dtm <- dtm_to_download()[1:1000,1:500]
        print(2)
        write.csv(new_dtm, file, row.names=T)
      
      
    }
  )
  
  
  bi_graph_df <- reactive({ if (is.null(input$file)) { return(NULL) }
    else{
      namesList = as.character(read.csv(input$file$datapath)[,1])
      l1 = duplicated(namesList)
      l2 = seq(1:sum(l1))
      #print(l2)
      namesList_new = paste0(namesList[l1],l2)
      namesList[l1] = namesList_new
      
      data =  as.data.frame(dtm())# select Loyal_Brands_DTM.csv file
      rownames(data) = namesList  # Assign row names
      data = as.data.frame(unique(data))
      co2015 = data # # define network data
      co2015 <- co2015[1:input$npoint,]
      return(co2015)
    }
    })

  output$interactive_slider <- renderUI({if (is.null(input$file)) { return(NULL) }
                              else{
                                
                                max_slider = sort(colSums(bi_graph_df()),decreasing = TRUE)[[2]]
                                sliderInput("cutoff", "Filter all brands selected by atleast following no of users", 
                                        min = 1,
                                        max = max_slider-1,
                                        value = floor(max_slider/2),
                                        step = 1)}})
  
  output$graph5 <- renderVisNetwork({ if (is.null(input$file)) { return(NULL) }
    else{
      require(igraph)
      co2015 <- bi_graph_df()
      group=rownames(co2015)
      # remove columns with sum less than 5
      co2015 = co2015[,colSums(co2015)>input$cutoff]
      co2015 = co2015[sum(co2015)>0,]
      #print(dim(co2015))
      rownums = nrow(co2015); colnums = ncol(co2015)
      graph1 = graph.incidence(co2015, mode=c("all") ) # create two mode network object
      V(graph1)   # Print Vertices. Based on vertices order change the color scheme in next line of code
      
      V(graph1)$color[1:rownums] = "pink"   # Color scheme for fist mode of vertices
      V(graph1)$color[(rownums+1):(rownums+colnums)] = "green" # Color Scheme for second mode of vertices
      
      
      # V(graph1)$shape[1:rownums] = 10
      # V(graph1)$shape[(rownums+1):(rownums+colnums)] = 50
      
      # V(graph1)$shape[1:rownums] = "triangle"
      # V(graph1)$color[(rownums+1):(rownums+colnums)] = "circle"
      
      V(graph1)$label = V(graph1)$name     # made some crap changes
      #V(graph1)$label.color = rgb(0.2,0.2,.9,1)
      V(graph1)$label.cex = .8
      #V(graph1)$size = 50
      V(graph1)$frame.color = NA
      E(graph1)$color = "green"
      
      #plot(graph1, layout=layout.fruchterman.reingold)
      visIgraph(graph1, layout = "layout.fruchterman.reingold", idToLabel = FALSE,physics = FALSE)  
      
      
    }
    
    
    
    
    
    
    
  })
    
  })

