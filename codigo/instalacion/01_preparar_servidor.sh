#!/usr/bin/env bash
# ============================================================================
# 01_preparar_servidor.sh
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Prepara la VM Ubuntu Server 24.04 LTS como servidor base:
#   1. Actualiza el sistema e instala paquetes base.
#   2. Configura hostname 'itec-server' y /etc/hosts.
#   3. Define zona horaria America/Bogota.
#   4. Activa actualizaciones automaticas de seguridad.
#   5. Endurece SSH (sin root directo) y valida antes de recargar.
#   6. Configura IP estatica 192.168.1.10/24 con netplan (paso final).
#
# Uso (como root o con sudo, desde la carpeta que contenga este script):
#   sudo bash 01_preparar_servidor.sh
#
# Notas:
#   - Es idempotente: puede ejecutarse de nuevo sin romper nada.
#   - El cambio de IP se hace AL FINAL para que, si se pierde la conexion SSH,
#     todo lo demas ya quede aplicado.
#   - Alternativa valida: dejar DHCP y crear una reserva 192.168.1.10 en el
#     router del laboratorio (seccion 5 de analisis.md); en ese caso el script
#     detecta la IP y no escribe el netplan.
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
NUEVO_HOSTNAME="itec-server"
IP_ESTATICA="192.168.1.10"
PREFIJO="24"
GATEWAY="192.168.1.1"
DNS1="192.168.1.1"
DNS2="8.8.8.8"
ZONA_HORARIA="America/Bogota"
NETPLAN_ARCHIVO="/etc/netplan/99-itec-estatica.yaml"
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

if [[ ! -f /etc/os-release ]]; then
    err "No se detecto /etc/os-release. Se requiere Ubuntu Server 24.04 LTS."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
    err "Sistema detectado: ${ID:-desconocido}. Este proyecto esta diseñado para Ubuntu Server 24.04 LTS."
    exit 1
fi
if [[ "${VERSION_ID:-}" != "24.04" ]]; then
    info "Version de Ubuntu: ${VERSION_ID:-desconocida} (el proyecto se probo para 24.04 LTS; se continua)."
fi

# Interfaz de red por defecto (la que tiene la ruta por defecto)
if command -v ip >/dev/null 2>&1; then
    INTERFAZ="$(ip route show default 2>/dev/null | awk '{print $5; exit}')"
fi
if [[ -z "${INTERFAZ:-}" || "${INTERFAZ}" == "lo" ]]; then
    INTERFAZ="$(ls /sys/class/net | grep -v '^lo$' | head -n 1)"
fi
if [[ -z "${INTERFAZ:-}" ]]; then
    err "No se pudo detectar una interfaz de red. Configure la red manualmente y vuelva a ejecutar."
    exit 1
fi
info "Interfaz de red principal detectada: ${INTERFAZ}"

IP_ACTUAL="$(ip -4 addr show "${INTERFAZ}" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1 || true)"
info "IP actual en ${INTERFAZ}: ${IP_ACTUAL:-sin asignar}"

# ========================= 1. Actualizacion del sistema ======================
log "Actualizando listas de paquetes..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

log "Actualizando paquetes instalados (puede tardar varios minutos)..."
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# ========================= 2. Paquetes base =================================
log "Instalando paquetes base..."
apt-get install -y \
    curl wget git htop vim nano tree \
    net-tools dnsutils unzip rsync tmux \
    ca-certificates gnupg software-properties-common \
    unattended-upgrades

# ========================= 3. Hostname y /etc/hosts =========================
log "Configurando hostname '${NUEVO_HOSTNAME}'..."
hostnamectl set-hostname "${NUEVO_HOSTNAME}"

if [[ -f /etc/hosts ]]; then
    cp /etc/hosts "/etc/hosts.bak.${FECHA}"
    info "Respaldo de /etc/hosts en /etc/hosts.bak.${FECHA}"
fi

