#!/usr/bin/env bash
if [ "$#" -ne 1 ]; then
	echo "Argumentos inválidos. Uso: $0 <ruta al log>"
	echo "Cantidad de argumentos inválida" >&2
	exit 1
fi

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	echo "Uso: $0 <ruta al log>"
	exit 0
fi

if [ ! -f "$1" ]; then
	echo "El archivo $1 no existe" >&2
	exit 2
fi

ruta=$1
total_peticiones=$(wc -l < $ruta)
codigos_http=$(cut -d" " -f9 $1)
total_errores=$(wc -l <<< $(grep -v 200 <<< $codigos_http))
ips=$(cut -d" " -f1 $1)
ip_frecuente=$(grep -oE "[^ ]+" <<< $(head -n 1 <<< $(sort -nr <<< $(uniq -c <<< $ips))))
ip_unicas=$(wc -l <<< $(uniq <<< $ips))

cat << EOF
Total de peticiones: $total_peticiones
Peticiones con error: $total_errores
IP con más peticiones: $(tail -n 1 <<< $ip_frecuente) ($(head -n 1 <<< $ip_frecuente) peticiones)
Direcciones IP únicas: $ip_unicas
EOF

exit 0
