# 🔒 Seguridad: Desarrollo vs Producción

## ✅ **SÍ puedes desarrollar sin afectar producción**

Tu proyecto está configurado de forma **completamente separada**. Aquí te explico cómo:

---

## 🔄 **Separación de Entornos**

### **1. Desarrollo Local (Tu Máquina)**

**Configuración automática:**
- `FLASK_ENV=development` (por defecto)
- `USE_FIREBASE=false` (por defecto en desarrollo)
- **Base de datos:** SQLite local (`backend/app.db`)
- **Imágenes:** Carpeta local (`backend/uploads/`)
- **Backend:** `http://127.0.0.1:8000`

**Qué significa:**
- ✅ Todos los usuarios/proyectos que crees se guardan **SOLO en tu máquina**
- ✅ Las imágenes se guardan **SOLO en tu máquina**
- ✅ **NO se conecta a Firebase** a menos que lo configures explícitamente
- ✅ **NO puede afectar** la base de datos de producción (`innovate` en Firestore)

### **2. Producción (Web Desplegada)**

**Configuración automática:**
- `FLASK_ENV=production`
- `USE_FIREBASE=true` (configurado en `cloudbuild.yaml`)
- **Base de datos:** Firestore (`innovate` database)
- **Imágenes:** Firebase Storage
- **Backend:** Cloud Run (URL de producción)

**Qué significa:**
- ✅ Todos los usuarios/proyectos se guardan en **Firebase**
- ✅ Las imágenes se guardan en **Firebase Storage**
- ✅ **NO se conecta** a tu base de datos local
- ✅ **NO puede afectar** tu entorno de desarrollo

---

## 🛡️ **Qué Puede Afectar Producción**

### **❌ NO afecta producción (seguro hacerlo localmente):**

1. ✅ **Modificar código
2. ✅ **Crear/eliminar usuarios/proyectos localmente**
3. ✅ **Agregar/eliminar imágenes localmente**
4. ✅ **Cambiar la base de datos SQLite local**
5. ✅ **Modificar archivos de código** (hasta que despliegues)

### **⚠️ SÍ afecta producción (solo cuando despliegues):**

1. ⚠️ **Desplegar cambios de código** (cuando ejecutas `./scripts/deploy_backend.sh` o haces push a la rama que activa Cloud Build)
2. ⚠️ **Cambiar variables de entorno en Cloud Run** (como `USE_FIREBASE`, `OPENAI_API_KEY`, etc.)
3. ⚠️ **Desplegar el frontend** (cuando ejecutas `firebase deploy`)

---

## 🔍 **Cómo Verificar tu Entorno Actual**

### **En el Backend (Terminal donde corre Flask):**

```bash
# Verifica qué entorno estás usando
python -c "import os; print('FLASK_ENV:', os.getenv('FLASK_ENV', 'development'))"
python -c "import os; print('USE_FIREBASE:', os.getenv('USE_FIREBASE', 'false'))"
```

**Resultado esperado en desarrollo:**
```
FLASK_ENV: development
USE_FIREBASE: false  (o vacío)
```

### **En el Código (Backend):**

El backend verifica automáticamente:
```python
# En backend/config.py
def get_config():
    env = os.getenv("FLASK_ENV", "development").lower()
    if env == "production":
        return ProductionConfig  # → USE_FIREBASE=true por defecto
    return DevelopmentConfig     # → USE_FIREBASE=false por defecto
```

### **En el Frontend (Flutter):**

```dart
// En lib/core/environment.dart
static bool get isDevelopment {
  return kDebugMode;  // true cuando ejecutas 'flutter run'
}

static bool get useFirebase {
  if (isDevelopment) {
    return false;  // En desarrollo, NO usa Firebase
  }
  return true;  // En producción (release), usa Firebase
}
```

---

## 🎯 **Guía de Buenas Prácticas**

### **✅ Para Desarrollo Local:**

