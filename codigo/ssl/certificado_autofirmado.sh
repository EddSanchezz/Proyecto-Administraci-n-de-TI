#!/usr/bin/env bash
# ============================================================================
# certificado_autofirmado.sh - PKI local para HTTPS en la LAN
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Genera una pequeña CA local y un certificado de servidor firmado por ella,
# valido para:
#   - itec-quindio.duckdns.org (dominio publico del proyecto)
#   - itec-server / itec-server.lan (nombre interno del servidor)
#   - 192.168.80.10 y localhost (acceso directo por IP)
#
# Ventajas frente a un certificado autofirmado simple: solo se importa la CA
# (ca.crt) en los clientes y TODOS los servicios del servidor que presenten
# certificados firmados por ella se muestran confiables; ademas se pueden
# renovar los certificados de servidor sin volver a tocar los clientes.
#
# Uso:
#   sudo bash certificado_autofirmado.sh            # genera CA + certificado
#   sudo bash certificado_autofirmado.sh --servidor # regenera SOLO el de servidor
#
# Salida en /etc/ssl/itec/:
#   ca.crt        (publico: importar en clientes)          permisos 644
#   ca.key        (privado: NO salir del servidor)        permisos 600
#   servidor.crt  (publico: usar en Traefik/Dokploy/CUPS) permisos 644
#   servidor.key  (privado: usar en Traefik/Dokploy/CUPS) permisos 600
#
# Validez: CA 10 anos; certificado de servidor 825 dias (limite aceptado
# por los almacenes de confianza modernos).
#
# Distribucion de la CA de confianza en clientes:
#   Windows: doble clic en ca.crt > Instalar certificado >
#            Equipo local > "Entidades de certificacion en las que confio"
#   Linux:   sudo cp ca.crt /usr/local/share/ca-certificates/itec-ca.crt
#            sudo update-ca-certificates
#   Firefox: Administracion > Certificados > Importar (marcar confianza web)
# ============================================================================

set -euo pipefail

# ----------------------------- Parametros fijos -----------------------------
DIR_SSL="/etc/ssl/itec"
DIAS_CA="3650"
DIAS_SERVIDOR="825"
TAMANO_RSA="4096"
PAIS="CO"
ORG="Instituto Tecnico de Educacion Comfenalco Quindio"
OU="Infraestructura de TI"
# Dominio principal del despliegue. En el laboratorio se usa sslip.io porque
# resuelve sin registro y sin IP publica; DuckDNS queda como alternativa.
CN_DOMINIO="${CN_DOMINIO:-itec.192-168-80-10.sslip.io}"
FECHA="$(date +%Y%m%d-%H%M%S)"

# ----------------------------- Utilidades -----------------------------------
log()  { echo "[+] $*"; }
info() { echo "[i] $*"; }
err()  { echo "[ERROR] $*" >&2; }

if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root (sudo bash $0)."
    exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
    log "Instalando openssl..."
    apt-get update -y
    apt-get install -y openssl
fi

mkdir -p "${DIR_SSL}"
cd "${DIR_SSL}"

# ========================= 1. Autoridad certificadora ========================
if [[ ! -f ca.key || "${1:-}" != "--servidor" ]]; then
    if [[ -f ca.key && -f ca.crt ]]; then
        log "Ya existe una CA local (${DIR_SSL}/ca.crt). No se regenera."
        log "Use '--servidor' si solo quiere renovar el certificado del servidor."
    else
        log "Generando CA local (RSA ${TAMANO_RSA}, ${DIAS_CA} dias)..."
        openssl req -x509 -newkey "rsa:${TAMANO_RSA}" -nodes \
            -keyout ca.key -out ca.crt -days "${DIAS_CA}" \
            -subj "/C=${PAIS}/O=${ORG}/OU=${OU}/CN=CA ITEC Quindio"
        chmod 600 ca.key
        chmod 644 ca.crt
        log "CA generada: ${DIR_SSL}/ca.crt"
    fi
else
    log "Modo --servidor: se reutiliza la CA existente."
fi

# ========================= 2. Certificado del servidor =======================
# Se hace con CSR para firmar con la CA y asi poder renovar solo este par.
log "Generando solicitud (CSR) del servidor..."

# Extensiones modernas: SAN obligatorio (los navegadores ignoran el CN).
cat > san_itec.cnf <<EOF
[req]
distinguished_name = dn
req_extensions     = san
prompt             = no

[dn]
C  = ${PAIS}
O  = ${ORG}
OU = ${OU}
CN = ${CN_DOMINIO}

[san]
subjectAltName = @nombres

[nombres]
DNS.1 = ${CN_DOMINIO}
DNS.2 = itec-server
DNS.3 = itec-server.lan
DNS.4 = localhost
DNS.5 = itec-quindio.duckdns.org
IP.1  = 192.168.80.10
IP.2  = 127.0.0.1
EOF

openssl req -new -newkey "rsa:${TAMANO_RSA}" -nodes \
    -keyout servidor.key -out servidor.csr \
    -config san_itec.cnf

# Extension de uso del certificado al firmar.
cat > ext_servidor.cnf <<EOF
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @nombres

[nombres]
DNS.1 = ${CN_DOMINIO}
DNS.2 = itec-server
DNS.3 = itec-server.lan
DNS.4 = localhost
DNS.5 = itec-quindio.duckdns.org
IP.1  = 192.168.80.10
IP.2  = 127.0.0.1
EOF

log "Firmando el certificado del servidor con la CA local (${DIAS_SERVIDOR} dias)..."
openssl x509 -req -in servidor.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out servidor.crt -days "${DIAS_SERVIDOR}" \
    -extfile ext_servidor.cnf

chmod 600 servidor.key
chmod 644 servidor.crt

# Material intermedio y respaldo de la configuracion usada.
cp san_itec.cnf "san_itec.cnf.bak.${FECHA}"
rm -f servidor.csr ext_servidor.cnf san_itec.cnf ca.srl

# ========================= 3. Verificacion ==================================
log "Verificando el certificado generado..."
openssl verify -CAfile ca.crt servidor.crt

log "Campos del certificado (subject, emisor y SAN):"
openssl x509 -in servidor.crt -noout -subject -issuer
openssl x509 -in servidor.crt -noout -text | grep -A 1 "Subject Alternative Name"

# ========================= Resumen ===========================================
log "Certificados listos en ${DIR_SSL}:"
ls -l "${DIR_SSL}"
echo "------------------------------------------------------------"
echo " ca.crt        : importar en los clientes (confianza)"
echo " servidor.crt/key : usar en Dokploy/Traefik y en CUPS (631)"
echo "------------------------------------------------------------"
echo " Uso en Dokploy: panel > Certificates > importar"
echo "   Certificate: ${DIR_SSL}/servidor.crt"
echo "   Private key: ${DIR_SSL}/servidor.key"
echo " y asociar el certificado al dominio ${CN_DOMINIO}."
echo "------------------------------------------------------------"
echo " Nota: para produccion con dominio publico y puertos 80/443"
echo " redirigidos en el router, se puede usar Let's Encrypt desde"
echo " Dokploy/Traefik; esta PKI local es la alternativa sin exponer"
echo " el servidor a internet (escenario de laboratorio del curso)."
echo "------------------------------------------------------------"
