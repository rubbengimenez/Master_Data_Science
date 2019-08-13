                                                    ####################
                                                    # APLICACIÓN SHINY #
                                                    ####################
                                                            ####
                                                 # RUBÉN  GIMÉNEZ  MARTÍN #
                                                            ####
                                                    
################# HERRAMIENTAS ###############
#Carga de paquetes
packages = c('shinythemes','shiny','ggplot2','DT','dplyr','plotly')
package.check <- lapply(packages, FUN = function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE)
    library(x, character.only = TRUE)
  }
})

                                                    
                                                    
                                                    
                                                    
# Función para la carga de datos
# Fuente: https://stackoverflow.com/questions/5577221/how-can-i-load-an-object-into-a-variable-name-that-i-specify-from-an-r-data-file
loadRData <- function(fileName){
  #loads an RData file, and returns it
  load(fileName)
  get(ls()[ls() != 'fileName'])
}
###############################################


# Aplicación Shiny

# UI
ui<-navbarPage( "App Master Ciencia de Datos ",
                windowTitle = "Rubén Giménez APP",
                theme = shinytheme("slate"), 
                #Primera pestaña
                tabPanel("Selección de máquina",
                         sidebarLayout(
                           sidebarPanel(
                             titlePanel(h4("MÁQUINA")),
                             fileInput(inputId = "browser", label = "Selecciona un Fichero", buttonLabel = "Buscar", placeholder = "Cargue el fichero"),
                             conditionalPanel(
                               condition = "output.fileUploaded == true",
                               selectInput(inputId = "buttons1",label="Selecciona un fichero",
                                                    choices = " ",
                                                    selected = " "))),
                           mainPanel(
                             h5("Probabilidad de orden"),
                             plotlyOutput(outputId = "probs"))
                         )),
                #Segunda pestaña
                navbarMenu("Estado de la máquina",
                           #Segunda pestaña 2.1
                           tabPanel("Evolución temporal alarmas",
                                    sidebarLayout(
                                      sidebarPanel(
                                        titlePanel(h4("ALARMAS radiobuttons")),
                                        radioButtons(inputId = "radiobuttons1", label = "Selecciona la franja horaria", choices = " ")),
                                      mainPanel(
                                        h5("Evolución temporal Alarmas"),
                                        plotlyOutput(outputId = "evtempAlarmas"))
                                    )),
                           #Segunda pestaña 2.2
                           tabPanel("Registros de las máquinas",
                                    sidebarLayout(
                                      sidebarPanel(
                                        titlePanel(h4("ALARMAS checkbox")),
                                        checkboxGroupInput(inputId = "checkbox1", "Selecciona las alarmas para ver en la tabla",
                                                           choices=" ",inline=FALSE)
                                      ),
                                      mainPanel(
                                        h5("Registros de la máquina seleccionada"),
                                        dataTableOutput(outputId = "tablamaquina"))
                                    ))
                ),
                #Tercera Pestaña
                tabPanel("Estadísticos Globales Temporales",
                         sidebarLayout(
                           sidebarPanel(
                             titlePanel(h4("PERIODO Y ESTADÍSTICAS")),
                            dateRangeInput(inputId = "datestats",label = "Selecciona el periodo",start = "2016-01-02",end = "2016-12-14",min = "2016-01-02", max = "2016-12-14",startview = "year", language = "es", weekstart = 1, separator = "a"),
                             titlePanel(h4("HISTOGRAMA")),
                             selectInput(inputId = "buttons2", label = "Alarma", choices = " ", selected = " "),
                             sliderInput(inputId = "sliderstats",label = "Bins del Histograma",min = 1,max = 50,value = 15),
                             titlePanel(h4("BOXPLOT")),
                             checkboxInput(inputId = "checkbox2",label = "Todas las máquinas", value = FALSE)),
                           mainPanel(
                             h5("Histograma de la alarma seleccionada"),
                             plotlyOutput(outputId = "histogramstats"),
                             h5("Boxplot de la alarma seleccionada:"),
                             plotlyOutput(outputId = "boxplotstats")


                             )
                         )),
                #Cuarta pestaña Datacamp
                tabPanel("DataCamp",
                         h1("Building Web Applications in R with Shiny"),
                         imageOutput(outputId = "certif", width = 200, height = 200))

)

