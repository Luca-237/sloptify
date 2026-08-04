from fastapi import APIRouter, HTTPException, Query
from ytmusicapi import YTMusic
from typing import Optional

router = APIRouter()

# Modo anónimo — sin autenticación
yt = YTMusic()


def _extract_thumbnail(thumbnails: list) -> Optional[str]:
    """Obtiene la URL del thumbnail de mayor resolución."""
    if not thumbnails:
        return None
    # Ordenar por resolución (width * height) y devolver el mayor
    sorted_thumbs = sorted(thumbnails, key=lambda t: t.get("width", 0) * t.get("height", 0), reverse=True)
    return sorted_thumbs[0].get("url")


def _safe_artist_name(artists) -> str:
    """Extrae nombre de artistas de forma segura."""
    if not artists:
        return "Desconocido"
    if isinstance(artists, list):
        return ", ".join(a.get("name", "") for a in artists if a.get("name"))
    return str(artists)


@router.get("/songs")
def search_songs(q: str = Query(..., description="Término de búsqueda")):
    """Busca canciones en YouTube Music."""
    try:
        results = yt.search(q, filter="songs", limit=25)
        songs = []
        for item in results:
            songs.append({
                "videoId": item.get("videoId"),
                "title": item.get("title", "Sin título"),
                "artist": _safe_artist_name(item.get("artists")),
                "album": item.get("album", {}).get("name") if item.get("album") else None,
                "duration": item.get("duration"),
                "thumbnail": _extract_thumbnail(item.get("thumbnails", [])),
                "type": "song",
            })
        return {"results": songs, "count": len(songs)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/albums")
def search_albums(q: str = Query(..., description="Término de búsqueda")):
    """Busca álbumes en YouTube Music."""
    try:
        results = yt.search(q, filter="albums", limit=20)
        albums = []
        for item in results:
            albums.append({
                "browseId": item.get("browseId"),
                "title": item.get("title", "Sin título"),
                "artist": _safe_artist_name(item.get("artists")),
                "year": item.get("year"),
                "thumbnail": _extract_thumbnail(item.get("thumbnails", [])),
                "type": "album",
            })
        return {"results": albums, "count": len(albums)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/artists")
def search_artists(q: str = Query(..., description="Término de búsqueda")):
    """Busca artistas en YouTube Music."""
    try:
        results = yt.search(q, filter="artists", limit=15)
        artists = []
        for item in results:
            artists.append({
                "browseId": item.get("browseId"),
                "name": item.get("artist", item.get("title", "Desconocido")),
                "thumbnail": _extract_thumbnail(item.get("thumbnails", [])),
                "type": "artist",
            })
        return {"results": artists, "count": len(artists)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/all")
def search_all(q: str = Query(..., description="Término de búsqueda")):
    """Búsqueda general: canciones, álbumes y artistas."""
    try:
        results = yt.search(q, limit=20)
        items = []
        for item in results:
            result_type = item.get("resultType", "unknown")
            base = {
                "type": result_type,
                "thumbnail": _extract_thumbnail(item.get("thumbnails", [])),
            }
            if result_type == "song":
                base.update({
                    "videoId": item.get("videoId"),
                    "title": item.get("title", "Sin título"),
                    "artist": _safe_artist_name(item.get("artists")),
                    "album": item.get("album", {}).get("name") if item.get("album") else None,
                    "duration": item.get("duration"),
                })
            elif result_type == "album":
                base.update({
                    "browseId": item.get("browseId"),
                    "title": item.get("title", "Sin título"),
                    "artist": _safe_artist_name(item.get("artists")),
                    "year": item.get("year"),
                })
            elif result_type == "artist":
                base.update({
                    "browseId": item.get("browseId"),
                    "name": item.get("artist", item.get("title", "Desconocido")),
                })
            items.append(base)
        return {"results": items, "count": len(items)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
