<?php
/**
 * ============================================================================
 * inscripcion.php - Formulario de preinscripcion en linea
 * ----------------------------------------------------------------------------
 * Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
 * Instituto Tecnico de Educacion Comfenalco Quindio
 *
 * Replica el proceso de inscripcion del PEI (seccion 3.1.2.1): el aspirante
 * envia sus datos, la recepcionista programa la entrevista con el Coordinador
 * de Bienestar Institucional y el registro queda en PostgreSQL para su
 * seguimiento desde secretaria.
 *
 * Seguridad aplicada:
 *   - Token CSRF por sesion en el formulario (bloqueo de envios falsificados).
 *   - Validacion server-side de TODOS los campos (la de HTML es solo apoyo).
 *   - Consultas siempre preparadas (PDO, sin concatenar SQL).
 *   - Salida escapada con htmlspecialchars (prevencion XSS).
 *   - Duplicados bloqueados por restriccion unica en la base de datos
 *     (documento + programa) con mensaje amable.
 *   - Autorizacion de tratamiento de datos obligatoria (Ley 1581 de 2012,
 *     PEI 3.1.1): se guarda el hecho y la fecha, no el detalle del consentimiento.
 * ============================================================================
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';

session_start();

/* --------------------------- Constantes del formulario -------------------- */

const TIPOS_DOCUMENTO = ['CC', 'TI', 'CE', 'PEP', 'PAP'];
const JORNADAS = [
    'diurna'   => 'Diurna',
    'nocturna' => 'Nocturna',
    'sabatina' => 'Sabatina',
];

/* ------------------------------- Validacion ------------------------------- */

/**
 * Valida los datos enviados y devuelve [datos, errores].
 * Reglas alineadas con las restricciones declaradas en db/init.sql.
 */
function validar(array $post, array $programasValidos): array
{
    $datos = [
        'nombres'           => trim($post['nombres'] ?? ''),
        'apellidos'         => trim($post['apellidos'] ?? ''),
        'tipo_documento'    => trim($post['tipo_documento'] ?? ''),
        'numero_documento'  => trim($post['numero_documento'] ?? ''),
        'fecha_nacimiento'  => trim($post['fecha_nacimiento'] ?? ''),
        'correo'            => trim($post['correo'] ?? ''),
        'telefono'          => trim($post['telefono'] ?? ''),
        'programa'          => trim($post['programa'] ?? ''),
        'jornada'           => trim($post['jornada'] ?? ''),
        'autorizacion'      => isset($post['autorizacion']),
    ];

    $errores = [];

    if ($datos['nombres'] === '' || mb_strlen($datos['nombres']) < 3) {
        $errores['nombres'] = 'Escriba sus nombres (minimo 3 letras).';
    } elseif (mb_strlen($datos['nombres']) > 80) {
        $errores['nombres'] = 'El campo nombres no puede exceder 80 caracteres.';
    }

    if ($datos['apellidos'] === '' || mb_strlen($datos['apellidos']) < 3) {
        $errores['apellidos'] = 'Escriba sus apellidos (minimo 3 letras).';
    } elseif (mb_strlen($datos['apellidos']) > 80) {
        $errores['apellidos'] = 'El campo apellidos no puede exceder 80 caracteres.';
    }

    if (!in_array($datos['tipo_documento'], TIPOS_DOCUMENTO, true)) {
        $errores['tipo_documento'] = 'Seleccione un tipo de documento valido.';
    }

    if (!preg_match('/^[0-9]{5,12}$/', $datos['numero_documento'])) {
        $errores['numero_documento'] = 'El numero de documento debe tener entre 5 y 12 digitos.';
    }

    $fecha = DateTime::createFromFormat('Y-m-d', $datos['fecha_nacimiento']);
    if ($datos['fecha_nacimiento'] === '' || !$fecha || $fecha->format('Y-m-d') !== $datos['fecha_nacimiento']) {
        $errores['fecha_nacimiento'] = 'Indique una fecha de nacimiento valida.';
    } else {
        $edad = (int)$fecha->diff(new DateTime('today'))->y;
        if ($edad < 10 || $edad > 100) {
            $errores['fecha_nacimiento'] = 'La fecha de nacimiento no es coherente con una preinscripcion.';
        }
    }

    if (!filter_var($datos['correo'], FILTER_VALIDATE_EMAIL) || mb_strlen($datos['correo']) > 120) {
        $errores['correo'] = 'Escriba un correo electronico valido.';
    }

    if (!preg_match('/^[0-9()+ \-]{7,20}$/', $datos['telefono'])) {
        $errores['telefono'] = 'Escriba un telefono de contacto de 7 a 20 digitos.';
    }

    if (!in_array($datos['programa'], $programasValidos, true)) {
        $errores['programa'] = 'Seleccione un programa de la oferta vigente.';
    }

    if (!isset(JORNADAS[$datos['jornada']])) {
        $errores['jornada'] = 'Seleccione una jornada valida.';
    }

    if (!$datos['autorizacion']) {
        $errores['autorizacion'] = 'Debe autorizar el tratamiento de sus datos personales para continuar.';
    }

    return [$datos, $errores];
}

