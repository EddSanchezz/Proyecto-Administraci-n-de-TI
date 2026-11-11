#!/usr/bin/env bash
# ============================================================================
# respaldo.sh - Respaldo semanal cifrado del servidor ITEC
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Respalda (analisis.md, seccion 7 - Riesgos):
#   1. El arbol compartido /srv/compartido (NFS/Samba) en un tar cifrado.
#   2. La base de datos PostgreSQL 'itec' (formulario de preinscripcion)
#      mediante pg_dump dentro del contenedor Docker.
#
# Todo se guarda en /srv/backups con nombre fechado, cifrado con AES-256
# (clave en /etc/itec/backup.key, fuera del repositorio) y retencion de
# 4 semanas (los respaldos mas antiguos se eliminan automaticamente).
#
# Uso:
#   sudo ./respaldo.sh                 # ejecutar un respaldo ahora
#   sudo ./respaldo.sh --instalar      # crea clave, cron semanal y logrotate
#
# Instalado como: /usr/local/sbin/itec-respaldo.sh
# Programado:     domingos 23:00 (/etc/cron.d/itec-respaldo)
# Registro:       /var/log/itec-respaldo.log
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
DIR_DATOS="/srv/compartido"
DIR_RESPALDOS="/srv/backups"
DIR_CLAVES="/etc/itec"
CLAVE="${DIR_CLAVES}/backup.key"
LOG="/var/log/itec-respaldo.log"
RETENCION_DIAS=28

# Base de datos de la aplicacion web (creada desde Dokploy, ver codigo/web/).
BD_NOMBRE="itec"
BD_USUARIO="itec_app"
# Contenedor autodetectado (se puede sobreescribir: CONTENEDOR_BD=xxx ./respaldo.sh)
CONTENEDOR_BD="${CONTENEDOR_BD:-}"

FECHA="$(date +%Y-%m-%d_%H%M)"
RUTA_INSTALADA="/usr/local/sbin/itec-respaldo.sh"

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[$(date '+%F %T')] $*"; }
err()  { echo "[$(date '+%F %T')] [ERROR] $*" >&2; }

# ----------------------------- Verificaciones -------------------------------
if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo)."
    exit 1
fi

mkdir -p "${DIR_RESPALDOS}"
chmod 700 "${DIR_RESPALDOS}"

# ========================= Funcion de respaldo ===============================
respaldar() {
    log "Iniciando respaldo ${FECHA}..."

    # ------------------------- 1. Arbol compartido --------------------------
    if [[ -d "${DIR_DATOS}" ]]; then
        ARCHIVO_TAR="${DIR_RESPALDOS}/compartido_${FECHA}.tar.gz.enc"
        if [[ -r "${CLAVE}" ]]; then
            tar -czf - -C "$(dirname "${DIR_DATOS}")" "$(basename "${DIR_DATOS}")" \
                | openssl enc -aes-256-cbc -pbkdf2 -salt -pass "file:${CLAVE}" \
                > "${ARCHIVO_TAR}"
            log "Compartido respaldado y CIFRADO: ${ARCHIVO_TAR} ($(du -h "${ARCHIVO_TAR}" | cut -f1))"
        else
            tar -czf "${DIR_RESPALDOS}/compartido_${FECHA}.tar.gz" -C "$(dirname "${DIR_DATOS}")" "$(basename "${DIR_DATOS}")"
            log "Compartido respaldado (SIN cifrar: no existe ${CLAVE}, use --instalar)."
        fi
    else
        log "Aviso: ${DIR_DATOS} no existe todavia (se omite; normal antes de la semana 3)."
    fi

    # ------------------------- 2. PostgreSQL --------------------------------
    # Localizar el contenedor de PostgreSQL de la aplicacion si no se indico.
    if [[ -z "${CONTENEDOR_BD}" ]] && command -v docker >/dev/null 2>&1; then
        CONTENEDOR_BD="$(docker ps --format '{{.Names}}' | grep -i postgres | head -n 1 || true)"
    fi

    if [[ -n "${CONTENEDOR_BD}" ]]; then
        ARCHIVO_SQL="${DIR_RESPALDOS}/postgresql_${FECHA}.sql.gz.enc"
        if [[ -r "${CLAVE}" ]]; then
            docker exec "${CONTENEDOR_BD}" pg_dump -U "${BD_USUARIO}" "${BD_NOMBRE}" \
                | gzip \
                | openssl enc -aes-256-cbc -pbkdf2 -salt -pass "file:${CLAVE}" \
                > "${ARCHIVO_SQL}"
            log "Base de datos '${BD_NOMBRE}' respaldada y CIFRADA desde ${CONTENEDOR_BD}: ${ARCHIVO_SQL}"
        else
            docker exec "${CONTENEDOR_BD}" pg_dump -U "${BD_USUARIO}" "${BD_NOMBRE}" \
                | gzip > "${DIR_RESPALDOS}/postgresql_${FECHA}.sql.gz"
            log "Base de datos '${BD_NOMBRE}' respaldada (SIN cifrar) desde ${CONTENEDOR_BD}."
        fi
    else
        log "Aviso: no hay contenedor PostgreSQL activo (se omite el volcado)."
    fi

    # ------------------------- 3. Retencion ---------------------------------
    log "Aplicando retencion: eliminar respaldos de mas de ${RETENCION_DIAS} dias..."
    find "${DIR_RESPALDOS}" -maxdepth 1 -type f \( -name 'compartido_*' -o -name 'postgresql_*' \) \
        -mtime "+${RETENCION_DIAS}" -print -delete | sed 's/^/  eliminado: /' || true

    # ------------------------- 4. Reporte -----------------------------------
    log "Contenido actual de ${DIR_RESPALDOS}:"
    ls -lh "${DIR_RESPALDOS}" | tail -n +2 | sed 's/^/  /'
    log "Respaldo terminado."
}

