# Problema de recuperacion de un clique

El Problema del Clique Implantado (Planted Clique Problem) consiste en tomar un grafo base estructurado bajo el modelo de Erdős-Rényi `G(n, p)` (en nuestro caso `p=0.5`) e incrustar artificialmente en él un subgrafo completamente conectado (un clique) de tamaño `k`. El desafío fundamental radica en que, en la matriz de adyacencia desordenada, las conexiones del clique se camuflan dentro del "ruido" estadístico de las aristas aleatorias.

Identificar cuáles son exactamente esos `k` vértices ocultos entre los `n` totales es un problema computacionalmente prohibitivo si se intenta resolver mediante búsqueda combinatoria o fuerza bruta (NP).

Para sortear esta complejidad algorítmica, estudiamos una solución directa basada en el álgebra lineal espectral. En lugar de analizar la red nodo por nodo, extraemos el vector propio principal derivado de la matriz de adyacencia para evaluar la centralidad espectral. Dado que los vértices del clique están densamente interconectados entre sí (además de poseer sus conexiones aleatorias normales), su grado topológico se eleva significativamente por encima de la media del grafo, acaparando la mayor magnitud en las coordenadas del vector propio. Al aislar el valor absoluto de estas coordenadas y rankear los vértices, logramos separar limpiamente la anomalía del ruido de fondo, demostrando de forma analítica y visual cómo las propiedades algebraicas de la matriz delatan la topología oculta de la red.

## Contenido

- Shiny app para visualizar el algoritmo para hallar un clique en un grafo de Erdős-Rényi
https://miguel-trias.shinyapps.io/clique/

Presentacion Quarto/RevealJS para hablar sobre este problema
https://mtrias.github.io/clique

