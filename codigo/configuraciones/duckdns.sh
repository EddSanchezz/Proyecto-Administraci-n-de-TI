#!/usr/bin/env bash
# ============================================================================
# duckdns.sh - Actualizacion del DNS dinamico DuckDNS
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Mantiene el subdominio itec-quindio.duckdns.org apuntando a la IP publica
# de la red del instituto (que es dinamica; ver riesgo R5 de analisis.md).
#
# SEGURIDAD: el token de DuckDNS NUNCA se guarda en este repositorio.
# El script lo busca en este orden:
#   1. Variable de entorno  DUCKDNS_TOKEN
#   2. Archivo              /etc/duckdns/token   (permisos 600, solo root)
#
# Uso:
#   sudo ./duckdns.sh                       # una sola actualizacion
#   sudo DUCKDNS_TOKEN=xxxx ./duckdns.sh    # una actualizacion, token por entorno
#   sudo ./duckdns.sh --instalar TOKEN      # instala cron cada 5 min + logrotate
#
# Al instalar se copia este script a /usr/local/sbin/duckdns-itec.sh,
# el token queda en /etc/duckdns/token y el cron en /etc/cron.d/duckdns.
# ============================================================================

set -euo pipefail

DOMINIO="itec-quindio"                 # nombre del subdominio en DuckDNS (sin .duckdns.org)
FQDN="${DOMINIO}.duckdns.org"
URL_UPDATE="https://www.duckdns.org/update?domains=${DOMINIO}&token=%s&ip="
ARCHIVO_TOKEN="/etc/duckdns/token"
RUTA_INSTALADA="/usr/local/sbin/duckdns-itec.sh"
LOG="/var/log/duckdns.log"

log()  { echo "[+] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ------------------------- Obtencion del token -------------------------------
obtener_token() {
    if [[ -n "${DUCKDNS_TOKEN:-}" ]]; then
        printf '%s' "${DUCKDNS_TOKEN}"
        return 0
    fi
    if [[ -r "${ARCHIVO_TOKEN}" ]]; then
        tr -d '[:space:]' < "${ARCHIVO_TOKEN}"
        return 0
    fi
    return 1
}

# ------------------------- Modo: actualizar -----------------------------------
actualizar() {
    if ! TOKEN="$(obtener_token)"; then
        err "No se encontro el token de DuckDNS."
        err "Guarde el token en ${ARCHIVO_TOKEN} (chmod 600, propiedad de root)"
        err "o exportelo en la variable DUCKDNS_TOKEN. Ejemplo:"
        err "  sudo install -m 600 -o root -g root /dev/null ${ARCHIVO_TOKEN}"
        err "  sudo nano ${ARCHIVO_TOKEN}"
        exit 1
    fi

    # 'ip=' vacio: DuckDNS detecta la IP publica desde la que sale la peticion.
    RESPUESTA="$(curl -fsS --max-time 30 "$(printf "${URL_UPDATE}" "${TOKEN}")" || echo "FALLO_RED")"

    case "${RESPUESTA}" in
        OK)
            log "$(date '+%F %T') ${FQDN} actualizado correctamente."
            ;;
        KO)
            err "$(date '+%F %T') DuckDNS rechazo la actualizacion (token o dominio invalido)."
            exit 1
            ;;
        FALLO_RED)
            err "$(date '+%F %T') Sin conexion con www.duckdns.org."
            exit 1
            ;;
        *)
            # DuckDNS devuelve 'OK' o 'KO'; cualquier otra cosa se reporta.
            log "$(date '+%F %T') Respuesta inesperada de DuckDNS: ${RESPUESTA}"
            ;;
    esac
}

# ------------------------- Modo: instalar ------------------------------------
instalar() {
    if [[ $EUID -ne 0 ]]; then
        err "La instalacion requiere root (sudo)."
        exit 1
    fi

    local token="${1:-}"
    if [[ -z "${token}" ]]; then
        err "Uso: sudo ./duckdns.sh --instalar <TOKEN_DE_DUCKDNS>"
        exit 1
    fi

    # Token fuera del repositorio, con permisos restringidos.
    install -d -m 700 -o root -g root /etc/duckdns
    printf '%s' "${token}" > "${ARCHIVO_TOKEN}"
    chmod 600 "${ARCHIVO_TOKEN}"
    log "Token guardado en ${ARCHIVO_TOKEN} (fuera del repositorio, permisos 600)."

    # Copia operativa del script (independiente de la carpeta del proyecto).
    cp "$(readlink -f "${BASH_SOURCE[0]}")" "${RUTA_INSTALADA}"
    chmod 700 "${RUTA_INSTALADA}"
    log "Script instalado en ${RUTA_INSTALADA}."

    # Tarea programada cada 5 minutos (DuckDNS recomienda intervalos >= 5 min).
    cat > /etc/cron.d/duckdns <<EOF
# Actualizacion de DNS dinamico DuckDNS - Proyecto ITEC
*/5 * * * * root ${RUTA_INSTALADA} >> ${LOG} 2>&1
EOF
    chmod 644 /etc/cron.d/duckdns
    log "Cron instalado en /etc/cron.d/duckdns (cada 5 minutos)."

    # Rotacion del log para que no crezca sin control.
    cat > /etc/logrotate.d/duckdns <<EOF
${LOG} {
    weekly
    rotate 8
    compress
    missingok
    notifempty
}
EOF
    log "Rotacion de ${LOG} configurada (/etc/logrotate.d/duckdns)."

    log "Ejecutando la primera actualizacion..."
    "${RUTA_INSTALADA}"
    log "Instalacion completa. Revise ${LOG} para el historial."
}

# ------------------------- Punto de entrada ----------------------------------
case "${1:-}" in
    --instalar)
        instalar "${2:-}"
        ;;
    ""|--actualizar)
        actualizar
        ;;
    *)
        err "Opcion no reconocida: ${1}"
        err "Uso: ./duckdns.sh [--actualizar | --instalar TOKEN]"
        exit 1
        ;;
esac
