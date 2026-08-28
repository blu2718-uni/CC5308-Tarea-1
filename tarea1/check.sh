#!/usr/bin/env bash
#
# check.sh — Evaluador de la Tarea 1 (CC5308 · Administración de Sistemas Linux)
#
# Evalúa la entrega de un estudiante (archivo .tar.gz / .tgz / .tar / .zip o un
# directorio descomprimido) ejecutando cada utilitario pedido contra casos de
# prueba deterministas y comparando resultados.
#
# Uso:
#   ./check.sh <entrega.tar.gz | entrega.zip | directorio/>
#
# Requisitos del entorno: Ubuntu 24.04 (bash + coreutils + grep + tar). Para
# archivos .zip se requiere `unzip` (o `python3` como respaldo).
#
# Salida: PASS/FAIL por ítem (sin puntaje).

set -u

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------
BASH_BIN="${BASH_BIN:-bash}"
PASSED=0
FAILED=0

# Colores (se desactivan si stdout no es una TTY)
if [ -t 1 ]; then
    C_OK=$'\033[32m'; C_BAD=$'\033[31m'; C_INFO=$'\033[33m'; C_RESET=$'\033[0m'
else
    C_OK=""; C_BAD=""; C_INFO=""; C_RESET=""
fi

pass() { printf '%s[ OK ]%s %s\n' "$C_OK" "$C_RESET" "$*"; }
fail() { printf '%s[FAIL]%s %s\n' "$C_BAD" "$C_RESET" "$*"; }
info() { printf '%s[INFO]%s %s\n' "$C_INFO" "$C_RESET" "$*"; }

# check <descripción> <comando...>
#   Ejecuta <comando...>; muestra PASS si retorna 0, FAIL si no.
check() {
    local desc="$1"
    shift
    if "$@"; then
        pass "$desc"
        PASSED=$((PASSED + 1))
    else
        fail "$desc"
        FAILED=$((FAILED + 1))
    fi
}

# --- utilidades de comparación ----------------------------------------------
num_eq() { [ "$1" -eq "$2" ] 2>/dev/null; }
str_eq() { [ "$1" = "$2" ]; }
nonempty() { [ -n "$1" ]; }

# grab <palabra> <texto>  ->  valor a la derecha del primer ':' de la línea
#                             que contiene <palabra> (sin espacios laterales).
grab() {
    printf '%s\n' "$2" | grep -m1 -- "$1" | sed -E 's/^[^:]*:[[:space:]]*//'
}

# first_int <texto>  ->  primer entero que aparece en <texto>
first_int() {
    printf '%s\n' "$1" | grep -oE '[0-9]+' | head -n1
}

# header_fecha_ok <archivo_reporte>  ->  hay encabezado y una fecha no vacía
header_fecha_ok() {
    local rpt="$1"
    grep -q 'REPORTE DE DIRECTORIO' "$rpt" || return 1
    [ -n "$(grab 'Fecha y hora' "$(cat "$rpt")")" ]
}

# ruta_ok <salida_backup>  ->  "Respaldo creado" apunta a un archivo existente
ruta_ok() {
    local p
    p=$(grab 'Respaldo creado' "$1")
    [ -n "$p" ] && [ -f "$p" ]
}

# backup_content_ok <directorio_extraído>  ->  estructura y contenido íntegros
backup_content_ok() {
    local base="$1"
    [ -f "$base/mi archivo.txt" ] || return 1
    [ -f "$base/docs/nota.txt" ] || return 1
    [ -f "$base/src/app.sh" ] || return 1
    [ "$(cat "$base/mi archivo.txt")" = "hola mundo" ]
}

# ---------------------------------------------------------------------------
# Resolución de la entrega
# ---------------------------------------------------------------------------
INPUT="${1:-./entrega.tar.gz}"

if [ ! -e "$INPUT" ]; then
    printf 'Error: no existe la entrega "%s"\n' "$INPUT" >&2
    exit 2
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK" "$TESTROOT"' EXIT
TESTROOT=$(mktemp -d)

if [ -d "$INPUT" ]; then
    # Se evalúa un directorio ya descomprimido
    cp -r "$INPUT"/. "$WORK"/
