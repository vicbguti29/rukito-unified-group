# Instrucciones de Colaboración - Proyecto Rukito

Para **Víctor Borbor** (Frontend Flutter) y **Angello Vásconez** (Backend Go + Python)

---

## 📂 Estructura del Repositorio

```
rukito/
├── lib/                          # Código Flutter (FRONTEND - Víctor)
│   ├── main.dart                # Punto de entrada
│   ├── models/                  # Modelos de datos
│   ├── services/                # Servicios API
│   ├── providers/               # Estado global
│   ├── screens/                 # Vistas/Pantallas
│   ├── widgets/                 # Componentes
│   ├── theme/                   # Tema y colores
│   └── config/                  # Configuración
│
├── API_SPECIFICATION.md         # 📋 LEER: Especificación de endpoints
├── BACKEND_INTEGRATION.md       # 📋 LEER: Guía para Angello
├── ESPECIFICACIONES_PROTOTIPO.md # Especificaciones de diseño
├── README.md                    # Información general
└── pubspec.yaml                # Dependencias Flutter
```

---

## 👨‍💻 Victor Borbor - FRONTEND

### Tu Responsabilidad
- ✅ Interfaz de usuario (Flutter/Dart)
- ✅ Consumir API REST del backend
- ✅ Gestión de estado local (Provider)
- ✅ Navegación entre pantallas
- ✅ Temas y colores
- ✅ Validación de entrada

### Archivos Clave

```
lib/
├── main.dart                 # Cambiar MockApiService ↔ ApiService aquí
├── config/app_config.dart   # Configuración de la app
├── services/
│   ├── api_service.dart     # Cliente HTTP para backend real
│   └── mock_api_service.dart # Datos simulados para desarrollo
└── screens/
    ├── views/dashboard_view.dart
    ├── views/alerts_view.dart
    ├── views/historical_view.dart
    └── views/reports_view.dart
```

### Para Cambiar entre MockAPI y BackendReal

**En `lib/main.dart` línea ~18:**

```dart
// Para DESARROLLO (sin backend):
final IApiService apiService = MockApiService();

// Para INTEGRACIÓN (con backend):
final IApiService apiService = ApiService();
```

### Para Cambiar la URL del Backend

**En `lib/config/app_config.dart`:**

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:8080/api'; // ← CAMBIAR AQUÍ
  // ...
}
```

---

## 🔧 Angello Vásconez - BACKEND

### Tu Responsabilidad
- 🔧 Servidor Go con API REST
- 🔧 Recepción concurrente de datos (Goroutines)
- 🔧 Almacenamiento en MySQL
- 🔧 Servicio Python para análisis (dT/dt, correlaciones)
- 🔧 Lógica de priorización de alertas
- 🔧 Persistencia de datos históricos

### Documentación a Leer
1. **`API_SPECIFICATION.md`** - Endpoints exactos que necesita el frontend
2. **`BACKEND_INTEGRATION.md`** - Guía completa de integración
3. **`ESPECIFICACIONES_PROTOTIPO.md`** - Contexto del negocio

### Endpoints a Implementar (Resumen)

```go
// Cámaras
GET    /api/chambers
GET    /api/chambers/{id}

// Lecturas
GET    /api/readings/{id}
GET    /api/readings/{id}/history

// Alertas
GET    /api/alerts
GET    /api/alerts/chamber/{id}
PATCH  /api/alerts/{id}/read

// Configuración
GET    /api/config/alerts/{id}
PUT    /api/config/alerts/{id}

// Reportes
GET    /api/reports/{id}
GET    /api/statistics

