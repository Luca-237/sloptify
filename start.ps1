# start.ps1
$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n  Sloptify" -ForegroundColor Cyan
Write-Host "  Iniciando backend + frontend en Windows...`n" -ForegroundColor White

# Verificaciones
function Check-Command {
    param ($CmdName)
    $cmd = Get-Command $CmdName -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return $false
    }
    return $true
}

if (-not (Check-Command "python")) {
    Write-Host "[X] python no encontrado. Por favor, instala Python 3 (y asegúrate de agregarlo al PATH)." -ForegroundColor Red
    exit 1
}

if (-not (Check-Command "flutter")) {
    Write-Host "[X] flutter no encontrado. Por favor, instala Flutter (y asegúrate de agregarlo al PATH)." -ForegroundColor Red
    exit 1
}

# ffmpeg
if (-not (Check-Command "ffmpeg")) {
    Write-Host "[!] ffmpeg no encontrado. Considera instalarlo si hay problemas con audio/video." -ForegroundColor Yellow
}

# 1. BACKEND
Write-Host "`n[1/2] Backend (FastAPI)" -ForegroundColor Cyan
Set-Location "$RootDir\backend"

if (-not (Test-Path "venv\Scripts\activate.ps1")) {
    Write-Host "  [+] Creando entorno virtual..." -ForegroundColor White
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[X] Error al crear el entorno virtual." -ForegroundColor Red
        exit 1
    }
}

Write-Host "  [+] Instalando dependencias..." -ForegroundColor White
& ".\venv\Scripts\python.exe" -m pip install -q -r requirements.txt

if (-not (Test-Path "downloads")) {
    New-Item -ItemType Directory -Path "downloads" | Out-Null
}

Write-Host "  [>] Iniciando en http://localhost:8000" -ForegroundColor Green
$BackendJob = Start-Process -FilePath ".\venv\Scripts\uvicorn.exe" -ArgumentList "main:app --host 0.0.0.0 --port 8000 --reload" -PassThru -WindowStyle Minimized

Start-Sleep -Seconds 3
Write-Host "  [OK] Backend corriendo (PID: $($BackendJob.Id))" -ForegroundColor Green

# 2. FLUTTER WEB
Write-Host "`n[2/2] Frontend (Flutter Web)" -ForegroundColor Cyan
Set-Location "$RootDir\flutter_app"

Write-Host "  [+] Obteniendo paquetes..." -ForegroundColor White
flutter pub get

Write-Host "  [>] Iniciando Flutter web en puerto 3000..." -ForegroundColor Green
Write-Host "  [i] Podes presionar 'r' en esta terminal para hacer Hot Reload." -ForegroundColor Yellow
Write-Host "`n  [API] Backend API:   http://localhost:8000"
Write-Host "  [WEB] Flutter Web:   http://localhost:3000 (Abrilo en tu navegador)"
Write-Host "  Para detener todo, presiona Ctrl+C en esta consola.`n" -ForegroundColor Yellow

try {
    # Ejecutamos en foreground
    flutter run -d web-server --web-port=3000
} finally {
    Write-Host "`n[!] Deteniendo servicios..." -ForegroundColor Yellow
    if ($BackendJob -and -not $BackendJob.HasExited) {
        Stop-Process -Id $BackendJob.Id -Force -ErrorAction SilentlyContinue
        Write-Host "  [X] Backend detenido" -ForegroundColor Red
    }
    Write-Host "[OK] Todo limpio. Hasta la proxima!" -ForegroundColor Green
}
