CONX_CLIQUE_NO_ALEATORIO <- c(1,2, 1,3, 1,4, 2,3, 2,4, 3,4, 5,6, 4,6, 5,7, 6,7, 6,8)
CONX_CLIQUE_ALEATORIO <- c(2,5, 2,6, 2,3, 5,6, 3,5, 3,6, 3,7, 4,7, 1,7, 1,4, 1,8)
CONX_GRAFO_SIMPLE <- c(1,3, 1,5, 2,4, 3,6, 4,5, 5,6)


COLOR = "#36499d" #116699

# Fachada para construir grafos
grafo <- function(conexiones) {

  g <- make_graph(conexiones, directed = FALSE)

  # Devolvemos el objeto 'g' de forma invisible
  # para que puedas extraer la matriz de adyacencia después
  invisible(g)
}

imprimirGrafo <- function(grafo) {
  # Eliminar los márgenes base de R (Abajo, Izquierda, Arriba, Derecha)
  par(mar = c(0, 0, 0, 0))
  plot(
    grafo,
    layout = layout_with_kk(g),
    vertex.color = "#e6f2ff",
    vertex.frame.color = COLOR,
    vertex.frame.width = 3,
    vertex.label.color = COLOR,
    vertex.label.family = "sans",
    vertex.size = 25,
    edge.color = COLOR,
    edge.width = 2,
    # Reducir aún más el bounding box interno de igraph
    margin = .1
  )
}

# Extraer la matriz de adyacencia del grafo.
adyacencia <- function(grafo) {
  # Para grafos no dirigidos, esta matriz es obligatoriamente simétrica.
  # Usamos sparse = FALSE porque eigen() base de R requiere matrices densas.
  as_adj(grafo, sparse = TRUE)
}

propios <- function(A) {
  # symmetric = TRUE le indica a LAPACK que use el algoritmo optimizado para
  # matrices simétricas reales, garantizando que los valores propios sean reales (no complejos).
  eigen(A, symmetric = TRUE)
}

imprimirAdyacencia <- function(a, extraInfo="") {
  nFilas <- nrow(a)
  img <- image(
    a,
    main = sprintf("Matriz de Adyacencia (n = %d)", nFilas),
    sub = extraInfo,
    xlab = "",
    ylab = "",

    # TRUE es mas rapido, pero invierte el eje "y" para matrices grandes
    # FALSE es mas lento, no invierte el eje, pero genera un efecto de aliasing
    useRaster = FALSE,

    aspect = "iso",

    # usando useRaster=FALSE, el color es interpolado y no
    col.regions = c("#eeeeee", "#111111"),

    # Define los límites exactos de los intervalos de color
    # necesario para useRaster = FALSE
    at = c(-0.5, 0.5, 1.5),
  )

  # Agrego un latice a matrices "chicas"
  if (nFilas < 40) {
    img <- update(img, panel = function(x, y, z, ...) {
      lattice::panel.levelplot(x, y, z, ...)
      lattice::panel.abline(h = seq(0.5, nFilas + 0.5, by = 1), col = "#d3d3d3", lwd = 0.5)
      lattice::panel.abline(v = seq(0.5, nFilas + 0.5, by = 1), col = "#d3d3d3", lwd = 0.5)
    })
  }

  print(img)
}

# Calcula el número de aristas incidentes para todos los nodos
grados <- function(grafo) {
  degree(grafo, mode = "all")
}

# Imprime un grafico de distribucion de los grados de todos los vertices de un grafo
imprimirDistribucionGrados <- function(grafo, extraTitle="") {
  data.frame(
    Grado = grados(grafo)
  ) |>
    ggplot(aes(x = Grado)) +
    # Se ve mas linda, pero no es la que usa Kucera?
    # agregar al aes: , x=nodo
    # agregar al DF: nodo = 1:vcount(grafo)
    #geom_point(
    #  fill = COLOR,
    #  color = COLOR,
    #  width = 1
    #) +
    geom_bar(
      fill = COLOR,
      color = "white",
      width = 1
    ) +
    #geom_histogram(
    #  fill = COLOR,
    #  color = "white",
    #  binwidth = 5,
    #) +
    labs(
      title = sprintf("Distribución del Grado de los Vértices %s", extraTitle),
      x = element_blank(),
      y = element_blank(),
      #x = "Grado (# conexiones)",
      #y = "Frecuencia (# vértices)"
    ) +
    theme_minimal() +
    theme(
      panel.grid.minor = element_blank()
    )
}

# Fabrica un vector de conexiones de un grafo aleatorio G(n, p=0.5) de Erdős-Rényi
conexiones <- function(n) {
  g <- igraph::sample_gnp(n = n, p = 0.5, directed = FALSE, loops = FALSE)

  # Extraer la lista de aristas como matriz (E x 2)
  # as_edgelist devuelve una matriz donde cada fila es una arista
  matriz_aristas <- igraph::as_edgelist(g, names = FALSE)

  # Aplanar la matriz a un vector de formato c(u1, v1, u2, v2, ...)
  # t() transpone para que as.vector lea fila por fila en lugar de columna por columna
  vector_conexiones <- as.vector(t(matriz_aristas))

  return(vector_conexiones)
}

