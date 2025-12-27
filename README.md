# Rukito - Sistema de Monitoreo de Cadena de Frío 🥩❄️

Proyecto universitario para el monitoreo concurrente en tiempo real de cámaras frigoríficas, con sistema de alertas inteligentes y análisis de riesgo financiero.

---

## 🏛️ Arquitectura del Sistema

El proyecto sigue una arquitectura de microservicios híbrida:

1.  **Frontend (Flutter):** Dashboard móvil para visualización y control.
2.  **Backend Core (Go):** API Gateway de alto rendimiento, gestión de concurrencia (Goroutines) y persistencia.
3.  **Analytics Service (Python):** Motor de inteligencia de negocio, cálculo de $dT/dt$ y estimación de costos basada en scraping de mercado.
4.  **Base de Datos (MySQL):** Almacenamiento centralizado.

---

---

## 📂 Estructura de Carpetas

```
/
├── rukito/                  # Frontend Flutter
├── rukito-backend/          # Backend Monorepo
│   ├── cmd/server/          # Entrypoint Go
│   ├── internal/            # Código fuente Go (API, DB, Modelos)
│   ├── analytics/           # Microservicio Python
│   │   ├── analysis.py      # Lógica de negocio (FDA Rule, dT/dt)
│   │   ├── scraper.py       # Extracción de precios de mercado
│   │   └── main.py          # API FastAPI
│   └── scripts/             # SQL de inicialización
└── datos/                   # CSVs compartidos (precios, logs)
```

---

## 📱 Frontend (Flutter)

Aplicación móvil para el usuario final (Responsabilidad: Víctor Borbor).

### Características
*   **Dashboard en Tiempo Real**: Visualización actualizada de todas las cámaras.
*   **Centro de Alertas**: Sistema de prioridades (P1, P2, P3).
*   **Histórico y Reportes**: Gráficos de tendencias y KPIs financieros.

### Instalación
```bash
cd rukito
flutter pub get
flutter run
```

### Configuración API
Para conectar con el backend real, editar `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'http://localhost:8080/api';
```


## 🚀 Guía de Inicio Rápido (Backend & Analytics)

Para levantar toda la infraestructura del servidor (Responsabilidad: Angello Vásconez).

### 1. Prerrequisitos
*   **Go** (1.20+)
*   **Python** (3.9+)
*   **MySQL** (8.0+) corriendo en local o Docker.

### 2. Configuración de Base de Datos
Ejecuta el script SQL para crear la base de datos y cargar datos iniciales:
```bash
# Desde la raíz del repositorio
mysql -u root -p < rukito-backend/scripts/setup.sql
```

### 3. Configuración del Entorno
Asegúrate de que el archivo `.env` en `rukito-backend/` tenga tus credenciales correctas:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=rukito_user
DB_PASSWORD=secure_password
DB_NAME=rukito
SERVER_PORT=8080
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

# Opción A: Modo Producción (Simulación Aleatoria)
go run cmd/server/main.go

# Opción B: Modo Testing (Escenarios Deterministas)
# export SIMULATION_MODE=SCENARIO && go run cmd/server/main.go
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

## 🧪 Ejecución de Pruebas (Test Suite)

Hemos preparado una suite de scripts automatizados para verificar la integración de todos los componentes.

**Instrucciones:**
1.  Asegúrate de tener **ambos servidores corriendo** (Go en 8080, Python en 8000).
2.  Ejecuta los siguientes comandos desde la carpeta `rukito-backend/`:

```bash
cd rukito-backend

# 1. Verificar Endpoints Básicos (CRUD)
./test_endpoints.sh

# 2. Verificar Integración Go <-> Python (Ping)
./test_integration_basics.sh

# 3. Verificar Simulación de Escenarios (Requiere reiniciar Go con SIMULATION_MODE=SCENARIO)
# ./test_scenarios.sh

# 4. Verificar Cadena de Valor Completa (Scraping -> Análisis -> Reporte Financiero)
./test_analytics_integration.sh
```

---

## 👥 Equipo
*   **Víctor Borbor:** Frontend & UI/UX.
*   **Angello Vásconez:** Backend, Arquitectura & Data Analytics.
