#!/bin/bash

# Directorio de trabajo
REPORT_DIR="$HOME/Auditoria_WiFi"
mkdir -p "$REPORT_DIR"

# Función de notificación
notify() {
    notify-send "WiFi Lab" "$1" -i network-wireless
}

# --- MONITOREO EN TIEMPO REAL ---
monitor_salud() {
    local ip_ap=$1
    local duracion=$2
    echo -e "\e[1;33m[!] Monitor de Salud activo para: $ip_ap\e[0m"
    echo "Segundo | Latencia"
    for i in $(seq 1 $duracion); do
        LAT=$(ping -c 1 -W 1 $ip_ap | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
        if [ -z "$LAT" ]; then
            echo -e "$i seg | TIMEOUT"; echo "$i 1000" >> "$REPORT_DIR/puntos.dat"
        else
            echo -e "$i seg | $LAT ms"; echo "$i $LAT" >> "$REPORT_DIR/puntos.dat"
        fi
        sleep 1
    done
}

# --- GENERACIÓN DE GRÁFICO ---
generar_grafico() {
    local salida_png="$REPORT_DIR/grafico_$(date +%H%M).png"
    gnuplot << EOF
        set terminal png size 800,400 background rgb '#121212'
        set output '$salida_png'
        set title "Impacto de Saturación" tc rgb 'white'
        set xlabel "Segundos" tc rgb 'white'
        set ylabel "Latencia (ms)" tc rgb 'white'
        set border lc rgb 'white'
        set grid lc rgb '#333333'
        set style line 1 lc rgb '#00ff00' lw 2
        plot "$REPORT_DIR/puntos.dat" with lines ls 1 title "Respuesta AP"
EOF
    viewnior "$salida_png" & 
}

# --- MENÚ PRINCIPAL ---
while true; do
    ACCION=$(zenity --list --title="WiFi Audit Lab v2.0" \
        --column="ID" --column="Prueba" --width=400 --height=350 \
        1 "Activar Modo Monitor" \
        2 "Prueba de Estrés + Monitor + Gráfico" \
        3 "Limpiar Datos" 4 "Salir")

    case $ACCION in
        1) pkexec airmon-ng start wlan0 ;;
        2)
            BSSID=$(zenity --entry --text="BSSID (MAC):")
            IP_AP=$(zenity --entry --text="IP Router:" --entry-text="192.168.1.1")
            TIEMPO=$(zenity --scale --text="Segundos:" --min-value=10 --max-value=120 --value=30)
            echo "# Seg Lat" > "$REPORT_DIR/puntos.dat"
            gnome-terminal --title="MONITOR" -- bash -c "$(declare -f monitor_salud); monitor_salud $IP_AP $TIEMPO; exec bash" &
            ( mdk4 wlan0mon d -b <(echo $BSSID) -c 6 & PID=$!; sleep $TIEMPO; kill $PID ) | zenity --progress --auto-close
            generar_grafico
            ;;
        3) rm -rf "$REPORT_DIR"/*.dat "$REPORT_DIR"/*.png ;;
        4) break ;;
    esac
done
