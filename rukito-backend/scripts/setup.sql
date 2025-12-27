-- Script de creación de base de datos y tablas para Rukito

-- Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS rukito;
USE rukito;

-- 1. Tabla de Cámaras Frigoríficas
CREATE TABLE IF NOT EXISTS chambers (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    content VARCHAR(255),
    target_temperature DECIMAL(5,2) NOT NULL,
    critical_threshold DECIMAL(5,2) NOT NULL,
    warning_threshold DECIMAL(5,2) NOT NULL,
    location VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Tabla de Lecturas de Temperatura
CREATE TABLE IF NOT EXISTS temperature_readings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sensor_id VARCHAR(50),
    temperature DECIMAL(5,2) NOT NULL,
    rate_of_change DECIMAL(5,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'NORMAL',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES chambers(id)
);

-- 3. Tabla de Alertas
CREATE TABLE IF NOT EXISTS alerts (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority INT NOT NULL, -- 0=P1, 1=P2, 2=P3
    type INT NOT NULL,     -- Enum de tipos
    sensor_id VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    estimated_cost DECIMAL(10,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES chambers(id)
);

-- 4. Tabla de Configuración de Alertas
CREATE TABLE IF NOT EXISTS alert_configs (
    id VARCHAR(50) PRIMARY KEY,
    sensor_id VARCHAR(50) UNIQUE,
    max_temperature DECIMAL(5,2) NOT NULL,
    min_temperature DECIMAL(5,2) NOT NULL,
    rate_of_change_threshold DECIMAL(5,2) NOT NULL,
    priority INT NOT NULL, -- 0=low, 1=med, 2=high
    is_enabled BOOLEAN DEFAULT TRUE,
    notification_channels JSON, -- Almacena ['sms', 'push', etc]
    recipients JSON,            -- Almacena ['+593...', etc]
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES chambers(id)
);

-- Datos Iniciales de Prueba (Seed Data)
INSERT INTO chambers (id, name, content, target_temperature, critical_threshold, warning_threshold, location)
VALUES 
('CF-1', 'Cámara Frigorífica 1 (CF-1)', 'Carnes Prime', -20.00, -18.00, -17.00, 'Sala Principal'),
('CF-2', 'Cámara Frigorífica 2 (CF-2)', 'Lácteos y Moros', 4.00, 8.00, 6.00, 'Sala Principal'),
('REF-3', 'Refrigerador 3 (REF-3)', 'Vegetales', 2.00, 5.00, 3.00, 'Sala Principal');

INSERT INTO alert_configs (id, sensor_id, max_temperature, min_temperature, rate_of_change_threshold, priority, is_enabled, notification_channels, recipients)
VALUES 
('CONFIG-CF-1', 'CF-1', 5.00, -25.00, 0.50, 2, TRUE, '["sms", "push"]', '["+593999123456"]'),
('CONFIG-CF-2', 'CF-2', 10.00, 0.00, 1.00, 1, TRUE, '["push"]', '["+593999000000"]');
