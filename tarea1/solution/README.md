# `analizar_log.sh`

El script se ejecuta corriendo `$ ./analizar_log.sh <ruta al log>`, el script es capaz de identificar si está la cantidad correcta de argumentos y si el archivo indicado existe. Correr `$ ./analizar_log.sh <-h | --help>` despliega instrucciones del uso correcto del script. 

Se decidió extraer primero los códigos http antes de procesar la cantidad de errores para hacer de la implementación más sencilla.

Para determinar la ip_frecuente, primero se extrae el listado de ip's, se cuenta y se extrae el más repetido. El `grep` al final tiene como único trabajo limpiar el string que contiene el contador y la IP usando expresiones regulares y flags de grep. Separa las ocurrencias y la IP en dos lineas distintas.

# `organizar.sh`

El script se ejecuta corriendo `$ ./organizar.sh <directorio>`, maneja los mismos casos que el script anterior, pero verifica la existencia del directorio indicado. `$ ./organizar <-h | --help>` despliega información de uso.

Primero se determina si cada archivo del input es efectivamente un archivo regular, luego se revisa si no es oculto usando globbing, luego se extrae la información relevante y luego se revisa si tiene extensión o no para moverlo a la carpeta correspondiente.

Para determinar si el archivo posee extensión, se usa `grep` para ver si el nombre del archivo tiene un `.`.

Para mantener un registro de las categorías que se han escaneado, usamos un string que tratamos como un set. Cada linea del string corresponde a una categoría y cada vez que escaneamos un archivo, vemos si su categoria está usando `grep -qx`.

Extraemos las categorias para el reporte aplicando un sort y leyendo cada categoria con un ciclo. Armando el string delimitado por espacios descrito en el enunciado.

# `reporte.sh`

El script se ejecuta corriendo `$ ./reporte.sh <directorio>`, maneja los mismos casos que el script anterior. Correr `$ ./reporte.sh <-h | --help>` muestra instrucciones de uso.

Se decidió construir el contenido de `reporte.txt` a mano, hacerlo de forma programática fue lo que se intentó primer y resultó ser mas esfuerzo del que realmente era nescesario.

Usando if's anidados, se revisa que un archivo es precisamente un archivo **y** que el archivo no esté oculto. Luego se revisa si es un archivo vacio o no.

# `backup.sh`

El script se ejecuta corriendo `$ ./backup.sh <directorio a respaldar> [directorio destino]`. El script maneja los casos en que no haya la cantidad correcta de argumentos y revisa si el/los directorios que se le entregan son válidos. El script es capaz de identificar errores si se le entrga solo el directorio a respaldar o si se le entrega un directorio destino. Correr `$ ./backup.sh <-h | --help>` entrega instrucciones de uso.

El script es capaz de manejar rutas absolutas y relativas, construyendo el directorio de salida en función de lo que se le entregue. El directorio de salida siempre acaba siendo una dirección absoluta. 

Para preservar la estructura del directorio a respaldar, se usa la flag `--directory` para que `tar` se *"pare"* en el directorio padre del directorio a respaldar y desde allí empaquetar recursivamente el directorio entregado. La salida del tar es entregada como una ruta absoluta, y es esta ruta del tar la que es reportada al final de la ejecución.