# ------------------------- Modo: instalar ------------------------------------
instalar() {
    # Clave de cifrado fuera del repositorio.
    if [[ ! -f "${CLAVE}" ]]; then
        install -d -m 700 -o root -g root "${DIR_CLAVES}"
        openssl rand -base64 48 > "${CLAVE}"
        chmod 600 "${CLAVE}"
        log "Clave de cifrado generada en ${CLAVE} (600, solo root)."
        log "IMPORTANTE: copie esta clave a un lugar seguro FUERA del servidor;"
        log "sin ella los respaldos cifrados no se pueden restaurar."
    else
        log "La clave ${CLAVE} ya existe: no se regenera."
    fi

    # Copia operativa.
    cp "$(readlink -f "${BASH_SOURCE[0]}")" "${RUTA_INSTALADA}"
    chmod 700 "${RUTA_INSTALADA}"
    log "Script instalado en ${RUTA_INSTALADA}."

    # Cron: domingos a las 23:00.
    cat > /etc/cron.d/itec-respaldo <<EOF
# Respaldo semanal cifrado del servidor ITEC
0 23 * * 0 root ${RUTA_INSTALADA} >> ${LOG} 2>&1
EOF
    chmod 644 /etc/cron.d/itec-respaldo
    log "Cron instalado: domingos 23:00 (/etc/cron.d/itec-respaldo)."

    # Logrotate del registro.
    cat > /etc/logrotate.d/itec-respaldo <<EOF
${LOG} {
    weekly
    rotate 8
    compress
    missingok
    notifempty
}
EOF
    log "Rotacion de ${LOG} configurada."

    log "Ejecutando el primer respaldo..."
    "${RUTA_INSTALADA}"
}

# ------------------------- Restauracion (referencia) -------------------------
# Para restaurar un respaldo cifrado:
#   openssl enc -d -aes-256-cbc -pbkdf2 -pass file:/etc/itec/backup.key \
#     -in compartido_FECHA.tar.gz.enc | tar -xzf - -C /
#   gunzip < <(openssl enc -d -aes-256-cbc -pbkdf2 -pass file:/etc/itec/backup.key \
#     -in postgresql_FECHA.sql.gz.enc) | \
#     docker exec -i CONTENEDOR psql -U itec_app -d itec

# ------------------------- Punto de entrada ----------------------------------
case "${1:-}" in
    --instalar)
        instalar
        ;;
    ""|--ahora)
        respaldar
        ;;
    *)
        err "Opcion no reconocida: ${1}"
        err "Uso: sudo ./respaldo.sh [--ahora | --instalar]"
        exit 1
        ;;
esac