if ! grep -qE "^${IP_ESTATICA}\s" /etc/hosts; then
    # 127.0.1.1 se usa en Ubuntu para el FQDN; se agregan ambas entradas
    # solo si no existen todavia (idempotente).
    if ! grep -qE "^127\.0\.1\.1\s" /etc/hosts; then
        printf '%s\n' "127.0.1.1 ${NUEVO_HOSTNAME}.lan ${NUEVO_HOSTNAME}" >> /etc/hosts
    fi
    printf '%s\n' "${IP_ESTATICA} itec-server.lan itec-server" >> /etc/hosts
    log "Entradas de ${NUEVO_HOSTNAME} agregadas a /etc/hosts."
else
    log "Entrada ${IP_ESTATICA} ya presente en /etc/hosts."
fi

# ========================= 4. Zona horaria ==================================
log "Configurando zona horaria ${ZONA_HORARIA}..."
timedatectl set-timezone "${ZONA_HORARIA}"
timedatectl | grep -E 'Time zone|Local time'

# ========================= 5. Actualizaciones automaticas ===================
log "Activando actualizaciones automaticas de seguridad (unattended-upgrades)..."
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
systemctl enable --now unattended-upgrades >/dev/null 2>&1 || true

# ========================= 6. Endurecimiento ligero de SSH ==================
log "Configurando opciones de seguridad de SSH..."
if [[ -d /etc/ssh/sshd_config.d ]]; then
    cat > /etc/ssh/sshd_config.d/99-itec.conf <<EOF
# Proyecto ITEC - politicas SSH
PermitRootLogin no
X11Forwarding no
EOF
    if sshd -t 2>/dev/null; then
        systemctl reload ssh
        log "SSH recargado: inicio de sesion directo de root deshabilitado."
    else
        err "La configuracion SSH nueva no valida (sshd -t). No se recargo y no se rompio el servicio."
        rm -f /etc/ssh/sshd_config.d/99-itec.conf
    fi
else
    info "No existe /etc/ssh/sshd_config.d; se omite el ajuste de SSH."
fi

# ========================= 7. IP estatica con netplan ========================
if [[ "${IP_ACTUAL:-}" == "${IP_ESTATICA}" ]]; then
    log "La VM ya tiene la IP ${IP_ESTATICA}: no se modifica la configuracion de red."
else
    log "Escribiendo configuracion netplan estatica para ${IP_ESTATICA}/${PREFIJO} en ${INTERFAZ}..."
    NETPLAN_VIEJO="$(ls /etc/netplan/*.yaml 2>/dev/null | head -n 1 || true)"
    if [[ -n "${NETPLAN_VIEJO}" ]]; then
        cp "${NETPLAN_VIEJO}" "${NETPLAN_VIEJO}.bak.${FECHA}"
        info "Respaldo del netplan original: ${NETPLAN_VIEJO}.bak.${FECHA}"
    fi

    cat > "${NETPLAN_ARCHIVO}" <<EOF
# Configuracion estatica del servidor ITEC (proyecto Administracion de TI)
network:
  version: 2
  renderer: networkd
  ethernets:
    ${INTERFAZ}:
      dhcp4: false
      dhcp6: false
      addresses:
        - ${IP_ESTATICA}/${PREFIJO}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${DNS1}, ${DNS2}]
EOF
    chmod 600 "${NETPLAN_ARCHIVO}"

    log "Validando sintaxis del netplan..."
    netplan generate
    log "Aplicando configuracion de red (netplan apply)..."
    log "ADVERTENCIA: si esta conectado por SSH desde otra subred, la sesion puede caerse."
    log "             Reconectese a ${IP_ESTATICA} y verifique con: ip a"
    netplan apply || netplan try --timeout 60 || true
fi

# ========================= Resumen ===========================================
log "Preparacion del servidor terminada."
echo "------------------------------------------------------------"
echo " Hostname      : $(hostname)"
echo " Zona horaria  : $(timedatectl show --property=Timezone --value)"
echo " Interfaz      : ${INTERFAZ}"
echo " IP            : ${IP_ACTUAL:-dhcp -> ${IP_ESTATICA}}"
echo "------------------------------------------------------------"
echo " Siguientes pasos:"
echo "   1. Verificar:  ip a  |  ping -c 3 8.8.8.8  |  ping -c 3 google.com"
echo "   2. Probar SSH: ssh <usuario>@${IP_ESTATICA}"
echo "   3. Continuar con 02_instalar_dokploy.sh"
echo "------------------------------------------------------------"
