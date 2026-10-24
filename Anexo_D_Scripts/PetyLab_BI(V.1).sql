CREATE DATABASE PetYLab_BI;
GO

USE PetYLab_BI;
GO

CREATE TABLE dim_tiempo (
    fecha DATE NOT NULL,
    dia TINYINT,
    mes TINYINT,
    periodo CHAR(7),
    trimestre CHAR(2),
    año SMALLINT,
    nomDia VARCHAR(15),
    nomMes VARCHAR(15),

    CONSTRAINT PK_dim_tiempo
        PRIMARY KEY (fecha)
);
GO

CREATE TABLE dim_servicio (
    id_servicio INT NOT NULL,
    nomServicio VARCHAR(100) NOT NULL,
    descripcion VARCHAR(500),
    costo DECIMAL(10,2),

    CONSTRAINT PK_dim_servicio
        PRIMARY KEY (id_servicio)
);
GO

CREATE TABLE dim_mascota (
    id_mascota INT NOT NULL,
    nomMascota VARCHAR(100) NOT NULL,
    especie VARCHAR(50),
    raza VARCHAR(100),
    dniDueño CHAR(8),
    nomDueño VARCHAR(150),

    CONSTRAINT PK_dim_mascota
        PRIMARY KEY (id_mascota)
);
GO

CREATE TABLE dim_empleado (
    id_empleado INT NOT NULL,
    dni CHAR(8),
    nombre VARCHAR(100) NOT NULL,
    especialidad VARCHAR(100),

    CONSTRAINT PK_dim_empleado
        PRIMARY KEY (id_empleado)
);
GO

CREATE TABLE dim_estadoCita (
    id_estado INT NOT NULL,
    estado VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200),

    CONSTRAINT PK_dim_estadoCita
        PRIMARY KEY (id_estado)
);
GO

CREATE TABLE fac_atencion (
    id_atencion INT NOT NULL,

    id_empleado INT NOT NULL,
    id_servicio INT NOT NULL,
    id_estado INT NOT NULL,
    id_mascota INT NOT NULL,
    fecha DATE NOT NULL,

    descripcion_atencion VARCHAR(500),
    hora_inicio TIME(0),
    hora_fin TIME(0),
    costo DECIMAL(10,2),

    CONSTRAINT PK_fac_atencion
        PRIMARY KEY (id_atencion),

    CONSTRAINT FK_fac_atencion_tiempo
        FOREIGN KEY (fecha)
        REFERENCES dim_tiempo(fecha),

    CONSTRAINT FK_fac_atencion_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES dim_empleado(id_empleado),

    CONSTRAINT FK_fac_atencion_servicio
        FOREIGN KEY (id_servicio)
        REFERENCES dim_servicio(id_servicio),

    CONSTRAINT FK_fac_atencion_estado
        FOREIGN KEY (id_estado)
        REFERENCES dim_estadoCita(id_estado),

    CONSTRAINT FK_fac_atencion_mascota
        FOREIGN KEY (id_mascota)
        REFERENCES dim_mascota(id_mascota)
);
GO

CREATE TABLE fac_capacidad (
    id_capacidad INT NOT NULL,

    id_empleado INT NOT NULL,
    fecha DATE NOT NULL,

    hora_entrada TIME(0),
    hora_salida TIME(0),
    minutos_refrigerio SMALLINT,
    minutos_disponibles SMALLINT,
    capacidad_atenciones_estimada INT,

    CONSTRAINT PK_fac_capacidad
        PRIMARY KEY (id_capacidad),

    CONSTRAINT UQ_fac_capacidad_empleado_fecha
        UNIQUE (id_empleado, fecha),

    CONSTRAINT FK_fac_capacidad_tiempo
        FOREIGN KEY (fecha)
        REFERENCES dim_tiempo(fecha),

    CONSTRAINT FK_fac_capacidad_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES dim_empleado(id_empleado)
);
GO