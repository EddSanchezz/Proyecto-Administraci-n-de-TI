# Análisis y Diseño de Infraestructura de Servicios de TI

**Proyecto Final — Administración de Infraestructura de TI · Entregable 1 (Semana 1)**

| | |
|---|---|
| **Institución académica** | Universidad del Quindío — Facultad de Ingeniería de Sistemas y Computación |
| **Semestre** | 2026-2 |
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
| **Naturaleza** | Institución de formación para el trabajo y el desarrollo humano, creada y operada por la Caja de Compensación Familiar Comfenalco Quindío; opera como área de servicio subsidiado de la Caja (marco de la Ley 115 de 1994) |
| **NIT / representante legal** | 890000381-0 / José Fernando Montes Salazar (PEI 2024) |
| **Ubicación** | Sede en la Calle 23 con Carrera 23, esquina (Armenia, Quindío); nueva sede en el barrio Granada (Cra. 22 # 10-35) |
| **Inicio de actividades** | 1997, con el programa Secretariado Auxiliar Contable Sistematizado (la Caja ofrece capacitación desde 1967) |
| **Licencia de funcionamiento** | Resolución 1712 del 8 de septiembre de 2020, expedida por la Secretaría de Educación Municipal de Armenia (antecedente: 1630 de 2007; el sitio web registra además la 2714 de 2025) |
| **Oferta académica** | Once programas técnicos laborales, programas de educación informal de menos de 160 horas (once áreas), capacitaciones empresariales y oferta virtual vía Moodle desde 2023 |
| **Programas técnicos laborales** | Auxiliar de Talento Humano, Auxiliar de Recursos Humanos, Auxiliar Contable y Financiero, Secretariado Auxiliar Contable, Auxiliar de Cartera y Cobranzas, Electricista en Construcción Residencial, Liniero en Redes de Energía, Operario de Confección, Peluquería, Manicurista y Pedicurista, y Preparatorio Musical (conocimientos académicos) |
| **Jornadas y modalidad** | Diurna, nocturna y sabatina; presencial con trabajo virtual (80/20 sabatinos, 90/10 de lunes a viernes) |
| **Proceso de admisión y matrícula** | Preinscripción con autorización de tratamiento de datos, entrevista de ingreso (único criterio de admisión en técnicos) y documentación; pruebas adicionales para Preparatorio Musical y Liniero en Redes de Energía; edad mínima 15 años (18 para Liniero); tarifas diferenciadas por categoría de afiliación a la Caja (A, B, C, no afiliado) |
| **Reglamentación pública** | PEI (versión 010, código C-DECYB-0006, 2024-04-11) y Reglamento Estudiantil (versión 007, código I-ED-0001, 2024-04-16), publicados en PDF en el sitio de Comfenalco Quindío |
| **Contacto oficial** | institutotecnico@comfenalcoquindio.co · 606 736 8976 (PEI 2024); PBX Comfenalco 606 731 4001 (opc. 7 Educación / opc. 1 Instituto) |
| **Dependencia organizacional** | Departamento Instituto Técnico, adscrito a la Gerencia de Educación de Comfenalco Quindío; la infraestructura tecnológica se rige por el área de Transformación Digital de la Caja |
| **Sistemas académicos actuales** | Administrador Educativo (por contrato de concesión) para inscripción en línea y registro académico; plataforma virtual Moodle (concesión) |

El PEI y el Reglamento Estudiantil públicos son la fuente de datos reales para este análisis y para el contenido del sitio web (programas, estructura, admisión y matrícula), sin necesidad de solicitar información adicional a la institución. La sección 1.2 resume los datos verificados en ambos documentos.

### 1.2 Datos verificados en el PEI y el Reglamento Estudiantil

#### Identificación y trayectoria (PEI, capítulo 1)

- Identificación oficial (PEI 1.1): NIT 890000381-0; representante legal José Fernando Montes Salazar; dirección Calle 23 carrera 23, esquina (Armenia); teléfono 6067368976; correo institutotecnico@comfenalcoquindio.co; naturaleza privada; modalidad presencial; jornadas diurna, nocturna y sabatina; licencia de funcionamiento 1712 del 8 de septiembre de 2020.
- Trayectoria: la Caja ofrece capacitación desde 1967; el Instituto inicia labores en 1997 con el programa Secretariado Auxiliar Contable Sistematizado; mantiene certificación de calidad ISO 9001 desde 2013 y programas certificados bajo las normas NTC 5555, NTC 5581 y NTC 5666.
- El PEI no define misión y visión propias del Instituto: su gestión se alinea con el direccionamiento estratégico corporativo de Comfenalco Quindío (documento I-DA-0003), cuyo propósito es "generar bienestar integral y prosperidad colectiva" y cuya Mega 2025 es impactar socialmente al 94% de la población afiliada (Reglamento).

#### Oferta académica (PEI, secciones 2.1 a 2.3)

Programas técnicos laborales vigentes, todos con jornadas diurna, nocturna y sabatina:

| Programa | Registro / reconocimiento | Duración |
|---|---|---|
| Técnico Laboral en Auxiliar de Recursos Humanos | Resolución 3838 de noviembre 25 de 2016 | 900 horas |
| Técnico Laboral Auxiliar Contable y Financiero | Resoluciones 63-01673 de 2020 y 0964 del 23 de junio de 2021 | 1.780 horas |
| Conocimientos académicos en Preparatorio Musical | Resolución 1508 del 24 de julio de 2020 | 576 horas |
| Técnico Laboral Liniero en Redes de Energía | Resolución 1509 del 24 de julio de 2020 | 900 horas |
| Técnico Laboral en Auxiliar de Cartera y Cobranzas | Resolución 1809 del 22 de septiembre de 2020 | 900 horas |
| Técnico Laboral en Secretariado Auxiliar Contable | Resoluciones 3072 de 2014 y 0968 del 23 de junio de 2021 | 1.780 horas |
| Técnico Laboral en Electricista Construcción Residencial | Resoluciones 3069 de 2014 y 0963 del 23 de junio de 2021 | 900 horas |
| Técnico Laboral en Peluquería | Resolución 0967 del 23 de junio de 2021 | 900 horas |
| Técnico Laboral en Operario de Confección | Resolución 1604 del 28 de julio de 2022 | 900 horas |
| Técnico Laboral en Manicurista y Pedicurista | Resolución 1685 del 11 de julio de 2023 | 700 horas |
| Técnico Laboral en Auxiliar de Talento Humano | Resoluciones 1685 de 2023 y 63-00797 de 2023 | 1.780 horas |

- Educación informal (PEI 2.1.2): cursos vocacionales de menos de 160 horas que no conducen a título y entregan constancia de asistencia; once áreas: artística, baile, belleza, cocina y nutrición, confección, descanso, emprendimiento, manualidades, música, sistemas y sostenibilidad.
- Capacitaciones empresariales (PEI 2.1.3): se orientan en las instalaciones del Instituto o de la empresa contratante.
- Población objeto (PEI 2.3): trabajadores afiliados a la Caja y su núcleo familiar, con prioridad en las categorías A y B, población no afiliada y empresas afiliadas o no afiliadas.
- Tarifas (PEI 2.2): aprobadas anualmente por el Consejo Directivo de la Caja; formas de pago: contado, credisubsidio, pagos o transferencias electrónicas, crédito directo con Comfenalco y financiación con fondo de garantías.

#### Jornadas y modalidad (PEI, sección 2.5)

| Jornada | Horario | Hora académica | Intensidad |
|---|---|---|---|
| Diurna | 7:00 a.m. a 11:30 a.m. y 1:30 p.m. a 6:00 p.m. | 50 minutos | 25 horas semanales; 18 semanas por periodo |
| Nocturna | 6:00 p.m. a 10:00 p.m. | 45 minutos | 25 horas semanales; 18 semanas por periodo |
| Sabatina | 7:00 a.m. a 12:00 m. y 1:00 p.m. a 5:00 p.m. | 45 minutos | 11 horas por sábado; promedio de cuatro periodos (dos años) |

- Modalidad: presencial con trabajo virtual (80% presencial / 20% virtual en sabatinos; 90% / 10% de lunes a viernes); la oferta virtual opera en Moodle desde 2023.

#### Procesos académicos (PEI 2.6 a 2.12 y 3.1; Reglamento, capítulos IV a VI)

- Inscripción (PEI 3.1.2.1): presencial en las instalaciones o en línea desde la plataforma del Administrador Educativo; la recepcionista o la persona designada por rectoría programa la entrevista.
- Admisión (PEI 3.1.2.2): entrevista con el Coordinador de Bienestar Institucional; es el único criterio y evalúa relaciones interpersonales, personalidad, motivación de ingreso, afinidad con el programa y aspiración académica. Preparatorio Musical exige prueba de conocimientos y Liniero en Redes de Energía exige prueba y entrevista.
- Matrícula (PEI 3.1.2.3; Reglamento, arts. 33 y 34): efectiva con el pago en cursos vocacionales; en técnicos requiere admisión, documentación y pago según categoría de afiliación. Se renueva cada periodo con paz y salvo de la Coordinación Académica y Tesorería.
- Evaluación (PEI 2.6): Conocimiento 35%, Desempeño 35% y Producto 30%; escala de 0.0 a 5.0; competente con 3.5 o más. El Reglamento regula los planes de mejoramiento (nota entre 1.5 y 3.5), el curso de recuperación (entre 2.0 y 3.5, con costo) y la repetición de módulos.
- Certificación (PEI 2.11): constancia de asistencia en educación informal con asistencia mínima del 80% (en virtual, 100% de las actividades y 80% de los encuentros sincrónicos); en técnicos, el comité de certificación verifica el estado académico y se entrega el Certificado de Aptitud Ocupacional con registro en el libro de actas (programa, resolución, intensidad, fecha, graduandos y documentos).
- Pasantías (PEI 2.7.4): contrato de aprendizaje de seis meses bajo la Ley 789 de 2002 en los programas Secretariado Auxiliar Contable, Auxiliar Contable y Financiero (900 horas lectivas más 880 de etapa productiva) y Auxiliar de Talento Humano; incluye inducción, remisión de hojas de vida e informes de seguimiento.
- Egresados (PEI 2.12): seguimiento a los seis meses de la graduación y encuesta cada dos años a todas las cohortes (requisitos NTC 5581).

#### Organización y sistemas de información (PEI, capítulo 3)

- Archivo académico (PEI 3.2): todo el registro académico (matrículas, pensum, notas, asistencia, pasantías) reside en el Administrador Educativo; existe libro de grados y actas de grado; las constancias se expiden con verificación en el sistema y visto bueno de la coordinación académica.
- Planta de personal (PEI 3.4.1): perfiles de cargo documentados para la planta completa (dieciséis perfiles más vigilancia), entre ellos rectoría, coordinaciones académica, de vocacionales y de bienestar institucional, asistentes, docentes, secretaría y el cargo propio de tecnología: auxiliar de gestión TIC (perfil F-UE-0017).
- Finanzas (PEI 3.5): presupuesto anual aprobado por el Consejo Directivo de la Caja; ingresos por matrículas técnicas, cursos vocacionales, capacitaciones, convenios y el aporte del 4%; informe anual de costos a la Secretaría de Educación.
- Tecnología (PEI 3.3): el mantenimiento de la infraestructura tecnológica lo dicta el área de Transformación Digital de la Caja y el locativo el área de Infraestructura; el administrador educativo y la plataforma virtual operan por contratos de concesión; los proveedores de software académico se evalúan por soporte, disponibilidad y facilidad de uso (Anexo 1 del PEI).

#### Reglamento Estudiantil (versión 007, código I-ED-0001, 2024-04-16)

- Naturaleza: institución de educación para el trabajo y el desarrollo humano, bajo la autoridad de la Secretaría de Educación Municipal de Armenia y el Ministerio de Educación Nacional.
- Define aspirante, admisión, matrícula y clases de estudiante (nuevo, en continuidad, reingreso); la matrícula se invalida por inexactitud de datos y la condición de estudiante se pierde por no renovación, cancelación voluntaria o expulsión decidida por el Consejo Académico.
- Consagra 24 derechos y 22 deberes del estudiante, entre ellos conocer el reglamento, recibir retroalimentación en máximo ocho días, obtener certificaciones y carnet estudiantil, asistir puntualmente según horarios y llamado a lista, y estar a paz y salvo.
- Cancelación del periodo: devolución del 75% solo dentro de la primera semana; en informal, si la asistencia no supera el 20%, devolución del 75%; el trabajo intermodular es requisito del certificado y su sustentación extemporánea (hasta tres años) cuesta el 10% del valor del semestre (categoría C).

Estos datos alimentan directamente el diseño: el sitio web publica la oferta y los procesos verificados (sección 3.2), el formulario de preinscripción replica los datos que el Instituto exige, incluida la autorización de tratamiento de datos personales (PEI 3.1.1), el árbol compartido refleja las dependencias académicas y administrativas (sección 6) y las colas de impresión atienden la expedición de constancias y certificados (sección 3.6).

### 1.3 Escenario de infraestructura de TI del proyecto

Como equipo consultor, proponemos e implementamos la infraestructura sobre el escenario de trabajo del curso: un servidor local que centraliza la gestión de servicios web, archivos, impresión, sincronización de tiempo, autenticación de usuarios y acceso compartido. El mapeo de servicios con la operación del instituto es el siguiente:

- **Estudiantes en salas de informática Linux** (formación práctica de programas técnicos): necesitan cuentas de usuario centralizadas (**NIS**) y persistencia de sus trabajos entre salas (**NFS**).
- **Administración y secretaría académica en equipos Windows** (matrículas, certificados, contabilidad): necesitan carpetas compartidas accesibles desde Windows (**Samba**).
- **Impresión de certificados, constancias y material didáctico**: requiere un servidor de impresión centralizado con colas administrables (**CUPS**).
- **Formulario de inscripción en línea** conectado a una base de datos propia (**PostgreSQL**), desplegado junto al sitio institucional (**Dokploy**).

### 1.4 Necesidades identificadas

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

Se propone **un único servidor** (máquina virtual Ubuntu Server 24.04 LTS, IP fija `192.168.80.10`) que centraliza dos frentes complementarios:

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
- **Criterio de éxito:** panel de Dokploy operativo desde la LAN, con la aplicación del sitio web desplegada desde Git y en ejecución como contenedor, y su base de datos PostgreSQL creada y asociada desde el propio panel.

### 3.2 Sitio web institucional — Nginx (contenedor vía Dokploy)

- **Necesidad:** N1.
- **Qué aporta:** sitio con la oferta académica real tomada del PEI: programas técnicos laborales, requisitos y proceso de admisión y matrícula (preinscripción, entrevista, documentación), tarifas por categoría de afiliación, horarios y canales de contacto; incluye el formulario de preinscripción conectado a PostgreSQL. Se sirve por HTTPS detrás de Traefik.
- **Por qué Nginx:** extremadamente ligero para contenido mayoritariamente estático, estándar de la industria y de bajo consumo en un servidor de 2 vCPU.
- **Criterio de éxito:** sitio accesible por HTTPS con la oferta real del PEI (los once programas técnicos con duración, jornadas, tarifas y proceso de admisión) y el formulario de preinscripción guardando registros en PostgreSQL.

### 3.3 NTP — servidor de tiempo

- **Necesidad:** N6.
- **Qué aporta:** el servidor se sincroniza contra `pool.ntp.org` y se convierte en la fuente de hora única de la red local (puerto 123/UDP); las estaciones Windows y Linux apuntan a él.
- **Por qué importa en el instituto:** los registros de matrícula, la expedición de certificados y constancias, y los respaldos requieren marcas de tiempo consistentes y verificables.
- **Alternativas descartadas:** que cada equipo sincronice por su cuenta contra internet (deriva entre equipos, tráfico innecesario y dependencia del proveedor).
- **Criterio de éxito:** servidor sincronizado con `pool.ntp.org` (estado y estrato visibles con `ntpq -p`) y al menos un cliente Windows y un cliente Linux obteniendo la hora desde 192.168.80.10 con desviación menor a un segundo.

### 3.4 NFS — compartición de archivos para las salas Linux

- **Necesidad:** N2 y N3 (estaciones Linux de las salas de informática).
- **Qué aporta:** exporta el árbol `/srv/compartido/academicos` por NFSv4 (puerto 2049) para que las salas Linux monten los directorios de trabajo como una unidad local: los estudiantes acceden a sus trabajos desde cualquier sala, con permisos por grupo (estudiantes, docentes).
- **Alcance:** exportación restringida a la subred 192.168.80.0/24.
- **Criterio de éxito:** una estación Linux monta `/srv/compartido/academicos` por NFSv4 y un archivo creado en una sala queda disponible al iniciar sesión desde otra sala (persistencia verificada en el servidor).

### 3.5 NIS — autenticación centralizada para las salas Linux

- **Necesidad:** N5.
- **Qué aporta:** un solo dominio de credenciales para las estaciones Linux de las salas: altas y bajas de cuentas estudiantiles en un único punto, con grupos por rol (estudiantes, docentes, administrativos). La rotación total de estudiantes por periodo académico se administra con scripts sobre el servidor, no sala por sala.
- **Alternativas descartadas:** LDAP/OpenLDAP o Active Directory (más robustos, pero sobredimensionados para las salas Linux y el tamaño de la dependencia; requieren mayor mantenimiento).
- **Limitación aceptada conscientemente:** NIS es un protocolo legado sin cifrado; se mitiga limitándolo estrictamente a la LAN y con UFW (puerto 834 solo para la subred). Los equipos Windows de administración y secretaría usan Samba con credenciales propias; un directorio corporativo completo queda fuera del alcance y del presupuesto de esta fase.
- **Criterio de éxito:** una cuenta creada únicamente en el servidor permite iniciar sesión en las estaciones Linux de las salas con su directorio personal, y los puertos 834 y 111 responden solo dentro de la subred (verificado con UFW).

### 3.6 CUPS — servidor de impresión

- **Necesidad:** N4.
- **Qué aporta:** las impresoras se conectan al servidor; CUPS publica colas IPP (puerto 631) utilizables desde Windows y Linux, con administración web (`https://192.168.80.10:631`) y registro de trabajos.
- **Beneficio:** la secretaría imprime certificados y constancias desde su cola, los docentes imprimen material didáctico desde las salas, y queda trazabilidad del gasto de impresión.
- **Criterio de éxito:** la cola se publica en `ipp://192.168.80.10:631`, es utilizable desde un cliente Windows y uno Linux, y los trabajos enviados quedan registrados en la interfaz de administración.

### 3.7 Samba — compartición de archivos para Windows

- **Necesidad:** N2 y N3 (equipos Windows de administración y secretaría académica).
- **Qué aporta:** exporta el **mismo árbol `/srv/compartido`** por SMB/CIFS (puerto 445) con carpetas por dependencia y `valid users` por grupo: NFS y Samba sirven los mismos datos, evitando duplicación entre plataformas.
- **Decisión de diseño:** deshabilitar NetBIOS legado (puertos 137–139) usando solo SMB sobre 445, soportado nativamente por Windows, macOS y Linux modernos.
- **Criterio de éxito:** las carpetas (`\\itec-server\secretaria`, `contabilidad`, `publico`) accesibles desde Windows solo con usuarios válidos del grupo correspondiente, permisos diferenciados por carpeta y puertos 137–139 cerrados (verificado con UFW).

### 3.8 Base de datos — PostgreSQL vía Dokploy

- **Necesidad:** N1 (formulario de preinscripción) y base para las aplicaciones académicas de N7.
- **Qué aporta:** base de datos relacional provisionada y administrada desde el panel de Dokploy; accesible solo desde la red interna (puerto 5432 no expuesto a internet). En ella se registran los aspirantes del formulario de inscripción con los datos que el PEI exige para la preinscripción: identificación, programa y jornada de interés, categoría de afiliación y autorización de tratamiento de datos personales.
- **Por qué PostgreSQL:** motor robusto y sin costo de licencia, soportado de forma nativa por Dokploy, con tipografía de datos adecuada para el registro de aspirantes (documentos, categorías de afiliación, programa de interés).
- **Criterio de éxito:** base de datos creada y conectada a la aplicación web (las preinscripciones quedan persistidas).

### 3.9 Dominio/DNS y SSL/TLS

- **Necesidad:** N8.
- **Qué aporta:** nombre de dominio gratuito que apunta al servidor y certificado TLS para HTTPS. En el diseño se propuso **DuckDNS** (`itec-quindio.duckdns.org`) con **Let's Encrypt**; en el laboratorio, al no disponer de IP pública ni de reenvío de los puertos 80/443 en el router, se usa **sslip.io** (`itec.192-168-80-10.sslip.io`, DNS gratuito sin registro que resuelve a la IP del servidor) y un certificado **autofirmado con CA propia** generado por `codigo/ssl/certificado_autofirmado.sh`. La CA se importa en los clientes de la LAN para que el candado sea confiable.
- **Por qué esta combinación:** costo cero y funcionamiento aun detrás de NAT/CGNAT. DuckDNS + Let's Encrypt queda documentado como la variante de producción cuando exista IP pública y los puertos 80/443 estén reenviados.
- **Criterio de éxito:** el dominio del laboratorio resuelve a `192.168.80.10`, el sitio responde por HTTPS con certificado válido/confiable y el puerto 80 únicamente redirige a 443.

### 3.10 Mejoras opcionales (puntos extra)

| Mejora | Descripción | Criterio de éxito |
|---|---|---|
| **Firewall UFW** | política *default deny*; solo se habilitan los puertos de la tabla de requisitos, y los servicios internos solo para la subred | UFW activo con denegación por defecto; desde fuera de la subred no se alcanza ningún servicio interno |
| **Docker Compose** | el sitio web y la base de datos se versionan con `docker-compose.yml` para despliegue reproducible | `docker compose up -d` levanta sitio y base de datos desde cero sin pasos manuales adicionales |
| **Respaldos automáticos** | tarea programada (cron) que respalda `/srv/compartido` y vuelca la base de datos | el respaldo semanal aparece en `/srv/backups` con datos actuales y una restauración de prueba es exitosa |
| **Monitoreo básico** | verificación periódica de servicios activos con alertas | la verificación reporta el estado de todos los servicios y genera alerta al detenerse alguno |

## 4. Tabla de requisitos

Servidor: **192.168.80.10** (hostname `itec-server`) · Red local: `192.168.80.0/24`

| # | Servicio | Software | IP | Puerto(s) | Protocolo | Tipo de servicio |
|---|---|---|---|---|---|---|
| 1 | Administración remota | OpenSSH | 192.168.80.10 | 22 | TCP | Gestión remota segura |
| 2 | Panel PaaS | Dokploy | 192.168.80.10 | 3000 | TCP (HTTP, solo LAN) | Plataforma de despliegue |
| 3 | Sitio web institucional | Traefik + Nginx (Dokploy) | 192.168.80.10 | 443 (80 → redirige a 443) | TCP (HTTPS/TLS) | Sitio web |
| 4 | Sincronización de tiempo | ntpd | 192.168.80.10 | 123 | UDP | NTP |
| 5 | Archivos salas Linux | nfs-kernel-server | 192.168.80.10 | 2049 | TCP (NFSv4) | Compartición de archivos |
| 6 | Autenticación salas Linux | ypserv (NIS) | 192.168.80.10 | 834 (fijado) + 111 | TCP/UDP (RPC) | Servicio de credenciales |
| 7 | Impresión | cupsd | 192.168.80.10 | 631 | TCP/UDP (IPP) | Servidor de impresión |
| 8 | Archivos Windows | smbd (Samba) | 192.168.80.10 | 445 | TCP (SMB/CIFS) | Compartición de archivos |
| 9 | Base de datos | PostgreSQL (Dokploy) | 192.168.80.10 | 5432 (solo LAN / red interna Docker) | TCP | Base de datos relacional |

**Notas de la tabla:**

- El puerto 834 de NIS se fija explícitamente en la configuración (`ypserv -p`) para poder filtrarlo con UFW; rpcbind (111) queda igualmente restringido a la LAN.
- Samba funciona únicamente sobre 445; los puertos legado NetBIOS 137–139 permanecen deshabilitados.
- El puerto 80 solo recibe tráfico para redirigirlo a HTTPS.
- 3000 (panel Dokploy) y 5432 (PostgreSQL) no se exponen a internet: UFW y la cadena `DOCKER-USER` los limitan a `192.168.80.0/24`. El 5432 de la base de Dokploy no se publica fuera de la red interna de Docker; la regla UFW es defensa en profundidad.
- El acceso HTTPS usa el dominio `itec.192-168-80-10.sslip.io` y un certificado de la CA local; ver §3.9.

## 5. Recursos y configuración de la máquina virtual

| Aspecto | Valor |
|---|---|
| Hipervisor | VirtualBox 7.x o VMware Workstation |
| Sistema operativo | Ubuntu Server 24.04 LTS |
| vCPU | 2 |
| RAM | 4 GB |
| Disco | 40 GB |
| Modo de red | Bridged (accesible desde toda la red local) |
| IP | 192.168.80.10 estática (o reserva DHCP en el router) |
| Hostname | itec-server |
| Puerta de enlace / DNS | 192.168.80.1 / DNS del proveedor o 8.8.8.8 |

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

- **Firewall (UFW):** política por defecto denegatoria; solo los puertos de la sección 4, y los servicios internos (123, 834, 2049, 445, 631, 3000, 5432) aceptan tráfico únicamente desde `192.168.80.0/24`.
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

## 10. Análisis de costo-beneficio

Toda la pila propuesta se construye con software libre o de uso gratuito. La tabla contrasta cada componente con la alternativa comercial típica (precios de lista aproximados para una carga equivalente; interesa el orden de magnitud, no una cotización exacta):

| Componente | Solución propuesta | Alternativa comercial típica | Beneficio |
|---|---|---|---|
| PaaS de despliegue | Dokploy autohospedado (USD 0) | Heroku (dyno básico ~25 USD/mes) o Vercel Pro (~20 USD/mes): 240–300 USD/año | Despliegue ágil sin costo recurrente y con los datos dentro de la institución |
| Base de datos | PostgreSQL (USD 0) | BD administrada en la nube (~25–40 USD/mes) o licencia de SQL Server (varios miles de USD) | Motor robusto sin licencias, soportado nativamente por Dokploy |
| Archivos y autenticación de las salas Linux | NFS + NIS incluidos en Ubuntu Server (USD 0) | Windows Server con File Server y AD DS más CALs por usuario/equipo (mil a varios miles de USD) | Funcionalidad requerida por las salas a costo cero |
| Archivos para Windows | Samba incluido en Ubuntu Server (USD 0) | Windows Server con File Server más CALs | Un solo árbol de datos para Linux y Windows sin licencias |
| Impresión | CUPS incluido en Ubuntu Server (USD 0) | Soluciones comerciales de gestión de impresión con cobro por dispositivo o usuario | Colas IPP estándar para Windows y Linux con registro de trabajos |
| Firewall | UFW incluido en Ubuntu (USD 0) | Appliance de firewall (300–1.500 USD) o servicio gestionado | Filtrado por subred suficiente para el alcance del proyecto |
| Dominio y TLS | DuckDNS + Let's Encrypt o sslip.io + CA local (USD 0) | Dominio propio (~15 USD/año) más certificado comercial (~150-300 USD/año) | DNS y certificados sin costo, también detrás de NAT |
| Sistema operativo del servidor | Ubuntu Server 24.04 LTS (USD 0) | Windows Server 2022 Standard (~1.000 USD por licencia) | Sin costo de licencia y con actualizaciones de seguridad gratuitas |

El costo de licencias de la pila completa es cero, frente a alternativas que suman desde unos cientos hasta varios miles de dólares. Los costos que la propuesta sí asume son de otra naturaleza: horas de instalación y administración (a cargo del equipo del proyecto), el hardware o la VM (existente en el laboratorio) y el consumo energético. Como beneficios no monetarios adicionales, la institución conserva los datos de aspirantes y estudiantes en sus propios sistemas (relevante para la Ley 1581 de 2012) y evita la dependencia de proveedores externos para el funcionamiento del sitio y de los servicios.

## 11. Trazabilidad de requisitos y evidencias

Esta tabla conecta cada requisito del proyecto con su verificación y con la captura real que lo demuestra (todas en `capturas/`). Se actualiza a medida que se ejecuta la implementación; una fila sin captura se considera pendiente.

| Requisito | Verificación | Evidencia |
|---|---|---|
| VM con 2 vCPU, 4 GB RAM, 40 GB y red bridged | Configuración de VirtualBox + `hostnamectl` | `capturas/01_vm/01_virtualbox_config.png`, `03_ip_hostname.png` |
| IP fija, hostname y SSH | `ip -br a`, `hostnamectl`, `ssh` desde el host | `capturas/01_vm/03_ip_hostname.png`, `04_ssh_desde_host.png` |
| Dokploy instalado y panel operativo | `docker service ls`, panel en `:3000` | `capturas/02_dokploy/02_docker_service_ls.png`, `03_panel_login.png` |
| Dominio/DNS configurado | `dig`/`nslookup` del dominio | `capturas/03_dns_ssl/02_dig.png` |
| SSL/TLS activo | `openssl verify`, candado del navegador | `capturas/03_dns_ssl/03_certificado.png`, `04_https_candado.png` |
| Firewall UFW (extra) | `ufw status verbose`, `iptables -L DOCKER-USER` | `capturas/11_seguridad/01_ufw_status.png`, `02_docker_user.png` |
| Sitio web HTTPS con contenido real | Navegador: home, oferta y formulario | `capturas/05_web/01_home_https.png`, `02_oferta_programas.png` |
| Formulario conectado a PostgreSQL | Envío real + `SELECT` de la fila | `capturas/05_web/04_registro_exitoso.png`, `capturas/06_bd/04_preinscripcion_insertada.png` |
| Base de datos creada en Dokploy | Panel de Dokploy + `\dt` | `capturas/06_bd/01_dokploy_db_running.png`, `02_tablas.png` |
| Backup automático (extra) | Archivos `.enc`, cron, log y restauración | `capturas/11_seguridad/04_backup_archivos.png` a `07_restauracion_select.png` |

---

*Documento elaborado para el Proyecto Final del curso Administración de Infraestructura de TI — Universidad del Quindío, 2026-1. Fuente de datos institucionales: PEI y Reglamento Estudiantil públicos del Instituto Técnico de Educación Comfenalco Quindío.*
