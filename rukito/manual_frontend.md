# Manual Técnico del Frontend - Rukito

**Versión:** 2.0 (Refactor Granular)
**Tecnología:** Flutter (Dart)
**Arquitectura:** Provider + MVVM Simplificado

Este documento detalla la estructura, funcionalidad y contratos de API de cada pantalla de la aplicación Rukito.

---

## 1. Dashboard (Vista Principal)

El centro de mando que ofrece una visión panorámica del estado de todas las cámaras frigoríficas.

### 🎯 Funcionalidad
*   **Tarjetas de Estado en Tiempo Real:** Muestra la temperatura actual, tasa de cambio y estado operativo (Normal, Advertencia, Crítico Calor, Crítico Frío).
*   **Código de Colores Semántico:** 
    *   🟢 Verde: Operación Normal
    *   🟠 Naranja: Advertencia (Precaución)
    *   🔴 Rojo: Crítico (Peligro Calor/Frío)
    *   ⚪ Gris: Desconectado
*   **Acceso Rápido:** Botón directo a la configuración de cada cámara.

### 🔗 Integración API

**Endpoint:** `GET /chambers`

**Respuesta JSON Esperada:**
```json
[
  {
    "id": "CF-1",
    "name": "Cámara Carnes Prime",
    "content": "Lomo Fino",
    "location": "Zona A",
    "current_temperature": -16.5,
    "target_temperature": -18.0,
    "rate_of_change": 0.5,
    "status": "WARNING_HOT", // ENUM: NORMAL, WARNING_HOT, CRITICAL_HOT, CRITICAL_COLD, OFFLINE
    "last_update": "2024-12-11T22:15:00Z",
    "recent_temperatures": [-16.0, -16.2, -16.5, -16.4], // Lista de floats para sparklines
    "is_active": true
  }
]
```

---

## 2. Reportes y Análisis

Herramienta de inteligencia de negocios para evaluar el desempeño térmico y económico.

### 🎯 Funcionalidad
*   **KPIs Financieros:** Costo estimado de pérdidas y horas fuera de rango.
*   **Gráfico de Tendencia:** Visualización histórica con **4 líneas de referencia** (Objetivo, Advertencia, Crítico Calor, Crítico Frío).
*   **Diagnóstico Automático:** Gráfico de barras con las causas probables de las alertas (Puerta Abierta, Falla Motor, etc.).
*   **Insights Textuales:** Resúmenes generados por el motor de analíticas.

### 🔗 Integración API

**Endpoint 1:** `GET /reports/{id}?start=...&end=...` (Datos Analíticos)
**Endpoint 2:** `GET /readings/{id}/history?start=...&end=...` (Datos Gráfico)
**Endpoint 3:** `GET /config/alerts/{id}` (Umbrales de Referencia)

**Respuesta JSON (Reporte):**
```json
{
  "chamber_id": "CF-1",
  "total_alerts": 12,
  "critical_alerts": 5,
  "hours_at_risk": 6.5,
  "estimated_cost": 2500.00,
  "uptime_percentage": 92.0,
  "alert_causes": {
    "Puerta Abierta": 5,
    "Falla Compresor": 2
  },
  "analysis_risk_text": "Riesgo alto detectado en turno nocturno.",
  "analysis_cost_text": "Impacto financiero significativo."
}
```

---

## 3. Histórico de Temperaturas

Registro detallado y auditable de cada lectura del sensor.

### 🎯 Funcionalidad
*   **Tabla Paginada:** Listado denso de lecturas.
*   **Estado Granular:** Etiquetas visuales para cada lectura (Normal, Advertencia, Crítico).
*   **Filtros:** Selector de rango de fechas y cámara específica.
*   **Diferencial:** Cálculo automático de desviación respecto al objetivo (`T - Target`).

### 🔗 Integración API

**Endpoint:** `GET /readings/{id}/history?start=...&end=...`

**Respuesta JSON:**
```json
[
  {
    "id": 1050,
    "sensor_id": "CF-1",
    "temperature": -16.5,
    "target_temperature": -18.0,
    "rate_of_change": 0.5,
    "status": "WARNING_HOT",
    "timestamp": "2024-12-11T22:15:00Z"
  }
]
```

---

## 4. Centro de Alertas

Buzón unificado de incidentes y notificaciones.

