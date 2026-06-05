# ==============================================================================
# SUBMÓDULO: Interacción y Renderizado de la Matriz de Adyacencia
# ==============================================================================

# Observador encargado del mapeo continuo-discreto del clic en el Mapa de Bits
observeEvent(input$matrix_click, {
  req(v$nodes)
  req(input$matrix_click$x, input$matrix_click$y)

  node_ids <- sort(as.integer(v$nodes$id))
  click_x_idx <- round(input$matrix_click$x)
  click_y_idx <- round(input$matrix_click$y)

  if(click_x_idx >= 1 && click_x_idx <= length(node_ids) &&
     click_y_idx >= 1 && click_y_idx <= length(node_ids)) {

    node_x <- as.character(node_ids[click_x_idx])
    node_y <- as.character(rev(node_ids)[click_y_idx]) # Reversa por orden invertido de ggplot2

    if (node_x == node_y) {
      showNotification("No se permiten auto-lazos en un grafo simple.", type = "warning")
      return()
    }

    edge_match <- v$edges %>%
      filter((from == node_x & to == node_y) | (from == node_y & to == node_x))

    if (nrow(edge_match) > 0) {
      # Borrado por Proxy
      target_id <- edge_match$id[1]
      v$edges <- v$edges %>% filter(id != target_id)
      visNetworkProxy("network_plot") %>% visRemoveEdges(id = target_id)
      showNotification(paste("Arista eliminada:", node_x, "—", node_y), type = "message")
    } else {
      # Adición por Proxy
      new_id <- paste0(node_x, "-", node_y)
      new_edge <- data.frame(id = new_id, from = node_x, to = node_y, smooth = FALSE,
                             color = "#848484", width = 1, stringsAsFactors = FALSE)
      v$edges <- bind_rows(v$edges, new_edge)
      visNetworkProxy("network_plot") %>% visUpdateEdges(edges = new_edge)
      showNotification(paste("Nueva arista creada:", node_x, "—", node_y), type = "default")
    }

    v$matrix_trigger <- v$matrix_trigger + 1
  }
})

# Requiere la librería Matrix si no está cargada (library(Matrix))
output$adj_matrix_plot <- renderPlot({
  req(v$edges, v$nodes)

  g_actual <- graph_from_data_frame(d = v$edges, vertices = v$nodes, directed = FALSE)
  # Extraer matriz dispersa nativa
  A_sparse <- as_adjacency_matrix(g_actual, sparse = TRUE)

  # Renderizar Spy Plot: aristas como puntos negros, ausencia como blanco
  image(
    A_sparse,
    main = paste("Topología de Adyacencia (", vcount(g_actual), "x", vcount(g_actual), ")"),
    sub = "Los puntos oscuros representan aristas (1). El espacio en blanco es desconexión (0).",
    col.regions = c("white", "#2B7CE9"),
    useRaster = TRUE # useRaster es vital para performance en matrices > 500
  )
})
