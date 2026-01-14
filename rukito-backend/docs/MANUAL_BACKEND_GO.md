# Manual Técnico: Backend Core (Go)

## 1. Visión General
El **Backend Core** es el cerebro operativo del sistema Rukito. Desarrollado en **Go (Golang)**, su objetivo principal es manejar la alta concurrencia de múltiples sensores transmitiendo datos en tiempo real, persistir esta información sin latencia y exponer una API REST segura para el cliente móvil.

**Responsabilidades:**
1.  **Ingestión de Datos:** Recibir y procesar lecturas de temperatura simultáneas.
2.  **Monitoreo en Tiempo Real:** Evaluar cada lectura entrante contra umbrales de seguridad granulares instantáneamente.
3.  **Gestión de Alertas:** Generar notificaciones críticas basadas en estados (`WARNING`, `CRITICAL`) y evitar el "ruido" mediante deduplicación.
4.  **API Gateway:** Servir datos al Frontend y actuar como puente hacia el servicio de Analítica (Python).

---

## 2. Arquitectura del Proyecto
El proyecto sigue una estructura modular estándar en Go ("Clean Architecture" simplificada):

```
rukito-backend/
├── analytics/            # Servicio de Analítica en Python (Ver MANUAL_ANALYTICS_PYTHON.md)
├── cmd/
│   └── server/
│       └── main.go       # Punto de entrada. Carga configuración y arranca servicios.
├── internal/
│   ├── api/              # Capa de Transporte (HTTP Handlers y Rutas).
│   ├── db/               # Capa de Infraestructura (Conexión MySQL).
│   ├── models/           # Definiciones de Estructuras de Datos (Structs JSON).
│   └── service/          # Lógica de Negocio (Simulación, Alertas).
├── tests/                # Suite de pruebas de integración y lógica.
└── .env                  # Variables de entorno (No subir al repo).
```

---

## 3. Funcionamiento Interno

### 3.1. Motor de Concurrencia (Simulación de Sensores)
El corazón del sistema reside en `internal/service/sensor_service.go`. Utiliza las primitivas de concurrencia de Go: **Goroutines** y **Channels**.

*   **Sensores (Productores):**
    *   Al iniciar, el sistema lanza una **Goroutine independiente** para cada sensor configurado (`CF-1`, `CF-2`, `REF-3`).
    *   Cada sensor tiene su propio ciclo de vida (`Ticker`) y genera datos cada 5 segundos.
    *   Los datos se envían a un **Canal (`chan DataPoint`)** centralizado. Esto evita condiciones de carrera.

*   **Worker Pool (Consumidor):**
    *   La función `processSensorData` consume el canal.
    *   **Cache de Configuración:** Mantiene una copia en memoria de los umbrales de alerta (`alert_configs`) que se actualiza cada 5 segundos desde la BD. Esto permite evaluar reglas sin latencia de I/O.

### 3.2. Lógica de Evaluación Granular
Al recibir una lectura, el sistema evalúa dinámicamente el estado usando 4 umbrales configurables:

1.  **Estados:**
    *   `CRITICAL_HOT`: Si T > Umbral Crítico Calor.
    *   `WARNING_HOT`: Si T > Umbral Advertencia Calor.
    *   `CRITICAL_COLD`: Si T < Umbral Crítico Frío.
    *   `NORMAL`: En rango seguro.

2.  **Generación de Alertas:**
    *   Si el estado es crítico o advertencia, se verifica si ya se envió una alerta recientemente (Ventana de 2 minutos).
    *   Si aplica, se inserta en la tabla `alerts` con la severidad (`CRITICAL`/`WARNING`) y categoría (`HOT_TEMP`/`COLD_TEMP`) correspondientes.

### 3.3. Base de Datos (Esquema Granular)
El backend utiliza MySQL con un esquema relacional optimizado.

#### A. Tabla `users` (Usuarios y Roles)
Gestión de perfiles y destinatarios de notificaciones.
*   `id`: INT (PK).
*   `full_name`, `email`, `phone_number`: Datos de contacto.
*   `role`: ENUM ('admin', 'manager', 'staff'). Define permisos y recepción de alertas.

#### B. Tabla `chambers` (Cámaras)
Inventario físico de equipos.
*   `id`: VARCHAR (PK, ej: 'CF-1').
*   `name`: Nombre descriptivo.
*   `updated_at`: Timestamp de la última señal de vida (Heartbeat).
*   *Nota:* Ya no almacena umbrales ni temperaturas actuales (se calculan o consultan en tiempo real).

#### C. Tabla `alert_configs` (Reglas de Negocio)
Define la "física" y notificaciones de cada cámara.
*   `sensor_id`: FK a `chambers`.
*   `threshold_critical_cold`, `threshold_target`, `threshold_warning_hot`, `threshold_critical_hot`: DECIMAL. Los 4 límites térmicos.
*   `actions_critical_hot` (JSON): Reglas de notificación (canales y roles) para cada estado.

