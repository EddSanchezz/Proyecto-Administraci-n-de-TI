-- ============================================================================
-- init.sql - Esquema de la base de datos del sitio web institucional ITEC
-- ----------------------------------------------------------------------------
-- Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
-- Instituto Tecnico de Educacion Comfenalco Quindio
--
-- Este archivo alimenta el formulario de preinscripcion en linea (necesidad
-- N1 de analisis.md) con los datos reales de la oferta academica verificados
-- en el PEI 2024 (seccion 2.1: once programas tecnicos laborales vigentes).
--
-- Como se aplica:
--   1. Con docker compose: se monta en /docker-entrypoint-initdb.d/ y la
--      imagen oficial de PostgreSQL lo ejecuta al crear el volumen por
--      primera vez (usuario/base de datos vienen de las variables .env).
--   2. Con Dokploy: al crear la base de datos PostgreSQL se pega este
--      contenido en el campo de inicializacion, o se ejecuta con:
--      docker exec -i <contenedor> psql -U itec_app -d itec < init.sql
--
-- Contenido:
--   * tabla programas        : oferta academica (fuente del formulario).
--   * tabla preinscripciones : aspirantes (datos Ley 1581 de 2012).
--   * vista v_preinscripciones_por_programa : consulta de secretaria.
-- ============================================================================

SET client_encoding = 'UTF8';

-- ----------------------------------------------------------------------------
-- Tabla programas: oferta tecnica laboral vigente (PEI 2024, seccion 2.1).
-- Los once programas conservan el registro/ reconocimiento oficial y la
-- duracion en horas publicados por el Instituto.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS programas (
    codigo          text        PRIMARY KEY,
    nombre          text        NOT NULL,
    nivel           text        NOT NULL DEFAULT 'Tecnico Laboral',
    registro        text        NOT NULL,
    duracion_horas  integer     NOT NULL CHECK (duracion_horas > 0),
    jornadas        text        NOT NULL DEFAULT 'Diurna, Nocturna y Sabatina',
    activo          boolean     NOT NULL DEFAULT true
);

INSERT INTO programas (codigo, nombre, nivel, registro, duracion_horas) VALUES
    ('aux_recursos_humanos',    'Tecnico Laboral en Auxiliar de Recursos Humanos',               'Tecnico Laboral',           'Resolucion 3838 del 25 de noviembre de 2016',                 900),
    ('aux_contable_financiero', 'Tecnico Laboral Auxiliar Contable y Financiero',                'Tecnico Laboral',           'Resoluciones 63-01673 de 2020 y 0964 del 23 de junio de 2021', 1780),
    ('preparatorio_musical',     'Conocimientos academicos en Preparatorio Musical',             'Conocimientos academicos',  'Resolucion 1508 del 24 de julio de 2020',                     576),
    ('liniero_redes_energia',   'Tecnico Laboral Liniero en Redes de Energia',                  'Tecnico Laboral',           'Resolucion 1509 del 24 de julio de 2020',                      900),
    ('aux_cartera_cobranzas',   'Tecnico Laboral en Auxiliar de Cartera y Cobranzas',           'Tecnico Laboral',           'Resolucion 1809 del 22 de septiembre de 2020',                  900),
    ('secretariado_contable',   'Tecnico Laboral en Secretariado Auxiliar Contable',            'Tecnico Laboral',           'Resoluciones 3072 de 2014 y 0968 del 23 de junio de 2021',   1780),
    ('electricista_residencial','Tecnico Laboral en Electricista Construccion Residencial',     'Tecnico Laboral',           'Resoluciones 3069 de 2014 y 0963 del 23 de junio de 2021',    900),
    ('peluqueria',              'Tecnico Laboral en Peluqueria',                                 'Tecnico Laboral',           'Resolucion 0967 del 23 de junio de 2021',                      900),
    ('operario_confeccion',     'Tecnico Laboral en Operario de Confeccion',                    'Tecnico Laboral',           'Resolucion 1604 del 28 de julio de 2022',                      900),
    ('manicurista_pedicurista', 'Tecnico Laboral en Manicurista y Pedicurista',                 'Tecnico Laboral',           'Resolucion 1685 del 11 de julio de 2023',                      700),
    ('aux_talento_humano',      'Tecnico Laboral en Auxiliar de Talento Humano',                'Tecnico Laboral',           'Resoluciones 1685 de 2023 y 63-00797 de 2023',               1780)
