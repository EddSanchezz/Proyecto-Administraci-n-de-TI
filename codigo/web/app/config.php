<?php
/**
 * ============================================================================
 * config.php - Configuracion comun de la aplicacion web ITEC
 * ----------------------------------------------------------------------------
 * Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
 * Instituto Tecnico de Educacion Comfenalco Quindio
 *
 * Toda la configuracion sensible entra por variables de entorno (buenas
 * practicas de doce factores), definidas:
 *   - con Dokploy: en la configuracion de la aplicacion y su PostgreSQL.
 *   - con docker compose: en el archivo .env (fuera del repositorio).
 *
 * Este archivo NO contiene secretos.
 * ============================================================================
 */

declare(strict_types=1);

/* --------------------------- Configuracion de BD ------------------------- */

function db_config(): array
{
    return [
        'host' => getenv('DB_HOST') ?: 'db',
        'port' => getenv('DB_PORT') ?: '5432',
        'name' => getenv('DB_NAME') ?: 'itec',
        'user' => getenv('DB_USER') ?: 'itec_app',
        'pass' => getenv('DB_PASS') ?: '',
    ];
}

/* ------------------------------ Conexion PDO ------------------------------ */

function db(): PDO
{
    static $pdo = null;

    if ($pdo === null) {
        $c  = db_config();
        $dsn = sprintf(
            'pgsql:host=%s;port=%s;dbname=%s',
            $c['host'],
            $c['port'],
            $c['name']
        );

        $pdo = new PDO($dsn, $c['user'], $c['pass'], [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    }

    return $pdo;
}

/* ------------------------------- Utilidades ------------------------------- */

/** Escapa texto para salida HTML (previene XSS en campos ingresados). */
function e(?string $texto): string
{
    return htmlspecialchars($texto ?? '', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/** Fragmentos comunes de cabecera y pie de pagina del sitio. */
function cabecera(string $titulo, string $activo = ''): void
{
    $paginas = [
        ''            => 'Inicio',
        'inscripcion' => 'Preinscripcion',
    ];
    $nav = '';
    foreach ($paginas as $ruta => $etiqueta) {
        $clase  = ($ruta === $activo) ? ' class="activo"' : '';
        $enlace = ($ruta === '') ? 'index.php' : $ruta . '.php';
        $nav   .= sprintf('<a href="%s"%s>%s</a>', $enlace, $clase, $etiqueta);
    }
    ?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($titulo) ?> - Instituto Tecnico de Educacion Comfenalco Quindio</title>
    <link rel="stylesheet" href="estilos.css">
</head>
<body>
    <header class="cabecera-sitio">
        <div class="contenedor barra">
            <a class="marca" href="index.php">
                <span class="marca-sigla">ITEC</span>
                <span class="marca-texto">Instituto Tecnico de Educacion<br>Comfenalco Quindio</span>
            </a>
            <nav class="navegacion"><?= $nav ?></nav>
        </div>
    </header>
    <main class="contenedor">
    <?php
}

function pie(): void
{
    ?>
    </main>
    <footer class="pie-sitio">
        <div class="contenedor">
            <p>
                Instituto Tecnico de Educacion Comfenalco Quindio - NIT 890000381-0 -
                Licencia de funcionamiento 1712 del 8 de septiembre de 2020.
            </p>
            <p>
                Sitio desarrollado como Proyecto Final del curso Administracion de
                Infraestructura de TI - Universidad del Quindio, 2026-1.
            </p>
        </div>
    </footer>
</body>
</html>
    <?php
}