// Health
GET    /api/health
```

Ver `API_SPECIFICATION.md` para **request/response completos**.

### Modelos Esperados

Ver sección "Modelo de Datos Esperado" en `BACKEND_INTEGRATION.md`.

Todos los endpoints deben retornar JSON con la estructura exacta especificada.

---

## 🔄 Flujo de Desarrollo

### Semana 1: Setup
- [ ] **Victor**: Correr `flutter run -d chrome` con MockApiService
- [ ] **Angello**: Setup proyecto Go + MySQL

### Semana 2-3: Backend Básico
- [ ] **Victor**: Mejorar UI/UX según feedback
- [ ] **Angello**: Implementar endpoints GET (lectura)
  - `/chambers`
  - `/readings/{id}`
  - `/alerts`

### Semana 3-4: Integración
- [ ] **Victor**: Cambiar a ApiService, conectar con backend
- [ ] **Angello**: Implementar endpoints PATCH/PUT (escritura)
  - `PATCH /alerts/{id}/read`
  - `PUT /config/alerts/{id}`

### Semana 4-5: Analytics
- [ ] **Victor**: Mejorar vistas de reportes
- [ ] **Angello**: Servicio Python + integración Go
  - Análisis de dT/dt
  - Correlaciones
  - Reportes

### Semana 5-6: Concurrencia
- [ ] **Victor**: Testing y bugs
- [ ] **Angello**: Goroutines para múltiples sensores

### Semana 6: Producción
- [ ] **Victor**: Deploy a Play Store
- [ ] **Angello**: Deploy backend a servidor

---

## 📞 Integración

### Verificar que todo funciona:

1. **Backend corriendo:**
   ```bash
   # Terminal 1: Backend Go
   go run main.go
   # → Debe escuchar en http://localhost:8080
   ```

2. **Frontend conectado:**
   ```bash
   # Terminal 2: Frontend Flutter
   flutter run -d chrome
   # → Cambiar apiService = ApiService() en main.dart
   # → Dashboard debe mostrar datos del backend
   ```

3. **Verificar health:**
   ```bash
   curl http://localhost:8080/api/health
   # → { "status": "ok", "timestamp": "..." }
   ```

---

## 🧪 Testing

### Frontend Testing

```bash
# Unitarios
flutter test

# Con cobertura
flutter test --coverage

# Análisis de código
flutter analyze
```

### Backend Testing (Go)

```bash
# Tests unitarios
go test ./...

# Con cobertura
go test -cover ./...

# Verificar endpoints
curl http://localhost:8080/api/chambers
```

---

## 📋 Checklist de Entrega

### Frontend (Victor)
- [ ] Dashboard funcional con 4 vistas
- [ ] Conecta con API backend
- [ ] Manejo de errores robusto
- [ ] Tests unitarios ≥ 80% cobertura
- [ ] Responsive (desktop, tablet, mobile)
- [ ] Documentación actualizada

### Backend (Angello)
- [ ] Todos los 12 endpoints implementados
- [ ] Datos en MySQL persistentes
- [ ] Concurrencia con Goroutines
- [ ] Servicio Python funcionando
- [ ] Tests ≥ 70% cobertura
- [ ] Documentación de API
- [ ] CORS habilitado

---

## 🆘 Troubleshooting

### "Failed to fetch from API"
- **Victor**: Verificar que `ApiService` está usando en `main.dart`
- **Angello**: Asegurar backend corriendo en `http://localhost:8080`
- **Ambos**: Verificar CORS está habilitado

### "JSON deserialization error"
- **Victor**: Revisar que estructura JSON matches a models
- **Angello**: Asegurar response matches `API_SPECIFICATION.md`

### "Schema mismatch"
- **Ambos**: Ejecutar juntos en llamada y verificar endpoint a endpoint

---

## 📚 Documentación

- **Especificaciones de diseño**: `ESPECIFICACIONES_PROTOTIPO.md`
- **API Specification**: `API_SPECIFICATION.md`
- **Guía de Backend**: `BACKEND_INTEGRATION.md`
- **README General**: `README.md`

---

## 🎯 Objetivos Principales

1. ✅ **Dashboard en tiempo real** de todas las cámaras
2. ✅ **Sistema de alertas prioritarias** (P1, P2, P3)
3. ✅ **Histórico de temperaturas** con análisis
4. ✅ **Reportes de riesgo** con cálculos de dT/dt
5. ✅ **Concurrencia** sin latencia
6. ✅ **Persistencia** de datos históricos

---

## 📞 Comunicación Recomendada

- **Daily Standup**: 10:00 AM (15 min)
- **Weekly Sync**: Viernes 3:00 PM (30 min)
- **Issues**: GitHub/Jira
- **Chat**: Slack/Teams
- **Emergencias**: Llamada directa

---

## 🚀 Deploy

### Desarrollo
- Frontend: `flutter run -d chrome`
- Backend: `go run main.go`

### Producción
- Frontend: `flutter build apk` + Google Play
- Backend: Docker en servidor cloud

---

**¡Éxito en el proyecto!** 🎉

Cualquier duda, revisar la documentación o contactar al otro integrante.
