# ui.R

ui <- fluidPage(

  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),

  titlePanel("Análisis Espectral: Plante Clique Problem"),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      class = "scrollable-sidebar",

      # Sección 1: Grafo Erdős-Rényi
      tags$b("1. Grafo Erdős-Rényi G(n, p)"),
      sliderInput("num_vertices", "Número de vértices (n):", min = 10, max = 1000, value = 100, step = 10),
      sliderInput("prob_p", "Probabilidad de arista (p):", min = 0, max = 1, value = 0.5, step = 0.05),
      actionButton("btn_generate_graph", "Regenerar Grafo", class = "btn-primary btn-block"),
      hr(),

      # Sección 2: Edición Directa
      tags$b("2. Edición Directa"),
      p("Modifica la topología seleccionando nodos individuales. Clickea en un nodo para inspeccionar las conexiones del vértice elegido. Clickea en otro nodo para conectarlos.", style = "font-size: 0.9em; color: #555;"),
      hr(),

      # Sección 3: Implantación
      tags$b("3. Implantación"),
      sliderInput("clique_k", "Tamaño del clique (k):", min = 3, max = 100, value = 25, step = 1),
      actionButton("btn_plant_clique", "Implantar Clique Aleatorio", class = "btn-success btn-block"),
      uiOutput("planted_clique_ui"),
      hr(),

      # Sección 4: Algoritmo
      tags$b("4. Algoritmo Espectral"),
      actionButton("btn_run_algo", "Buscar Clique Máximo", class = "btn-warning btn-block"),
      uiOutput("algo_results_ui"),
      uiOutput("algorithm_monitor_ui")
    ),

    mainPanel(
      width = 9,
      # ui.R (Fragmento modificado de la pestaña principal)
      tabsetPanel(
        tabPanel("Grafo",
                 visNetworkOutput("network_plot", width = "100%", height = "800px")
        ),
        tabPanel("Adyacencia",
                 # Se eleva a 800px para emparejar el alto del canvas y optimizar el viewport
                 plotOutput("adj_matrix_plot", height = "800px")
        )
      )
    )
  )
)
