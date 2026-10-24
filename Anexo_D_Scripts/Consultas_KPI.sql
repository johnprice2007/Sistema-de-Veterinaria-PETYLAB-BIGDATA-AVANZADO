USE PetYLab_BI;
GO
-- KPI generales
SELECT COUNT(*) AS TotalCitas,
 SUM(CASE WHEN e.estado='ATENDIDA' THEN 1 ELSE 0 END) AS AtencionesRealizadas,
 SUM(CASE WHEN e.estado='PENDIENTE' THEN 1 ELSE 0 END) AS CitasPendientes,
 SUM(CASE WHEN e.estado='CANCELADA' THEN 1 ELSE 0 END) AS CitasCanceladas,
 SUM(CASE WHEN e.estado='EN ESPERA' THEN 1 ELSE 0 END) AS CitasEnEspera,
 CAST(100.0*SUM(CASE WHEN e.estado='ATENDIDA' THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(10,2)) AS PorcentajeAtencion,
 CAST(100.0*SUM(CASE WHEN e.estado='CANCELADA' THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(10,2)) AS PorcentajeCancelacion
FROM fac_atencion a JOIN dim_estadoCita e ON e.id_estado=a.id_estado;

-- Demanda por periodo y servicio
SELECT t.periodo,s.nomServicio,COUNT(*) AS TotalCitas
FROM fac_atencion a JOIN dim_tiempo t ON t.fecha=a.fecha
JOIN dim_servicio s ON s.id_servicio=a.id_servicio
GROUP BY t.periodo,s.nomServicio ORDER BY t.periodo,s.nomServicio;

-- Duracion media por servicio (solo citas atendidas, duracion mismo dia)
SELECT s.nomServicio,CAST(AVG(CAST(DATEDIFF(MINUTE,a.hora_inicio,a.hora_fin) AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS MinutosPromedio
FROM fac_atencion a JOIN dim_servicio s ON s.id_servicio=a.id_servicio
JOIN dim_estadoCita e ON e.id_estado=a.id_estado
WHERE e.estado='ATENDIDA' AND a.hora_inicio IS NOT NULL AND a.hora_fin>=a.hora_inicio
GROUP BY s.nomServicio ORDER BY s.nomServicio;

-- Utilizacion estimada, hechos agregados por separado
WITH Disponible AS (SELECT SUM(minutos_disponibles) AS MinutosDisponibles FROM fac_capacidad),
Atendido AS (SELECT SUM(DATEDIFF(MINUTE,a.hora_inicio,a.hora_fin)) AS MinutosAtendidos
FROM fac_atencion a JOIN dim_estadoCita e ON e.id_estado=a.id_estado
WHERE e.estado='ATENDIDA' AND a.hora_inicio IS NOT NULL AND a.hora_fin>=a.hora_inicio)
SELECT d.MinutosDisponibles, a.MinutosAtendidos,
CAST(100.0*a.MinutosAtendidos/NULLIF(d.MinutosDisponibles,0) AS DECIMAL(10,2)) AS UtilizacionPorcentaje
FROM Disponible d CROSS JOIN Atendido a;
