#!/bin/bash
# ============================================================
#  Sloptify — Start Script
#  Levanta backend + frontend con un solo comando
# ============================================================

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── PIDs para cleanup ───────────────────────────────────────
BACKEND_PID=""
FLUTTER_PID=""

cleanup() {
    echo ""
    echo -e "${YELLOW}⏹  Deteniendo servicios...${NC}"
    [ -n "$BACKEND_PID" ] && kill "$BACKEND_PID" 2>/dev/null && echo -e "   ${RED}■${NC} Backend detenido"
    [ -n "$FLUTTER_PID" ] && kill "$FLUTTER_PID" 2>/dev/null && echo -e "   ${RED}■${NC} Flutter detenido"
    wait 2>/dev/null
    echo -e "${GREEN}✔  Todo limpio. ¡Hasta la próxima! 🎵${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# ── Banner ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}"
echo "  Sloptify"
echo -e "${NC}"
echo -e "${BOLD}  Iniciando backend + frontend...${NC}"
echo ""

# ── Verificar pre-requisitos ────────────────────────────────
# Agregar ruta manual de Flutter en caso de que no esté en el PATH global
export PATH="$PATH:$HOME/Escritorio/flutter/bin"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✖  python3 no encontrado. Instalalo primero.${NC}"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✖  flutter no encontrado. Instalalo primero.${NC}"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}⚠  ffmpeg no encontrado. Instalalo con: sudo apt install ffmpeg${NC}"
    exit 1
fi

# ══════════════════════════════════════════════════════════════
#  1. BACKEND
# ══════════════════════════════════════════════════════════════
echo -e "${CYAN}[1/2]${NC} ${BOLD}Backend (FastAPI)${NC}"

cd "$ROOT_DIR/backend"

# Crear venv si no existe
if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
    echo -e "  📦 Creando entorno virtual..."
    rm -rf venv 2>/dev/null
    if ! python3 -m venv venv; then
        echo -e "${RED}✖  Error al crear el entorno virtual.${NC}"
        echo -e "${YELLOW}   Es probable que necesites instalar python3-venv.${NC}"
        echo -e "${YELLOW}   Ejecutá: sudo apt install python3-venv (o python3.13-venv)${NC}"
        exit 1
    fi
fi

# Activar e instalar deps
source venv/bin/activate
echo -e "  📥 Instalando dependencias..."
pip install -q -r requirements.txt

mkdir -p downloads

echo -e "  ${GREEN}▶${NC}  Iniciando en ${BOLD}http://localhost:8000${NC}"
uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

# Esperar a que el backend esté listo
echo -ne "  ⏳ Esperando al backend"
for i in $(seq 1 15); do
    if curl -s http://localhost:8000/ > /dev/null 2>&1; then
        echo -e "\r  ${GREEN}✔${NC}  Backend listo                "
        break
    fi
    echo -n "."
    sleep 1
done

# ══════════════════════════════════════════════════════════════
#  2. FLUTTER WEB
# ══════════════════════════════════════════════════════════════
echo -e "${CYAN}[2/2]${NC} ${BOLD}Frontend (Flutter Web)${NC}"

cd "$ROOT_DIR/flutter_app"

echo -e "  📥 Obteniendo paquetes..."
flutter pub get --suppress-analytics > /dev/null 2>&1

echo -e "  ${GREEN}▶${NC}  Iniciando Flutter web en puerto 3000..."
echo -e "  ${YELLOW}ℹ️  El primer inicio puede tardar unos segundos en compilar.${NC}"
echo -e "  ${YELLOW}ℹ️  Podés presionar 'r' en esta terminal para hacer Hot Reload.${NC}"
echo ""
echo -e "  🖥️  Backend API:   ${BOLD}http://localhost:8000${NC}"
echo -e "  🌐  Flutter Web:   ${BOLD}http://localhost:3000${NC} (Abrilo en tu navegador)"
echo -e "  ${YELLOW}Ctrl+C para detener todo${NC}"
echo ""

# Correr flutter en foreground para permitir hot reload
flutter run -d web-server --web-port=3000 --suppress-analytics
