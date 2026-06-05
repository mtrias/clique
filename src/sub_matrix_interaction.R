# src/sub_matrix_interaction.R

output$adj_matrix_plot <- renderPlot({
  req(v$matrix_trigger > 0)

  isolate({
    req(v$nodes, v$edges)
    n_current <- nrow(v$nodes)

    if (nrow(v$edges) == 0 || n_current == 0) {
      plot.new()
      title("Estructura de Adyacencia Vacía")
      return()
    }

    g_temp <- graph_from_data_frame(v$edges, directed = FALSE, vertices = v$nodes)
    adj_sparse <- as_adjacency_matrix(g_temp, sparse = TRUE)

    # aspect = "iso" garantiza que la razón de cambio entre X e Y sea 1:1 (Geometría Cuadrada)
    p_mat <- image(adj_sparse,
                   main = sprintf("Matriz de Adyacencia Dispersa (n = %d)", n_current),
                   sub = "Visualización isométrica basada en Spy Plot",
                   xlab = "Vértices",
                   ylab = "Vértices",
                   useRaster = TRUE,
                   aspect = "iso",
                   col.regions = c("white", "#2c3e50"))

    GRID_THRESHOLD <- 50

    if (n_current < GRID_THRESHOLD) {
      p_mat <- update(p_mat, panel = function(x, y, z, ...) {
        lattice::panel.levelplot(x, y, z, ...)
        lattice::panel.abline(h = seq(0.5, n_current + 0.5, by = 1), col = "#d3d3d3", lwd = 0.5)
        lattice::panel.abline(v = seq(0.5, n_current + 0.5, by = 1), col = "#d3d3d3", lwd = 0.5)
      })
    }

    print(p_mat)
  })
})
