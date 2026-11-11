#!/usr/bin/env bash
# ============================================================================
# 06_instalar_cups.sh - Servidor de impresion centralizado (CUPS)
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Atiende la necesidad N4 (analisis.md): impresion centralizada y trazable de
# certificados, constancias y material didactico, con colas administrables
# desde la interfaz web en el puerto 631.
#
# Que hace este script:
#   1. Instala cups y cups-pdf (impresora virtual PDF: permite probar y
#      evidenciar la cola sin impresora fisica en el laboratorio).
#   2. Despliega cupsd.conf (escucha en 0.0.0.0:631 solo para la LAN via
#      UFW; administracion desde la red local).
#   3. Agrega al administrador del proyecto al grupo lpadmin.
#   4. Si ya genero la PKI local (codigo/ssl/certificado_autofirmado.sh),
#      configura CUPS para servir HTTPS con ese certificado en el 631.
#
# Uso:
#   sudo bash 06_instalar_cups.sh [usuario_admin]
#   (sin argumento usa el usuario que invoco el sudo, si aplica)
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
PUERTO="631"
CONF_CUPSD="/etc/cups/cupsd.conf"
CONF_FILES="/etc/cups/cups-files.conf"
CERT_SERVIDOR="/etc/ssl/itec/servidor.crt"
LLAVE_SERVIDOR="/etc/ssl/itec/servidor.key"
FECHA="$(date +%Y%m%d-%H%M%S)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUPSD_ORIGEN="${SCRIPT_DIR}/../configuraciones/cupsd.conf"

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
info() { echo "[i] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ----------------------------- Verificaciones -------------------------------
if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo bash $0)."
    exit 1
fi

if [[ ! -f "${CUPSD_ORIGEN}" ]]; then
    err "No se encontro la configuracion: ${CUPSD_ORIGEN}"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ========================= 1. Instalacion ====================================
log "Instalando CUPS y la impresora virtual PDF..."
apt-get update -y
apt-get install -y cups cups-pdf

# ========================= 2. Configuracion cupsd.conf ========================
if [[ -f "${CONF_CUPSD}" ]]; then
    cp "${CONF_CUPSD}" "${CONF_CUPSD}.bak.${FECHA}"
fi
install -m 644 "${CUPSD_ORIGEN}" "${CONF_CUPSD}"
log "Configuracion desplegada en ${CONF_CUPSD}."

# ========================= 3. HTTPS con la PKI local ==========================
# Solo si el certificado del proyecto existe; si no, CUPS genera uno propio.
if [[ -f "${CERT_SERVIDOR}" && -f "${LLAVE_SERVIDOR}" ]]; then
    log "Usando el certificado del proyecto para HTTPS en el puerto ${PUERTO}..."
    sed -i '/^# === PROYECTO ITEC/,/^# === FIN PROYECTO ITEC/d' "${CONF_FILES}" 2>/dev/null || true
    cat >> "${CONF_FILES}" <<EOF
# === PROYECTO ITEC - certificado TLS del servidor de impresion ===
ServerCertificate ${CERT_SERVIDOR}
ServerKey ${LLAVE_SERVIDOR}
# === FIN PROYECTO ITEC ===
EOF
    info "CUPS presentara el mismo certificado que el sitio web (PKI en /etc/ssl/itec)."
else
    info "No existe la PKI local (/etc/ssl/itec): CUPS generara su propio"
    info "certificado autofirmado. Ejecute codigo/ssl/certificado_autofirmado.sh"
    info "antes si quiere un certificado unico y confiable para toda la LAN."
fi

# ========================= 4. Administrador en lpadmin =======================
USUARIO_ADMIN="${1:-${SUDO_USER:-}}"
if [[ -n "${USUARIO_ADMIN}" && "${USUARIO_ADMIN}" != "root" ]]; then
    if id "${USUARIO_ADMIN}" >/dev/null 2>&1; then
        usermod -aG lpadmin "${USUARIO_ADMIN}"
        log "Usuario '${USUARIO_ADMIN}' agregado al grupo lpadmin (administra impresoras)."
    else
        err "El usuario '${USUARIO_ADMIN}' no existe en el sistema; no se agrego a lpadmin."
    fi
else
    info "No se indico usuario: administre la interfaz con una cuenta en lpadmin."
    info "Uso: sudo bash $0 nombre_usuario"
fi

# ========================= 5. Arranque ========================================
log "Habilitando e iniciando cups..."
systemctl enable --now cups
systemctl restart cups
sleep 3

if ! systemctl is-active --quiet cups; then
    err "El servicio cups no esta activo. Diagnostico:"
    journalctl -u cups -n 20 --no-pager || true
    exit 1
fi
log "Servicio cups activo."

# ========================= 6. Verificacion ====================================
log "Puerto en escucha (${PUERTO}/tcp):"
ss -tln | grep ":${PUERTO} " || err "El puerto ${PUERTO} no esta en escucha."

log "Respuesta de la interfaz web (HTTPS con certificado propio/PKI):"
curl -ksS -o /dev/null -w "  HTTP %{http_code}\n" "https://127.0.0.1:${PUERTO}/" || true

log "Colas de impresion registradas (cups-pdf crea la cola PDF):"
lpstat -p 2>/dev/null | sed 's/^/  /' || info "Sin colas todavia: agregue impresoras desde https://192.168.1.10:${PUERTO}"

# ========================= Resumen =============================================
log "Servidor de impresion configurado."
echo "------------------------------------------------------------"
echo " Interfaz web    : https://192.168.1.10:${PUERTO}"
echo " Impresora virtual: cola 'PDF' (salida en ~/PDF del usuario)"
echo " Administracion  : usuarios en el grupo lpadmin"
echo " Firewall        : puerto ${PUERTO}/tcp+udp solo para la LAN (ufw_reglas.sh)"
echo "------------------------------------------------------------"
echo " Prueba de impresion (evidencia semana 4):"
echo "   echo 'Pagina de prueba ITEC' | lp -d PDF"
echo "   lpstat -W completed          (ver el trabajo completado)"
echo "   ls ~/PDF                      (el PDF generado)"
echo "------------------------------------------------------------"
echo " Agregar una impresora fisica:"
echo "   Panel > Administration > Add Printer (IPP Everywhere si es moderna)"
echo "   o: lpadmin -p Sala101 -E -v ipp://192.168.1.50/ipp/print -m everywhere"
echo "------------------------------------------------------------"
