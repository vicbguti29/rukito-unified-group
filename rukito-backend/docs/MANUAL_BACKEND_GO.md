# Manual Técnico: Backend Core (Go)

## 1. Visión General
El **Backend Core** es el cerebro operativo del sistema Rukito. Desarrollado en **Go (Golang)**, su objetivo principal es manejar la alta concurrencia de múltiples sensores transmitiendo datos en tiempo real, persistir esta información sin latencia y exponer una API REST segura para el cliente móvil.

**Responsabilidades:**
1.  **Ingestión de Datos:** Recibir y procesar lecturas de temperatura simultáneas.
2.  **Monitoreo en Tiempo Real:** Evaluar cada lectura entrante contra umbrales de seguridad instantáneamente.
3.  **Gestión de Alertas:** Generar notificaciones críticas y evitar el "ruido" (spam) mediante deduplicación.
4.  **API Gateway:** Servir datos al Frontend y actuar como puente hacia el servicio de Analítica (Python).

---

## 2. Arquitectura del Proyecto
El proyecto sigue una estructura modular estándar en Go ("Clean Architecture" simplificada):

```
rukito-backend/
├── cmd/
│   └── server/
│       └── main.go       # Punto de entrada. Carga configuración y arranca servicios.
├── internal/
│   ├── api/              # Capa de Transporte (HTTP Handlers).
│   ├── db/               # Capa de Infraestructura (Conexión MySQL).
│   ├── models/           # Definiciones de Estructuras de Datos (Structs).
│   └── service/          # Lógica de Negocio (Simulación, Alertas).
└── .env                  # Variables de entorno (No subir al repo).
```

---

## 3. Funcionamiento Interno

### 3.1. Motor de Concurrencia (Simulación de Sensores)
El corazón del sistema reside en `internal/service/sensor_service.go`. Utiliza las primitivas de concurrencia de Go: **Goroutines** y **Channels**.

*   **Sensores (Productores):**
    *   Al iniciar, el sistema lanza una **Goroutine independiente** para cada sensor configurado (`CF-1`, `CF-2`, `REF-3`).
    *   Cada sensor tiene su propio ciclo de vida (`Ticker`) y genera datos cada 5 segundos.
    *   Los datos se envían a un **Canal (`chan DataPoint`)** centralizado. Esto evita condiciones de carrera y bloqueos.

*   **Worker Pool (Consumidor):**
    *   Una función `processSensorData` escucha constantemente el canal.
    *   Procesa los datos uno a uno en orden de llegada (FIFO), pero a una velocidad extremadamente alta, permitiendo manejar miles de sensores virtuales.

### 3.2. Lógica de Cálculo y Alertas
Dentro del ciclo de procesamiento, ocurre la magia en tiempo real:

1.  **Cálculo Instantáneo de $dT/dt$:**
    *   El sistema mantiene un mapa en memoria RAM (`lastStates`) con la última lectura conocida de cada sensor.
    *   Al llegar un nuevo dato, calcula la diferencia con el anterior para obtener la **Tasa de Cambio** instantánea (`rate_of_change`).
    *   *Ventaja:* Este cálculo toma nanosegundos y no requiere consultas lentas a la base de datos.

2.  **Evaluación de Estado:**
    *   Compara la temperatura actual con los umbrales definidos (hardcoded para la simulación: -18°C para CF-1, etc.).
    *   Determina el estado: `NORMAL`, `ADVERTENCIA` o `CRÍTICO`.

3.  **Generación de Alertas (con Anti-Spam):**
    *   Si el estado es `CRÍTICO`, el sistema consulta otro mapa en memoria (`lastAlertTime`).
    *   **Regla de Negocio:** Solo se genera una nueva alerta en la base de datos si han pasado más de **2 minutos** desde la última alerta para ese sensor. Esto previene saturar la tabla `alerts` con mensajes repetidos cada 5 segundos.

### 3.3. Persistencia (Base de Datos)
El backend utiliza `database/sql` con el driver nativo de MySQL.
*   **Inserción:** Cada lectura se guarda en `temperature_readings`.
*   **Actualización:** Se actualiza el registro de la cámara en `chambers` para reflejar el estado actual ("Snapshot").

---

## 4. Modos de Operación
El comportamiento del backend se controla mediante la variable de entorno `SIMULATION_MODE` en el archivo `.env` o al ejecutar el comando.

| Modo | Valor Variable | Descripción | Uso Recomendado |
| :--- | :--- | :--- | :--- |
| **Random (Default)** | `RANDOM` | Los sensores generan variaciones térmicas aleatorias pequeñas (+/- 0.5°C). El sistema suele permanecer estable. | **Producción / Demo General** |
| **Scenario** | `SCENARIO` | Ejecuta un guion determinista. `CF-1` inicia crítico y se arregla. `CF-2` inicia bien y falla. | **Testing Automático / QA** |

---

## 5. API REST e Integración
El backend expone endpoints JSON en el puerto **8080**.

*   **Endpoints Directos (CRUD):**
    *   `GET /api/chambers`: Consulta rápida a MySQL.
    *   `GET /api/readings/{id}`: Historial reciente.
    *   `GET /api/alerts`: Notificaciones activas.

*   **Endpoints Proxy (Gateway):**
    *   `GET /api/reports/{id}`: **No procesa datos**. Recibe la petición y la reenvía internamente al microservicio de Python (Puerto 8000). Devuelve la respuesta de Python tal cual al cliente. Esto hace transparente para el Frontend el hecho de que existen dos servicios.

---

## 6. Comandos de Ejecución

**Instalar Dependencias:**
```bash
go mod tidy
```

**Iniciar Servidor (Modo Normal):**
```bash
go run cmd/server/main.go
```

**Iniciar Servidor (Modo Test de Escenarios):**

Cambiar la siguiente linea en el archivo **.env** de rukito-backend

```bash
 # Modos de Simulación: RANDOM (Producción) | SCENARIO (Testing)
SIMULATION_MODE=SCENARIO
```
