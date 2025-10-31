#!/bin/bash
# Script para desplegar el backend en Google Cloud Run

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Desplegando backend en Cloud Run${NC}"

# Verificar que gcloud esté instalado
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI no está instalado${NC}"
    exit 1
fi

# Variables (actualizar según sea necesario)
PROJECT_ID="innova-proyectos-jobs"
REGION="us-central1"
SERVICE_NAME="innova-backend"
CLOUD_SQL_INSTANCE="innova-proyectos-jobs:us-central1:innova-db"

# Variables de entorno para la aplicación
# IMPORTANTE: Actualiza estos valores con tus credenciales reales
DB_PASSWORD="${DB_PASSWORD:-InnovaApp2025!}"
JWT_SECRET="${JWT_SECRET:-qDcnGgERRXUXqrUdWSU53XAq5aSLgkn8hipCevcF2u8I89ovn4mN2ncxt0GtxJdQZ_tDJKe83Bb5cs-GPQoUoQ}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
ADZUNA_APP_ID="${ADZUNA_APP_ID:-}"
ADZUNA_API_KEY="${ADZUNA_API_KEY:-}"

# Construir DATABASE_URL
DATABASE_URL="postgresql://innovaapp:${DB_PASSWORD}@/innovadb?host=/cloudsql/${CLOUD_SQL_INSTANCE}"

# Verificar que estamos en el proyecto correcto
echo -e "${YELLOW}Configurando proyecto...${NC}"
gcloud config set project $PROJECT_ID

# Verificar variables críticas
if [ -z "$OPENAI_API_KEY" ] || [ -z "$ADZUNA_APP_ID" ] || [ -z "$ADZUNA_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  Advertencia: Algunas API keys no están configuradas${NC}"
    echo -e "${YELLOW}Configúralas antes de desplegar exportando las variables:${NC}"
    echo -e "${YELLOW}  export OPENAI_API_KEY=tu_key${NC}"
    echo -e "${YELLOW}  export ADZUNA_APP_ID=tu_id${NC}"
    echo -e "${YELLOW}  export ADZUNA_API_KEY=tu_key${NC}"
    echo ""
    echo -e "${YELLOW}Continuando sin API keys (puedes añadirlas después)...${NC}"
    echo ""
fi

# Construir y desplegar
echo -e "${YELLOW}Construyendo y desplegando...${NC}"
echo -e "${YELLOW}Esto puede tardar 5-10 minutos...${NC}"

# Preparar variables de entorno
ENV_VARS="DATABASE_URL=${DATABASE_URL}"
ENV_VARS="${ENV_VARS},JWT_SECRET_KEY=${JWT_SECRET}"
ENV_VARS="${ENV_VARS},FLASK_ENV=production"
ENV_VARS="${ENV_VARS},DEBUG=False"
ENV_VARS="${ENV_VARS},AUTO_CREATE_DB=true"
# Firebase configuration
ENV_VARS="${ENV_VARS},USE_FIREBASE=true"
ENV_VARS="${ENV_VARS},FIREBASE_STORAGE_BUCKET=innova-proyectos-jobs.firebasestorage.app"
ENV_VARS="${ENV_VARS},FIRESTORE_DATABASE=innovate"

if [ -n "$OPENAI_API_KEY" ]; then
    ENV_VARS="${ENV_VARS},OPENAI_API_KEY=${OPENAI_API_KEY}"
fi

if [ -n "$ADZUNA_APP_ID" ]; then
    ENV_VARS="${ENV_VARS},ADZUNA_APP_ID=${ADZUNA_APP_ID}"
fi

if [ -n "$ADZUNA_API_KEY" ]; then
    ENV_VARS="${ENV_VARS},ADZUNA_API_KEY=${ADZUNA_API_KEY}"
fi

gcloud run deploy $SERVICE_NAME \
    --source . \
    --region=$REGION \
    --platform=managed \
    --allow-unauthenticated \
    --add-cloudsql-instances=$CLOUD_SQL_INSTANCE \
    --set-env-vars="$ENV_VARS" \
    --max-instances=10 \
    --memory=512Mi \
    --timeout=300 \
    --port=8080

# Obtener URL del servicio
echo -e "${GREEN}✅ Despliegue completado${NC}"
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
echo -e "${GREEN}URL del servicio: ${SERVICE_URL}${NC}"

# Test health endpoint
echo -e "${YELLOW}Verificando health endpoint...${NC}"
if curl -s "${SERVICE_URL}/api/health" | grep -q "ok"; then
    echo -e "${GREEN}✅ Backend funcionando correctamente${NC}"
else
    echo -e "${RED}⚠️  Advertencia: Health check falló${NC}"
fi

echo -e "${GREEN}🎉 Despliegue completo${NC}"
echo -e "${YELLOW}Actualiza Flutter con esta URL:${NC}"
echo -e "${GREEN}${SERVICE_URL}${NC}"

