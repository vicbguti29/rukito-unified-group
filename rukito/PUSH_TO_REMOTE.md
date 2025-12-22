# Subir a Repositorio Remoto

Tu proyecto ya está en Git localmente. Ahora sube a GitHub, GitLab o Bitbucket.

---

## 🟢 Si usas GitHub

### 1. Crear repositorio en GitHub
- Ve a https://github.com/new
- Nombre: `rukito` o `rukito-frontend`
- Descripción: "Sistema de Monitoreo de Cadena de Frío - Frontend Flutter"
- **NO** inicializar con README (ya lo tenemos)
- Click "Create repository"

### 2. Agregar remoto y push
```bash
cd c:/Users/lenovo/rukito

# Reemplazar CON_TU_USUARIO
git remote add origin https://github.com/CON_TU_USUARIO/rukito.git

# Push al repositorio
git branch -M main
git push -u origin main
```

### 3. Verificar en GitHub
- Ve a https://github.com/CON_TU_USUARIO/rukito
- Deberías ver todos los archivos

---

## 🟠 Si usas GitLab

### 1. Crear repositorio en GitLab
- Ve a https://gitlab.com/projects/new
- Nombre: `rukito`
- Visibilidad: Private (si es proyecto universitario)
- Click "Create project"

### 2. Agregar remoto y push
```bash
cd c:/Users/lenovo/rukito

# Reemplazar CON_TU_USUARIO
git remote add origin https://gitlab.com/CON_TU_USUARIO/rukito.git

# Push
git branch -M main
git push -u origin main
```

---

## 🔵 Si usas Bitbucket

### 1. Crear repositorio en Bitbucket
- Ve a https://bitbucket.org/repo/create
- Nombre: `rukito`
- Access Level: Private
- Click "Create repository"

### 2. Agregar remoto y push
```bash
cd c:/Users/lenovo/rukito

# Reemplazar CON_TU_USUARIO
git remote add origin https://bitbucket.org/CON_TU_USUARIO/rukito.git

# Push
git branch -M main
git push -u origin main
```

---

## ✅ Verificar que funcionó

```bash
# Ver remoto
git remote -v

# Debería mostrar:
# origin  https://github.com/...
# origin  https://github.com/... (fetch)

# Ver log
git log --oneline
# Debería mostrar tu commit inicial
```

---

## 📋 Estructura que verá Angello

Cuando Angello clone el repo, verá:

```
rukito/
├── README.md                    # Instrucciones generales
├── QUICK_START.md              # Inicio rápido
├── API_SPECIFICATION.md         # ⭐ PARA ANGELLO
├── BACKEND_INTEGRATION.md       # ⭐ PARA ANGELLO
├── INSTRUCCIONES_COLABORACION.md
├── pubspec.yaml                # Dependencias Flutter
├── lib/                        # Código Flutter
└── .gitignore                  # Archivos ignorados
```

---

## 🤝 Invitar a Angello

Después de subir:

### En GitHub:
1. Ve a Settings → Collaborators
2. Agrega su email: Invita como Collaborator
3. Comparte el link del repo

### En GitLab:
1. Ve a Members → Add members
2. Busca a Angello
3. Dale acceso como Developer o Maintainer

### En Bitbucket:
1. Ve a Repository settings → User and group access
2. Agrega a Angello
3. Dale acceso como Developer

---

## 🔄 Workflow Colaborativo

Después que ambos tengan acceso:

```bash
# Victor (Frontend)
git clone https://github.com/CON_TU_USUARIO/rukito.git
cd rukito
flutter pub get
flutter run -d chrome

# Angello (Backend) - Crea repo separado para backend
git clone https://github.com/ANGELLO_USUARIO/rukito-backend.git
cd rukito-backend
go mod init github.com/ANGELLO_USUARIO/rukito-backend
```

---

## 📝 Commits Futuros

### Victor (Frontend)
```bash
git add lib/screens/views/dashboard_view.dart
git commit -m "feat(dashboard): improve loading animation"
git push origin main
```

### Angello (Backend - repo separado)
```bash
git add cmd/server/main.go
git commit -m "feat(api): implement GET /chambers endpoint"
git push origin main
```

---

## 🚫 No Subir

El `.gitignore` ya está configurado para NO incluir:
- `build/` - Archivos compilados
- `.dart_tool/` - Cache de Dart
- `pubspec.lock` - Se regenera automáticamente
- Archivos del IDE

---

## 💡 Tips

- **Commit messages**: Usar formato `feat()`, `fix()`, `docs()`
- **Branches**: Crear rama para cada feature: `git checkout -b feature/login`
- **Pull Requests**: Útiles para code review antes de merge

---

## ❓ Problemas al Push

### "Repository not found"
- Verificar URL del remoto: `git remote -v`
- Verificar credenciales de GitHub/GitLab
- Usar token en vez de password (GitHub requiere esto)

### "Please set your author identity"
Ya lo hicimos al inicio, pero si pide de nuevo:
```bash
git config --global user.name "Victor Borbor"
git config --global user.email "victor@ejemplo.com"
```

### "Permission denied (publickey)"
Usar HTTPS en vez de SSH:
```bash
git remote set-url origin https://github.com/usuario/rukito.git
```

---

**¡Listo!** Ahora puedes compartir el repo con Angello 🎉
