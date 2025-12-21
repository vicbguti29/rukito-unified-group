# API Specification - Rukito Backend

Especificación completa de endpoints que el backend Go debe implementar para integrarse con el frontend Flutter.

## Base URL
```
http://localhost:8080/api
```

## Autenticación
Por ahora sin autenticación. Implementar en fase 2.

---

## 1. CÁMARAS FRIGORÍFICAS

### GET `/chambers`
Obtiene todas las cámaras frigoríficas activas.

**Response: 200 OK**
```json
[
  {
    "id": "CF-1",
    "name": "Cámara Frigorífica 1 (CF-1)",
    "content": "Carnes Prime",
    "current_temperature": -16.5,
    "target_temperature": -20,
    "critical_threshold": -18,
    "warning_threshold": -17,
    "rate_of_change": 0.5,
    "status": 1,
    "last_update": "2024-12-11T22:15:00Z",
    "recent_temperatures": [-20, -19.5, -18.5, -17.5, -16.5, -16],
    "is_active": true,
    "location": "Sala Principal"
  }
]
```

**Status enum:**
- 0: online
- 1: warning
- 2: offline

---

### GET `/chambers/{id}`
Obtiene una cámara específica.

**Response: 200 OK**
```json
{
  "id": "CF-1",
  "name": "Cámara Frigorífica 1 (CF-1)",
  "content": "Carnes Prime",
  "current_temperature": -16.5,
  "target_temperature": -20,
  "critical_threshold": -18,
  "warning_threshold": -17,
  "rate_of_change": 0.5,
  "status": 1,
  "last_update": "2024-12-11T22:15:00Z",
  "recent_temperatures": [-20, -19.5, -18.5, -17.5, -16.5, -16],
  "is_active": true,
  "location": "Sala Principal"
}
```

---

## 2. LECTURAS DE TEMPERATURA

### GET `/readings/{chamber_id}`
Obtiene las lecturas recientes de una cámara.

**Query Parameters:**
- `limit` (default: 100): Número de registros a retornar

**Response: 200 OK**
```json
[
  {
    "id": "READ-CF-1-0",
    "sensor_id": "CF-1",
    "temperature": -16.5,
    "target_temperature": -20,
    "min_temperature": -21,
    "max_temperature": -14,
    "rate_of_change": 0.5,
    "timestamp": "2024-12-11T22:15:00Z",
    "status": "ADVERTENCIA"
  }
]
```

**Status values:**
- `CRÍTICO`: Temperatura > threshold crítico
- `ADVERTENCIA`: Temperatura > threshold advertencia
- `NORMAL`: Temperatura normal

---

### GET `/readings/{chamber_id}/history`
Obtiene histórico de temperatura para un rango de fechas.

**Query Parameters:**
- `start` (required): ISO8601 datetime (2024-12-04T00:00:00Z)
- `end` (required): ISO8601 datetime (2024-12-11T23:59:59Z)

**Response: 200 OK**
```json
[
  {
    "id": "READ-CF-1-120",
    "sensor_id": "CF-1",
    "temperature": -20.0,
    "target_temperature": -20,
    "min_temperature": -21,
    "max_temperature": -14,
    "rate_of_change": 0.0,
    "timestamp": "2024-12-04T00:00:00Z",
    "status": "NORMAL"
  }
]
```

---

## 3. ALERTAS

### GET `/alerts`
Obtiene todas las alertas activas.

**Query Parameters:**
- `limit` (default: 50): Número de registros
- `unread_only` (default: false): Solo alertas sin leer

**Response: 200 OK**
```json
[
  {
    "id": "ALT-001",
    "title": "CF-1 en Riesgo de Pérdida Total",
    "description": "La puerta de CF-1 (Carnes Prime) detectada abierta...",
    "priority": 0,
    "type": 0,
    "sensor_id": "CF-1",
    "timestamp": "2024-12-11T22:18:00Z",
    "is_read": false,
    "estimated_cost": 15000.0,
    "affected_content": "Carnes Premium",
    "suggested_action": "Cerrar puerta inmediatamente"
  }
]
```

**Priority enum:**
- 0: P1 (Crítica)
- 1: P2 (Advertencia)
- 2: P3 (Info)

**Type enum:**
- 0: temperatureCritical
- 1: temperatureWarning
- 2: doorOpen
- 3: powerFailure
- 4: maintenanceRequired
- 5: normalOperation
- 6: smsNotification

---

### GET `/alerts/chamber/{chamber_id}`
Obtiene alertas específicas de una cámara.

**Response: 200 OK**
```json
[
  {
    "id": "ALT-001",
    "title": "CF-1 en Riesgo de Pérdida Total",
    "description": "...",
    "priority": 0,
    "type": 0,
    "sensor_id": "CF-1",
    "timestamp": "2024-12-11T22:18:00Z",
    "is_read": false,
    "estimated_cost": 15000.0,
    "affected_content": "Carnes Premium",
    "suggested_action": "Cerrar puerta inmediatamente"
  }
]
```

