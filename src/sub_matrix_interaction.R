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

# Renderizado de la matriz de calor discreta binaria (ggplot2)
output$adjacency_bitmap_plot <- renderPlot({
  v$matrix_trigger
  req(v$nodes)

  node_ids <- as.integer(v$nodes$id)
  grid_data <- expand.grid(X = node_ids, Y = node_ids) %>% mutate(Conectado = "0")

  edges_df <- v$edges
  if (!is.null(edges_df) && nrow(edges_df) > 0) {
    e_from <- as.integer(edges_df$from)
    e_to <- as.integer(edges_df$to)

    hash_grid <- paste(grid_data$X, grid_data$Y, sep = "-")
    hash_edges_1 <- paste(e_from, e_to, sep = "-")
    hash_edges_2 <- paste(e_to, e_from, sep = "-")

    grid_data$Conectado[hash_grid %in% hash_edges_1 | hash_grid %in% hash_edges_2] <- "1"
  }

  grid_data$Conectado[grid_data$X == grid_data$Y] <- "0"

  ggplot(grid_data, aes(x = factor(X), y = factor(Y, levels = rev(sort(node_ids))), fill = Conectado)) +
    geom_tile(color = "#E0E0E0", linewidth = 0.2) +
    scale_fill_manual(values = c("0" = "#FFFFFF", "1" = "#000000"), guide = "none") +
    labs(x = "ID de Vértice (Eje X)", y = "ID de Vértice (Eje Y)") +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, family = "monospace", size = 8),
      axis.text.y = element_text(family = "monospace", size = 8),
      panel.grid = element_blank(),
      axis.ticks = element_line(color = "#888888")
    )
})
