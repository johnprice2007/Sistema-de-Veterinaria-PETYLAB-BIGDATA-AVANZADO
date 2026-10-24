USE PetYLab_BI;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cargar_PetyLab_BI
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1 FROM [STG_REGISTRO$]
            WHERE ID_ATENCION IS NULL OR ID_MASCOTA IS NULL
               OR ID_VETERINARIO IS NULL OR ID_SERVICIO IS NULL
               OR ID_ESTADO IS NULL OR FECHA IS NULL
        )
            RAISERROR('Hay datos obligatorios vacios en REGISTRO.', 16, 1);

        IF EXISTS (
            SELECT ID_ATENCION FROM [STG_REGISTRO$]
            GROUP BY ID_ATENCION HAVING COUNT(*) > 1
        )
            RAISERROR('Hay IDs de atencion repetidos.', 16, 1);

        IF EXISTS (
            SELECT 1 FROM [STG_REGISTRO$] r
            LEFT JOIN [STG_SERVICIO$] s ON r.ID_SERVICIO = s.ID_SERVICIO
            LEFT JOIN [STG_ESTADO$] ec ON r.ID_ESTADO = ec.ID_ESTADO
            LEFT JOIN [STG_CAPACIDAD$] c ON r.ID_VETERINARIO = c.ID_VETERINARIO
            WHERE s.ID_SERVICIO IS NULL OR ec.ID_ESTADO IS NULL
               OR c.ID_VETERINARIO IS NULL
        )
            RAISERROR('Hay servicios, estados o empleados sin correspondencia.', 16, 1);

        IF EXISTS (
            SELECT 1 FROM [STG_REGISTRO$] r
            JOIN [STG_SERVICIO$] s ON r.ID_SERVICIO = s.ID_SERVICIO
            WHERE r.COSTO IS NULL OR s.COSTO IS NULL OR r.COSTO <> s.COSTO
        )
            RAISERROR('Los costos de REGISTRO no coinciden con SERVICIO.', 16, 1);

        DELETE FROM fac_atencion;
        DELETE FROM fac_capacidad;
        DELETE FROM dim_mascota;
        DELETE FROM dim_servicio;
        DELETE FROM dim_estadoCita;
        DELETE FROM dim_empleado;
        DELETE FROM dim_tiempo;

        INSERT INTO dim_tiempo (
            fecha, dia, mes, periodo, trimestre, año, nomDia, nomMes
        )
        SELECT
            CAST(FECHA AS DATE), DAY(FECHA), MONTH(FECHA),
            CONVERT(CHAR(7), CAST(FECHA AS DATE), 120),
            'T' + CONVERT(CHAR(1), DATEPART(QUARTER, FECHA)),
            YEAR(FECHA), MAX(NOMBRE_DIA), MAX(NOMBRE_MES)
        FROM [STG_REGISTRO$]
        GROUP BY CAST(FECHA AS DATE), DAY(FECHA), MONTH(FECHA),
                 DATEPART(QUARTER, FECHA), YEAR(FECHA);


        INSERT INTO dim_servicio (
            id_servicio, nomServicio, descripcion, costo
        )
        SELECT ID_SERVICIO, SERVICIO, DESCRIPCION_SERVICIO, COSTO
        FROM [STG_SERVICIO$];


        INSERT INTO dim_estadoCita (
            id_estado, estado, descripcion
        )
        SELECT ID_ESTADO, ESTADO_CITA, DESCRIPCION
        FROM [STG_ESTADO$];


        INSERT INTO dim_empleado (
            id_empleado, dni, nombre, especialidad
        )
        SELECT
            ID_VETERINARIO,
            RIGHT('00000000' + CONVERT(VARCHAR(20), DNI_VETERINARIO), 8),
            NOMBRE_VETERINARIO, ESPECIALIDAD
        FROM [STG_CAPACIDAD$];


        INSERT INTO dim_mascota (
            id_mascota, nomMascota, especie, raza, dniDueño, nomDueño
        )
        SELECT
            ID_MASCOTA, MAX(NOMBRE_MASCOTA), MAX(ESPECIE), MAX(RAZA),
            MAX(RIGHT('00000000' + CONVERT(VARCHAR(20), DNI_DUENO), 8)),
            MAX(LTRIM(RTRIM(CONCAT(
                COALESCE(NOMBRE_DUENO, ''), ' ',
                COALESCE(APELLIDO_PATERNO_DUENO, ''), ' ',
                COALESCE(APELLIDO_MATERNO_DUENO, '')
            ))))
        FROM [STG_REGISTRO$]
        GROUP BY ID_MASCOTA;

        INSERT INTO fac_atencion (
            id_atencion, id_mascota, id_empleado, id_servicio, id_estado,
            fecha, descripcion_atencion, hora_inicio, hora_fin, costo
        )
        SELECT
            r.ID_ATENCION, m.id_mascota, e.id_empleado, s.id_servicio,
            ec.id_estado, t.fecha, r.DESCRIPCION_ATENCION,
            CAST(r.HORA_INICIO AS TIME(0)), CAST(r.HORA_FIN AS TIME(0)),
            r.COSTO
        FROM [STG_REGISTRO$] r
        INNER JOIN dim_tiempo t ON t.fecha = CAST(r.FECHA AS DATE)
        INNER JOIN dim_mascota m ON m.id_mascota = r.ID_MASCOTA
        INNER JOIN dim_empleado e ON e.id_empleado = r.ID_VETERINARIO
        INNER JOIN dim_servicio s ON s.id_servicio = r.ID_SERVICIO
        INNER JOIN dim_estadoCita ec ON ec.id_estado = r.ID_ESTADO;


        INSERT INTO fac_capacidad (
            id_capacidad, id_empleado, fecha, hora_entrada, hora_salida,
            minutos_refrigerio, minutos_disponibles,
            capacidad_atenciones_estimada
        )
        SELECT
            ROW_NUMBER() OVER (ORDER BY t.fecha, e.id_empleado),
            e.id_empleado, t.fecha,
            CAST(c.HORA_ENTRADA AS TIME(0)),
            CAST(c.HORA_SALIDA AS TIME(0)),
            c.MINUTOS_REFRIGERIO, c.MINUTOS_DISPONIBLES,
            c.CAPACIDAD_ATENCIONES
        FROM dim_tiempo t
        CROSS JOIN dim_empleado e
        INNER JOIN [STG_CAPACIDAD$] c ON c.ID_VETERINARIO = e.id_empleado;

        IF (SELECT COUNT(*) FROM fac_atencion) <>
           (SELECT COUNT(*) FROM [STG_REGISTRO$])
            RAISERROR('No se cargaron todas las citas.', 16, 1);


        COMMIT TRANSACTION;

        PRINT 'ETL de PETYLAB completado correctamente.';

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @MensajeError NVARCHAR(4000);
        SET @MensajeError = ERROR_MESSAGE();

        RAISERROR('%s', 16, 1, @MensajeError);

    END CATCH;
END;
GO

EXEC dbo.sp_Cargar_PetyLab_BI;

SELECT 'dim_tiempo' AS tabla, COUNT(*) AS registros FROM dim_tiempo
UNION ALL SELECT 'dim_mascota', COUNT(*) FROM dim_mascota
UNION ALL SELECT 'dim_empleado', COUNT(*) FROM dim_empleado
UNION ALL SELECT 'dim_servicio', COUNT(*) FROM dim_servicio
UNION ALL SELECT 'dim_estadoCita', COUNT(*) FROM dim_estadoCita
UNION ALL SELECT 'fac_atencion', COUNT(*) FROM fac_atencion
UNION ALL SELECT 'fac_capacidad', COUNT(*) FROM fac_capacidad;