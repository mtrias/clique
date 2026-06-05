# ----------------------------------------------------------------------------
# COMPONENTE: ALGORITMO ESPECTRAL DE DETECCIÓN CON TELEMETRÍA
# ARCHIVO: src/sub_run_spectral.R
# ----------------------------------------------------------------------------
observeEvent(input$run_clique_btn, {
  req(v$nodes)

  algo_running(TRUE)
  found_nodes_list(NULL)

  # Inicialización de búfer de logs para el frontend
  txt <- ">> [ALGORITMO] Iniciando Detección Espectral Adaptativa...\n"
  algo_logs(txt)

  # --- PASO 1: Reconstrucción Algebraica de la Topología ---
  g_actual <- graph_from_data_frame(d = v$edges, vertices = v$nodes, directed = FALSE)
  A <- as_adjacency_matrix(g_actual, sparse = FALSE)
  node_ids <- rownames(A)
  ground_truth <- as.character(planted_nodes_list())

  # --- PASO 2: Factorización Espectral y Selección de Vector ---
  ev <- eigen(A, symmetric = TRUE)
  u1_dispercion <- sd(abs(ev$vectors[, 1]))

  cat("\n==================================================\n")
  cat("[DIAGNÓSTICO] ANÁLISIS DE MATRIZ ALEATORIA\n")
  cat("==================================================\n")
  cat(paste("-> Desviación Estándar de u1:", round(u1_dispercion, 4), "\n"))

  # Criterio dinámico basado en la dispersión del Perron-Frobenius
  if (u1_dispercion > 0.05) {
    u_target <- ev$vectors[, 1]
    vector_identificado <- "u1 (Modo Dominante)"
  } else {
    u_target <- ev$vectors[, 2]
    vector_identificado <- "u2 (Modo Subestructura)"
  }
  names(u_target) <- node_ids

  txt <- paste0(algo_logs(), ">> [LOG] Selector automático eligió: ", vector_identificado, "\n")
  algo_logs(txt)

  # --- PASO 3: Proyección en el Espacio Vectorial (Truncamiento K) ---
  k_target <- input$clique_size
  u_abs_sorted <- sort(abs(u_target), decreasing = TRUE)
  U_nodes <- names(u_abs_sorted)[1:k_target]

  # Evaluación matemática instantánea del aislamiento de señal
  if (!is.null(ground_truth)) {
    nodos_correctos_en_U <- intersect(U_nodes, ground_truth)
    cat(paste("-> Nodos del Clique Real en conjunto inicial U:",
              length(nodos_correctos_en_U), "de", k_target, "\n"))
    cat(paste("-> Nodos falsos positivos que se colaron en U:",
              paste(setdiff(U_nodes, ground_truth), collapse = ", "), "\n"))
  }

  # --- PASO 4: Fase de Extensión / Limpieza Combinatoria (Q) ---
  Q_nodes <- character()
  umbral_vecinos <- ceiling((3 / 4) * k_target)

  cat(paste("-> Umbral de vecindad requerido para clasificar en Q:", umbral_vecinos, "nodos\n"))
  cat("\n[REVISIÓN DE NODOS DEL CLIQUE REAL]\n")

  for (node in node_ids) {
    vecinos_nodo <- names(which(A[as.character(node), ] == 1))
    conteo_en_U <- sum(vecinos_nodo %in% U_nodes)

    # Telemetría específica para el subconjunto de control (ground truth)
    if (node %in% ground_truth) {
      cat(paste("   Nodo", node, "-> Vecinos dentro de U:", conteo_en_U))
      if (conteo_en_U >= umbral_vecinos) {
        cat(" [PASÓ a Q]\n")
      } else {
        cat(" [RECHAZADO - Falso Negativo]\n")
      }
    }

    if (conteo_en_U >= umbral_vecinos) {
      Q_nodes <- c(Q_nodes, as.character(node))
    }
  }

  found_nodes_list(Q_nodes)

  # --- PASO 5: Mapeo de Convergencia ---
  if (!is.null(ground_truth)) {
    exito <- length(Q_nodes) == length(ground_truth) && all(sort(Q_nodes) == sort(ground_truth))
    if (exito) {
      txt <- paste0(algo_logs(), ">> [ÉXITO] ¡Clique Oculto recuperado de forma exacta!\n")
    } else {
      txt <- paste0(algo_logs(), ">> [AVISO] Detección parcial. Revisa la terminal de R para ver la pérdida de señal.\n")
    }
  }
  algo_logs(txt)

  # --- PASO 6: Sincronización Estética mediante visNetworkProxy ---
  nodes_reset <- data.frame(
    id = as.character(v$nodes$id),
    color.background = "#97C2FC", color.border = "#2B7CE9", borderWidth = 1,
    stringsAsFactors = FALSE
  )
  visNetworkProxy("network_plot") %>% visUpdateNodes(nodes = nodes_reset)

  if (length(Q_nodes) > 0) {
    nodes_update <- data.frame(
      id = as.character(Q_nodes),
      color.background = "#FFBB99", color.border = "#FF5500", borderWidth = 2,
      stringsAsFactors = FALSE
    )
    visNetworkProxy("network_plot") %>% visUpdateNodes(nodes = nodes_update)
  }

  cat("==================================================\n\n")
  algo_running(FALSE)
})
