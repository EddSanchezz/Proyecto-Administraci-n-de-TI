#!/usr/bin/env bash
# ============================================================================
# usuarios_nis.sh - Gestion de cuentas de estudiantes por lote (NIS)
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Automatiza la rotacion masiva de cuentas estudiantiles por periodo (riesgo
# R3 de analisis.md): alta y baja de usuarios por lotes desde un CSV y
# reconstruccion automatica de los mapas NIS.
#
# Formato del CSV (separador punto y coma; una linea por usuario):
#   usuario;grupos;nombre completo
# Ejemplo (usuarios.csv):
#   juan.perez;academicos,publico;Juan Perez Gomez
#   maria.lopez;academicos,publico;Maria Lopez Restrepo
#
# En el alta:
#   - Se crea la cuenta con /home/usuario (directorio base del servidor).
#   - Clave temporal aleatoria (se muestra una sola vez).
#   - Se obliga al cambio de clave en el primer inicio de sesion.
#   - Se reconstruyen los mapas NIS (make -C /var/yp).
#
# Uso:
#   sudo bash usuarios_nis.sh alta  usuarios.csv
#   sudo bash usuarios_nis.sh baja  usuarios.csv
#   sudo bash usuarios_nis.sh lista
#   sudo bash usuarios_nis.sh clave juan.perez        # resetea una clave
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
GRUPOS_PERMITIDOS="academicos secretaria contabilidad publico"
MAPAS_DIR="/var/yp"

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ----------------------------- Verificaciones -------------------------------
if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo)."
    exit 1
fi

reconstruir_mapas() {
    log "Reconstruyendo mapas NIS..."
    make -C "${MAPAS_DIR}" >/dev/null
    log "Mapas actualizados (verificar: ypcat passwd | tail -n 5)."
}

clave_aleatoria() {
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12
}

alta_usuario() {
    local usuario="${1}" grupos="${2}" nombre="${3}"

    if id "${usuario}" >/dev/null 2>&1; then
        err "El usuario '${usuario}' ya existe; se omite."
        return 0
    fi

    # Validar grupos contra la lista permitida del diseño.
    local grupo grupo_valido todos_validos="si"
    IFS=',' read -ra lista <<< "${grupos}"
    for grupo in "${lista[@]}"; do
        grupo_valido="no"
        for g in ${GRUPOS_PERMITIDOS}; do
            [[ "${grupo}" == "${g}" ]] && grupo_valido="si"
        done
        if [[ "${grupo_valido}" == "no" ]]; then
            err "Grupo no permitido '${grupo}' para ${usuario} (use: ${GRUPOS_PERMITIDOS// /, })."
            todos_validos="no"
        fi
    done
    if [[ "${todos_validos}" == "no" ]]; then
        return 1
    fi

    useradd -m -c "${nombre}" -G "${grupos}" -s /bin/bash "${usuario}"
    local clave
    clave="$(clave_aleatoria)"
    echo "${usuario}:${clave}" | chpasswd
    chage -d 0 "${usuario}"   # obliga a cambiar la clave en el primer login

    log "  creado: ${usuario} (${nombre}) grupos=${grupos}"
    log "         clave temporal: ${clave} (cambiarla en el primer inicio de sesion)"
}

baja_usuario() {
    local usuario="${1}"
    if ! id "${usuario}" >/dev/null 2>&1; then
        log "  el usuario '${usuario}' no existe; se omite."
        return 0
    fi
    userdel -r "${usuario}" 2>/dev/null || userdel "${usuario}"
    log "  eliminado: ${usuario}"
}

# ----------------------------- Punto de entrada ------------------------------
case "${1:-}" in
    alta|baja)
        ARCHIVO_CSV="${2:-}"
        if [[ -z "${ARCHIVO_CSV}" || ! -r "${ARCHIVO_CSV}" ]]; then
            err "Indique un CSV legible: sudo bash $0 ${1} usuarios.csv"
            err "Formato: usuario;grupos;nombre completo"
            exit 1
        fi

        log "Procesando ${ARCHIVO_CSV} (modo ${1})..."
        local_total=0
        while IFS=';' read -r usuario grupos nombre; do
            # Ignorar encabezados, comentarios y lineas vacias.
            [[ -z "${usuario}" || "${usuario}" == \#* ]] && continue
            [[ -z "${nombre}" ]] && nombre="Usuario ${usuario}"
            if [[ "${1}" == "alta" ]]; then
                alta_usuario "${usuario}" "${grupos}" "${nombre}" || true
            else
                baja_usuario "${usuario}"
            fi
            local_total=$((local_total + 1))
        done < "${ARCHIVO_CSV}"

        log "Lineas procesadas: ${local_total}."
        reconstruir_mapas
        ;;
    clave)
        usuario="${2:-}"
        if [[ -z "${usuario}" ]]; then
            err "Uso: sudo bash $0 clave <usuario>"
            exit 1
        fi
        clave="$(clave_aleatoria)"
        echo "${usuario}:${clave}" | chpasswd
        chage -d 0 "${usuario}"
        log "Clave de ${usuario} reestablecida: ${clave}"
        reconstruir_mapas
        ;;
    lista)
        log "Usuarios locales con directorio en /home (fuente de los mapas NIS):"
        awk -F: -v h=1000 '$3>=h && $3<65534 {printf "  %-20s uid=%s grupos=%s\n", $1, $3, $5}' /etc/passwd
        log "Grupos del diseño y sus miembros:"
        for g in ${GRUPOS_PERMITIDOS}; do
            printf '  %-14s: %s\n' "${g}" "$(getent group "${g}" | cut -d: -f4)"
        done
        ;;
    *)
        err "Uso: sudo bash $0 {alta|baja} <archivo.csv> | lista | clave <usuario>"
        exit 1
        ;;
esac
