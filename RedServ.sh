#! /usr/local/bin/env bash

# Función para mostrar las interfaces de red y su estado
mostrar_interfaces() {
    echo "Interfaces de red disponibles:"
    paste -d " " <(ip a | grep -E "^[0-9]+:" | sed -E 's/^[0-9]+: ([^:]+).*/\1/') <(ip a | grep "state" | sed -E 's/.*state (\w+).*/\1/')
}

# Función para cambiar el estado de una interfaz
cambiar_estado_interfaz() {
    read -p "Ingrese el nombre de la interfaz que desea modificar: " interfaz
    read -p "¿quieres activar (up) o desactivar (down) la interfaz? (up/down): " accion
    sudo ip link set dev "$interfaz" "$accion"
    echo "La interfaz $interfaz ha sido $accion."
}

# Función para configurar una interfaz de forma estática o dinámica
configurar_interfaz() {
    read -p "Ingrese el nombre de la interfaz que desea configurar: " interfaz
    read -p "¿Desea una configuración estática o dinámica? (estatica/dinamica): " tipo_config

    if [ "$tipo_config" == "estatica" ]; then
        read -p "Ingrese la dirección IP: " ip_addr
        read -p "Ingrese la máscara de subred (por ejemplo, 24 para 255.255.255.0): " netmask
        read -p "Ingrese la puerta de enlace: " gateway
        sudo ip addr add "$ip_addr"/"$netmask" dev "$interfaz"
        sudo ip route add default via "$gateway" dev "$interfaz"
        echo "Configuración estática aplicada a la interfaz $interfaz."
    elif [ "$tipo_config" == "dinamica" ]; then
        sudo dhclient "$interfaz"
        echo "Configuración dinámica (DHCP) solicitada para la interfaz $interfaz."
    else
        echo "Opción no válida. Por favor, elija 'estatica' o 'dinamica'."
    fi
}

# Función para mostrar redes inalámbricas disponibles y conectarse
conectar_red_inalambrica() {
    read -p "Ingrese el nombre de la interfaz inalámbrica (por ejemplo, wlan0): " interfaz
    sudo ip link set "$interfaz" up
    echo "Escaneando redes disponibles..."
    sudo iwlist "$interfaz" scan | grep 'ESSID' | sed 's/.*ESSID:"\(.*\)"/\1/'
    read -p "Ingrese el SSID de la red a la que desea conectarse: " ssid
    read -s -p "Ingrese la contraseña de la red (deje en blanco si es una red abierta): " psk
    echo

    wpa_config="/etc/wpa_supplicant/wpa_supplicant.conf"
    sudo bash -c "cat > $wpa_config << EOL
network={
    ssid=\"$ssid\"
    psk=\"$psk\"
}
EOL"
    sudo wpa_supplicant -B -i "$interfaz" -c "$wpa_config"
    sudo dhclient "$interfaz"
    echo "Conectado a la red $ssid."
}

# Función principal
menu_principal() {
    while true; do
        echo "1. Mostrar interfaces de red"
        echo "2. Cambiar estado de las interfaces"
        echo "3. Configurar una interfaz (estática o dinámica)"
        echo "4. Conectar a una red inalámbrica"
        echo "5. Salir"
        read -p "Seleccione una opción (1-5): " opcion

        case $opcion in
            1) mostrar_interfaces ;;
            2) cambiar_estado_interfaz ;;
            3) configurar_interfaz ;;
            4) conectar_red_inalambrica ;;
            5) exit 0 ;;
            *) echo "Opción no válida. Por favor, seleccione un número del 1 al 5." ;;
        esac
    done
}


menu_principal