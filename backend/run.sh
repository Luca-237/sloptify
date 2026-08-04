#!/bin/bash
# Script para iniciar el backend de Music API

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar si existe el entorno virtual
if [ ! -d "venv" ]; then
    echo "📦 Creando entorno virtual..."
    python3 -m venv venv
fi

# Activar entorno virtual
source venv/bin/activate

# Instalar/actualizar dependencias
echo "📥 Instalando dependencias..."
pip install -q -r requirements.txt

# Verificar ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "⚠️  ffmpeg no está instalado. Instálalo con: sudo apt install ffmpeg"
    exit 1
fi

# Crear carpeta de descargas si no existe
mkdir -p downloads

echo ""
echo "🎵 Iniciando Music API en http://localhost:8000"
echo "📖 Documentación disponible en http://localhost:8000/docs"
echo ""

uvicorn main:app --host 0.0.0.0 --port 8000 --reload
