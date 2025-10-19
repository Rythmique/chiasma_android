import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

/// Widget de test pour diagnostiquer les problèmes de paiement
class PaymentDebugPage extends StatefulWidget {
  const PaymentDebugPage({super.key});

  @override
  State<PaymentDebugPage> createState() => _PaymentDebugPageState();
}

class _PaymentDebugPageState extends State<PaymentDebugPage> {
  String _logs = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs += '${DateTime.now().toIso8601String()}: $message\n';
    });
    developer.log(message, name: 'PaymentDebug');
  }

  Future<void> _testPayment() async {
    setState(() {
      _isLoading = true;
      _logs = '';
    });

    try {
      _addLog('=== DÉBUT DU TEST ===');

      // 1. Vérifier l'authentification
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addLog('❌ ERREUR: Utilisateur non authentifié');
        setState(() => _isLoading = false);
        return;
      }
      _addLog('✅ Utilisateur authentifié: ${user.uid}');

      // 2. Créer l'instance Cloud Functions
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      _addLog('✅ Instance Cloud Functions créée (region: europe-west1)');

      // 3. Préparer les données
      final data = {
        'userId': user.uid,
        'amount': 9.99,
        'currency': 'EUR',
        'subscriptionType': 'monthly',
      };
      _addLog('✅ Données préparées: $data');

      // 4. Appeler la fonction
      _addLog('📡 Appel de initializePayment...');
      final callable = functions.httpsCallable('initializePayment');

      try {
        final result = await callable.call<Map<String, dynamic>>(data);
        _addLog('✅ Réponse reçue: ${result.data}');

        if (result.data['success'] == true) {
          _addLog('✅ SUCCÈS: Paiement initialisé!');
          _addLog('   Payment ID: ${result.data['paymentId']}');
          _addLog('   Payment URL: ${result.data['paymentUrl']}');
        } else {
          _addLog('❌ ÉCHEC: ${result.data['error']}');
        }
      } on FirebaseFunctionsException catch (e) {
        _addLog('❌ ERREUR Firebase Functions:');
        _addLog('   Code: ${e.code}');
        _addLog('   Message: ${e.message}');
        _addLog('   Details: ${e.details}');

        // Analyse de l'erreur
        switch (e.code) {
          case 'not-found':
            _addLog('');
            _addLog('💡 SOLUTION: La fonction initializePayment n\'existe pas.');
            _addLog('   Déployez les Cloud Functions:');
            _addLog('   cd functions && npm run deploy');
            break;
          case 'permission-denied':
            _addLog('');
            _addLog('💡 SOLUTION: Problème de permissions.');
            _addLog('   Vérifiez les règles Firestore et IAM.');
            break;
          case 'unauthenticated':
            _addLog('');
            _addLog('💡 SOLUTION: Utilisateur non authentifié.');
            _addLog('   Connectez-vous d\'abord.');
            break;
          case 'internal':
            _addLog('');
            _addLog('💡 SOLUTION: Erreur interne de la fonction.');
            _addLog('   Vérifiez les logs: firebase functions:log --only initializePayment');
            break;
          default:
            _addLog('');
            _addLog('💡 Vérifiez les logs Cloud Functions pour plus de détails.');
        }
      }

      _addLog('=== FIN DU TEST ===');
    } catch (e, stackTrace) {
      _addLog('❌ ERREUR INATTENDUE: $e');
      _addLog('Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCloudFunctionsConnectivity() async {
    setState(() {
      _isLoading = true;
      _logs = '';
    });

    try {
      _addLog('=== TEST DE CONNECTIVITÉ ===');

      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      _addLog('✅ Instance créée');

      // Tester avec une fonction simple
      _addLog('📡 Test d\'appel à Cloud Functions...');

      final callable = functions.httpsCallable('initializePayment');
      _addLog('✅ Callable créé');

      // Note: Cet appel va échouer mais nous permettra de savoir si la fonction existe
      try {
        await callable.call<Map<String, dynamic>>({'test': true});
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'not-found') {
          _addLog('❌ La fonction initializePayment n\'existe PAS');
          _addLog('💡 Déployez les fonctions: cd functions && npm run deploy');
        } else {
          _addLog('✅ La fonction initializePayment existe!');
          _addLog('   (L\'erreur ${e.code} est normale pour ce test)');
        }
      }

      _addLog('=== FIN DU TEST ===');
    } catch (e) {
      _addLog('❌ ERREUR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Paiement MoneyFusion'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Outils de Diagnostic',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testPayment,
              icon: const Icon(Icons.payment),
              label: const Text('Tester Paiement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCloudFunctionsConnectivity,
              icon: const Icon(Icons.cloud),
              label: const Text('Tester Connectivité Cloud Functions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Logs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs.isEmpty ? 'Aucun log pour le moment' : _logs,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