else
    case "$INPUT" in
        *.tar.gz|*.tgz|*.tar)
            tar -xf "$INPUT" -C "$WORK" ;;
        *.zip)
            if command -v unzip >/dev/null 2>&1; then
                unzip -q "$INPUT" -d "$WORK"
            elif command -v python3 >/dev/null 2>&1; then
                python3 -m zipfile -e "$INPUT" "$WORK"
            else
                printf 'Error: no hay descompresor de .zip (instala `unzip`)\n' >&2
                exit 2
            fi
            ;;
        *)
            printf 'Error: formato no soportado: %s\n' "$INPUT" >&2
            exit 2 ;;
    esac
fi

find_script() { find "$WORK" -type f -name "$1" 2>/dev/null | head -n1; }

A_LOG=$(find_script 'analizar_log.sh')
ORG=$(find_script 'organizar.sh')
REP=$(find_script 'reporte.sh')
BAK=$(find_script 'backup.sh')

info "Evaluando entrega: $INPUT"
info "Directorio de trabajo: $WORK"

# ---------------------------------------------------------------------------
# Fixtures deterministas
# ---------------------------------------------------------------------------
make_fixtures() {
    # --- access.log (30 peticiones, 7 con error, IP top 192.168.1.10 = 6) ---
    cat > "$TESTROOT/access.log" << 'EOF'
192.168.1.10 - - [20/Oct/2026:09:00:01 -0300] "GET /index.html HTTP/1.1" 200 5234
192.168.1.10 - - [20/Oct/2026:09:00:15 -0300] "GET /css/estilo.css HTTP/1.1" 200 12048
192.168.1.10 - - [20/Oct/2026:09:01:02 -0300] "GET /js/app.js HTTP/1.1" 200 38422
192.168.1.10 - - [20/Oct/2026:09:01:30 -0300] "GET /noexiste.html HTTP/1.1" 404 153
192.168.1.10 - - [20/Oct/2026:09:02:11 -0300] "GET /img/logo.png HTTP/1.1" 200 15234
192.168.1.10 - - [20/Oct/2026:09:02:40 -0300] "GET /contacto HTTP/1.1" 200 894
10.0.0.5 - - [20/Oct/2026:09:03:05 -0300] "GET /index.html HTTP/1.1" 200 5234
10.0.0.5 - - [20/Oct/2026:09:03:22 -0300] "GET /api/estado HTTP/1.1" 200 342
10.0.0.5 - - [20/Oct/2026:09:04:01 -0300] "GET /descargas/manual.pdf HTTP/1.1" 404 153
10.0.0.5 - - [20/Oct/2026:09:04:18 -0300] "GET /faq HTTP/1.1" 200 2101
10.0.0.5 - - [20/Oct/2026:09:04:45 -0300] "GET /img/banner.jpg HTTP/1.1" 200 88111
172.16.0.8 - - [20/Oct/2026:09:05:09 -0300] "GET /index.html HTTP/1.1" 200 5234
172.16.0.8 - - [20/Oct/2026:09:05:33 -0300] "GET /blog/post1 HTTP/1.1" 200 6640
172.16.0.8 - - [20/Oct/2026:09:06:02 -0300] "GET /admin HTTP/1.1" 403 199
172.16.0.8 - - [20/Oct/2026:09:06:20 -0300] "GET /blog/post2 HTTP/1.1" 200 5176
192.168.1.11 - - [20/Oct/2026:09:07:01 -0300] "GET /index.html HTTP/1.1" 200 5234
192.168.1.11 - - [20/Oct/2026:09:07:14 -0300] "GET /css/estilo.css HTTP/1.1" 200 12048
192.168.1.11 - - [20/Oct/2026:09:07:39 -0300] "GET /recursos/antiguo.html HTTP/1.1" 404 153
192.168.1.11 - - [20/Oct/2026:09:08:02 -0300] "GET /perfil HTTP/1.1" 200 1783
10.0.0.7 - - [20/Oct/2026:09:08:26 -0300] "GET /index.html HTTP/1.1" 200 5234
10.0.0.7 - - [20/Oct/2026:09:08:50 -0300] "GET /api/reporte HTTP/1.1" 500 0
10.0.0.7 - - [20/Oct/2026:09:09:11 -0300] "GET /img/logo.png HTTP/1.1" 200 15234
172.16.0.9 - - [20/Oct/2026:09:09:34 -0300] "GET /index.html HTTP/1.1" 200 5234
172.16.0.9 - - [20/Oct/2026:09:10:01 -0300] "GET /blog/post3 HTTP/1.1" 200 7421
172.16.0.9 - - [20/Oct/2026:09:10:29 -0300] "GET /faq HTTP/1.1" 200 2101
192.168.1.12 - - [20/Oct/2026:09:11:05 -0300] "GET /index.html HTTP/1.1" 200 5234
192.168.1.12 - - [20/Oct/2026:09:11:33 -0300] "GET /temp/borrador.html HTTP/1.1" 404 153
192.168.1.12 - - [20/Oct/2026:09:12:08 -0300] "GET /contacto HTTP/1.1" 200 894
10.0.0.6 - - [20/Oct/2026:09:12:40 -0300] "GET /admin HTTP/1.1" 403 199
10.0.0.6 - - [20/Oct/2026:09:13:02 -0300] "GET /index.html HTTP/1.1" 200 5234
EOF

    # --- organizar: archivos variados ---
    mkdir -p "$TESTROOT/org"
    (
        cd "$TESTROOT/org"
        touch nota.txt datos.csv LEEME.md Informe.TXT sin_ext archivo.tar.gz .oculto.txt
        mkdir carpeta
        touch carpeta/dentro.txt
    )

    # --- reporte: 4 archivos (100, 200, 0 y 300 bytes) ---
    mkdir -p "$TESTROOT/rep"
    head -c 100 /dev/zero > "$TESTROOT/rep/a.bin"
    head -c 200 /dev/zero > "$TESTROOT/rep/b.bin"
    : > "$TESTROOT/rep/vacio.txt"
    head -c 300 /dev/zero > "$TESTROOT/rep/c.bin"

    # --- backup: directorio con espacios y archivos anidados ---
    mkdir -p "$TESTROOT/bk/proyecto con espacios/docs" "$TESTROOT/bk/proyecto con espacios/src"
    printf 'hola mundo\n' > "$TESTROOT/bk/proyecto con espacios/mi archivo.txt"
    printf 'nota importante\n' > "$TESTROOT/bk/proyecto con espacios/docs/nota.txt"
    printf '#!/usr/bin/env bash\n' > "$TESTROOT/bk/proyecto con espacios/src/app.sh"
}
make_fixtures

