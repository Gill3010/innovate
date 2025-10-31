# Guía de Despliegue - Innovate App

## Recomendación principal: **Railway.app** 🚂

### ¿Por qué Railway?

Para una app Flutter + Flask como la tuya, **Railway** es la mejor opción porque:

1. **Deploy en 1 click** (conecta GitHub y depliega automáticamente)
2. **PostgreSQL incluido** (tu backend ya lo soporta)
3. **Variables de entorno fáciles** (para tus API keys)
4. **Free tier generoso**: $5 USD gratis/mes
5. **No necesitas configurar Docker** (detecta Flask automáticamente)
6. **HTTPS automático** (certificados SSL gratuitos)
7. **Perfecto para Python/Flask**

### Plan de costo
- **Free tier**: $5 USD/mes gratis → suficiente para empezar
- **Starter**: $10/mes → para apps con tráfico moderado
- **Pro**: $20/mes → producción real

## Alternativas

### 2. **Render.com** 🎨
- ✅ Free tier (con limitaciones)
- ✅ PostgreSQL gratis
- ❌ Apps gratuitas se "duermen" después de 15 min inactivas
- ❌ Más lento para arrancar
- 💰 Mejor para MVP/testing, no producción

### 3. **Fly.io** 🚀
- ✅ Deploy global (edge computing)
- ✅ Muy rápido
- ❌ Más complejo de configurar
- ❌ Necesitas Dockerfile
- 💰 $5/mes mínimo

### 4. **AWS/GCP/Azure** ☁️
- ❌ Mucho más complejo (necesitas configurar VPC, ALB, ECS/Cloud Run, RDS)
- ❌ Curva de aprendizaje alta
- ✅ Mayor escalabilidad
- 💰 Free tier limitado, después puede ser caro
- ⚠️ **No recomendado para empezar**

### 5. **Firebase** 🔥
- ✅ Excelente para Flutter mobile apps
- ❌ No soporta Flask nativamente (necesitarías Cloud Functions + Node.js/Python)
- ❌ Firebase Functions muy caras después del free tier
- ✅ Firestore para base de datos
- ⚠️ **Requiere refactorizar tu backend**

## Pasos para desplegar en Railway

### 1. Preparar backend para producción

```bash
# Crea un requirements.txt limpio (ya lo tienes)
cd backend
pip install -r requirements.txt
```

### 2. Crear archivo Railway

Crea `railway.json` en la raíz:
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "cd backend && python -m backend.app",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### 3. Setup en Railway

1. Ve a [railway.app](https://railway.app)
2. Crea cuenta (usando GitHub)
3. "New Project" → "Deploy from GitHub repo"
4. Selecciona tu repo `innovate`
5. Railway detecta Flask automáticamente

### 4. Configurar base de datos PostgreSQL

1. En tu proyecto Railway: "+ New" → "Database" → "Add PostgreSQL"
2. Railway crea automáticamente `DATABASE_URL`
3. Cópiala y agrégala a Variables de Entorno

### 5. Variables de entorno en Railway

En Settings → Variables, agrega:
```
FLASK_ENV=production
SECRET_KEY=<genera-uno-seguro>
JWT_SECRET_KEY=<genera-otro-seguro>
DATABASE_URL=${{Postgres.DATABASE_URL}}
OPENAI_API_KEY=<tu-key>
ADZUNA_APP_ID=<tu-id>
ADZUNA_APP_KEY=<tu-key>
AUTO_CREATE_DB=true
FORCE_HTTPS=true
```

### 6. Deploy

Railway depliega automáticamente cada push a `main`.

### 7. Configurar dominio

Settings → Domains → "Generate Domain" (gratis con HTTPS)

## Actualizar Flutter para producción

Después del deploy, actualiza `ApiClient`:

```dart
static String _resolveDefaultBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  // En producción, usa tu dominio de Railway
  if (kReleaseMode) return 'https://tu-app.railway.app';
  if (kIsWeb) return 'http://127.0.0.1:8000';
  try {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  } catch (_) {}
  return 'http://127.0.0.1:8000';
}
```

## Migrar base de datos local a producción

```bash
# En Railway, obtén tu DATABASE_URL y ejecuta:
flask db upgrade  # Si usas Flask-Migrate
# O crea tablas manualmente:
python -m backend.app  # Con AUTO_CREATE_DB=true
```

## Checklist pre-deploy

- [ ] Eliminar archivos `.env` del repo (ya en .gitignore ✅)
- [ ] Configurar todas las variables de entorno en Railway
- [ ] Probar que PostgreSQL funcione
- [ ] Configurar dominio personalizado (opcional)
- [ ] Probar endpoints críticos en producción
- [ ] Configurar backups de PostgreSQL (Railway lo hace automático)
- [ ] Monitorear logs y errores

## Comparación visual

| Feature | Railway | Render | Fly.io | AWS |
|---------|---------|--------|--------|-----|
| Deploy fácil | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ |
| Free tier | $5/mes | Sí (sleeps) | Limitado | Limitado |
| PostgreSQL | ✅ Incluido | ✅ Incluido | ❌ Externo | ✅ RDS |
| HTTPS gratis | ✅ | ✅ | ✅ | ✅ |
| Sleep mode | ❌ | ✅ (free) | ❌ | N/A |
| Escalabilidad | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Complejidad | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Mejor para ti** | **✅ SÍ** | Pruebas | Escala | Empresas |

## Conclusión

**Railway** es la opción más simple y económica para empezar. Cuando tu app crezca, podrás migrar a AWS o Azure sin problemas.


