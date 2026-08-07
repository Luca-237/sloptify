import os
import re
import asyncio
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import yt_dlp

router = APIRouter()

DOWNLOADS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "downloads")
os.makedirs(DOWNLOADS_DIR, exist_ok=True)


class DownloadRequest(BaseModel):
    videoId: str
    title: str = "audio"
    artist: str = "Unknown"


def _sanitize_filename(name: str) -> str:
    """Elimina caracteres no válidos para nombres de archivo."""
    name = re.sub(r'[\\/*?:"<>|]', "", name)
    return name.strip()[:100]


@router.post("")
async def download_song(req: DownloadRequest):
    """
    Descarga una canción de YouTube como MP3 usando yt-dlp.
    Devuelve la URL de descarga del archivo generado.
    """
    if not req.videoId:
        raise HTTPException(status_code=400, detail="videoId es requerido")

    safe_title = _sanitize_filename(req.title)
    safe_artist = _sanitize_filename(req.artist)
    filename = f"{safe_title} - {safe_artist}.mp3"
    output_path = os.path.join(DOWNLOADS_DIR, filename)

    # Si ya existe, devolver directamente
    if os.path.exists(output_path):
        return {
            "status": "ready",
            "filename": filename,
            "downloadUrl": f"/download/file/{filename}",
        }

    url = f"https://music.youtube.com/watch?v={req.videoId}"

    ydl_opts = {
        "format": "bestaudio/best",
        "outtmpl": os.path.join(DOWNLOADS_DIR, f"{safe_title} - {safe_artist}.%(ext)s"),
        "postprocessors": [
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "192",
            }
        ],
        "quiet": True,
        "no_warnings": True,
        "retries": 3,
        "socket_timeout": 30,
        "geo_bypass": True,
        "nocheckcertificate": True,
    }

    try:
        # Ejecutar yt-dlp en un thread separado para no bloquear el event loop
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, _run_download, url, ydl_opts)

        if not os.path.exists(output_path):
            raise HTTPException(status_code=500, detail="El archivo no fue generado correctamente")

        return {
            "status": "ready",
            "filename": filename,
            "downloadUrl": f"/download/file/{filename}",
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al descargar: {str(e)}")


def _run_download(url: str, ydl_opts: dict):
    """Ejecuta yt-dlp de forma síncrona."""
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])


@router.get("/file/{filename}")
def serve_file(filename: str):
    """Sirve el archivo MP3 para descarga directa."""
    filepath = os.path.join(DOWNLOADS_DIR, filename)
    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Archivo no encontrado")
    return FileResponse(
        filepath,
        media_type="audio/mpeg",
        filename=filename,
    )


@router.delete("/file/{filename}")
def delete_file(filename: str):
    """Elimina un archivo descargado (limpieza opcional)."""
    filepath = os.path.join(DOWNLOADS_DIR, filename)
    if os.path.exists(filepath):
        os.remove(filepath)
        return {"status": "deleted"}
    return {"status": "not_found"}
