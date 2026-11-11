# Análisis y Diseño de Infraestructura de Servicios de TI

**Proyecto Final — Administración de Infraestructura de TI · Entregable 1 (Semana 1)**

| | |
|---|---|
| **Institución académica** | Universidad del Quindío — Facultad de Ingeniería de Sistemas y Computación |
| **Semestre** | 2026-1 |
| **Equipo** | Esteban · Jerónimo · Brahian · Jack Alejandro Marín Hernández (equipo de ingenieros) |
| **Empresa analizada** | Instituto Técnico de Educación Comfenalco Quindío |
| **Plataforma central** | Dokploy (PaaS) sobre Ubuntu Server 24.04 LTS |
| **Diagrama de arquitectura** | `diagrama.mmd` (formato Mermaid) |

---

## 1. Contexto de la empresa

### 1.1 Perfil general

| Aspecto | Descripción |
|---|---|
| **Nombre** | Instituto Técnico de Educación Comfenalco Quindío |
| **Naturaleza** | Institución de formación para el trabajo y el desarrollo humano, creada y operada por la Caja de Compensación Familiar Comfenalco Quindío (marco de la Ley 115 de 1994) |
| **Ubicación** | Sede en la Calle 23 con Carrera 23, esquina (Armenia, Quindío); nueva sede en el barrio Granada (Cra. 22 # 10-35) |
| **Inicio de actividades** | 1997, con el programa Secretariado Auxiliar Contable Sistematizado |
| **Licencias de funcionamiento** | Resoluciones 1630 de 2007, 1712 de 2020 y 2714 de 2025 |
| **Oferta académica** | Programas técnicos laborales, cursos cortos, talleres, diplomados, capacitación empresarial y evaluación/certificación por competencias laborales |
| **Programas técnicos laborales** | Secretariado Auxiliar Contable, Auxiliar Contable y Financiero, Auxiliar de Talento Humano, Electricista en Construcción Residencial, Liniero de Redes de Energía, Operario de Confección, Manicurista y Pedicurista, Peluquería, Preparación de Alimentos y Manejo de Herramientas para Codificación de Software |
| **Proceso de admisión y matrícula** | Preinscripción, entrevista y presentación de documentación; edad mínima 15 años (18 para Liniero de Redes de Energía); tarifas diferenciadas por categoría de afiliación a la Caja (A, B, C, no afiliado) |
| **Reglamentación pública** | Proyecto Educativo Institucional (PEI) y Reglamento Estudiantil publicados en PDF en el sitio de Comfenalco Quindío |
| **Contacto oficial** | institutotecnico@cqteduca.edu.co · PBX 606 731 4001 (opc. 7 Educación / opc. 1 Instituto) |
| **Dependencia organizacional** | Departamento Instituto Técnico, adscrito a la Gerencia de Educación de Comfenalco Quindío |

El PEI y el Reglamento Estudiantil públicos son la fuente de datos reales para este análisis y para el contenido del sitio web (programas, estructura, admisión y matrícula), sin necesidad de solicitar información adicional a la institución.

### 1.2 Escenario de infraestructura de TI del proyecto

Como equipo consultor, proponemos e implementamos la infraestructura sobre el escenario de trabajo del curso: un servidor local que centraliza la gestión de servicios web, archivos, impresión, sincronización de tiempo, autenticación de usuarios y acceso compartido. El mapeo de servicios con la operación del instituto es el siguiente:

- **Estudiantes en salas de informática Linux** (formación práctica de programas técnicos): necesitan cuentas de usuario centralizadas (**NIS**) y persistencia de sus trabajos entre salas (**NFS**).
- **Administración y secretaría académica en equipos Windows** (matrículas, certificados, contabilidad): necesitan carpetas compartidas accesibles desde Windows (**Samba**).
- **Impresión de certificados, constancias y material didáctico**: requiere un servidor de impresión centralizado con colas administrables (**CUPS**).
- **Formulario de inscripción en línea** conectado a una base de datos propia (**PostgreSQL**), desplegado junto al sitio institucional (**Dokploy**).

### 1.3 Necesidades identificadas

| # | Necesidad | Impacto actual |
|---|---|---|
| N1 | Portal institucional con oferta académica y preinscripción en línea | La información de programas y matrícula está dispersa; la preinscripción depende de formularios externos y atención presencial |
| N2 | Persistencia de los trabajos de estudiantes entre salas Linux | Los archivos quedan en el equipo usado en la sesión y se pierden o duplican entre salas |
| N3 | Acceso a documentos académicos y administrativos desde Windows y Linux | Cada plataforma usa rutas y copias separadas |
| N4 | Impresión centralizada y trazable de certificados y material didáctico | Colas locales por sala, dependencia del equipo anfitrión y gasto sin control |
| N5 | Gestión centralizada de cuentas de estudiantes por periodo académico | Alta y baja de usuarios duplicadas equipo por equipo en cada inicio de ciclo |
| N6 | Hora uniforme y confiable en toda la red | Sellos de tiempo inconsistentes en matrículas, certificados y respaldos |
| N7 | Despliegue ágil de aplicaciones internas sin contratar DevOps | Los procesos académicos (registro, certificación) permanecen manuales |
| N8 | Acceso seguro (cifrado TLS) al sitio web y a las herramientas de administración | Sin HTTPS; servicios internos expuestos sin control |

## 2. Solución propuesta — visión general

Se propone **un único servidor** (máquina virtual Ubuntu Server 24.04 LTS, IP fija `192.168.1.10`) que centraliza dos frentes complementarios:

1. **Frente moderno (PaaS):** **Dokploy** con Traefik como proxy inverso, sobre el cual se despliega el sitio web institucional con su base de datos PostgreSQL y el formulario de preinscripción; allí podrán alojarse futuras aplicaciones académicas (N7).
2. **Frente de servicios de red tradicionales:** NTP, NFS, NIS, CUPS y Samba para resolver las necesidades operativas de salas, secretaría y administración (N2–N6).

**Por qué un solo servidor:** presupuesto limitado de la dependencia educativa, administración a cargo de un equipo muy reducido y carga moderada. La separación lógica se logra con contenedores Docker (frente moderno) y con el firewall UFW, que limita cada servicio a la subred local.

El diagrama completo de la arquitectura está en **`diagrama.mmd`** (renderizable en <https://mermaid.live> o en VS Code).

## 3. Justificación de cada servicio propuesto

### 3.1 Dokploy — plataforma PaaS

- **Necesidad que atiende:** N7 (despliegue ágil) y N1 (alojamiento del sitio web).
- **Qué aporta:** plataforma autohospedada y gratuita que, sobre Docker, ofrece despliegue desde Git, proxy inverso (Traefik), certificados SSL automáticos, gestión de bases de datos (incluye PostgreSQL) y dominios desde un panel web.
- **Alternativas descartadas:** despliegue manual con Docker/Nginx (requiere expertiz que el instituto no tiene dedicada y es propenso a errores); PaaS públicos tipo Heroku/Vercel (costo recurrente en dólares y datos de estudiantes fuera de la institución); contratar administrador DevOps (costo laboral).
- **Beneficio para el instituto:** el personal de la Gerencia de Educación puede desplegar el sitio web hoy y las aplicaciones académicas de mañana (p. ej., consulta de certificados) desde una interfaz gráfica, sin línea de comandos.

### 3.2 Sitio web institucional — Nginx (contenedor vía Dokploy)

- **Necesidad:** N1.
- **Qué aporta:** sitio con la oferta académica real tomada del PEI: programas técnicos laborales, requisitos y proceso de admisión y matrícula (preinscripción, entrevista, documentación), tarifas por categoría de afiliación, horarios y canales de contacto; incluye el formulario de preinscripción conectado a PostgreSQL. Se sirve por HTTPS detrás de Traefik.
- **Por qué Nginx:** extremadamente ligero para contenido mayoritariamente estático, estándar de la industria y de bajo consumo en un servidor de 2 vCPU.
- **Criterio de éxito:** accesible vía HTTPS con contenido relevante para la institución (programas, admisión, matrícula, contacto).

### 3.3 NTP — servidor de tiempo

- **Necesidad:** N6.
- **Qué aporta:** el servidor se sincroniza contra `pool.ntp.org` y se convierte en la fuente de hora única de la red local (puerto 123/UDP); las estaciones Windows y Linux apuntan a él.
- **Por qué importa en el instituto:** los registros de matrícula, la expedición de certificados y constancias, y los respaldos requieren marcas de tiempo consistentes y verificables.
- **Alternativas descartadas:** que cada equipo sincronice por su cuenta contra internet (deriva entre equipos, tráfico innecesario y dependencia del proveedor).

### 3.4 NFS — compartición de archivos para las salas Linux

- **Necesidad:** N2 y N3 (estaciones Linux de las salas de informática).
- **Qué aporta:** exporta el árbol `/srv/compartido/academicos` por NFSv4 (puerto 2049) para que las salas Linux monten los directorios de trabajo como una unidad local: los estudiantes acceden a sus trabajos desde cualquier sala, con permisos por grupo (estudiantes, docentes).
- **Alcance:** exportación restringida a la subred 192.168.1.0/24.

### 3.5 NIS — autenticación centralizada para las salas Linux

- **Necesidad:** N5.
- **Qué aporta:** un solo dominio de credenciales para las estaciones Linux de las salas: altas y bajas de cuentas estudiantiles en un único punto, con grupos por rol (estudiantes, docentes, administrativos). La rotación total de estudiantes por periodo académico se administra con scripts sobre el servidor, no sala por sala.
- **Alternativas descartadas:** LDAP/OpenLDAP o Active Directory (más robustos, pero sobredimensionados para las salas Linux y el tamaño de la dependencia; requieren mayor mantenimiento).
- **Limitación aceptada conscientemente:** NIS es un protocolo legado sin cifrado; se mitiga limitándolo estrictamente a la LAN y con UFW (puerto 834 solo para la subred). Los equipos Windows de administración y secretaría usan Samba con credenciales propias; un directorio corporativo completo queda fuera del alcance y del presupuesto de esta fase.

### 3.6 CUPS — servidor de impresión

- **Necesidad:** N4.
- **Qué aporta:** las impresoras se conectan al servidor; CUPS publica colas IPP (puerto 631) utilizables desde Windows y Linux, con administración web (`https://192.168.1.10:631`) y registro de trabajos.
- **Beneficio:** la secretaría imprime certificados y constancias desde su cola, los docentes imprimen material didáctico desde las salas, y queda trazabilidad del gasto de impresión.

### 3.7 Samba — compartición de archivos para Windows

- **Necesidad:** N2 y N3 (equipos Windows de administración y secretaría académica).
- **Qué aporta:** exporta el **mismo árbol `/srv/compartido`** por SMB/CIFS (puerto 445) con carpetas por dependencia y `valid users` por grupo: NFS y Samba sirven los mismos datos, evitando duplicación entre plataformas.
- **Decisión de diseño:** deshabilitar NetBIOS legado (puertos 137–139) usando solo SMB sobre 445, soportado nativamente por Windows, macOS y Linux modernos.

### 3.8 Base de datos — PostgreSQL vía Dokploy

- **Necesidad:** N1 (formulario de preinscripción) y base para las aplicaciones académicas de N7.
- **Qué aporta:** base de datos relacional provisionada y administrada desde el panel de Dokploy; accesible solo desde la red interna (puerto 5432 no expuesto a internet). En ella se registran los aspirantes del formulario de inscripción.
- **Por qué PostgreSQL:** motor robusto y sin costo de licencia, soportado de forma nativa por Dokploy, con tipografía de datos adecuada para el registro de aspirantes (documentos, categorías de afiliación, programa de interés).
- **Criterio de éxito:** base de datos creada y conectada a la aplicación web (las preinscripciones quedan persistidas).

### 3.9 Dominio/DNS y SSL/TLS

- **Necesidad:** N8.
- **Qué aporta:** nombre público con **DNS dinámico gratuito** (DuckDNS, propuesto: `itec-quindio.duckdns.org`) que apunta al servidor; certificado **Let's Encrypt** emitido y renovado automáticamente por Dokploy/Traefik para HTTPS. Como alternativa inmediata para pruebas internas, certificado autofirmado generado por script (`codigo/ssl/`).
- **Por qué esta combinación:** costo cero, renovación automática y sin advertencias de navegador una vez el dominio resuelva.

### 3.10 Mejoras opcionales (puntos extra)

| Mejora | Descripción |
|---|---|
| **Firewall UFW** | política *default deny*; solo se habilitan los puertos de la tabla de requisitos, y los servicios internos solo para la subred |
| **Docker Compose** | el sitio web y la base de datos se versionan con `docker-compose.yml` para despliegue reproducible |
| **Respaldos automáticos** | tarea programada (cron) que respalda `/srv/compartido` y vuelca la base de datos |
| **Monitoreo básico** | verificación periódica de servicios activos con alertas |

## 4. Tabla de requisitos

Servidor: **192.168.1.10** (hostname `itec-server`) · Red local: `192.168.1.0/24`

| # | Servicio | Software | IP | Puerto(s) | Protocolo | Tipo de servicio |
|---|---|---|---|---|---|---|
| 1 | Administración remota | OpenSSH | 192.168.1.10 | 22 | TCP | Gestión remota segura |
| 2 | Panel PaaS | Dokploy | 192.168.1.10 | 3000 | TCP (HTTP, solo LAN) | Plataforma de despliegue |
| 3 | Sitio web institucional | Traefik + Nginx (Dokploy) | 192.168.1.10 | 443 (80 → redirige a 443) | TCP (HTTPS/TLS) | Sitio web |
| 4 | Sincronización de tiempo | ntpd | 192.168.1.10 | 123 | UDP | NTP |
| 5 | Archivos salas Linux | nfs-kernel-server | 192.168.1.10 | 2049 | TCP (NFSv4) | Compartición de archivos |
| 6 | Autenticación salas Linux | ypserv (NIS) | 192.168.1.10 | 834 (fijado) + 111 | TCP/UDP (RPC) | Servicio de credenciales |
| 7 | Impresión | cupsd | 192.168.1.10 | 631 | TCP/UDP (IPP) | Servidor de impresión |
| 8 | Archivos Windows | smbd (Samba) | 192.168.1.10 | 445 | TCP (SMB/CIFS) | Compartición de archivos |
| 9 | Base de datos | PostgreSQL (Dokploy) | 192.168.1.10 | 5432 (solo interno) | TCP | Base de datos relacional |

**Notas de la tabla:**

- El puerto 834 de NIS se fija explícitamente en la configuración (`ypserv -p`) para poder filtrarlo con UFW; rpcbind (111) queda igualmente restringido a la LAN.
- Samba funciona únicamente sobre 445; los puertos legado NetBIOS 137–139 permanecen deshabilitados.
- El puerto 80 solo recibe tráfico para redirigirlo a HTTPS.
- 3000 (panel Dokploy) y 5432 (PostgreSQL) no se exponen a internet: reglas UFW limitadas a la subred.

## 5. Recursos y configuración de la máquina virtual

| Aspecto | Valor |
|---|---|
| Hipervisor | VirtualBox 7.x o VMware Workstation |
| Sistema operativo | Ubuntu Server 24.04 LTS |
| vCPU | 2 |
| RAM | 4 GB |
| Disco | 40 GB |
| Modo de red | Bridged (accesible desde toda la red local) |
| IP | 192.168.1.10 estática (o reserva DHCP en el router) |
| Hostname | itec-server |
| Puerta de enlace / DNS | 192.168.1.1 / DNS del proveedor o 8.8.8.8 |

## 6. Diseño del árbol de datos compartidos

Un único árbol servido por NFS (salas Linux) y Samba (administración y secretaría), con permisos por grupo:

```
/srv/compartido/
├── academicos/      # NFS: trabajos y guías por programa (grupos: estudiantes rw, docentes rw)
├── secretaria/      # Samba: matrículas y certificados (secretaría rw)
├── contabilidad/    # Samba: facturación y cartera (contabilidad rw)
└── publico/         # material didáctico de libre consulta (todos, rw)
```

| Carpeta | NFS (salas Linux) | Samba (Windows) |
|---|---|---|
| academicos | /srv/compartido/academicos | (solo lectura para docentes con cuenta) |
| secretaria | — | \\\\itec-server\\secretaria |
| contabilidad | — | \\\\itec-server\\contabilidad |
| publico | /srv/compartido/publico | \\\\itec-server\\publico |

## 7. Seguridad

- **Firewall (UFW):** política por defecto denegatoria; solo los puertos de la sección 4, y los servicios internos (123, 834, 2049, 445, 631, 3000, 5432) aceptan tráfico únicamente desde `192.168.1.0/24`.
- **TLS:** HTTPS obligatorio en el sitio web (Let's Encrypt o autofirmado en pruebas).
- **Datos personales de aspirantes y estudiantes** (Ley 1581 de 2012): la base de datos no se expone a internet, se incluye en los respaldos cifrados y el acceso queda limitado a la red interna.
- **NIS:** aceptado como solución legada solo dentro de la LAN y protegido por firewall.
- **Respaldos:** cron semanal de `/srv/compartido` + volcado de la BD hacia `/srv/backups`.
- **Actualizaciones:** `unattended-upgrades` para parches de seguridad del SO.

## 8. Plan de implementación

| Semana | Entregable | Alcance |
|---|---|---|
| 1 | Análisis y diseño | Este documento + `diagrama.mmd` |
| 2 | Infraestructura base | VM Ubuntu + Dokploy + NTP + dominio DNS + SSL/TLS |
| 3 | Servicios | Web, NTP en clientes, NFS, NIS, CUPS, Samba, base de datos |
| 4 | Documentación y presentación | `documentacion.md` completo + demostración (15 min) |

## 9. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Servidor único = punto único de falla | Alto | Respaldos automáticos, snapshot de la VM y árbol de datos separado del sistema |
| NIS legado sin cifrado | Medio | Alcance limitado a la LAN + reglas UFW por subred |
| Rotación masiva de cuentas estudiantiles por periodo | Medio | Gestión de usuarios NIS automatizada con scripts (alta/baja por lote) |
| Datos personales de aspirantes en la BD | Medio | Puerto 5432 solo interno, respaldos cifrados, acceso restringido (Ley 1581 de 2012) |
| IP pública dinámica del proveedor | Medio | DNS dinámico (DuckDNS) actualizado automáticamente |
| Certificado autofirmado genera advertencias | Bajo | Transición a Let's Encrypt al quedar el dominio operativo |
| Saturación de la VM (2 vCPU) | Medio | Carga moderada de la dependencia + monitoreo básico (extra) |

---

*Documento elaborado para el Proyecto Final del curso Administración de Infraestructura de TI — Universidad del Quindío, 2026-1. Fuente de datos institucionales: PEI y Reglamento Estudiantil públicos del Instituto Técnico de Educación Comfenalco Quindío.*
