# ==============================================================================
# SUBMÓDULO: Interacción Directa sobre el Lienzo de Red (Modo Pivote)
# ==============================================================================

# Manejo del clic sobre un vértice específico de la red
observeEvent(input$node_canvas_click, {
  clicked <- as.character(input$node_canvas_click)
  current_pivot <- active_pivot()

  if (is.null(current_pivot)) {
    # Activar Pivote
    active_pivot(clicked)
    visNetworkProxy("network_plot") %>%
      visUpdateNodes(nodes = data.frame(id = clicked, color.background = "#00FF66", color.border = "#000000")) %>%
      visSelectNodes(id = clicked)

  } else {
    if (clicked != current_pivot) {
      # Conectar Vértice Secundario con Pivote
      edge_match <- v$edges %>%
        filter((from == current_pivot & to == clicked) | (from == clicked & to == current_pivot))

      if (nrow(edge_match) == 0) {
        new_id <- paste0(current_pivot, "-", clicked)
        new_edge <- data.frame(id = new_id, from = current_pivot, to = clicked, smooth = FALSE,
                               color = "#848484", width = 1, stringsAsFactors = FALSE)
        v$edges <- bind_rows(v$edges, new_edge)

        visNetworkProxy("network_plot") %>% visUpdateEdges(edges = new_edge)
        v$matrix_trigger <- v$matrix_trigger + 1
      }
      visNetworkProxy("network_plot") %>% visSelectNodes(id = current_pivot)

    } else {
      # Auto-clic apaga el pivote
      visNetworkProxy("network_plot") %>%
        visUpdateNodes(nodes = data.frame(id = clicked, color.background = "#97C2FC", color.border = "#2B7CE9")) %>%
        visUnselectAll()
      active_pivot(NULL)
    }
  }
})

# Clic en el fondo del lienzo desactiva el pivote
observeEvent(input$empty_canvas_click, {
  old_pivot <- active_pivot()
  if (!is.null(old_pivot)) {
    visNetworkProxy("network_plot") %>%
      visUpdateNodes(nodes = data.frame(id = old_pivot, color.background = "#97C2FC", color.border = "#2B7CE9")) %>%
      visUnselectAll()
    active_pivot(NULL)
  }
})

# Texto de estado del pivote
output$pivot_status <- renderText({
  pivot <- active_pivot()
  if(is.null(pivot)) "Pivote: Ninguno" else paste("Pivote: ", pivot)
})
