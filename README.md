# Innova - Portafolio & Jobs App

Aplicación móvil Flutter para gestión de portafolio profesional y búsqueda de empleos.

## 🚀 Inicio Rápido

### Desarrollo Local

```bash
# Instalar dependencias
flutter pub get

# Iniciar backend (en otra terminal)
cd backend
AUTO_CREATE_DB=true python -m backend.app

# Ejecutar app
flutter run
```

### Despliegue a Producción

Ver guía completa en [`QUICKSTART.md`](./QUICKSTART.md).

```bash
# 1. Desplegar backend
./scripts/deploy_backend.sh

# 2. Construir APK
./scripts/build_apk.sh <URL_DEL_BACKEND>
```

## 📁 Estructura del Proyecto

```
innovate/
├── lib/                          # Código Flutter
│   ├── core/                     # API client, utils
│   ├── features/                 # Features de la app
│   │   ├── auth/                 # Autenticación
│   │   ├── portfolio/            # Gestión de portafolio
│   │   ├── jobs/                 # Búsqueda de empleos
│   │   └── ai/                   # Asistente IA
│   └── main.dart                 # Entry point
├── backend/                      # Backend Flask
│   ├── routes/                   # API endpoints
│   ├── models.py                 # Modelos SQLAlchemy
│   └── app.py                    # App Flask
├── android/                      # Configuración Android
├── ios/                          # Configuración iOS
├── scripts/                      # Scripts de despliegue
│   ├── deploy_backend.sh         # Despliega backend a Cloud Run
│   ├── build_apk.sh              # Construye APK de producción
│   └── setup_android_signing.sh  # Configura signing
├── Dockerfile                    # Para Cloud Run
├── QUICKSTART.md                 # Guía rápida
└── DEPLOYMENT.md                 # Guía completa
```

## ✨ Características

### 📱 App Móvil

- ✅ Autenticación con JWT
- ✅ Gestión de portafolio profesional
- ✅ Subida de imágenes y proyectos
- ✅ Búsqueda de empleos (Adzuna, Remotive, RemoteOK, etc.)
- ✅ Compartir portafolio vía QR/URL
- ✅ Asistente IA para consejos de carrera
- ✅ Favoritos y filtros
- ✅ Soporte iOS y Android

### 🔧 Backend

- ✅ Flask + PostgreSQL
- ✅ Rate limiting
- ✅ Caching
- ✅ APIs de empleo integradas
- ✅ OpenAI integration
- ✅ Listo para Cloud Run

## 🛠️ Stack Tecnológico

- **Frontend**: Flutter 3.32.5 / Dart 3.8+
- **Backend**: Flask 3.0 / Python 3.11
- **Base de datos**: PostgreSQL 15
- **Cloud**: Google Cloud Run + Cloud SQL
- **Storage**: Local (puede migrar a Firebase Storage)

## 📖 Documentación

- [`QUICKSTART.md`](./QUICKSTART.md) - Despliegue en 30 minutos
- [`DEPLOYMENT.md`](./DEPLOYMENT.md) - Guía completa de despliegue
- `lib/README.md` - Documentación del código Flutter

## 🔐 Configuración

### Variables de Entorno (Backend)

```env
DATABASE_URL=postgresql://user:pass@host/db
JWT_SECRET_KEY=tu_secret_key
OPENAI_API_KEY=sk-...
ADZUNA_APP_ID=...
ADZUNA_API_KEY=...
```

### Build Flags (Flutter)

```bash
# Desarrollo
flutter run

# Producción con URL custom
flutter build apk --dart-define=API_BASE_URL=https://tu-backend.com
```

## 🧪 Testing

```bash
# Backend
cd backend
pytest

# Flutter
flutter test
```

## 📦 Build

### Android APK

```bash
flutter build apk --release --dart-define=API_BASE_URL=<backend_url>
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=<backend_url>
```

### iOS

```bash
flutter build ios --release --dart-define=API_BASE_URL=<backend_url>
```

## 🚀 Despliegue

### Backend (Cloud Run)

```bash
./scripts/deploy_backend.sh
```

### App (APK)

```bash
./scripts/build_apk.sh <backend_url>
```

## 💰 Costos

Estimación mensual para tráfico bajo-medio:

- Cloud Run: $0-5/mes
- Cloud SQL (f1-micro): $7/mes
- **Total**: ~$7-12/mes

## 🤝 Contribuir

1. Fork el proyecto
2. Crea tu feature branch (`git checkout -b feature/amazing`)
3. Commit tus cambios (`git commit -m 'Add amazing feature'`)
4. Push al branch (`git push origin feature/amazing`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es privado.

## 👤 Autor

**Israel Samuels**
- Director de desarrollo y Operaciones - Innova Proyectos

## 🆘 Soporte

- 📧 Email: tu@email.com
- 📱 Issues: [GitHub Issues](https://github.com/tu-usuario/innovate/issues)

---

**Estado del Proyecto**: ✅ Listo para producción

**Última actualización**: Octubre 2025
