#!/usr/bin/env bash
# ============================================================================
# 04_instalar_nfs.sh - Comparticion de archivos para las salas Linux (NFSv4)
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Implementa el arbol de datos compartidos definido en analisis.md (seccion 6):
#
#   /srv/compartido/academicos    NFS y Samba (trabajos y guias)
#   /srv/compartido/secretaria    solo Samba (matriculas y certificados)
#   /srv/compartido/contabilidad  solo Samba (facturacion y cartera)
#   /srv/compartido/publico       NFS y Samba (material didactico, todos rw)
#
# Permisos por grupo POSIX (compartidos luego por Samba):
#   academicos  -> estudiantes y docentes (rw en academicos)
#   secretaria -> personal de secretaria (rw en secretaria)
#   contabilidad -> personal de contabilidad (rw en contabilidad)
#   publico     -> todos los usuarios con cuenta (rw en publico)
#
# Solo se exporta por NFS lo acordado en el diseño: academicos y publico,
# restringido a la red 192.168.80.0/24, con root_squash (el root del cliente
# no obtiene privilegios de root en el servidor).
#
# Se fuerza NFSv4 en el puerto 2049/tcp (sin v3, sin puertos aleatorios de
# rpc.mountd), lo que permite filtrarlo limpiamente con UFW.
#
# Uso:
#   sudo bash 04_instalar_nfs.sh
#
# Requiere: 01_preparar_servidor.sh ya ejecutado.
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
RED_LAN="192.168.80.0/24"
DIR_BASE="/srv/compartido"
CARPETAS=(academicos secretaria contabilidad publico)
GRUPOS=(academicos secretaria contabilidad publico)
ARCHIVO_EXPORTS="/etc/exports"
ARCHIVO_NFSD="/etc/nfs.conf.d/99-itec.conf"
FECHA="$(date +%Y%m%d-%H%M%S)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORTS_ORIGEN="${SCRIPT_DIR}/../configuraciones/exports"

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
info() { echo "[i] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ----------------------------- Verificaciones -------------------------------
if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo bash $0)."
    exit 1
fi

if [[ ! -f "${EXPORTS_ORIGEN}" ]]; then
    err "No se encontro la configuracion: ${EXPORTS_ORIGEN}"
    err "Ejecute el script desde el arbol del repositorio (codigo/instalacion)."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ========================= 1. Instalar el servidor NFS =======================
log "Instalando nfs-kernel-server..."
apt-get update -y
apt-get install -y nfs-kernel-server

# ========================= 2. Grupos y arbol de carpetas =====================
log "Creando grupos de acceso (si no existen)..."
for grupo in "${GRUPOS[@]}"; do
    if ! getent group "${grupo}" >/dev/null; then
        groupadd "${grupo}"
        log "  grupo creado: ${grupo}"
    else
        log "  grupo ya existe: ${grupo}"
    fi
done

log "Creando el arbol compartido en ${DIR_BASE}..."
for carpeta in "${CARPETAS[@]}"; do
    install -d -o root -g "${carpeta}" -m 2770 "${DIR_BASE}/${carpeta}"
done
# 'publico' es de libre escritura para usuarios con cuenta.
chown root:publico "${DIR_BASE}/publico"
chmod 2777 "${DIR_BASE}/publico"

log "Estructura resultante:"
ls -ld "${DIR_BASE}"/* | sed 's/^/  /'

# ========================= 3. Exportaciones NFS ==============================
if [[ -f "${ARCHIVO_EXPORTS}" ]] && ! grep -qE "^# === PROYECTO ITEC" "${ARCHIVO_EXPORTS}"; then
    cp "${ARCHIVO_EXPORTS}" "${ARCHIVO_EXPORTS}.bak.${FECHA}"
    info "Respaldo de ${ARCHIVO_EXPORTS}: ${ARCHIVO_EXPORTS}.bak.${FECHA}"
fi

# Se anade un bloque marcado al final (idempotente: se reemplaza si ya existe).
sed -i '/^# === PROYECTO ITEC/,/^# === FIN PROYECTO ITEC/d' "${ARCHIVO_EXPORTS}" 2>/dev/null || true
cat "${EXPORTS_ORIGEN}" >> "${ARCHIVO_EXPORTS}"
log "Exportaciones agregadas a ${ARCHIVO_EXPORTS} (academicos y publico, red ${RED_LAN})."

# ========================= 4. Solo NFSv4, puerto 2049 =========================
log "Fijando NFSv4 unico en el puerto 2049/tcp..."
install -d -m 755 /etc/nfs.conf.d
cat > "${ARCHIVO_NFSD}" <<'EOF'
# PROYECTO ITEC - solo NFSv4 en puerto fijo 2049/tcp
# (permite filtrar el servicio con UFW sin puertos dinamicos de NFSv3)
[nfsd]
    vers3=n
    vers4=y
    vers4.1=y
    vers4.2=y
    tcp=y
    udp=n
    port=2049
EOF

# ========================= 5. Arrancar y exportar ============================
log "Recargando exportaciones..."
exportfs -ra
exportfs -v | sed 's/^/  /'

log "Habilitando el servicio..."
systemctl enable --now nfs-kernel-server
systemctl restart nfs-kernel-server

# ========================= 6. Verificacion ===================================
sleep 3
if ! systemctl is-active --quiet nfs-kernel-server; then
    err "nfs-kernel-server no esta activo:"
    systemctl status nfs-kernel-server --no-pager || true
    journalctl -u nfs-kernel-server -n 15 --no-pager || true
    exit 1
fi
log "Servicio NFS activo."

log "Puerto NFS en escucha (2049/tcp):"
ss -tln | grep ':2049 ' || err "El puerto 2049 no aparecio; revise: ss -tlnp | grep nfsd"

# ========================= Resumen ===========================================
log "Servidor NFS configurado."
echo "------------------------------------------------------------"
echo " Exportaciones      : ${DIR_BASE}/{academicos,publico} -> ${RED_LAN}"
echo " Protocolo          : NFSv4.1/4.2 solo por 2049/tcp"
echo "------------------------------------------------------------"
echo " Montaje en un cliente Linux de sala:"
echo "   sudo mkdir -p /mnt/{academicos,publico}"
echo "   sudo mount -t nfs 192.168.80.10:/srv/compartido/academicos /mnt/academicos"
echo "   sudo mount -t nfs 192.168.80.10:/srv/compartido/publico     /mnt/publico"
echo "   df -h /mnt/academicos"
echo " Persistente en el cliente (/etc/fstab):"
echo "   192.168.80.10:/srv/compartido/academicos /mnt/academicos nfs4 defaults,_netdev 0 0"
echo "------------------------------------------------------------"
echo " Usuarios: agregue cuentas a los grupos con usuarios_nis.sh"
echo " (codigo/configuraciones) y reconstruya los mapas NIS."
echo "------------------------------------------------------------"
