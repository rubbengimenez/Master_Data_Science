                                                # ########### #
                                                # LA TERRETA #
# library(devtools)                             # ########## #
# library(leaflet)
# library(tmap)
# library(shinythemes)
# library(shiny)
# library(ggplot2)
# library(DT)
# library(dplyr)
# library(plotly)
# if(!suppressWarnings(require('photon'))){devtools::install_github(repo = 'rCarto/photon')}
# library(photon)
# library(rlang)
# library(tidyr)

packages = c('readxl','devtools','leaflet','tmap','shinythemes','shiny','ggplot2','DT', 'dplyr', 'plotly', 'rlang','tidyr','leaflet.extras')
#use this function to check if each package is on the local machine
#if a package is installed, it will be loaded
#if any are not, the missing package(s) will be installed and loaded
package.check <- lapply(packages, FUN = function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE)
    library(x, character.only = TRUE)
  }
})
if(!suppressWarnings(require('photon'))){devtools::install_github(repo = 'rCarto/photon')}


# install.ImageMagick()
# library(animation) no debería hacer falta

rm(package.check, packages)





############################## HERRAMIENTAS #######################
load("CV_data.Rdata")

municipios <- unique(CV_map_T@data$Municipios[order(CV_map_T@data$Municipios)])
years <- paste(1998:2018)
provincias <- c("Alicante", "Castellón", "Valencia")
colores <- rev(viridisLite::plasma(9))
breaks <- c(0, 500, 2500, 5000, 10000, 20000, 70000, 150000, 250000,Inf)
my_labels <- c("De 0 a 500 habitantes",
               "De 500 a 2,500 habitantes",
               "De 2,500 a 5,000 habitantes",
               "De 5,000 a 10,000 habitantes",
               "De 10,000 a 20,000 habitantes",
               "De 20,000 a 70,000 habitantes",
               "De 70,000 a 150,000 habitantes",
               "De 150,000 a 250,000 habitantes",
               "250,000 o más habitantes")
###################################################################


