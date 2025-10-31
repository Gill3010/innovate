# 🎯 Guía Paso a Paso: Crear Firestore y Storage

He intentado crear Firestore y Storage automáticamente, pero requieren habilitar APIs primero y algunos pasos interactivos. Te guío para hacerlo manualmente (es rápido, 5 minutos).

## 🔧 Paso 1: Habilitar APIs (ya lo intenté hacer por ti)

Si las APIs ya están habilitadas, continúa. Si no, ejecuta:

```bash
gcloud services enable firestore.googleapis.com storage-component.googleapis.com --project=innova-proyectos-jobs
```

## 📋 Paso 2: Crear Firestore Database

**Tiempo estimado: 2 minutos**

1. **Abre Firebase Console**
   - Ve a: https://console.firebase.google.com/project/innova-proyectos-jobs/firestore
   - O ve a [Firebase Console](https://console.firebase.google.com/) → Selecciona tu proyecto → Firestore Database

2. **Si ves "Crear base de datos" o "Crear una base de datos":**
   - Haz clic en el botón
   - Selecciona **"Iniciar en modo de producción"** (modo con reglas de seguridad)
   - Ubicación: Selecciona **`us-central1 (Iowa)`** (recomendado)
   - Haz clic en **"Habilitar"** o **"Crear"**

3. **Espera a que termine la creación** (30-60 segundos)

4. **✅ Listo**: Verás la interfaz de Firestore con la base de datos creada

---

## 📦 Paso 3: Crear Firebase Storage

**Tiempo estimado: 2 minutos**

1. **Abre Firebase Storage**
   - Ve a: https://console.firebase.google.com/project/innova-proyectos-jobs/storage
   - O en Firebase Console → Storage (en el menú lateral)

2. **Si ves "Comenzar" o "Iniciar":**
   - Haz clic en el botón
   - Selecciona **"Iniciar en modo de producción"** (modo con reglas de seguridad)
   - Ubicación: Usa la misma que Firestore si es posible (`us-central1`)
   - Haz clic en **"Listo"** o **"Crear"**

3. **Espera a que termine la creación** (30-60 segundos)

4. **✅ Listo**: Verás la interfaz de Storage con el bucket creado

---

## 🔒 Paso 4: Desplegar Reglas de Seguridad (Opcional pero Recomendado)

**Tiempo estimado: 1 minuto**

Ejecuta estos comandos desde la raíz del proyecto:

```bash
# Desplegar reglas de Firestore
firebase deploy --only firestore:rules

# Desplegar reglas de Storage
firebase deploy --only storage:rules
```

**¿Qué hacen estas reglas?**
- Permiten que usuarios autenticados creen y modifiquen sus propios datos
- Protegen contra acceso no autorizado
- Ya están configuradas en los archivos `firestore.rules` y `storage.rules`

---

## ✅ Verificación Final

Después de completar los pasos, ejecuta:

```bash
./verificar_firebase.sh
```

O verifica manualmente:
- Firestore: https://console.firebase.google.com/project/innova-proyectos-jobs/firestore
- Storage: https://console.firebase.google.com/project/innova-proyectos-jobs/storage

---

## 🚀 Después de Esto

Una vez completados estos pasos:

1. ✅ **Despliega el backend** con Cloud Build (como lo has estado haciendo)
2. ✅ **Los usuarios nuevos** se crearán automáticamente en Firestore
3. ✅ **Los proyectos nuevos** se guardarán en Firestore
4. ✅ **Las imágenes** se subirán a Firebase Storage
5. ✅ **Todo funcionará** como esperas

---

## 🆘 Si Tienes Problemas

### Error: "API no habilitada"
Ejecuta:
```bash
gcloud services enable firestore.googleapis.com storage-component.googleapis.com --project=innova-proyectos-jobs
```

### Error: "Permiso denegado"
Asegúrate de estar autenticado:
```bash
gcloud auth login
firebase login
```

### No puedes acceder a Firebase Console
Asegúrate de tener acceso al proyecto `innova-proyectos-jobs` en Firebase.

---

## 📊 Resumen Rápido

| Paso | Acción | Tiempo | Estado |
|------|--------|--------|--------|
| 1 | Habilitar APIs | 1 min | ⚠️ Puede requerir ejecutar comando |
| 2 | Crear Firestore | 2 min | ❌ Necesitas hacerlo |
| 3 | Crear Storage | 2 min | ❌ Necesitas hacerlo |
| 4 | Desplegar reglas | 1 min | ⚠️ Opcional pero recomendado |

**Total: ~5 minutos**

---

## 💡 Consejos

- Haz ambos en la misma sesión para ser más rápido
- Puedes abrir ambos enlaces en pestañas diferentes
- No necesitas configurar nada más, solo crear las bases de datos
- Las reglas las puedes desplegar después si prefieres

¿Necesitas ayuda con algún paso específico?

