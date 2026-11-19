#!/usr/bin/env bash
# ============================================================================
# 05_instalar_nis.sh - Autenticacion centralizada para las salas Linux (NIS)
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Configura el servidor como maestro NIS del dominio 'itec.local':
#   - Paquete 'nis' (ypserv + ypbind + yp-tools, disponibles en Ubuntu 24.04).
#   - Dominio NIS: itec.local (archivo /etc/defaultdomain).
#   - Modo maestro: NISSERVER=master en /etc/default/nis.
#   - ypserv fijado en el puerto 834 (YPSERVARGS="-p 834") para filtrarlo
#   - /var/yp/securenets: solo localhost y 192.168.80.0/24 pueden consultar.
#
# LIMITACION ACEPTADA EN EL DISEÑO (analisis.md, seccion 7): NIS viaja sin
# cifrado; se mitiga limitandolo a la LAN y con reglas UFW por subred.
#
# Recomendacion: 
#   instalar junto al servicio nfs (04_instalar_nfs)
# ============================================================================

# ----------------------------- Parametros fijos -----------------------------
SECURENETS_FILE="/etc/ypserv.securenets"
NIS_CONF="/etc/default/nis"
NIS_DOMAIN="itec.local"
NIS_NET="192.168.80.0"
NIS_MASK="255.255.255.0"
NSSWITCH_FILE="/etc/nsswitch.conf"
NIS_SERVER_IP="192.168.80.10"
YPSERV_PORT=834

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
info() { echo "[i] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ----------------------------- Verificaciones -------------------------------
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  err "Este script debe ejecutarse como root (sudo bash $0)."
  exit 1
fi

# ------------------------------ Funciones -----------------------------------
#
# =================== instalacion de nis para el servidor maestro =================
instalar_servidor() {
  info "INSTALANDO PAQUETES"

  apt update -qq
  apt install nis -y -qq

  log "PAQUETES INSTALADOS"

  # configuracion del comportamiento como servidor nis
  if grep -qE '^#?\s*NISSERVER=' "$NIS_CONF"; then
    sed -i -E 's/^#?\s*NISSERVER=.*/NISSERVER=master/' "$NIS_CONF"
  else
    echo "NISSERVER=master" >> "$NIS_CONF"
  fi

  # configuracion del puerto de nis
  if grep -qE '^#?\s*YPSERVARGS=\s*' "$NIS_CONF"; then
    sed -i -E "s/^#?\s*YPSERVARGS=.*/YPSERVARGS=-p ${YPSERV_PORT}/" "$NIS_CONF"
  else 
    echo "YPSERVARGS=-p ${YPSERV_PORT}" >> "$NIS_CONF"
  fi

  # configuracion de acceso al servicio
  echo "# Generado automaticamente - restringir ypserv a red local" > "$SECURENETS_FILE"
  echo "255.255.255.255 127.0.0.1" >> "$SECURENETS_FILE"
  echo "${NIS_MASK} ${NIS_NET}" >> "$SECURENETS_FILE"

  # Asignacion del dominio
  echo "$NIS_DOMAIN" | tee /etc/defaultdomain
  domainname "$NIS_DOMAIN"

  log "NIS CONFIGURADO"

  # reinicio de los servicio
  systemctl restart rpcbind ypserv

  # actualizacion de la lista
  printf "\x04" | /usr/lib/yp/ypinit -m

  # regenerar mapa de usuarios
  make -C /var/yp

  # Resumen
  log "Servidor NIS configurado."
  echo "------------------------------------------------------------"
  echo " Dominio NIS   : ${NIS_DOMAIN}"
  echo " Servidor      : 192.168.80.10 (ypserv en ${YPSERV_PORT} + rpcbind 111)"
  echo " Red autorizada: ${NIS_NET} (secretnets)"
  echo "------------------------------------------------------------"
  echo " Alta de estudiantes por lote:"
  echo "   sudo bash codigo/configuraciones/usuarios_nis.sh alta usuarios.csv"
  echo " Configuracion manual de un CLIENTE Linux de sala:"
  echo "   sudo apt install nis"
  echo "   echo 'domain ${DOMINIO_NIS} server 192.168.80.10' >> /etc/yp.conf"
  echo "   sudo systemctl enable --now rpcbind nis"
  echo "   sudo sed -i 's/^(passwd:.*)/\1 nis/' /etc/nsswitch.conf"
  echo "   sudo sed -i 's/^(group:.*)/\1 nis/'  /etc/nsswitch.conf"
  echo "   ypcat passwd   (listar cuentas)"
  echo "   ypwhich        (debe responder 192.168.80.10)"
  echo " Configuracion usando el script:"
  echo "   sudo bash 05_instalar_nis cliente"
  echo "------------------------------------------------------------"
}

# =================== instalacion de nis para cliente =================
actualizar_lista_usuarios() {
  info "ACTUALIZANDO LISTA"
  make -C /var/yp
  log "LISTA DE USUARIOS ACTUALIZADA"
}

# =================== instalacion de nis para cliente =================
instalar_cliente() {
  info "INSTALANDO PAQUETES"

  apt update -qq
  apt install nis -y -qq

  log "PAQUETES INSTALADOS"

  # configuracion del comportamiento como servidor nis
  info  "CONFIGURANDO NIS"

  if grep -qE '^#?\s*NISCLIENT=' "$NIS_CONF"; then
    sed -i -E 's/^#?\s*NISCLIENT=.*/NISSERVER=true/' "$NIS_CONF"
  else
    echo "NISCLIENT=true" >> "$NIS_CONF"
  fi

  # configuracion del nsswitch para consultar nis
  cp -an "$NSSWITCH_FILE" "${NSSWITCH_FILE}.bak"

  for db in passwd group shadow; do
    if grep -qE "^${db}:" "$NSSWITCH_FILE"; then
      if ! grep -qE "^${db}:.*\bnis\b" "$NSSWITCH_FILE"; then
        sed -i -E "s/^(${db}:.*)/\1 nis/" "$NSSWITCH_FILE"
      fi
    else
      echo "${db}: files nis" >> "$NSSWITCH_FILE"
    fi
  done

  # Asignacion del dominio
  echo "$NIS_DOMAIN" | tee /etc/defaultdomain
  domainname "$NIS_DOMAIN"

  # configuracion para asignar el servidor nis
  echo "# Generado automaticamente - mapeo de servidor nis" > /etc/yp.conf
  echo "ypserver $NIS_SERVER_IP" >> /etc/yp.conf

  log "NIS CONFIGURADO"
  systemctl restart rpcbind ypbind
  log "INSTALACION COMPLETADA"
}

# ========================= instalacion segun el caso =========================

if [[ -z "${1:-}" ]]; then
  err "DEBE ELEGIR UNA OPCION ENTRE: servidor|cliente"
  exit 1
fi

if [[ "$1" = "servidor" ]]; then
  if [ -n "${2:-}" ] && [ "$2" = "usuarios" ]; then
    actualizar_lista_usuarios
  else
    instalar_servidor
  fi
elif [[ "$1" = "cliente" ]]; then
  instalar_cliente
else
  err "OPCION DE INSTALACION INVALIDA"
  exit 1
fi

