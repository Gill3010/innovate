#!/bin/bash
# Script para configurar el signing de Android

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Configurando Android Signing${NC}"

# Verificar que keytool esté instalado
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}Error: keytool no está instalado${NC}"
    exit 1
fi

KEYSTORE_PATH="$HOME/innova-key.jks"
KEY_ALIAS="innova"

# Verificar si el keystore ya existe
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}Keystore ya existe en: ${KEYSTORE_PATH}${NC}"
    read -p "¿Deseas crear uno nuevo? (esto sobrescribirá el existente) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Manteniendo keystore existente${NC}"
        exit 0
    fi
fi

# Solicitar información
echo -e "${YELLOW}Creando nuevo keystore...${NC}"
echo -e "${YELLOW}Por favor ingresa la siguiente información:${NC}"
read -p "Password del keystore: " -s STORE_PASSWORD
echo
read -p "Confirma password: " -s STORE_PASSWORD_CONFIRM
echo

if [ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}Error: Las contraseñas no coinciden${NC}"
    exit 1
fi

read -p "Key password (presiona Enter para usar el mismo): " -s KEY_PASSWORD
echo
if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD=$STORE_PASSWORD
fi

# Generar keystore
echo -e "${YELLOW}Generando keystore...${NC}"
keytool -genkey -v -keystore $KEYSTORE_PATH \
    -alias $KEY_ALIAS \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Innova, OU=Development, O=Innova, L=Panama, ST=Panama, C=PA"

echo -e "${GREEN}✅ Keystore creado en: ${KEYSTORE_PATH}${NC}"

# Crear archivo key.properties
KEY_PROPERTIES="android/key.properties"
echo -e "${YELLOW}Creando ${KEY_PROPERTIES}...${NC}"

cat > $KEY_PROPERTIES << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_PATH
EOF

echo -e "${GREEN}✅ Archivo key.properties creado${NC}"

# Advertencia de seguridad
echo -e "${RED}⚠️  IMPORTANTE:${NC}"
echo -e "${YELLOW}1. NO cometas key.properties ni el keystore a Git${NC}"
echo -e "${YELLOW}2. Guarda una copia segura del keystore${NC}"
echo -e "${YELLOW}3. Si pierdes el keystore, no podrás actualizar la app en Play Store${NC}"

# Verificar configuración en build.gradle
echo -e "${YELLOW}Verificando configuración en build.gradle...${NC}"
if ! grep -q "signingConfigs" android/app/build.gradle.kts; then
    echo -e "${RED}⚠️  build.gradle.kts necesita configuración de signing${NC}"
    echo -e "${YELLOW}Revisa DEPLOYMENT.md para las instrucciones${NC}"
else
    echo -e "${GREEN}✅ build.gradle.kts parece estar configurado${NC}"
fi

echo -e "${GREEN}🎉 Configuración de signing completa${NC}"


