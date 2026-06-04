# ==============================================================================
# ARCHIVO: ui.R
# Misión: Definir la estructura visual y la disposición de los componentes
#         de la interfaz de usuario sin contener lógica de cómputo.
# ==============================================================================

ui <- fluidPage(
  # ----------------------------------------------------------------------------
  # CONFIGURACIÓN DEL ENCABEZADO Y CARGA DE ESTILOS
  # ----------------------------------------------------------------------------
  tags$head(
    # Vincula el archivo CSS externo ubicado en la carpeta obligatoria 'www/'
    # Shiny mapea 'www/' como la raíz para rutas relativas, por eso se omite en el href.
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),

  # ----------------------------------------------------------------------------
  # DISPOSICIÓN PRINCIPAL DE LA PÁGINA (Sidebar + MainPanel)
  # ----------------------------------------------------------------------------
  sidebarLayout(

    # PANEL LATERAL: Controles e inputs de la aplicación
    sidebarPanel(
      width = 3,                       # Ocupa 3 de las 12 columnas disponibles del grid
      class = "scrollable-sidebar",    # Aplica scroll interno si los controles desbordan la pantalla

      # SECCIÓN 1: Configuración de la topología inicial del grafo
      h4(tags$b("1. Grafo Base")),
      sliderInput("num_vertices", "Número de Vértices:", min = 5, max = 205, value = 100, step = 1),
      actionButton("regenerate_btn", "Regenerar Grafo", class = "btn-primary btn-block", icon = icon("sync")),

      hr(), # Separador visual horizontal

      # SECCIÓN 2: Panel de información sobre cómo editar el grafo en vivo
      h4(tags$b("2. Edición Directa")),
      wellPanel(
        h5(tags$b("Interacción Total:")),
        p(tags$small("• Pestaña Red: Clic para activar pivote y conectar.")),
        p(tags$small("• Pestaña Matriz: Haz clic directo en cualquier celda para alternar (conectar/desconectar) aristas.")),
        p(tags$small("• Nota: No se permiten lazos (auto-conexiones)."))
      ),
      # Muestra en texto monoespaciado qué nodo está seleccionado para conectar en el lienzo
      verbatimTextOutput("pivot_status"),

      hr(),

      # SECCIÓN 3: Configuración del subgrafo completo oculto (Clique Plantado)
      h4(tags$b("3. Implantación")),
      sliderInput("clique_size", "Tamaño del Clique (k):", min = 5, max = 155, value = 141, step = 1),
      actionButton("plant_random_clique_btn", "Implantar Clique Aleatorio", class = "btn-success btn-block", icon = icon("dice")),
      br(),
      # Contenedor dinámico que mostrará la lista de nodos que forman el clique implantado
      uiOutput("planted_clique_ui"),

      hr(),

      # SECCIÓN 4: Disparador del algoritmo y consola de monitorización
      h4(tags$b("4. Ejecución del Algoritmo")),
      actionButton("run_clique_btn", "Buscar Clique Máximo", class = "btn-warning btn-block", icon = icon("bolt")),

      # Contenedor dinámico que inyectará la terminal negra con los logs del backend
      uiOutput("algorithm_monitor_ui")
    ),

    # PANEL PRINCIPAL: Despliegue de los dos enfoques del grafo (Visual vs Algebraico)
    mainPanel(
      width = 9,                       # Ocupa las 9 columnas restantes del grid de Bootstrap
      tabsetPanel(
        type = "tabs",

        # Pestaña de la Red Geométrica interactiva
        tabPanel("Vista de Red", icon = icon("network-wired"),
                 br(),
                 visNetworkOutput("network_plot", width = "100%", height = "700px")
        ),

        # Pestaña de la Matriz Binaria de Adyacencia
        tabPanel("Mapa de Bits (Adyacencia)", icon = icon("th"),
                 br(),
                 # Encapsula el gráfico en un contenedor blanco para estilizado CSS
                 div(class = "matrix-plot-container",
                     # Captura las coordenadas exactas de los clics sobre el ggplot2
                     plotOutput("adjacency_bitmap_plot", width = "900px", height = "850px", click = "matrix_click")
                 )
        )
      )
    )
  )
)
