# Guía de Integración Backend - Rukito

Para **Angello Vásconez** (Backend Go + Python Analytics)

---

## 📋 Resumen

El frontend Flutter necesita un backend Go que exponga una API REST en `http://localhost:8080/api`.

**Responsabilidad del Frontend:**
- ✅ Interfaz de usuario
- ✅ Gestión de estado local
- ✅ Navegación entre vistas

**Responsabilidad del Backend:**
- 🔧 Recibir datos de sensores (concurrencia con Goroutines)
- 🔧 Almacenar datos en MySQL
- 🔧 Exponer API REST con endpoints especificados
- 🔧 Servicio Python para análisis (dT/dt, correlaciones)
- 🔧 Lógica de priorización de alertas

---

## 🔌 Endpoints Requeridos

Ver `API_SPECIFICATION.md` para detalles completos.

**Resumen rápido:**

```
GET  /api/chambers                      # Todas las cámaras
GET  /api/chambers/{id}                 # Una cámara
GET  /api/readings/{id}                 # Lecturas recientes
GET  /api/readings/{id}/history         # Histórico (rango fechas)
GET  /api/alerts                        # Todas las alertas
GET  /api/alerts/chamber/{id}           # Alertas de una cámara
PATCH /api/alerts/{id}/read             # Marcar como leída
GET  /api/config/alerts/{id}            # Configuración
PUT  /api/config/alerts/{id}            # Actualizar config
GET  /api/reports/{id}                  # Reportes de análisis
GET  /api/statistics                    # Estadísticas generales
GET  /api/health                        # Health check
```

---

## 🗄️ Modelo de Datos Esperado

### ColdChamber
```go
type ColdChamber struct {
    ID                 string    `json:"id"`
    Name               string    `json:"name"`
    Content            string    `json:"content"`
    CurrentTemperature float64   `json:"current_temperature"`
    TargetTemperature  float64   `json:"target_temperature"`
    CriticalThreshold  float64   `json:"critical_threshold"`
    WarningThreshold   float64   `json:"warning_threshold"`
    RateOfChange       float64   `json:"rate_of_change"`
    Status             int       `json:"status"` // 0=online, 1=warning, 2=offline
    LastUpdate         time.Time `json:"last_update"`
    RecentTemps        []float64 `json:"recent_temperatures"`
    IsActive           bool      `json:"is_active"`
    Location           string    `json:"location"`
}
```

### TemperatureReading
```go
type TemperatureReading struct {
    ID               string    `json:"id"`
    SensorID         string    `json:"sensor_id"`
    Temperature      float64   `json:"temperature"`
    TargetTemp       float64   `json:"target_temperature"`
    MinTemp          float64   `json:"min_temperature"`
    MaxTemp          float64   `json:"max_temperature"`
    RateOfChange     float64   `json:"rate_of_change"` // dT/dt
    Timestamp        time.Time `json:"timestamp"`
    Status           string    `json:"status"` // CRÍTICO, ADVERTENCIA, NORMAL
}
```

### Alert
```go
type Alert struct {
    ID              string    `json:"id"`
    Title           string    `json:"title"`
    Description     string    `json:"description"`
    Priority        int       `json:"priority"` // 0=P1, 1=P2, 2=P3
    Type            int       `json:"type"` // Enum de tipos
    SensorID        string    `json:"sensor_id"`
    Timestamp       time.Time `json:"timestamp"`
    IsRead          bool      `json:"is_read"`
    EstimatedCost   *float64  `json:"estimated_cost"`
    AffectedContent *string   `json:"affected_content"`
    SuggestedAction *string   `json:"suggested_action"`
}
```

### AlertConfig
```go
type AlertConfig struct {
    ID                     string    `json:"id"`
    SensorID               string    `json:"sensor_id"`
    MaxTemp                float64   `json:"max_temperature"`
    MinTemp                float64   `json:"min_temperature"`
    RateOfChangeThreshold  float64   `json:"rate_of_change_threshold"`
    Priority               int       `json:"priority"` // 0=low, 1=med, 2=high
    IsEnabled              bool      `json:"is_enabled"`
    NotificationChannels   []string  `json:"notification_channels"`
    Recipients             []string  `json:"recipients"`
    CreatedAt              time.Time `json:"created_at"`
    UpdatedAt              time.Time `json:"updated_at"`
}
```

---

## 🚀 Proceso de Integración

### Fase 1: Setup Base
1. Crear proyecto Go con estructura estándar
2. Configurar MySQL (crear base de datos)
3. Implementar modelos anteriores
4. Setup CORS (permitir requests desde localhost:3000+)

### Fase 2: Endpoints CRUD
1. Implementar endpoints de **lectura** (GET):
   - `/chambers`
   - `/readings/{id}`
   - `/alerts`
   - `/config/alerts/{id}`
   
2. Implementar endpoints de **escritura** (PATCH/PUT):
   - `PATCH /alerts/{id}/read`
   - `PUT /config/alerts/{id}`

3. Implementar endpoints de **análisis**:
   - `/reports/{id}`
   - `/statistics`

### Fase 3: Concurrencia
1. Implementar Goroutines para recibir datos de múltiples sensores
2. Queue de procesamiento de datos
3. Procesamiento concurrente sin latencia

