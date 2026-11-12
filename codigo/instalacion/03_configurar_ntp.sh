#!/usr/bin/env bash
# ============================================================================
# 03_configurar_ntp.sh
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Convierte el servidor en el servidor de tiempo de la LAN (192.168.80.0/24):
#   - Instala ntpsec: en Ubuntu 24.04 el paquete 'ntp' es transitorio hacia
#     ntpsec (ntpd + ntpq, configuracion en /etc/ntpsec/ntp.conf).
#   - Despliega la configuracion de codigo/configuraciones/ntp.conf:
#     servidores del pool de Colombia/Sudamerica y permisos restrict.
#   - Desactiva systemd-timesyncd para que solo ntpd administre la hora.
#
# Uso (desde la carpeta instalacion/ o con rutas completas):
#   sudo bash 03_configurar_ntp.sh
#
# Verificacion en clientes:
#   Linux:   ntpdate -q 192.168.80.10   o   chronyd/ntpd apuntando al servidor
#   Windows: w32tm /query /status tras apuntar al NTP interno
#
# Firewall: el puerto 123/udp solo se abre para la LAN en
#   codigo/seguridad/ufw_reglas.sh
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
RED_LAN="192.168.80.0/24"
CONF_DESTINO="/etc/ntpsec/ntp.conf"
FECHA="$(date +%Y%m%d-%H%M%S)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_ORIGEN="${SCRIPT_DIR}/../configuraciones/ntp.conf"

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
info() { echo "[i] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ----------------------------- Verificaciones -------------------------------
if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo bash $0)."
    exit 1
fi

if [[ ! -f "${CONF_ORIGEN}" ]]; then
    err "No se encontro la configuracion: ${CONF_ORIGEN}"
    err "El script espera el arbol del repositorio (codigo/instalacion y codigo/configuraciones)."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ========================= 1. Instalar ntpsec ================================
log "Instalando ntpsec (implementacion NTP para Ubuntu 24.04)..."
if ! apt-get install -y ntpsec; then
    err "Fallo la instalacion de ntpsec. Verifique que el repositorio"
    err "'universe' este habilitado (viene activo en Ubuntu Server)."
    exit 1
fi

# ========================= 2. Desplegar configuracion =======================
if [[ -f "${CONF_DESTINO}" ]]; then
    cp "${CONF_DESTINO}" "${CONF_DESTINO}.bak.${FECHA}"
    info "Respaldo de la configuracion previa: ${CONF_DESTINO}.bak.${FECHA}"
fi

install -m 644 "${CONF_ORIGEN}" "${CONF_DESTINO}"
log "Configuracion desplegada en ${CONF_DESTINO}."
info "Red LAN autorizada a consultar la hora: ${RED_LAN}"

# ========================= 3. Evitar doble demonio ===========================
# systemd-timesyncd tambien ajusta la hora; se apaga para que solo ntpd sirva.
if systemctl is-active --quiet systemd-timesyncd; then
    log "Desactivando systemd-timesyncd (el servidor de tiempo ahora es ntpd)..."
    systemctl disable --now systemd-timesyncd
fi

# ========================= 4. Arrancar el servicio ==========================
log "Habilitando e iniciando el servicio ntpsec..."
systemctl enable --now ntpsec
systemctl restart ntpsec

sleep 5

if ! systemctl is-active --quiet ntpsec; then
    err "El servicio ntpsec no quedo activo. Diagnostico:"
    systemctl status ntpsec --no-pager || true
    journalctl -u ntpsec -n 20 --no-pager || true
    exit 1
fi
log "Servicio ntpsec activo."

# ========================= 5. Verificacion ==================================
log "Estado de sincronizacion (ntpq -p): puede tardar unos minutos en"
log "marcar los servidores remotos con un '*' (fuente seleccionada)."
ntpq -p || true

log "Puerto NTP en escucha (123/udp):"
ss -uln | grep ':123 ' || info "Nota: ntpd puede tardar unos segundos en abrir el socket."

# ========================= Resumen ===========================================
log "Servidor NTP configurado."
echo "------------------------------------------------------------"
echo " Servidor de tiempo : 192.168.80.10 (puerto 123/udp, solo LAN)"
echo " Verificar         : ntpq -p   |   timedatectl"
echo "------------------------------------------------------------"
echo " Configuracion de clientes:"
echo "   Linux (chrony):  server 192.168.80.10 iburst  en /etc/chrony/chrony.conf"
echo "                   luego: systemctl restart chrony && chronyc sources"
echo "   Linux (ntpsec):  server 192.168.80.10 iburst  en /etc/ntpsec/ntp.conf"
echo "   Windows (admin): w32tm /config /manualpeerlist:192.168.80.10 /syncfromflags:manual /update"
echo "                   luego: w32tm /query /status"
echo "------------------------------------------------------------"