### 🎯 Funcionalidad
*   **Tarjetas de Incidente:** Diseño "Premium" con iconos circulares y badges de estado.
*   **Indicadores de Canal:** Iconos (🔔, ✉️, 💬) que muestran por qué medio se notificó (Push, Email, SMS).
*   **Gestión de Estado:** Marcar como leídas (punto azul desaparece).
*   **KPIs Rápidos:** Contador de alertas totales y pendientes de lectura.

### 🔗 Integración API

**Endpoint:** `GET /alerts` (Lista)
**Endpoint:** `PATCH /alerts/{id}/read` (Marcar Leída)

**Respuesta JSON (Lista):**
```json
[
  {
    "id": "ALT-001",
    "title": "Temperatura Crítica",
    "description": "Se superó el límite de -10°C por más de 15 min.",
    "severity": "CRITICAL", // WARNING, CRITICAL
    "category": "HOT_TEMP", // HOT_TEMP, COLD_TEMP, RAPID_CHANGE, SENSOR_OFFLINE
    "timestamp": "2024-12-11T22:18:00Z",
    "is_read": false,
    "estimated_cost": 500.00,
    "channels": ["PUSH", "EMAIL", "SMS"], // Canales ejecutados
    "sensor_id": "CF-1"
  }
]
```

---

## 5. Configuración de Cámara

Panel de control para definir las reglas de negocio y seguridad de cada equipo.

### 🎯 Funcionalidad
*   **Umbrales Granulares:** Definición precisa de 4 niveles:
    1.  🥶 Crítico Frío (Congelación excesiva)
    2.  🎯 Objetivo (Ideal)
    3.  ⚠️ Temperatura Advertencia (Pre-alarma)
    4.  🔥 Crítico Calor (Peligro)
*   **Ayuda Contextual:** Botón de información (Tooltip) explicativo en el parámetro de Sensibilidad.
*   **Reglas de Notificación:** Configuración de canales (Push, Email, SMS) separada por escenario de riesgo.

### 🔗 Integración API

**Endpoint (Carga):** `GET /config/alerts/{id}`
**Endpoint (Guardado):** `PUT /config/alerts/{id}`

**Estructura JSON (Configuración):**
```json
{
  "sensor_id": "CF-1",
  "thresholds": {
    "critical_cold": -30.0,
    "target": -20.0,
    "warning_hot": -15.0,
    "critical_hot": -10.0,
    "rate_of_change": 1.0
  },
  "notifications": {
    "on_warning_hot": {
      "channels": ["push"], 
      "target_roles": ["staff"]
    },
    "on_critical_hot": {
      "channels": ["push", "sms", "email"],
      "target_roles": ["manager"]
    },
    "on_critical_cold": {
      "channels": ["email"],
      "target_roles": ["technician"]
    }
  },
  "is_enabled": true
}
```

---

## 6. Perfil de Usuario

Gestión de datos de contacto para la recepción de alertas.

### 🎯 Funcionalidad
*   **Edición de Datos:** Nombre, Correo Electrónico y Teléfono.
*   **Rol:** Visualización del rol asignado (Admin, Técnico, etc.).
*   **Avatar:** Generación automática basada en iniciales.

### 🔗 Integración API

**Endpoint (Carga):** `GET /users/profile`
**Endpoint (Guardado):** `PUT /users/profile`

**Estructura JSON:**
```json
{
  "id": "USR-123",
  "name": "Juan Pérez",
  "email": "juan.perez@empresa.com",
  "phone_number": "+593 99 123 4567",
  "role": "admin",
  "avatar_url": null
}

---

## ⚠️ Estado de Implementación y Deuda Técnica (Prototipo V2)

Esta sección detalla discrepancias conocidas entre el diseño y la implementación actual del prototipo.

### 1. Gestión de Avatar de Usuario
*   **Estado:** Implementación Estática.
*   **Detalle:** Aunque el modelo `UserProfile` y la API incluyen el campo `avatar_url`, la interfaz de usuario ignora este valor y carga el archivo local `assets/images/bello.png` de forma persistente.
*   **Motivo:** Evitar la modificación del esquema de base de datos actual y garantizar una visualización personalizada inmediata en el prototipo.

### 2. Persistencia de Sesión
*   **Estado:** No Implementada.
*   **Detalle:** El sistema asume un perfil de administrador constante (ID: USR-001). No existe flujo de Login ni almacenamiento de tokens JWT en esta versión.

### 3. Conectividad en Tiempo Real
*   **Estado:** Simulación por Polling.
*   **Detalle:** El frontend solicita actualizaciones periódicas. No se han implementado WebSockets para notificaciones instantáneas ("Push Real").
```
