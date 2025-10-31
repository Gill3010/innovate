# Cómo obtener y configurar la API Key de OpenAI

## Paso 1: Crear cuenta en OpenAI

1. Ve a **https://platform.openai.com/signup**
2. Crea una cuenta (puedes usar Google, Microsoft, o email)
3. Verifica tu email

## Paso 2: Agregar método de pago (requerido)

⚠️ **Importante**: OpenAI requiere agregar una tarjeta de crédito para usar la API, aunque ofrecen crédito gratuito inicial.

1. Ve a **https://platform.openai.com/account/billing**
2. Haz clic en "Add payment method"
3. Agrega tu tarjeta de crédito o débito
4. OpenAI te dará $5 USD de crédito gratuito para empezar

## Paso 3: Obtener tu API Key

1. Ve a **https://platform.openai.com/api-keys**
2. Haz clic en "Create new secret key"
3. Dale un nombre (ej: "Innovate App")
4. **IMPORTANTE**: Copia la API key inmediatamente. Solo se muestra una vez y empieza con `sk-...`
5. Guárdala en un lugar seguro

## Paso 4: Configurar en tu proyecto

1. En la raíz del proyecto (`/Users/israelsamuels/innovate`), crea un archivo llamado `.env`
2. Copia el siguiente contenido y reemplaza `sk-tu-api-key-aqui` con tu API key real:

```bash
FLASK_ENV=development
SECRET_KEY=change-me-to-a-random-secret-key
JWT_SECRET_KEY=change-me-to-another-random-secret-key
CORS_ORIGINS=*
CACHE_TYPE=SimpleCache
CACHE_DEFAULT_TIMEOUT=300
RATELIMIT_DEFAULT=100 per minute
PORT=8000
FORCE_HTTPS=false
AUTO_CREATE_DB=true

# ⬇️ Pega tu API key aquí (reemplaza sk-tu-api-key-aqui)
OPENAI_API_KEY=sk-tu-api-key-aqui

# Adzuna (opcional, para búsqueda de trabajos)
ADZUNA_APP_ID=
ADZUNA_APP_KEY=
ADZUNA_COUNTRY=gb
```

## Paso 5: Reiniciar el backend

Después de crear el archivo `.env`, reinicia el servidor backend:

```bash
# Si el backend está corriendo, detenlo (Ctrl+C) y luego:
python -m backend.app
```

## 💰 Costos

- **Crédito gratuito inicial**: $5 USD al registrarte
- **Modelo usado en esta app**: `gpt-4o-mini` (más económico)
- **Costo aproximado**: 
  - ~$0.00015 por 1000 tokens (entrada)
  - ~$0.0006 por 1000 tokens (salida)
  - Un mensaje típico del asesor usa ~200-500 tokens ≈ $0.0001-0.0003 por consulta

**Ejemplo**: Con $5 USD puedes hacer aproximadamente 15,000-50,000 consultas.

## 🔒 Seguridad

- **NUNCA** subas tu archivo `.env` a Git (ya está en `.gitignore`)
- **NUNCA** compartas tu API key públicamente
- Si comprometes tu key, revócala inmediatamente en https://platform.openai.com/api-keys

## ❓ Problemas comunes

**Error: "OPENAI_API_KEY no está configurada"**
- Verifica que el archivo `.env` esté en la raíz del proyecto
- Verifica que el backend esté leyendo el archivo `.env` (usa `python-dotenv`)
- Reinicia el servidor después de agregar la variable

**Error: "Error de autenticación con OpenAI"**
- Verifica que tu API key sea correcta (debe empezar con `sk-`)
- Verifica que no tenga espacios extra al copiar/pegar
- Verifica que tengas crédito disponible en tu cuenta

## 📚 Recursos

- Documentación oficial: https://platform.openai.com/docs
- Dashboard: https://platform.openai.com/playground
- Uso y facturación: https://platform.openai.com/usage
