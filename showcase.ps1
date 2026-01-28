# Showcase Script for Rukito
# Inicia todos los servicios necesarios para una demostración

Write-Host "🚀 Iniciando Entorno de Demostración Rukito..." -ForegroundColor Cyan

# 1. Iniciar Backend Go
Write-Host "📦 Iniciando Servidor Go (Puerto 8080)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd rukito-backend; go run cmd/server/main.go"

# 2. Iniciar Analytics Python
Write-Host "🧠 Iniciando Servicio de Analítica (Puerto 8000)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd rukito-backend/analytics; venv/Scripts/activate; uvicorn main:app --port 8000"

# 3. Lanzar Frontend (Usando el servidor de desarrollo o el build web)
Write-Host "📱 Lanzando Frontend Flutter..." -ForegroundColor Yellow
Start-Process "http://localhost:8080" # El servidor Go suele servir el index o proxy

Write-Host "✅ Todo en marcha. ¡Disfruta de la demo!" -ForegroundColor Green
