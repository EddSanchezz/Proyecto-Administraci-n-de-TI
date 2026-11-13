# Documentación Técnica

**Proyecto Final — Administración de Infraestructura de TI · Universidad del Quindío · 2026-2**

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
13. Exportación de configuraciones P4
14. Guion de demostración P4

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

### 1.1 Entorno P4 (VM de pruebas)

> Esta subsección documenta la ejecución de la parte P4 (`guia.md`: NTP, CUPS y Samba) en una VM independiente. El entorno del diseño grupal (`192.168.80.10`) se conserva arriba; los valores siguientes son los reales de la VM de P4.

| Dato | Valor |
|---|---|
| Hipervisor | VirtualBox |
| Sistema operativo | Ubuntu **26.04.1 LTS** (instalado; el diseño preveía 24.04) |
| Red del PC (Windows) | `192.168.1.4/24` |
| Puerta de enlace | `192.168.1.1` |
| Interfaz de la VM | `enp0s3` |
| IP inicial de la VM (DHCP) | `192.168.1.8/24` |
| IP fija elegida | `192.168.1.50/24` (verificada libre) |
| Usuario Linux | `kami` |
| Archivos Netplan | `00-installer-config.yaml`, `01-network-manager-all.yaml` |

**Procedimiento**

- [x] Verificar la red del PC con `ipconfig` (`192.168.1.4/24`, máscara `255.255.255.0`).
- [x] Verificar que la VM responde en la misma subred (`ping 192.168.1.8` desde Windows).
- [x] Verificar que `192.168.1.50` está libre (`ping` sin respuesta).
- [x] Confirmar que el renderer activo es NetworkManager (`systemctl is-active systemd-networkd NetworkManager`).
- [x] Configurar la IP fija `192.168.1.50/24` con Netplan (`00-installer-config.yaml`; se conservó `01-network-manager-all.yaml`).
- [x] Confirmar adaptador puente en VirtualBox y tomar la captura C01.
- [x] Actualizar Ubuntu e instalar/habilitar SSH.
- [x] Probar `ping` y `ssh` desde Windows (captura C03).
- [x] Crear snapshot "base_limpia".

> La captura C01 muestra el adaptador en modo puente sobre `Realtek PCIe GbE Family Controller` y el snapshot `base_limpia` creado en VirtualBox.

> **Nota de versión:** la VM quedó con Ubuntu 26.04.1 LTS. La guía contempla 22.04 y 24.04; en 26.04 el paquete `ntp` también es transitorio hacia `ntpsec`, por lo que se usa `ntpsec` (ver sección 4).

**Verificación ejecutada**

```bash
ip -br a
# enp0s3  UP  192.168.1.50/24  fe80::a00:27ff:fe28:6e55/64

ip route
# default via 192.168.1.1 dev enp0s3 proto static metric 100
# 192.168.1.0/24 dev enp0s3 proto kernel scope link src 192.168.1.50 metric 100

ping -c 3 8.8.8.8              # 0% packet loss
ping -c 3 google.com           # resuelve por DNS y responde
```

Desde Windows: `ping 192.168.1.50` responde correctamente.

**Evidencias:** `capturas/01_vm/p4-c01-vm-red-puente.png`, `p4-c02-ip-fija-vm.png`, `p4-c03-ping-ssh-windows.png`

**Problemas encontrados y solución:** el renderer activo era NetworkManager y no systemd-networkd; se editó `00-installer-config.yaml` y se conservó `01-network-manager-all.yaml` para no romper la configuración existente. La VM quedó con Ubuntu 26.04.1 LTS en lugar de 24.04; la diferencia se documentó en la sección 4 y no afectó los servicios.

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

**Procedimiento del diseño** — scripts: `codigo/instalacion/03_configurar_ntp.sh` · configuración: `codigo/configuraciones/ntp.conf`

**Verificación del diseño**

```
ntpq -p                       # el servidor sincroniza con pool.ntp.org
# Cliente Linux:
chronyc tracking  |  ntpq -p  # apunta a 192.168.80.10
# Cliente Windows:
w32tm /query /status
```

**Evidencias del diseño:** `capturas/04_ntp/`

### 4.1 Ejecución P4 (VM de pruebas, Ubuntu 26.04)

**Entorno:** Ubuntu 26.04.1 LTS no ofrece el paquete `ntp` (candidato vacío) y usa `chrony` por defecto. El servidor se implementó con **`ntpsec`**, que reemplazó a `chrony` para evitar dos demonios usando el puerto 123.

**Instalación y configuración**

