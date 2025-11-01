import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

/// Page de diagnostic pour tester le chargement des utilisateurs
class TestUserLoadingPage extends StatefulWidget {
  const TestUserLoadingPage({super.key});

  @override
  State<TestUserLoadingPage> createState() => _TestUserLoadingPageState();
}

class _TestUserLoadingPageState extends State<TestUserLoadingPage> {
  List<Map<String, dynamic>> _users = [];
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testLoadUsers();
  }

  Future<void> _testLoadUsers() async {
    const logName = 'TestUserLoading';

    try {
      dev.log('=== TEST CHARGEMENT UTILISATEURS ===', name: logName);

      // Test 1: Compter tous les utilisateurs
      final allUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      dev.log('Total utilisateurs dans la base: ${allUsersSnapshot.docs.length}', name: logName);

      // Test 2: Compter les utilisateurs de type teacher_transfer
      final teacherTransferSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('accountType', isEqualTo: 'teacher_transfer')
          .get();
      dev.log('Utilisateurs teacher_transfer: ${teacherTransferSnapshot.docs.length}', name: logName);

      // Test 3: Lister les types de comptes
      final accountTypes = <String>{};
      for (var doc in allUsersSnapshot.docs) {
        final data = doc.data();
        accountTypes.add(data['accountType']?.toString() ?? 'null');
      }
      dev.log('Types de comptes présents: $accountTypes', name: logName);

      // Test 4: Essayer la requête avec orderBy
      dev.log('\nTest avec orderBy createdAt:', name: logName);
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('accountType', isEqualTo: 'teacher_transfer')
            .orderBy('createdAt', descending: true)
            .get();
        dev.log('Succès! Trouvé ${querySnapshot.docs.length} utilisateurs', name: logName);

        // Analyser les timestamps
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          dev.log('User ${doc.id}: createdAt = ${data['createdAt']}, type = ${data['createdAt'].runtimeType}', name: logName);
        }
      } catch (e, st) {
        dev.log('ERREUR avec orderBy: $e', name: logName, error: e, stackTrace: st);
        dev.log('L\'index composite est peut-être manquant ou en cours de création', name: logName);
      }

      // Test 5: Charger sans orderBy
      dev.log('\nTest SANS orderBy:', name: logName);
      final simpleQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('accountType', isEqualTo: 'teacher_transfer')
          .get();
      dev.log('Trouvé ${simpleQuery.docs.length} utilisateurs', name: logName);

      // Charger les données pour affichage
      setState(() {
        _users = simpleQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'nom': data['nom'] ?? 'Sans nom',
            'email': data['email'] ?? 'Sans email',
            'accountType': data['accountType'] ?? 'null',
            'createdAt': data['createdAt']?.toString() ?? 'null',
            'hasCreatedAt': data['createdAt'] != null,
          };
        }).toList();
        _isLoading = false;
      });

    } catch (e, st) {
      dev.log('ERREUR GLOBALE: $e', name: logName, error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Chargement Utilisateurs'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ERREUR:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Utilisateurs trouvés: ${_users.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._users.map((user) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['nom'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Email: ${user['email']}'),
                                Text('Type: ${user['accountType']}'),
                                Text(
                                  'createdAt: ${user['hasCreatedAt'] ? "✅" : "❌"} ${user['createdAt']}',
                                  style: TextStyle(
                                    color: user['hasCreatedAt']
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isLoading = true;
            _users = [];
            _errorMessage = '';
          });
          _testLoadUsers();
        },
        backgroundColor: const Color(0xFFF77F00),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