# Implanta un clique de tamaño k en una posicion aleatoria (TRUE) o en los primeros vertices (FALSE)
implantar <- function(conexiones, k, positionRandom = TRUE) {
  # Inferir el número total de vértices (n) buscando el índice máximo en el vector
  n_nodos <- max(conexiones)

  if (k > n_nodos) {
    stop("El tamaño del clique (k) no puede exceder el número total de vértices (n).")
  }

  # Seleccionar el subconjunto de vértices para el clique
  if (positionRandom) {
    nodos_clique <- sample(1:n_nodos, k)
  } else {
    nodos_clique <- 1:k
  }

  # combn() genera todas las combinaciones posibles (las aristas del clique).
  # Retorna una matriz de 2 x C(k,2). Transponemos para tener formato de lista de aristas (C(k,2) x 2).
  matriz_clique <- t(combn(nodos_clique, 2))

  # Reconstruir la matriz de aristas original a partir del vector
  matriz_orig <- matrix(conexiones, ncol = 2, byrow = TRUE)

  # Estandarización topológica:
  # Para poder detectar si el clique agrega una arista que G(n, 0.5) ya había generado por azar,
  # forzamos a que en cada par de nodos el menor esté a la izquierda y el mayor a la derecha.
  # Usamos pmin y pmax porque están vectorizados en C y son extremadamente rápidos.
  orig_u <- pmin(matriz_orig[, 1], matriz_orig[, 2])
  orig_v <- pmax(matriz_orig[, 1], matriz_orig[, 2])
  matriz_orig <- cbind(orig_u, orig_v)

  clique_u <- pmin(matriz_clique[, 1], matriz_clique[, 2])
  clique_v <- pmax(matriz_clique[, 1], matriz_clique[, 2])
  matriz_clique <- cbind(clique_u, clique_v)

  # Concatenar el grafo base con el clique
  matriz_combinada <- rbind(matriz_orig, matriz_clique)

  # Extraer únicamente los pares de aristas únicos para preservar un grafo simple
  matriz_unica <- unique(matriz_combinada)

  # Aplanar la matriz final de vuelta al formato vectorial c(u1, v1, u2, v2, ...)
  vector_final <- as.vector(t(matriz_unica))

  return(vector_final)
}

# Ordenar los grados de los vértices según su importancia espectral (Vector Propio)
rankingVertices <- function(g, ev) {

  # 1. Obtener el grado topológico de cada vértice del grafo.
  # degree() devuelve un vector numérico con la cantidad de aristas incidentes,
  # indexado por el orden interno de los vértices en la estructura de igraph (del 1 al n).
  vectorGrados <- degree(g)

  # 2. Calcular el ranking (índices) basado en el vector propio.
  # El vector propio principal (ev) derivado de la matriz de adyacencia
  # representa matemáticamente la Centralidad de Vector Propio (Eigenvector Centrality).
  # La función order() no ordena el vector 'ev' per se, sino que retorna un vector con las posiciones
  # originales de los elementos, ordenadas según su valor numérico.
  # Se utiliza decreasing = TRUE para que el vértice más "central" (mayor valor) quede en la posición 1.
  ############
  # DUDA: si ordeno lo por ev, los nodos del clique se ven al final del grafo porque el vector propio -ev es el mismo pero cambiado de sentido. Sin embargo, segun gemini deberia ordenar por abs(ev), pero creo que se equivoca
  indicesOrdenados <- order(ev*(-1), decreasing = TRUE)

  # 3. Aplicar el ranking al vector de grados.
  # Se extraen los valores de 'vectorGrados' siguiendo estrictamente el orden espectral obtenido.
  # Así, el primer elemento del vector resultante será el grado del vértice con la mayor coordenada en 'ev'.
  gradosOrdenados <- vectorGrados[indicesOrdenados]

  return(gradosOrdenados)
}

# Visualizar la relación entre la centralidad espectral y el grado del vértice
graficarRankingVertices <- function(g, ev) {

  # 1. Obtener el vector de grados ordenado algebraicamente llamando a la función anterior.
  gradosRanking <- rankingVertices(g, ev)

  # 2. Estructurar los datos en un data.frame requerido por la gramática de ggplot2.
  # 'Indice' representa la posición en el ranking espectral (eje X).
  # 'Grado' representa el número real de conexiones de ese vértice (eje Y).
  df_ranking <- data.frame(
    Indice = 1:length(gradosRanking),
    Grado = gradosRanking
  )

  # 3. Construir el objeto gráfico subyacente.
  # Se utiliza geom_line() para visualizar la tendencia matemática global de la red.
  # Si el grafo sigue una topología de ley de potencias (redes libres de escala) o tiene un clique
  # fuertemente conectado, la línea mostrará una caída logarítmica o escalonada pronunciada.
  p <- ggplot(df_ranking, aes(x = Indice, y = Grado)) +
    geom_line(color = COLOR, linewidth = .5) +
    labs(
      title = sprintf("Correlación Grado del Vertice segun Espectro (n=%d)", length(gradosRanking)),
      subtitle = "Vértices ordenados descendentemente por coordenada asociada en el Vector Propio",
      x = "Vertices Ordenados por Ranking Espectral en v2",
      y = "Grado del Vértice"
    ) +
    # Permitimos que ggplot calcule los saltos del eje X dinámicamente para evitar superposición de texto
    scale_x_continuous(n.breaks = 10) +
    theme_minimal() +
    theme(
      panel.grid.minor = element_blank(), # Limpia el ruido visual de las líneas fraccionales
      plot.title = element_text(face = "bold")
    )

  # 4. Renderizar el gráfico en el dispositivo activo.
  print(p)
}
