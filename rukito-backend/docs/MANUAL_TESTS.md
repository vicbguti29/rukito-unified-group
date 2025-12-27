# Manual de Pruebas y Validación (Test Suite)

## 1. Introducción
Rukito cuenta con una suite de pruebas automatizada basada en scripts de Bash y verificaciones con `curl` y Python. Estas pruebas cubren desde la disponibilidad básica de los servicios hasta la lógica de negocio compleja.

Todos los scripts se encuentran en la raíz de `rukito-backend/`.

---

## 2. Scripts de Prueba

### 2.1. `test_endpoints.sh` (Pruebas CRUD)
*   **Objetivo:** Verificar que la API REST de Go responde correctamente a todas las operaciones de lectura y escritura.
*   **Alcance:**
    *   Health Check.
    *   Listado de Cámaras y Lecturas.
    *   Lectura y Actualización de Configuraciones.
    *   Gestión de Alertas.
*   **Ejecución:** `./test_endpoints.sh`
*   **Señal de Éxito:** JSONs válidos en la salida de cada paso.

### 2.2. `test_integration_basics.sh` (Ping entre Servicios)
*   **Objetivo:** Confirmar que ambos microservicios (Go y Python) están activos y pueden comunicarse (o al menos coexistir).
*   **Alcance:**
    *   Verifica puerto 8080 (Go).
    *   Verifica puerto 8000 (Python).
    *   Verifica que Python puede leer la BD y generar un reporte básico.
*   **Ejecución:** `./test_integration_basics.sh`
*   **Señal de Éxito:** Tres checks verdes (✅) indicando "ONLINE".

### 2.3. `test_scenarios.sh` (Prueba E2E de Alertas)
*   **Objetivo:** Validar el motor de reglas de negocio y la detección de alertas en tiempo real.
*   **Requisito:** El servidor Go debe iniciarse en modo escenario: `export SIMULATION_MODE=SCENARIO && go run ...`
*   **Lógica:**
    1.  Toma una muestra inicial (T=0).
    2.  Espera 25 segundos mientras el simulador ejecuta su guion interno.
    3.  Verifica que `CF-1` pasó de Crítico a Normal.
    4.  Verifica que `CF-2` pasó de Normal a Crítico.
    5.  Confirma que se generó un registro en la tabla `alerts`.
*   **Señal de Éxito:** "✅ Alerta CF-1 Detectada".

### 2.4. `test_analytics_integration.sh` (Cadena de Valor Completa)
*   **Objetivo:** Validar la precisión matemática del módulo de Analítica.
*   **Flujo Probado:**
    1.  Ejecuta `scraper.py` -> Genera CSV de precios.
    2.  Llama a la API de Análisis.
    3.  Verifica que `estimated_cost` > 0 (usando los precios del CSV).
*   **Interpretación de Resultados:**
    *   Muestra el contexto (Inventario 200kg, Regla 4 horas).
    *   Valida que el cálculo final tenga sentido financiero.
*   **Señal de Éxito:** "✅ ÉXITO: El sistema calculó un costo financiero...".

---

## 3. Matriz de Errores Comunes

| Síntoma | Causa Probable | Solución |
| :--- | :--- | :--- |
| **Connection Refused (8080)** | El servidor Go no está corriendo. | Ejecutar `go run cmd/server/main.go`. |
| **Connection Refused (8000)** | El servidor Python no está corriendo. | Ejecutar `uvicorn main:app` en `analytics/`. |
| **Error: Unsupported operand type** | Python viejo en memoria. | Reiniciar `uvicorn` tras cambios de código. |
| **Costo Estimado = 0** | No hubo alertas en los últimos 30 min. | Ejecutar primero una prueba que genere alertas (Escenario) o esperar. |
| **Database connection failed** | Credenciales incorrectas en `.env`. | Revisar usuario/password de MySQL. |

---

## 4. Flujo de Trabajo Recomendado para Desarrollo

1.  Hacer cambios en el código (Go o Python).
2.  Reiniciar el servicio correspondiente.
3.  Ejecutar `test_integration_basics.sh` para verificar que levanta.
4.  Si tocaste lógica de negocio, ejecutar `test_analytics_integration.sh`.
