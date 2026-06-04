# ==============================================================================
# SUBMÓDULO: Generación y Renderizado del Grafo Inicial
# ==============================================================================

# Generación aislada del grafo original (se ejecuta por botón o carga inicial)
generate_graph_event <- eventReactive({
  input$regenerate_btn
}, {
  n_nodes <- input$num_vertices

  # Reseteo completo de estados intermedios
  active_pivot(NULL)
  planted_nodes_list(NULL)
  found_nodes_list(NULL)
  algo_logs(">> Grafo inicializado.\n")
  algo_running(FALSE)

  # Parámetro adaptativo para mantener el grafo disperso
  p_proporcional <- .5
  g <- sample_gnp(n = n_nodes, p = p_proporcional, directed = FALSE)
  vis_data <- toVisNetworkData(g)

  # Ajuste de tamaño según volumen de datos
  nodo_size <- 11
  fuante_size <- 11

  # Construcción del dataframe de nodos
  nodes_df <- vis_data$nodes %>%
    mutate(id = as.character(id), label = id, size = nodo_size, font.size = fuante_size,
           font.color = "#000000", font.face = "Arial Black",
           color.background = "#97C2FC", color.border = "#2B7CE9", borderWidth = 1)

  # Construcción del dataframe de aristas
  if (!is.null(vis_data$edges) && nrow(vis_data$edges) > 0) {
    edges_df <- vis_data$edges %>%
      mutate(from = as.character(from), to = as.character(to),
             smooth = FALSE, color = "#848484", width = 1)
  } else {
    edges_df <- data.frame(from = character(), to = character(),
                           smooth = logical(), color = character(),
                           width = numeric(), stringsAsFactors = FALSE)
  }

  # Asignación de ID único compuesto ("origen-destino") para el ruteo por Proxy
  if(nrow(edges_df) > 0) {
    edges_df$id <- paste0(edges_df$from, "-", edges_df$to)
  } else {
    edges_df$id <- character()
  }

  v$g <- g
  v$nodes <- nodes_df
  v$edges <- edges_df
  v$matrix_trigger <- v$matrix_trigger + 1

  return(TRUE)
}, ignoreNULL = FALSE)

# Render del lienzo físico de visNetwork (Congelado mediante isolate)
output$network_plot <- renderVisNetwork({
  generate_graph_event()

  initial_nodes <- isolate(v$nodes)
  initial_edges <- isolate(v$edges)

  req(initial_nodes, initial_edges)

  visNetwork(initial_nodes, initial_edges) %>%
    visPhysics(
      stabilization = list(
        enabled = TRUE,
        iterations = 100
      ),
      barnesHut = list(
        gravitationalConstant = -100,
        centralGravity = 0.1,
        springLength = 250
      )
    ) %>%
    visEvents(stabilizationIterationsDone = "function() { this.setOptions({physics: false}); }") %>%
    visInteraction(hover = TRUE, hoverConnectedEdges = FALSE) %>%
    visOptions(highlightNearest = TRUE) %>%
    visEvents(click = "function(properties) {
      if(properties.nodes.length > 0) {
        Shiny.setInputValue('node_canvas_click', properties.nodes[0], {priority: 'event'});
      } else {
        Shiny.setInputValue('empty_canvas_click', true, {priority: 'event'});
      }
    }")
})
