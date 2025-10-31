#!/bin/bash
# Script para configurar OPENAI_API_KEY en Cloud Run

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ID="innova-proyectos-jobs"
REGION="us-central1"
SERVICE_NAME="innova-backend"

# Verificar que OPENAI_API_KEY esté configurada
if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}Error: OPENAI_API_KEY no está configurada${NC}"
    echo -e "${YELLOW}Configúrala ejecutando:${NC}"
    echo -e "${YELLOW}  export OPENAI_API_KEY=tu_api_key_aqui${NC}"
    exit 1
fi

echo -e "${YELLOW}Configurando OPENAI_API_KEY en Cloud Run...${NC}"

# Actualizar variable de entorno
gcloud run services update $SERVICE_NAME \
    --region=$REGION \
    --update-env-vars="OPENAI_API_KEY=${OPENAI_API_KEY}"

echo -e "${GREEN}✅ OPENAI_API_KEY configurada correctamente${NC}"

