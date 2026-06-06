# src/sub_plant_clique.R

observeEvent(input$btn_plant_clique, {
  req(v$nodes)

  k <- input$clique_k
  available_nodes <- v$nodes$id

  if (length(available_nodes) < k) return()

  target_nodes <- sample(available_nodes, k)
  planted_nodes_list(target_nodes)

  all_clique_edges <- as.data.frame(t(combn(target_nodes, 2)))
  colnames(all_clique_edges) <- c("from", "to")

  all_clique_edges <- all_clique_edges %>%
    mutate(
      u = pmin(from, to),
      v = pmax(from, to)
    )

  current_edges <- v$edges %>%
    mutate(
      u = pmin(from, to),
      v = pmax(from, to)
    )

  # Filtrado de complemento mediante índices ordenados
  missing_edges <- anti_join(all_clique_edges, current_edges, by = c("u", "v")) %>%
    select(from, to) %>%
    mutate(
      color = "#28a745",
      width = 2,
      id = paste0(pmin(from, to), "-", pmax(from, to))
    )

  if (nrow(missing_edges) > 0) {
    v$edges <- bind_rows(v$edges, missing_edges)
    visNetworkProxy("network_plot") %>% visUpdateEdges(missing_edges)

    update_nodes <- data.frame(
      id = target_nodes,
      color = list(background = "#e9f7ef", border = "#28a745"),
      borderWidth = 3
    )
    visNetworkProxy("network_plot") %>% visUpdateNodes(update_nodes)

    v$matrix_trigger <- v$matrix_trigger + 1
  }

  logs <- algo_logs()
  algo_logs(c(logs, sprintf("Clique K_%d incrustado de manera determinista. Aristas agregadas: %d.", k, nrow(missing_edges))))
})

output$planted_clique_ui <- renderUI({
  nodes <- planted_nodes_list()
  if (length(nodes) > 0) {
    div(class = "clique-box",
        tags$b("Nodos del Clique Oculto:"),
        p(paste(sort(nodes), collapse = ", "), style = "word-wrap: break-word; font-size: 0.85em;")
    )
  }
})
