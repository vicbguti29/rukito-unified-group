-- Script de configuración de base de datos Rukito - Versión 2.0 (Granular)
-- PRECAUCIÓN: Este script sobrescribe la estructura anterior.

CREATE DATABASE IF NOT EXISTS rukito;
USE rukito;

DROP TABLE IF EXISTS alert_configs; -- Depende de chambers
DROP TABLE IF EXISTS temperature_readings; -- Depende de chambers
DROP TABLE IF EXISTS alerts; -- Depende de chambers y de users
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS chambers;

-- 1. Tabla de Usuarios (Contactos y Gestión)

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    role ENUM('admin', 'manager', 'staff', 'technician') NOT NULL DEFAULT 'staff',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Tabla de Cámaras (Información Física)

CREATE TABLE chambers (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    content_description VARCHAR(255),
    location VARCHAR(255),
    model VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Tabla de Configuración de Alertas (Lógica de Negocio)
CREATE TABLE alert_configs (
    id VARCHAR(50) PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Umbrales Granulares
    threshold_critical_cold DECIMAL(5,2) NOT NULL, -- Ej: -30.00
    threshold_target DECIMAL(5,2) NOT NULL,        -- Ej: -20.00
    threshold_warning_hot DECIMAL(5,2) NOT NULL,   -- Ej: -15.00
    threshold_critical_hot DECIMAL(5,2) NOT NULL,  -- Ej: -10.00
    
    rate_of_change_threshold DECIMAL(5,2) DEFAULT 1.0,
    
    -- Notificaciones (JSON para flexibilidad de canales y roles)
    actions_warning_hot JSON,  
    actions_critical_hot JSON, 
    actions_critical_cold JSON,
    
    is_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (sensor_id) REFERENCES chambers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Tabla de Lecturas de Temperatura
CREATE TABLE temperature_readings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    temperature DECIMAL(5,2) NOT NULL,
    rate_of_change DECIMAL(5,2) DEFAULT 0.00,
    
    -- Estados alineados con la configuración
    status ENUM('NORMAL', 'WARNING_HOT', 'CRITICAL_HOT', 'CRITICAL_COLD') NOT NULL DEFAULT 'NORMAL',
    
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_reading_sensor_time (sensor_id, timestamp),
    FOREIGN KEY (sensor_id) REFERENCES chambers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Tabla de Historial de Alertas
CREATE TABLE alerts (
    id VARCHAR(50) PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    severity ENUM('WARNING', 'CRITICAL') NOT NULL,
    category ENUM('HOT_TEMP', 'COLD_TEMP', 'RAPID_CHANGE', 'SENSOR_OFFLINE') NOT NULL,
    
    is_read BOOLEAN DEFAULT FALSE,
    acknowledged_by INT,
    resolved_at TIMESTAMP NULL,
    
    estimated_cost DECIMAL(10,2) DEFAULT 0.00,
    channels JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_alert_sensor (sensor_id),
    INDEX idx_alert_severity (severity),
    FOREIGN KEY (sensor_id) REFERENCES chambers(id) ON DELETE CASCADE,
    FOREIGN KEY (acknowledged_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --- DATOS INICIALES ---

INSERT INTO users (full_name, email, phone_number, role) 
VALUES ('Don Jorge Admin', 'jorge@rukito.com', '+593999999999', 'admin');

INSERT INTO chambers (id, name, content_description, location, model)
VALUES 
('CF-1', 'Cámara Carnes Prime', 'Lomo Fino y Cortes Especiales', 'Zona A - Principal', 'ColdMaster 3000'),
('CF-2', 'Cámara Lácteos', 'Yogur y Quesos', 'Zona B - Despacho', 'RefriGen v2'),
('REF-3', 'Refrigerador Verduras', 'Vegetales Frescos', 'Zona C - Cocina', 'Samsung Industrial');

INSERT INTO alert_configs (id, sensor_id, threshold_critical_cold, threshold_target, threshold_warning_hot, threshold_critical_hot, actions_warning_hot, actions_critical_hot, actions_critical_cold)
VALUES 
('CONF-CF-1', 'CF-1', -30.00, -20.00, -15.00, -10.00, 
 '{"channels": ["push"], "target_roles": ["staff"]}', 
 '{"channels": ["push", "email", "sms"], "target_roles": ["manager", "admin"]}', 
 '{"channels": ["email"], "target_roles": ["technician"]}'),
('CONF-CF-2', 'CF-2', -5.00, 4.00, 7.00, 10.00, 
 '{"channels": ["push"], "target_roles": ["staff"]}', 
 '{"channels": ["push", "email"], "target_roles": ["manager"]}', 
 '{"channels": ["email"], "target_roles": ["staff"]}');