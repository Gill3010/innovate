# Configuración de Firebase para Desarrollo y Producción

Este documento explica cómo configurar Firebase para que funcione en ambos entornos: desarrollo (local) y producción (Firebase).

## Arquitectura de Entornos

- **Desarrollo (Local)**: Usa SQLite local y almacenamiento de archivos local
- **Producción (Firebase)**: Usa Firestore para base de datos y Firebase Storage para imágenes

## Paso 1: Habilitar Firestore y Storage en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: `innova-proyectos-jobs`
3. En el menú lateral, ve a **Firestore Database**
   - Haz clic en "Crear base de datos"
   - Elige el modo de producción (con reglas de seguridad)
   - Selecciona una ubicación (recomendado: `us-central1`)
4. Ve a **Storage**
   - Haz clic en "Comenzar"
   - Acepta las reglas de seguridad por defecto

## Paso 2: Desplegar Reglas de Seguridad

Las reglas de seguridad ya están configuradas en los archivos del proyecto:

```bash
# Desplegar reglas de Firestore
firebase deploy --only firestore:rules

# Desplegar reglas de Storage
firebase deploy --only storage:rules

# Desplegar índices de Firestore (si es necesario)
firebase deploy --only firestore:indexes
```

## Paso 3: Configurar Credenciales para el Backend

Para que el backend pueda usar Firebase Admin SDK en producción, necesitas:

### Opción A: Usar Service Account Key (Desarrollo/Testing)

1. En Firebase Console, ve a **Configuración del proyecto** > **Cuentas de servicio**
2. Haz clic en "Generar nueva clave privada"
3. Guarda el archivo JSON (ej: `firebase-service-account.json`)
4. **NO** subas este archivo al repositorio. Agréguelo a `.gitignore`
5. Configura la variable de entorno:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/firebase-service-account.json"
```

### Opción B: Application Default Credentials (Cloud Run/Production)

En producción (Cloud Run, Cloud Functions, etc.), puedes usar Application Default Credentials automáticamente. Solo asegúrate de que el servicio tenga los permisos necesarios.

## Paso 4: Variables de Entorno del Backend

### Desarrollo (Local)
```bash
FLASK_ENV=development
USE_FIREBASE=false  # Usa SQLite local
DATABASE_URL=sqlite:///app.db
```

### Producción
```bash
FLASK_ENV=production
USE_FIREBASE=true
FIREBASE_STORAGE_BUCKET=innova-proyectos-jobs.firebasestorage.app
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
# O en Cloud Run, no necesitas GOOGLE_APPLICATION_CREDENTIALS
```

## Paso 5: Configurar Flutter App

### Desarrollo (Local)
Por defecto, la app detecta automáticamente el entorno:
- En modo debug (`flutter run`): Usa backend local
- En modo release (`flutter build`): Usa producción

### Producción
Para construir para producción, puedes especificar variables:

```bash
# Build para web (producción)
flutter build web --release --dart-define=API_BASE_URL=https://tu-backend-url.com
```

O usa la URL de producción del backend que ya está desplegado.

## Paso 6: Migración de Datos (Opcional)

Si tienes datos en SQLite local que quieres migrar a Firestore, puedes crear un script de migración:

```python
# backend/migrate_to_firebase.py
# Este script leería de SQLite y escribiría a Firestore
```

## Estructura de Datos en Firestore

### Colección `users`
```json
{
  "email": "user@example.com",
  "name": "Usuario",
  "bio": "...",
  "title": "...",
  "avatar_url": "...",
  "portfolio_share_token": "...",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Colección `projects`
```json
{
  "user_id": 123,
  "title": "...",
  "description": "...",
  "technologies": "...",
  "images": "[url1, url2]",
  "links": "[url1, url2]",
  "category": "...",
  "featured": false,
  "share_token": "...",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## Verificación

1. **Desarrollo**: 
   - Ejecuta el backend local
   - Verifica que los datos se guardan en SQLite
   - Las imágenes se guardan en `backend/uploads/`

2. **Producción**:
   - Despliega el backend con `USE_FIREBASE=true`
   - Verifica en Firebase Console que los datos aparecen en Firestore
   - Verifica en Storage que las imágenes se suben correctamente

## Troubleshooting

### Error: "Firebase Admin SDK no se puede inicializar"
- Verifica que `GOOGLE_APPLICATION_CREDENTIALS` apunta a un archivo válido
- En producción, verifica que el servicio tiene permisos de Service Account

### Error: "Permiso denegado en Firestore"
- Verifica que las reglas de seguridad están desplegadas
- Revisa las reglas en `firestore.rules`

### Las imágenes no se suben a Firebase Storage
- Verifica que `FIREBASE_STORAGE_BUCKET` está configurado correctamente
- Verifica las reglas de Storage en `storage.rules`

## Próximos Pasos

1. ✅ Firestore configurado
2. ✅ Firebase Storage configurado
3. ⏭️ Configurar Firebase Authentication (siguiente paso)
4. ⏭️ Integrar Firebase Auth con el backend
5. ⏭️ Actualizar las rutas del backend para usar Firestore en producción

