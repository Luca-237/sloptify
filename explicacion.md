# Guía de Arquitectura y Código de Sloptify

Este documento explica la estructura del proyecto, la función de cada archivo y funciona como guía para futuros colaboradores sobre dónde y cómo hacer modificaciones.

El proyecto está dividido en dos partes principales:
1. **Backend (Python / FastAPI)**: Se encarga de buscar música y proveer el audio evitando bloqueos de CORS.
2. **Frontend (Flutter Web)**: La interfaz gráfica y reproductor.

---

## 1. Backend (`/backend`)

El backend actúa como un puente entre la aplicación y los servicios de YouTube Music, usando `ytmusicapi` para búsquedas y `yt-dlp` para descargas/streams.

### Archivos clave:
- **`main.py`**: El punto de entrada principal. Configura CORS (para permitir que Flutter se conecte) y registra todas las rutas (routers).
- **`requirements.txt`**: Las dependencias de Python (`fastapi`, `yt-dlp`, `ytmusicapi`, `httpx`, etc).

### Routers (`/backend/routers/`):
- **`search.py`**: Endpoints para buscar canciones, álbumes y artistas.
- **`album.py`**: Endpoint para obtener los detalles y la lista de canciones de un álbum en específico.
- **`stream.py`**: **[Core]** Es el proxy de streaming. En lugar de descargar la canción entera, extrae la URL de Google y la canaliza (pipe) al frontend en tiempo real. Esto permite reproducción instantánea y funciona con la barra de progreso (soporta peticiones Range).
- **`download.py`**: Se encarga de descargar la canción como archivo MP3 en el disco del servidor (usando ffmpeg) y proveerla al usuario para descarga.
- **`image_proxy.py`**: Resuelve el problema de CORS de las imágenes de YouTube, descargando las portadas en el servidor y enviándolas al frontend.

---

## 2. Frontend (`/flutter_app`)

Desarrollado en Flutter, utiliza `Riverpod` para la gestión de estados y `just_audio` para la reproducción de audio.

### Punto de Entrada y Configuración
- **`lib/main.dart`**: Inicia la aplicación y define la configuración general (ej. título de la app, `ProviderScope`).
- **`lib/theme/app_theme.dart`**: Contiene toda la paleta de colores (dark mode, accent colors) y la tipografía de la aplicación. **Modificar este archivo para cambiar el diseño general.**
- **`lib/api/config.dart`**: Define la URL del backend (`kBaseUrl`).

### Conexión con el Backend (`/lib/api/`)
- **`music_api.dart`**: Funciones HTTP para hablar con `search.py`, `album.py` y `download.py`.
- **`image_proxy.dart`**: Utilidad que convierte URLs de imágenes de YouTube para que pasen a través de nuestro `image_proxy.py`.

### Manejo de Estado / Reproductor (`/lib/providers/`)
- **`player_provider.dart`**: **[Core]** Este es el corazón de la aplicación. Mantiene el estado actual (`PlayerStateData`), la cola de canciones, la posición de reproducción, el volumen y se comunica con `just_audio`. Si querés cambiar cómo funciona el salto de canciones o la lógica de reproducción, es acá.

### Pantallas (`/lib/screens/`)
- **`home_screen.dart`**: Interfaz de inicio con la barra de búsqueda y filtros (Todo, Canciones, Álbumes).
- **`album_screen.dart`**: Pantalla de detalle de un álbum, donde se muestra su portada y la lista de reproducción.

### Componentes de UI (`/lib/widgets/`)
- **`main_layout.dart`**: Envoltura que divide la pantalla en dos: el contenido principal a la izquierda y el reproductor a la derecha.
- **`sidebar_player.dart`**: El panel lateral derecho. Contiene la portada gigante, los botones de anterior/play/siguiente y la barra de progreso. 
- **`download_button.dart` & `download_helper.dart`**: El botón que inicia la descarga y la lógica para descargar MP3 directamente en el navegador sin abrir pestañas.
- **`song_card.dart` & `album_card.dart`**: El diseño individual de cada "tarjetita" de canción o álbum en los resultados.

---

## ¿Dónde hacer cambios? (Casos de uso comunes)

1. **Quiero cambiar los colores o estilos visuales generales:**
   - Andá a `flutter_app/lib/theme/app_theme.dart` y modificá las constantes de la paleta.

2. **Quiero modificar el diseño de los controles del reproductor (botones de play/pausa, slider):**
   - Andá a `flutter_app/lib/widgets/sidebar_player.dart`.

3. **Quiero agregar la opción de "Modo Aleatorio (Shuffle)" o "Repetir":**
   - Lógica: `flutter_app/lib/providers/player_provider.dart` (agregar el estado y modificar la función `playNext`).
   - UI: `flutter_app/lib/widgets/sidebar_player.dart` (agregar los íconos de shuffle/repeat).

4. **Quiero agregar una nueva fuente de búsqueda de información (ej. letras de canciones):**
   - Backend: Creá un nuevo router en `backend/routers/lyrics.py` y registralo en `backend/main.py`.
   - Frontend: Agregá la llamada HTTP en `flutter_app/lib/api/music_api.dart` y mostrála en la UI creando un nuevo widget.

5. **El streaming de audio falla o está lento:**
   - Toda esa magia ocurre en `backend/routers/stream.py`. Ahí es donde se extrae la URL y se hace el *pipe* HTTP.

---
**Comando rápido para ejecutar todo el proyecto a la vez:** `./start.sh` (Levanta el entorno de Python, las dependencias y corre Flutter Web simultáneamente).
