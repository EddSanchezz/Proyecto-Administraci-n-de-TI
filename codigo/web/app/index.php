<?php
/**
 * ============================================================================
 * index.php - Sitio web institucional del Instituto ITEC
 * ----------------------------------------------------------------------------
 * Proyecto Final - Administracion de Infraestructura de TI (Uniquindio 2026-1)
 * Instituto Tecnico de Educacion Comfenalco Quindio
 *
 * Contenido verificado en el PEI 2024 y el Reglamento Estudiantil
 * (version 007, codigo I-ED-0001): identificacion, oferta academica,
 * procesos de admision y matricula, jornadas, modalidad y contacto.
 * No se inventan datos: todo lo publicado aqui proviene del analisis.
 * ============================================================================
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';

cabecera('Inicio');
?>

<section class="portada">
    <h1>Formacion para el trabajo y el desarrollo humano</h1>
    <p class="lema">
        Institucion de naturaleza privada, modalidad presencial, con licencia de
        funcionamiento 1712 del 8 de septiembre de 2020, adscrita a Comfenalco
        Quindio y bajo la autoridad de la Secretaria de Educacion Municipal de
        Armenia y el Ministerio de Educacion Nacional.
    </p>
    <p>
        <a class="boton grande" href="inscripcion.php">Preinscribase aqui</a>
        <a class="boton secundario" href="#oferta">Ver la oferta academica</a>
    </p>
</section>

<section id="instituto">
    <h2>El Instituto</h2>
    <div class="dos-columnas">
        <div>
            <h3>Trayectoria</h3>
            <ul>
                <li>La Caja Comfenalco Quindio ofrece capacitacion desde 1967.</li>
                <li>El Instituto inicia labores en 1997 con el programa Secretariado Auxiliar Contable Sistematizado.</li>
                <li>Certificacion de calidad ISO 9001 desde 2013.</li>
                <li>Programas certificados bajo las normas NTC 5555, NTC 5581 y NTC 5666.</li>
                <li>Oferta virtual en la plataforma Moodle desde 2023.</li>
            </ul>
        </div>
        <div>
            <h3>Identificacion</h3>
            <ul>
                <li>NIT 890000381-0.</li>
                <li>Direccion: Calle 23 carrera 23, esquina, Armenia, Quindio.</li>
                <li>Telefono: 606 7368976.</li>
                <li>Correo: institutotecnico@comfenalcoquindio.co.</li>
                <li>Jornadas: diurna, nocturna y sabatina.</li>
            </ul>
        </div>
    </div>
    <p class="nota">
        Poblacion objeto: trabajadores afiliados a la Caja y su nucleo familiar
        (con prioridad en las categorias A y B), poblacion no afiliada y
        empresas afiliadas o no afiliadas.
    </p>
</section>

<section id="oferta">
    <h2>Oferta academica</h2>

    <h3>Programas tecnicos laborales vigentes</h3>
    <p>
        Todos los programas se ofrecen en jornada diurna, nocturna y sabatina.
        La certificacion se entrega como Certificado de Aptitud Ocupacional al
        aprobar el plan de estudios y el trabajo intermodular.
    </p>
    <div class="tabla-desplazable">
        <table>
            <thead>
                <tr>
                    <th>Programa</th>
                    <th>Registro / reconocimiento</th>
                    <th>Duracion</th>
                </tr>
            </thead>
            <tbody>
                <tr><td>Tecnico Laboral en Auxiliar de Recursos Humanos</td><td>Resolucion 3838 del 25 de noviembre de 2016</td><td>900 horas</td></tr>
                <tr><td>Tecnico Laboral Auxiliar Contable y Financiero</td><td>Resoluciones 63-01673 de 2020 y 0964 del 23 de junio de 2021</td><td>1.780 horas</td></tr>
                <tr><td>Conocimientos academicos en Preparatorio Musical</td><td>Resolucion 1508 del 24 de julio de 2020</td><td>576 horas</td></tr>
                <tr><td>Tecnico Laboral Liniero en Redes de Energia</td><td>Resolucion 1509 del 24 de julio de 2020</td><td>900 horas</td></tr>
                <tr><td>Tecnico Laboral en Auxiliar de Cartera y Cobranzas</td><td>Resolucion 1809 del 22 de septiembre de 2020</td><td>900 horas</td></tr>
                <tr><td>Tecnico Laboral en Secretariado Auxiliar Contable</td><td>Resoluciones 3072 de 2014 y 0968 del 23 de junio de 2021</td><td>1.780 horas</td></tr>
                <tr><td>Tecnico Laboral en Electricista Construccion Residencial</td><td>Resoluciones 3069 de 2014 y 0963 del 23 de junio de 2021</td><td>900 horas</td></tr>
                <tr><td>Tecnico Laboral en Peluqueria</td><td>Resolucion 0967 del 23 de junio de 2021</td><td>900 horas</td></tr>
                <tr><td>Tecnico Laboral en Operario de Confeccion</td><td>Resolucion 1604 del 28 de julio de 2022</td><td>900 horas</td></tr>
                <tr><td>Tecnico Laboral en Manicurista y Pedicurista</td><td>Resolucion 1685 del 11 de julio de 2023</td><td>700 horas</td></tr>
                <tr><td>Tecnico Laboral en Auxiliar de Talento Humano</td><td>Resoluciones 1685 de 2023 y 63-00797 de 2023</td><td>1.780 horas</td></tr>
            </tbody>
        </table>
    </div>

    <h3>Educacion informal y capacitacion empresarial</h3>
    <p>
        Cursos vocacionales de menos de 160 horas que entregan constancia de
        asistencia (minimo 80 por ciento) en once areas: artistica, baile,
        belleza, cocina y nutricion, confeccion, descanso, emprendimiento,
        manualidades, musica, sistemas y sostenibilidad. Tambien se brindan
        capacitaciones en las instalaciones del Instituto o de la empresa
        contratante.
    </p>
</section>

<section id="admision">
    <h2>Admision y matricula</h2>
    <ol class="pasos">
        <li>
            <h3>1. Preinscripcion</h3>
            <p>
                Presencial en las instalaciones o en linea desde este sitio.
                La recepcionista o la persona designada por rectoria programa
                la entrevista.
            </p>
        </li>
        <li>
            <h3>2. Entrevista de admision</h3>
            <p>
                Con el Coordinador de Bienestar Institucional; es el unico
                criterio de admision (evalua relaciones interpersonales,
                personalidad, motivacion, afinidad con el programa y aspiracion
                academica). Preparatorio Musical exige prueba de conocimientos
                y Liniero en Redes de Energia exige prueba y entrevista.
            </p>
        </li>
        <li>
            <h3>3. Documentacion y pago</h3>
            <p>
                La matricula se efectiviza con el pago (en vocacionales) y con
                la admision, la documentacion y el pago segun categoria de
                afiliacion (en tecnicos). Formas de pago: contado,
                credisubsidio, pagos electronicos, credito directo y
                financiacion con fondo de garantias.
            </p>
        </li>
        <li>
            <h3>4. Renovacion por periodo</h3>
            <p>
                La matricula se renueva cada periodo con paz y salvo de la
                Coordinacion Academica y de Tesoreria.
            </p>
        </li>
    </ol>
    <p class="nota">
        Evaluacion por competencias: Conocimiento 35 por ciento, Desempeno 35
        por ciento y Producto 30 por ciento, en escala de 0.0 a 5.0 (competente
        desde 3.5). El Reglamento Estudiantil regula planes de mejoramiento,
        cursos de recuperacion y cancelaciones.
    </p>
</section>

<section id="jornadas">
    <h2>Jornadas y modalidad</h2>
    <div class="tabla-desplazable">
        <table>
            <thead>
                <tr>
                    <th>Jornada</th>
                    <th>Horario</th>
                    <th>Hora academica</th>
                    <th>Intensidad</th>
                </tr>
            </thead>
            <tbody>
                <tr><td>Diurna</td><td>7:00 a.m. a 11:30 a.m. y 1:30 p.m. a 6:00 p.m.</td><td>50 minutos</td><td>25 horas semanales; 18 semanas por periodo</td></tr>
                <tr><td>Nocturna</td><td>6:00 p.m. a 10:00 p.m.</td><td>45 minutos</td><td>25 horas semanales; 18 semanas por periodo</td></tr>
                <tr><td>Sabatina</td><td>7:00 a.m. a 12:00 m. y 1:00 p.m. a 5:00 p.m.</td><td>45 minutos</td><td>11 horas por sabado; promedio de cuatro periodos (dos anios)</td></tr>
            </tbody>
        </table>
    </div>
    <p>
        Modalidad presencial con trabajo virtual: 80 por ciento presencial y
        20 por ciento virtual en sabatinos; 90 y 10 de lunes a viernes.
    </p>
</section>

<section id="contacto" class="contacto">
    <h2>Contacto</h2>
    <address>
        <p>Instituto Tecnico de Educacion Comfenalco Quindio</p>
        <p>Calle 23 carrera 23, esquina - Armenia, Quindio</p>
        <p>Telefono: 606 7368976</p>
        <p>Correo: institutotecnico@comfenalcoquindio.co</p>
    </address>
    <p><a class="boton" href="inscripcion.php">Iniciar preinscripcion</a></p>
</section>

<?php pie(); ?>
