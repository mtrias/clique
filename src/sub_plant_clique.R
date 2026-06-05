# ----------------------------------------------------------------------------
# COMPONENTE: IMPLANTACIÓN DE ESTRUCTURA OCULTA (PLANTED CLIQUE)
# ARCHIVO: src/sub_plant_clique.R
# ----------------------------------------------------------------------------
observeEvent(input$plant_random_clique_btn, {
  req(v$nodes)
  k <- input$clique_size
  active_pivot(NULL)

  # Selección aleatoria uniforme de los nodos del clique
  all_node_ids <- as.character(v$nodes$id)
  chosen_nodes <- sample(all_node_ids, k)
  planted_nodes_list(chosen_nodes)

  # Telemetría de inyección en consola R
  cat("\n==================================================\n")
  cat("[LOG] IMPLANTACIÓN DE ESTRUCTURA OCULTA (PLANTED CLIQUE)\n")
  cat("==================================================\n")
  cat(paste("-> Tamaño del Subgrafo Completo (k):", k, "\n"))
  cat(paste("-> Identificadores únicos del Ground Truth:\n   ",
            paste(sort(as.numeric(chosen_nodes)), collapse = ", "), "\n"))

  # 1. Generar la totalidad de combinaciones binarias teóricas del clique K_k
  combinations <- combn(chosen_nodes, 2)
  potential_edges <- data.frame(
    from = as.character(combinations[1, ]),
    to = as.character(combinations[2, ]),
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      u_min = pmin(from, to),
      u_max = pmax(from, to)
    )

  # 2. Normalización indexada de las aristas preexistentes del modelo Erdős-Rényi
  existing_edges <- v$edges
  if (nrow(existing_edges) > 0) {
    existing_normalized <- existing_edges %>%
      mutate(
        u_min = pmin(as.character(from), as.character(to)),
        u_max = pmax(as.character(from), as.character(to))
      )

    # 3. Exclusión exacta de intersecciones simétricas (Evita la duplicación)
    new_edges_filtered <- potential_edges %>%
      anti_join(existing_normalized, by = c("u_min", "u_max"))
  } else {
    new_edges_filtered <- potential_edges
  }

  # 4. Formateo y mutación del estado reactivo global
  if (nrow(new_edges_filtered) > 0) {
    new_edges <- data.frame(
      from = new_edges_filtered$from,
      to = new_edges_filtered$to,
      smooth = FALSE,
      color = "#00CC44",
      width = 2,
      stringsAsFactors = FALSE
    )
    new_edges$id <- paste0(new_edges$from, "-", new_edges$to)

    # Unión indexada al set de datos reactivo
    v$edges <- bind_rows(existing_edges, new_edges)

    # Inyección dinámica de elementos al lienzo sin redibujado total
    visNetworkProxy("network_plot") %>% visUpdateEdges(edges = new_edges)
  }

  cat(paste("-> Aristas reales inyectadas (no preexistentes):", nrow(new_edges_filtered), "\n"))
  cat("==================================================\n\n")
})
