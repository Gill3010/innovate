# ✅ Checklist de Despliegue

Sigue estos pasos en orden para desplegar tu aplicación a producción.

## 📋 Pre-Despliegue (Ya Completado)

- ✅ Firebase configurado: `innova-proyectos-jobs`
- ✅ Flutter configurado para Android e iOS
- ✅ Dockerfile creado
- ✅ Scripts de despliegue listos
- ✅ API Client configurado para producción

## 🚀 Pasos a Ejecutar

### □ 1. Configurar Google Cloud (5 min)

```bash
# Autenticarse
gcloud auth login

# Configurar proyecto
gcloud config set project innova-proyectos-jobs

# Habilitar APIs
gcloud services enable run.googleapis.com sqladmin.googleapis.com cloudbuild.googleapis.com
```

**Verificar**: `gcloud config get-value project` debe mostrar `innova-proyectos-jobs`

---

### □ 2. Crear Base de Datos (10 min)

```bash
# Crear instancia (tarda ~5-10 min)
gcloud sql instances create innova-db \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=us-central1 \
    --root-password=TuPasswordSeguro123 \
    --storage-type=SSD \
    --storage-size=10GB

# Esperar a que se complete
gcloud sql instances list

# Crear base de datos
gcloud sql databases create innovadb --instance=innova-db

# Crear usuario
gcloud sql users create innovaapp \
    --instance=innova-db \
    --password=TuAppPasswordSeguro456
```

**Verificar**: `gcloud sql databases list --instance=innova-db`

**Guardar**:
- Password root: `TuPasswordSeguro123`
- Password app: `TuAppPasswordSeguro456`
- Connection name: `innova-proyectos-jobs:us-central1:innova-db`

---

### □ 3. Generar Secretos (1 min)

```bash
# JWT Secret
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

**Guardar** el resultado para el siguiente paso.

---

### □ 4. Desplegar Backend (10 min)

**Opción A - Script Automatizado**:

1. Edita `scripts/deploy_backend.sh`
2. Añade tus variables de entorno
3. Ejecuta: `./scripts/deploy_backend.sh`

**Opción B - Manual**:

```bash
gcloud run deploy innova-backend \
    --source . \
    --region=us-central1 \
    --platform=managed \
    --allow-unauthenticated \
    --add-cloudsql-instances=innova-proyectos-jobs:us-central1:innova-db \
    --set-env-vars="DATABASE_URL=postgresql://innovaapp:TuAppPasswordSeguro456@/innovadb?host=/cloudsql/innova-proyectos-jobs:us-central1:innova-db,JWT_SECRET_KEY=<tu_jwt_secret_aqui>,FLASK_ENV=production,DEBUG=False,OPENAI_API_KEY=<tu_openai_key>,ADZUNA_APP_ID=<tu_adzuna_id>,ADZUNA_API_KEY=<tu_adzuna_key>" \
    --max-instances=10 \
    --memory=512Mi \
    --timeout=300 \
    --port=8080
```

**Guardar** la URL del servicio: `https://innova-backend-xxxxx-uc.a.run.app`

**Verificar**:
```bash
curl https://innova-backend-xxxxx-uc.a.run.app/api/health
```

Debe responder: `{"status":"ok"}`

---

### □ 5. Configurar Android Signing (2 min)

```bash
./scripts/setup_android_signing.sh
```

**Seguir** las instrucciones en pantalla.

**Resultado**:
- Keystore creado en: `~/innova-key.jks`
- Archivo `android/key.properties` creado

**⚠️ IMPORTANTE**: 
- Haz backup del keystore
- NO lo cometas a Git
- Si lo pierdes, no podrás actualizar la app en Play Store

---

### □ 6. Construir APK de Producción (5 min)

```bash
./scripts/build_apk.sh https://innova-backend-xxxxx-uc.a.run.app
```

**Reemplaza** la URL con la de tu backend del paso 4.

**Resultado**:
- APK en: `build/app/outputs/flutter-apk/app-release.apk`
- Tamaño: ~30-50 MB

**Verificar**:
```bash
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

---

### □ 7. Probar la App (5 min)

**Opción A - Dispositivo Conectado**:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Opción B - Compartir APK**:
```bash
open build/app/outputs/flutter-apk/
```

Envía el APK a tu dispositivo y instálalo.

**Probar**:
1. Abrir app
2. Registrar usuario
3. Crear proyecto
4. Buscar empleos
5. Compartir portafolio

---

## 🎯 Post-Despliegue

### □ Configurar Dominio Personalizado (Opcional)

```bash
gcloud run domain-mappings create \
    --service=innova-backend \
    --domain=api.tudominio.com \
    --region=us-central1
```

### □ Configurar CI/CD (Opcional)

1. Conectar repositorio a Cloud Build
2. El archivo `cloudbuild.yaml` ya está listo
3. Cada push a `main` desplegará automáticamente

### □ Configurar Monitoring

```bash
# Habilitar Cloud Monitoring
gcloud services enable monitoring.googleapis.com

# Ver métricas
gcloud run services browse innova-backend
```

### □ Configurar Backups

Cloud SQL hace backups automáticos, pero verifica:

```bash
gcloud sql instances describe innova-db \
    --format="value(settings.backupConfiguration)"
```

---

## 📊 Verificación Final

Comprueba que todo funciona:

- [ ] Backend responde en la URL de Cloud Run
- [ ] Health endpoint devuelve `{"status":"ok"}`
- [ ] Puedes registrar un usuario desde la app
- [ ] Puedes crear un proyecto con imagen
- [ ] Búsqueda de empleos funciona
- [ ] Compartir portafolio funciona (QR + URL)
- [ ] La app se instala sin errores

---

## 💰 Costos Mensuales Esperados

| Servicio | Plan | Costo Estimado |
|----------|------|----------------|
| Cloud Run | 2M requests | $0-5 |
| Cloud SQL | f1-micro | $7 |
| Cloud Storage | 1GB | $0.02 |
| **TOTAL** | | **~$7-12** |

---

## 📞 Siguiente Nivel

Una vez que todo funcione:

1. **Play Store**: Sube el AAB a Google Play Console
2. **App Store**: Build iOS y sube a App Store Connect
3. **Analytics**: Integra Firebase Analytics
4. **Crash Reporting**: Activa Crashlytics
5. **Push Notifications**: Configura FCM

---

## 🔥 Comandos Rápidos de Referencia

```bash
# Ver logs del backend
gcloud run services logs tail innova-backend --region=us-central1

# Actualizar backend
gcloud run deploy innova-backend --source . --region=us-central1

# Conectar a la DB
gcloud sql connect innova-db --user=innovaapp --database=innovadb

# Construir nuevo APK
./scripts/build_apk.sh <BACKEND_URL>

# Ver servicios activos
gcloud run services list
gcloud sql instances list
```

---

## ✅ ¡Completado!

Si marcaste todos los checkboxes, ¡tu app ya está en producción! 🎉

**Siguiente**: Distribuir el APK o subir a Play Store.


