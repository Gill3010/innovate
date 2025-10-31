#!/bin/bash
# Script para configurar la base de datos PostgreSQL

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTANCE_NAME="innova-db"
DB_NAME="innovadb"
DB_USER="innovaapp"
DB_PASSWORD="${DB_PASSWORD:-InnovaApp2025!}"

echo -e "${GREEN}🗄️  Configurando base de datos${NC}"

# Verificar que la instancia esté lista
echo -e "${YELLOW}Verificando estado de la instancia...${NC}"
STATE=$(gcloud sql instances describe $INSTANCE_NAME --format="value(state)")

if [ "$STATE" != "RUNNABLE" ]; then
    echo -e "${YELLOW}Estado actual: ${STATE}${NC}"
    echo -e "${YELLOW}La instancia aún no está lista. Espera hasta que esté en estado RUNNABLE${NC}"
    echo -e "${YELLOW}Verifica con: gcloud sql instances describe $INSTANCE_NAME --format='value(state)'${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Instancia lista (RUNNABLE)${NC}"

# Crear base de datos
echo -e "${YELLOW}Creando base de datos '${DB_NAME}'...${NC}"
gcloud sql databases create $DB_NAME --instance=$INSTANCE_NAME || {
    # Si ya existe, continúa
    echo -e "${YELLOW}Base de datos ya existe, continuando...${NC}"
}

# Crear usuario
echo -e "${YELLOW}Creando usuario '${DB_USER}'...${NC}"
gcloud sql users create $DB_USER \
    --instance=$INSTANCE_NAME \
    --password=$DB_PASSWORD 2>&1 | grep -v "already exists" || {
    echo -e "${YELLOW}Usuario ya existe, continuando...${NC}"
}

# Obtener connection name
CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME --format="value(connectionName)")

echo -e "${GREEN}✅ Base de datos configurada${NC}"
echo -e "${GREEN}Connection Name: ${CONNECTION_NAME}${NC}"
echo -e "${GREEN}Base de datos: ${DB_NAME}${NC}"
echo -e "${GREEN}Usuario: ${DB_USER}${NC}"