/* ----------------------------- Logica principal --------------------------- */

/* Token CSRF: uno por sesion, rotado despues de un registro exitoso. */
if (empty($_SESSION['csrf'])) {
    $_SESSION['csrf'] = bin2hex(random_bytes(32));
}
$tokenSesion = $_SESSION['csrf'];

$registrado = null;
$errores    = [];
$datos      = [
    'nombres' => '', 'apellidos' => '', 'tipo_documento' => 'CC', 'numero_documento' => '',
    'fecha_nacimiento' => '', 'correo' => '', 'telefono' => '', 'programa' => '',
    'jornada' => 'diurna', 'autorizacion' => false,
];

/* Oferta academica: fuente de verdad = tabla programas en PostgreSQL. */
try {
    $filasProgramas = db()
        ->query('SELECT codigo, nombre, duracion_horas FROM programas WHERE activo ORDER BY nombre')
        ->fetchAll();
    $programasValidos = array_column($filasProgramas, 'codigo');
} catch (PDOException $e) {
    error_log('Error de conexion a PostgreSQL: ' . $e->getMessage());
    $filasProgramas  = [];
    $programasValidos = [];
    $errores['general'] = 'El servicio de preinscripcion no esta disponible en este momento. '
        . 'Intente mas tarde o acerquese a las instalaciones del Instituto.';
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    /* Verificacion del token CSRF. */
    if (!hash_equals($tokenSesion, $_POST['csrf'] ?? '')) {
        $errores['general'] = 'La sesion expiro o el envio no es valido. Vuelva a cargar el formulario.';
    } else {
        [$datos, $errores] = validar($_POST, $programasValidos);

        if (empty($errores)) {
            try {
                $sentencia = db()->prepare(
                    'INSERT INTO preinscripciones
                        (nombres, apellidos, tipo_documento, numero_documento,
                         fecha_nacimiento, correo, telefono, programa_codigo,
                         jornada, autorizacion_datos)
                     VALUES
                        (:nombres, :apellidos, :tipo_documento, :numero_documento,
                         :fecha_nacimiento, :correo, :telefono, :programa,
                         :jornada, :autorizacion)'
                );
                $sentencia->execute([
                    ':nombres'           => $datos['nombres'],
                    ':apellidos'         => $datos['apellidos'],
                    ':tipo_documento'    => $datos['tipo_documento'],
                    ':numero_documento'  => $datos['numero_documento'],
                    ':fecha_nacimiento'  => $datos['fecha_nacimiento'],
                    ':correo'            => $datos['correo'],
                    ':telefono'          => $datos['telefono'],
                    ':programa'          => $datos['programa'],
                    ':jornada'           => $datos['jornada'],
                    ':autorizacion'      => $datos['autorizacion'] ? 'true' : 'false',
                ]);
                $registrado = $datos;

                /* Rotar token y limpiar el formulario tras el registro. */
                $_SESSION['csrf'] = bin2hex(random_bytes(32));
                $datos = [
                    'nombres' => '', 'apellidos' => '', 'tipo_documento' => 'CC', 'numero_documento' => '',
                    'fecha_nacimiento' => '', 'correo' => '', 'telefono' => '', 'programa' => '',
                    'jornada' => 'diurna', 'autorizacion' => false,
                ];
            } catch (PDOException $e) {
                if ($e->getCode() === '23505') {
                    /* Restriccion unica documento+programa. */
                    $errores['numero_documento'] =
                        'Ya existe una preinscripcion con ese documento para el programa seleccionado.';
                } else {
                    error_log('Error al registrar preinscripcion: ' . $e->getMessage());
                    $errores['general'] = 'No fue posible guardar la preinscripcion. Intente de nuevo en unos minutos.';
                }
            }
        }
    }
}

