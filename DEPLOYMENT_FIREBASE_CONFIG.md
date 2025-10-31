# 🔧 Configuración de Firebase en Despliegue

## ✅ Cambio Realizado

Se actualizó `cloudbuild.yaml` para configurar automáticamente Firebase al desplegar.

## 📋 Variables Agregadas

Las siguientes variables de entorno se configuran automáticamente en Cloud Run:

1. **`FLASK_ENV=production`**
   - Define que estamos en entorno de producción
   - Activa `ProductionConfig` que tiene `USE_FIREBASE=true` por defecto

2. **`USE_FIREBASE=true`**
   - Habilita explícitamente el uso de Firebase
   - Hace que usuarios y proyectos se guarden en Firestore
   - Hace que imágenes se suban a Firebase Storage

3. **`FIREBASE_STORAGE_BUCKET=innova-proyectos-jobs.firebasestorage.app`**
   - Define el bucket de Firebase Storage
   - Necesario para que las imágenes se suban correctamente

## 🎯 Ventajas de Hacerlo Explícito

✅ **Claridad**: Es evidente qué configuración se usa en producción  
✅ **Mantenibilidad**: Fácil de cambiar sin tocar código  
✅ **Robustez**: No depende de valores por defecto que pueden cambiar  
✅ **Documentación**: El archivo `cloudbuild.yaml` documenta la configuración  

## 🔐 Credenciales de Firebase

**Importante**: En Cloud Run, las credenciales de Firebase se manejan automáticamente usando **Application Default Credentials (ADC)**. No necesitas configurar `GOOGLE_APPLICATION_CREDENTIALS` manualmente porque:

1. Cloud Run tiene acceso automático a las credenciales del proyecto
2. El código en `backend/firebase_service.py` maneja esto:
   ```python
   try:
       firebase_admin.initialize_app()  # Usa ADC automáticamente
   ```

## 📊 Flujo Completo

### Desarrollo Local
```bash
# Sin variables o con .env
FLASK_ENV=development  # (por defecto)
USE_FIREBASE=false     # (por defecto en desarrollo)

# Resultado: SQLite local
```

### Producción (Cloud Run)
```bash
# Configurado en cloudbuild.yaml
FLASK_ENV=production
USE_FIREBASE=true
FIREBASE_STORAGE_BUCKET=innova-proyectos-jobs.firebasestorage.app

# Resultado: Firebase Firestore + Storage
```

## ⚠️ Nota sobre DATABASE_URL

Aunque configuramos `USE_FIREBASE=true`, el `DATABASE_URL` todavía se puede usar para:
- Datos que no migramos a Firebase (si los hay)
- Como fallback si Firebase no está disponible
- Para compatibilidad con código existente

En el futuro, si todo está en Firebase, puedes eliminar `DATABASE_URL` del despliegue.

## ✅ Verificación

Después de desplegar, puedes verificar en los logs de Cloud Run:

```bash
gcloud run services logs read innova-backend --region=us-central1 --limit=50
```

Deberías ver:
```
Firebase inicializado correctamente
```

Si ves esto, significa que Firebase está funcionando correctamente en producción.

