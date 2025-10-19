#!/bin/bash

# Test de la Cloud Function initializePayment

echo "🔍 Test de la fonction initializePayment..."
echo ""

# URL de la fonction
FUNCTION_URL="https://europe-west1-chiasma-android.cloudfunctions.net/initializePayment"

# Données de test
DATA='{
  "data": {
    "userId": "test-user-123",
    "amount": 9.99,
    "currency": "EUR",
    "subscriptionType": "monthly"
  }
}'

echo "📡 Appel de la fonction..."
echo "URL: $FUNCTION_URL"
echo "Données: $DATA"
echo ""

# Appel de la fonction
RESPONSE=$(curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "$DATA" \
  2>&1)

echo "📥 Réponse:"
echo "$RESPONSE"
echo ""

# Vérifier si c'est un succès ou une erreur
if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ ERREUR détectée dans la réponse"
else
    echo "✅ Pas d'erreur apparente"
fi