1. **No configures `USE_FIREBASE=true` en tu `.env` local**
   - Déjalo como `USE_FIREBASE=false` o simplemente no lo pongas

2. **Verifica que estás usando el backend local**
   - Flutter en desarrollo apunta a `http://127.0.0.1:8000`
   - Si el backend no está corriendo localmente, la app no funcionará (lo cual es correcto)

3. **Experimenta libremente**
   - Puedes borrar `backend/app.db` y `backend/uploads/` cuando quieras
   - Esto NO afecta producción en absoluto

### **⚠️ Antes de Desplegar a Producción:**

1. **Prueba localmente primero**
   - Asegúrate de que todo funciona en desarrollo

2. **Revisa los cambios**
   - Usa `git diff` para ver qué has cambiado
   - Si cambias algo relacionado con Firebase, verifica que funcione

3. **Despliega conscientemente**
   - Solo despliega cuando estés seguro
   - Los despliegues se hacen con `./scripts/deploy_backend.sh` o push a la rama que activa Cloud Build

---

## 📊 **Resumen Visual**

```
┌─────────────────────────────────────────────────────────┐
│  TU MÁQUINA (DESARROLLO)                                 │
├─────────────────────────────────────────────────────────┤
│  ✅ FLASK_ENV=development                               │
│  ✅ USE_FIREBASE=false                                   │
│  ✅ SQLite: backend/app.db                               │
│  ✅ Imágenes: backend/uploads/                           │
│  ✅ Backend: http://127.0.0.1:8000                       │
│                                                          │
│  🔒 NO puede acceder a Firebase de producción            │
│  🔒 Cambios locales NO afectan producción                │
└─────────────────────────────────────────────────────────┘

                    ⬇️ (Solo cuando despliegues)

┌─────────────────────────────────────────────────────────┐
│  PRODUCCIÓN (WEB)                                        │
├─────────────────────────────────────────────────────────┤
│  ✅ FLASK_ENV=production                                 │
│  ✅ USE_FIREBASE=true                                    │
│  ✅ Firestore: innovate database                         │
│  ✅ Imágenes: Firebase Storage                           │
│  ✅ Backend: Cloud Run (URL producción)                  │
│                                                          │
│  🔒 NO puede acceder a tu base de datos local            │
│  🔒 Cambios de producción NO afectan desarrollo          │
└─────────────────────────────────────────────────────────┘
```

---

## 🚨 **Señales de Alerta**

**Si ves alguna de estas señales, detente y verifica:**

1. ❌ El backend local intenta conectarse a Firebase cuando no debería
   - **Solución:** Verifica que `USE_FIREBASE=false` en tu entorno local

2. ❌ La app local intenta conectarse a la URL de producción
   - **Solución:** Verifica que estás en modo desarrollo (`flutter run` sin `--release`)

3. ❌ Ves datos de producción en tu entorno local
   - **Solución:** Esto NO debería pasar. Si pasa, hay un problema de configuración

---

## ✅ **Conclusión**

**Puedes desarrollar con total libertad:**
- ✅ Modifica el código todo lo que necesites
- ✅ Crea/elimina datos localmente sin preocupación
- ✅ Experimenta con nuevas características
- ✅ **NO afectará producción** hasta que despliegues explícitamente

**Producción está protegida:**
- 🔒 Usa Firebase (Firestore + Storage)
- 🔒 Está en Cloud Run
- 🔒 Tiene sus propias variables de entorno
- 🔒 **NO puede verse afectada** por tus cambios locales

---

## 💡 **Recomendación Final**

**Para mayor seguridad, agrega esto a tu `.env` local:**

```bash
# .env (archivo local, NO subir a git)
FLASK_ENV=development
USE_FIREBASE=false
```

Así te aseguras de que siempre uses el entorno local, incluso si accidentalmente cambias algo en el código.

---

**Última actualización:** $(date)
**Configuración verificada:** ✅ Separación completa de entornos

