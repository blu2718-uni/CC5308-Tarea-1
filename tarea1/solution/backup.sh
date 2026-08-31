#!/usr/bin/env bash

if [ "$#" -ne 2 ] && [ "$#" -ne 1 ]; then
	echo "Uso: $0 <directorio> [directorio_destino]"
	echo "Cantidad de argumentos inválida" >&2
	exit 1
fi

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	echo "Uso: $0 <directorio> [directorio_destino]"
	exit 0
fi

if [ ! -d "$1" ]; then
	echo "Directorio a respaldar inválido" >&2
	exit 2
elif [ "$2" != "" ] && [ ! -d "$2" ]; then
	echo "Directorio destino inválido" >&2
	exit 2
fi

directorio_salida=$PWD
nombre_base="$(basename "$1")"
marca_de_tiempo=$(date '+%Y%m%d_%H%M%S')
nombre_tar="backup_${nombre_base}_${marca_de_tiempo}.tar.gz"

if [ "$2" != "" ]; then
	if [[ "$2" = /* ]]; then
		directorio_salida="$2"
	else
		directorio_salida="$directorio_salida/$2"
	fi
fi

tar -czf "$directorio_salida/$nombre_tar" "$1"

cat << EOF
Respaldo creado: $directorio_salida/$nombre_tar
EOF

exit 0
