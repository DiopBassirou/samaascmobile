import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  List<dynamic> _pendingAscs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingAscs();
  }

  Future<void> _fetchPendingAscs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/superadmin/ascs/pending'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _pendingAscs = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processRequest(String codeUnique, bool isApprove) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final endpoint = isApprove ? 'approve' : 'reject';
    
    await http.post(
      Uri.parse('$_baseUrl/superadmin/ascs/$codeUnique/$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    _fetchPendingAscs(); // Rafraîchir la liste
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Super Admin', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingAscs.isEmpty
              ? const Center(child: Text("Aucune demande en attente."))
              : ListView.builder(
                  itemCount: _pendingAscs.length,
                  itemBuilder: (context, index) {
                    final asc = _pendingAscs[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(Icons.shield, color: Colors.blueAccent),
                        title: Text("${asc['nom']} (${asc['ville']})"),
                        subtitle: Text("Créateur: ${asc['president']?['prenom'] ?? ''} ${asc['president']?['nom'] ?? ''}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _processRequest(asc['code_unique'], true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _processRequest(asc['code_unique'], false),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
