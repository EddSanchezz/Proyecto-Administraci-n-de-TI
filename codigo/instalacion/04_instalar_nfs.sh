#!/bin/bash
# ============================================================================
# 04_instalar_nfs.sh - comparticion de archivos para las salas linux (nfsv4)
# ----------------------------------------------------------------------------
# proyecto final - administracion de infraestructura de ti (uniquindio 2026-2)
# instituto tecnico de educacion comfenalco quindio
#
# implementa el arbol de datos compartidos definido en analisis.md (seccion 6):
#
#   /srv/compartido/academicos    nfs y samba (trabajos y guias)
#   /srv/compartido/secretaria    solo samba (matriculas y certificados)
#   /srv/compartido/contabilidad  solo samba (facturacion y cartera)
#   /srv/compartido/publico       nfs y samba (material didactico, todos rw)
#
# permisos por grupo posix (compartidos luego por samba):
#   academicos   -> estudiantes y docentes (rw en academicos)
#   secretaria   -> personal de secretaria (rw en secretaria)
#   contabilidad -> personal de contabilidad (rw en contabilidad)
#   publico      -> todos los usuarios con cuenta (rw en publico)
#
# solo se exporta por nfs lo acordado en el diseño: academicos y publico,
# restringido a la red 192.168.80.0/24, con root_squash (el root del cliente
# no obtiene privilegios de root en el servidor).
#
# se fuerza nfsv4 en el puerto 2049/tcp (sin v3, sin puertos aleatorios de
# rpc.mountd), lo que permite filtrarlo limpiamente con ufw.
# ============================================================================

# ----------------------------- Parametros fijos -----------------------------
NFS_EXPORTS_FILE="/etc/exports"
NFS_NET="192.168.80.0/24"
NFS_SERVER_IP="192.168.80.10"
NFS_SHARE_FOLDER="/srv/compartido"
CARPETAS=(academicos secretaria contabilidad publico)
GRUPOS=(academicos secretaria contabilidad publico)
NFS_CONF="/etc/nfs.conf"

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

# ----------------------------- Funciones -----------------------------------

# ====================== configuracion de grupos ======================
configurar_grupos() {
  info "Configurando grupos"

  for grupo in "${GRUPOS[@]}"; do
    if ! getent group "${grupo}" >/dev/null; then
      groupadd "${grupo}"
      log "  grupo creado: ${grupo}"
    else
      log "  grupo ya existe: ${grupo}"
    fi
  done

  log "Grupos configurados correctamente"
}

# ====================== configuracionde carpetas ======================
configurar_carpetas() {
  info "Creando el arbol compartido en ${NFS_SHARE_FOLDER}..."

  for carpeta in "${CARPETAS[@]}"; do
    install -d -o root -g "${carpeta}" -m 2770 "${NFS_SHARE_FOLDER}/${carpeta}"
  done

  # 'publico' es de libre escritura para usuarios con cuenta.
  chown root:publico "${NFS_SHARE_FOLDER}/publico"
  chmod 2777 "${NFS_SHARE_FOLDER}/publico"

  log "Carpetas configuradas correctamente"
}

# ====================== instalacion de nis en servidor ======================
instalar_servidor() {
  # actualizar repositorios
  info "INSTALANDO PAQUETES"

  apt-get update -qq
  apt-get install nfs-kernel-server -y -qq

  log "PAQUETES INSTALADOS"

  # configurar carpetas y grupos
  configurar_grupos
  configurar_carpetas

  # configuracion de exports
  echo "# Generado automaticamente - exportacion carpeta compartida" > "$NFS_EXPORTS_FILE"
  echo "$NFS_SHARE_FOLDER $NFS_NET(rw,sync,no_root_squash,no_subtree_check,nocrossmnt)" >> "$NFS_EXPORTS_FILE"

  log "CONFIGURACION DE EXPORTACION GENERRADA"

  cp -an "$NFS_CONF" "${NFS_CONF}.bak"
 
  # configuracion de la version 4 de nfs y el puerto fijo
  sed -i -E '/^\[nfsd\]/,/^\[/{s/^\s*#?\s*vers3\s*=.*/vers3=n/}' "$NFS_CONF"
  sed -i -E '/^\[nfsd\]/,/^\[/{s/^\s*#?\s*port\s*=.*/port=2049/}' "$NFS_CONF"

  log "Demonio nfsd configurado"

  # recargar exportaciones y reiniciar servicios
  exportfs -ra
  systemctl enable --now nfs-kernel-server
  systemctl restart nfs-kernel-server

  # ========================= Resumen ===========================================
  log "Servidor NFS configurado."
  echo "------------------------------------------------------------"
  echo " Exportaciones      : ${NFS_SHARE_FOLDER}/{academicos,publico} -> ${NFS_NET}"
  echo " Protocolo          : NFSv4.1/4.2 solo por 2049/tcp"
  echo "------------------------------------------------------------"
  echo " Montaje manual en un cliente Linux de sala:"
  echo "   sudo mkdir -p /mnt/{academicos,publico}"
  echo "   sudo mount -t nfs 192.168.80.10:/srv/compartido/academicos /mnt/academicos"
  echo "   sudo mount -t nfs 192.168.80.10:/srv/compartido/publico /mnt/publico"
  echo "   df -h /mnt/academicos"
  echo " Persistente en el cliente (/etc/fstab):"
  echo "   192.168.80.10:/srv/compartido/academicos /mnt/academicos nfs4 defaults,_netdev 0 0"
  echo " Montaje usando el script:"
  echo "   sudo bash 04_instalar_nfs cliente"
  echo "------------------------------------------------------------"
  echo " Recomendacion: user junto a nis"
  echo " Usuarios: agregue cuentas a los grupos con usuarios_nis.sh"
  echo " (codigo/configuraciones) y reconstruya los mapas NIS."
  echo "------------------------------------------------------------"
}

# ====================== instalacion de nis en cliente ======================
instalar_cliente() {
  # actualizar repositorios
  info "INSTALANDO PAQUETES"

  apt update -qq
  apt install nfs-common autofs -y -q

  log "PAQUETES INSTALADOS"

  # configuracion autofs
  if [ ! -f "/etc/auto.home" ]; then
    touch /etc/auto.home
  fi

  if ! grep -qE "^\s*/srv/compartido" /etc/auto.home; then
    echo "$NFS_SHARE_FOLDER  -fstype=nfs,rw,soft,intr  $NFS_SERVER_IP:$NFS_SHARE_FOLDER" >> /etc/auto.home
  fi

  if ! grep -qE "/-\s*/etc/auto.home" /etc/auto.master; then
    echo "/- /etc/auto.home" >> /etc/auto.master
  fi

  log "AUTOFS CONFIGURADO"

  # iniciar servicio
  systemctl enable --now autofs
  systemctl restart autofs

  log "INSTALACION COMPLETADA"
}

# ----------------------------- Ejecucion -----------------------------------
if [ -z "${1:-}" ]; then
  err "DEBE ELEGIR UNA OPCION: servidor|cliente"
  exit 1
elif [ "$1" = "servidor" ]; then
  instalar_servidor
elif [ "$1" = "cliente" ]; then
  instalar_cliente
else
  err "OPCION DE INSTALACION INVALIDA"
  exit 1
fi

