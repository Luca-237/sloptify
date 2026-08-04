import asyncio
import httpx
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
import yt_dlp

router = APIRouter()

def _get_stream_url(video_id: str) -> str:
    url = f"https://music.youtube.com/watch?v={video_id}"
    ydl_opts = {
        "format": "bestaudio/best",
        "quiet": True,
        "no_warnings": True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        return info['url']

async def fetch_audio_stream(url: str):
    async with httpx.AsyncClient() as client:
        async with client.stream("GET", url) as response:
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail="Error al obtener el stream de YouTube")
            async for chunk in response.aiter_bytes(chunk_size=65536):
                yield chunk

@router.get("/{video_id}")
async def stream_audio(video_id: str):
    try:
        loop = asyncio.get_event_loop()
        stream_url = await loop.run_in_executor(None, _get_stream_url, video_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener URL del stream: {str(e)}")

    return StreamingResponse(fetch_audio_stream(stream_url), media_type="audio/webm")
