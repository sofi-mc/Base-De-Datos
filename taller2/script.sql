CREATE DATABASE mareaAlta;
USE mareaAlta;

CREATE TABLE ubicacion (
    id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
    zona VARCHAR(10) NOT NULL CHECK (zona IN ('URBANA', 'RURAL')),
    division VARCHAR(15) NOT NULL CHECK (division IN ('BARRIO', 'CORREGIMIENTO', 'VEREDA')),
    nombre VARCHAR(100) NOT NULL,
    referencia VARCHAR(200),
    UNIQUE (nombre, division),
    CHECK (
        (zona = 'URBANA' AND division = 'BARRIO')
        OR (zona = 'RURAL' AND division IN ('CORREGIMIENTO', 'VEREDA'))
    )
) ENGINE=InnoDB;


CREATE TABLE hogar (
    id_hogar INT AUTO_INCREMENT PRIMARY KEY,
    nombre_contacto VARCHAR(100) NOT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    numero_personas INT NOT NULL CHECK (numero_personas > 0),
    id_ubicacion INT NOT NULL,
    FOREIGN KEY (id_ubicacion) REFERENCES ubicacion (id_ubicacion)
) ENGINE=InnoDB;


CREATE INDEX idx_hogar_posible_duplicado
ON hogar (telefono_contacto, id_ubicacion);


