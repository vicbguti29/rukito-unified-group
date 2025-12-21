# Quick Start - Rukito

Guía rápida para comenzar a trabajar.

---

## 🎯 Para Victor (Frontend)

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Ejecutar en navegador
```bash
flutter run -d chrome
```

### 3. Desarrollar con datos simulados
- El proyecto usa `MockApiService` por defecto
- No necesitas backend corriendo
- Los datos se cargan automáticamente

### 4. Conectar con backend (cuando esté listo)
Editar `lib/main.dart` línea 18:
```dart
// Cambiar de:
final IApiService apiService = MockApiService();

// A:
final IApiService apiService = ApiService();
```

Luego ejecutar el backend en otra terminal:
```bash
# Backend debe correr en http://localhost:8080/api
go run main.go
```

---

## 🔧 Para Angello (Backend)

### 1. Revisar especificación de API
Lee: `API_SPECIFICATION.md`

### 2. Crear estructura de proyecto Go
```bash
mkdir rukito-backend
cd rukito-backend
go mod init github.com/yourusername/rukito-backend
```

### 3. Implementar primeros endpoints
Empezar por:
- `GET /api/chambers`
- `GET /api/health`

### 4. Verificar que funciona
```bash
# Terminal 1: Backend
go run main.go

# Terminal 2: Test
curl http://localhost:8080/api/health
# Debe responder: {"status":"ok","timestamp":"..."}
```

### 5. Crear base de datos
Ver sección "Estructura de Base de Datos" en `BACKEND_INTEGRATION.md`

---

## 📝 Documentos Clave

| Documento | Para | Contenido |
|-----------|------|----------|
| `API_SPECIFICATION.md` | Ambos | Endpoints, request/response |
| `BACKEND_INTEGRATION.md` | Angello | Guía completa de backend |
| `INSTRUCCIONES_COLABORACION.md` | Ambos | Roles y responsabilidades |
| `ESPECIFICACIONES_PROTOTIPO.md` | Victor | Diseño y UX |
| `README.md` | Ambos | Información general |

---

## 🔗 Integración Paso a Paso

### Semana 1: Frontend corriendo
✅ Victor: `flutter run -d chrome` → Dashboard visible
✅ Angello: Setup Go + MySQL

### Semana 2: Backend con primeros endpoints
✅ Angello: GET `/chambers` y `/health` funcionan
✅ Victor: Sigue con MockApiService

### Semana 3: Integración
✅ Victor: Cambia a `ApiService()`
✅ Ambos: Testing integración
✅ Angello: Implementa más endpoints

### Semana 4+: Expansión
✅ Angello: Concurrencia, Python Analytics
✅ Victor: Pulir UI, testing, bugs

---

## 🧪 Verificar Integración

### 1. Backend Activo
```bash
curl http://localhost:8080/api/health
```
Respuesta esperada:
```json
{"status":"ok","timestamp":"2024-12-11T22:30:00Z"}
```

### 2. Frontend Conectado
- `flutter run -d chrome`
- Cambiar `ApiService()` en `main.dart`
- Dashboard debe mostrar datos

### 3. Todo funciona cuando:
- ✅ Dashboard carga cámaras
- ✅ Alertas se muestran
- ✅ Puedes cambiar vistas
- ✅ No hay errores en consola

---

## 🆘 Problemas Comunes

### Frontend no se ejecuta
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Backend no inicia
- Verificar MySQL corriendo
- Verificar puerto 8080 disponible
- Revisar variables de entorno (.env)

### API retorna 404
- Verificar URL en `AppConfig`
- Revisar ruta del endpoint
- Confirmar método HTTP (GET, POST, etc.)

### JSON error
- Verificar estructura en `API_SPECIFICATION.md`
- Usar herramienta online para validar JSON
- Revisar tipos de datos

---

## 📋 Checklist Inicial

### Victor
- [ ] `flutter pub get` ✅
- [ ] `flutter run -d chrome` ✅
- [ ] Dashboard se carga ✅
- [ ] Las 4 vistas funcionan ✅
- [ ] Lee `API_SPECIFICATION.md` ✅

### Angello
- [ ] Lee `API_SPECIFICATION.md` ✅
- [ ] Crea proyecto Go ✅
- [ ] Configura MySQL ✅
- [ ] Implementa `/health` ✅
- [ ] Implementa `/chambers` ✅

---

## 🚀 Next Steps

1. **Victor**: 
   - Pulir UI según `ESPECIFICACIONES_PROTOTIPO.md`
   - Agregar validaciones
   - Crear tests

2. **Angello**:
   - Implementar todos los endpoints
   - Crear base de datos
   - Implementar concurrencia

3. **Ambos**:
   - Reunión de integración
   - Testing end-to-end
   - Documentación final

---

## 📞 Help

Si algo no funciona:
1. Lee la documentación relevante
2. Revisa los logs (consola/terminal)
3. Contacta al otro integrante
4. Usa curl/Postman para debug

---

¡Buena suerte! 🎉
