# ============================================================================
# Dockerfile - Sitio web institucional ITEC (PHP 8.3 + Apache)
# ----------------------------------------------------------------------------
# Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
# Instituto Tecnico de Educacion Comfenalco Quindio
#
# Imagen minima basada en la oficial de PHP con Apache. El unico modulo
# adicional necesario es pdo_pgsql (conexion a PostgreSQL).
#
# La aplicacion se sirve desde /var/www/html (raiz por defecto de Apache).
# La configuracion de la base de datos entra por variables de entorno
# (ver .env.example y app/config.php), nunca por archivos versionados.
# ============================================================================

FROM php:8.3-apache

# Driver PostgreSQL para PDO (requiere libpq-dev para compilar).
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq-dev \
    && docker-php-ext-install pdo_pgsql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Habilitar modulo de reescritura (por si se agregan rutas amables).
RUN a2enmod rewrite

# Codigo de la aplicacion (ver .dockerignore).
COPY app/ /var/www/html/

# El servidor web es el dueno de los archivos estaticos.
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
