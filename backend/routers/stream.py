import os
import re
import asyncio
import time
from fastapi import APIRouter, HTTPException, Request, Response
from fastapi.responses import StreamingResponse, FileResponse
import yt_dlp
import httpx

router = APIRouter()

# Cache de URLs directas para evitar llamar a yt-dlp repetidas veces por la misma canción
# Estructura: { "video_id": {"url": "...", "expires_at": 12345678} }
URL_CACHE = {}
URL_CACHE_TTL = 3600  # 1 hora

def _extract_direct_url(video_id: str) -> str:
    """Extrae la URL directa del stream de audio usando yt-dlp (sin descargar)."""
    ydl_opts = {
        "format": "bestaudio/best",
        "quiet": True,
        "no_warnings": True,
    }
    url = f"https://music.youtube.com/watch?v={video_id}"
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        return info['url']

async def _get_cached_url(video_id: str) -> str:
    now = time.time()
    if video_id in URL_CACHE and URL_CACHE[video_id]["expires_at"] > now:
        return URL_CACHE[video_id]["url"]

    loop = asyncio.get_event_loop()
    try:
        url = await loop.run_in_executor(None, _extract_direct_url, video_id)
        URL_CACHE[video_id] = {"url": url, "expires_at": now + URL_CACHE_TTL}
        return url
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obteniendo URL: {str(e)}")

@router.get("/file/{video_id}")
async def proxy_stream(video_id: str, request: Request):
    """
    Actúa como un proxy de streaming.
    Obtiene la URL directa y canaliza el stream HTTP, soportando headers Range nativamente.
    Esto permite inicio instantáneo y seek sin tener que descargar el archivo entero.
    """
    direct_url = await _get_cached_url(video_id)

    # Reenviar headers clave (especialmente Range para permitir seek en el reproductor)
    req_headers = {}
    range_header = request.headers.get("Range")
    if range_header:
        req_headers["Range"] = range_header

    client = httpx.AsyncClient()
    
    # We must use httpx.stream to avoid downloading the entire file into memory
    req = client.build_request("GET", direct_url, headers=req_headers)
    
    try:
        yt_response = await client.send(req, stream=True)
    except Exception as e:
        await client.aclose()
        raise HTTPException(status_code=500, detail=f"Error conectando al stream: {str(e)}")

    resp_headers = {}
    for k, v in yt_response.headers.items():
        if k.lower() in ("content-type", "content-length", "content-range", "accept-ranges"):
            resp_headers[k] = v
            
    resp_headers["Access-Control-Allow-Origin"] = "*"

    async def stream_generator():
        try:
            async for chunk in yt_response.aiter_bytes(chunk_size=65536):
                yield chunk
        finally:
            await yt_response.aclose()
            await client.aclose()

    return StreamingResponse(
        stream_generator(),
        status_code=yt_response.status_code,
        headers=resp_headers,
        media_type=resp_headers.get("Content-Type", "audio/webm")
    )

@router.get("/url/{video_id}")
async def get_stream_url(video_id: str):
    """Devuelve la URL de nuestro propio proxy de stream."""
    return {"url": f"/stream/file/{video_id}"}
