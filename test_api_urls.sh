#!/bin/bash

# Script pour tester différentes URLs possibles de l'API MoneyFusion

MERCHANT_ID="68aee21447de6b2608cdac7a"

echo "=== Test des URLs possibles pour l'API MoneyFusion ==="
echo ""

# Liste des URLs à tester
urls=(
  "https://api.moneyfusion.net/merchant/$MERCHANT_ID/payment"
  "https://api.moneyfusion.net/v1/payment"
  "https://pay.moneyfusion.net/api/payment"
  "https://api.pay.moneyfusion.net/payment"
  "https://moneyfusion.net/api/payment"
  "https://api.moneyfusion.net/payment/initiate"
)

# Données de test minimales
test_data='{
  "totalPrice": 100,
  "article": [{"Test": 100}],
  "numeroSend": "0123456789",
  "nomclient": "Test User",
  "personal_Info": [{"userId": "test123"}]
}'

counter=1
for url in "${urls[@]}"; do
  echo "[$counter] Test de : $url"

  response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$url" \
    -H "Content-Type: application/json" \
    -d "$test_data" 2>&1)

  http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
  body=$(echo "$response" | grep -v "HTTP_CODE:")

  echo "   Code HTTP: $http_code"

  if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    echo "   ✅ SUCCÈS ! Cette URL semble fonctionner !"
    echo "   Réponse: $body"
  elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
    echo "   🔑 URL existe mais nécessite authentification"
  elif [ "$http_code" = "404" ]; then
    echo "   ❌ URL n'existe pas"
  else
    echo "   ⚠️  Réponse inattendue"
    echo "   $body" | head -3
  fi

  echo ""
  ((counter++))
done

echo "=== Fin des tests ==="
echo ""
echo "💡 Conseil: Si aucune URL ne fonctionne, contactez MoneyFusion pour obtenir votre API URL exacte."