# ---------------------------------------------------------------------------
# A. Formalidades
# ---------------------------------------------------------------------------
echo
info "=== A. Formalidades ==="

check "los 4 scripts están presentes" bash -c '
    [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ]
' _ "$A_LOG" "$ORG" "$REP" "$BAK"

shebang_ok() {
    local s
    for s in "$@"; do
        [ -n "$s" ] || return 1
        head -n1 "$s" | grep -q '^#!.*bash' || return 1
    done
    return 0
}
check "shebang bash en los 4 scripts" shebang_ok "$A_LOG" "$ORG" "$REP" "$BAK"

exec_ok() {
    local s
    for s in "$@"; do
        [ -x "$s" ] || return 1
    done
    return 0
}
check "bit ejecutable en los 4 scripts" exec_ok "$A_LOG" "$ORG" "$REP" "$BAK"

README=$(find "$WORK" -iname 'readme.md' 2>/dev/null | head -n1)
check "README.md presente" test -n "$README"

# ---------------------------------------------------------------------------
# B. analizar_log.sh
# ---------------------------------------------------------------------------
echo
info "=== B. analizar_log.sh ==="

if [ -n "$A_LOG" ]; then
    LOG_OUT=$($BASH_BIN "$A_LOG" "$TESTROOT/access.log" 2>/dev/null)

    check "total de peticiones = 30" \
        num_eq "$(grab 'Total' "$LOG_OUT")" 30
    check "peticiones con error = 7" \
        num_eq "$(grab 'error' "$LOG_OUT")" 7

    ip_ok() {
        case "$1" in
            *192.168.1.10*) : ;;
            *) return 1 ;;
        esac
        printf '%s\n' "$1" | grep -qE '(^|[^0-9])6([^0-9]|$)'
    }
    check "IP con más peticiones = 192.168.1.10 (6)" \
        ip_ok "$(grab 'IP con' "$LOG_OUT")"

    check "direcciones IP únicas = 8" \
        num_eq "$(grab 'Direcciones' "$LOG_OUT")" 8
