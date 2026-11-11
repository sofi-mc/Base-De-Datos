CREATE TABLE ubicacion (
    id_ubicacion SERIAL PRIMARY KEY,
    zona VARCHAR(10) NOT NULL CHECK (zona IN ('URBANA', 'RURAL')),
    division VARCHAR(15) NOT NULL CHECK (division IN ('BARRIO', 'CORREGIMIENTO', 'VEREDA')),
    nombre VARCHAR(100) NOT NULL,
    referencia VARCHAR(200),
    UNIQUE (nombre, division),
    CHECK (
        (zona = 'URBANA' AND division = 'BARRIO')
        OR (zona = 'RURAL' AND division IN ('CORREGIMIENTO', 'VEREDA'))
    )
);

CREATE TABLE hogar (
    id_hogar SERIAL PRIMARY KEY,
    nombre_contacto VARCHAR(100) NOT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    numero_personas INTEGER NOT NULL CHECK (numero_personas > 0),
    id_ubicacion INTEGER NOT NULL REFERENCES ubicacion (id_ubicacion)
);

CREATE INDEX idx_hogar_posible_duplicado ON hogar (telefono_contacto, id_ubicacion);

CREATE TABLE condicion (
    id_condicion SERIAL PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE hogar_condicion (
    id_hogar INTEGER NOT NULL REFERENCES hogar (id_hogar),
    id_condicion INTEGER NOT NULL REFERENCES condicion (id_condicion),
    PRIMARY KEY (id_hogar, id_condicion)
);

CREATE TABLE necesidad (
    id_necesidad SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE reporte (
    id_reporte SERIAL PRIMARY KEY,
    urgencia VARCHAR(10) NOT NULL CHECK (urgencia IN ('ALTA', 'MEDIA', 'BAJA')),
    cantidad_estimada DECIMAL(10,2) CHECK (cantidad_estimada > 0),
    estado VARCHAR(15) NOT NULL DEFAULT 'PENDIENTE'
        CHECK (estado IN ('PENDIENTE', 'EN_ATENCION', 'ATENDIDO')),
    observacion VARCHAR(300),
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    id_hogar INTEGER NOT NULL REFERENCES hogar (id_hogar),
    id_necesidad INTEGER NOT NULL REFERENCES necesidad (id_necesidad)
);

CREATE UNIQUE INDEX uq_reporte_abierto ON reporte (id_hogar, id_necesidad)
WHERE estado <> 'ATENDIDO';

CREATE TABLE seguimiento (
    id_seguimiento SERIAL PRIMARY KEY,
    estado VARCHAR(15) NOT NULL
        CHECK (estado IN ('PENDIENTE', 'EN_ATENCION', 'ATENDIDO')),
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacion VARCHAR(300),
    id_reporte INTEGER NOT NULL REFERENCES reporte (id_reporte)
);

CREATE TABLE donante (
    id_donante SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo_donante VARCHAR(25) NOT NULL
        CHECK (tipo_donante IN ('PERSONA', 'ORGANIZACION_COMUNITARIA', 'EMPRESA', 'ENTIDAD_PUBLICA')),
    telefono VARCHAR(20)
);

CREATE TABLE donacion (
    id_donacion SERIAL PRIMARY KEY,
    fecha_recepcion DATE NOT NULL,
    id_donante INTEGER NOT NULL REFERENCES donante (id_donante)
);

CREATE TABLE tipo_ayuda (
    id_tipo_ayuda SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    unidad_medida VARCHAR(20) NOT NULL
);

CREATE TABLE detalle_donacion (
    id_detalle_donacion SERIAL PRIMARY KEY,
    cantidad_recibida DECIMAL(10,2) NOT NULL CHECK (cantidad_recibida > 0),
    id_donacion INTEGER NOT NULL REFERENCES donacion (id_donacion),
    id_tipo_ayuda INTEGER NOT NULL REFERENCES tipo_ayuda (id_tipo_ayuda),
    UNIQUE (id_donacion, id_tipo_ayuda)
);

CREATE TABLE punto_atencion (
    id_punto SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    direccion VARCHAR(150) NOT NULL,
    estado_habilitado BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    estado VARCHAR(10) NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

CREATE TABLE funcion (
    id_funcion SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200)
);

CREATE TABLE usuario_funcion (
    id_usuario_funcion SERIAL PRIMARY KEY,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    estado VARCHAR(10) NOT NULL DEFAULT 'ACTIVA' CHECK (estado IN ('ACTIVA', 'INACTIVA')),
    id_usuario INTEGER NOT NULL REFERENCES usuario (id_usuario),
    id_funcion INTEGER NOT NULL REFERENCES funcion (id_funcion),
    UNIQUE (id_usuario, id_funcion, fecha_inicio),
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE equipo (
    id_equipo SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE usuario_equipo (
    id_usuario INTEGER NOT NULL REFERENCES usuario (id_usuario),
    id_equipo INTEGER NOT NULL REFERENCES equipo (id_equipo),
    PRIMARY KEY (id_usuario, id_equipo)
);

CREATE TABLE jornada (
    id_jornada SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    estado VARCHAR(12) NOT NULL DEFAULT 'PROGRAMADA'
        CHECK (estado IN ('PROGRAMADA', 'EN_CURSO', 'FINALIZADA')),
    id_equipo INTEGER NOT NULL REFERENCES equipo (id_equipo),
    id_ubicacion INTEGER NOT NULL REFERENCES ubicacion (id_ubicacion),
    UNIQUE (id_equipo, fecha)
);

CREATE TABLE entrega (
    id_entrega SERIAL PRIMARY KEY,
    fecha_entrega DATE NOT NULL,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(12) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'CONFIRMADA')),
    id_hogar INTEGER NOT NULL REFERENCES hogar (id_hogar),
    id_punto INTEGER NOT NULL REFERENCES punto_atencion (id_punto),
    id_usuario INTEGER NOT NULL REFERENCES usuario (id_usuario),
    id_jornada INTEGER REFERENCES jornada (id_jornada),
    CHECK (CAST(fecha_registro AS DATE) >= fecha_entrega)
);

CREATE TABLE detalle_entrega (
    id_detalle_entrega SERIAL PRIMARY KEY,
    cantidad_entregada DECIMAL(10,2) NOT NULL CHECK (cantidad_entregada > 0),
    id_entrega INTEGER NOT NULL REFERENCES entrega (id_entrega),
    id_tipo_ayuda INTEGER NOT NULL REFERENCES tipo_ayuda (id_tipo_ayuda),
    UNIQUE (id_entrega, id_tipo_ayuda)
);

CREATE VIEW inventario AS
SELECT t.id_tipo_ayuda, t.nombre, t.unidad_medida,
    COALESCE((SELECT SUM(dd.cantidad_recibida)
              FROM detalle_donacion dd
              WHERE dd.id_tipo_ayuda = t.id_tipo_ayuda), 0)
    - COALESCE((SELECT SUM(de.cantidad_entregada)
                FROM detalle_entrega de
                JOIN entrega e ON e.id_entrega = de.id_entrega
                WHERE de.id_tipo_ayuda = t.id_tipo_ayuda AND e.estado = 'CONFIRMADA'), 0) AS disponible
FROM tipo_ayuda t;