```bash
sudo apt install ntpsec -y
sudo systemctl status ntpsec --no-pager

sudo cp /etc/ntpsec/ntp.conf /etc/ntpsec/ntp.conf.bak
sudo tee -a /etc/ntpsec/ntp.conf > /dev/null <<'EOF'

# === Proyecto P4: servidor de tiempo para la LAN ===
server pool.ntp.org iburst
restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap nopeer
# === Fin Proyecto P4 ===
EOF

sudo systemctl restart ntpsec
```

**Verificación**

```bash
sudo systemctl status ntpsec --no-pager
ntpq -p
sudo ss -ulnp | grep 123
sudo ufw status
```

Resultado observado:

- `ntpsec.service`: `active (running)`.
- Escucha en `192.168.1.50:123/udp` (además de `127.0.0.1` y `0.0.0.0`).
- `ufw`: inactivo, por lo que no se requieren reglas adicionales.
- `ntpq -p`: seleccionó `*1.co.ntp.edgeuno.com` (estrato 2) con desfase aproximado de `-9 ms`; también aparecen fuentes `+` de respaldo.
- Windows: `w32tm /stripchart /computer:192.168.1.50 /samples:3 /dataonly` respondió con 3 muestras y un desfase de aproximadamente `+1.07 s`.
- Windows sincronizado: `w32tm /resync` completó correctamente y `w32tm /query /source` muestra `192.168.1.50`; `w32tm /query /status` reporta `Stratum: 4`, `ReferenceId: 0xC0A80132` y `Last Successful Sync Time` correcta.

**Evidencias:** `capturas/04_ntp/p4-c04-ntp-servidor.png`, `p4-c05-ntp-stripchart-windows.png`, `p4-c06-ntp-windows-sincronizado.png`

**Problemas encontrados y solución:** Ubuntu 26.04 no ofrece el paquete `ntp` y trae `chrony` por defecto; se instaló `ntpsec`, que reemplazó a `chrony` para evitar dos demonios compitiendo por el puerto 123. En Windows fue necesario ejecutar `w32tm /resync` para forzar la sincronización con `192.168.1.50`.

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

**Procedimiento del diseño** — script: `codigo/instalacion/06_instalar_cups.sh` · configuración: `codigo/configuraciones/cupsd.conf` (incluye la impresora virtual PDF para evidenciar colas sin impresora física)

**Verificación del diseño:** administrar impresoras en `https://192.168.80.10:631`; imprimir página de prueba desde un cliente.

**Evidencias del diseño:** `capturas/09_cups/`

### 9.1 Ejecución P4 (VM de pruebas, Ubuntu 26.04)

**Instalación y configuración**

```bash
sudo apt install cups printer-driver-cups-pdf -y
sudo usermod -aG lpadmin $USER
sudo cupsctl --remote-admin --remote-any --share-printers
sudo systemctl enable --now cups
sudo systemctl restart cups
```

Después de cerrar y volver a abrir la sesión SSH, `groups` confirmó que `kami` pertenece a `lpadmin`.

**Verificación**

```bash
sudo systemctl status cups --no-pager
sudo ss -tlnp | grep 631
cupsctl
lpstat -t
```

Resultado observado:

- CUPS `2.4.16-1ubuntu1.3` y `printer-driver-cups-pdf` `3.0.2` instalados.
- `cups.service`: `active (running)`.
- Escucha en `0.0.0.0:631` y `[::]:631`.
- `cupsctl`: `_remote_admin=1`, `_remote_any=1`, `_share_printers=1`, `WebInterface=Yes`.
- `lpstat -t`: cola virtual `PDF` creada automáticamente por `cups-pdf`.
- `Impresora_Empresa` creada desde la web de CUPS con la plantilla **Generic CUPS-PDF Printer**; `printers.conf` confirma `Accepting Yes`, `Shared Yes` y `State Idle`.
- En Ubuntu 26.04, `cups-pdf` escribe el PDF en `${HOME}/PDF` (por ejemplo `/home/kami/PDF/Test_Page.pdf`), no en `/var/spool/cups-pdf/`.
- Prueba desde Windows: la impresora se agregó por URL y se enviaron dos imágenes; `lpstat -W completed -o` mostró `Impresora_Empresa-10` y `Impresora_Empresa-11` completados con el usuario `MI PC`.
- Se detectaron trabajos que permanecían en la cola aunque el PDF ya se había generado. La causa fue que `systemctl stop cups` no detenía CUPS por la activación de `cups.socket` y `cups.path`. Solución: detener `cups.service`, `cups.socket` y `cups.path`, eliminar los archivos `c0*`/`d0*` de `/var/spool/cups/` y volver a iniciar `cups.service`. Tras esto, el trabajo `Impresora_Empresa-9` quedó completado, `lpstat -o` quedó vacío y `lpstat -W completed -o` mostró el trabajo.

