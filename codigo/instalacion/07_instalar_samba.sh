#!/usr/bin/env bash
# ============================================================================
# 07_instalar_samba.sh - Comparticion de archivos para Windows (Samba)
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Comparte las carpetas de /srv/compartido para los equipos Windows de
# administracion y secretaria (necesidad N3 de analisis.md), sobre SMB
# directo en el puerto 445/tcp, sin NetBIOS (137-139), como se definio en
# el diseño para simplificar el firewall.
#
# Recursos publicados (analisis.md, seccion 6):
#   \\itec-server\academicos     docentes con cuenta (lectura/escritura)
#   \\itec-server\secretaria     secretaria academica
#   \\itec-server\contabilidad   contabilidad
#   \\itec-server\publico        material didactico (todos con cuenta)
#
# Uso (los nombres se agregan ademas a Samba con smbpasswd):
#   sudo bash 07_instalar_samba.sh usuario1 usuario2 ...
#   (sin argumentos se instala sin altas de usuario; luego use smbpasswd -a)
#
# Requiere: 04_instalar_nfs.sh (crea el arbol y los grupos POSIX).
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
CONF_SAMBA="/etc/samba/smb.conf"
FECHA="$(date +%Y%m%d-%H%M%S)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMB_ORIGEN="${SCRIPT_DIR}/../configuraciones/smb.conf"

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
info() { echo "[i] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ----------------------------- Verificaciones -------------------------------
if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo bash $0)."
    exit 1
fi

if [[ ! -f "${SMB_ORIGEN}" ]]; then
    err "No se encontro la configuracion: ${SMB_ORIGEN}"
    exit 1
fi

if [[ ! -d /srv/compartido ]]; then
    err "No existe /srv/compartido. Ejecute primero 04_instalar_nfs.sh"
    err "(crea el arbol de datos y los grupos compartidos con Samba)."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ========================= 1. Instalacion ====================================
log "Instalando samba y smbclient..."
apt-get update -y
apt-get install -y samba smbclient

# ========================= 2. Configuracion ===================================
if [[ -f "${CONF_SAMBA}" ]]; then
    cp "${CONF_SAMBA}" "${CONF_SAMBA}.bak.${FECHA}"
fi
install -m 644 "${SMB_ORIGEN}" "${CONF_SAMBA}"
log "Configuracion desplegada en ${CONF_SAMBA}."

# Validar sintaxis antes de arrancar (testparm es el chequeo oficial).
log "Validando la configuracion con testparm..."
if ! testparm -s "${CONF_SAMBA}" >/dev/null 2>&1; then
    err "testparm rechazo la configuracion. Revise ${CONF_SAMBA}."
    exit 1
fi
log "Sintaxis valida."

# ========================= 3. Servicios =======================================
# nmbd se deshabilita: se decide usar solo SMB directo (445) sin NetBIOS.
log "Deshabilitando nmbd (no se usa NetBIOS 137-139)..."
systemctl disable --now nmbd 2>/dev/null || true

log "Habilitando e iniciando smbd..."
systemctl enable --now smbd
systemctl restart smbd
sleep 2

if ! systemctl is-active --quiet smbd; then
    err "smbd no esta activo. Diagnostico:"
    systemctl status smbd --no-pager || true
    journalctl -u smbd -n 15 --no-pager || true
    exit 1
fi
log "Servicio smbd activo."

# ========================= 4. Usuarios ========================================
for usuario in "${@}"; do
    if id "${usuario}" >/dev/null 2>&1; then
        if pdbedit -L 2>/dev/null | grep -q "^${usuario}:"; then
            log "El usuario '${usuario}' ya existe en Samba."
        else
            log "Alta Samba para '${usuario}' (defina la contrasena cuando se pida):"
            smbpasswd -a "${usuario}"
        fi
    else
        err "El usuario del sistema '${usuario}' no existe (primero: useradd o usuarios_nis.sh)."
    fi
done

if [[ $# -eq 0 ]]; then
    info "No se dieron usuarios. Para habilitar acceso a un equipo Windows:"
    info "   sudo smbpasswd -a <usuario>"
fi

# ========================= 5. Verificacion ====================================
log "Puerto en escucha (445/tcp, solo SMB directo):"
ss -tln | grep ':445 ' || err "El puerto 445 no esta en escucha."

log "Recursos compartidos publicados:"
smbclient -L localhost -N 2>/dev/null | grep -E 'Disk|IPC|Printer' | sed 's/^/  /' \
    || info "Liste recursos con: smbclient -L //192.168.80.10 -N"

# ========================= Resumen ============================================
log "Servidor Samba configurado."
echo "------------------------------------------------------------"
echo " Recursos       : academicos secretaria contabilidad publico"
echo " Acceso Windows : \\\\itec-server\\secretaria  (o \\\\192.168.80.10\\publico)"
echo " Protocolo      : SMB directo 445/tcp (NetBIOS deshabilitado)"
echo "------------------------------------------------------------"
echo " Prueba local:"
echo "   smbclient //localhost/secretaria -U <usuario>"
echo "   (subir archivo de prueba: put archivo.txt | ls)"
echo " Prueba desde Windows:"
echo "   \\\\itec-server\\publico  -> crear y abrir un archivo"
echo "------------------------------------------------------------"
