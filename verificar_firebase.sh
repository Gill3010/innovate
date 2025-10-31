#!/bin/bash
# Script para verificar el estado de Firebase antes del despliegue

echo "🔍 Verificando configuración de Firebase..."
echo ""

PROJECT_ID="innova-proyectos-jobs"

echo "📋 Proyecto Firebase: $PROJECT_ID"
echo ""

# Verificar si Firestore está habilitado
echo "1️⃣ Verificando Firestore Database..."
firebase firestore:databases:list --project=$PROJECT_ID 2>&1 | grep -q "Error\|error" 
if [ $? -eq 0 ]; then
    echo "   ❌ Firestore NO está habilitado o hay un error"
    echo "   👉 Ve a Firebase Console y crea Firestore Database"
    echo "   👉 URL: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
else
    echo "   ✅ Firestore parece estar configurado"
    firebase firestore:databases:list --project=$PROJECT_ID 2>&1 | head -10
fi

echo ""
echo "2️⃣ Verificando Storage..."
# No hay comando CLI directo, pero podemos verificar las reglas
if [ -f "storage.rules" ]; then
    echo "   ✅ Archivo de reglas de Storage existe"
else
    echo "   ⚠️ Archivo storage.rules no encontrado"
fi

echo ""
echo "3️⃣ Verificando reglas de Firestore..."
if [ -f "firestore.rules" ]; then
    echo "   ✅ Archivo de reglas de Firestore existe"
else
    echo "   ⚠️ Archivo firestore.rules no encontrado"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 RECOMENDACIONES:"
echo ""
echo "Antes de desplegar el backend, asegúrate de:"
echo ""
echo "1. ✅ Crear Firestore Database en Firebase Console"
echo "   👉 https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo ""
echo "2. ✅ Crear Firebase Storage en Firebase Console"
echo "   👉 https://console.firebase.google.com/project/$PROJECT_ID/storage"
echo ""
echo "3. ✅ Desplegar reglas de seguridad (opcional pero recomendado):"
echo "   firebase deploy --only firestore:rules"
echo "   firebase deploy --only storage:rules"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

