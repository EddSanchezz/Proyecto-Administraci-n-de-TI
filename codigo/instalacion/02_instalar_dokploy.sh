#!/usr/bin/env bash
# ============================================================================
# 02_instalar_dokploy.sh
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Instala Docker (si falta) y la plataforma Dokploy en el servidor Ubuntu
# 24.04 LTS, usando el instalador oficial documentado:
#   https://docs.dokploy.com/docs/core/installation
#
# Que hace Dokploy por dentro:
#   - Inicializa Docker Swarm en modo single-node.
#   - Despliega Traefik como proxy inverso (puertos 80 y 443).
#   - Levanta el panel web en el puerto 3000 y su PostgreSQL interno.
#
# Uso:
#   sudo bash 02_instalar_dokploy.sh
#
# Requisitos previos: 01_preparar_servidor.sh ya ejecutado.
# Puertos libres necesarios: 80, 443, 3000.
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
IP_SERVIDOR="${IP_SERVIDOR:-192.168.80.10}"
PUERTO_PANEL="${PUERTO_PANEL:-3000}"
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

# Memoria y disco: Dokploy requiere minimo 1 GB RAM y 10 GB libres.
RAM_MB="$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)"
DISCO_MB="$(df -m / | awk 'NR==2 {print $4}')"
info "RAM detectada: ${RAM_MB} MB | Espacio libre en /: ${DISCO_MB} MB"
if [[ "${RAM_MB}" -lt 900 ]]; then
    err "Se requieren al menos 1 GB de RAM (recomendado 2 GB). Asigne mas memoria a la VM."
    exit 1
fi
if [[ "${DISCO_MB}" -lt 400 ]]; then
    err "Se requieren al menos 10 GB libres en disco. Aumente el disco de la VM."
    exit 1
fi

# Puertos requeridos libres (el instalador oficial falla si estan ocupados).
for puerto in 80 443 "${PUERTO_PANEL}"; do
    if ss -tuln | awk '{print $5}' | grep -qE ":${puerto}$"; then
        err "El puerto ${puerto} ya esta en uso. Liberelo antes de instalar Dokploy."
        err "Procesos que lo usan: $(ss -tulnp | grep ":${puerto} " || true)"
        exit 1
    fi
done
log "Puertos 80, 443 y ${PUERTO_PANEL} disponibles."

export DEBIAN_FRONTEND=noninteractive

# ========================= 1. Docker ========================================
if command -v docker >/dev/null 2>&1; then
    log "Docker ya esta instalado: $(docker --version)"
else
    log "Instalando Docker Engine desde el repositorio oficial (get.docker.com)..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
fi

systemctl enable --now docker
if ! docker info >/dev/null 2>&1; then
    err "El servicio Docker no responde. Revise: systemctl status docker"
    exit 1
fi
log "Docker operativo: $(docker --version)"

# ========================= 2. Dokploy (instalador oficial) ==================
log "Descargando y ejecutando el instalador oficial de Dokploy..."
log "Se fija ADVERTISE_ADDR=${IP_SERVIDOR} para que Swarm use la IP de la LAN."
log "El proceso descarga imagenes y puede tardar entre 2 y 5 minutos."

# El instalador oficial de dokploy.com:
#   - instala Docker si falta,
#   - inicializa Swarm (usa ADVERTISE_ADDR si esta definida),
#   - despliega Traefik (80/443), el panel (3000) y su PostgreSQL interno.
curl -sSL https://dokploy.com/install.sh | ADVERTISE_ADDR="${IP_SERVIDOR}" sh

# ========================= 3. Verificacion ==================================
log "Verificando la instalacion..."

if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    err "Docker Swarm no quedo activo. Revise: docker info | grep Swarm"
    exit 1
fi
log "Docker Swarm activo (nodo manager unico)."

if ! docker service ls | grep -q dokploy; then
    err "No se encontraron los servicios de Dokploy. Revise: docker service ls"
    exit 1
fi
log "Servicios de Dokploy desplegados:"
docker service ls

log "Esperando a que el contenedor del panel arranque (maximo 90 s)..."
for i in $(seq 1 18); do
    if curl -fsS -o /dev/null --max-time 5 "http://127.0.0.1:${PUERTO_PANEL}" 2>/dev/null; then
        break
    fi
    sleep 5
done

if curl -fsS -o /dev/null --max-time 5 "http://127.0.0.1:${PUERTO_PANEL}"; then
    log "El panel de Dokploy responde en el puerto ${PUERTO_PANEL}."
else
    err "El panel aun no responde en el puerto ${PUERTO_PANEL}."
    err "Revise con: docker service logs -f dokploy"
    exit 1
fi

# ========================= Resumen ===========================================
log "Instalacion de Dokploy terminada."
echo "------------------------------------------------------------"
echo " Panel web      : http://${IP_SERVIDOR}:${PUERTO_PANEL}"
echo "                   (crear la cuenta de administrador en el"
echo "                    primer acceso; usar datos del equipo)"
echo " Proxy inverso  : Traefik en puertos 80 y 443"
echo " Contenido      : dokploy/ (volumenes dokploy-data, postgres-data)"
echo "------------------------------------------------------------"
echo " Siguientes pasos:"
echo "   1. Abrir http://${IP_SERVIDOR}:${PUERTO_PANEL} y crear la cuenta admin."
echo "   2. Ejecutar 03_configurar_ntp.sh"
echo "   3. Aplicar el firewall: codigo/seguridad/ufw_reglas.sh"
echo "   4. Registrar itec-quindio en DuckDNS y usar"
echo "      codigo/configuraciones/duckdns.sh"
echo "------------------------------------------------------------"
