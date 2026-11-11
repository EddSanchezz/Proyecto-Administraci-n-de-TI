# Proyecto Final — Administración de Infraestructura de TI

> Infraestructura de servicios TI para el **Instituto Técnico de Educación Comfenalco Quindío** — Dokploy (PaaS) + servicios Linux tradicionales.
> Universidad del Quindío · Facultad de Ingeniería de Sistemas y Computación · Semestre 2026-1

**Equipo (ingenieros):** Esteban · Jerónimo · Brahian · Jack Alejandro Marín Hernández

## Estado del proyecto

| Semana | Entregable | Archivos | Estado |
|--------|------------|----------|--------|
| 1 | Análisis y diseño | `analisis.md` · `diagrama.mmd` | Listo para revisión |
| 2 | Infraestructura base | `codigo/instalacion/01-03` · `codigo/ssl/` · `codigo/configuraciones/` · `codigo/seguridad/` | Código listo; pendiente ejecutar en la VM |
| 3 | Servicios de infraestructura | `codigo/instalacion/04-07` · `codigo/web/` · `codigo/configuraciones/` | Código listo; pendiente ejecutar en la VM |
| 4 | Documentación y presentación | `documentacion.md` · `capturas/` | Plantilla lista |

## Estructura del repositorio

```
.
├── README.md               # este archivo: instrucciones y resumen
├── analisis.md             # Entregable 1: análisis de necesidades y diseño
├── diagrama.mmd            # Entregable 1: diagrama de arquitectura (Mermaid)
├── documentacion.md        # Entregable 4: documentación técnica (plantilla)
├── capturas/               # evidencias de servicios funcionando
├── codigo/                 # configuraciones y scripts propios
│   ├── instalacion/        # scripts de instalación (Dokploy, NTP, ...)
│   ├── configuraciones/     # archivos de configuración (ntp.conf, ...)
│   ├── ssl/                # generación de certificados
│   ├── seguridad/          # reglas de firewall (UFW)
│   └── web/                # sitio web institucional + base de datos
└── Documentos/              # guía oficial del proyecto (PDF)
```

## Mapeo de servicios con la operación del instituto

| Servicio | Área del instituto que lo usa |
|---|---|
| NIS + NFS | Estudiantes en salas de informática Linux (cuentas y trabajos persistentes entre salas) |
| Samba | Administración y secretaría académica en Windows (matrículas, certificados, contabilidad) |
| CUPS | Impresión de certificados, constancias y material didáctico |
| Sitio web + PostgreSQL | Portal con oferta académica (PEI) y formulario de preinscripción en línea |
| NTP | Hora uniforme para matrículas, certificados y respaldos |
| Dokploy | Despliegue del sitio y de futuras aplicaciones académicas |

## Cómo revisar la Semana 1

1. **`analisis.md`** — contexto real del instituto (perfil y datos verificados en el PEI y el Reglamento Estudiantil: identificación, once programas técnicos con registro y duración, jornadas, procesos de admisión, matrícula, evaluación y certificación), necesidades (N1–N8), justificación de cada servicio con su criterio de éxito, tabla de requisitos (IP/puerto/protocolo/tipo), recursos de la VM, árbol de datos compartido, plan por semanas, riesgos y análisis de costo-beneficio (licencias cero frente a alternativas comerciales).
2. **`diagrama.mmd`** — copiar su contenido en <https://mermaid.live> (o abrir en VS Code con la extensión *Markdown Preview Mermaid Support*) para ver el diagrama de arquitectura.

### Pendientes por completar (antes de la entrega)

- [ ] Registrar el subdominio en DuckDNS (propuesto: `itec-quindio.duckdns.org`).
- [ ] Completar apellidos de Esteban, Jerónimo y Brahian si se desea el nombre completo en los documentos.

## Próximos pasos (Semana 2)

1. Crear la VM: VirtualBox/VMware · Ubuntu Server 24.04 LTS · 2 vCPU · 4 GB RAM · 40 GB · red **bridged**.
2. Configurar IP estática `192.168.1.10` (o reserva DHCP).
3. Ejecutar los scripts de `codigo/` siguiendo el orden de `codigo/README.md`:
   preparación del servidor, Dokploy, NTP, DuckDNS, certificado y firewall.
4. Registrar el dominio DuckDNS y configurar SSL/TLS.
5. Tomar las evidencias en `capturas/` y completar `documentacion.md`.

El código de las semanas 2 y 3 está escrito y documentado (ver `codigo/README.md`
para el orden de ejecución y las notas de seguridad sobre secretos); falta
ejecutarlo en la VM, verificar cada servicio y evidenciar.

## Recursos

- Guía oficial del curso: `Documentos/11_proyecto_final_admin_infraestructura.pdf`
- PEI y Reglamento Estudiantil del instituto: <https://comfenalcoquindio.com/instituto-tecnico> (sección Reglamentación)
- [Documentación de Dokploy](https://dokploy.com/docs)
- Manuales: NFS · Samba · CUPS · [NTP Project](https://www.ntppool.org/es/) · NIS

---

