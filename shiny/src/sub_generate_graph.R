# src/sub_generate_graph.R

observeEvent(input$btn_generate_graph, {
  n <- input$num_vertices
  p <- input$prob_p

  # Generación estocástica del modelo Erdős-Rényi
  g <- igraph::sample_gnp(n, p, directed = FALSE, loops = FALSE)

  nodes_df <- data.frame(
    id = 1:n,
    label = as.character(1:n),
    color = "#97c2fc",
    size = 15,
    font.size = 20,
    stringsAsFactors = FALSE
  )

  edges_list <- igraph::as_data_frame(g, what = "edges")
  if (nrow(edges_list) > 0) {
    edges_df <- data.frame(
      from = edges_list$from,
      to = edges_list$to,
      color = "#cccccc",
      width = 1,
      id = paste0(pmin(edges_list$from, edges_list$to), "-", pmax(edges_list$from, edges_list$to)),
      stringsAsFactors = FALSE
    )
  } else {
    edges_df <- data.frame(from = integer(0), to = integer(0), color = character(0), width = numeric(0), id = character(0), stringsAsFactors = FALSE)
  }

  v$nodes <- nodes_df
  v$edges <- edges_df

  if (is.null(v$graph_init_trigger)) {
    v$graph_init_trigger <- 1
  } else {
    v$graph_init_trigger <- v$graph_init_trigger + 1
  }

  active_pivot(NULL)
  planted_nodes_list(integer(0))
  found_nodes_list(integer(0))
  algo_running(FALSE)
  algo_logs(sprintf("Grafo G(n=%d, p=%.2f) instanciado. Aristas iniciales: %d.", n, p, nrow(edges_df)))

  v$matrix_trigger <- v$matrix_trigger + 1
}, ignoreNULL = FALSE)

output$network_plot <- renderVisNetwork({
  req(v$graph_init_trigger)

  isolate({
    req(v$nodes, v$edges)

    # Cómputo matricial de física adaptativa para mitigar la aglomeración central
    n_scale <- nrow(v$nodes)
    computed_repulsion <- -15000 - (300 * n_scale) # Repulsión escalar agresiva
    computed_gravity   <- max(0.001, 0.04 - (0.00006 * n_scale)) # Desvanecimiento de la gravedad central
    computed_spring    <- 180 + (0.8 * n_scale) # Expansión lineal de la longitud de las aristas

    visNetwork(v$nodes, v$edges) %>%
      visNodes(shape = "dot") %>%
      visEdges(smooth = FALSE) %>%
      visPhysics(
        solver = "barnesHut",
        barnesHut = list(
          gravitationalConstant = computed_repulsion,
          centralGravity = computed_gravity,
          springLength = computed_spring,
          springConstant = 0.012
        ),
        stabilization = list(enabled = TRUE, iterations = 150)
      ) %>%
      visEvents(
        stabilizationIterationsDone = "function() { this.setOptions( { physics: false } ); }",
        click = "function(nodes) { Shiny.onInputChange('network_plot_click', nodes); }",
        doubleClick = "function(nodes) { Shiny.onInputChange('network_plot_dblclick', nodes); }"
      ) %>%
      visOptions(highlightNearest = FALSE)
  })
})

observeEvent(input$network_plot_dblclick, {
  node_id <- input$network_plot_dblclick$nodes
  if (length(node_id) > 0) {
    node_id <- as.integer(node_id[[1]])

    v$nodes <- v$nodes[v$nodes$id != node_id, ]
    v$edges <- v$edges[!(v$edges$from == node_id | v$edges$to == node_id), ]

    visNetworkProxy("network_plot") %>% visRemoveNodes(node_id)
    v$matrix_trigger <- v$matrix_trigger + 1
  }
})