CREATE TABLE condicion (
    id_condicion INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;


CREATE TABLE hogar_condicion (
    id_hogar INT NOT NULL,
    id_condicion INT NOT NULL,
    PRIMARY KEY (id_hogar, id_condicion),
    FOREIGN KEY (id_hogar) REFERENCES hogar (id_hogar),
    FOREIGN KEY (id_condicion) REFERENCES condicion (id_condicion)
) ENGINE=InnoDB;


CREATE TABLE necesidad (
    id_necesidad INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;


CREATE TABLE reporte (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,
    urgencia VARCHAR(10) NOT NULL CHECK (urgencia IN ('ALTA', 'MEDIA', 'BAJA')),
    cantidad_estimada DECIMAL(10,2) CHECK (cantidad_estimada > 0),
    estado VARCHAR(15) NOT NULL DEFAULT 'PENDIENTE'
        CHECK (estado IN ('PENDIENTE', 'EN_ATENCION', 'ATENDIDO')),
    observacion VARCHAR(300),
    fecha DATE NOT NULL DEFAULT (CURRENT_DATE),
    id_hogar INT NOT NULL,
    id_necesidad INT NOT NULL,

    id_hogar_abierto INT AS (
        CASE WHEN estado <> 'ATENDIDO'
        THEN id_hogar ELSE NULL END
    ) PERSISTENT,

    FOREIGN KEY (id_hogar) REFERENCES hogar (id_hogar),
    FOREIGN KEY (id_necesidad) REFERENCES necesidad (id_necesidad),
    UNIQUE KEY uq_reporte_abierto (id_hogar_abierto, id_necesidad)
) ENGINE=InnoDB;


CREATE TABLE seguimiento (
    id_seguimiento INT AUTO_INCREMENT PRIMARY KEY,
    estado VARCHAR(15) NOT NULL
        CHECK (estado IN ('PENDIENTE', 'EN_ATENCION', 'ATENDIDO')),
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacion VARCHAR(300),
    id_reporte INT NOT NULL,
    FOREIGN KEY (id_reporte) REFERENCES reporte (id_reporte)
) ENGINE=InnoDB;


CREATE TABLE donante (
    id_donante INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo_donante VARCHAR(25) NOT NULL
        CHECK (tipo_donante IN ('PERSONA', 'ORGANIZACION_COMUNITARIA', 'EMPRESA', 'ENTIDAD_PUBLICA')),
    telefono VARCHAR(20)
) ENGINE=InnoDB;


CREATE TABLE donacion (
    id_donacion INT AUTO_INCREMENT PRIMARY KEY,
    fecha_recepcion DATE NOT NULL,
    id_donante INT NOT NULL,
    FOREIGN KEY (id_donante) REFERENCES donante (id_donante)
) ENGINE=InnoDB;


CREATE TABLE tipo_ayuda (
    id_tipo_ayuda INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    unidad_medida VARCHAR(20) NOT NULL
) ENGINE=InnoDB;


CREATE TABLE detalle_donacion (
    id_detalle_donacion INT AUTO_INCREMENT PRIMARY KEY,
    cantidad_recibida DECIMAL(10,2) NOT NULL CHECK (cantidad_recibida > 0),
    id_donacion INT NOT NULL,
    id_tipo_ayuda INT NOT NULL,
    FOREIGN KEY (id_donacion) REFERENCES donacion (id_donacion),
    FOREIGN KEY (id_tipo_ayuda) REFERENCES tipo_ayuda (id_tipo_ayuda),
    UNIQUE (id_donacion, id_tipo_ayuda)
) ENGINE=InnoDB;


CREATE TABLE punto_atencion (
    id_punto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    direccion VARCHAR(150) NOT NULL,
    estado_habilitado BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;


CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    estado VARCHAR(10) NOT NULL DEFAULT 'ACTIVO'
        CHECK (estado IN ('ACTIVO', 'INACTIVO'))
) ENGINE=InnoDB;


CREATE TABLE funcion (
    id_funcion INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200)
) ENGINE=InnoDB;


CREATE TABLE usuario_funcion (
    id_usuario_funcion INT AUTO_INCREMENT PRIMARY KEY,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    estado VARCHAR(10) NOT NULL DEFAULT 'ACTIVA'
        CHECK (estado IN ('ACTIVA', 'INACTIVA')),
    id_usuario INT NOT NULL,
    id_funcion INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_funcion) REFERENCES funcion (id_funcion),
    UNIQUE (id_usuario, id_funcion, fecha_inicio),
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;


CREATE TABLE equipo (
    id_equipo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;


CREATE TABLE usuario_equipo (
    id_usuario INT NOT NULL,
    id_equipo INT NOT NULL,
    PRIMARY KEY (id_usuario, id_equipo),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_equipo) REFERENCES equipo (id_equipo)
) ENGINE=InnoDB;


CREATE TABLE jornada (
    id_jornada INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL,
    estado VARCHAR(12) NOT NULL DEFAULT 'PROGRAMADA'
        CHECK (estado IN ('PROGRAMADA', 'EN_CURSO', 'FINALIZADA')),
    id_equipo INT NOT NULL,
    id_ubicacion INT NOT NULL,
    FOREIGN KEY (id_equipo) REFERENCES equipo (id_equipo),
    FOREIGN KEY (id_ubicacion) REFERENCES ubicacion (id_ubicacion),
    UNIQUE (id_equipo, fecha)
) ENGINE=InnoDB;


CREATE TABLE entrega (
    id_entrega INT AUTO_INCREMENT PRIMARY KEY,
    fecha_entrega DATE NOT NULL,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(12) NOT NULL DEFAULT 'PENDIENTE'
        CHECK (estado IN ('PENDIENTE', 'CONFIRMADA')),
    id_hogar INT NOT NULL,
    id_punto INT NOT NULL,
    id_usuario INT NOT NULL,
    id_jornada INT,
    FOREIGN KEY (id_hogar) REFERENCES hogar (id_hogar),
    FOREIGN KEY (id_punto) REFERENCES punto_atencion (id_punto),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_jornada) REFERENCES jornada (id_jornada),
    CHECK (DATE(fecha_registro) >= fecha_entrega)
) ENGINE=InnoDB;


CREATE TABLE detalle_entrega (
    id_detalle_entrega INT AUTO_INCREMENT PRIMARY KEY,
    cantidad_entregada DECIMAL(10,2) NOT NULL CHECK (cantidad_entregada > 0),
    id_entrega INT NOT NULL,
    id_tipo_ayuda INT NOT NULL,
    FOREIGN KEY (id_entrega) REFERENCES entrega (id_entrega),
    FOREIGN KEY (id_tipo_ayuda) REFERENCES tipo_ayuda (id_tipo_ayuda),
    UNIQUE (id_entrega, id_tipo_ayuda)
) ENGINE=InnoDB;


