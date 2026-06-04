# ==============================================================================
# SUBMÓDULO: Algoritmo Espectral de Alon, Krivelevich y Sudakov (1998)
# Misión: Implementar la detección de cliques ocultos mediante la descomposición
#         en vectores propios de la matriz de adyacencia.
# ==============================================================================

# ----------------------------------------------------------------------------
# 1. IMPLANTACIÓN DE UN CLIQUE (BACKEND Y FRONTEND PROXY)
# ----------------------------------------------------------------------------
observeEvent(input$plant_random_clique_btn, {
  req(v$nodes)
  k <- input$clique_size
  active_pivot(NULL)

  all_node_ids <- v$nodes$id
  chosen_nodes <- sample(all_node_ids, k) # Muestreo sin reemplazo
  planted_nodes_list(chosen_nodes)        # Almacenamos el "Ground Truth"

  # Generar todas las aristas inducidas (K_k)
  combinations <- combn(chosen_nodes, 2)
  new_edges <- data.frame(
    from = as.character(combinations[1, ]), to = as.character(combinations[2, ]),
    smooth = FALSE, color = "#00CC44", width = 2, stringsAsFactors = FALSE
  )
  new_edges$id <- paste0(new_edges$from, "-", new_edges$to)

  # Evitar duplicar aristas preexistentes
  existing_edges <- v$edges
  if (nrow(existing_edges) > 0) {
    new_edges <- new_edges %>%
      anti_join(existing_edges, by = c("from", "to")) %>%
      anti_join(existing_edges, by = c("from" = "to", "to" = "from"))
  }

  if (nrow(new_edges) > 0) {
    v$edges <- bind_rows(v$edges, new_edges)

    # Marcamos en verde los nodos implantados en el lienzo mediante proxy
    nodes_update <- data.frame(
      id = chosen_nodes, color.background = "#D6F5D6", color.border = "#00CC44", borderWidth = 2, stringsAsFactors = FALSE
    )

    visNetworkProxy("network_plot") %>%
      visUpdateEdges(edges = new_edges) %>%
      visUpdateNodes(nodes = nodes_update) %>%
      visUnselectAll()

    v$matrix_trigger <- v$matrix_trigger + 1
    showNotification(paste("Se implantó un clique de tamaño", k), type = "message")
  }
})

