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

# 1. BACKEND (Comentado porque estás usando Render)
Write-Host "`n[1/2] Backend (Render)`n  Usando backend remoto de Render. No se inicia localmente." -ForegroundColor Cyan

# 2. FLUTTER WEB
Write-Host "`n[2/2] Frontend (Flutter Web)" -ForegroundColor Cyan
Set-Location "$RootDir\flutter_app"

Write-Host "  [+] Obteniendo paquetes..." -ForegroundColor White
flutter pub get

Write-Host "  [>] Iniciando Flutter web en puerto 3000..." -ForegroundColor Green
Write-Host "  [i] Podes presionar 'r' en esta terminal para hacer Hot Reload." -ForegroundColor Yellow
Write-Host "`n  [API] Backend API:   https://sloptify.onrender.com (Remoto)"
Write-Host "  [WEB] Flutter Web:   http://localhost:3000 (Abrilo en tu navegador)"
Write-Host "  Para detener todo, presiona Ctrl+C en esta consola.`n" -ForegroundColor Yellow

try {
    # Ejecutamos en foreground
    flutter run -d web-server --web-port=3000
} finally {
    Write-Host "`n[!] Deteniendo servicios..." -ForegroundColor Yellow
    Write-Host "[OK] Todo limpio. Hasta la proxima!" -ForegroundColor Green
}