/* --------------------------------- Salida --------------------------------- */

cabecera('Preinscripcion', 'inscripcion');

if ($registrado !== null):
    /* ---------------------- Confirmacion de registro ---------------------- */
    $nombrePrograma = '';
    foreach ($filasProgramas as $p) {
        if ($p['codigo'] === $registrado['programa']) {
            $nombrePrograma = $p['nombre'];
            break;
        }
    }
    ?>
    <section class="mensaje exito">
        <h1>Preinscripcion registrada</h1>
        <p>
            Gracias, <strong><?= e($registrado['nombres'] . ' ' . $registrado['apellidos']) ?></strong>.
            Sus datos quedaron registrados en el sistema del Instituto.
        </p>
        <p>
            Programa: <strong><?= e($nombrePrograma) ?></strong> -
            jornada <strong><?= e(JORNADAS[$registrado['jornada']]) ?></strong>.
        </p>
        <h2>Que sigue ahora</h2>
        <ol>
            <li>La secretaria academica verificara su informacion y lo contactara al correo y telefono registrados.</li>
            <li>Asistira a la <strong>entrevista de admision</strong> con el Coordinador de Bienestar Institucional (unico criterio de admision).</li>
            <li>Con la admision, entregara la documentacion exigida y pagara la matricula segun su categoria de afiliacion.</li>
        </ol>
        <p class="nota">
            Registro realizado el <?= e(date('d/m/Y H:i')) ?>. Los datos personales se tratan
            conforme a la Ley 1581 de 2012 y la Politica de Tratamiento de Datos del Instituto.
        </p>
        <p><a class="boton" href="index.php">Volver al inicio</a></p>
    </section>
    <?php
