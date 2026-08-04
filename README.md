# MusicFinder 🎵

Buscador y descargador de música usando YouTube Music API.

## Estructura

```
musica/
├── backend/         # Python FastAPI
└── flutter_app/     # Flutter (Web + Android APK)
```

---

## 🖥️ Iniciar el Backend

### Pre-requisitos
```bash
sudo apt install python3-venv ffmpeg
```

### Iniciar
```bash
cd backend
./run.sh
```

El servidor quedará en: **http://localhost:8000**  
Documentación interactiva: **http://localhost:8000/docs**

---

## 📱 Ejecutar la App Flutter

### Pre-requisitos
- Flutter SDK instalado
- Para Android: Android SDK + emulador o dispositivo

### Desarrollo web
```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

### APK Android (emulador)
> Edita `lib/api/config.dart` y cambia `kBaseUrl` a `http://10.0.2.2:8000`

```bash
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

### APK Android (dispositivo físico, misma red)
> Edita `lib/api/config.dart` con la IP de tu PC: `http://192.168.X.X:8000`

---

## 🌐 Migrar a Hosting Externo (futuro)

1. Despliega el contenido de `backend/` en Railway/Render/VPS
2. Cambia `kBaseUrl` en `flutter_app/lib/api/config.dart`:
   ```dart
   const String kBaseUrl = 'https://tu-servidor.com';
   ```
3. Rebuild del APK

---

## Tecnologías
- **Frontend**: Flutter / Dart
- **Backend**: FastAPI (Python)
- **Búsqueda**: ytmusicapi (modo anónimo)
- **Descarga**: yt-dlp + ffmpeg
- **Diseño**: Tema oscuro premium, Inter font, glassmorphism