#### D. Tabla `temperature_readings` (Historial)
Log inmutable de lecturas.
*   `status`: ENUM ('NORMAL', 'WARNING_HOT', 'CRITICAL_HOT', 'CRITICAL_COLD'). Estado calculado al momento de la lectura.
*   `temperature`: DECIMAL. Valor real.

#### E. Tabla `alerts` (Incidentes)
Registro de eventos notificados.
*   `severity`: ENUM ('WARNING', 'CRITICAL').
*   `category`: ENUM ('HOT_TEMP', 'COLD_TEMP', etc.).
*   `is_read`: BOOLEAN. Estado de gestión.
*   `channels`: JSON. Lista de canales por los que se intentó notificar (ej: `["email", "push"]`).

---

## 4. API REST (Especificación de Endpoints)

El backend expone endpoints JSON en el puerto **8080**. A continuación se detalla su uso por vista del Frontend.

### A. Dashboard (Vista Principal)
**Endpoint:** `GET /api/chambers`
*   **Uso:** Renderizar tarjetas de estado en tiempo real.
*   **Lógica:** Realiza un JOIN complejo para obtener la cámara + su última lectura + su objetivo configurado.
*   **Estructura JSON:**
    ```json
    [
      {
        "id": "CF-1",
        "name": "Cámara Carnes",
        "current_temperature": -16.5,
        "status": "WARNING_HOT",
        "recent_temperatures": [-16.0, -16.2, -16.5, ...] // Para Sparkline
      }
    ]
    ```

### B. Reportes y Análisis
**Endpoint:** `GET /api/reports/{id}?start=...&end=...`
*   **Uso:** Gráficos financieros y diagnósticos.
*   **Lógica:** Proxy hacia el servicio de Python. Calcula el rango en minutos y delega el análisis pesado.
*   **Estructura JSON:**
    ```json
    {
      "hours_at_risk": 2.5,
      "estimated_cost": 500.00,
      "alert_causes": {"Puerta Abierta": 5},
      "uptime_percentage": 92.0,
      "analysis_risk_text": "ALTO RIESGO: Se detectaron brechas...",
      "analysis_cost_text": "Impacto financiero significativo...",
      "analysis_rate_text": "Inestabilidad térmica severa..."
    }
    ```

### C. Historial de Temperaturas
**Endpoint:** `GET /api/readings/{id}/history?start=...&end=...`
*   **Uso:** Tabla paginada y gráfico de línea histórico.
*   **Lógica:** Consulta directa a `temperature_readings` con filtros de fecha.

### D. Centro de Alertas
**Endpoint:** `GET /api/alerts`
*   **Uso:** Listado de notificaciones.
*   **Endpoint:** `PATCH /api/alerts/{id}/read`
*   **Uso:** Marcar alerta como leída (Círculo azul desaparece).

### E. Configuración
**Endpoint:** `GET /api/config/alerts/{id}`
**Endpoint:** `PUT /api/config/alerts/{id}`
*   **Uso:** Formulario de configuración de umbrales.
*   **Validación:** El backend rechaza configuraciones físicamente imposibles (ej: `Critical Cold > Target`).
*   **Estructura JSON:**
    ```json
    {
      "thresholds": {
        "critical_cold": -30.0,
        "target": -20.0,
        "warning_hot": -15.0,
        "critical_hot": -10.0
      },
      "notifications": { ... }
    }
    ```

### F. Perfil de Usuario
**Endpoint:** `GET /api/users/profile`
**Endpoint:** `PUT /api/users/profile`
*   **Uso:** Gestión de datos de contacto del administrador (Don Jorge).

---

## 5. Comandos de Ejecución

**Instalar Dependencias:**
```bash
go mod tidy
```

**Iniciar Servidor:**
```bash
go run cmd/server/main.go
```
El servidor iniciará automáticamente la simulación de sensores y escuchará en el puerto 8080.

---

## 6. Roadmap / Futuras Implementaciones

### A. Estadísticas Globales
**Endpoint:** `GET /api/statistics`
*   **Función:** Proxy hacia `/analyze/statistics` del servicio de Python.
*   **Estado:** Disponible pero no integrado en el Frontend actual.

### B. Envío Real de Notificaciones
Actualmente, el sistema registra la alerta en la BD y simula el envío. La integración con proveedores (Twilio, SendGrid) está pendiente.

### C. Enrutamiento Dinámico de Alertas
La configuración de alertas (`alert_configs`) soporta reglas como `target_roles: ["technician"]`.
*   **Futuro:** El backend deberá consultar la tabla `users` para encontrar los correos con rol 'technician' y enviarles la alerta específica.
*   **Actual:** Todas las alertas se asumen para el administrador principal (ID 1).

### D. Gestión Multi-Usuario
La tabla `users` está diseñada para soportar múltiples cuentas y roles, pero el sistema opera en modo monousuario (Admin).
*   **Pendiente:** Endpoints para crear usuarios (`POST /users`), Login (JWT) y gestión de permisos.