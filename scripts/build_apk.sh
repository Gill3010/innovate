#!/bin/bash
# Script para construir APK de producción

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}📱 Construyendo APK de producción${NC}"

# Verificar que Flutter esté instalado
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter no está instalado${NC}"
    exit 1
fi

# Obtener URL del backend (puede pasarse como argumento)
if [ -z "$1" ]; then
    echo -e "${RED}Error: Debes proporcionar la URL del backend${NC}"
    echo -e "${YELLOW}Uso: ./scripts/build_apk.sh <BACKEND_URL>${NC}"
    echo -e "${YELLOW}Ejemplo: ./scripts/build_apk.sh https://innova-backend-xxxxx-uc.a.run.app${NC}"
    exit 1
fi

BACKEND_URL=$1

echo -e "${YELLOW}Backend URL: ${BACKEND_URL}${NC}"

# Limpiar build anterior
echo -e "${YELLOW}Limpiando builds anteriores...${NC}"
flutter clean

# Obtener dependencias
echo -e "${YELLOW}Obteniendo dependencias...${NC}"
flutter pub get

# Construir APK
echo -e "${YELLOW}Construyendo APK...${NC}"
flutter build apk --release \
    --dart-define=API_BASE_URL=$BACKEND_URL \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols

# Verificar que se construyó correctamente
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo -e "${GREEN}✅ APK construido exitosamente${NC}"
    echo -e "${GREEN}Tamaño: ${APK_SIZE}${NC}"
    echo -e "${GREEN}Ubicación: build/app/outputs/flutter-apk/app-release.apk${NC}"
    
    # Mostrar información del APK
    echo -e "${YELLOW}Información del APK:${NC}"
    aapt dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E "package:|versionCode|versionName"
else
    echo -e "${RED}Error: No se pudo construir el APK${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Build completo${NC}"
echo -e "${YELLOW}Para instalar:${NC} adb install build/app/outputs/flutter-apk/app-release.apk"


