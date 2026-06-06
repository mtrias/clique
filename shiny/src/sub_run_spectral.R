# src/sub_run_spectral.R

observeEvent(input$btn_run_algo, {
  req(v$nodes, v$edges)

  algo_running(TRUE)
  k <- input$clique_k

  # Generar grafo igraph subyacente para el cómputo matricial
  g_calc <- igraph::graph_from_data_frame(v$edges, directed = FALSE, vertices = v$nodes)
  A <- igraph::as_adjacency_matrix(g_calc, sparse = FALSE) # Matriz densa para eigen() nativo de R base
  n_nodes <- nrow(A)

  current_logs <- c("--- INICIO DE BÚSQUEDA ESPECTRAL (Alon et al.) ---")

  # 1. Descomposición Espectral
  eig <- eigen(A, symmetric = TRUE)
  u1 <- eig$vectors[, 1]
  u2 <- eig$vectors[, 2]

  # !!!DUDA: si ordeno lo por ev, los nodos del clique se ven al final del grafo porque el vector propio -ev es el mismo pero cambiado de sentido. Sin embargo, segun gemini deberia ordenar por abs(ev), pero creo que se equivoca

  # Evaluación empírica de la dispersión de Wigner
  sd_u1 <- sd(abs(u1))
  current_logs <- c(current_logs, sprintf("Dispersión espectral en u1: %.4f", sd_u1))

  if (sd_u1 > 0.05) {
    current_logs <- c(current_logs, "Señal dominante detectada en el primer autovector (u1).")
    target_vector <- abs(u1)
  } else {
    current_logs <- c(current_logs, "Utilizando el segundo autovector (u2) según la cota de la brecha espectral.")
    target_vector <- abs(u2)
  }

  # 2. Selección del subconjunto semilla U (Truncamiento top-k)
  node_indices <- order(target_vector, decreasing = TRUE)[1:k]
  U_nodes <- igraph::V(g_calc)$name[node_indices]

  current_logs <- c(current_logs, sprintf("Fase 1: Conjunto inicial U extraído (tamaño %d).", length(U_nodes)))

  # 3. Fase de Extensión (Limpieza de Falsos Positivos)
  threshold <- ceiling(0.75 * k)
  Q_nodes <- c()

  for (v_name in igraph::V(g_calc)$name) {
    # Extraer vecinos del vértice
    neighbors_v <- as.character(igraph::neighbors(g_calc, v_name)$name)
    # Contar conexiones hacia el conjunto semilla U
    connections_to_U <- length(intersect(neighbors_v, U_nodes))

    if (connections_to_U >= threshold) {
      Q_nodes <- c(Q_nodes, v_name)
    }
  }

  current_logs <- c(current_logs, sprintf("Fase 2: Umbral de conexión hacia U = %d aristas.", threshold))
  current_logs <- c(current_logs, sprintf("Nodos recuperados finales (Conjunto Q): %d", length(Q_nodes)))

  # Convertir a entero para cruce lógico
  found_nodes <- as.integer(Q_nodes)
  found_nodes_list(found_nodes)

  # 4. Actualización visual atómica
  if (length(found_nodes) > 0) {
    # Utilizamos 'color.border' para evitar sobreescribir el 'color.background'
    # de los nodos (ya sean azules originales o verdes si fueron implantados).
    update_nodes_algo <- data.frame(
      id = found_nodes,
      borderWidth = 5,           # Borde engrosado para resaltar
      color.border = "#fd7e14",  # Borde Naranja estricto (Hexadecimal definido en el CSS)
      stringsAsFactors = FALSE
    )

    visNetworkProxy("network_plot") %>% visUpdateNodes(update_nodes_algo)
  }

  algo_logs(current_logs)
})
