# Rukito - Sistema de Monitoreo de Cadena de Frío 🥩❄️

Proyecto universitario para el monitoreo concurrente en tiempo real de cámaras frigoríficas, con sistema de alertas inteligentes y análisis de riesgo financiero.

---

## 🏛️ Arquitectura del Sistema

El proyecto sigue una arquitectura de microservicios híbrida:

1.  **Frontend (Flutter):** Dashboard móvil multiplataforma para visualización y control.
2.  **Backend Core (Go):** API Gateway de alto rendimiento, gestión de concurrencia (Goroutines) y persistencia.
3.  **Analytics Service (Python):** Motor de inteligencia de negocio, cálculo de riesgo térmico y estimación de costos basada en scraping de mercado.
4.  **Base de Datos (MySQL):** Almacenamiento centralizado con esquema granular.

---

## 📂 Estructura de Carpetas

```
/
├── rukito/                  # Frontend Flutter
├── rukito-backend/          # Backend Monorepo
│   ├── cmd/server/          # Entrypoint Go
│   ├── internal/            # Código fuente Go (API, DB, Modelos)
│   ├── analytics/           # Microservicio Python (FastAPI)
│   ├── scripts/             # SQL de inicialización y Seeding
│   └── tests/               # Suite de pruebas de integración
└── datos/                   # CSVs compartidos (precios, logs)
```

---

## 📱 Frontend (Flutter)

Aplicación móvil para el usuario final (Responsabilidad: Víctor Borbor).

### Características Clave
*   **Dashboard Granular**: Visualización en tiempo real con Sparklines (mini-gráficos de tendencia).
*   **Configuración Avanzada**: Gestión de 4 umbrales térmicos (Frío, Objetivo, Advertencia, Calor) con validaciones de seguridad.
*   **Centro de Alertas**: Clasificación por severidad (Crítico vs Advertencia) e iconos semánticos.
*   **Reportes Inteligentes**: Análisis de confiabilidad, costos y diagnósticos automáticos.

### Instalación
```bash
cd rukito
flutter pub get
flutter run
```

### Configuración API
Para conectar con el backend real, editar `lib/services/api_service.dart`:
```dart
// Para Android Emulator use 10.0.2.2, para Web/Desktop use localhost
static const String _baseUrl = 'http://localhost:8080/api';
```

---

## 🚀 Guía de Inicio Rápido (Backend & Analytics)

Para levantar toda la infraestructura del servidor (Responsabilidad: Angello Vásconez).

### 1. Prerrequisitos
*   **Go** (1.20+)
*   **Python** (3.9+)
*   **MySQL** (8.0+) corriendo en local o Docker.

### 2. Configuración de Base de Datos
Ejecuta el script SQL para crear la base de datos y cargar datos iniciales:
```bash
# Desde la raíz del repositorio (rukito-unified-group/)
mysql -u root -p < rukito-backend/scripts/setup.sql
```

### 3. Configuración del Entorno
Crea un archivo `.env` en `rukito-backend/`. Ejemplo de estructura final:

```env
# Base de datos
DB_HOST=localhost
DB_PORT=3306
DB_USER=TU_USUARIO_MYSQL
DB_PASSWORD=TU_CONTRASEÑA_MYSQL
DB_NAME=rukito

# Servidor Go
SERVER_PORT=8080
SERVER_HOST=0.0.0.0

# Python Analytics Service
PYTHON_SERVICE_URL=http://localhost:8000
```

### 4. Ejecutar Backend (Go)
El servidor principal que maneja la simulación de sensores y la API.

```bash
cd rukito-backend

# Instalar dependencias (basado en go.mod)
go mod tidy
# Nota: Esto instalará automáticamente:
# - github.com/go-sql-driver/mysql (v1.9.3)
# - github.com/gorilla/mux (v1.8.1)
# - github.com/joho/godotenv (v1.5.1)
# - github.com/google/uuid (v1.6.0)

go run cmd/server/main.go
```
*El servidor escuchará en `http://localhost:8080`.*

### 5. Ejecutar Servicio de Analítica (Python)
El microservicio para cálculos financieros y reportes.

```bash
cd rukito-backend/analytics

# Crear y activar entorno virtual
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar servidor
uvicorn main:app --port 8000 --reload
```
*El servicio escuchará en `http://localhost:8000`.*

---

## 🧪 Ejecución de Pruebas (Test Suite Backend)

La suite de pruebas automatizadas verifica la integridad lógica y la comunicación entre servicios.

**Nota:** Estos tests validan únicamente el Backend (Go + Python).

**Instrucciones:**
1.  Asegúrate de que **MySQL, Go (8080) y Python (8000)** estén corriendo.
2.  Los scripts se encuentran en la carpeta `rukito-backend/tests/`.
3.  Ejecuta el script maestro o los tests individuales según necesites:

```bash
cd rukito-backend

# Ejecutar suite completa de integración
./tests/test_full_integration_suite.sh
```

---

## 📚 Manuales y Documentación

Documentación técnica detallada para desarrolladores e integradores.

*   **[Manual del Frontend (Flutter)](rukito/manual_frontend.md):** Guía de pantallas, modelos y consumo de API.
*   **[Manual del Backend (Go)](rukito-backend/docs/MANUAL_BACKEND_GO.md):** API, endpoints granulares y arquitectura.
*   **[Manual de Analítica (Python)](rukito-backend/docs/MANUAL_ANALYTICS_PYTHON.md):** Algoritmos financieros y de riesgo.
*   **[Manual de Tests](rukito-backend/docs/MANUAL_TESTS.md):** Guía detallada de la suite de pruebas del servidor (Backend y Analítica).
*   **[Arquitectura del Sistema](rukito-backend/docs/SYSTEM_ARCHITECTURE.md):** Diagramas de flujo y ciclo de vida del dato.

---

## 👥 Equipo
*   **Víctor Borbor:** Frontend & UI/UX.
*   **Angello Vásconez:** Backend, Arquitectura & Data Analytics.