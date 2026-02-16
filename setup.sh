#!/bin/bash
echo "[+] Instalando dependencias necesarias..."
sudo apt update
sudo apt install mdk4 zenity aircrack-ng gnuplot viewnior libnotify-bin -y
chmod +x wifi_audit_pro.sh
echo "[+] Configuración terminada."
