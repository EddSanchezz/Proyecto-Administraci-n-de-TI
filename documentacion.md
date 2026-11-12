# Documentación Técnica

**Proyecto Final — Administración de Infraestructura de TI · Universidad del Quindío · 2026-1**

| | |
|---|---|
| **Empresa** | Instituto Técnico de Educación Comfenalco Quindío |
| **Servidor** | Ubuntu Server 24.04 LTS · `192.168.80.10` · hostname `itec-server` |
| **Dominio** | `https://itec.192-168-80-10.sslip.io` (DNS gratuito sin registro) |
| **Equipo** | Esteban · Jerónimo · Brahian · Jack Alejandro Marín Hernández |

> Plantilla de trabajo: completar cada sección durante las semanas 2–4. Por cada servicio se documenta: **procedimiento de instalación**, **comandos de verificación y pruebas**, **capturas de evidencia** (guardarlas en `capturas/`) y **problemas encontrados con su solución**.

## Índice

1. Preparación de la máquina virtual
2. Instalación de Dokploy
3. Dominio/DNS y SSL/TLS
4. Servicio NTP
5. Sitio web institucional
6. Base de datos PostgreSQL
7. Servicio NFS
8. Servicio NIS
9. Servicio CUPS
10. Servicio Samba
11. Firewall y respaldos (extras)
12. Bitácora de problemas

---

## 1. Preparación de la máquina virtual

**Procedimiento**

- [ ] Crear VM en VirtualBox/VMware: 2 vCPU, 4 GB RAM, 40 GB disco, red bridged
- [ ] Instalar Ubuntu Server 24.04 LTS con hostname `itec-server`
- [ ] Configurar IP estática `192.168.80.10/24`, gateway `192.168.80.1`
- [ ] Crear usuario administrador y habilitar SSH

**Verificación**

```
ip a                          # confirmar IP 192.168.80.10
ping -c 3 8.8.8.8             # salida a internet
ssh usuario@192.168.80.10      # acceso remoto
```

**Evidencias:** `capturas/01_vm/`

**Problemas encontrados y solución:** *(completar)*

---

## 2. Instalación de Dokploy

**Procedimiento** — script: `codigo/instalacion/02_instalar_dokploy.sh`

- [ ] Instalar Docker (si no está) y ejecutar el instalador oficial de Dokploy
- [ ] Acceder al panel en `http://192.168.80.10:3000` y crear cuenta de administrador

**Verificación**

```
docker ps                     # contenedores de Dokploy activos
systemctl status docker
```

**Evidencias:** `capturas/02_dokploy/`

**Problemas encontrados y solución:** *(completar)*

---

## 3. Dominio/DNS y SSL/TLS

- [ ] Dominio/DNS: en el laboratorio se usa `itec.192-168-80-10.sslip.io` (DNS gratuito sin registro; resuelve a `192.168.80.10`). La variante DuckDNS (`itec-quindio.duckdns.org`) queda documentada para cuando exista IP pública; script: `codigo/configuraciones/duckdns.sh`.
- [ ] Certificado TLS: CA propia + certificado del servidor con `codigo/ssl/certificado_autofirmado.sh`; importar `ca.crt` en los clientes y asociar el certificado al dominio en Dokploy. Let's Encrypt queda como alternativa si los puertos 80/443 están reenviados.

**Verificación:** `https://itec.192-168-80-10.sslip.io` carga sin advertencias; candado verde (CA importada).

**Evidencias:** `capturas/03_dns_ssl/`

**Problemas encontrados y solución:** *(completar)*

---

## 4. Servicio NTP

**Procedimiento** — scripts: `codigo/instalacion/03_configurar_ntp.sh` · configuración: `codigo/configuraciones/ntp.conf`

**Verificación**

```
ntpq -p                       # el servidor sincroniza con pool.ntp.org
# Cliente Linux:
chronyc tracking  |  ntpq -p  # apunta a 192.168.80.10
# Cliente Windows:
w32tm /query /status
```

**Evidencias:** `capturas/04_ntp/`

**Problemas encontrados y solución:** *(completar)*

---

## 5. Sitio web institucional