# ----------------------------------------------------------------------------
# 2. ALGORITMO ESPECTRAL DE ALON ET AL. (1998)
# ----------------------------------------------------------------------------
observeEvent(input$run_clique_btn, {
  req(v$nodes)

  # Bloqueamos banderas reactivas de ejecución
  algo_running(TRUE)
  found_nodes_list(NULL)

  # Inicializamos logs en la consola virtual
  txt <- ">> [ALGORITMO] Iniciando Detección Espectral (Alon, Krivelevich & Sudakov, 1998)...\n"
  txt <- paste0(txt, ">> [PASO 1] Construyendo Matriz de Adyacencia A...\n")
  algo_logs(txt)
  Sys.sleep(1)

  # --- PASO 1: Obtención de la Matriz de Adyacencia Real de los datos ---
  # Reconstruimos la matriz simétrica pura del estado actual de la app (v$nodes y v$edges)
  node_ids <- sort(as.integer(v$nodes$id))
  n <- length(node_ids)

  # Inicializar matriz vacía
  A <- matrix(0, nrow = n, ncol = n, dimnames = list(node_ids, node_ids))

  # Rellenar con las aristas existentes
  if (!is.null(v$edges) && nrow(v$edges) > 0) {
    for (i in 1:nrow(v$edges)) {
      f <- as.character(v$edges$from[i])
      t <- as.character(v$edges$to[i])
      A[f, t] <- 1
      A[t, f] <- 1
    }
  }

  message("matriz de adyacencia pronta") #####>>>>
  message(A)                             #####>>>>

  txt <- paste0(algo_logs(), ">> [PASO 2] Ejecutando Descomposición Espectral (Eigen-decomposition)...\n")
  algo_logs(txt)
  Sys.sleep(0.2)

  # --- PASO 2: Computar el segundo vector propio de A ---
  # eigen() devuelve los valores y vectores ordenados decrecientemente por valor propio
  ev <- eigen(A, symmetric = TRUE)

  message(
    paste0("EIGEN encontrados:",ncol(ev$vectors))
  ) #####>>>>

  # Validamos existencia de un segundo componente espectral
  if (ncol(ev$vectors) < 2) {
    algo_logs(paste0(algo_logs(), ">> [ERROR] No hay suficientes componentes espectrales.\n"))
    algo_running(FALSE)
    return()
  }

  # Extraemos el segundo vector propio u2
  u2 <- ev$vectors[, 2]
  names(u2) <- node_ids # Mapeamos nombres de nodos a los componentes

  message("Segundo EIGEN")
  message(u2)      #####>>>>

  txt <- paste0(algo_logs(), ">> [PASO 3] Analizando magnitudes del segundo vector propio u2...\n")
  algo_logs(txt)
  Sys.sleep(0.2)

  # --- PASO 3: Selección de los k vértices de mayor magnitud ---
  # El tamaño k del clique objetivo se extrae del slider de la UI o se estima
  k_target <- input$clique_size

  # Ordenar por valor absoluto (magnitud de la perturbación espectral) de mayor a menor
  u2_abs_sorted <- sort(abs(u2), decreasing = TRUE)

  # Seleccionar las primeras k etiquetas de nodos de mayor magnitud
  U_nodes <- names(u2_abs_sorted)[1:k_target]

  txt <- paste0(algo_logs(), ">> Subconjunto espectral inicial U localizado (k=", k_target, ").\n")
  txt <- paste0(txt, ">> [PASO 4] Iniciando fase de limpieza (3/4 * k vecinos en U)...\n")
  algo_logs(txt)
  Sys.sleep(0.2)

  # --- PASO 4: Fase de Extensión / Limpieza (Voto de Vecindad) ---
  Q_nodes <- character() # Nos aseguramos de que empiece como un vector de caracteres vacío
  umbral_vecinos <- ceiling((3 / 4) * k_target)

  for (node in as.character(node_ids)) {
    # Forzamos a que las consultas de matriz usen caracteres para los nombres de las filas
    vecinos_nodo <- names(which(A[as.character(node), ] == 1))

    # Contar cuántos vecinos están en el subconjunto espectral U
    conteo_en_U <- sum(vecinos_nodo %in% U_nodes)

    if (conteo_en_U >= umbral_vecinos) {
      Q_nodes <- c(Q_nodes, as.character(node)) # CASADO FORZADO A CHARACTER
    }
  }

  # Guardamos el resultado del clique recuperado en el estado
  found_nodes_list(Q_nodes)

  message("RESULTADO:")
  message(Q_nodes)

  # --- FINALIZACIÓN Y FEEDBACK VISUAL ---
  ground_truth <- planted_nodes_list()
  if (!is.null(ground_truth)) {
    # Forzamos a que ambos vectores sean caracteres antes de ordenarlos para la comparativa
    exito <- length(Q_nodes) == length(ground_truth) && all(sort(as.character(Q_nodes)) == sort(as.character(ground_truth)))
    if (exito) {
      txt <- paste0(algo_logs(), ">> [ÉXITO] ¡Clique Oculto recuperado de forma exacta!\n")
    } else {
      txt <- paste0(algo_logs(), ">> [AVISO] Detección completada. Se halló una estructura densa alternativa.\n")
    }
  } else {
    txt <- paste0(algo_logs(), ">> [FIN] Proceso terminado sobre topología empírica.\n")
  }
  algo_logs(txt)

  # --- ACTUALIZACIÓN CRÍTICA DEL FRONTEND MEDIANTE PROXY ---
  # 1. Resetear la estética de todos los nodos al color azul/gris original
  nodes_reset <- data.frame(
    id = as.character(v$nodes$id), # Forzado a character
    color.background = "#97C2FC",
    color.border = "#2B7CE9",
    borderWidth = 1,
    stringsAsFactors = FALSE
  )
  visNetworkProxy("network_plot") %>% visUpdateNodes(nodes = nodes_reset)

  # 2. Si el algoritmo recuperó nodos, pintarlos inmediatamente de naranja
  if (length(Q_nodes) > 0) {
    nodes_update <- data.frame(
      id = as.character(Q_nodes), # SOLUCIÓN: Forzado estricto a character para Javascript
      color.background = "#FFBB99",
      color.border = "#FF5500",
      borderWidth = 2,
      stringsAsFactors = FALSE
    )
    # Enviamos la actualización limpia al navegador
    visNetworkProxy("network_plot") %>% visUpdateNodes(nodes = nodes_update)
  }

  algo_running(FALSE)
})

# ----------------------------------------------------------------------------
# 3. INTERFACES DINÁMICAS DE RENDIMIENTO
# ----------------------------------------------------------------------------
output$planted_clique_ui <- renderUI({
  nodes <- planted_nodes_list()
  if(is.null(nodes)) return(NULL)
  div(class = "clique-box", paste("Planted Ground Truth: { ", paste(nodes, collapse = ", "), " }"))
})

output$algorithm_monitor_ui <- renderUI({
  if(!algo_running() && nchar(algo_logs()) == 0) return(NULL)

  final_result_panel = NULL
  nodes <- found_nodes_list()
  if(!is.null(nodes)) {
    final_result_panel <- tagList(
      h5(tags$b("Estimación de Q (Clique Recuperado):")),
      div(class = "search-box", paste("{ ", paste(nodes, collapse = ", "), " }"))
    )
  }

  tagList(
    br(),
    h5(tags$b("Consola Espectral (Alon et al. 1998):")),
    tags$pre(class = "algo-console", algo_logs()),
    final_result_panel
  )
})
