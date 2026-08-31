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

archivos=0
categorias=""

for archivo in "$1"/*; do
	if [ -f "$archivo" ] &&
	   [ "${archivo%%.*}" != "" ]; then
		nombre="${archivo%%.*}"
		extension="${archivo##*.}"
		categoria="${extension,,}"
		archivos=$((archivos + 1))
		
		if [ "$(grep "\." <<< "$(basename "$archivo")")" != "" ]; then
			if ! grep -qx "$categoria" <<< "$categorias"; then
				categorias="$categorias$categoria"$'\n'
			fi

			mkdir -p "$1"/"$categoria"/
			mv "$archivo" "$1"/"$categoria"/
		else
			mkdir -p "$1"/"sin_extension"/
			mv "$archivo" "$1"/"sin_extension"/
		fi
	fi
done

categorias="$(sort <<< $categorias)"
lista_categorias=""

for categoria in $(echo "$categorias"); do
	lista_categorias="$lista_categorias$categoria "
done

cat << EOF
Archivos organizados: $archivos
Categorías: $lista_categorias
EOF

exit 0
