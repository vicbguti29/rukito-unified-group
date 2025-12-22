# Rukito - Sistema de Monitoreo de Cadena de Frío

Aplicación móvil Flutter para monitoreo en tiempo real de cámaras frigoríficas en el restaurante Rukito.

## 📱 Características

- **Dashboard en Tiempo Real**: Visualización actualizada de todas las cámaras frigoríficas
- **Centro de Alertas**: Sistema de alertas prioritarias (P1, P2, P3)
- **Histórico de Temperaturas**: Análisis de datos históricos y tendencias
- **Reportes y Análisis**: KPIs y análisis detallado de riesgo
- **Configuración de Alertas**: Personalización de umbrales y prioridades

## 🛠️ Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── models/                   # Modelos de datos
│   ├── temperature_reading.dart
│   ├── alert.dart
│   ├── cold_chamber.dart
│   ├── alert_config.dart
│   └── index.dart
├── services/                 # Servicios API
│   ├── api_service.dart
│   └── index.dart
├── providers/                # Estado global (Provider)
│   ├── chamber_provider.dart
│   ├── alert_provider.dart
│   └── index.dart
├── screens/                  # Pantallas
│   ├── home_screen.dart
│   └── views/
│       ├── dashboard_view.dart
│       ├── alerts_view.dart
│       ├── historical_view.dart
│       └── reports_view.dart
├── widgets/                  # Componentes reutilizables
│   ├── chamber_card.dart
│   ├── alert_item.dart
│   ├── stats_card.dart
│   ├── temperature_chart.dart
│   └── index.dart
└── theme/                    # Tema y colores
    └── app_colors.dart
```

## 🚀 Instalación y Setup

### Requisitos
- Flutter SDK 3.0.0+
- Dart 3.0.0+
- Android SDK o Xcode

### Pasos

1. **Clonar el repositorio**
   ```bash
   git clone <repo-url>
   cd rukito
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Ejecutar en desarrollo**
   ```bash
   flutter run
   ```

4. **Compilar para producción**
   ```bash
   # Android
   flutter build apk --split-per-abi

   # iOS
   flutter build ios
   ```

## 📋 Configuración API

Editar `lib/services/api_service.dart`:

```dart
static const String _baseUrl = 'http://localhost:8080/api'; // Cambiar a URL del backend
```

## 🎨 Temas y Colores

Los colores están centralizados en `lib/theme/app_colors.dart`:

- **Crítico**: #e74c3c (Rojo)
- **Advertencia**: #f39c12 (Naranja)
- **Normal**: #2ecc71 (Verde)
- **Info**: #3498db (Azul)

## 📊 Vistas Principales

### 1. Dashboard
- Tarjetas de cámaras con temperatura en tiempo real
- Mini gráficos de histórico
- Estadísticas generales

### 2. Centro de Alertas
- Lista de alertas ordenadas por prioridad
- Marcar como leídas
- Información detallada de cada alerta

### 3. Histórico
- Filtro por fecha y cámara
- Tabla de datos históricos
- Análisis de tendencias

### 4. Reportes
- KPIs de los últimos 30 días
- Análisis de riesgos
- Estadísticas de uptime

## 🔌 Integración con Backend

El frontend consume la API REST del backend Go:

### Endpoints usados:

```
GET /api/chambers                  # Obtener todas las cámaras
GET /api/chambers/{id}             # Obtener una cámara
GET /api/readings/{id}             # Obtener lecturas recientes
GET /api/readings/{id}/history     # Obtener histórico
GET /api/alerts                    # Obtener alertas
GET /api/alerts/chamber/{id}       # Obtener alertas de cámara
PATCH /api/alerts/{id}/read        # Marcar alerta como leída
GET /api/config/alerts/{id}        # Obtener config de alertas
PUT /api/config/alerts/{id}        # Actualizar config
GET /api/reports/{id}              # Obtener reportes
GET /api/statistics                # Obtener estadísticas
GET /api/health                    # Health check
```

## 🧪 Testing

```bash
# Ejecutar tests unitarios
flutter test

# Ejecutar con cobertura
flutter test --coverage
```

## 📱 Responsive Design

La aplicación está optimizada para:
- **Desktop**: 1920x1080
- **Tablet**: 768-1024px
- **Mobile**: 375-480px

## 🔐 Seguridad

- ✅ Validación de entrada de datos
- ✅ HTTPS para comunicación API
- ✅ Almacenamiento local seguro con `shared_preferences`
- ✅ Manejo de errores y excepciones

## 🐛 Troubleshooting

### Error: "Failed to connect to API"
- Verificar que el backend esté corriendo
- Revisar la URL base en `api_service.dart`
- Comprobar firewall y conectividad de red

### Error: "Null safety issues"
- Ejecutar `flutter clean` y `flutter pub get`
- Analizar código: `flutter analyze`

## 📝 Notas para Desarrollo

### Próximas Mejoras
- [ ] Animaciones de transición mejoradas
- [ ] WebSocket para actualizaciones en tiempo real
- [ ] Notificaciones push nativas
- [ ] Offlining y sincronización
- [ ] Gráficos interactivos con fl_chart

### Dependencias Futuras
- `fl_chart`: Gráficos avanzados
- `web_socket_channel`: WebSocket en tiempo real
- `firebase_messaging`: Notificaciones push
- `sqflite`: Base de datos local

## 👥 Responsables

- **Frontend (Flutter/Dart)**: Víctor Borbor

## 📄 Licencia

Proprietary - Rukito

## 📞 Contacto

Para reportar issues o sugerencias, contactar al equipo de desarrollo.
