# Codigo del proyecto

**Proyecto Final — Administración de Infraestructura de TI · Universidad del Quindio · 2026-1**
**Instituto Técnico de Educación Comfenalco Quindio**

Todo el código de la infraestructura del proyecto. Los scripts se escribieron y
revisaron **sin VM**, siguiendo la documentación oficial de cada componente
(los hechos verificados se citan en cada encabezado), y están preparados para
ejecutarse en la VM Ubuntu Server 24.04 LTS (`itec-server`, `192.168.80.10`).

## Contenido

| Carpeta | Contenido |
|---|---|
| `instalacion/` | Scripts numerados que se ejecutan en orden sobre la VM. |
| `configuraciones/` | Archivos de configuración que despliegan los scripts y utilidades operativas (DuckDNS, gestión de usuarios NIS). |
| `ssl/` | PKI local: CA propia + certificado del servidor para HTTPS en la LAN. |
| `seguridad/` | Firewall UFW (con reglas `DOCKER-USER`) y respaldo semanal cifrado. |
| `web/` | Sitio institucional (PHP 8.3) + `db/init.sql` (esquema PostgreSQL). |

## Orden de ejecución en la VM

Ejecutar como root (`sudo bash ...`) desde una copia local del repositorio
(por ejemplo `/root/proyecto/`), siguiendo las semanas del plan:

### Semana 2 — Infraestructura base

1. `instalacion/01_preparar_servidor.sh` — actualiza el SO, hostname
   `itec-server`, zona horaria, IP estática `192.168.80.10` (netplan), SSH
   sin root directo y actualizaciones automáticas.
2. `instalacion/02_instalar_dokploy.sh` — instala Docker + Dokploy con el
   instalador oficial (`ADVERTISE_ADDR` fijo a `192.168.80.10`). Panel en
   `http://192.168.80.10:3000`.
3. `instalacion/03_configurar_ntp.sh` — instala `ntpsec` y despliega
   `configuraciones/ntp.conf` (servidor de tiempo de la LAN en 123/udp).
4. `configuraciones/duckdns.sh` — actualiza `itec-quindio.duckdns.org`.
   El token NUNCA se sube al repositorio:
   `sudo ./duckdns.sh --instalar <TOKEN>` lo guarda en `/etc/duckdns/token`
   y programa el cron cada 5 minutos.
5. `ssl/certificado_autofirmado.sh` — CA local + certificado con SAN
   (`itec-quindio.duckdns.org`, `itec-server`, `192.168.80.10`) para Traefik
   y CUPS. Importar `ca.crt` en los clientes de confianza.
6. `seguridad/ufw_reglas.sh` — política denegatoria por defecto; puertos
   internos solo desde `192.168.80.0/24`; incluye filtrado `DOCKER-USER`
   para los puertos que Docker publica (3000, 5432).

### Semana 3 — Servicios

7. `instalacion/04_instalar_nfs.sh` — árbol `/srv/compartido` con grupos
   por dependencia, exportaciones NFSv4 (`configuraciones/exports`) solo
   para `academicos` y `publico` en 2049/tcp.
8. `instalacion/05_instalar_nis.sh` — servidor maestro NIS `itec.local`,
   `ypserv` en 834, `securenets` para la LAN, mapas con `MERGE_PASSWD`.
9. `configuraciones/usuarios_nis.sh` — alta/baja de estudiantes por lote
   (CSV `usuario;grupos;nombre`) y reconstrucción de mapas.
10. `instalacion/06_instalar_cups.sh` — impresión centralizada
    (`configuraciones/cupsd.conf`) con impresora virtual PDF para evidencias.
11. `instalacion/07_instalar_samba.sh` — recursos SMB en 445/tcp
    (`configuraciones/smb.conf`): `academicos`, `secretaria`,
    `contabilidad`, `publico`, con permisos por grupo.
12. `seguridad/respaldo.sh --instalar` — respaldo semanal cifrado
    (AES-256, clave en `/etc/itec/backup.key`) de `/srv/compartido` +
    PostgreSQL hacia `/srv/backups`, con retención de 4 semanas.

### Sitio web y base de datos (`web/`)

Dos formas de desplegar la misma aplicación:

- **Directa en la VM (docker compose):**
  1. `cp .env.example .env` y cambiar `POSTGRES_PASSWORD`.
  2. `docker compose up -d --build`.
  3. Sitio en `http://192.168.80.10:8080`, PostgreSQL en 5432 (solo LAN).
- **Con Dokploy (flujo del proyecto):** crear la aplicación desde el
  repositorio Git (detecta el `Dockerfile`), crear el PostgreSQL con usuario
  `itec_app`, base `itec`, y aplicar `db/init.sql`; registrar las variables
  de entorno `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS` y asociar
  el dominio `itec-quindio.duckdns.org` (con el certificado de `ssl/`).

## Notas de seguridad

- El token de DuckDNS y las claves de la base de datos y del cifrado de
  respaldos se guardan fuera del repositorio (`/etc/duckdns/token`,
  `.env`, `/etc/itec/backup.key`).
- `01_preparar_servidor.sh` hace el cambio de IP al final: si la sesión SSH
  se pierde, todo lo demás ya está aplicado (y la alternativa de reserva DHCP
  está documentada en `analisis.md`, sección 5).
- Los scripts son idempotentes (re-ejecutarlos no rompe la configuración) y
  respaldan cada archivo de sistema que modifican (`*.bak.<fecha>`).