**Evidencias:** `capturas/09_cups/p4-c09-cups-web-impresora.png`, `p4-c10-cups-lpstat.png`, `p4-c11-cups-trabajo-pdf.png`, `p4-c12-cups-windows-impresora.png`, `p4-c13-cups-windows-prueba.png`, `p4-c14-cups-cola-trabajo-windows.png`

**Problemas encontrados y solución:** los trabajos quedaban en cola aunque el PDF ya se había generado porque `systemctl stop cups` no detenía CUPS por la activación de `cups.socket` y `cups.path`. Se detuvieron `cups.service`, `cups.socket` y `cups.path`, se eliminaron los archivos `c0*`/`d0*` de `/var/spool/cups/` y se reinició `cups.service`. Además, en Ubuntu 26.04 `cups-pdf` escribe en `${HOME}/PDF` (`/home/kami/PDF`), no en `/var/spool/cups-pdf/`.

---

## 10. Servicio Samba

**Procedimiento del diseño** — script: `codigo/instalacion/07_instalar_samba.sh` · configuración: `codigo/configuraciones/smb.conf` (recursos por grupo POSIX; SMB directo en 445, sin NetBIOS)

**Verificación del diseño**

```
smbclient //192.168.80.10/secretaria -U usuario
# Desde Windows: \\itec-server\secretaria
```

**Evidencias del diseño:** `capturas/10_samba/`

### 10.1 Ejecución P4 (VM de pruebas, Ubuntu 26.04)

**Instalación y respaldo**

```bash
sudo apt install samba smbclient -y
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
```

**Grupo, usuario y carpeta**

```bash
sudo groupadd sambausers
sudo useradd -M -s /usr/sbin/nologin -G sambausers empleado1
sudo smbpasswd -a empleado1

sudo usermod -aG sambausers $USER
sudo smbpasswd -a $USER

sudo mkdir -p /srv/samba/empresa
sudo chgrp sambausers /srv/samba/empresa
sudo chmod 2770 /srv/samba/empresa
```

**Recurso compartido**

```bash
sudo tee -a /etc/samba/smb.conf > /dev/null <<'EOF'

[empresa]
   comment = Carpeta compartida de la empresa
   path = /srv/samba/empresa
   browseable = yes
   writable = yes
   guest ok = no
   valid users = @sambausers
   force group = sambausers
   create mask = 0660
   directory mask = 2770
EOF
```

**Verificación**

```bash
testparm -s
sudo systemctl enable --now smbd nmbd
sudo systemctl restart smbd nmbd
sudo systemctl status smbd --no-pager
smbclient -L localhost -U empleado1
smbclient //localhost/empresa -U empleado1 -c 'mkdir prueba_servidor; ls'
```

Resultado observado:

- `testparm -s`: configuración cargada sin errores y sección `[empresa]` presente.
- `smbd.service`: `active (running)`; `nmbd` habilitado.
- `smbclient -L localhost`: publica el recurso `empresa`.
- `smbclient //localhost/empresa`: creó y listó la carpeta `prueba_servidor`.
- Permisos de `/srv/samba/empresa`: `drwxrws--- root sambausers`.
- `pdbedit -L`: cuentas Samba `empleado1` y `kami` registradas.
- Windows: se accedió a `\\192.168.1.50\empresa` con `empleado1` y se creó `prueba_windows.txt`; `ls -l /srv/samba/empresa` confirmó ese archivo y la carpeta `prueba_servidor` creada antes desde Linux.
- Acceso denegado: `net use \\192.168.1.50\empresa /user:empleado1 "malapassword"` devolvió `System error 1326: The user name or password is incorrect`. Antes apareció `System error 1219` por credenciales guardadas; se resolvió con `net use * /delete /y`.

**Evidencias:** `capturas/10_samba/p4-c15-samba-testparm.png`, `p4-c16-samba-smbclient-local.png`, `p4-c17-samba-windows-carpeta.png`, `p4-c18-samba-windows-archivo.png`, `p4-c19-samba-servidor-archivo.png`, `p4-c21-samba-acceso-denegado.png`

