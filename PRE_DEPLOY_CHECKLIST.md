# ✅ Checklist Pre-Despliegue

## Verificación Rápida

### ✅ Configuración
- [x] Firestore Database `innovate` creada
- [x] Firebase Storage habilitado
- [x] Reglas de seguridad desplegadas
- [x] `cloudbuild.yaml` configurado con `USE_FIREBASE=true`
- [x] Código actualizado para usar Firebase

### ✅ Variables en cloudbuild.yaml
- [x] `FLASK_ENV=production`
- [x] `USE_FIREBASE=true`
- [x] `FIRESTORE_DATABASE=innovate`
- [x] `FIREBASE_STORAGE_BUCKET=innova-proyectos-jobs.firebasestorage.app`

## 🚀 Comando de Despliegue

```bash
gcloud builds submit --config cloudbuild.yaml
```

O si usas un script específico:
```bash
# Verifica si tienes un script de despliegue
./scripts/deploy_backend.sh  # si existe
```

## 📊 Después del Despliegue

1. Verifica los logs:
```bash
gcloud run services logs read innova-backend --region=us-central1 --limit=50
```

2. Busca el mensaje:
```
Firebase inicializado correctamente
```

3. Prueba crear un usuario desde la web desplegada

4. Verifica en Firebase Console:
   - Firestore → colección `users`
   - Firestore → colección `projects`
   - Storage → carpeta `uploads/`

## ⚠️ Si algo falla

Si ves errores en los logs relacionados con Firebase:
- Verifica que las APIs estén habilitadas
- Verifica que Cloud Run tenga permisos de Firebase
- Revisa los logs para más detalles

