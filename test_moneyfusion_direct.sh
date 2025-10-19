#!/bin/bash

echo "=== Test direct API MoneyFusion avec votre Merchant ID ==="
echo ""

MERCHANT_ID="68aee21447de6b2608cdac7a"

# Données de test minimales
test_data='{
  "totalPrice": 100,
  "article": [{"Test": 100}],
  "numeroSend": "0123456789",
  "nomclient": "Test User",
  "personal_Info": [{"userId": "test123"}]
}'

echo "Test 1: URL avec merchant ID dans le chemin"
echo "URL: https://pay.moneyfusion.net/api/$MERCHANT_ID/payment"
curl -v -X POST "https://pay.moneyfusion.net/api/$MERCHANT_ID/payment" \
  -H "Content-Type: application/json" \
  -d "$test_data" 2>&1 | grep -E "(HTTP|statut|error|token)" | head -10

echo ""
echo "---"
echo ""

echo "Test 2: URL avec merchant dans les paramètres"
echo "URL: https://pay.moneyfusion.net/api/payment?merchant=$MERCHANT_ID"
curl -v -X POST "https://pay.moneyfusion.net/api/payment?merchant=$MERCHANT_ID" \
  -H "Content-Type: application/json" \
  -d "$test_data" 2>&1 | grep -E "(HTTP|statut|error|token)" | head -10

echo ""
echo "---"
echo ""

echo "Test 3: Endpoint simple sans merchant ID"
echo "URL: https://pay.moneyfusion.net/api/payment"
curl -v -X POST "https://pay.moneyfusion.net/api/payment" \
  -H "Content-Type: application/json" \
  -d "$test_data" 2>&1 | grep -E "(HTTP|statut|error|token|merchant)" | head -10

echo ""
echo "=== Fin des tests ==="
