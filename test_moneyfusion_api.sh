#!/bin/bash

# Script de test pour vérifier l'API MoneyFusion

API_KEY="moneyfusion_v1_68aee21447de6b2608cdac7a_935F04A1AB87FB33786CB171C3CC822A37CABB3A64AB5FD01A33E80A1CA86023"
MERCHANT_ID="68aee21447de6b2608cdac7a"

echo "=== Test de l'API MoneyFusion ==="
echo ""

# Test 1: URL avec .net
echo "Test 1: Tentative avec https://api.moneyfusion.net/v1"
curl -X POST https://api.moneyfusion.net/v1/payments/initiate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -H "X-Merchant-Id: $MERCHANT_ID" \
  -d '{
    "amount": 500,
    "currency": "XOF",
    "phone_number": "+2250123456789",
    "payment_method": "orange_money",
    "description": "Test paiement",
    "customer_id": "test_user_123"
  }' \
  -w "\nHTTP Status: %{http_code}\n" \
  -v 2>&1

echo ""
echo "================================================"
echo ""

# Test 2: URL avec .com (comme dans la Cloud Function)
echo "Test 2: Tentative avec https://api.moneyfusion.com/v1"
curl -X POST https://api.moneyfusion.com/v1/payments/initiate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -H "X-Merchant-Id: $MERCHANT_ID" \
  -d '{
    "amount": 500,
    "currency": "XOF",
    "phone_number": "+2250123456789",
    "payment_method": "orange_money",
    "description": "Test paiement",
    "customer_id": "test_user_123"
  }' \
  -w "\nHTTP Status: %{http_code}\n" \
  -v 2>&1

echo ""
echo "=== Fin des tests ==="
