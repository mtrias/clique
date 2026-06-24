# Problema de Recuperacion de un Clique Implantado

El Problema del Clique Implantado (Planted Clique Problem) consiste en tomar un grafo base estructurado bajo el modelo de Erdős-Rényi `G(n, p)` (en nuestro caso `p=0.5`) e incrustar artificialmente en él un subgrafo completamente conectado (un clique) de tamaño `k`. El desafío fundamental radica en que, en la matriz de adyacencia desordenada, las conexiones del clique se camuflan dentro del "ruido" estadístico de las aristas aleatorias.

Identificar cuáles son exactamente esos `k` vértices ocultos entre los `n` totales es un problema computacionalmente prohibitivo (NP) si se intenta resolver mediante búsqueda combinatoria o fuerza bruta.

Para sortear esta complejidad algorítmica, estudiamos una solución directa basada en el álgebra lineal espectral. En lugar de analizar la red nodo por nodo, extraemos el vector propio principal derivado de la matriz de adyacencia para evaluar la centralidad espectral. Dado que los vértices del clique están densamente interconectados entre sí (además de poseer sus conexiones aleatorias normales), su grado topológico se eleva significativamente por encima de la media del grafo, acaparando la mayor magnitud en las coordenadas del vector propio. Al aislar el valor absoluto de estas coordenadas y rankear los vértices, logramos separar limpiamente la anomalía del ruido de fondo, demostrando de forma analítica y visual cómo las propiedades algebraicas de la matriz delatan la topología oculta de la red.

## Contenido

**Aplicación Shiny para visualizar el algoritmo espectral de Alon para hallar un clique en un grafo Erdős-Rényi**
<br/> https://miguel-trias.shinyapps.io/clique/
<br/>

**Presentacion Quarto/RevealJS**
<br/> https://mtrias.github.io/clique
<br/>

**Resumen de Estudio**
<br/> https://mtrias.github.io/alnae/
<br/>

## Referencias

Manuel H. (2021). Detección de un k-subgrafo denso en un grafo aleatorio. https://www.fcea.udelar.edu.uy/institucional/agenda/5385-seminario-del-iesta-3.html

Roughgarden, T. (2017). Cs264: Beyond worst-case analysis lectures# 9 and 10: Spectral algorithms for planted bisection and planted clique.

Alon, N., Krivelevich, M., and Sudakov, B. (1998). Finding a large hidden clique in a random graph. Random Structures & Algorithms, 13(3-4):457–466.

Kucera, L. (1995). Expected complexity of graph partitioning problems. Discrete Applied Mathematics, 57(2-3):193–212.11

Lei, J., Rinaldo, A., et al. (2015). Consistency of spectral clustering in stochastic block models. Annals of Statistics, 43(1):215–237.

Lugosi, G. (2017). Lectures on combinatorial statistics. 47th Probability Summer School, Saint-Flour, pages 1–91.

## Descargo de Responsabilidad

**Naturaleza del Proyecto**
<br/>Este repositorio contiene material desarrollado exclusivamente como un proyecto de evaluación estudiantil. No se ofrece ninguna garantía explícita o implícita sobre la exactitud, rigor matemático o correctitud absoluta de las implementaciones ni de las afirmaciones teóricas aquí expuestas.
<br/>

**Autoría Intelectual**
<br/>La propiedad intelectual de los conceptos, algoritmos y desarrollos matemáticos pertenece estrictamente a los profesores del curso y a los autores de los artículos académicos listados en la sección de Referencias. Mi contribución personal se limitó a la recopilación, curaduría y estructuración visual de la información para fines pedagógicos.
<br/>

**Asistencia de IA**
<br/>El código fuente (scripts de R, configuraciones de Quarto y estilos) fue desarrollado y depurado con la asistencia de herramientas de Inteligencia Artificial.
<br/>

**Uso del Material**
<br/>El material compilado en este repositorio puede ser utilizado, reproducido o modificado a total discreción por cualquier usuario. Se recomienda mantener la debida atribución a los autores originales citados en la bibliografía al reutilizar estos conceptos.
<br/>