else:
    /* ---------------------------- Formulario ------------------------------ */
    ?>
    <section class="pagina-formulario">
        <h1>Formulario de preinscripcion</h1>
        <p class="introduccion">
            Complete sus datos para iniciar el proceso de admision. La inscripcion
            tambien puede hacerse de forma presencial en las instalaciones del
            Instituto (PEI, seccion 3.1.2.1).
        </p>

        <?php if (isset($errores['general'])): ?>
            <p class="mensaje error"><?= e($errores['general']) ?></p>
        <?php elseif (empty($filasProgramas) && $_SERVER['REQUEST_METHOD'] === 'GET'): ?>
            <p class="mensaje aviso">
                En este momento no se puede cargar la oferta academica desde la base de datos.
                Intente mas tarde.
            </p>
        <?php endif; ?>

        <form method="post" action="inscripcion.php" class="formulario" novalidate>
            <input type="hidden" name="csrf" value="<?= e($tokenSesion) ?>">

            <fieldset>
                <legend>Identificacion del aspirante</legend>

                <div class="campo">
                    <label for="nombres">Nombres *</label>
                    <input type="text" id="nombres" name="nombres" maxlength="80" required
                           value="<?= e($datos['nombres']) ?>">
                    <?php if (isset($errores['nombres'])): ?><p class="error-campo"><?= e($errores['nombres']) ?></p><?php endif; ?>
                </div>

                <div class="campo">
                    <label for="apellidos">Apellidos *</label>
                    <input type="text" id="apellidos" name="apellidos" maxlength="80" required
                           value="<?= e($datos['apellidos']) ?>">
                    <?php if (isset($errores['apellidos'])): ?><p class="error-campo"><?= e($errores['apellidos']) ?></p><?php endif; ?>
                </div>

                <div class="campo media">
                    <label for="tipo_documento">Tipo de documento *</label>
                    <select id="tipo_documento" name="tipo_documento" required>
                        <?php
                        $etiquetasTipo = ['CC' => 'Cedula de ciudadania', 'TI' => 'Tarjeta de identidad',
                                          'CE' => 'Cedula de extranjeria', 'PEP' => 'Permiso especial de permanencia',
                                          'PAP' => 'Pasaporte'];
                        foreach ($etiquetasTipo as $valor => $etiqueta): ?>
                            <option value="<?= $valor ?>" <?= $datos['tipo_documento'] === $valor ? 'selected' : '' ?>><?= $etiqueta ?></option>
                        <?php endforeach; ?>
                    </select>
                    <?php if (isset($errores['tipo_documento'])): ?><p class="error-campo"><?= e($errores['tipo_documento']) ?></p><?php endif; ?>
                </div>

                <div class="campo media">
                    <label for="numero_documento">Numero de documento *</label>
                    <input type="text" id="numero_documento" name="numero_documento" inputmode="numeric"
                           pattern="[0-9]{5,12}" maxlength="12" required
                           value="<?= e($datos['numero_documento']) ?>">
                    <?php if (isset($errores['numero_documento'])): ?><p class="error-campo"><?= e($errores['numero_documento']) ?></p><?php endif; ?>
                </div>

                <div class="campo media">
                    <label for="fecha_nacimiento">Fecha de nacimiento *</label>
                    <input type="date" id="fecha_nacimiento" name="fecha_nacimiento" required
                           value="<?= e($datos['fecha_nacimiento']) ?>">
                    <?php if (isset($errores['fecha_nacimiento'])): ?><p class="error-campo"><?= e($errores['fecha_nacimiento']) ?></p><?php endif; ?>
                </div>
            </fieldset>

            <fieldset>
                <legend>Contacto</legend>

                <div class="campo media">
                    <label for="correo">Correo electronico *</label>
                    <input type="email" id="correo" name="correo" maxlength="120" required
                           value="<?= e($datos['correo']) ?>">
                    <?php if (isset($errores['correo'])): ?><p class="error-campo"><?= e($errores['correo']) ?></p><?php endif; ?>
                </div>

                <div class="campo media">
                    <label for="telefono">Telefono / celular *</label>
                    <input type="tel" id="telefono" name="telefono" maxlength="20" required
                           placeholder="606 7368976"
                           value="<?= e($datos['telefono']) ?>">
                    <?php if (isset($errores['telefono'])): ?><p class="error-campo"><?= e($errores['telefono']) ?></p><?php endif; ?>
                </div>
            </fieldset>

            <fieldset>
                <legend>Programa de interes</legend>

                <div class="campo">
                    <label for="programa">Programa tecnico laboral *</label>
                    <select id="programa" name="programa" required>
                        <option value="" disabled <?= $datos['programa'] === '' ? 'selected' : '' ?>>Seleccione un programa</option>
                        <?php foreach ($filasProgramas as $p): ?>
                            <option value="<?= e($p['codigo']) ?>" <?= $datos['programa'] === $p['codigo'] ? 'selected' : '' ?>>
                                <?= e($p['nombre']) ?> (<?= e((string)$p['duracion_horas']) ?> horas)
                            </option>
                        <?php endforeach; ?>
                    </select>
                    <?php if (isset($errores['programa'])): ?><p class="error-campo"><?= e($errores['programa']) ?></p><?php endif; ?>
                </div>

                <div class="campo media">
                    <label for="jornada">Jornada *</label>
                    <select id="jornada" name="jornada" required>
                        <?php foreach (JORNADAS as $valor => $etiqueta): ?>
                            <option value="<?= $valor ?>" <?= $datos['jornada'] === $valor ? 'selected' : '' ?>><?= $etiqueta ?></option>
                        <?php endforeach; ?>
                    </select>
                    <?php if (isset($errores['jornada'])): ?><p class="error-campo"><?= e($errores['jornada']) ?></p><?php endif; ?>
                </div>
            </fieldset>

            <fieldset>
                <legend>Autorizacion de datos personales</legend>
                <div class="campo chequeo">
                    <label class="etiqueta-chequeo">
                        <input type="checkbox" name="autorizacion" value="1" required
                               <?= $datos['autorizacion'] ? 'checked' : '' ?>>
                        Autorizo al Instituto Tecnico de Educacion Comfenalco Quindio a recolectar,
                        almacenar y usar mis datos personales unicamente para el proceso de admision,
                        matricula y comunicaciones academicas, conforme a la Ley 1581 de 2012. *
                    </label>
                    <?php if (isset($errores['autorizacion'])): ?><p class="error-campo"><?= e($errores['autorizacion']) ?></p><?php endif; ?>
                </div>
            </fieldset>

            <p class="nota">
                Los campos marcados con * son obligatorios. La entrevista de admision es el
                unico criterio de ingreso; para Preparatorio Musical y Liniero en Redes de
                Energia se aplican ademas pruebas de conocimientos.
            </p>

            <button type="submit" class="boton">Enviar preinscripcion</button>
        </form>
    </section>
    <?php
endif;

pie();
