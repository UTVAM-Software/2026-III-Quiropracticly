
-- =====================================================
-- QUIROPRACTICLY
-- Base de datos para gestión quiropráctica
-- MySQL 8.0+
-- =====================================================

CREATE DATABASE IF NOT EXISTS quiropracticly
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE quiropracticly;

-- =====================================================
-- 1. USUARIOS
-- =====================================================

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellidos VARCHAR(150) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =====================================================
-- 2. ROLES
-- =====================================================

CREATE TABLE IF NOT EXISTS roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =====================================================
-- 3. PERMISOS
-- =====================================================

CREATE TABLE IF NOT EXISTS permisos (
    id_permiso INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    clave VARCHAR(120) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;

-- =====================================================
-- 4. RELACIÓN USUARIOS - ROLES
-- =====================================================

CREATE TABLE IF NOT EXISTS usuario_roles (
    id_usuario INT NOT NULL,
    id_rol INT NOT NULL,

    PRIMARY KEY (id_usuario, id_rol),

    FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON DELETE CASCADE,

    FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- 5. RELACIÓN ROLES - PERMISOS
-- =====================================================

CREATE TABLE IF NOT EXISTS rol_permisos (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,

    PRIMARY KEY (id_rol, id_permiso),

    FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol)
        ON DELETE CASCADE,

    FOREIGN KEY (id_permiso)
        REFERENCES permisos(id_permiso)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- 6. PERMISOS INDIVIDUALES DE USUARIOS
-- permitido = 1: concede permiso
-- permitido = 0: revoca permiso
-- =====================================================

CREATE TABLE IF NOT EXISTS usuario_permisos (
    id_usuario INT NOT NULL,
    id_permiso INT NOT NULL,
    permitido BOOLEAN NOT NULL,

    PRIMARY KEY (id_usuario, id_permiso),

    FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON DELETE CASCADE,

    FOREIGN KEY (id_permiso)
        REFERENCES permisos(id_permiso)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- 7. PACIENTES
-- =====================================================

CREATE TABLE IF NOT EXISTS pacientes (
    id_paciente INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellidos VARCHAR(150) NOT NULL,
    fecha_nacimiento DATE,
    telefono VARCHAR(20),
    correo VARCHAR(150),
    direccion VARCHAR(255),
    contacto_emergencia VARCHAR(150),
    telefono_emergencia VARCHAR(20),
    fotografia VARCHAR(255),
    notas TEXT,
    estado ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo',

    creado_por INT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (creado_por)
        REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- 8. CITAS
-- =====================================================

CREATE TABLE IF NOT EXISTS citas (
    id_cita INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(20) NOT NULL UNIQUE,

    id_paciente INT NOT NULL,
    id_profesional INT,

    fecha_hora DATETIME NOT NULL,
    duracion_minutos INT NOT NULL DEFAULT 30,
    motivo VARCHAR(255),

    estado ENUM(
        'Pendiente',
        'Confirmada',
        'Completada',
        'Cancelada',
        'No asistió'
    ) NOT NULL DEFAULT 'Pendiente',

    notas TEXT,

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (id_paciente)
        REFERENCES pacientes(id_paciente)
        ON DELETE RESTRICT,

    FOREIGN KEY (id_profesional)
        REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL,

    CHECK (duracion_minutos > 0)
) ENGINE=InnoDB;

-- =====================================================
-- 9. CASOS CLÍNICOS
-- =====================================================

CREATE TABLE IF NOT EXISTS casos_clinicos (
    id_caso INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(20) NOT NULL UNIQUE,

    id_paciente INT NOT NULL,
    creado_por INT,

    nombre VARCHAR(150) NOT NULL,
    motivo_consulta TEXT NOT NULL,
    area VARCHAR(100),
    diagnostico TEXT,
    antecedentes TEXT,
    datos_adicionales TEXT,

    fecha_registro DATE NOT NULL,

    estado ENUM(
        'Abierto',
        'En seguimiento',
        'Cerrado'
    ) NOT NULL DEFAULT 'Abierto',

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (id_paciente)
        REFERENCES pacientes(id_paciente)
        ON DELETE RESTRICT,

    FOREIGN KEY (creado_por)
        REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- 10. TRATAMIENTOS
-- =====================================================

CREATE TABLE IF NOT EXISTS tratamientos (
    id_tratamiento INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(20) NOT NULL UNIQUE,

    id_paciente INT NOT NULL,
    id_caso INT,

    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,

    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,

    sesiones_totales INT DEFAULT 1,
    sesiones_completadas INT NOT NULL DEFAULT 0,

    costo DECIMAL(10,2) DEFAULT 0.00,

    estado ENUM(
        'Activo',
        'Completado',
        'Suspendido'
    ) NOT NULL DEFAULT 'Activo',

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (id_paciente)
        REFERENCES pacientes(id_paciente)
        ON DELETE RESTRICT,

    FOREIGN KEY (id_caso)
        REFERENCES casos_clinicos(id_caso)
        ON DELETE SET NULL,

    CHECK (sesiones_totales > 0),
    CHECK (sesiones_completadas >= 0),
    CHECK (sesiones_completadas <= sesiones_totales),
    CHECK (costo >= 0)
) ENGINE=InnoDB;

-- =====================================================
-- DATOS INICIALES: ROLES
-- =====================================================

INSERT IGNORE INTO roles (nombre, descripcion) VALUES
('Administrador', 'Acceso completo al sistema'),
('Profesional', 'Gestión de pacientes y atención clínica'),
('Recepcionista', 'Gestión de pacientes y citas');

-- =====================================================
-- DATOS INICIALES: PERMISOS
-- =====================================================

INSERT IGNORE INTO permisos (nombre, clave, descripcion) VALUES

-- Pacientes
('Consultar pacientes', 'pacientes.leer', 'Ver pacientes'),
('Crear pacientes', 'pacientes.crear', 'Registrar pacientes'),
('Editar pacientes', 'pacientes.editar', 'Modificar pacientes'),
('Eliminar pacientes', 'pacientes.eliminar', 'Eliminar pacientes'),

-- Citas
('Consultar citas', 'citas.leer', 'Ver citas'),
('Crear citas', 'citas.crear', 'Agendar citas'),
('Editar citas', 'citas.editar', 'Modificar citas'),
('Eliminar citas', 'citas.eliminar', 'Eliminar citas'),

-- Casos clínicos
('Consultar casos clínicos', 'casos.leer', 'Ver casos clínicos'),
('Crear casos clínicos', 'casos.crear', 'Registrar casos clínicos'),
('Editar casos clínicos', 'casos.editar', 'Modificar casos clínicos'),
('Eliminar casos clínicos', 'casos.eliminar', 'Eliminar casos clínicos'),

-- Tratamientos
('Consultar tratamientos', 'tratamientos.leer', 'Ver tratamientos'),
('Crear tratamientos', 'tratamientos.crear', 'Registrar tratamientos'),
('Editar tratamientos', 'tratamientos.editar', 'Modificar tratamientos'),
('Eliminar tratamientos', 'tratamientos.eliminar', 'Eliminar tratamientos'),

-- Usuarios
('Consultar usuarios', 'usuarios.leer', 'Ver usuarios'),
('Crear usuarios', 'usuarios.crear', 'Registrar usuarios'),
('Editar usuarios', 'usuarios.editar', 'Modificar usuarios'),
('Eliminar usuarios', 'usuarios.eliminar', 'Eliminar usuarios'),

-- Roles
('Consultar roles', 'roles.leer', 'Ver roles'),
('Crear roles', 'roles.crear', 'Registrar roles'),
('Editar roles', 'roles.editar', 'Modificar roles'),
('Eliminar roles', 'roles.eliminar', 'Eliminar roles'),

-- Permisos
('Consultar permisos', 'permisos.leer', 'Ver permisos'),
('Crear permisos', 'permisos.crear', 'Registrar permisos'),
('Asignar permisos', 'permisos.asignar', 'Asignar o revocar permisos');

-- =====================================================
-- ASIGNAR TODOS LOS PERMISOS AL ADMINISTRADOR
-- =====================================================

INSERT IGNORE INTO rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r
CROSS JOIN permisos p
WHERE r.nombre = 'Administrador';

-- =====================================================
-- PERMISOS DEL PROFESIONAL
-- =====================================================

INSERT IGNORE INTO rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r
CROSS JOIN permisos p
WHERE r.nombre = 'Profesional'
AND p.clave IN (
    'pacientes.leer',
    'pacientes.crear',
    'pacientes.editar',
    'citas.leer',
    'citas.crear',
    'citas.editar',
    'casos.leer',
    'casos.crear',
    'casos.editar',
    'tratamientos.leer',
    'tratamientos.crear',
    'tratamientos.editar'
);

-- =====================================================
-- PERMISOS DE RECEPCIÓN
-- =====================================================

INSERT IGNORE INTO rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r
CROSS JOIN permisos p
WHERE r.nombre = 'Recepcionista'
AND p.clave IN (
    'pacientes.leer',
    'pacientes.crear',
    'pacientes.editar',
    'citas.leer',
    'citas.crear',
    'citas.editar',
    'citas.eliminar'
);

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================
