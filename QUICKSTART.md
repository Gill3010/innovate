# 🚀 Guía Rápida de Despliegue

Esta guía te llevará de 0 a producción en ~30 minutos.

## ✅ Pre-requisitos Completados

- ✅ Firebase configurado: `innova-proyectos-jobs`
- ✅ Dockerfile creado
- ✅ Scripts de despliegue listos
- ✅ Flutter configurado para producción

## 📋 Pasos a Seguir

### 1. Inicializar Google Cloud (5 min)

```bash
# Autenticarse
gcloud auth login

# Configurar proyecto
gcloud config set project innova-proyectos-jobs

# Habilitar APIs necesarias
gcloud services enable run.googleapis.com sqladmin.googleapis.com cloudbuild.googleapis.com
```

### 2. Crear Base de Datos PostgreSQL (5 min)

```bash
# Crear instancia de Cloud SQL
gcloud sql instances create innova-db \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=us-central1 \
    --root-password=TuPasswordSeguro123 \
    --storage-type=SSD \
    --storage-size=10GB

# Crear base de datos
gcloud sql databases create innovadb --instance=innova-db

# Crear usuario de aplicación
gcloud sql users create innovaapp \
    --instance=innova-db \
    --password=TuAppPasswordSeguro456
```

⏳ **Esto tarda ~5-10 minutos**. Puedes verificar con:
```bash
gcloud sql instances list
```

### 3. Generar JWT Secret

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

Guarda el resultado, lo necesitarás en el siguiente paso.

### 4. Desplegar Backend (10 min)

Opción A - **Usando el script automatizado** (recomendado):

```bash
# Edita el script primero para añadir tus variables de entorno
nano scripts/deploy_backend.sh

# Ejecuta
./scripts/deploy_backend.sh
```

Opción B - **Manual**:

```bash
gcloud run deploy innova-backend \
    --source . \
    --region=us-central1 \
    --platform=managed \
    --allow-unauthenticated \
    --add-cloudsql-instances=innova-proyectos-jobs:us-central1:innova-db \
    --set-env-vars="DATABASE_URL=postgresql://innovaapp:TuAppPasswordSeguro456@/innovadb?host=/cloudsql/innova-proyectos-jobs:us-central1:innova-db,JWT_SECRET_KEY=<tu_jwt_secret>,FLASK_ENV=production,DEBUG=False" \
    --max-instances=10 \
    --memory=512Mi \
    --timeout=300 \
    --port=8080
```

📝 **Guarda la URL** que te devuelve, algo como:
```
https://innova-backend-xxxxx-uc.a.run.app
```

### 5. Configurar Android Signing (2 min)

```bash
./scripts/setup_android_signing.sh
```

Sigue las instrucciones en pantalla.

### 6. Construir APK (5 min)

```bash
./scripts/build_apk.sh https://innova-backend-xxxxx-uc.a.run.app
```

Reemplaza la URL con la que obtuviste en el paso 4.

El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

### 7. Instalar y Probar

```bash
# Instalar en dispositivo conectado
adb install build/app/outputs/flutter-apk/app-release.apk

# O compartir el APK para instalación manual
open build/app/outputs/flutter-apk/
```

## 🎉 ¡Listo!

Tu aplicación ya está en producción.

## 🔧 Comandos Útiles

### Ver logs del backend

```bash
gcloud run services logs tail innova-backend --region=us-central1
```

### Actualizar backend

```bash
# Hacer cambios en el código
git commit -am "feat: nueva funcionalidad"

# Redesplegar
./scripts/deploy_backend.sh
```

### Construir nueva versión de la app

```bash
# Actualizar versión en pubspec.yaml
# Ejemplo: version: 1.0.1+2

# Construir nueva APK
./scripts/build_apk.sh https://innova-backend-xxxxx-uc.a.run.app
```

### Conectar a la base de datos

```bash
gcloud sql connect innova-db --user=innovaapp --database=innovadb
```

## 💰 Costos Estimados

- Cloud Run: ~$0-5/mes (2M requests gratis)
- Cloud SQL (f1-micro): ~$7/mes
- **Total**: ~$7-12/mes

## 📚 Documentación Completa

Para más detalles, revisa `DEPLOYMENT.md`.

## 🆘 Problemas Comunes

### "Connection refused" al backend

```bash
# Verificar que el servicio está corriendo
gcloud run services list

# Ver logs
gcloud run services logs read innova-backend --region=us-central1 --limit=50
```

### APK no instala

```bash
# Verificar que el APK está firmado
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

### Backend responde 500

```bash
# Ver logs detallados
gcloud run services logs tail innova-backend --region=us-central1

# Verificar variables de entorno
gcloud run services describe innova-backend --region=us-central1
```

## 📞 Siguientes Pasos

1. **Dominio personalizado**: Mapea tu propio dominio en Cloud Run
2. **CI/CD**: Configura deploy automático con Cloud Build
3. **Monitoring**: Activa alertas en Cloud Monitoring
4. **Play Store**: Sube tu app a Google Play Store

---

**¿Preguntas?** Revisa `DEPLOYMENT.md` para la guía completa.


