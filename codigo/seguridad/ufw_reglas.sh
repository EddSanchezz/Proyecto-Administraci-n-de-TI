#!/usr/bin/env bash
# ============================================================================
# ufw_reglas.sh - Politica de firewall del servidor ITEC
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Politica (analisis.md, seccion 7): denegar todo el trafico entrante,
# permitir el saliente, y abrir SOLO lo siguiente:
#
#   Puerto  Servicio             Origen permitido
#   ------  -------------------   ----------------------------------
#   22/tcp  SSH administrativo    cualquier origen (con rate-limit)
#   80/tcp  HTTP (Traefik)        cualquier origen (redireccion a HTTPS
#                                 y validacion Let's Encrypt)
#   443/tcp HTTPS (Traefik)       cualquier origen
#   3000/tcp Panel Dokploy        solo 192.168.80.0/24
#   5432/tcp PostgreSQL           solo 192.168.80.0/24
#   123/udp NTP                   solo 192.168.80.0/24
#   111     rpcbind               solo 192.168.80.0/24 (clientes NIS)
#   834     ypserv (NIS)          solo 192.168.80.0/24 (puerto fijado con -p)
#   2049/tcp NFSv4                solo 192.168.80.0/24
#   445/tcp Samba                 solo 192.168.80.0/24 (solo SMB directo,
#                                 sin NetBIOS 137-139)
#   631     CUPS (IPP)            solo 192.168.80.0/24
#
# IMPORTANTE - Docker y UFW: los puertos que Docker publica (por ejemplo el
# 3000 del panel de Dokploy) NO pasan por las reglas UFW de INPUT porque van
# por NAT a la cadena FORWARD. Por eso este script ademas instala reglas en
# la cadena DOCKER-USER (la unica cadena de Docker pensada para filtrar el
# trafico publicado) y las hace persistentes con una unidad de systemd.
#
# Uso:
#   sudo bash ufw_reglas.sh
#
# Advertencia: 'ufw reset' borra TODAS las reglas anteriores y parte de cero
# con las de este proyecto. Es intencional, para que el resultado sea
# reproducible; si ya tenia reglas propias, respaldelas antes.
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
RED_LAN="${RED_LAN:-192.168.80.0/24}"
PUERTOS_LAN_TCP=(3000 5432 2049 445 631 111 834)
PUERTOS_LAN_UDP=(123 631 111 834)
PUERTOS_PUBLICOS_TCP=(22 80 443)

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
info() { echo "[i] $*"; }
err()  { echo "[ERROR] $*" >&2; }

if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo bash $0)."
    exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y ufw
fi

# ========================= 1. Politicas base =================================
log "Reiniciando UFW desde cero (politica reproducible del proyecto)..."
ufw --force reset >/dev/null

ufw default deny incoming
ufw default allow outgoing
log "Politicas base: entrante DENEGADO, saliente PERMITIDO."

# ========================= 2. Reglas =========================================
# SSH con limitacion de tasa: bloquea fuentes que intenten conectar mas de
# 6 veces en 30 segundos (proteccion contra fuerza bruta).
ufw limit 22/tcp comment 'SSH administrativo con rate-limit'
log "SSH (22/tcp) permitido con rate-limit."

for puerto in "${PUERTOS_PUBLICOS_TCP[@]:1}"; do
    ufw allow "${puerto}/tcp" comment 'Web Traefik HTTP/HTTPS'
done
log "HTTP (80) y HTTPS (443) permitidos para Traefik."

for puerto in "${PUERTOS_LAN_TCP[@]}"; do
    ufw allow from "${RED_LAN}" to any port "${puerto}" proto tcp \
        comment "Servicio interno ${puerto}/tcp solo LAN"
done

for puerto in "${PUERTOS_LAN_UDP[@]}"; do
    ufw allow from "${RED_LAN}" to any port "${puerto}" proto udp \
        comment "Servicio interno ${puerto}/udp solo LAN"
done
log "Servicios internos restringidos a ${RED_LAN}:"
log "  3000 Dokploy | 5432 PostgreSQL | 123 NTP | 111+834 NIS | 2049 NFS | 445 Samba | 631 CUPS"

# Registro de eventos bloqueados a nivel bajo (suficiente para auditar sin
# llenar el disco de logs).
ufw logging low

# ========================= 3. Activar ========================================
log "Activando UFW..."
ufw --force enable

# ========================= 4. Reglas DOCKER-USER ============================
# Filtra los puertos publicados por Docker (bypass de UFW). Se aplican ahora
# y en cada arranque mediante una unidad de systemd.
if command -v docker >/dev/null 2>&1 && command -v iptables >/dev/null 2>&1; then
    HELPER="/usr/local/sbin/itec-docker-user.sh"

    cat > "${HELPER}" <<'EOF'
#!/usr/bin/env bash
# Reglas DOCKER-USER para puertos publicados por Docker (proyecto ITEC).
# Ejecutado por itec-docker-user.service en cada arranque (tras Docker).
set -euo pipefail
RED_LAN="__RED_LAN__"

# No tocar la cadena si Docker aun no la creo.
iptables -L DOCKER-USER -n >/dev/null 2>&1 || exit 0

# 1. Mantener el trafico de conexiones ya establecidas.
iptables -C DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN 2>/dev/null || \
    iptables -I DOCKER-USER 1 -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN

# 2. Panel de Dokploy (3000) y PostgreSQL (5432) publicados por Docker:
#    solo accesibles desde la LAN, igual que la regla UFW equivalente.
for puerto in 3000 5432; do
    iptables -C DOCKER-USER -p tcp --dport "${puerto}" ! -s "${RED_LAN}" -j DROP 2>/dev/null || \
        iptables -I DOCKER-USER 2 -p tcp --dport "${puerto}" ! -s "${RED_LAN}" -j DROP
done
EOF
    sed -i "s|__RED_LAN__|${RED_LAN}|g" "${HELPER}"
    chmod 700 "${HELPER}"

    cat > /etc/systemd/system/itec-docker-user.service <<EOF
[Unit]
Description=Reglas DOCKER-USER para puertos Docker del proyecto ITEC
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
ExecStart=${HELPER}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable itec-docker-user.service >/dev/null 2>&1 || true

    # Docker ya esta corriendo: aplicar de inmediato.
    if systemctl is-active --quiet docker; then
        "${HELPER}"
        log "Reglas DOCKER-USER aplicadas (3000 y 5432 solo LAN, sobreviven reinicios)."
    fi
else
    info "Docker/iptables no disponibles todavia. Ejecute este script de nuevo"
    info "despues de instalar Dokploy para filtrar el puerto 3000 en DOCKER-USER."
fi

# ========================= 5. Verificacion ===================================
log "Reglas activas (ufw status verbose):"
ufw status verbose

echo "------------------------------------------------------------"
echo " Verificar desde un equipo de la LAN:"
echo "   ssh usuario@192.168.80.10        (debe conectar)"
echo "   curl -I http://192.168.80.10      (responde Traefik)"
echo " Desde FUERA de la LAN: 3000, 5432, 2049, 445, 631, 123, 834 y 111"
echo " deben rechazarse (timeout)."
echo "------------------------------------------------------------"
