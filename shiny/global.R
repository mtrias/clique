# global.R

# Carga estricta de librerías
library(shiny)
library(visNetwork)
library(igraph)
library(dplyr)

# Para clases dgCMatrix y operaciones dispersas
# Se usa automaticamente al cargar matrices grandes en image()
library(Matrix)

#############################################################
##### IMPORTANTE ############################################
#############################################################
#                                                           #
# Siempre que se agreguen paquetes aqui, hay que actualizar #
# el workflow de github que envia la app a Shiny            #
#                                                           #
#############################################################
