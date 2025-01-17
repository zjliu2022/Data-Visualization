library(shiny)
library(shinythemes)
library(shinydashboard)
library(ggplot2)
library(data.table)
library(leaflet)
library(leaflet.extras)
library(DT)
library(scales)
library(tidyverse)


###################
### The UI Part
###################

ui <- dashboardPage(
  dashboardHeader(title = "Beijing Restaurants"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "page1", icon = icon("info-circle")),
      menuItem("Ranking", tabName = "page2", icon = icon("server")),
      menuItem("Map", tabName = "page3", icon = icon("fa-solid fa-map")),
      menuItem("Data", tabName = "page4", icon = icon("fa-solid fa-database")
      ))
  ),
  dashboardBody(
    tabItems(
      ### Tab for the Intro 
      tabItem(tabName = "page1",
              column(width = 12, img(src = "1.jpg", width = 600), align = "center"),
              h2("Why are we here"),
              p("'We tend to decide where to eat, where to go to bookstores, where to watch movies, where to party...by reading reviews.' American linguist 
                 Shaotang Ren pointed out the voice of consumers in the age of Internet Economy in his book <Food Linguistics>."),
              p("It's true."),
              p("Nowadays people are having so many options but so little information by themselves to tell which ones are good.
                 To help people with finding their favored restaurant, we are creating this website as a guide for people in Beijing."),
              a(href="https://github.com/zjliu2022/Data-Visualization", "Data Source"),
              h2("What can we do"),
              p("Through this webpage, we aim to address the following problems to better serve people finding ideal restaurants."),
              p("• What restaurants are there in Beijing?"),
              p("• What are their ratings?"),
              p("• How many comments are there for each restaurant?"),
              p("• What are monthly sales for each restaurant?"),
              p("• What is average price for each restaurant?"),
              h2("How we did it"),
              p("We obtained the merchant data of a leading platform (Meituan) in the food delivery industry in China through a web crawler platform.
                 We also collected information from a big-data service product and integrated the data information of the business district where the merchants are located. 
                 We obtained the data from the census bureaus of various cities.
                 In the end, more than 29,000 rows of data were obtained. Please See below for specific data descriptions."),
              p(" We focused on Merchants in Beijing from the crawled data.
                  There were many variables of the original data. By using descriptive statistics, we examined the features and performed data cleaning: We eliminated
                  Irrelevant variables (such as business ID, address, etc.) and abnormal data (such as unreasonable extreme values, blank values). For certain variables
                  We made sure the units are the same and changed the format. (for example, the business hours are divided into day, night, and early morning). 
                  We finally kept these variables: monthly sales, average price, Delivery time, delivery type, number of comments, delivery fee, business hours, etc."),
              h2("What you can see"),
              p("Bar chart: Top 10 Merchants under different metrics."),
              p("Heatmap: Merchants information (Ratings, Monthly sales, Number of Comments, Average prices."),
              p("Data table: shows all data points."),
              h2("Data Dictionary"),
              p("city: Name of the City ( Here we only include Beijing)"),
              p("district: District of the City"),
              p("name: Name of the merchant"),
              p("score:  Average merchant Rating in the delivery platform, generated by the user"),
              p("comment_number:  Total number of comments of the Merchant"),
              p("month_sales:  Total sales for the merchant in January 2022"),
              p("avg_price_rmb:  Average price of the merchant's product"),
              p("category1: Type of product that Merchant sales (Most of them are Foods related products)"),
              p("delivery_time1: Expected delivery time of the Merchant"),
              p("delivery_type1: Type of delivery of Merchant (Run & Flash are delivery services provided by the platform, Merchant means merchant will deliver the product without third party services)"),
              p("in_time_delivery_percent: Percentage to order that delivery within the expected delivery time"),
              p("min_price_rmb: Minimum price of the order"),
              p("shipping_fee: Delivery fee"),
              p("lat:  Geographic Information"),
              p("lng： Geographic Information"),
      ),
      
      ### Tab for the Ranking 
      tabItem(tabName = "page2",
              h2('Ranking the Merchant Data'),
              radioButtons("radio1", choices = list("Rank by average price" = 1, "Rank by comment number" = 2),
                           selected = 1, inline = T, label = "Please only select one of the following checkbox!"),
              plotOutput("plot1")
      ),
      
      ### Tab for the Map 
      tabItem(tabName = "page3",
              h2("Visualize the Merchant Data on Map"),
              radioButtons("radio2", choices = list("Show Monthly_Sales Density(Orange)" = 1, "Show Avg_Price Density(Pink)" = 2, 
                                                   "Show Score Density(Green)" = 3, "Show Merchant Count Density(Red)" = 4),
                           selected = 1, inline = T, label = "Please only select one of the following checkbox!"),
              leafletOutput("myMap", width="100%", height=600)
              
      ),
      
      ### Tab for the Table 
      tabItem(tabName = "page4",
              dataTableOutput("myTable"))
    )
  )
)

###################
### The Server Part
###################
server <- function(input, output, session) {
  data = read_csv("data.csv")
  
  ###################
  ## Map Data Prep
  ###################
  data_map = read_csv('data.csv')
  data_map$month_sales_clean = as.numeric(data_map$month_sales_clean)
    
  
  # Data for Count_map 
  Count_map_data = data_map %>% 
    group_by(lng=round(lng,3),lat=round(lat,3)) %>%
    summarise(N=n()) %>%
    mutate(latL=lat-0.0011, latH=lat+0.0011, lngL=lng-0.0011, lngH=lng+0.0011) %>%
    mutate(Poptext = paste("The number of merchants in this area is: ",round(N,3)))

  # Data for Score_map
  Score_map_data = data_map %>% 
    group_by(lng=round(lng,3),lat=round(lat,3)) %>%
    summarise(N=mean(score)) %>%
    mutate(latL=lat-0.0011, latH=lat+0.0011, lngL=lng-0.0011, lngH=lng+0.0011) %>%
    mutate(Poptext = paste("The avgerage of score in this area is: ",round(N,3)))
  
  # Data for the Sales_map
  Sales_map_data = data_map %>% 
    group_by(lng=round(lng,3),lat=round(lat,3)) %>%
    summarise(N=mean(month_sales_clean)) %>%
    mutate(latL=lat-0.0011, latH=lat+0.0011, lngL=lng-0.0011, lngH=lng+0.0011)%>%
    mutate(Poptext = paste("The avgerage of monthly sales in this area is: ",round(N,3)))
  
  # Data for the Price_map
  Price_map_data = data_map %>% 
    group_by(lng=round(lng,3),lat=round(lat,3)) %>%
    summarise(N=mean(avg_price_rmb)) %>%
    mutate(latL=lat-0.0011, latH=lat+0.0011, lngL=lng-0.0011, lngH=lng+0.0011)%>%
    mutate(Poptext = paste("The avgerage of price in this area is: ",round(N,3)))
  
  
  ####################
  ## Render Rank Plot
  ####################
  output$plot1 = renderPlot({
    
    if(input$radio1 == 1) {
      data = data_map %>% 
        arrange(desc(avg_price_rmb)) %>% 
        slice(1:10) 
      plot = data %>%
        ggplot(aes(x=name, y=avg_price_rmb, fill=name)) +
        geom_histogram(stat='identity', show.legend=FALSE) +
        coord_flip() +
        theme(
          panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank()) 
      return(plot)
    }
    
    if(input$radio1 == 2) {
      data = data_map %>%
        filter(category1 == "Foods" & comment_number != "Unknown") %>%
        arrange(desc(comment_number)) %>% 
        slice(1:10) 
      plot = data %>%
        ggplot(aes(x=name, y=comment_number, fill=name)) +
        geom_histogram(stat='identity', show.legend=FALSE) +
        coord_flip() +
        theme(
          panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank()) 
      return(plot)
    }
    
  })
  
  
  ###############
  ## Render Map
  ###############
  output$myMap = renderLeaflet({
  
    if(input$radio2 == 1){
      Sales_map=Sales_map_data %>% 
        leaflet() %>% 
        addTiles() %>%
        setView(116.407,39.904, zoom=12) %>%
        addProviderTiles(providers$Stamen.Toner, group = "Toner")%>%
        addProviderTiles(providers$CartoDB.Positron, group = 'CartoDB')%>%
        addLayersControl(baseGroups = c("Toner", "OSM",'CartoDB'),
                         options = layersControlOptions(collapsed = FALSE)) %>%
        addRectangles(
          lng1=~lngL, 
          lat1=~latL,
          lng2=~lngH, 
          lat2=~latH,
          fillOpacity = ~N*0.0003, 
          opacity = 0, 
          fillColor = "orange", 
          label = ~Poptext)%>%
        addTiles("SalesDensity Plot")
      return(Sales_map)
    }
    
    if(input$radio2 == 2){
      Price_map=Price_map_data %>% 
        leaflet() %>% 
        addTiles() %>%
        setView(116.407,39.904, zoom=12) %>%
        addProviderTiles(providers$Stamen.Toner, group = "Toner")%>%
        addProviderTiles(providers$CartoDB.Positron, group = 'CartoDB')%>%
        addLayersControl(baseGroups = c("Toner", "OSM",'CartoDB'),
                         options = layersControlOptions(collapsed = FALSE)) %>%
        addRectangles(
          lng1=~lngL, 
          lat1=~latL,
          lng2=~lngH, 
          lat2=~latH,
          fillOpacity = ~N/100, 
          opacity = 0, 
          fillColor = "Pink", 
          label = ~Poptext)%>%
        addTiles("SalesDensity Plot")
      return(Price_map)
    }
    
    if(input$radio2 == 3){
      Score_map=Score_map_data %>% 
        leaflet() %>% 
        addTiles() %>%
        setView(116.407,39.904, zoom=12) %>%
        addProviderTiles(providers$Stamen.Toner, group = "Toner")%>%
        addProviderTiles(providers$CartoDB.Positron, group = 'CartoDB')%>%
        addLayersControl(baseGroups = c("Toner", "OSM",'CartoDB'),
                         options = layersControlOptions(collapsed = FALSE)) %>%
        addRectangles(
          lng1=~lngL, 
          lat1=~latL,
          lng2=~lngH, 
          lat2=~latH,
          fillOpacity = ~N*0.07, 
          opacity = 0, 
          fillColor = "green", 
          label = ~Poptext)%>%
        addTiles("Score Density Plot")
      return(Score_map)
    }
    if(input$radio2 == 4) {
      Count_map=Count_map_data %>% 
        leaflet() %>% 
        addTiles() %>%
        setView(116.407,39.904, zoom=12) %>%
        addProviderTiles(providers$Stamen.Toner, group = "Toner")%>%
        addProviderTiles(providers$CartoDB.Positron, group = 'CartoDB')%>%
        addLayersControl(baseGroups = c("Toner", "OSM",'CartoDB'),
                         options = layersControlOptions(collapsed = FALSE)) %>%
        addRectangles(
          lng1=~lngL, 
          lat1=~latL,
          lng2=~lngH, 
          lat2=~latH,
          fillOpacity = ~N*0.2, 
          opacity = 0, 
          fillColor = "red", 
          label = ~Poptext
        )%>%
        addTiles("Merchant Density Plot")
      return(Count_map)
    }
  })
  
  
  
  #################
  ## Render Table
  #################
  output$myTable = renderDataTable({
    return(datatable(data,options = list(scrollX=TRUE), rownames= FALSE))
  })
}
  
 

shinyApp(ui = ui, server = server)