ui<-navbarPage( "COMUNIDAD VALENCIANA",
                theme = shinytheme("united"),
                # shinythemes::themeSelector(),
                tabPanel("CARACTERÍSTICAS POR PROVINCIA",
                         sidebarPanel(
                           selectInput(inputId = "years1", label = "Seleccione Año", choices = years, selected = years[21]),
                           selectInput(inputId = "selectprovincia", label = "Seleccine la provincia",choices = provincias, selected = provincias[2])
                         ),
                           mainPanel(
                             h2("Habitantes en la Comunidad Valenciana por municipio"),
                             leafletOutput(outputId = "whole_map"),
                             h2("Mapa por provincia"),
                             leafletOutput(outputId = "prov_map"), 
                             h3("Evolución de la población"),
                             plotlyOutput(outputId = "evoprov"),
                             plotlyOutput(outputId = "provbars"),
                             plotlyOutput(outputId = "provbars_menos")
                             
                           )
                         ),
                tabPanel("CARACTERÍSTICAS POR MUNICIPIO",
                         sidebarLayout(
                           sidebarPanel(
                             selectInput(inputId = "buttons1", label = "Municipio", choices = municipios, selected = municipios[185]),
                             leafletOutput(outputId = "munimapa")),
                           mainPanel(
                             h2("Evolución de la Población por Municipio"),
                             tableOutput(outputId = "munitabla"),
                             plotlyOutput(outputId = "municipioschart")
                           )
                         ))
                )

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  output$whole_map <- renderLeaflet({
    munimap <- tm_shape(CV_map)+
      tm_fill(col = input$years1,
              style = "fixed", 
              palette = colores, 
              breaks = breaks ,
              labels = my_labels,
              title = paste("Habitantes por municipio, Comunidad Valenciana", input$years1))+
      tm_borders(alpha =  0.7)+
      tm_layout(main.title = paste("Comunidad Valenciana", input$years1), 
                title.size = 2,
                legend.outside = T,
                legend.outside.size = 0.4, 
                legend.outside.position = c("right") ,
                bg.color = "gray88", 
                frame = FALSE,
                inner.margin = 0.1, 
                outer.margins = 0.05, 
                legend.width = 11)+
      tm_polygons()
    munimapleaf <- tmap_leaflet(munimap)
    munimapleaf %>% addProviderTiles("OpenStreetMap") %>% 	setView(lng	=	 1.888587 , lat	=	39.495297   , zoom	=	7) %>% leaflet.extras::	addResetMapButton()
  })
  
  output$prov_map <- renderLeaflet({
    munimap <- tm_shape(CV_map[CV_map@data$NAME_2 == input$selectprovincia,])+
      tm_fill(col = input$years1,
              style = "fixed", 
              palette = colores, 
              breaks = breaks ,
              labels = my_labels,
              title = paste("Habitantes por municipio", input$selectprovincia,input$years1))+
      tm_borders(alpha =  0.7)+
      tm_layout(main.title = paste("Comunidad Valenciana", input$years1), 
                title.size = 2,
                legend.outside = T,
                legend.outside.size = 0.4, 
                legend.outside.position = c("right") ,
                bg.color = "gray88", 
                frame = FALSE,
                inner.margin = 0.1, 
                outer.margins = 0.05, 
                legend.width = 11)+
      tm_polygons()
    munimapleaf <- tmap_leaflet(munimap)
    munimapleaf %>% addProviderTiles("OpenStreetMap")%>% setView(lng	=	 1.381307 , lat	=	39.580639   , zoom	=	7) %>% leaflet.extras::	addResetMapButton() 
    
  })
  
  
  output$evoprov <- renderPlotly({
    aux <- CV_map@data %>% filter(NAME_2 == input$selectprovincia) 
    aux.unique <- !duplicated(aux[c("Municipios")])
    #se selecciona los municipios para no repetir 
    aux <- aux[aux.unique,] %>% dplyr:: select(`1998`:`2018`) %>%  tidyr:: gather(years, population) %>% dplyr:: group_by(years) %>% summarise(population = sum(population, na.rm = T))
    print(ggplotly(ggplot(data = aux, aes(x = years, y = population, group = 1))+
                     geom_point(aes(fill ="#cc7a00"))+
                     geom_line(aes(alpha = 0.8))+
                     labs(x = "Años" , y = "Población")+
                     theme(legend.position = "none",axis.text.x = element_text(angle = 45,size=8, hjust = 1))+
                     ggtitle(paste("Evolución de la población total de la provincia de", input$selectprovincia))))
  })
  
  output$provbars <- renderPlotly({
    colors <- viridisLite::plasma(15)
    #se filtra por provincia y por año
    aux <- CV_map@data %>% filter(NAME_2 == input$selectprovincia) %>%  dplyr:: select(Municipios, input$years1) %>% dplyr:: arrange(desc(!! rlang::sym(c(input$years1))))
    #se selecciona los municipios para no repetir 
    aux.unique <- !duplicated(aux[c("Municipios")])
    aux <- aux[aux.unique,] %>% dplyr:: select(Municipios, input$years1)
    aux$Municipios <- reorder(aux$Municipios, -aux[,which(colnames(aux) == input$years1)])
    
    colnames(aux)[2] <- "Poblacion"
    
    print(ggplotly(ggplot(data = aux[1:15,], aes_string(x = "Municipios", y = "Poblacion", fill = "Municipios"))+
      geom_col()+
      theme(legend.position = "none",axis.text.x = element_text(angle = 45,size=8, hjust = 1))+
      labs(x = "Municipios" , y = "Población")+
      ggtitle(paste("15 municipios con más habitantes en", input$selectprovincia, "en", input$years1))+
      scale_fill_manual(values=colors)))
  })
  
  output$provbars_menos <- renderPlotly({
    colors <- rev(viridisLite::plasma(15,begin = 0.55, end = 1))
    #se filtra por provincia y por año
    aux <- CV_map@data %>% filter(NAME_2 == input$selectprovincia) %>%  dplyr:: select(Municipios, input$years1) %>% dplyr:: arrange(!! rlang::sym(c(input$years1)))
    #se selecciona los municipios para no repetir 
    aux.unique <- !duplicated(aux[c("Municipios")])
    aux <- aux[aux.unique,] %>% dplyr:: select(Municipios, input$years1)
    aux$Municipios <- reorder(aux$Municipios, aux[,which(colnames(aux) == input$years1)])
    
    colnames(aux)[2] <- "Poblacion"
    
    print(ggplotly(ggplot(data = aux[1:15,], aes_string(x = "Municipios", y = "Poblacion", fill = "Municipios"))+
                     geom_col()+
                     theme(legend.position = "none",axis.text.x = element_text(angle = 45,size=8, hjust = 1))+
                     labs(x = "Municipios" , y = "Población")+
                     ggtitle(paste("15 municipios con menos habitantes en", input$selectprovincia, "en", input$years1))+
                     scale_fill_manual(values=colors)))
  })
  

  
  
  
  output$municipioschart <- renderPlotly({
    aux <- CV_map_T@data %>% filter(Municipios == input$buttons1)
    print(ggplotly(ggplot(data = aux, aes(x = year, y = population, group = 1))+
                     geom_point()+
                     geom_line(aes(alpha=0.8))+
                     labs(x = "Años" , y = "Población")+
                     theme(legend.position = "none",axis.text.x = element_text(angle = 45,size=8, hjust = 1))))
  })
  
  output$munitabla <- renderTable({
    as.data.frame(CV_map@data %>% filter(Municipios == input$buttons1) %>% dplyr::select(`2018`:`1998`)) %>% lapply(as.integer) %>% as.data.frame()%>% setNames(rev(years))
  })
  
  output$munimapa <- renderLeaflet({
    mapa <- tm_shape(CV_map[CV_map@data$Municipios == input$buttons1,])+
      tm_fill(col = "2018",
              style = "fixed", 
              palette = colores, 
              breaks = breaks ,
              labels = my_labels,
              legend.show = FALSE,
              title = paste("Número de habitantes por municipio"))+
      tm_borders(alpha =  0.7)+
      tm_layout(main.title = paste(input$buttons1, 2018), 
                title.size = 2,
                frame = FALSE,
                inner.margin = 0.001, 
                outer.margins = 0.05, 
                legend.width = 11)

    mapaleaf <- tmap_leaflet(mapa)
    mapaleaf %>% leaflet(options = leafletOptions(zoomControl = FALSE)) %>% addProviderTiles("OpenStreetMap") %>% 	addMarkers(lng = photon::geocode(input$buttons1)$lon[1], lat = photon::geocode(input$buttons1)$lat[1], label = input$buttons1) %>% setView(lng	=	 -0.534203 , lat	=	39.361064   , zoom	=	7)   
  })
  

}

# Run the application 
shinyApp(ui = ui, server = server)