### Fase 4: Analytics (Python)
1. Servicio Python separado que:
   - Lee histórico de la BD
   - Calcula dT/dt (derivada de temperatura)
   - Detecta patrones de riesgo
   - Retorna alertas críticas al Go
2. Integración con el servidor Go

---

## 🔄 Flujo de Datos

```
Sensores (15-20)
    ↓
Go Server (Concurrencia con Goroutines)
    ├→ Recibe datos
    ├→ Guarda en MySQL
    ├→ Envía a Python Analytics
    └→ Genera alertas
        ↓
    Python (Análisis de datos)
        ├→ Lee histórico
        ├→ Calcula dT/dt
        ├→ Detecta riesgos
        └→ Retorna alertas
    ↓
Frontend Flutter
    ├→ GET /chambers
    ├→ GET /alerts
    ├→ GET /readings/{id}
    └→ Muestra dashboard
```

---

## 📝 Configuración Recomendada

### Variables de Entorno (.env)
```env
# Base de datos
DB_HOST=localhost
DB_PORT=3306
DB_USER=rukito_user
DB_PASSWORD=secure_password
DB_NAME=rukito

# Servidor Go
SERVER_PORT=8080
SERVER_HOST=0.0.0.0

# Python Analytics
PYTHON_SERVICE_URL=http://localhost:8000

# Sensores
SENSOR_TIMEOUT=30
SENSOR_RETRY_COUNT=3
```

### Estructura de Base de Datos

```sql
-- Cámaras
CREATE TABLE chambers (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255),
    content VARCHAR(255),
    target_temperature DECIMAL(5,2),
    critical_threshold DECIMAL(5,2),
    warning_threshold DECIMAL(5,2),
    location VARCHAR(255),
    is_active BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Lecturas de temperatura
CREATE TABLE temperature_readings (
    id VARCHAR(50) PRIMARY KEY,
    sensor_id VARCHAR(50),
    temperature DECIMAL(5,2),
    rate_of_change DECIMAL(5,2),
    status VARCHAR(20),
    timestamp TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES chambers(id)
);

-- Alertas
CREATE TABLE alerts (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255),
    description TEXT,
    priority INT,
    type INT,
    sensor_id VARCHAR(50),
    is_read BOOLEAN,
    estimated_cost DECIMAL(10,2),
    timestamp TIMESTAMP,
    created_at TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES chambers(id)
);

-- Configuración de alertas
CREATE TABLE alert_configs (
    id VARCHAR(50) PRIMARY KEY,
    sensor_id VARCHAR(50),
    max_temperature DECIMAL(5,2),
    min_temperature DECIMAL(5,2),
    rate_of_change_threshold DECIMAL(5,2),
    priority INT,
    is_enabled BOOLEAN,
    notification_channels JSON,
    recipients JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES chambers(id)
);
```

---

## 🧪 Testing

El frontend actual usa `MockApiService` que simula todos los endpoints.

Para cambiar al backend real:

**En `lib/main.dart`:**
```dart
// Cambiar de:
final IApiService apiService = MockApiService();

// A:
final IApiService apiService = ApiService(); // Usa http://localhost:8080/api
```

---

## 📞 Comunicación Entre Servicios

### Frontend → Backend
Peticiones HTTP REST a `http://localhost:8080/api/...`

### Backend Go → Python Analytics
Llamadas HTTP o gRPC (decidir):
```go
// Opción 1: HTTP
POST http://localhost:8000/analyze
{
    "chamber_id": "CF-1",
    "period_start": "2024-12-04T00:00:00Z",
    "period_end": "2024-12-11T23:59:59Z"
}

// Opción 2: gRPC (más eficiente)
// Definir servicios en .proto
```

---

## ✅ Checklist de Implementación

- [ ] Setup proyecto Go con estructura estándar
- [ ] Configurar MySQL y crear tablas
- [ ] Implementar modelos de datos
- [ ] Implementar endpoint: GET /chambers
- [ ] Implementar endpoint: GET /chambers/{id}
- [ ] Implementar endpoint: GET /readings/{id}
- [ ] Implementar endpoint: GET /readings/{id}/history
- [ ] Implementar endpoint: GET /alerts
- [ ] Implementar endpoint: GET /alerts/chamber/{id}
- [ ] Implementar endpoint: PATCH /alerts/{id}/read
- [ ] Implementar endpoint: GET /config/alerts/{id}
- [ ] Implementar endpoint: PUT /config/alerts/{id}
- [ ] Implementar endpoint: GET /reports/{id}
- [ ] Implementar endpoint: GET /statistics
- [ ] Implementar endpoint: GET /health
- [ ] Habilitar CORS
- [ ] Servicio Python para análisis
- [ ] Integración Python ↔ Go
- [ ] Concurrencia con Goroutines
- [ ] Testing end-to-end

---

## 📚 Referencias

- **Frontend Spec**: Ver `ESPECIFICACIONES_PROTOTIPO.md`
- **API Spec**: Ver `API_SPECIFICATION.md`
- **Código Frontend**: `lib/` en Flutter
- **Models Frontend**: `lib/models/`

---

## 🤝 Coordinación

**Reunión semanal recomendada:**
- Lunes 10am: Revisar progreso
- Miércoles: Resolver blockers de integración
- Viernes: Demo de nuevas features

**Canal de comunicación:**
- Issues: Problemas de integración
- Slack/Teams: Chat rápido
- Llamadas: Debugging de urgencias
