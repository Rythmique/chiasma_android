# Message à envoyer au support MoneyFusion

---

**Objet :** Demande de l'API URL pour intégration paiement

---

Bonjour,

Je suis en train d'intégrer l'API de paiement MoneyFusion dans mon application mobile CHIASMA.

**Informations de mon compte :**
- Merchant ID : `68aee21447de6b2608cdac7a`
- Clé API : `moneyfusion_v1_68aee21447de6b2608cdac7a_935F04A1AB87FB33786CB171C3CC822A37CABB3A64AB5FD01A33E80A1CA86023`

**Ma demande :**

Selon votre documentation, je dois utiliser "YOUR_API_URL" que je dois obtenir depuis mon tableau de bord.

Pourriez-vous me fournir :

1. **Mon API URL exacte** pour initier les paiements
2. **Un exemple complet de requête** avec cette URL
3. Confirmation que je n'ai besoin que du header `Content-Type: application/json` (pas d'Authorization header)

**Exemple de ce que j'ai implémenté :**

```json
POST [MON_API_URL]
Content-Type: application/json

{
  "totalPrice": 500,
  "article": [{"Abonnement": 500}],
  "numeroSend": "0123456789",
  "nomclient": "Client Test",
  "personal_Info": [{"userId": "123", "orderId": "456"}]
}
```

Est-ce correct ?

Merci de votre aide rapide, mon application est prête à être déployée dès que j'aurai cette information.

Cordialement

---

**Où envoyer ce message :**
- Support MoneyFusion (cherchez dans votre dashboard)
- Email de contact sur https://moneyfusion.net
- Chat support si disponible