# SERVER
server <- function(input, output, session) {
  
  #Función de carga de los datos
  Datos <- reactive({
    inFile <- input$browser
    if(is.null(inFile)) return(NULL)
    Datos <- loadRData(inFile$datapath)
  })
  
  output$fileUploaded <- reactive({
    return(!is.null(Datos()))
  })
  
  outputOptions(output, "fileUploaded", suspendWhenHidden=FALSE)
  
  
  #Actualización de los inputs con los datos cargados
  observe({
    updateSelectInput(session,inputId = "buttons1" ,choices = unique(Datos()$"matricula"), selected = "00.50.C2.C2.E2.90")
  })
  
  observe({
    updateRadioButtons(session, inputId = "radiobuttons1", choices = colnames(Datos()[,4:48]))
  })
  
  observe({
    updateCheckboxGroupInput(session, inputId = "checkbox1", choices = colnames(Datos()[,4:48]))
  })
  
  observe({
    updateSelectInput(session, inputId = "buttons2", choices = colnames(Datos()[,4:48]), selected = colnames(Datos()[4]))
  })
  
  # Tablas y Gráficos
  
  #Primer grafico
  output$probs <- renderPlotly({
    req(Datos(), input$buttons1)
    aux <- dplyr::filter(Datos(), matricula == input$buttons1)
    req(aux$dia, aux$p_orden)
    print(ggplotly(ggplot(aux, aes(x = dia, y = p_orden))+
             geom_line()+
             geom_point(aes(col = p_orden))+
             scale_colour_gradientn(colours = c("gray21","firebrick"))+
             ggtitle(paste("Probabilidad de Orden de la Matrícula:",input$buttons1))+
             labs(x = "Día" , y = "Probabilidad de Orden")))
  })
  
  #Tabla de segunda pestaña
  output$tablamaquina <- renderDataTable({
    req(Datos())
    aux <- Datos() %>% filter(matricula == input$buttons1)
    DT:: datatable(aux[,c("dia", "matricula", input$checkbox1, "p_orden")], rownames = FALSE, style = "bootstrap", options = list(pageLength = 10),filter = list(position = "bottom", plain = TRUE ,clear = TRUE))
  })

  #Gráfico segunda pestaña
  output$evtempAlarmas <- renderPlotly({
    req(Datos())
    print(ggplotly(ggplot(data = filter(Datos(), Datos()$"matricula" == input$buttons1 ),aes_string(x = "dia",y = input$radiobuttons1))+
        geom_line()+
        geom_point(aes_string(col = input$radiobuttons1))+
        scale_colour_gradientn(colours = c("gray21","firebrick"))+
        theme(legend.position = "none")+
        # scale_colour_gradientn(colours = c("gray21","firebrick"))+theme(legend.position = "none")+
        labs(x = "Día" , y = paste("Franja Horaria:  ", input$radiobuttons1))))
  })
  
  #Histograma 3 pestaña
  output$histogramstats <- renderPlotly({
    req(Datos())     
    print(ggplotly(ggplot(data = filter(Datos(), dia>input$datestats[1], dia<input$datestats[2]), aes_string(x = input$buttons2))+
                     geom_histogram(bins = input$sliderstats, fill= rev(tmaptools::get_brewer_pal("YlOrRd", n = input$sliderstats)), color="#383838", alpha = 0.9)+
                     labs(x = paste("Alarma:", input$buttons2), y = "Contador")))
  })
  
  #Boxplots 3 pestaña
  output$boxplotstats <- renderPlotly({
    req(Datos())
    Datos_filter <- filter(Datos(),dia>input$datestats[1], dia<input$datestats[2]) 
    index <- which(Datos_filter$matricula == input$buttons1)
    if(input$checkbox2 == FALSE){
      aux <- Datos_filter[index,]
      #Boxplot por matricula
      print(ggplotly(ggplot(data = aux, aes_string(y = input$buttons2 ))+
                       geom_boxplot(fill= "#dd0440", color="#383838", alpha = 0.9)+
                       labs(x = paste("Matricula", input$buttons1), y = "ALARMAS")))
    }
    #Conjunto de boxplots cuando se clica el checkbox
    else if(input$checkbox2 == TRUE){
      Datos_filter <- filter(Datos(),dia>input$datestats[1], dia<input$datestats[2]) 
      print(ggplotly(ggplot(data = Datos_filter, aes_string(y = input$buttons2, x = "matricula", fill = "matricula"))+
                       geom_boxplot(fill = rev(tmaptools::get_brewer_pal("YlOrRd", n = 26)), color="#383838", alpha = 0.9)+labs(x = "Matrículas", y = paste("Alarma: ", input$buttons2))+theme(legend.position = "none" ,axis.text.x = element_text(angle = 45,size=8, hjust = 1))))
    }
    else{NULL}
      
  })
  
  output$certif <- renderImage({
    list(src=("certificado.PNG"),fileType="image/png")
  }, deleteFile = FALSE)
  
  }

shinyApp(ui, server)
