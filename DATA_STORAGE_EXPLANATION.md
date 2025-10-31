# 📍 Dónde se Almacenan los Datos - Explicación

## Situación Actual

Cuando creaste el usuario desde la web, **se guardó en SQLite local**, no en Firebase. Por eso no lo ves en la consola de Firebase.

## ¿Por qué está en SQLite y no en Firebase?

Por diseño, el proyecto tiene **dos entornos**:

### 🖥️ Desarrollo (Local)
- **Base de datos**: SQLite (`backend/app.db`)
- **Almacenamiento de imágenes**: Carpeta local (`backend/uploads/`)
- **Configuración**: `USE_FIREBASE=false` (por defecto en desarrollo)
- **Ventaja**: Rápido para desarrollo, no requiere configuración de Firebase

### ☁️ Producción (Firebase)
- **Base de datos**: Firestore (Firebase)
- **Almacenamiento de imágenes**: Firebase Storage
- **Configuración**: `USE_FIREBASE=true` (en producción)
- **Ventaja**: Escalable, accesible desde cualquier lugar

## 📂 Dónde Ver tus Datos Actuales

### Ver Usuarios en SQLite Local

Ejecuta este comando desde la raíz del proyecto:

```bash
python3 backend/view_users.py
```

O directamente desde SQLite:

```bash
cd backend
sqlite3 app.db "SELECT id, email, name, created_at FROM users;"
```

### Ver el Archivo de Base de Datos

El archivo está en:
```
/Users/israelsamuels/innovate/backend/app.db
```

Puedes abrirlo con cualquier visor de SQLite:
- **DB Browser for SQLite** (app de macOS)
- **TablePlus** (app de macOS)
- Línea de comandos con `sqlite3`

## 🔄 Cómo Cambiar para Usar Firebase

Si quieres que los usuarios se guarden en Firebase **ahora mismo** (aunque estés en desarrollo):

### Paso 1: Configurar Variables de Entorno

Crea o edita el archivo `.env` en la raíz del proyecto:

```bash
# .env
USE_FIREBASE=true
FIREBASE_STORAGE_BUCKET=innova-proyectos-jobs.firebasestorage.app
GOOGLE_APPLICATION_CREDENTIALS=/ruta/a/firebase-service-account.json
```

### Paso 2: Obtener Credenciales de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: `innova-proyectos-jobs`
3. Ve a **Configuración del proyecto** > **Cuentas de servicio**
4. Haz clic en "Generar nueva clave privada"
5. Descarga el archivo JSON
6. Guarda la ruta en `GOOGLE_APPLICATION_CREDENTIALS`

### Paso 3: Reiniciar el Backend

```bash
# Detén el servidor (Ctrl+C)
# Vuelve a iniciarlo
python -m backend.app
```

### Paso 4: Verificar

1. Crea un nuevo usuario desde la web
2. Ve a Firebase Console > Firestore Database
3. Deberías ver el usuario en la colección `users`

## 📊 Comparación: SQLite vs Firestore

| Aspecto | SQLite (Desarrollo) | Firestore (Producción) |
|---------|---------------------|------------------------|
| **Ubicación** | Archivo local `app.db` | Nube (Firebase) |
| **Acceso** | Solo desde tu máquina | Desde cualquier lugar |
| **Configuración** | Automática | Requiere credenciales |
| **Escalabilidad** | Limitada | Alta |
| **Costo** | Gratis | Gratis hasta cierto límite |
| **Para ver datos** | Script local o DB Browser | Firebase Console |

## 🔍 Ver Datos en Firebase Console

Cuando uses Firebase, puedes ver los datos aquí:

1. **Firestore Database**: 
   - Ve a [Firebase Console](https://console.firebase.google.com/)
   - Selecciona tu proyecto
   - Ve a **Firestore Database** en el menú lateral
   - Verás las colecciones: `users`, `projects`, etc.

2. **Storage**:
   - En el mismo proyecto
   - Ve a **Storage** en el menú lateral
   - Verás las carpetas: `uploads/`, `avatars/`

## ⚠️ Importante

- **Los datos en SQLite NO se migran automáticamente a Firebase**
- Si cambias de SQLite a Firebase, los usuarios existentes en SQLite permanecerán ahí
- Para migrar datos, necesitarías crear un script de migración

## 🎯 Recomendación

Para desarrollo local, **mantén SQLite**:
- ✅ Más rápido
- ✅ No requiere configuración
- ✅ Funciona offline
- ✅ Perfecto para pruebas

Para producción, **usa Firebase**:
- ✅ Escalable
- ✅ Accesible desde la app desplegada
- ✅ Backup automático
- ✅ Integrado con Firebase Hosting

---

## Comandos Útiles

```bash
# Ver usuarios en SQLite
python3 backend/view_users.py

# Ver tablas en SQLite
sqlite3 backend/app.db ".tables"

# Ver estructura de la tabla users
sqlite3 backend/app.db ".schema users"

# Ver todos los usuarios con más detalle
sqlite3 backend/app.db "SELECT * FROM users;"
```

