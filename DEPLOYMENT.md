# Guía de Despliegue - Innova Proyectos & Jobs

## 📋 Requisitos Previos

1. Cuenta de Google Cloud Platform activa
2. Proyecto Firebase: `innova-proyectos-jobs` (✅ Ya configurado)
3. Google Cloud CLI instalado: `gcloud`
4. Docker instalado (opcional, para pruebas locales)

## 🚀 Paso 1: Configurar Google Cloud

### 1.1 Inicializar Google Cloud

```bash
# Iniciar sesión
gcloud auth login

# Configurar proyecto
gcloud config set project innova-proyectos-jobs

# Habilitar APIs necesarias
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

## 🗄️ Paso 2: Crear Base de Datos PostgreSQL (Cloud SQL)

### 2.1 Crear instancia de Cloud SQL

```bash
# Crear instancia PostgreSQL
gcloud sql instances create innova-db \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=us-central1 \
    --root-password=YOUR_STRONG_PASSWORD_HERE \
    --storage-type=SSD \
    --storage-size=10GB

# Crear base de datos
gcloud sql databases create innovadb --instance=innova-db

# Crear usuario de aplicación
gcloud sql users create innovaapp \
    --instance=innova-db \
    --password=YOUR_APP_PASSWORD_HERE
```

### 2.2 Obtener nombre de conexión

```bash
gcloud sql instances describe innova-db --format="value(connectionName)"
# Resultado: innova-proyectos-jobs:us-central1:innova-db
```

## 🔐 Paso 3: Configurar Variables de Entorno

### 3.1 Generar JWT Secret

```bash
# Generar un secreto aleatorio seguro
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

### 3.2 Preparar variables de entorno

Crea un archivo `backend/.env.cloud` con:

```env
DATABASE_URL=postgresql://innovaapp:YOUR_APP_PASSWORD_HERE@/innovadb?host=/cloudsql/innova-proyectos-jobs:us-central1:innova-db
JWT_SECRET_KEY=<resultado_del_paso_anterior>
OPENAI_API_KEY=<tu_openai_api_key>
ADZUNA_APP_ID=<tu_adzuna_app_id>
ADZUNA_API_KEY=<tu_adzuna_api_key>
FLASK_ENV=production
DEBUG=False
```

## 🐳 Paso 4: Construir y Desplegar Backend

### 4.1 Construir imagen Docker localmente (opcional para pruebas)

```bash
cd /Users/israelsamuels/innovate

# Construir imagen
docker build -t innova-backend .

# Probar localmente
docker run -p 8080:8080 --env-file backend/.env.cloud innova-backend
```

### 4.2 Desplegar en Cloud Run

```bash
# Construir y desplegar en un solo comando
gcloud run deploy innova-backend \
    --source . \
    --region=us-central1 \
    --platform=managed \
    --allow-unauthenticated \
    --add-cloudsql-instances=innova-proyectos-jobs:us-central1:innova-db \
    --set-env-vars="^@^DATABASE_URL=postgresql://innovaapp:YOUR_APP_PASSWORD@/innovadb?host=/cloudsql/innova-proyectos-jobs:us-central1:innova-db@JWT_SECRET_KEY=YOUR_JWT_SECRET@OPENAI_API_KEY=YOUR_OPENAI_KEY@ADZUNA_APP_ID=YOUR_ADZUNA_ID@ADZUNA_API_KEY=YOUR_ADZUNA_KEY@FLASK_ENV=production@DEBUG=False" \
    --max-instances=10 \
    --memory=512Mi \
    --timeout=300 \
    --port=8080

# Obtener URL del servicio desplegado
gcloud run services describe innova-backend --region=us-central1 --format="value(status.url)"
```

La URL será algo como: `https://innova-backend-xxxxx-uc.a.run.app`

### 4.3 Inicializar base de datos

```bash
# Una vez desplegado, crear las tablas
curl -X POST https://innova-backend-xxxxx-uc.a.run.app/api/health
```

## 📱 Paso 5: Configurar Flutter con URL de Producción

### 5.1 Actualizar API Client

Edita `lib/core/api_client.dart`:

```dart
static String _resolveDefaultBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  
  // URL de producción
  const prodUrl = 'https://innova-backend-xxxxx-uc.a.run.app';
  if (!kDebugMode) return prodUrl; // Producción
  
  // Desarrollo local
  if (kIsWeb) return 'http://127.0.0.1:8000';
  try {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  } catch (_) {}
  return 'http://127.0.0.1:8000';
}
```

