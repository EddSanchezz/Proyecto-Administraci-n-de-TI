#!/usr/bin/env bash
# ============================================================================
# 05_instalar_nis.sh - Autenticacion centralizada para las salas Linux (NIS)
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Configura el servidor como maestro NIS del dominio 'itec.local':
#   - Paquete 'nis' (ypserv + ypbind + yp-tools, disponibles en Ubuntu 24.04).
#   - Dominio NIS: itec.local (archivo /etc/defaultdomain).
#   - Modo maestro: NISSERVER=master en /etc/default/nis.
#   - ypserv fijado en el puerto 834 (YPSERVARGS="-p 834") para filtrarlo
#     con UFW; rpcbind (111) queda tambien restringido a la LAN.
#   - /var/yp/securenets: solo localhost y 192.168.1.0/24 pueden consultar.
#   - Mapas passwd+shadow fusionados (MERGE_PASSWD/MERGE_GROUP) para que el
#     inicio de sesion de los estudiantes funcione en las salas.
#
# LIMITACION ACEPTADA EN EL DISEÑO (analisis.md, seccion 7): NIS viaja sin
# cifrado; se mitiga limitandolo a la LAN y con reglas UFW por subred.
#
# Uso:
#   sudo bash 05_instalar_nis.sh
#
# Requiere: 01_preparar_servidor.sh y (idealmente) 04_instalar_nfs.sh.
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
DOMINIO_NIS="itec.local"
RED_LAN="192.168.1.0/24"
PUERTO_YPSERV="834"
FECHA="$(date +%Y%m%d-%H%M%S)"

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
info() { echo "[i] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ----------------------------- Verificaciones -------------------------------
if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo bash $0)."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ========================= 1. Instalar el paquete nis ========================
log "Instalando nis (ypserv, ypbind, yp-tools)..."
# Se pre-responde la pregunta de debconf del dominio para que la instalacion
# no se detenga; el valor definitivo se fija despues en /etc/defaultdomain.
echo "nis nis/nisdomain string ${DOMINIO_NIS}" | debconf-set-selections 2>/dev/null || true
apt-get update -y
apt-get install -y nis

# ========================= 2. Dominio y modo maestro =========================
log "Configurando dominio NIS '${DOMINIO_NIS}'..."
printf '%s\n' "${DOMINIO_NIS}" > /etc/defaultdomain
domainname "${DOMINIO_NIS}" || true

log "Ajustando /etc/default/nis (modo maestro + puerto fijo ${PUERTO_YPSERV})..."
if [[ -f /etc/default/nis ]]; then
    cp /etc/default/nis "/etc/default/nis.bak.${FECHA}"
fi
sed -i 's/^NISSERVER=.*/NISSERVER=master/' /etc/default/nis
if grep -q '^YPSERVARGS=' /etc/default/nis; then
    sed -i "s/^YPSERVARGS=.*/YPSERVARGS=\"-p ${PUERTO_YPSERV}\"/" /etc/default/nis
else
    printf '%s\n' "YPSERVARGS=\"-p ${PUERTO_YPSERV}\"" >> /etc/default/nis
fi
info "NISSERVER=master | YPSERVARGS=-p ${PUERTO_YPSERV}"

# ========================= 3. Restriccion de clientes ========================
# securenets: solo el propio servidor y la LAN pueden hablar con ypserv.
log "Escribiendo /var/yp/securenets (solo localhost y ${RED_LAN})..."
cat > /var/yp/securenets <<EOF
# PROYECTO ITEC - clientes autorizados del servidor NIS
# host    red
255.0.0.0    127.0.0.0
255.255.255.0 192.168.1.0
EOF
chmod 644 /var/yp/securenets

# ========================= 4. El servidor como cliente de si mismo ==========
log "Configurando ypbind local (/etc/yp.conf)..."
if [[ -f /etc/yp.conf ]]; then
    cp /etc/yp.conf "/etc/yp.conf.bak.${FECHA}"
fi
if ! grep -qE "^ypserver 127\.0\.0\.1" /etc/yp.conf; then
    cat >> /etc/yp.conf <<EOF
# PROYECTO ITEC - el servidor usa su propio NIS
domain ${DOMINIO_NIS} server 127.0.0.1
ypserver 127.0.0.1
EOF
fi

