# ==============================================================================
# ARCHIVO: server.R (Controlador Central Modularizado)
# Misión: Inicializar los vectores de estado e integrar los submódulos de R
# ==============================================================================

server <- function(input, output, session) {

  # 1. ESTADO REACTIVO CENTRALIZADO
  v <- reactiveValues(
    nodes = NULL,
    edges = NULL,
    matrix_trigger = 0
  )

  # Variables reactivas de estado interno
  active_pivot       <- reactiveVal(NULL)
  planted_nodes_list <- reactiveVal(NULL)
  found_nodes_list   <- reactiveVal(NULL)
  algo_logs          <- reactiveVal("")
  algo_running       <- reactiveVal(FALSE)

  # Reglas de negocio básicas de los inputs
  observeEvent(input$num_vertices, {
    updateSliderInput(session, "clique_size", max = min(input$num_vertices, 15))
  })

  # 2. INTEGRACIÓN COMPORTAMENTAL MEDIANTE CARGA DETALLADA (source)
  # El parámetro local = TRUE obliga a compilar el código dentro del entorno
  # nativo del server, permitiendo el uso directo de 'input', 'output' y 'v$'.

  source("src/sub_generate_graph.R",        local = TRUE)
  source("src/sub_matrix_interaction.R",    local = TRUE)
  source("src/sub_network_interaction.R",   local = TRUE)
  source("src/sub_algorithms.R",            local = TRUE)
}
