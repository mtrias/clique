# server.R

server <- function(input, output, session) {

  # ---------------------------------------------------------
  # CONTROL DE ESTADO CENTRALIZADO
  # ---------------------------------------------------------
  v <- reactiveValues(
    nodes = NULL,
    edges = NULL,
    matrix_trigger = 0 # Disparador aislado para la matriz dispersa
  )

  active_pivot <- reactiveVal(NULL)
  planted_nodes_list <- reactiveVal(integer(0))
  found_nodes_list <- reactiveVal(integer(0))
  algo_logs <- reactiveVal(character(0))
  algo_running <- reactiveVal(FALSE)

  # ---------------------------------------------------------
  # DINÁMICA DE UMBRAL (Evadir colapso de Wigner)
  # ---------------------------------------------------------
  observeEvent(input$num_vertices, {
    # k = ceil(2.5 * sqrt(n))
    suggested_k <- ceiling(2.5 * sqrt(input$num_vertices))

    updateSliderInput(session, "clique_k",
                      max = input$num_vertices,
                      value = min(suggested_k, input$num_vertices))
  })

  # ---------------------------------------------------------
  # RENDERIZADO DE RESULTADOS DE ALGORITMO (Diagnóstico)
  # ---------------------------------------------------------
  output$algo_results_ui <- renderUI({
    req(algo_running())

    planted <- planted_nodes_list()
    found <- found_nodes_list()

    # Teoría de conjuntos para métricas de clasificación
    true_positives <- intersect(planted, found)
    false_positives <- setdiff(found, planted)
    false_negatives <- setdiff(planted, found)

    recall <- length(true_positives) / max(1, length(planted))
    precision <- length(true_positives) / max(1, length(found))

    # Determinar color de estado
    if (length(false_positives) == 0 && length(false_negatives) == 0) {
      status_color <- "#d4edda" # Verde - Exacto
      border_color <- "#c3e6cb"
      status_text <- "Recuperación Exacta"
    } else if (length(true_positives) > 0) {
      status_color <- "#fff3cd" # Amarillo - Parcial
      border_color <- "#ffeeba"
      status_text <- "Detección Parcial (Con Ruido/Pérdida)"
    } else {
      status_color <- "#f8d7da" # Rojo - Fallo
      border_color <- "#f5c6cb"
      status_text <- "Fallo en la Recuperación"
    }

    div(class = "search-box", style = paste0("background-color:", status_color, "; border-color:", border_color, ";"),
        tags$h5(tags$b(status_text)),
        tags$ul(
          tags$li(paste("Aciertos (TP):", length(true_positives))),
          tags$li(paste("Ruido (FP):", length(false_positives))),
          tags$li(paste("Pérdida (FN):", length(false_negatives)))
        )
    )
  })

  output$algorithm_monitor_ui <- renderUI({
    logs <- algo_logs()
    if(length(logs) > 0) {
      div(class = "log-output", HTML(paste(logs, collapse = "<br/>")))
    }
  })

  # ---------------------------------------------------------
  # CARGA ESTRICTA DE SUBMÓDULOS
  # ---------------------------------------------------------
  source("src/sub_generate_graph.R", local = TRUE)
  source("src/sub_matrix_interaction.R", local = TRUE)
  source("src/sub_network_interaction.R", local = TRUE)
  source("src/sub_plant_clique.R", local = TRUE)
  source("src/sub_run_spectral.R", local = TRUE)
}
