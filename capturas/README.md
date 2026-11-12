# Evidencias del proyecto

Capturas **reales** tomadas durante la ejecución en la VM `itec-server`
(Ubuntu Server 24.04 LTS, `192.168.80.10`). No se usan mockups ni salidas
simuladas. Cada archivo incluye, cuando es de terminal, el comando, la salida,
la fecha y el prompt del servidor; las capturas de navegador muestran la URL
completa y el candado HTTPS.

## Índice

| Carpeta | Contenido | Responsable |
|---|---|---|
| `01_vm/` | Configuración de VirtualBox, instalación, IP, hostname, SSH | P1 |
| `02_dokploy/` | Instalación, servicios Docker/Swarm, panel y proyecto | P1 |
| `03_dns_ssl/` | DNS, certificado y HTTPS | P1 |
| `04_ntp/` | Servidor NTP y clientes sincronizados | P4 |
| `05_web/` | Sitio institucional, oferta, formulario y despliegue | P2 |
| `06_bd/` | PostgreSQL en Dokploy, tablas y preinscripciones | P2 |
| `07_nfs/` | Exportación y montaje NFS | P3 |
| `08_nis/` | Dominio NIS y autenticación de clientes | P3 |
| `09_cups/` | Cola de impresión y trabajo de prueba | P4 |
| `10_samba/` | Recurso SMB accesible desde Windows | P4 |
| `11_seguridad/` | UFW, DOCKER-USER, respaldos y restauración | P1 / P2 |
| `12_integracion/` | Diagrama renderizado, documentación y prueba end-to-end | P1 / P2 |
| `logs/` | Salidas de texto complementarias (opcional) | Todos |

## Convención de nombres

`NN_descripcion_corta.png` (por ejemplo `03_ip_hostname.png`). Se conserva la
fecha visible en la captura; no se renombra el archivo para ocultar cuándo se
tomó.
