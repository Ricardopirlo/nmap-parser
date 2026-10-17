#!/bin/bash



result_parser () {

    for i in xx*; do
        host_ip=$(grep -E 'Nmap scan report' "$i" | grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}')
        if [ -n "$host_ip" ]; then
            echo "      <tr>"
            echo "        <td>$host_ip</td>"

            # Líneas de puertos abiertos de este host (un solo grep para las dos columnas)
            
            lineas=$(grep -E '^[0-9]{1,5}/(tcp|udp) +open' "$i" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            if [ -n "$lineas" ]; then
                # Campo 1 de cada línea: el puerto
                puertos_abiertos=$(echo "$lineas" | awk '{printf "%s<br>", $1}')
                # Del campo 3 en adelante: servicio y versión
                servicios=$(echo "$lineas" | awk '{$1=$2=""; sub(/^ +/, ""); printf "%s<br>", $0}')
            else
                puertos_abiertos="No hay puertos abiertos"
                servicios="No hay servicios expuestos"
            fi

            echo "        <td>$puertos_abiertos</td>"
            echo "        <td>$servicios</td>"
            echo "      </tr>"
        fi
    done
    return 0

}

generar_html () {
    

cat <<EOF
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>$TITULO</title>
    <style>
      table {
        font-family: arial, sans-serif;
        border-collapse: collapse;
        width: 100%;
      }
 
      td, th {
        border: 1px solid #dddddd;
        text-align: left;
        padding: 8px;
      }
 
      tr:nth-child(even) {
        background-color: #dddddd;
      }
    </style>
  </head>
  <body>
    <h1>$TITULO</h1>
    <p>$TIMESTAMP</p>
 
    <table>
      <tr>
        <th>Host IP</th>
        <th>Puertos abiertos</th>
        <th>Servicio</th>
      </tr>
$(result_parser)
      </table>
  </body>
</html>
EOF
}