O mejor, usa variables de entorno al construir:

## 📦 Paso 6: Construir APK/AAB para Android

### 6.1 Preparar para producción

```bash
cd /Users/israelsamuels/innovate

# Actualizar versión en pubspec.yaml si es necesario
# version: 1.0.0+1

# Obtener dependencias
flutter pub get

# Limpiar build anterior
flutter clean
```

### 6.2 Construir APK (para pruebas/distribución manual)

```bash
# APK de producción con URL del backend
flutter build apk --release \
    --dart-define=API_BASE_URL=https://innova-backend-xxxxx-uc.a.run.app

# El APK estará en: build/app/outputs/flutter-apk/app-release.apk
```

### 6.3 Construir AAB (para Google Play Store)

```bash
# Primero, necesitas configurar signing key
# Genera keystore
keytool -genkey -v -keystore ~/innova-key.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias innova

# Crear android/key.properties
# storePassword=<password>
# keyPassword=<password>
# keyAlias=innova
# storeFile=/Users/israelsamuels/innova-key.jks

# Construir AAB
flutter build appbundle --release \
    --dart-define=API_BASE_URL=https://innova-backend-xxxxx-uc.a.run.app

# El AAB estará en: build/app/outputs/bundle/release/app-release.aab
```

## 🍎 Paso 7: Construir para iOS (opcional)

```bash
# Desde macOS
flutter build ios --release \
    --dart-define=API_BASE_URL=https://innova-backend-xxxxx-uc.a.run.app

# Abrir en Xcode para firmar y distribuir
open ios/Runner.xcworkspace
```

## ✅ Paso 8: Verificación

### 8.1 Probar backend

```bash
# Health check
curl https://innova-backend-xxxxx-uc.a.run.app/api/health

# Probar registro
curl -X POST https://innova-backend-xxxxx-uc.a.run.app/api/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"test123","name":"Test User"}'
```

### 8.2 Probar APK

```bash
# Instalar en dispositivo conectado
adb install build/app/outputs/flutter-apk/app-release.apk

# O compartir el APK para instalación manual
```

## 🔧 Configuración de Signing para Android

### Configurar android/app/build.gradle.kts

Añade antes de `android {}`:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Dentro de `android {}`, añade:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        // ... resto de configuración
    }
}
```

## 📊 Monitoreo

### Ver logs de Cloud Run

```bash
# Logs en tiempo real
gcloud run services logs tail innova-backend --region=us-central1

# Logs recientes
gcloud run services logs read innova-backend --region=us-central1 --limit=100
```

### Ver métricas

```bash
# Abrir consola de Cloud Run
gcloud run services browse innova-backend --region=us-central1
```

## 🔄 Actualizaciones

Para actualizar el backend:

```bash
# Hacer cambios en el código
# Luego redesplegar
gcloud run deploy innova-backend \
    --source . \
    --region=us-central1

# La URL no cambia, solo se actualiza el servicio
```

## 💰 Costos Estimados

- **Cloud Run**: ~$0 - $5/mes (nivel gratuito: 2M requests/mes)
- **Cloud SQL (f1-micro)**: ~$7/mes
- **Cloud Storage**: ~$0.02/GB/mes
- **Total estimado**: $7-12/mes para tráfico bajo

## 🆘 Troubleshooting

### Error: "Connection refused" en Cloud SQL

```bash
# Verificar que Cloud SQL está activo
gcloud sql instances list

# Verificar conexión
gcloud sql connect innova-db --user=postgres
```

### Error: "Image not found"

```bash
# Reconstruir con Cloud Build explícitamente
gcloud builds submit --tag gcr.io/innova-proyectos-jobs/innova-backend
```

### APK no instala

```bash
# Verificar firma
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

## 📝 Notas Importantes

1. **Seguridad**: Nunca commitas `key.properties` o `.env.cloud` a Git
2. **Backups**: Cloud SQL hace backups automáticos, pero verifica la configuración
3. **SSL**: Cloud Run proporciona SSL automáticamente
4. **Dominios**: Puedes mapear un dominio personalizado en Cloud Run
5. **Escalado**: Cloud Run escala automáticamente de 0 a N instancias

## 🎉 ¡Listo!

Tu aplicación ya está desplegada y lista para usuarios reales.

**URLs importantes:**
- Backend: `https://innova-backend-xxxxx-uc.a.run.app`
- Firebase Console: https://console.firebase.google.com/project/innova-proyectos-jobs
- Cloud Console: https://console.cloud.google.com/