- [ ] Desplegar la app desde Git con Dokploy (Nixpacks/Dockerfile) — código: `codigo/web/`
- [ ] Verificar contenido real del instituto: programas técnicos, admisión y matrícula, contacto

**Verificación:** carga vía HTTPS; el formulario de preinscripción registra en PostgreSQL.

**Evidencias:** `capturas/05_web/`

**Problemas encontrados y solución:** *(completar)*

---

## 6. Base de datos PostgreSQL

- [ ] Crear la base de datos desde Dokploy — esquema: `codigo/web/db/init.sql`
- [ ] Conectar la aplicación web

**Verificación**

```
docker exec -it <contenedor_db> psql -U itec_app -d itec -c "\dt"
```

**Evidencias:** `capturas/06_bd/`

**Problemas encontrados y solución:** *(completar)*

---

## 7. Servicio NFS

**Procedimiento** — script: `codigo/instalacion/04_instalar_nfs.sh` · configuración: `codigo/configuraciones/exports` (crea el árbol y los grupos; exporta `academicos` y `publico` solo para la LAN, NFSv4 único en 2049/tcp)

```
sudo apt install nfs-kernel-server -y
sudo mkdir -p /srv/compartido/{academicos,secretaria,contabilidad,publico}
sudo nano /etc/exports
sudo exportfs -ra
sudo systemctl enable --now nfs-kernel-server
```

**Verificación (cliente Linux de sala)**

```
sudo mount -t nfs 192.168.80.10:/srv/compartido/academicos /mnt/academicos
df -h /mnt/academicos
```

**Evidencias:** `capturas/07_nfs/`

**Problemas encontrados y solución:** *(completar)*

---

## 8. Servicio NIS

**Procedimiento** — script: `codigo/instalacion/05_instalar_nis.sh` (dominio `itec.local`, `ypserv` en 834, `securenets` para la LAN, mapas con contraseñas fusionadas) · alta/baja de estudiantes por lote: `codigo/configuraciones/usuarios_nis.sh`

**Verificación**

```
ypcat passwd                      # cuentas de estudiantes centralizadas visibles
ypwhich                           # servidor NIS en uso
```

**Evidencias:** `capturas/08_nis/`

**Problemas encontrados y solución:** *(completar)*

---

## 9. Servicio CUPS

**Procedimiento** — script: `codigo/instalacion/06_instalar_cups.sh` · configuración: `codigo/configuraciones/cupsd.conf` (incluye la impresora virtual PDF para evidenciar colas sin impresora física)

**Verificación:** administrar impresoras en `https://192.168.80.10:631`; imprimir página de prueba desde un cliente.

**Evidencias:** `capturas/09_cups/`

**Problemas encontrados y solución:** *(completar)*

---

## 10. Servicio Samba

**Procedimiento** — script: `codigo/instalacion/07_instalar_samba.sh` · configuración: `codigo/configuraciones/smb.conf` (recursos por grupo POSIX; SMB directo en 445, sin NetBIOS)

**Verificación**

```
smbclient //192.168.80.10/secretaria -U usuario
# Desde Windows: \\itec-server\secretaria
```

**Evidencias:** `capturas/10_samba/`

**Problemas encontrados y solución:** *(completar)*

---

## 11. Firewall y respaldos (extras)

- [ ] Aplicar reglas UFW — script: `codigo/seguridad/ufw_reglas.sh` (incluye el filtrado `DOCKER-USER` de los puertos que publica Docker)
- [ ] Programar respaldo semanal de `/srv/compartido` + volcado de PostgreSQL — script: `codigo/seguridad/respaldo.sh` (instalar con `sudo ./respaldo.sh --instalar`)

**Verificación**

```
sudo ufw status verbose
```

**Evidencias:** `capturas/11_seguridad/`

**Problemas encontrados y solución:** *(completar)*

---

## 12. Bitácora de problemas

| # | Fecha | Servicio | Problema | Solución aplicada |
|---|---|---|---|---|
| 1 | | | | |

---

*Documentación elaborada para el Proyecto Final del curso Administración de Infraestructura de TI — Universidad del Quindío, 2026-1.*
