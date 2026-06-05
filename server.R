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

  # ==============================================================================
  # OPTIMIZACIÓN EN server.R: Inicialización del tamaño ideal de Clique
  # ==============================================================================
  observeEvent(input$num_vertices, {
    n <- input$num_vertices

    # Fórmula teórica adaptada: c * sqrt(n) donde c=2 asegura romper el bulto de Wigner
    ideal_k <- ceiling(2 * sqrt(n))

    # Coeficiente ajustado a 2.5 para mitigar la varianza estadística en n = 100
    ideal_k <- ceiling(2.5 * sqrt(n))

    # Garantizar que el valor ideal nunca exceda las dimensiones del grafo por seguridad
    if (ideal_k > n) ideal_k <- n

    # Actualizar dinámicamente el techo y el valor por defecto en la UI
    updateSliderInput(
      session,
      "clique_size",
      max = n,
      value = ideal_k
    )
  })

  # 2. INTEGRACIÓN COMPORTAMENTAL MEDIANTE CARGA DETALLADA (source)
  # El parámetro local = TRUE obliga a compilar el código dentro del entorno
  # nativo del server, permitiendo el uso directo de 'input', 'output' y 'v$'.

  source("src/sub_generate_graph.R",        local = TRUE)
  source("src/sub_matrix_interaction.R",    local = TRUE)
  source("src/sub_network_interaction.R",   local = TRUE)
  source("src/sub_plant_clique.R",          local = TRUE)
  source("src/sub_run_spectral.R",          local = TRUE)
}
