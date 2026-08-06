import httpx
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import Response

router = APIRouter()


@router.get("/image")
async def proxy_image(url: str = Query(..., description="URL de la imagen a proxear")):
    """Proxy de imágenes para evitar problemas de CORS con thumbnails de YouTube."""
    try:
        async with httpx.AsyncClient(follow_redirects=True, timeout=10.0) as client:
            response = await client.get(url)
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail="Error al obtener la imagen")

            content_type = response.headers.get("content-type", "image/jpeg")

            return Response(
                content=response.content,
                media_type=content_type,
                headers={
                    "Cache-Control": "public, max-age=86400",
                    "Access-Control-Allow-Origin": "*",
                },
            )
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Timeout al obtener la imagen")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al proxear imagen: {str(e)}")