# ========================= 5. Mapas con contrasenas ==========================
# Fusionar passwd/shadow y group/gshadow en los mapas para que el login
# de los estudiantes funcione en las salas (practica estandar de NIS).
log "Activando MERGE_PASSWD y MERGE_GROUP en /var/yp/Makefile..."
MAKEFILE=/var/yp/Makefile
if [[ -f "${MAKEFILE}" ]]; then
    cp "${MAKEFILE}" "${MAKEFILE}.bak.${FECHA}"
    sed -i 's/^MERGE_PASSWD=.*/MERGE_PASSWD=true/' "${MAKEFILE}"
    sed -i 's/^MERGE_GROUP=.*/MERGE_GROUP=true/' "${MAKEFILE}"
    grep -E '^(MERGE_PASSWD|MERGE_GROUP)' "${MAKEFILE}" | sed 's/^/  /'
else
    err "No se encontro ${MAKEFILE}; revise la instalacion del paquete nis."
    exit 1
fi

# ========================= 6. Arrancar y construir mapas ====================
log "Habilitando rpcbind y el servicio nis..."
systemctl enable --now rpcbind
systemctl restart rpcbind
systemctl enable --now nis 2>/dev/null || true
systemctl restart nis 2>/dev/null || service nis restart || true

log "Construyendo los mapas NIS (make en /var/yp)..."
# Si aun no existe el directorio del dominio, make lo crea interactivo;
# se envia 'y' por si pide confirmacion.
make -C /var/yp <<< "y" || make -C /var/yp
ls -1 /var/yp/ | sed 's/^/  mapa: /' | grep -v -E 'Makefile|securenets|nicknames|binding|\.bak' || true

log "Reiniciando nis con la configuracion final..."
systemctl restart nis 2>/dev/null || service nis restart || true
sleep 5

# ========================= 7. Verificacion ===================================
if ! systemctl is-active --quiet nis; then
    err "El servicio nis no reporta activo (revisar 'systemctl status nis')."
    err "Los demonios individuales se verifican a continuacion."
fi

log "ypwhich (servidor NIS en uso):"
ypwhich || true

log "Mapa passwd (primeras entradas):"
ypcat passwd 2>/dev/null | head -n 3 | sed 's/^/  /' || err "ypcat fallo: revise 'nis' y 'rpcbind'."

log "Puertos de ypserv (debe escuchar en ${PUERTO_YPSERV}):"
ss -ulnp 2>/dev/null | grep -E 'ypserv|:'"${PUERTO_YPSERV}"' ' | sed 's/^/  /' \
    || info "Verifique manualmente: ss -ulnp | grep ypserv"
info "Si ypserv NO aparece en ${PUERTO_YPSERV}, el argumento YPSERVARGS no fue"
info "aplicado por el demonio: revise 'ps aux | grep ypserv' y arranquelo con"
info "'ypserv -p ${PUERTO_YPSERV}' para confirmar, y luego ajuste /etc/default/nis."

# ========================= Resumen ===========================================
log "Servidor NIS configurado."
echo "------------------------------------------------------------"
echo " Dominio NIS   : ${DOMINIO_NIS}"
echo " Servidor      : 192.168.1.10 (ypserv en ${PUERTO_YPSERV} + rpcbind 111)"
echo " Red autorizada: ${RED_LAN} (secretnets + UFW)"
echo "------------------------------------------------------------"
echo " Alta de estudiantes por lote:"
echo "   sudo bash codigo/configuraciones/usuarios_nis.sh alta usuarios.csv"
echo " Configuracion de un CLIENTE Linux de sala:"
echo "   sudo apt install nis"
echo "   echo 'domain ${DOMINIO_NIS} server 192.168.1.10' >> /etc/yp.conf"
echo "   sudo systemctl enable --now rpcbind nis"
echo "   sudo sed -i 's/^passwd:.*/passwd: compat nis/' /etc/nsswitch.conf"
echo "   sudo sed -i 's/^group:.*/group: compat nis/'  /etc/nsswitch.conf"
echo "   ypcat passwd   (listar cuentas)"
echo "   ypwhich        (debe responder 192.168.1.10)"
echo "------------------------------------------------------------"
