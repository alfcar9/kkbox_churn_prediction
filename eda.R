# Instalar en caso de que la computadora no lo tenga 
#install.packages("sparklyr")
#install.packages("dbplot")
#spark_install(version = "2.1.0")

# Cargar bibliotecas 
library(sparklyr)
library(dplyr)
library(ggplot2)
library(dbplot)
library(tidyr)

# Configurar spark
conf <- spark_config()
conf$`sparklyr.cores.local` <- 4
conf$`sparklyr.shell.driver-memory` <- "7G"
conf$spark.memory.fraction <- 0.6

# Crear conexión
sc <- spark_connect(master = "local", 
                    version = "2.1.0",
                    config = conf)

# Verificar configuración en ejecutores
# http://localhost:4040/executors/	

# Abrimos los archivos
setwd("~/Documents/mineria/proyecto") #dirección donde están guardados los archivos
user_log <- sparklyr::spark_read_csv(sc, name="user_log", path="user_logs.csv", memory = FALSE)
trans <- sparklyr::spark_read_csv(sc, name="transactions", path="transactions.csv", memory = FALSE)
members <- sparklyr::spark_read_csv(sc, name="members", path="members_v3.csv", memory = FALSE)
train <- sparklyr::spark_read_csv(sc, name="train", path="train.csv", memory = FALSE)


src_tbls(sc)

## ANALISIS EXPLORATORIO DE DATOS

  ##UNIVARIADO

###user_log basic

summary_data <- user_log %>% 
  group_by(date) %>%
  summarise(count=n(), s=sum(total_secs, na.rm = TRUE), m=mean(total_secs, na.rm = TRUE)) %>%
  collect()

View(summary_data)

user_log %>% 
  dbplot_boxplot(1,total_secs) +
  theme_bw() 

user_log %>% 
  dbplot_bar(num_25) +
  theme_bw()                      
user_log %>% 
  dbplot_bar(num_50) +
  theme_bw() 
user_log %>% 
  dbplot_bar(num_75) +
  theme_bw() 
user_log %>% 
  dbplot_bar(num_985) +
  theme_bw() 
user_log %>% 
  dbplot_bar(num_100) +
  theme_bw() 
  #En todas las gráficas previas se puede ver como la mayoria de los datos son cero. Es decir que la mayoría de los usuarios no han escuchado canciones al 25%, 50%, 75%, 98.5% y 100%. 

user_log %>% 
  dbplot_bar(num_unq) +
  theme_bw() 
  #De igual manera se puede ver como los usuarios no se desvían mucho de sus preferencias y escuchan pocas canciones únicas.


##user_log basic

##user_log less basic
user_log %>%
  count(msno) %>%
  dbplot_bar() +
  theme_bw()

user_log %>% 
  filter(num_25 >= 1) %>% filter(num_25<15000) %>%
  dbplot_bar(num_25) +
  theme_bw()  


##transactions
trans %>% 
  dbplot_histogram(plan_list_price) +
  theme_bw()
trans %>% 
  dbplot_histogram(actual_amount_paid) +
  theme_bw()
  #Las gráficas de "plan list price" y "actual amount paid" se ven bastante similares. En el análisis bivariado veremos si esto es cierto.

trans %>% 
  dbplot_bar(payment_method_id) +
  theme_bw()
  #Hay 41 métodos diferentes de pago, entre ellos, el más usado y por mucho es el método "41".

trans %>% 
  dbplot_bar(payment_plan_days) +
  theme_bw()
  #Payment plan es la duración del plan. por lo que es una variable categórica. La mayoría de los planes dura "30" dias, pero otros datos notables son "0", "7" y "31" dias.

trans %>% 
  dbplot_bar(is_auto_renew) +
  theme_bw()
  #La mayoría de los usuarios tiene sus suscripciones con renovación automática. 
  #En muchos servicios actuales este es el default, sería interesante ver si también para KKBox. Ya que en ese caso esta gráfica indicaría que los usuarios no cambian sus defaults en lugar de que la mayoría de los usuarios escojan poner us suscripción en auto renovación concientemente.

trans %>% 
  dbplot_bar(is_cancel) +
  theme_bw()
  #Muy pocas transacciones son para cancelar el servicio, lo cual tiene mucho sentido cuando (en otra gráfica), ves que la mayoria de los usuarios renueva sus suscripciones.
  #De hecho sería muy extraño que la tasa de cancelaciones fuera más alta.


##members
members %>% 
  dbplot_bar(city) +
  theme_bw() 
  #La mayoría de los usuarios de KKBox provienen de la ciudad "1". La diferencia con cantidades de usuarios provenientes de otras ciudades es notable.

members %>% 
  dbplot_bar(bd) + 
  theme_bw() +
  labs(x = "Edad")
  #La gráfica de edades muestra muchas anomaias en los datos, ya que hay valores menores o iguales a 0 y mayores a 100. Dado que es una grfica áde edades de los usuarios esto no tiene sentido
members %>% 
  filter(bd >0) %>% filter(bd <= 100) %>%
  dbplot_bar(bd) + 
  theme_bw() +
  labs(x = "Edad")
  #Esta es la gráfica cuando se eliminan todos los valores menores o iguales a 0 y mayores a 100. Se puede notar una distribución de cola a la izquierda (es posible que los datos atípicos cerca del 100 también sean errores, pero no hay como saber esto con la información que tenemos).
  #La mayor concentración de edad de los usuarios de KKBox están alrededor de los 25 años.
members %>% 
  filter(bd >0) %>% filter(bd <= 100) %>%
  dbplot_histogram(bd, bins=4) + 
  theme_bw() +
  labs(x = "Edad")
  #Ahora bien, si hacemos a la edad un factor nos quedamos con la gráfia anterior. La mayoría de los usuarios están entre los 20 y 40 años.

members %>% 
  dbplot_bar(gender) +
  theme_bw() 
  #Muchos usuarios de KKBox no reportan su género. De los que si lo reportan, la mayoría son mujeres.

members %>% 
  dbplot_bar(registered_via) +
  theme_bw() 
  #Hay 19 metodos diferentes para registrarse. Donde "4" es el método más popular, seguido de "3" y "9". Hay muchos metodos poco utilizados, como el "1! o el "16".

##train
train %>%
  dbplot_bar(is_churn) +
  theme_bw() 
  #La mayoría de los usuarios no "churn", es decir que renovaron su suscripción. Con esta gráfica tambien se puede ver que se trata de un conjunto de datos muy desbalanceado.

  ##BIVARIADO
trans %>%
  dbplot_raster(plan_list_price, actual_amount_paid) 
  #Como era de esperar por lo visto en el análisis univariado, "actual list price" y "plan list pice" tienen casi una relación lineal. 
  #La única interrogante es la línea vertical en el cero de "plan list price". Esto puede tener que ve con el precio de lista de un "free trial" que sería cero, pero con usuarios que consumen más de lo que esta prueba cubre.

  ##MULTIVARIADO


#pca
pcaT<-trans %>%
  select(-msno) %>%
  ml_pca(k = 2)
View(pcaT)
  #Análisis de Componentes principales de transactions. El primer componente explica el 88% mientras que el segunto componente explica el 11%

pcaU<-user_log%>%
  select(-msno) %>%
  ml_pca(k = 2)
View(pcaM)
  #De acuerdo con el análisis de componentes principales de la tabla de "user_log" hay una sola componente que explica toda la varianza.



