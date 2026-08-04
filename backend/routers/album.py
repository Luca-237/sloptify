from fastapi import APIRouter, HTTPException, Path
from ytmusicapi import YTMusic
from typing import Optional

router = APIRouter()
yt = YTMusic()


def _extract_thumbnail(thumbnails: list) -> Optional[str]:
    if not thumbnails:
        return None
    sorted_thumbs = sorted(thumbnails, key=lambda t: t.get("width", 0) * t.get("height", 0), reverse=True)
    return sorted_thumbs[0].get("url")


def _safe_artist_name(artists) -> str:
    if not artists:
        return "Desconocido"
    if isinstance(artists, list):
        return ", ".join(a.get("name", "") for a in artists if a.get("name"))
    return str(artists)


@router.get("/{browse_id}")
def get_album(browse_id: str = Path(..., description="browseId del álbum")):
    """Devuelve el detalle completo de un álbum: info + tracklist."""
    try:
        album = yt.get_album(browse_id)
        if not album:
            raise HTTPException(status_code=404, detail="Álbum no encontrado")

        tracks = []
        for track in album.get("tracks", []):
            tracks.append({
                "videoId": track.get("videoId"),
                "title": track.get("title", "Sin título"),
                "artist": _safe_artist_name(track.get("artists")),
                "duration": track.get("duration"),
                "trackNumber": track.get("trackNumber"),
                "thumbnail": _extract_thumbnail(track.get("thumbnails", [])),
            })

        return {
            "browseId": browse_id,
            "title": album.get("title", "Sin título"),
            "artist": _safe_artist_name(album.get("artists")),
            "year": album.get("year"),
            "description": album.get("description"),
            "trackCount": album.get("trackCount"),
            "duration": album.get("duration"),
            "thumbnail": _extract_thumbnail(album.get("thumbnails", [])),
            "tracks": tracks,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