else
    fail "analizar_log.sh no encontrado"
fi

# ---------------------------------------------------------------------------
# C. organizar.sh
# ---------------------------------------------------------------------------
echo
info "=== C. organizar.sh ==="

if [ -n "$ORG" ]; then
    rm -rf "$TESTROOT/org"
    make_fixtures
    ORG_OUT=$($BASH_BIN "$ORG" "$TESTROOT/org" 2>/dev/null)

    check "nota.txt movido a txt/" test -f "$TESTROOT/org/txt/nota.txt"
    check "Informe.TXT (mayúsculas) movido a txt/" test -f "$TESTROOT/org/txt/Informe.TXT"
    check "LEEME.md movido a md/" test -f "$TESTROOT/org/md/LEEME.md"
    check "datos.csv a csv/ y archivo.tar.gz a gz/" bash -c '
        test -f "$1/csv/datos.csv" && test -f "$1/gz/archivo.tar.gz"
    ' _ "$TESTROOT/org"
    check "sin extensión movido a sin_extension/" test -f "$TESTROOT/org/sin_extension/sin_ext"
    check "ocultos y directorios intactos" bash -c '
        test -f "$1/.oculto.txt" && test -d "$1/carpeta" && test -f "$1/carpeta/dentro.txt"
    ' _ "$TESTROOT/org"
    check "resumen: Archivos organizados = 6" \
        num_eq "$(grab 'Archivos organizados' "$ORG_OUT")" 6
else
    fail "organizar.sh no encontrado"
fi

# ---------------------------------------------------------------------------
# D. reporte.sh
# ---------------------------------------------------------------------------
echo
info "=== D. reporte.sh ==="

if [ -n "$REP" ]; then
    REP_DIR=$(mktemp -d)
    pushd "$REP_DIR" >/dev/null || exit 1
    $BASH_BIN "$REP" "$TESTROOT/rep" 2>/dev/null
    RPT="$REP_DIR/reporte.txt"

    check "reporte.txt generado" test -f "$RPT"
    if [ -f "$RPT" ]; then
        REP_CONTENT=$(cat "$RPT")
        check "archivos totales = 4" \
            num_eq "$(grab 'Archivos totales' "$REP_CONTENT")" 4
        check "tamaño total = 600 bytes" \
            num_eq "$(grab 'Tamaño total' "$REP_CONTENT")" 600
        check "tamaño promedio = 150" \
            num_eq "$(first_int "$(grab 'promedio' "$REP_CONTENT")")" 150
        check "usuario ($USER) reportado" \
            str_eq "$(grab 'Generado por' "$REP_CONTENT")" "$USER"
        check "encabezado + fecha presente (here-doc)" header_fecha_ok "$RPT"
    fi
    popd >/dev/null || exit 1
    rm -rf "$REP_DIR"
else
    fail "reporte.sh no encontrado"
fi

# ---------------------------------------------------------------------------
# E. backup.sh
# ---------------------------------------------------------------------------
echo
info "=== E. backup.sh ==="

if [ -n "$BAK" ]; then
    BAK_DIR=$(mktemp -d)
    pushd "$BAK_DIR" >/dev/null || exit 1
    BAK_OUT=$($BASH_BIN "$BAK" "$TESTROOT/bk/proyecto con espacios" 2>/dev/null)
    NB=$(find "$BAK_DIR" -maxdepth 1 -name 'backup_*.tar.gz' | wc -l)

    check "crea exactamente un backup_*.tar.gz" [ "$NB" -eq 1 ]

    if [ "$NB" -eq 1 ]; then
        TARBALL=$(find "$BAK_DIR" -maxdepth 1 -name 'backup_*.tar.gz' | head -n1)
        mkdir "$BAK_DIR/ext"
        tar -xzf "$TARBALL" -C "$BAK_DIR/ext" 2>/dev/null

        check "contenido íntegro al extraer" backup_content_ok "$BAK_DIR/ext/proyecto con espacios"
    fi

    check "reporta ruta absoluta existente" ruta_ok "$BAK_OUT"
    popd >/dev/null || exit 1
    rm -rf "$BAK_DIR"
else
    fail "backup.sh no encontrado"
fi

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------
echo
info "============================================================="
info " Resultado: $PASSED PASS, $FAILED FAIL"
info "============================================================="

exit 0
