USE PetYLab_BI;
GO
-- Solo ejecutar despues de importar el Excel
SELECT 'Origen STG' AS Origen, COUNT(*) AS Total FROM [STG_REGISTRO$]
UNION ALL SELECT 'Destino BI', COUNT(*) FROM fac_atencion;

SELECT ID_ATENCION, COUNT(*) AS Veces FROM [STG_REGISTRO$]
GROUP BY ID_ATENCION HAVING COUNT(*)>1;
SELECT id_atencion, COUNT(*) AS Veces FROM fac_atencion
GROUP BY id_atencion HAVING COUNT(*)>1;

SELECT id_atencion FROM fac_atencion
EXCEPT SELECT ID_ATENCION FROM [STG_REGISTRO$];
SELECT ID_ATENCION FROM [STG_REGISTRO$]
EXCEPT SELECT id_atencion FROM fac_atencion;

SELECT 'dim_tiempo' AS Tabla, COUNT(*) AS Filas FROM dim_tiempo
UNION ALL SELECT 'dim_mascota',COUNT(*) FROM dim_mascota
UNION ALL SELECT 'dim_empleado',COUNT(*) FROM dim_empleado
UNION ALL SELECT 'dim_servicio',COUNT(*) FROM dim_servicio
UNION ALL SELECT 'dim_estadoCita',COUNT(*) FROM dim_estadoCita
UNION ALL SELECT 'fac_atencion',COUNT(*) FROM fac_atencion
UNION ALL SELECT 'fac_capacidad',COUNT(*) FROM fac_capacidad;

SELECT (SELECT COUNT(*) FROM dim_tiempo) AS Fechas,
       (SELECT COUNT(*) FROM dim_empleado) AS Empleados,
       (SELECT COUNT(*) FROM fac_capacidad) AS RegistrosCapacidad;
