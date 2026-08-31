#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
	echo "Argumentos inválidos. Uso: $0 <directorio>"
	echo "Cantidad de argumentos inválida" >&2
	exit 1
fi

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	echo "Uso: $0 <directorio>"
	exit 0
fi

if [ ! -d "$1" ]; then
	echo "No existe el directorio $1" >&2
	exit 2
fi

cantidad=0
cantidad_vacios=0
peso=0
peso_promedio=0
fecha=$(date '+%Y-%m-%d %H:%M:%S')

for archivo in "$1"/*; do
	if [ -f "$archivo" ] && [ "${archivo%%.*}" != "" ]; then
		if [ -s "$archivo" ]; then
			cantidad=$(($cantidad + 1))
			peso=$(($peso + $(wc -c < "$archivo")))
		else
			cantidad=$(($cantidad + 1))
			cantidad_vacios=$(($cantidad_vacios + 1))
		fi
	fi
done

if [ "$cantidad" -ne 0 ]; then
	peso_promedio=$(($peso / $cantidad))
fi

cat << EOF > reporte.txt
===========================================================
REPORTE DE DIRECTORIO
-----------------------------------------------------------
Generado por  : $USER
Fecha y hora  : $fecha
Directorio    : $1
-----------------------------------------------------------
Archivos totales     : $cantidad
Archivos vacios	     : $cantidad_vacios
Tamaño total (bytes) : $peso
Tamaño promedio      : $peso_promedio bytes por archivo
===========================================================
EOF

cat << EOF
Reporte generado en reporte.txt
EOF

exit 0