---

### PATCH `/alerts/{alert_id}/read`
Marca una alerta como leída.

**Response: 200 OK**
```json
{
  "id": "ALT-001",
  "is_read": true,
  "updated_at": "2024-12-11T22:20:00Z"
}
```

---

## 4. CONFIGURACIÓN DE ALERTAS

### GET `/config/alerts/{chamber_id}`
Obtiene la configuración de alertas de una cámara.

**Response: 200 OK**
```json
{
  "id": "CONFIG-CF-1",
  "sensor_id": "CF-1",
  "max_temperature": 5.0,
  "min_temperature": -25.0,
  "rate_of_change_threshold": 0.5,
  "priority": 2,
  "is_enabled": true,
  "notification_channels": ["sms", "push"],
  "recipients": ["+593999123456"],
  "created_at": "2024-11-11T00:00:00Z",
  "updated_at": "2024-12-11T00:00:00Z"
}
```

**Priority enum:**
- 0: low
- 1: medium
- 2: high

---

### PUT `/config/alerts/{chamber_id}`
Actualiza la configuración de alertas.

**Request Body:**
```json
{
  "id": "CONFIG-CF-1",
  "sensor_id": "CF-1",
  "max_temperature": 5.0,
  "min_temperature": -25.0,
  "rate_of_change_threshold": 0.4,
  "priority": 2,
  "is_enabled": true,
  "notification_channels": ["sms", "push", "email"],
  "recipients": ["+593999123456", "don@rukito.com"],
  "created_at": "2024-11-11T00:00:00Z",
  "updated_at": "2024-12-11T00:00:00Z"
}
```

**Response: 200 OK**
```json
{
  "id": "CONFIG-CF-1",
  "sensor_id": "CF-1",
  "max_temperature": 5.0,
  "min_temperature": -25.0,
  "rate_of_change_threshold": 0.4,
  "priority": 2,
  "is_enabled": true,
  "notification_channels": ["sms", "push", "email"],
  "recipients": ["+593999123456", "don@rukito.com"],
  "created_at": "2024-11-11T00:00:00Z",
  "updated_at": "2024-12-11T15:30:00Z"
}
```

---

## 5. REPORTES Y ANÁLISIS

### GET `/reports/{chamber_id}`
Obtiene análisis de riesgo para un período.

**Query Parameters:**
- `start` (required): ISO8601 datetime
- `end` (required): ISO8601 datetime

**Response: 200 OK**
```json
{
  "chamber_id": "CF-1",
  "period_start": "2024-11-11T00:00:00Z",
  "period_end": "2024-12-11T23:59:59Z",
  "hours_at_risk": 2.5,
  "estimated_cost": 15000.0,
  "uptime_percentage": 99.8,
  "total_alerts": 24,
  "critical_alerts": 3,
  "warning_alerts": 8,
  "info_alerts": 13,
  "avg_rate_of_change": 0.45,
  "critical_rate_events": 3,
  "demand_correlation": 0.78,
  "total_risk_hours": 4.2,
  "monthly_cost": 1200.0
}
```

---

### GET `/statistics`
Obtiene estadísticas generales del sistema.

**Response: 200 OK**
```json
{
  "total_chambers": 3,
  "active_chambers": 3,
  "critical_chambers": 1,
  "warning_chambers": 1,
  "average_temperature": -3.0,
  "total_alerts": 5,
  "unread_alerts": 4,
  "system_uptime": 99.8,
  "last_update": "2024-12-11T22:30:00Z"
}
```

---

## 6. HEALTH CHECK

### GET `/health`
Verifica que el servidor esté activo.

**Response: 200 OK**
```json
{
  "status": "ok",
  "timestamp": "2024-12-11T22:30:00Z"
}
```

---

## Error Handling

### 400 Bad Request
```json
{
  "error": "Parámetro requerido faltante",
  "details": "start date is required"
}
```

### 404 Not Found
```json
{
  "error": "Recurso no encontrado",
  "details": "chamber CF-1 not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Error interno del servidor",
  "details": "database connection failed"
}
```

---

## Notas Importantes

1. **Timestamps**: Usar ISO8601 con zona UTC (Z)
2. **Decimales**: Temperaturas con 1-2 decimales
3. **Enums**: Enviar como números enteros (índice 0-based)
4. **Paginación**: Implementar `limit` en todos los GET que retornen listas
5. **CORS**: Habilitar CORS para peticiones desde web
6. **Validación**: Validar que los datos enviados sean correctos antes de procesarlos

---

## Frontend Configuration

Para cambiar entre MockApiService y ApiService real:

**En `lib/main.dart`:**
```dart
// Para desarrollo con datos simulados:
final IApiService apiService = MockApiService();

// Para integración con backend real:
final IApiService apiService = ApiService();
```

El frontend usa `http://localhost:8080/api` por defecto. Para cambiar la URL:

**En `lib/services/api_service.dart`:**
```dart
static const String _baseUrl = 'http://tu-servidor:puerto/api';
```
