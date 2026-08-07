from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from routers import search, album, download, stream, image_proxy

app = FastAPI(
    title="Music Search & Downloader API",
    description="Busca canciones con ytmusicapi y descarga MP3 con yt-dlp",
    version="1.0.0",
)

# CORS — permite Flutter web y app Android local
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Servir archivos MP3 descargados
DOWNLOADS_DIR = os.path.join(os.path.dirname(__file__), "downloads")
os.makedirs(DOWNLOADS_DIR, exist_ok=True)
app.mount("/downloads", StaticFiles(directory=DOWNLOADS_DIR), name="downloads")

# Registrar routers
app.include_router(search.router, prefix="/search", tags=["Search"])
app.include_router(album.router, prefix="/album", tags=["Album"])
app.include_router(download.router, prefix="/download", tags=["Download"])
app.include_router(stream.router, prefix="/stream", tags=["Stream"])
app.include_router(image_proxy.router, prefix="/proxy", tags=["Proxy"])


@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "message": "Music API is running 🎵"}