ON CONFLICT (codigo) DO NOTHING;

-- ----------------------------------------------------------------------------
-- Tabla preinscripciones: aspirantes registrados desde el sitio web.
--
-- Restricciones alineadas con el proceso de admision del PEI (seccion
-- 3.1.2: la preinscripcion agenda la entrevista con el Coordinador de
-- Bienestar Institucional, unico criterio de admision) y con el tratamiento
-- de datos personales (PEI 3.1.1 y Ley 1581 de 2012): la autorizacion queda
-- registrada con fecha y NO se guardan datos sensibles.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS preinscripciones (
    id                  bigserial      PRIMARY KEY,
    nombres             text           NOT NULL,
    apellidos           text           NOT NULL,
    tipo_documento      text           NOT NULL CHECK (tipo_documento IN ('CC', 'TI', 'CE', 'PEP', 'PAP')),
    numero_documento    text           NOT NULL CHECK (numero_documento ~ '^[0-9]{5,12}$'),
    fecha_nacimiento    date           NOT NULL CHECK (fecha_nacimiento BETWEEN '1926-01-01' AND CURRENT_DATE),
    correo              text           NOT NULL CHECK (correo ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    telefono            text           NOT NULL CHECK (telefono ~ '^[0-9()+ -]{7,20}$'),
    programa_codigo     text           NOT NULL REFERENCES programas (codigo),
    jornada             text           NOT NULL CHECK (jornada IN ('diurna', 'nocturna', 'sabatina')),
    autorizacion_datos  boolean        NOT NULL CHECK (autorizacion_datos),
    estado              text           NOT NULL DEFAULT 'nueva' CHECK (estado IN ('nueva', 'contactada', 'entrevistada', 'admitida', 'no_admitida')),
    observaciones       text,
    created_at          timestamptz    NOT NULL DEFAULT now(),
    updated_at          timestamptz    NOT NULL DEFAULT now(),
    -- Un mismo documento no puede preinscribirse dos veces al mismo programa.
    CONSTRAINT uq_preinscripcion UNIQUE (tipo_documento, numero_documento, programa_codigo)
);

CREATE INDEX IF NOT EXISTS idx_preinscripciones_programa ON preinscripciones (programa_codigo);
CREATE INDEX IF NOT EXISTS idx_preinscripciones_estado   ON preinscripciones (estado);
CREATE INDEX IF NOT EXISTS idx_preinscripciones_fecha    ON preinscripciones (created_at DESC);

-- ----------------------------------------------------------------------------
-- Vista para secretaria: preinscripciones pendientes por programa con el
-- nombre legible del programa y los datos de contacto del aspirante.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_preinscripciones_por_programa AS
SELECT
    p.nombre                       AS programa,
    pr.estado,
    count(*)                       AS total,
    string_agg(
        pr.nombres || ' ' || pr.apellidos || ' <' || pr.correo || '>',
        ', ' ORDER BY pr.created_at
    )                              AS aspirantes
FROM preinscripciones pr
JOIN programas p ON p.codigo = pr.programa_codigo
GROUP BY p.nombre, pr.estado;

-- ----------------------------------------------------------------------------
-- Consultas de verificacion (para documentacion.md, semana 3):
--   SELECT codigo, nombre, duracion_horas FROM programas ORDER BY nombre;
--   SELECT count(*) FROM preinscripciones;
--   SELECT * FROM v_preinscripciones_por_programa;
--   INSERT de prueba controlada por el formulario web (no por SQL directo).
-- ----------------------------------------------------------------------------
