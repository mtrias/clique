# src/sub_network_interaction.R

observeEvent(input$network_plot_click, {
  nodes_clicked <- input$network_plot_click$nodes

  # Sub-rutina interna para homogeneizar y restablecer la estética global
  reset_topology_styles <- function() {
    if (nrow(v$nodes) > 0) {
      nodes_reset <- data.frame(
        id = v$nodes$id,
        color = "#97c2fc",
        borderWidth = 1,
        stringsAsFactors = FALSE
      )
      visNetworkProxy("network_plot") %>% visUpdateNodes(nodes_reset)
    }
    if (nrow(v$edges) > 0) {
      edges_reset <- data.frame(
        id = v$edges$id,
        color = v$edges$color, # Conserva propiedad de coloración base (ej. verde implantado)
        width = v$edges$width,
        stringsAsFactors = FALSE
      )
      visNetworkProxy("network_plot") %>% visUpdateEdges(edges_reset)
    }
  }

  # Caso 0: Clic en el vacío del lienzo -> Apagar entorno de aislamiento
  if (length(nodes_clicked) == 0) {
    if (!is.null(active_pivot())) {
      reset_topology_styles()
      active_pivot(NULL)
    }
    return()
  }

  target_node <- as.integer(nodes_clicked[[1]])
  current_pivot <- active_pivot()

  # Caso 1: No existe pivote previo -> Configurar aislamiento de la Ego-Network
  if (is.null(current_pivot)) {
    active_pivot(target_node)

    # Extraer la vecindad inmediata del subgrafo inducido por el vértice
    connected_edges <- v$edges %>% filter(from == target_node | to == target_node)
    neighbors_ids <- unique(c(connected_edges$from, connected_edges$to))
    neighbors_ids <- setdiff(neighbors_ids, target_node)

    all_node_ids <- v$nodes$id
    non_ego_ids <- setdiff(all_node_ids, c(target_node, neighbors_ids))

    # Actualización estética de nodos por proxy (Atenuación de no-vecinos)
    nodes_update <- data.frame(id = all_node_ids, stringsAsFactors = FALSE)
    nodes_update$color.background <- ifelse(nodes_update$id == target_node, "#39ff14", # Verde neón
                                            ifelse(nodes_update$id %in% neighbors_ids, "#97c2fc", "rgba(220, 220, 220, 0.2)"))
    nodes_update$color.border <- ifelse(nodes_update$id == target_node, "#1d8a0c",
                                        ifelse(nodes_update$id %in% neighbors_ids, "#2b7ce9", "rgba(200, 200, 200, 0.2)"))
    nodes_update$borderWidth <- ifelse(nodes_update$id == target_node, 5, 1) # Bordes anchos para el pivote

    visNetworkProxy("network_plot") %>% visUpdateNodes(nodes_update)

    # Actualización estética de aristas por proxy (Ensombrecimiento exógeno)
    if (nrow(v$edges) > 0) {
      edges_update <- data.frame(id = v$edges$id, stringsAsFactors = FALSE)
      is_incident <- (v$edges$from == target_node | v$edges$to == target_node)

      edges_update$width <- ifelse(is_incident, 4, 1) # Engrosar aristas del pivote
      edges_update$color <- ifelse(is_incident, v$edges$color, "rgba(205, 205, 205, 0.15)")

      visNetworkProxy("network_plot") %>% visUpdateEdges(edges_update)
    }

    # Caso 2: El usuario hace clic sobre el mismo pivote activo -> Desactivación
  } else if (current_pivot == target_node) {
    reset_topology_styles()
    active_pivot(NULL)

    # Caso 3: El usuario hace clic en otro nodo existiendo un pivote -> Adición estable de arista
  } else {
    edge_id <- paste0(pmin(current_pivot, target_node), "-", pmax(current_pivot, target_node))
    edge_exists <- any(v$edges$id == edge_id)

    if (!edge_exists) {
      # Construcción con estilo base idéntico a la red global original
      new_edge <- data.frame(
        from = current_pivot,
        to = target_node,
        color = "#cccccc",
        width = 1,
        id = edge_id,
        stringsAsFactors = FALSE
      )

      # Persistencia no reactiva sobre el backend de datos
      v$edges <- bind_rows(v$edges, new_edge)

      # Forzar visualización inmediata en la UI respetando el grosor del pivote actual (ancho 4)
      new_edge_proxy <- new_edge
      new_edge_proxy$width <- 4

      visNetworkProxy("network_plot") %>% visUpdateEdges(new_edge_proxy)
      v$matrix_trigger <- v$matrix_trigger + 1

      # Iluminar el nodo si se encontraba ensombrecido por no ser vecino previo
      visNetworkProxy("network_plot") %>% visUpdateNodes(data.frame(
        id = target_node,
        color.background = "#97c2fc",
        color.border = "#2b7ce9"
      ))

      logs <- algo_logs()
      algo_logs(c(logs, sprintf("Arista interactiva añadida de forma estable sin redibujado: %d <-> %d", current_pivot, target_node)))
    }
  }
})
