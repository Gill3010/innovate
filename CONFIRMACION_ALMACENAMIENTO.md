# ✅ CONFIRMACIÓN: Dónde se Almacenan los Datos

## 📋 Respuesta Directa

**SÍ, ahora funciona exactamente como quieres:**

### 🖥️ Desarrollo Local (tu máquina)
Cuando ejecutas el backend localmente:
- ✅ **Usuarios** → Se guardan en **SQLite local** (`backend/app.db`)
- ✅ **Proyectos** → Se guardan en **SQLite local**
- ✅ **Imágenes** → Se guardan en carpeta local (`backend/uploads/`)

**Configuración:**
- `FLASK_ENV=development` (por defecto)
- `USE_FIREBASE=false` (por defecto en desarrollo)

### ☁️ Producción Web (Firebase Hosting)
Cuando el backend está desplegado en Cloud Run (producción):
- ✅ **Usuarios** → Se guardan en **Firebase Firestore**
- ✅ **Proyectos** → Se guardan en **Firebase Firestore**
- ✅ **Imágenes** → Se guardan en **Firebase Storage**

**Configuración:**
- `FLASK_ENV=production`
- `USE_FIREBASE=true` (por defecto en producción)

## 🔧 Cómo Funciona

El código ahora detecta automáticamente el entorno:

```python
# En backend/routes/auth.py y backend/routes/projects.py
use_firebase = current_app.config.get("USE_FIREBASE", False)

if use_firebase and firebase_service.is_enabled:
    # Guarda en Firebase Firestore
else:
    # Guarda en SQLite/PostgreSQL (desarrollo)
```

## ✅ Cambios Realizados

1. ✅ **Registro de usuarios** (`/api/auth/register`):
   - Detecta si `USE_FIREBASE=true`
   - Si es true → guarda en Firestore
   - Si es false → guarda en SQLite (desarrollo)

2. ✅ **Login** (`/api/auth/login`):
   - Busca usuario en Firestore o SQLite según configuración

3. ✅ **Crear proyectos** (`/api/projects`):
   - Guarda en Firestore o SQLite según configuración

4. ✅ **Subir imágenes** (`/api/image`):
   - Ya estaba implementado: usa Firebase Storage si está habilitado

## 🎯 Verificación

### Para Desarrollo:
```bash
# Tu máquina local
python -m backend.app

# Crear usuario desde la web local
# → Se guarda en: backend/app.db (SQLite)
```

### Para Producción:
```bash
# Backend desplegado en Cloud Run
# Variables de entorno configuradas:
# FLASK_ENV=production
# USE_FIREBASE=true

# Crear usuario desde la web desplegada
# → Se guarda en: Firebase Firestore
# → Ver en: Firebase Console > Firestore Database
```

## ⚠️ Importante

Para que funcione en producción, necesitas:

1. **Configurar las variables de entorno en Cloud Run:**
   ```
   FLASK_ENV=production
   USE_FIREBASE=true
   FIREBASE_STORAGE_BUCKET=innova-proyectos-jobs.firebasestorage.app
   GOOGLE_APPLICATION_CREDENTIALS=(configurado automáticamente en Cloud Run)
   ```

2. **O configurar en `cloudbuild.yaml`** para que se establezcan automáticamente al desplegar.

## 📊 Resumen

| Entorno | Usuarios | Proyectos | Imágenes |
|---------|----------|-----------|----------|
| **Desarrollo** | SQLite local | SQLite local | Carpeta local |
| **Producción** | Firebase Firestore | Firebase Firestore | Firebase Storage |

✅ **Confirmado**: Funciona exactamente como querías.