**Problemas encontrados y solución:** al probar el acceso denegado desde Windows apareció `System error 1219` porque había conexiones guardadas con otras credenciales; se limpiaron con `net use * /delete /y`. El intento con contraseña incorrecta devolvió `System error 1326: The user name or password is incorrect`, que confirma que el recurso rechaza credenciales inválidas.

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
| 1 | 2026-11-12 | NTP | Ubuntu 26.04 no ofrece el paquete `ntp` y usa `chrony` por defecto | Se instaló `ntpsec`, que reemplazó a `chrony` y quedó como servidor de tiempo |
| 2 | 2026-11-12 | CUPS | Los trabajos permanecían en cola aunque el PDF ya se había generado | Se detuvo `cups.service`, `cups.socket` y `cups.path`; se borraron `c0*`/`d0*` de `/var/spool/cups/` y se reinició `cups.service` |
| 3 | 2026-11-12 | CUPS | El PDF no aparecía en `/var/spool/cups-pdf/` | En Ubuntu 26.04 `cups-pdf` escribe en `${HOME}/PDF` (`/home/kami/PDF`) |
| 4 | 2026-11-12 | Samba | Windows devolvía `System error 1219` al probar acceso denegado | Se limpiaron las conexiones guardadas con `net use * /delete /y` y se reintentó |

---

## 13. Exportación de configuraciones P4

Las configuraciones y salidas de verificación de la VM P4 se exportaron a `~/codigo-p4` y se copiaron al repositorio en `codigo/configuraciones/p4/`.

| Archivo | Contenido |
|---|---|
| `ntpsec.conf` | Configuración de `/etc/ntpsec/ntp.conf` con el bloque P4 para la LAN `192.168.1.0/24`. |
| `ntp-peers.txt` | Salida de `ntpq -p` con las fuentes y la fuente seleccionada. |
| `cupsd.conf` | Configuración de `/etc/cups/cupsd.conf`. |
| `cups-pdf.conf` | Configuración de `cups-pdf` (salida en `${HOME}/PDF`). |
| `cups-printers.conf` | Definición de `Impresora_Empresa` (compartida). |
| `cups-estado.txt` | Salida de `lpstat -t`. |
| `smb.conf` | Configuración de `/etc/samba/smb.conf` con el recurso `[empresa]`. |
| `samba-testparm.txt` | Salida de `testparm -s`. |
| `samba-usuarios.txt` | Salida de `pdbedit -L` (solo nombres de usuario; sin contraseñas). |

Estos archivos corresponden a la ejecución P4 y **no reemplazan** las configuraciones del diseño grupal que están en `codigo/configuraciones/` (`ntp.conf`, `cupsd.conf`, `smb.conf`). No incluyen contraseñas: la base de credenciales de Samba (`passdb.tdb`) no se copió.

**Evidencia:** `capturas/12_integracion/p4-c22-exportar-config.png`.

> La captura C22 se tomó antes de regenerar `samba-usuarios.txt` con `sudo pdbedit -L`; el archivo final del repositorio sí contiene los usuarios (`empleado1` y `kami`).

---

## 14. Guion de demostración P4

**Antes de empezar**

- VM encendida, en red puente y con IP `192.168.1.50`.
- PC Windows en `192.168.1.4`.
- Terminal en la VM y CMD en Windows.
- Capturas de respaldo en `capturas/` por si falla una prueba en vivo.

**Prueba 1 — NTP**

```bash
systemctl status ntpsec --no-pager | head -5
ntpq -p
sudo ss -ulnp | grep 123
```

```cmd
w32tm /stripchart /computer:192.168.1.50 /samples:3 /dataonly
w32tm /query /source
```

Mensaje: el servidor entrega la hora y Windows lo usa como fuente.

**Prueba 2 — CUPS**

```bash
lpstat -t
```

Desde Windows: abrir `http://192.168.1.50:631/printers/`, seleccionar `Impresora_Empresa` e imprimir una página de prueba. Luego, en la VM:

```bash
lpstat -W completed -o | head
ls -l ~/PDF
```

Mensaje: la cola recibe el trabajo y genera un PDF en `~/PDF`.

**Prueba 3 — Samba**

```cmd
net use * /delete /y
net use \\192.168.1.50\empresa /user:empleado1 *
explorer \\192.168.1.50\empresa
```

Crear un archivo y una carpeta desde Windows y verificar en la VM:

```bash
ls -l /srv/samba/empresa
```

Acceso denegado:

```cmd
net use * /delete /y
net use \\192.168.1.50\empresa /user:empleado1 "malapassword"
```

Mensaje: el recurso solo acepta usuarios del grupo `sambausers`.

**Cierre**

- Recordar que la VM es Ubuntu 26.04.1 LTS y que se usó `ntpsec` en lugar de `ntp`.
- Mostrar `documentacion.md` y `codigo/configuraciones/p4/` como evidencia de la ejecución.

---

*Documentación elaborada para el Proyecto Final del curso Administración de Infraestructura de TI — Universidad del Quindío, 2026-1.*
