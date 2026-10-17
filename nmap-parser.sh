#!/bin/bash

#este programa parsea los resultados de namp y construye un doc html
TITULO="Resultados nmap"
FECHA_ACTUAL="$(date)"
TIMESTAMP="Informe generado el $FECHA_ACTUAL por el usuario $(id -un)"

#Con este ajuste se comprueba si nmap funciono
nmap_exec () {
    echo "[INFO] Ejecutando nmap en la subred $1, por favor espere unos segundos..."
    # La redirección la hace el usuario (no root) a propósito: así el .raw es nuestro y no de root
    # shellcheck disable=SC2024
    if sudo nmap -sV "$1" > "$2"; then
        echo "[OK] Fichero $2 generado correctamente"
    else
        echo "[ERROR] nmap ha fallado. Revisa la red indicada y tus permisos de sudo" >&2
        rm -f "$2"    # no dejamos un .raw a medias que parezca reciente
        exit 1
    fi
}

#anadimos la funcion escanear  y dividir
escanear_y_dividir () {
    # Generamos el reporte raw con nmap
    nmap_exec "$1" "$2"
    # Borramos los trozos de ejecuciones anteriores y dividimos el fichero por líneas vacías
    echo "[INFO] Dividiendo el fichero $2 ..."
    rm -f xx*
    csplit "$2" '/^$/' '{*}' > /dev/null
    echo "[OK] Fichero $2 dividido en:" xx*
}


#ajuste de argumentos, asi se que debo colocar como argumentos

uso () {
    echo "Uso: $0 <ip[/máscara]> <salida.raw> <informe.html>" >&2
    echo "Ej.: $0 192.168.179.131/24 salida_nmap.raw resultados.html" >&2
    exit 1
}

# Validación 1: exactamente 3 argumentos
if [ $# -ne 3 ]; then
    echo "[ERROR] Se esperaban 3 argumentos y has escrito $#" >&2
    uso
fi

# Validación 2: el primer argumento solo puede ser una IP con máscara opcional (allowlist)
patron_red='^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'
if [[ ! $1 =~ $patron_red ]]; then
    echo "[ERROR] '$1' no es una IP o red válida (ej.: 192.168.179.0/24)" >&2
    uso
fi


# Importamos el fichero que genera el reporte HTML (lo buscamos junto al propio script)
source "$(dirname "$0")/html_report.sh" || { echo "[ERROR] No se encuentra html_report.sh junto a $0" >&2; exit 1; }


#corregimos el eroor de la duplicacion
if [ -n "$(find "$2" -mmin -30 2>/dev/null)" ]; then
    while true; do
        read -r -p "existe $2 con antiguedad menor a 30 minutos. sobreescribir? [y/n]: "
                case "$REPLY" in
            [yY]) escanear_y_dividir "$1" "$2"
                  break
                  ;;
            [nN]) echo "[INFO] utilizando el fichero $2 existente"
                  break
                  ;;
            *)    echo "[INFO] Respuesta no válida: escribe y o n"
                  ;;
        esac
    done
else
    escanear_y_dividir "$1" "$2"
fi


# Generamos el reporte con los resultados de nmap en HTML
echo "[INFO] Generando reporte html..."
if generar_html > "$3"; then
    echo "[OK] Reporte $3 generado correctamente"
else
    echo "[ERROR] No se pudo generar $3" >&2
    exit 1
fi
