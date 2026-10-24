USE PetYLab_BI;
GO

SET STATISTICS TIME ON;
SELECT t.periodo, s.nomServicio, COUNT(a.id_atencion) AS TotalCitas
FROM fac_atencion a
JOIN dim_tiempo t ON t.fecha=a.fecha
JOIN dim_servicio s ON s.id_servicio=a.id_servicio
GROUP BY t.periodo,s.nomServicio ORDER BY t.periodo,s.nomServicio;
SET STATISTICS TIME OFF;
